const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../utils/utils.zig");

const CallbackManager = @import("../../callback_manager.zig");
const Loop = @import("../main.zig");
const Handle = @import("../../handle.zig");
const TimerHandle = @import("../../timer_handle.zig");

const LoopObject = Loop.Python.LoopObject;

const std = @import("std");
const builtin = @import("builtin");

pub inline fn get_callback_info(allocator: std.mem.Allocator, args: []?PyObject) !?[]PyObject {
    if (args.len == 0) {
        return null;
    }

    const callback_info = try allocator.alloc(PyObject, args.len);
    errdefer allocator.free(callback_info);

    for (args, callback_info) |arg, *ci| {
        ci.* = python_c.py_newref(arg.?);
    }
    errdefer {
        for (callback_info) |arg| {
            python_c.py_decref(@ptrCast(arg));
        }
    }

    if (python_c.PyCallable_Check(callback_info[0]) < 0) {
        python_c.raise_python_type_error("Invalid callback\x00");
        return error.PythonError;
    }

    return callback_info;
}

inline fn z_loop_call_soon(
    self: *LoopObject, args: []?PyObject,
    knames: ?PyObject
) !*Handle.PythonHandleObject {
    if (args.len == 0) {
        python_c.raise_python_value_error("Invalid number of arguments\x00");
        return error.PythonError;
    }

    var context: ?PyObject = null;
    try python_c.parse_vector_call_kwargs(
        knames, args.ptr + args.len,
        &.{"context\x00"},
        &.{&context},
    );

    if (context) |py_ctx| {
        if (python_c.is_none(py_ctx)) {
            context = python_c.PyContext_CopyCurrent()
                orelse return error.PythonError;
            python_c.py_decref(py_ctx);
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

    const loop_data = utils.get_data_ptr(Loop, self);
    const allocator = loop_data.allocator;

    const callback_info = try get_callback_info(allocator, args[1..]);
    errdefer {
        if (callback_info) |_args| {
            for (_args) |arg| {
                python_c.py_decref(@ptrCast(arg));
            }
            allocator.free(_args);
        }
    }

    const py_handle: *Handle.PythonHandleObject = try Handle.fast_new_handle(context.?, loop_data);
    errdefer python_c.py_decref(@ptrCast(py_handle));

    const py_callback = python_c.py_newref(args[0].?);
    errdefer python_c.py_decref(py_callback);

    if (python_c.PyCallable_Check(py_callback) < 0) {
        python_c.raise_python_type_error("Invalid callback\x00");
        return error.PythonError;
    }

    const mutex = &loop_data.mutex;
    mutex.lock();
    defer mutex.unlock();

    if (!loop_data.initialized) {
        python_c.raise_python_runtime_error("Loop is closed\x00");
        return error.PythonError;
    }

    const callback: CallbackManager.Callback = .{
        .PythonGeneric = .{
            .args = callback_info,
            .exception_handler = self.exception_handler.?,
            .py_callback = py_callback,
            .py_context = context.?,
            .py_handle = py_handle,
            .cancelled = &py_handle.cancelled
        }
    };
    try Loop.Scheduling.Soon._dispatch(loop_data, callback);
    return python_c.py_newref(py_handle);
}

pub fn loop_call_soon(
    self: ?*LoopObject, args: ?[*]?PyObject, nargs: isize, knames: ?PyObject
) callconv(.C) ?*Handle.PythonHandleObject {
    return utils.execute_zig_function(z_loop_call_soon, .{
        self.?, args.?[0..@as(usize, @intCast(nargs))], knames
    });
}

pub fn loop_call_soon_threadsafe(
    self: ?*LoopObject, args: ?[*]?PyObject, nargs: isize, knames: ?PyObject
) callconv(.C) ?*Handle.PythonHandleObject {
    return utils.execute_zig_function(z_loop_call_soon, .{
        self.?, args.?[0..@as(usize, @intCast(nargs))], knames
    });
}

inline fn z_loop_delayed_call(
    self: *LoopObject, args: []?PyObject,
    knames: ?PyObject, comptime is_absolute: bool
) !*TimerHandle.PythonTimerHandleObject {
    if (args.len <= 1) {
        python_c.raise_python_value_error("Invalid number of arguments\x00");
        return error.PythonError;
    }

    var context: ?PyObject = null;
    try python_c.parse_vector_call_kwargs(
        knames, args.ptr + args.len,
        &.{"context\x00"},
        &.{&context},
    );

    if (context == null) {
        context = python_c.PyContext_CopyCurrent() orelse return error.PythonError;
    }
    errdefer python_c.py_decref(context.?);

    const loop_data = utils.get_data_ptr(Loop, self);
    const allocator = loop_data.allocator;

    const callback_info = try get_callback_info(allocator, args[2..]);
    errdefer {
        if (callback_info) |_args| {
            for (_args) |arg| {
                python_c.py_decref(@ptrCast(arg));
            }
            allocator.free(_args);
        }
    }

    const time: std.posix.timespec = blk: {
        const ts: f64 = python_c.PyFloat_AsDouble(args[0].?);
        if (is_absolute) {
            const when_sec = @trunc(ts);
            break :blk .{
                .sec = @intFromFloat(when_sec),
                .nsec = @as(@FieldType(std.posix.timespec, "nsec"), @intFromFloat((ts - when_sec) * std.time.ns_per_s))
            };
        }else{
            var _time: std.posix.timespec = undefined;
            try std.posix.clock_gettime(.MONOTONIC, &_time);

            const delay_sec = @trunc(ts);

            _time.sec += @intFromFloat(delay_sec);
            _time.nsec += @as(@FieldType(std.posix.timespec, "nsec"), @intFromFloat((ts - delay_sec) * std.time.ns_per_s));

            break :blk _time;
        }
    };

    const py_timer_handle: *TimerHandle.PythonTimerHandleObject = try TimerHandle.fast_new_timer_handle(
        time, context.?, loop_data
    );
    errdefer python_c.py_decref(@ptrCast(py_timer_handle));

    const py_callback = python_c.py_newref(args[1].?);
    errdefer python_c.py_decref(py_callback);

    if (python_c.PyCallable_Check(py_callback) < 0) {
        python_c.raise_python_type_error("Invalid callback\x00");
        return error.PythonError;
    }

    const mutex = &loop_data.mutex;
    mutex.lock();
    defer mutex.unlock();

    if (!loop_data.initialized) {
        python_c.raise_python_runtime_error("Loop is closed\x00");
        return error.PythonError;
    }

    const callback: CallbackManager.Callback = .{
        .PythonGeneric = .{
            .args = callback_info,
            .exception_handler = self.exception_handler.?,
            .py_callback = py_callback,
            .py_context = context.?,
            .py_handle = @ptrCast(py_timer_handle),
            .cancelled = &py_timer_handle.handle.cancelled
        }
    };
    py_timer_handle.handle.blocking_task_id = try Loop.Scheduling.IO.queue(loop_data, .{
        .WaitTimer = .{
            .callback = callback,
            .duration = time,
            .delay_type = .Absolute
        }
    });
    return python_c.py_newref(py_timer_handle);
}
pub fn loop_call_later(
    self: ?*LoopObject, args: ?[*]?PyObject, nargs: isize, knames: ?PyObject
) callconv(.C) ?*TimerHandle.PythonTimerHandleObject {
    return utils.execute_zig_function(z_loop_delayed_call, .{
        self.?, args.?[0..@as(usize, @intCast(nargs))], knames,
        false
    });
}

pub fn loop_call_at(
    self: ?*LoopObject, args: ?[*]?PyObject, nargs: isize, knames: ?PyObject
) callconv(.C) ?*TimerHandle.PythonTimerHandleObject {
    
    return utils.execute_zig_function(z_loop_delayed_call, .{
        self.?, args.?[0..@as(usize, @intCast(nargs))], knames,
        true
    });
}
