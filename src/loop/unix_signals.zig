const std = @import("std");

const python_c = @import("python_c");
const utils = @import("../utils/utils.zig");

const Loop = @import("main.zig");
const CallbackManager = @import("../callback_manager.zig");

const c = @cImport({
    @cInclude("signal.h");
});

const BTree = @import("../utils/btree.zig").init(u6, CallbackManager.Callback, 3);

callbacks: BTree,
fd: std.posix.fd_t,
mask: std.posix.sigset_t,
loop: *Loop,

blocking_task_id: usize = 0,

signalfd_info: std.os.linux.signalfd_siginfo = undefined,

fn dummy_signal_handler(_: c_int) callconv(.C) void {
    // std.log.info("Dummy signal handler", .{});
}

fn signal_handler(
    data: ?*anyopaque, status: CallbackManager.ExecuteCallbacksReturn
) CallbackManager.ExecuteCallbacksReturn {
    if (status != .Continue) return status;

    const loop: *Loop = @alignCast(@ptrCast(data.?));

    const sig = loop.unix_signals.signalfd_info.signo;
    const callback = loop.unix_signals.callbacks.get_value(@intCast(sig), null).?;
    const ret = CallbackManager.run_callback(loop.allocator, callback, .Continue);

    if (ret != .Continue) {
        return ret;
    }

    const buffer_to_read: std.os.linux.IoUring.ReadBuffer = .{
        .buffer = @as([*]u8, @ptrCast(&loop.unix_signals.signalfd_info))[0..@sizeOf(std.os.linux.signalfd_siginfo)],
    };

    _ = Loop.Scheduling.IO.queue(loop, Loop.Scheduling.IO.BlockingOperationData{
        .PerformRead = .{
            .fd = loop.unix_signals.fd,
            .data = buffer_to_read,
            .callback = CallbackManager.Callback{
                .ZigGeneric = .{
                    .data = loop,
                    .callback = &signal_handler
                }
            },
            .offset = 0
        }
    }) catch |err| {
        return utils.handle_zig_function_error(err, .Exception);
    };

    return .Continue;
}

fn default_sigint_signal_callback(
    _: ?*anyopaque, status: CallbackManager.ExecuteCallbacksReturn
) CallbackManager.ExecuteCallbacksReturn {
    if (status != .Continue) return status;
    python_c.PyErr_SetNone(python_c.PyExc_KeyboardInterrupt);
    return .Exception;
}

fn enqueue_signal_fd(self: *UnixSignals) !void {
    const blocking_task_id = self.blocking_task_id;
    const loop = self.loop;
    if (blocking_task_id > 0) {
        _ = try Loop.Scheduling.IO.queue(
            loop, Loop.Scheduling.IO.BlockingOperationData{
                .Cancel = blocking_task_id
            }
        );
    }

    const buffer_to_read: std.os.linux.IoUring.ReadBuffer = .{
        .buffer = @as([*]u8, @ptrCast(&self.signalfd_info))[0..@sizeOf(std.os.linux.signalfd_siginfo)],
    };

    self.blocking_task_id = try Loop.Scheduling.IO.queue(loop, Loop.Scheduling.IO.BlockingOperationData{
        .PerformRead = .{
            .fd = self.fd,
            .data = buffer_to_read,
            .callback = CallbackManager.Callback{
                .ZigGeneric = .{
                    .data = loop,
                    .callback = &signal_handler
                }
            },
        }
    });
}

pub fn link(self: *UnixSignals, sig: u6, callback: CallbackManager.Callback) !void {
    switch (@as(CallbackManager.CallbackType, callback)) {
        .ZigGeneric,.PythonGeneric => {},
        else => return error.InvalidCallback
    }

    // When the user create a new thread, we need to avoid that python catch the signal
    _ = c.signal(@intCast(sig), &dummy_signal_handler);

    const mask = &self.mask;
    std.os.linux.sigaddset(mask, sig);
    std.posix.sigprocmask(std.os.linux.SIG.BLOCK, mask, null);
    _ = c.siginterrupt(@intCast(sig), 0);

    self.fd = try std.posix.signalfd(self.fd, mask, 0);
    
    var prev_callback = self.callbacks.replace(sig, callback);
    if (prev_callback) |*v| {
        CallbackManager.cancel_callback(v, true);
        try Loop.Scheduling.Soon._dispatch(self.loop, v.*);
    }

    try self.enqueue_signal_fd();
}

pub fn unlink(self: *UnixSignals, sig: u6) !void {
    var callback_info = self.callbacks.delete(sig);
    if (callback_info) |*v| {
        CallbackManager.cancel_callback(v, true);
        try Loop.Scheduling.Soon._dispatch(self.loop, v.*);
    }else{
        return error.KeyNotFound;
    }
    if (callback_info == null) return error.KeyNotFound;

    const callback: CallbackManager.Callback = switch (sig) {
        std.os.linux.SIG.INT => CallbackManager.Callback{
            .ZigGeneric = .{
                .data = self.loop,
                .callback = &default_sigint_signal_callback,
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

    if (!self.callbacks.insert(sig, callback)) {
        @panic("Failed to insert callback");
    }
}

pub fn init(loop: *Loop) !void {
    var mask: std.posix.sigset_t = std.posix.empty_sigset;
    const fd = try std.posix.signalfd(-1, &mask, 0);
    errdefer std.posix.close(fd);

    loop.unix_signals = .{
        .callbacks = try BTree.init(loop.allocator),
        .fd = fd,
        .mask = mask,
        .loop = loop
    };
    const unix_signals = &loop.unix_signals;
    errdefer unix_signals.deinit() catch unreachable;

    try unix_signals.link(std.os.linux.SIG.INT, CallbackManager.Callback{
        .ZigGeneric = .{
            .data = loop,
            .callback = &default_sigint_signal_callback,
        }
    });
}

pub fn deinit(self: *UnixSignals) !void {
    std.posix.close(self.fd);
    const loop = self.loop;

    var mask: std.posix.sigset_t = std.posix.empty_sigset;

    while (true) {
        var sig: u6 = undefined;
        var value = self.callbacks.pop(&sig) orelse break;
        std.os.linux.sigaddset(&mask, sig);

        _ = c.signal(@intCast(sig), c.SIG_DFL);
        CallbackManager.cancel_callback(&value, true);
        try Loop.Scheduling.Soon._dispatch(loop, value);
    }

    std.posix.sigprocmask(std.os.linux.SIG.UNBLOCK, &mask, null);
    try self.callbacks.deinit();
}

const UnixSignals = @This();
