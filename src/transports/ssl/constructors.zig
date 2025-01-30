const std = @import("std");
const python_c = @import("python_c");

pub fn ssl_dealloc(_: *python_c.PyObject) callconv(.C) void {}

pub fn ssl_clear(_: *python_c.PyObject) callconv(.C) i32 {
    return 0;
}

pub fn ssl_init(
    _: *python_c.PyObject,
    _: *python_c.PyObject,
    _: *python_c.PyObject,
) callconv(.C) i32 {
    return 0;
}

inline fn z_ssl_init(
    _: *python_c.PyObject,
    _: *python_c.PyObject,
    _: *python_c.PyObject,
) callconv(.C) ?*python_c.PyObject {
    return null;
}
