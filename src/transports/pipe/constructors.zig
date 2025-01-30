const std = @import("std");
const python_c = @import("python_c");

pub fn pipe_dealloc(_: *python_c.PyObject) callconv(.C) void {}

pub fn pipe_clear(_: *python_c.PyObject) callconv(.C) i32 {
    return 0;
}

pub fn pipe_init(
    _: *python_c.PyObject,
    _: *python_c.PyObject,
    _: *python_c.PyObject,
) callconv(.C) i32 {
    return 0;
}

inline fn z_pipe_init(
    _: *python_c.PyObject,
    _: *python_c.PyObject,
    _: *python_c.PyObject,
) callconv(.C) ?*python_c.PyObject {
    return null;
}
