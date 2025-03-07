const std = @import("std");

const CallbackManager = @import("callback_manager");
const IO = @import("main.zig");

pub const DelayType = enum(u32) {
    Relative = 0,
    Absolute = std.os.linux.IORING_TIMEOUT_ABS
};

pub const WaitData = struct {
    callback: CallbackManager.Callback,
    duration: std.os.linux.timespec,
    delay_type: DelayType
};

pub fn wait(set: *IO.BlockingTasksSet, data: WaitData) !usize {
    const data_ptr = try set.push(.WaitTimer, data.callback);
    errdefer set.pop(data_ptr);

    const ring: *std.os.linux.IoUring = &set.ring;

    const timespec_sec_info = @typeInfo(@FieldType(std.os.linux.timespec, "sec")).int;
    const kernel_timespec_sec_info = @typeInfo(@FieldType(std.os.linux.kernel_timespec, "sec")).int;
    if (
        timespec_sec_info.bits == kernel_timespec_sec_info.bits and
        timespec_sec_info.signedness == kernel_timespec_sec_info.signedness
    ) {
        const sqe = try ring.timeout(
            @intCast(@intFromPtr(data_ptr)),
            @ptrCast(&data.duration), 0,
            @intFromEnum(data.delay_type)
        );
        sqe.flags |= std.os.linux.IOSQE_ASYNC;
    }else{
        const k_duration: std.os.linux.kernel_timespec = .{
            .sec = data.duration.tv_sec,
            .nsec = data.duration.tv_nsec
        };

        const sqe = try ring.timeout(
            @intCast(@intFromPtr(data_ptr)),
            &k_duration, 0,
            @intFromEnum(data.delay_type)
        );
        sqe.flags |= std.os.linux.IOSQE_ASYNC;
    }

    const ret = try ring.submit();
    if (ret != 1) {
        return error.SQENotSubmitted;
    }

    return @intFromPtr(data_ptr);
}
