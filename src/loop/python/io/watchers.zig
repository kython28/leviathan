const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("utils");

const CallbackManager = @import("callback_manager");
const Handle = @import("../../../handle.zig");
const Loop = @import("../../main.zig");

const LoopObject = Loop.Python.LoopObject;

const Scheduling = @import("../scheduling.zig");

fn loop_watchers_cleanup_callback(ptr: ?*anyopaque) void {
    const watcher: *Loop.FDWatcher = @alignCast(@ptrCast(ptr.?));

    const loop_data = watcher.loop_data;
    const allocator = loop_data.allocator;

    const fd = watcher.fd;
    if (fd >= 0) {
        _ = switch (watcher.event_type) {
            std.c.POLL.IN => loop_data.reader_watchers.delete(fd),
            std.c.POLL.OUT => loop_data.writer_watchers.delete(fd),
            else => unreachable
        };
    }

    python_c.py_decref(@ptrCast(watcher.handle));
    allocator.destroy(watcher);
}

fn loop_watchers_callback(data: *const CallbackManager.CallbackData) !void {
    const watcher: *Loop.FDWatcher = @alignCast(@ptrCast(data.user_data.?));

    const fd = watcher.fd;
    if (!data.cancelled and data.io_uring_err == .SUCCESS and fd >= 0) {
        const loop_data = watcher.loop_data;
        const handle = watcher.handle;
        const callback = CallbackManager.Callback{
            .func = &Handle.callback_for_python_generic_callbacks,
            .cleanup = &Handle.release_python_generic_callback,
            .data = .{
                .user_data = handle,
                .exception_context = .{
                    .module_ptr = @ptrCast(handle),
                    .exc_message = Handle.ExceptionMessage,
                    .module_name = Handle.ModuleName,
                    .callback_ptr = handle.py_callback.?
                }
            }
        };

        try Loop.Scheduling.Soon.dispatch(loop_data, &callback);
        python_c.py_incref(@ptrCast(handle));

        const watcher_callback: CallbackManager.Callback = .{
            .func = &loop_watchers_callback,
            .cleanup = null,
            .data = .{
                .user_data = watcher,
                .exception_context = null
            }
        };

        const blocking_task_id = try loop_data.io.queue(
            switch (watcher.event_type) {
                std.c.POLL.IN => Loop.Scheduling.IO.BlockingOperationData{
                    .WaitReadable = .{
                        .fd = fd,
                        .callback = watcher_callback
                    },
                },
                std.c.POLL.OUT => Loop.Scheduling.IO.BlockingOperationData{
                    .WaitWritable = .{
                        .fd = fd,
                        .callback = watcher_callback
                    },
                },
                else => unreachable
            }
        );

        watcher.blocking_task_id = blocking_task_id;
        return;
    }

    @call(.always_inline, loop_watchers_cleanup_callback, .{watcher});
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

    const allocator = loop_data.allocator;

    var py_handle: *Handle.PythonHandleObject = undefined;
    {
        const context = python_c.PyContext_CopyCurrent()
            orelse return error.PythonError;
        errdefer python_c.py_decref(context);

        const callback_info = try Scheduling.get_callback_info(allocator, args[2..]);
        errdefer {
            if (callback_info) |_args| {
                for (_args) |arg| {
                    python_c.py_decref(@ptrCast(arg));
                }
                allocator.free(_args);
            }
        }

        const py_callback = python_c.py_newref(args[1].?);
        errdefer python_c.py_decref(py_callback);

        if (python_c.PyCallable_Check(py_callback) <= 0) {
            python_c.raise_python_runtime_error("Invalid callback\x00");
            return error.PythonError;
        }

        py_handle = try Handle.fast_new_handle(
            context, loop_data, py_callback, callback_info, false
        );
    }
    errdefer python_c.py_decref(@ptrCast(py_handle));

    const mutex = &loop_data.mutex;
    mutex.lock();
    defer mutex.unlock();
    if (!loop_data.initialized) {
        python_c.raise_python_runtime_error("Loop is closed\x00");
        return error.PythonError;
    }

    const watcher_data: Loop.FDWatcher = .{
        .handle = py_handle,
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
        const prev_handle = existing_watcher_data.handle;
        python_c.py_decref(@ptrCast(prev_handle));

        existing_watcher_data.handle = watcher_data.handle;
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
        .func = &loop_watchers_callback,
        .cleanup = null,
        .data = .{
            .user_data = watcher_data_ptr,
            .exception_context = null
        }
        // .ZigGenericIO = .{
        //     .callback = &loop_watchers_callback,
        //     .data = watcher_data_ptr
        // }
    };

    const blocking_task_id = try loop_data.io.queue(
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

        existing_watcher_data.fd = -1;
        _ = try loop_data.io.queue(
            .{
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
