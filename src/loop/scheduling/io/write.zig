const std = @import("std");

const CallbackManager = @import("callback_manager");
const IO = @import("main.zig");

pub const PerformData = struct {
    fd: std.posix.fd_t,
    callback: CallbackManager.Callback,
    data: []const u8,
    offset: usize = 0,
    timeout: ?std.os.linux.kernel_timespec = null,
    zero_copy: bool = false
};

pub const PerformVData = struct {
    fd: std.posix.fd_t,
    callback: CallbackManager.Callback,
    data: []const std.posix.iovec_const,
    offset: usize = 0,
    timeout: ?std.os.linux.kernel_timespec = null,
    zero_copy: bool = false
};

pub fn wait_ready(set: *IO.BlockingTasksSet, data: IO.WaitData) !usize {
    const data_ptr = try set.push(.WaitWritable, data.callback);
    errdefer set.pop(data_ptr);

    const ring: *std.os.linux.IoUring = &set.ring;
    const sqe = try ring.poll_add(@intCast(@intFromPtr(data_ptr)), data.fd, std.c.POLL.OUT);
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

pub fn perform(set: *IO.BlockingTasksSet, data: PerformData) !usize {
    const data_ptr = try set.push(.PerformWrite, data.callback);
    errdefer set.pop(data_ptr);

    const ring = &set.ring;
    const sqe = blk: {
        if (data.zero_copy) {
            const iovecs: [1]std.posix.iovec_const = .{
                std.posix.iovec_const{
                    .base = data.data.ptr,
                    .len = data.data.len
                }
            };
            var msghr = comptime std.mem.zeroes(std.posix.msghdr_const);
            msghr.iov = &iovecs;
            msghr.iovlen = 1;

            break :blk try ring.sendmsg(@intCast(@intFromPtr(data_ptr)), data.fd, &msghr, std.posix.MSG.ZEROCOPY);
        }
        break :blk try ring.write(@intCast(@intFromPtr(data_ptr)), data.fd, data.data, data.offset);
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

pub fn perform_with_iovecs(set: *IO.BlockingTasksSet, data: PerformVData) !usize {
    const data_ptr = try set.push(.PerformWriteV, data.callback);
    errdefer set.pop(data_ptr);

    const ring = &set.ring;
    const sqe = blk: {
        if (data.zero_copy) {
            var msghr = comptime std.mem.zeroes(std.posix.msghdr_const);
            msghr.iov = data.data.ptr;
            msghr.iovlen = @intCast(data.data.len);

            break :blk try ring.sendmsg(@intCast(@intFromPtr(data_ptr)), data.fd, &msghr, std.posix.MSG.ZEROCOPY);
        }
        break :blk try ring.writev(@intCast(@intFromPtr(data_ptr)), data.fd, data.data, data.offset);
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
