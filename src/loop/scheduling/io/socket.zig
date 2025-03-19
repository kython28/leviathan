const std = @import("std");

const CallbackManager = @import("callback_manager");
const IO = @import("main.zig");

pub const ConnectData = struct {
    callback: CallbackManager.Callback,
    address: *const std.net.Address,
    socket_fd: std.posix.fd_t
};

pub const ShutdownData = struct {
    socket_fd: std.posix.fd_t,
    how: u32
};

pub fn connect(ring: *std.os.linux.IoUring, set: *IO.BlockingTasksSet, data: ConnectData) !usize {
    const data_ptr = try set.push(.SocketConnect, &data.callback);
    errdefer data_ptr.discard();

    const sqe = try ring.connect(
        @intCast(@intFromPtr(data_ptr)), data.socket_fd, &data.address.any,
        data.address.getOsSockLen()
    );
    sqe.flags |= std.os.linux.IOSQE_ASYNC;

    const ret = try ring.submit();
    if (ret != 1) {
        return error.SQENotSubmitted;
    }
    return @intFromPtr(data_ptr);
}

pub fn shutdown(ring: *std.os.linux.IoUring, set: *IO.BlockingTasksSet, data: ShutdownData) !usize {
    const data_ptr = try set.push(.SocketShutdown, null);
    errdefer data_ptr.discard();

    const sqe = try ring.shutdown(@intCast(@intFromPtr(data_ptr)), data.socket_fd, data.how);
    sqe.flags |= std.os.linux.IOSQE_ASYNC;

    const ret = try ring.submit();
    if (ret != 1) {
        return error.SQENotSubmitted;
    }
    return @intFromPtr(data_ptr);
}
