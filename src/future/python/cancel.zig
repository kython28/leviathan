const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Future = @import("../main.zig");
const PythonFutureObject = Future.Python.FutureObject;

const utils = @import("../../utils/utils.zig");

pub inline fn future_fast_cancel(instance: *PythonFutureObject, data: *Future, cancel_msg_py_object: ?PyObject) !bool {
    switch (data.status) {
        .FINISHED,.CANCELED => return false,
        else => {}
    }

    if (cancel_msg_py_object) |pyobj| {
        python_c.py_xdecref(instance.cancel_msg_py_object);
        if (python_c.unicode_check(pyobj)) {
            instance.cancel_msg_py_object = python_c.PyObject_Str(pyobj) orelse return error.PythonError;
        }else{
            instance.cancel_msg_py_object = python_c.py_newref(pyobj);
        }
    }

    try Future.Callback.call_done_callbacks(data, .CANCELED);
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

    var cancel_msg_py_object: ?PyObject = null;
    python_c.parse_vector_call_kwargs(
        knames, args.?,
        &.{"msg\x00"},
        &.{&cancel_msg_py_object},
    ) catch |err| {
        return utils.handle_zig_function_error(err, null);
    };

    const ret = future_fast_cancel(instance, future_data, cancel_msg_py_object) catch |err| {
        return utils.handle_zig_function_error(err, null);
    };

    return python_c.PyBool_FromLong(@intCast(@intFromBool(ret)));
}

pub fn future_cancelled(self: ?*PythonFutureObject, _: ?PyObject) callconv(.C) ?PyObject {
    const future_data = utils.get_data_ptr(Future, self.?);
    return switch (future_data.status) {
        .CANCELED => python_c.get_py_true(),
        else => python_c.get_py_false()
    };
}
