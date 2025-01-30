const std = @import("std");
const python_c = @import("python_c");

pub fn subprocess_dealloc(_: *python_c.PyObject) callconv(.C) void {}

pub fn subprocess_clear(_: *python_c.PyObject) callconv(.C) i32 {
    return 0;
}

pub fn subprocess_init(
    _: *python_c.PyObject,
    _: *python_c.PyObject,
    _: *python_c.PyObject,
) callconv(.C) i32 {
    return 0;
}

inline fn z_subprocess_init(
    _: *python_c.PyObject,
    _: *python_c.PyObject,
    _: *python_c.PyObject,
) callconv(.C) ?*python_c.PyObject {
    return null;
}
