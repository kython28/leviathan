const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../../utils/utils.zig");

const CallbackManager = @import("../../../callback_manager.zig");
const Handle = @import("../../../handle.zig");
const Loop = @import("../../main.zig");

const LoopObject = Loop.Python.LoopObject;

const Scheduling = @import("../scheduling.zig");


fn loop_watchers_callback(
    data: ?*anyopaque, status: CallbackManager.ExecuteCallbacksReturn
) CallbackManager.ExecuteCallbacksReturn {
    const watcher: *Loop.FDWatcher = @alignCast(@ptrCast(data.?));

    const loop_data = watcher.loop_data;
    const allocator = loop_data.allocator;
    const new_status = CallbackManager.run_callback(
        allocator, watcher.callback, status
    );

    const returned_without_problem = (
        @intFromEnum(status)&@intFromEnum(new_status)
    ) == @intFromEnum(CallbackManager.ExecuteCallbacksReturn.Continue);

    const fd = watcher.fd;
    if (returned_without_problem and fd >= 0) {
        const blocking_task_id = Loop.Scheduling.IO.queue(
            loop_data, switch (watcher.event_type) {
                std.c.POLL.IN => Loop.Scheduling.IO.BlockingOperationData{
                    .WaitReadable = .{
                        .fd = watcher.fd,
                        .callback = .{
                            .ZigGeneric = .{
                                .callback = &loop_watchers_callback,
                                .data = watcher
                            }
                        }
                    },
                },
                std.c.POLL.OUT => Loop.Scheduling.IO.BlockingOperationData{
                    .WaitWritable = .{
                        .fd = watcher.fd,
                        .callback = .{
                            .ZigGeneric = .{
                                .callback = &loop_watchers_callback,
                                .data = watcher
                            }
                        }
                    },
                },
                else => unreachable
            }
        ) catch |err| {
            _ = switch (watcher.event_type) {
                std.c.POLL.IN => loop_data.reader_watchers.delete(fd),
                std.c.POLL.OUT => loop_data.writer_watchers.delete(fd),
                else => unreachable
            };
            allocator.destroy(watcher);

            return utils.handle_zig_function_error(err, CallbackManager.ExecuteCallbacksReturn.Exception);
        };

        watcher.blocking_task_id = blocking_task_id;
        return .Continue;
    }

    if (fd >= 0) {
        _ = switch (watcher.event_type) {
            std.c.POLL.IN => loop_data.reader_watchers.delete(fd),
            std.c.POLL.OUT => loop_data.writer_watchers.delete(fd),
            else => unreachable
        };
    }
    allocator.destroy(watcher);
    return new_status;
}

inline fn z_loop_add_watcher(
    self: *LoopObject, args: []?PyObject,
    operation: Loop.Scheduling.IO.BlockingOperation
) !PyObject {
    if (args.len < 2) {
        python_c.raise_python_value_error("Invalid number of arguments\x00");
        return error.PythonError;
    }

    const loop_data = utils.get_data_ptr(Loop, self);

    const py_fd: PyObject = args[0].?;
    if (python_c.long_check(py_fd)) {
        python_c.raise_python_runtime_error("Invalid file descriptor\x00");
        return error.PythonError;
    }

    const fd: std.posix.fd_t = @intCast(python_c.PyLong_AsLong(py_fd));
    if (fd < 0) {
        python_c.raise_python_value_error("Invalid file descriptor\x00");
        return error.PythonError;
    }

    const context: PyObject = python_c.PyContext_CopyCurrent()
        orelse return error.PythonError;
    errdefer python_c.py_decref(context);

    const allocator = loop_data.allocator;
    const callback_info = try Scheduling.get_callback_info(allocator, args[2..]);
    errdefer {
        if (callback_info) |_args| {
            for (_args) |arg| {
                python_c.py_decref(@ptrCast(arg));
            }
            allocator.free(_args);
        }
    }

    const py_handle: *Handle.PythonHandleObject = try Handle.fast_new_handle(context, loop_data);
    errdefer python_c.py_decref(@ptrCast(py_handle));

    const py_callback = python_c.py_newref(args[1].?);
    errdefer python_c.py_decref(py_callback);

    if (python_c.PyCallable_Check(py_callback) < 0) {
        python_c.raise_python_runtime_error("Invalid callback\x00");
        return error.PythonError;
    }

    const mutex = &loop_data.mutex;
    mutex.lock();
    defer mutex.unlock();
    if (!loop_data.initialized) {
        python_c.raise_python_runtime_error("Loop is closed\x00");
        return error.PythonError;
    }

    const watcher_data: Loop.FDWatcher = .{
        .callback = .{
            .PythonGeneric = .{
                .args = callback_info,
                .exception_handler = self.exception_handler.?,
                .py_callback = py_callback,
                .py_context = context,
                .py_handle = py_handle,
                .cancelled = &py_handle.cancelled,
                .can_release = false
            }
        },
        .loop_data = loop_data,
        .event_type = switch (operation) {
            .WaitReadable => std.c.POLL.IN,
            .WaitWritable => std.c.POLL.OUT,
            else => unreachable
        },
        .fd = fd
    };

    const watchers = switch (operation) {
        .WaitWritable => &loop_data.writer_watchers,
        .WaitReadable => &loop_data.reader_watchers,
        else => unreachable
    };

    const existing_watcher_ptr: ?*Loop.FDWatcher = watchers.get_value(fd, null);
    if (existing_watcher_ptr) |existing_watcher_data| {
        var previous_callback = existing_watcher_data.callback;
        CallbackManager.cancel_callback(&previous_callback, true);

        try Loop.Scheduling.Soon._dispatch(
            loop_data, previous_callback
        );

        existing_watcher_data.callback = watcher_data.callback;
        return python_c.get_py_none();
    }

    const watcher_data_ptr = try allocator.create(Loop.FDWatcher);
    errdefer allocator.destroy(watcher_data_ptr);

    watcher_data_ptr.* = watcher_data;

    if (!watchers.insert(fd, watcher_data_ptr)) {
        python_c.raise_python_runtime_error("Unexpected error adding watcher\x00");
        return error.PythonError;
    }
    errdefer {
        if (watchers.delete(fd) == null) {
            unreachable;
        }
    }

    const watcher_callback: CallbackManager.Callback = .{
        .ZigGeneric = .{
            .callback = &loop_watchers_callback,
            .data = watcher_data_ptr
        }
    };

    const blocking_task_id = try Loop.Scheduling.IO.queue(
        loop_data,
        switch (operation) {
            .WaitReadable => Loop.Scheduling.IO.BlockingOperationData{
                .WaitReadable = .{
                    .fd = fd,
                    .callback = watcher_callback
                },
            },
            .WaitWritable => Loop.Scheduling.IO.BlockingOperationData{
                .WaitWritable = .{
                    .fd = fd,
                    .callback = watcher_callback
                },
            },
            else => unreachable
        }
    );

    watcher_data_ptr.blocking_task_id = blocking_task_id;
    return python_c.get_py_none();
}

