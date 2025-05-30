const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Future = @import("../main.zig");
const PythonFutureObject = Future.Python.FutureObject;

const utils = @import("utils");


inline fn raise_cancel_exception(self: *PythonFutureObject) void {
    if (self.cancel_msg_py_object) |cancel_msg_py_object| {
        python_c.PyErr_SetObject(utils.PythonImports.cancelled_error_exc, cancel_msg_py_object);
    }else{
        python_c.PyErr_SetNone(utils.PythonImports.cancelled_error_exc);
    }
}

pub inline fn get_result(self: *PythonFutureObject) ?PyObject {
    const future_data = utils.get_data_ptr(Future, self);
    return switch (future_data.status) {
        .pending => blk: {
            python_c.PyErr_SetString(utils.PythonImports.invalid_state_exc, "Result is not ready.\x00");
            break :blk null;
        },
        .finished => blk: {
            if (self.exception) |exc| {
                python_c.PyErr_SetRaisedException(
                    python_c.py_newref(exc)
                );
                break :blk null;
            }
            break :blk @as(PyObject, @alignCast(@ptrCast(future_data.result.?)));
        },
        .canceled => blk: {
            raise_cancel_exception(self);
            break :blk null;
        }
    };
}

pub fn future_result(self: ?*PythonFutureObject, _: ?PyObject) callconv(.C) ?PyObject {
    const res = get_result(self.?);
    python_c.py_xincref(res);
    return res;
}

pub fn future_exception(self: ?*PythonFutureObject, _: ?PyObject) callconv(.C) ?PyObject {
    const instance = self.?;

    const future_data = utils.get_data_ptr(Future, instance);

    return switch (future_data.status) {
        .pending => blk: {
            python_c.PyErr_SetString(utils.PythonImports.invalid_state_exc, "Exception is not set.\x00");
            break :blk null;
        },
        .finished => blk: {
            if (instance.exception) |exc| {
                break :blk python_c.py_newref(exc);
            }
            break :blk python_c.get_py_none();
        },
        .canceled => blk: {
            raise_cancel_exception(instance);
            break :blk null;
        }
    };
}

pub inline fn future_fast_set_exception(self: *PythonFutureObject, obj: *Future, exception: PyObject) void {
    self.exception = exception;
    Future.Callback.call_done_callbacks(obj, .finished);
}

inline fn z_future_set_exception(self: *PythonFutureObject, exception: PyObject) !PyObject {
    if (python_c.exception_check(exception)) {
        python_c.raise_python_type_error("Invalid exception instance\x00");
        return error.PythonError;
    }

    const future_data = utils.get_data_ptr(Future, self);

    switch (future_data.status) {
        .finished, .canceled => {
            python_c.PyErr_SetString(utils.PythonImports.invalid_state_exc, "Exception already setted\x00");
            return error.PythonError;
        },
        else => {}
    }

    _ = future_fast_set_exception(self, future_data, python_c.py_newref(exception));
    return python_c.get_py_none();
}

pub fn future_set_exception(self: ?*PythonFutureObject, exception: ?PyObject) callconv(.C) ?PyObject {
    return utils.execute_zig_function(z_future_set_exception, .{self.?, exception.?});
}

pub inline fn future_fast_set_result(obj: *Future, result: PyObject) void {
    obj.result = python_c.py_newref(result);
    Future.Callback.call_done_callbacks(obj, .finished);
}

inline fn z_future_set_result(self: *PythonFutureObject, result: PyObject) !PyObject {
    const future_data = utils.get_data_ptr(Future, self);

    switch (future_data.status) {
        .finished,.canceled => {
            python_c.PyErr_SetString(utils.PythonImports.invalid_state_exc, "Result already setted\x00");
            return error.PythonError;
        },
        else => {}
    }

    future_fast_set_result(future_data, result);
    return python_c.get_py_none();
}

pub fn future_set_result(self: ?*PythonFutureObject, result: ?PyObject) callconv(.C) ?PyObject {
    return utils.execute_zig_function(z_future_set_result, .{self.?, result.?});
}

pub fn future_done(self: ?*PythonFutureObject, _: ?PyObject) callconv(.C) ?PyObject {
    const future_data = utils.get_data_ptr(Future, self.?);
    return switch (future_data.status) {
        .finished,.canceled => python_c.get_py_true(),
        else => python_c.get_py_false()
    };
}
