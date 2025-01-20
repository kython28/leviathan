const std = @import("std");

const CallbackManager = @import("../../../callback_manager.zig");
const IO = @import("main.zig");

pub fn perform(set: *IO.BlockingTasksSet, task_id: usize) !usize {
    const data_ptr = try set.push(.Cancel, null);
    errdefer set.pop(data_ptr) catch unreachable;

    // TODO: Cancel should perform in same ring of task_id
    const ring: *std.os.linux.IoUring = &set.ring;
    const task_data: IO.BlockingTaskDataLinkedList.Node = @ptrFromInt(task_id);
    if (task_data.data.operation == .WaitTimer) {
        _ = try ring.timeout_remove(@intCast(@intFromPtr(data_ptr)), task_id, 0);
    }else{
        _ = try ring.cancel(@intCast(@intFromPtr(data_ptr)), task_id, 0);
    }

    const ret = try ring.submit();
    if (ret != 1) {
        @panic("Unexpected number of submitted sqes");
    }
    return @intFromPtr(data_ptr);
}
