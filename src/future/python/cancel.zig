const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Future = @import("../main.zig");
const PythonFutureObject = Future.Python.FutureObject;

const utils = @import("../../utils/utils.zig");

pub inline fn future_fast_cancel(instance: *PythonFutureObject, cancel_msg_py_object: ?PyObject) bool {
    if (cancel_msg_py_object) |pyobj| {
        if (python_c.PyUnicode_Check(pyobj) == 0) {
            python_c.PyErr_SetString(python_c.PyExc_TypeError.?, "Cancel message must be a string\x00");
            return false;
        }

        instance.cancel_msg_py_object = python_c.py_newref(pyobj);
    }

    const future_data = utils.get_data_ptr(Future, instance);
    Future.Callback.call_done_callbacks(future_data, .CANCELED) catch |err| {
        return utils.handle_zig_function_error(err, false);
    };

    return true;
}

pub fn future_cancel(
    self: ?*PythonFutureObject, args: ?[*]?PyObject, nargs: isize, knames: ?PyObject
) callconv(.C) ?PyObject {
    if (nargs != 0) {
        python_c.raise_python_value_error("Invalid number of arguments\x00");
        return null;
    }

    const instance = self.?;

    const future_data = utils.get_data_ptr(Future, instance);
    const mutex = &future_data.mutex;
    mutex.lock();
    defer mutex.unlock();

    switch (future_data.status) {
        .FINISHED,.CANCELED => return python_c.get_py_false(),
        else => {}
    }

    var cancel_msg_py_object: ?PyObject = null;
    python_c.parse_vector_call_kwargs(
        knames, args.?,
        &.{"msg\x00"},
        &.{&cancel_msg_py_object},
    ) catch |err| {
        return utils.handle_zig_function_error(err, null);
    };

    if (!future_fast_cancel(instance, cancel_msg_py_object)) {
        return null;
    }

    return python_c.get_py_true();
}

pub fn future_cancelled(self: ?*PythonFutureObject, _: ?PyObject) callconv(.C) ?PyObject {
    const future_data = utils.get_data_ptr(Future, self.?);
    const mutex = &future_data.mutex;
    mutex.lock();
    defer mutex.unlock();

    return switch (future_data.status) {
        .CANCELED => python_c.get_py_true(),
        else => python_c.get_py_false()
    };
}
