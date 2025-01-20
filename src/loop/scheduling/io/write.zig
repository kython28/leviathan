const std = @import("std");

const CallbackManager = @import("../../../callback_manager.zig");
const IO = @import("main.zig");

pub const PerformData = struct {
    fd: std.posix.fd_t,
    callback: CallbackManager.Callback,
    data: []const u8,
    offset: usize
};

pub fn wait_ready(set: *IO.BlockingTasksSet, data: IO.WaitData) !void {
    const data_ptr = try set.push(.WaitWritable, data.callback);
    errdefer set.pop(data_ptr) catch unreachable;

    const ring: *std.os.linux.IoUring = &set.ring;
    _ = try ring.poll_add(@intCast(@intFromPtr(data_ptr)), data.fd, std.c.POLL.OUT);
    const ret = try ring.submit();
    if (ret != 1) {
        @panic("Unexpected number of submitted sqes");
    }
}

pub fn perform(set: *IO.BlockingTasksSet, data: PerformData) !void {
    const data_ptr = try set.push(.PerformWrite, data.callback);
    errdefer set.pop(data_ptr) catch unreachable;

    const ring = &set.ring;
    _ = try ring.write(@intCast(@intFromPtr(data_ptr)), data.fd, data.data, data.offset);
    const ret = try ring.submit();
    if (ret != 1) {
        @panic("Unexpected number of submitted sqes");
    }
}
