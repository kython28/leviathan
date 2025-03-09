const std = @import("std");

const CallbackManager = @import("callback_manager");
const IO = @import("main.zig");

pub fn perform(task_id: usize) !usize {
    const task_data: *IO.BlockingTaskData = @ptrFromInt(task_id);

    const set_address = task_id - @offsetOf(IO.BlockingTasksSet, "task_data_pool") - @as(usize, task_data.index) * @sizeOf(IO.BlockingTaskData);
    const set: *IO.BlockingTasksSet = @ptrFromInt(set_address); // Cancel requests must be in same IOUring ring

    const data_ptr = try set.push(.Cancel, null);
    errdefer set.pop(data_ptr);

    const ring: *std.os.linux.IoUring = &set.ring;
    if (task_data.operation == .WaitTimer) {
        _ = try ring.timeout_remove(@intCast(@intFromPtr(data_ptr)), task_id, 0);
    }else{
        _ = try ring.cancel(@intCast(@intFromPtr(data_ptr)), task_id, 0);
    }

    const ret = try ring.submit();
    if (ret != 1) {
        return error.SQENotSubmitted;
    }
    return @intFromPtr(data_ptr);
}