pub fn loop_add_reader(
    self: ?*LoopObject, args: ?[*]?PyObject, nargs: isize
) callconv(.C) ?PyObject {
    return utils.execute_zig_function(z_loop_add_watcher, .{
        self.?, args.?[0..@as(usize, @intCast(nargs))],
        Loop.Scheduling.IO.BlockingOperation.WaitReadable
    });
}

pub fn loop_add_writer(
    self: ?*LoopObject, args: ?[*]?PyObject, nargs: isize
) callconv(.C) ?PyObject {
    return utils.execute_zig_function(z_loop_add_watcher, .{
        self.?, args.?[0..@as(usize, @intCast(nargs))],
        Loop.Scheduling.IO.BlockingOperation.WaitWritable
    });
}

inline fn z_loop_remove_watcher(
    self: *LoopObject, py_fd: PyObject,
    operation: Loop.Scheduling.IO.BlockingOperation
) !PyObject {
    if (python_c.long_check(py_fd)) {
        python_c.raise_python_runtime_error("Invalid file descriptor\x00");
        return error.PythonError;
    }

    const fd: std.posix.fd_t = @intCast(python_c.PyLong_AsLong(py_fd));
    if (fd < 0) {
        python_c.raise_python_value_error("Invalid file descriptor\x00");
        return error.PythonError;
    }

    const loop_data = utils.get_data_ptr(Loop, self);
    const mutex = &loop_data.mutex;
    mutex.lock();
    defer mutex.unlock();

    if (!loop_data.initialized) {
        python_c.raise_python_runtime_error("Loop is closed\x00");
        return error.PythonError;
    }

    const watchers = switch (operation) {
        .WaitWritable => &loop_data.writer_watchers,
        .WaitReadable => &loop_data.reader_watchers,
        else => unreachable
    };

    const existing_watcher_ptr: ?*Loop.FDWatcher = watchers.delete(fd);
    if (existing_watcher_ptr) |existing_watcher_data| {
        const blocking_task_id = existing_watcher_data.blocking_task_id;
        if (blocking_task_id == 0) {
            @panic("Unexpected blocking task id");
        }

        CallbackManager.cancel_callback(&existing_watcher_data.callback, true);
        existing_watcher_data.fd = -1;

        _ = try Loop.Scheduling.IO.queue(
            loop_data, Loop.Scheduling.IO.BlockingOperationData{
                .Cancel = blocking_task_id
            }
        );

        return python_c.get_py_true();
    }

    return python_c.get_py_false();
}

pub fn loop_remove_reader(
    self: ?*LoopObject, py_fd: ?PyObject
) callconv(.C) ?PyObject {
    return utils.execute_zig_function(z_loop_remove_watcher, .{
        self.?, py_fd.?, Loop.Scheduling.IO.BlockingOperation.WaitReadable
    });
}

pub fn loop_remove_writer(
    self: ?*LoopObject, py_fd: ?PyObject
) callconv(.C) ?PyObject {
    return utils.execute_zig_function(z_loop_remove_watcher, .{
        self.?, py_fd.?, Loop.Scheduling.IO.BlockingOperation.WaitWritable
    });
}
