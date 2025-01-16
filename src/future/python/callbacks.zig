const builtin = @import("builtin");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Future = @import("../main.zig");
const Loop = @import("../../loop/main.zig");
const PythonFutureObject = Future.Python.FutureObject;

const CallbackManager = @import("../../callback_manager.zig");

const utils = @import("../../utils/utils.zig");

inline fn z_future_add_done_callback(
    self: *PythonFutureObject, args: []?PyObject,
    knames: ?PyObject
) !PyObject {
    if (args.len != 1) {
        python_c.raise_python_value_error("Invalid number of arguments\x00");
        return error.PythonError;
    }

    var context: ?PyObject = null;
    try python_c.parse_vector_call_kwargs(
        knames, args.ptr + args.len,
        &.{"context\x00"},
        &.{&context},
    );

    const py_loop = self.py_loop.?;
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
    }else {
        context = python_c.PyContext_CopyCurrent() orelse return error.PythonError;
    }
    errdefer python_c.py_decref(context.?);

    const future_data = utils.get_data_ptr(Future, self);
    const mutex = &future_data.mutex;
    mutex.lock();
    defer mutex.unlock();

    const callback = python_c.py_newref(args[0].?);
    errdefer python_c.py_decref(callback);

    if (python_c.PyCallable_Check(callback) < 0) {
        python_c.raise_python_type_error("Invalid callback\x00");
        return error.PythonError;
    }

    var callback_data: CallbackManager.Callback = .{
        .PythonFuture = .{
            .py_future = @ptrCast(self),
            .py_callback = callback,
            .py_context = context.?,
            .exception_handler = py_loop.exception_handler.?,
        }
    };

    switch (future_data.status) {
        .PENDING => try Future.Callback.add_done_callback(future_data, callback_data),
        else => {
            python_c.py_incref(@ptrCast(self));
            errdefer python_c.py_decref(@ptrCast(self));

            callback_data.PythonFuture.dec_future = true;
            try Loop.Scheduling.Soon.dispatch(future_data.loop, callback_data);
        }
    }

    return python_c.get_py_none();
}

pub fn future_add_done_callback(
    self: ?*PythonFutureObject, args: ?[*]?PyObject, nargs: isize, knames: ?PyObject
) callconv(.C) ?PyObject {
    return utils.execute_zig_function(z_future_add_done_callback, .{
        self.?, args.?[0..@as(usize, @intCast(nargs))], knames
    });
}

pub fn future_remove_done_callback(self: ?*PythonFutureObject, callback: ?PyObject) callconv(.C) ?PyObject {
    const future_data = utils.get_data_ptr(Future, self.?);
    const mutex = &future_data.mutex;
    mutex.lock();
    defer mutex.unlock();

    const removed_count = Future.Callback.remove_done_callback(
        future_data, @intCast(@intFromPtr(callback.?))
    );

    return python_c.PyLong_FromUnsignedLongLong(@intCast(removed_count));
}
