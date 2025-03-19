const std = @import("std");
const IO = @import("main.zig");

pub fn perform(ring: *std.os.linux.IoUring, task_id: usize) !usize {
    const task: *IO.BlockingTask= @ptrFromInt(task_id);

    if (task.operation == .WaitTimer) {
        _ = try ring.timeout_remove(0, task_id, 0);
    }else{
        _ = try ring.cancel(0, task_id, 0);
    }

    const ret = try ring.submit();
    if (ret != 1) {
        return error.SQENotSubmitted;
    }
    return 0;
}
