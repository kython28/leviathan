const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("utils");

const Loop = @import("../../main.zig");

const std = @import("std");


pub fn loop_time(self: ?*Loop.Python.LoopObject, _: ?PyObject) callconv(.C) ?PyObject {
    _ = self.?;

    const time = std.posix.clock_gettime(.MONOTONIC) catch |err| {
        return utils.handle_zig_function_error(err, null);
    };

    const f_time: f64 = @as(f64, @floatFromInt(time.sec)) + @as(f64, @floatFromInt(time.nsec)) / std.time.ns_per_s;
    return python_c.PyFloat_FromDouble(f_time);
}
