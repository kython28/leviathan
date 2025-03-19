// This module was made to work with python functions only
const std = @import("std");

const python_c = @import("python_c");
const utils = @import("utils");

const Loop = @import("main.zig");
const CallbackManager = @import("callback_manager");


const c = @cImport({
    @cInclude("signal.h");
});

const CallbacksBTree = utils.BTree(u6, CallbackManager.Callback, 3);

callbacks: CallbacksBTree,
fd: std.posix.fd_t,
mask: std.posix.sigset_t,
loop: *Loop,

blocking_task_id: usize = 0,

signalfd_info: std.os.linux.signalfd_siginfo = undefined,

fn dummy_signal_handler(_: c_int) callconv(.C) void {
    // std.log.info("Dummy signal handler", .{});
}

fn signal_handler(data: *const CallbackManager.CallbackData) !void {
    const io_uring_err = data.io_uring_err;
    if (data.cancelled or io_uring_err == .CANCELED) return;

    const loop: *Loop = @alignCast(@ptrCast(data.user_data.?));
    if (io_uring_err != .SUCCESS) {
        const exception = python_c.PyObject_CallFunction(
            python_c.PyExc_OSError, "Ls\x00",
            @as(c_long, @intFromEnum(io_uring_err)),
            "IO error during signal handling\x00"
        ) orelse return error.PythonError;

        loop.mutex.lock();
        loop.stopping = true;
        loop.mutex.unlock();

        python_c.PyErr_SetRaisedException(exception);
        return error.PythonError;
    }

    const sig = loop.unix_signals.signalfd_info.signo;

    const callback = loop.unix_signals.callbacks.get_value_ptr(@intCast(sig), null).?;
    python_c.py_incref(@alignCast(@ptrCast(callback.data.user_data.?)));

    try Loop.Scheduling.Soon.dispatch(loop, callback);

    const buffer_to_read: std.os.linux.IoUring.ReadBuffer = .{
        .buffer = @as([*]u8, @ptrCast(&loop.unix_signals.signalfd_info))[0..@sizeOf(std.os.linux.signalfd_siginfo)],
    };

    loop.unix_signals.blocking_task_id = try loop.io.queue(.{
        .PerformRead = .{
            .fd = loop.unix_signals.fd,
            .data = buffer_to_read,
            .callback = CallbackManager.Callback{
                .func = &signal_handler,
                .cleanup = null,
                .data = .{
                    .exception_context = null,
                    .user_data = loop,
                },
                },
            .offset = 0
        }
    });
}

fn default_sigint_signal_callback(data: *const CallbackManager.CallbackData) !void {
    if (data.cancelled) return;

    python_c.PyErr_SetNone(python_c.PyExc_KeyboardInterrupt);
    return error.PythonError;
}

fn enqueue_signal_fd(self: *UnixSignals) !void {
    const blocking_task_id = self.blocking_task_id;
    const loop = self.loop;
    if (blocking_task_id > 0) {
        _ = try loop.io.queue(.{
            .Cancel = blocking_task_id
        });
    }

    const buffer_to_read: std.os.linux.IoUring.ReadBuffer = .{
        .buffer = @as([*]u8, @ptrCast(&self.signalfd_info))[0..@sizeOf(std.os.linux.signalfd_siginfo)],
    };

    self.blocking_task_id = try loop.io.queue(.{
        .PerformRead = .{
            .fd = self.fd,
            .data = buffer_to_read,
            .callback = CallbackManager.Callback{
                // .ZigGeneric = .{
                //     .data = loop,
                //     .callback = &signal_handler
                // }
                .func = &signal_handler,
                .cleanup = null,
                .data = .{
                    .exception_context = null,
                    .user_data = loop,
                },
            },
        }
    });
}

pub fn link(self: *UnixSignals, sig: u6, callback: CallbackManager.Callback) !void {
    // When the user create a new thread, we need to avoid that python catch the signal
    _ = c.signal(@intCast(sig), &dummy_signal_handler);

    const mask = &self.mask;
    std.os.linux.sigaddset(mask, sig);
    std.posix.sigprocmask(std.os.linux.SIG.BLOCK, mask, null);
    _ = c.siginterrupt(@intCast(sig), 0);

    self.fd = try std.posix.signalfd(self.fd, mask, 0);
    try self.enqueue_signal_fd();
    
    var prev_callback = self.callbacks.replace(sig, callback);
    if (prev_callback) |*v| {
        v.data.cancelled = true;
        try Loop.Scheduling.Soon.dispatch_nonthreadsafe(self.loop, v);
    }else{
        try self.loop.reserve_slots(1);
    }
}

pub fn unlink(self: *UnixSignals, sig: u6) !void {
    var callback_info = self.callbacks.delete(sig);
    if (callback_info) |*v| {
        v.data.cancelled = true;
        Loop.Scheduling.Soon.dispatch_guaranteed_nonthreadsafe(self.loop, v);
    }else{
        return error.KeyNotFound;
    }
    if (callback_info == null) return error.KeyNotFound;

    const callback: CallbackManager.Callback = switch (sig) {
        std.os.linux.SIG.INT => CallbackManager.Callback{
            .func = &default_sigint_signal_callback,
            .cleanup = null,
            .data = .{
                .user_data = self.loop,
                .exception_context = null
            }
        },
        else => {
            var mask: std.posix.sigset_t = std.posix.empty_sigset;

            std.os.linux.sigaddset(&mask, sig);
            std.posix.sigprocmask(std.os.linux.SIG.UNBLOCK, &mask, null);

            std.os.linux.sigdelset(&self.mask, sig);
            self.fd = try std.posix.signalfd(self.fd, &self.mask, 0);
            _ = c.signal(@intCast(sig), c.SIG_DFL);
            _ = c.siginterrupt(@intCast(sig), 1);
            return;
        }
    };

    try self.loop.reserve_slots(1);
    if (!self.callbacks.insert(sig, callback)) {
        @panic("Failed to insert callback");
    }
}

pub fn init(loop: *Loop) !void {
    var mask: std.posix.sigset_t = std.posix.empty_sigset;
    const fd = try std.posix.signalfd(-1, &mask, 0);
    errdefer std.posix.close(fd);

    loop.unix_signals = .{
        .callbacks = try CallbacksBTree.init(loop.allocator),
        .fd = fd,
        .mask = mask,
        .loop = loop
    };
    const unix_signals = &loop.unix_signals;
    errdefer unix_signals.deinit();

    try unix_signals.link(std.os.linux.SIG.INT, CallbackManager.Callback{
        .func = &default_sigint_signal_callback,
        .cleanup = null,
        .data = .{
            .user_data = loop,
            .exception_context = null
        }
    });
}

pub fn deinit(self: *UnixSignals) void {
    std.posix.close(self.fd);
    const loop = self.loop;

    var mask: std.posix.sigset_t = std.posix.empty_sigset;

    while (true) {
        var sig: u6 = undefined;
        var value = self.callbacks.pop(&sig) orelse break;
        std.os.linux.sigaddset(&mask, sig);

        _ = c.signal(@intCast(sig), c.SIG_DFL);
        value.data.cancelled = true;
        Loop.Scheduling.Soon.dispatch_guaranteed(loop, &value);
    }

    std.posix.sigprocmask(std.os.linux.SIG.UNBLOCK, &mask, null);
    self.callbacks.deinit() catch |err| {
        std.debug.panic("Unexpected error while releasing Callbacks Btree: {s}", .{@errorName(err)});
    };
}

const UnixSignals = @This();
