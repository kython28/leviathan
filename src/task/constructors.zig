const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../utils/main.zig");

const CallbackManager = @import("../callback_manager.zig");
const Future = @import("../future/main.zig");
const Loop = @import("../loop/main.zig");
const Task = @import("main.zig");

const callbacks = @import("callbacks.zig");

const LoopObject = Loop.Python.LoopObject;
const PythonTaskObject = Task.PythonTaskObject;

const std = @import("std");
const builtin = @import("builtin");

inline fn task_set_initial_values(self: *PythonTaskObject) void {
    Future.Python.Constructors.future_set_initial_values(&self.fut);
    self.py_context = null;
    self.coro = null;
    self.name = null;

    self.wake_up_task_callback = null;
    self.fut_waiter = null;

    self.weakref_list = null;

    self.cancel_requests = 0;
    self.must_cancel = false;
}

inline fn task_init_configuration(
    self: *PythonTaskObject, loop: *LoopObject,
    coro: PyObject, context: PyObject, name: ?PyObject
) !void {
    Future.Python.Constructors.future_init_configuration(&self.fut, loop);
    if (python_c.PyCoro_CheckExact(coro) == 0) {
        switch (python_c.PyObject_HasAttrStringWithError(coro, "__await__\x00")) {
            1 => {},
            0 => {
                python_c.raise_python_type_error("Coro argument must be a coroutine\x00");
                return error.PythonError;
            },
            else => return error.PythonError
        }
    }

    const coro_throw: PyObject = python_c.PyObject_GetAttrString(coro, "throw\x00") orelse return error.PythonError;
    errdefer python_c.py_decref(coro_throw);

    const wrapper = python_c.PyCFunction_New(
        @constCast(&callbacks.LeviathanPyTaskWakeupMethod), @ptrCast(self)
    ) orelse return error.PythonError;
    errdefer python_c.py_decref(wrapper);

    self.name = name;

    self.coro = coro;
    self.coro_throw = coro_throw;

    self.py_context = context;

    self.wake_up_task_callback = wrapper;
}

inline fn task_schedule_coro(self: *PythonTaskObject, loop: *LoopObject) !void {
    const ret: PyObject = python_c.PyObject_CallOneArg(utils.PythonImports.register_task_func, @ptrCast(self))
        orelse return error.PythonError;
    python_c.py_decref(ret);

    const loop_data = utils.get_data_ptr(Loop, loop);

    const callback: CallbackManager.Callback = .{
        .PythonTask = .{
            .task = self
        }
    };

    try Loop.Scheduling.Soon.dispatch(loop_data, callback);
    python_c.py_incref(@ptrCast(self));
}

pub inline fn fast_new_task(
    loop: *LoopObject, coro: PyObject,
    context: PyObject, name: ?PyObject
) !*PythonTaskObject {
    const instance: *PythonTaskObject = @ptrCast(
        Task.PythonTaskType.tp_alloc.?(&Task.PythonTaskType, 0) orelse return error.PythonError
    );
    task_set_initial_values(instance);
    errdefer python_c.py_decref(@ptrCast(instance));

    try task_init_configuration(instance, loop, coro, context, name);
    errdefer { instance.py_context = null; }

    try task_schedule_coro(instance, loop);

    return instance;
}

inline fn z_task_new(
    @"type": *python_c.PyTypeObject, _: ?PyObject,
    _: ?PyObject
) !*PythonTaskObject {
    const instance: *PythonTaskObject = @ptrCast(@"type".tp_alloc.?(@"type", 0) orelse return error.PythonError);
    task_set_initial_values(instance);
    return instance;
}

pub fn task_new(
    @"type": ?*python_c.PyTypeObject, args: ?PyObject,
    kwargs: ?PyObject
) callconv(.C) ?PyObject {
    const self = utils.execute_zig_function(
        z_task_new, .{@"type".?, args, kwargs}
    );
    return @ptrCast(self);
}

