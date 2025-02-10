const std = @import("std");

const CallbackManager = @import("../../../callback_manager.zig");
const IO = @import("main.zig");

pub const PerformData = struct {
    fd: std.posix.fd_t,
    callback: CallbackManager.Callback,
    data: std.os.linux.IoUring.ReadBuffer,
    offset: usize
};

pub fn wait_ready(set: *IO.BlockingTasksSet, data: IO.WaitData) !usize {
    const data_ptr = try set.push(.WaitReadable, data.callback);
    errdefer set.pop(data_ptr) catch unreachable;

    const ring: *std.os.linux.IoUring = &set.ring;
    const sqe = try ring.poll_add(@intCast(@intFromPtr(data_ptr)), data.fd, std.c.POLL.IN);
    sqe.flags |= std.os.linux.IOSQE_ASYNC;
    const ret = try ring.submit();
    if (ret != 1) {
        @panic("Unexpected number of submitted sqes");
    }
    return @intFromPtr(data_ptr);
}

pub fn perform(set: *IO.BlockingTasksSet, data: PerformData) !usize {
    const data_ptr = try set.push(.PerformRead, data.callback);
    errdefer set.pop(data_ptr) catch unreachable;

    const ring = &set.ring;
    const sqe = try ring.read(@intCast(@intFromPtr(data_ptr)), data.fd, data.data, data.offset);
    sqe.flags |= std.os.linux.IOSQE_ASYNC;
    const ret = try ring.submit();
    if (ret != 1) {
        @panic("Unexpected number of submitted sqes");
    }
    return @intFromPtr(data_ptr);
}
