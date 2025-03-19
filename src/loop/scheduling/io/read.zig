const std = @import("std");

const CallbackManager = @import("callback_manager");
const IO = @import("main.zig");

pub const PerformData = struct {
    fd: std.posix.fd_t,
    callback: CallbackManager.Callback,
    data: std.os.linux.IoUring.ReadBuffer,
    offset: usize = 0,
    timeout: ?std.os.linux.kernel_timespec = null,
    zero_copy: bool = false
};

pub fn wait_ready(ring: *std.os.linux.IoUring, set: *IO.BlockingTasksSet, data: IO.WaitData) !usize {
    const data_ptr = try set.push(.WaitReadable, &data.callback);
    errdefer data_ptr.discard();

    const sqe = try ring.poll_add(@intCast(@intFromPtr(data_ptr)), data.fd, std.c.POLL.IN);
    sqe.flags |= std.os.linux.IOSQE_ASYNC;

    var expected_submission: u32 = 1;
    if (data.timeout) |*timeout| {
        sqe.flags |= std.os.linux.IOSQE_IO_LINK;
        const timeout_sqe = try ring.link_timeout(0, timeout, 0);
        timeout_sqe.flags |= std.os.linux.IOSQE_ASYNC;
        expected_submission += 1;
    }

    const ret = try ring.submit();
    if (ret != expected_submission) {
        return error.SQENotSubmitted;
    }
    return @intFromPtr(data_ptr);
}

pub fn perform(ring: *std.os.linux.IoUring, set: *IO.BlockingTasksSet, data: PerformData) !usize {
    const data_ptr = try set.push(.PerformRead, &data.callback);
    errdefer data_ptr.discard();

    const sqe = blk: {
        if (data.zero_copy) {
            var msghr = comptime std.mem.zeroes(std.posix.msghdr);

            switch (data.data) {
                .buffer_selection => @panic("TODO"),
                .iovecs => |iovecs| {
                    msghr.iov = @constCast(iovecs.ptr);
                    msghr.iovlen = @intCast(iovecs.len);
                },
                .buffer => |buffer| {
                    const iovecs: [1]std.posix.iovec = .{
                        std.posix.iovec{
                            .base = buffer.ptr,
                            .len = buffer.len
                        }
                    };
                    msghr.iov = @constCast(&iovecs);
                    msghr.iovlen = 1;
                }
            }

            break :blk try ring.recvmsg(@intCast(@intFromPtr(data_ptr)), data.fd, &msghr, std.posix.MSG.ZEROCOPY);
        }
        break :blk try ring.read(@intCast(@intFromPtr(data_ptr)), data.fd, data.data, data.offset);
    };
    sqe.flags |= std.os.linux.IOSQE_ASYNC;

    var expected_submission: u32 = 1;
    if (data.timeout) |*timeout| {
        sqe.flags |= std.os.linux.IOSQE_IO_LINK;
        const timeout_sqe = try ring.link_timeout(0, timeout, 0);
        timeout_sqe.flags |= std.os.linux.IOSQE_ASYNC;
        expected_submission += 1;
    }

    const ret = try ring.submit();
    if (ret != expected_submission) {
        return error.SQENotSubmitted;
    }
    return @intFromPtr(data_ptr);
}
