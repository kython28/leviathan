const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const CallbackManager = @import("callback_manager");
const Loop = @import("loop/main.zig");
const utils = @import("utils");

pub const PythonHandleObject = extern struct {
    ob_base: python_c.PyObject,

    contextvars: ?PyObject,
    loop_data: ?*Loop,

    py_callback: ?PyObject,
    py_callback_args: ?[*]PyObject,
    py_callback_len: usize,

    blocking_task_id: usize,
    cancelled: bool,
    finished: bool,
    thread_safe: bool,
};

pub const ExceptionMessage: [:0]const u8 = "An error ocurred while executing python callback";
pub const ModuleName: [:0]const u8 = "handle";

pub fn release_python_generic_callback(ptr: ?*anyopaque) !void {
    const handle: *PythonHandleObject = @alignCast(@ptrCast(ptr.?));

    python_c.py_decref(@ptrCast(handle));
}

pub fn callback_for_python_generic_callbacks(data: *const CallbackManager.CallbackData) !void {
    const handle: *PythonHandleObject = @alignCast(@ptrCast(data.user_data.?));
    const thread_safe = handle.thread_safe;
    if (thread_safe) {
        @atomicStore(bool, &handle.finished, true, .release);
    }else{
        handle.finished = true;
    }

    var cancelled: bool = data.cancelled;
    if (!cancelled) {
        if (thread_safe) {
            cancelled = @atomicLoad(bool, &handle.cancelled, .acquire);
        }else{
            cancelled = handle.cancelled;
        }
    }

    if (cancelled) {
        python_c.py_decref(@ptrCast(handle));
        return;
    }

    const py_context = handle.contextvars.?;
    if (python_c.PyContext_Enter(py_context) < 0) {
        return error.PythonError;
    }

    var result: PyObject = undefined;
    if (handle.py_callback_args) |args| {
        result = python_c.PyObject_Vectorcall(
            handle.py_callback.?, args, handle.py_callback_len, null
        ) orelse return error.PythonError;
    }else{
        result = python_c.PyObject_CallNoArgs(handle.py_callback.?)
            orelse return error.PythonError;
    }
    python_c.py_decref(result);

    if (python_c.PyContext_Exit(py_context) < 0) {
        return error.PythonError;
    }

    python_c.py_decref(@ptrCast(handle));
}

pub inline fn fast_new_handle(
    contextvars: PyObject, loop_data: *Loop, py_callback: PyObject, args: ?[]PyObject,
    thread_safe: bool
) !*PythonHandleObject {
    const instance: *PythonHandleObject = @ptrCast(
        PythonHandleType.tp_alloc.?(&PythonHandleType, 0) orelse return error.PythonError
    );

    instance.contextvars = contextvars;
    instance.loop_data = loop_data;
    instance.py_callback = py_callback;

    if (args) |v| {
        instance.py_callback_args = v.ptr;
        instance.py_callback_len = v.len;
    }

    instance.blocking_task_id = 0;
    instance.cancelled = false;
    instance.finished = false;
    instance.thread_safe = thread_safe;

    return instance;
}

fn handle_dealloc(self: ?*PythonHandleObject) callconv(.C) void {
    const instance = self.?;
    python_c.py_decref_and_set_null(&instance.contextvars);
    python_c.py_decref_and_set_null(&instance.py_callback);

    const args_len = instance.py_callback_len;
    if (instance.py_callback_args) |args_ptr| {
        const allocator = instance.loop_data.?.allocator;
        const args = args_ptr[0..args_len];

        for (args) |arg| python_c.py_decref(arg);

        allocator.free(args);
    }

    const @"type": *python_c.PyTypeObject = python_c.get_type(@ptrCast(instance));
    @"type".tp_free.?(@ptrCast(instance));
}

