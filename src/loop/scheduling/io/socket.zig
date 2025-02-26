const std = @import("std");

const CallbackManager = @import("../../../callback_manager.zig");
const IO = @import("main.zig");

pub const ShutdownData = struct {
    socket_fd: std.posix.fd_t,
    how: u32
};

pub fn shutdown(set: *IO.BlockingTasksSet, data: ShutdownData) !usize {
    const data_ptr = try set.push(.WaitReadable, null);
    errdefer set.pop(data_ptr);

    const ring: *std.os.linux.IoUring = &set.ring;
    const sqe = try ring.shutdown(@intCast(@intFromPtr(data_ptr)), data.socket_fd, data.how);
    sqe.flags |= std.os.linux.IOSQE_ASYNC;
    const ret = try ring.submit();
    if (ret != 1) {
        @panic("Unexpected number of submitted sqes");
    }
    return @intFromPtr(data_ptr);
}