pub fn task_clear(self: ?*PythonTaskObject) callconv(.C) c_int {
    const py_task = self.?;
    const fut = &py_task.fut;

    const future_data = utils.get_data_ptr(Future, fut);
    if (!future_data.released) {
        const _result = future_data.result;
        if (_result) |res| {
            python_c.py_decref(@alignCast(@ptrCast(res)));
        }
        future_data.release();
    }

    python_c.py_decref_and_set_null(@ptrCast(&fut.py_loop));
    python_c.py_decref_and_set_null(&fut.exception);
    python_c.py_decref_and_set_null(&fut.exception_tb);
    python_c.py_decref_and_set_null(&fut.cancel_msg_py_object);

    python_c.py_decref_and_set_null(&py_task.py_context);
    python_c.py_decref_and_set_null(&py_task.name);

    python_c.py_decref_and_set_null(&py_task.coro);
    python_c.py_decref_and_set_null(&py_task.coro_throw);

    python_c.py_decref_and_set_null(&py_task.wake_up_task_callback);
    python_c.py_decref_and_set_null(&py_task.fut_waiter);

    if (py_task.weakref_list != null) {
        python_c.PyObject_ClearWeakRefs(@ptrCast(py_task));
        py_task.weakref_list = null;
    }

    return 0;
}

pub fn task_traverse(self: ?*PythonTaskObject, visit: python_c.visitproc, arg: ?*anyopaque) callconv(.C) c_int {
    const instance = self.?;
    return python_c.py_visit(
        &[_]?*python_c.PyObject{
            @ptrCast(instance.fut.py_loop),
            instance.fut.exception,
            instance.fut.exception_tb,
            instance.fut.cancel_msg_py_object,

            instance.py_context,
            instance.name,
            instance.coro,
            instance.coro_throw,

            instance.fut_waiter,
            instance.wake_up_task_callback
        }, visit, arg
    );
}

pub fn task_dealloc(self: ?*PythonTaskObject) callconv(.C) void {
    const instance = self.?;

    python_c.PyObject_GC_UnTrack(instance);
    _ = task_clear(instance);

    const @"type": *python_c.PyTypeObject = @ptrCast(python_c.Py_TYPE(@ptrCast(instance)) orelse unreachable);
    @"type".tp_free.?(@ptrCast(instance));
}

inline fn z_task_init(
    self: *PythonTaskObject, args: ?PyObject, kwargs: ?PyObject
) !c_int {
    var kwlist: [5][*c]u8 = undefined;
    kwlist[0] = @constCast("coro\x00");
    kwlist[1] = @constCast("loop\x00");
    kwlist[2] = @constCast("name\x00");
    kwlist[3] = @constCast("context\x00");
    kwlist[4] = null;

    var coro: ?PyObject = null;
    var py_loop: ?PyObject = null;
    var name: ?PyObject = null;
    var context: ?PyObject = null;

    if (python_c.PyArg_ParseTupleAndKeywords(
            args, kwargs, "OO|$OO\x00", @ptrCast(&kwlist), &coro, &py_loop,
            &name, &context
        ) < 0) {
        return error.PythonError;
    }

    const leviathan_loop: *LoopObject = @ptrCast(py_loop.?);
    if (!python_c.type_check(@ptrCast(leviathan_loop), Loop.Python.LoopType)) {
        python_c.raise_python_type_error("Invalid asyncio event loop. Only Leviathan's event loops are allowed\x00");
        return error.PythonError;
    }

    if (context) |py_ctx| {
        if (python_c.is_none(py_ctx)) {
            context = python_c.PyContext_CopyCurrent()
                orelse return error.PythonError;
        }else if (python_c.is_type(py_ctx, &python_c.PyContext_Type)) {
            python_c.py_incref(py_ctx);
        }else{
            python_c.raise_python_type_error("Invalid context\x00");
            return error.PythonError;
        }
    }else{
        context = python_c.PyContext_CopyCurrent() orelse return error.PythonError;
    }
    errdefer python_c.py_decref(context.?);

    if (name) |v| {
        if (python_c.is_none(v)) {
            python_c.py_decref_and_set_null(&name);
        }else if (python_c.unicode_check(v)) {
            name = python_c.PyObject_Str(v) orelse return error.PythonError;
        }else{
            name = python_c.py_newref(v);
        }
    }
    errdefer python_c.py_xdecref(name);
    
    python_c.py_incref(coro.?);
    errdefer python_c.py_decref(coro.?);

    try task_init_configuration(self, leviathan_loop, coro.?, context.?, name);
    errdefer { self.py_context = null; }

    try task_schedule_coro(self, leviathan_loop);

    return 0;
}

pub fn task_init(
    self: ?*PythonTaskObject, args: ?PyObject, kwargs: ?PyObject
) callconv(.C) c_int {
    return utils.execute_zig_function(z_task_init, .{self.?, args, kwargs});
}
