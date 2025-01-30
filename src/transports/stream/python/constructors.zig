const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

pub fn stream_dealloc(_: *python_c.PyObject) callconv(.C) void {}

pub fn stream_clear(_: *python_c.PyObject) callconv(.C) i32 {
    return 0;
}

pub fn stream_init(
    _: ?PyObject,
    _: ?PyObject,
    _: ?PyObject,
) callconv(.C) i32 {
    return 0;
}

inline fn z_stream_init(
    _: PyObject,
    _: PyObject,
    _: PyObject,
) !python_c.PyObject {
    return null;
}