inline fn z_handle_init(
    self: *PythonHandleObject, args: ?PyObject, kwargs: ?PyObject
) !c_int {
    var kwlist: [2][*c]u8 = undefined;
    kwlist[0] = @constCast("context\x00");
    kwlist[1] = null;

    var py_context: ?PyObject = null;

    if (python_c.PyArg_ParseTupleAndKeywords(
            args, kwargs, "O\x00", @ptrCast(&kwlist), &py_context
    ) < 0) {
        return error.PythonError;
    }
    
    if (py_context) |ctx| {
        if (python_c.is_none(ctx)) {
            python_c.raise_python_type_error("context cannot be None\x00");
            return error.PythonError;
        }
    }

    self.contextvars = python_c.py_newref(py_context.?);
    self.cancelled = false;
    self.thread_safe = false;

    return 0;
}

fn handle_init(self: ?*PythonHandleObject, args: ?PyObject, kwargs: ?PyObject) callconv(.C) c_int {
    return utils.execute_zig_function(z_handle_init, .{self.?, args, kwargs});
}

fn handle_get_context(self: ?*PythonHandleObject, _: ?PyObject) callconv(.C) ?PyObject {
    return python_c.py_newref(self.?.contextvars.?);
}

pub inline fn fast_handle_cancel(self: *PythonHandleObject) !void {
    const thread_safe = self.thread_safe;
    const finished = switch (thread_safe) {
        false => self.finished,
        true => @atomicLoad(bool, &self.finished, .acquire)
    };
    if (finished) {
        return;
    }

    const cancelled = switch (thread_safe) {
        false => self.cancelled,
        true => @atomicLoad(bool, &self.cancelled, .acquire)
    };

    if (!cancelled) {
        const blocking_task_id = self.blocking_task_id;
        if (blocking_task_id > 0) {
            const loop_data = self.loop_data.?;

            const mutex = &loop_data.mutex;
            mutex.lock();
            defer mutex.unlock();

            _ = try Loop.Scheduling.IO.queue(loop_data, .{
                .Cancel = blocking_task_id
            });
        }

        if (thread_safe) {
            @atomicStore(bool, &self.cancelled, true, .release);
        }else{
            self.cancelled = true;
        }
    }
}

fn handle_cancel(self: ?*PythonHandleObject, _: ?PyObject) callconv(.C) ?PyObject {
    fast_handle_cancel(self.?) catch |err| {
        return utils.handle_zig_function_error(err, null);
    };

    return python_c.get_py_none();
}

fn handle_cancelled(self: ?*PythonHandleObject, _: ?PyObject) callconv(.C) ?PyObject {
    const instance = self.?;
    const cancelled = switch (instance.thread_safe) {
        false => instance.cancelled,
        true => @atomicLoad(bool, &instance.cancelled, .acquire)
    };

    return python_c.PyBool_FromLong(@intCast(@intFromBool(cancelled)));
}

const PythonhandleMethods: []const python_c.PyMethodDef = &[_]python_c.PyMethodDef{
    python_c.PyMethodDef{
        .ml_name = "cancel\x00",
        .ml_meth = @ptrCast(&handle_cancel),
        .ml_doc = "Cancel the callback. If the callback has already been canceled or executed, this method has no effect.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "cancelled\x00",
        .ml_meth = @ptrCast(&handle_cancelled),
        .ml_doc = "Return True if the callback was cancelled.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "get_context\x00",
        .ml_meth = @ptrCast(&handle_get_context),
        .ml_doc = "Return the contextvars.Context object associated with the handle.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = null, .ml_meth = null, .ml_doc = null, .ml_flags = 0
    }
};

pub var PythonHandleType = python_c.PyTypeObject{
    .tp_name = "leviathan.Handle\x00",
    .tp_doc = "Leviathan's handle class\x00",
    .tp_basicsize = @sizeOf(PythonHandleObject),
    .tp_itemsize = 0,
    .tp_flags = python_c.Py_TPFLAGS_DEFAULT | python_c.Py_TPFLAGS_BASETYPE,
    .tp_new = &python_c.PyType_GenericNew,
    .tp_init = @ptrCast(&handle_init),
    .tp_dealloc = @ptrCast(&handle_dealloc),
    .tp_methods = @constCast(PythonhandleMethods.ptr),
    .tp_members = null
};

