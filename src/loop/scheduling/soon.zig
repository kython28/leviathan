const Loop = @import("../main.zig");

const CallbackManager = @import("callback_manager");

pub inline fn dispatch_nonthreadsafe(self: *Loop, callback: *const CallbackManager.Callback) !void {
    if (self.io.ring_blocked) {
        try self.io.wakeup_eventfd();
    }

    const ready_queue = &self.ready_tasks_queues[self.ready_tasks_queue_index];
    _ = try ready_queue.append(callback, @max(1, self.reserved_slots));
}

pub inline fn dispatch(self: *Loop, callback: *const CallbackManager.Callback) !void {
    const mutex = &self.mutex;
    mutex.lock();
    defer mutex.unlock();

    try dispatch_nonthreadsafe(self, callback);
}

pub inline fn dispatch_guaranteed_nonthreadsafe(self: *Loop, callback: *const CallbackManager.Callback) void {
    const ready_queue = &self.ready_tasks_queues[self.ready_tasks_queue_index];

    self.reserved_slots -= 1;

    _ = ready_queue.try_append(callback) orelse @panic("Trying to add a callback without available space");
}

pub inline fn dispatch_guaranteed(self: *Loop, callback: *const CallbackManager.Callback) void {
    const mutex = &self.mutex;
    mutex.lock();
    defer mutex.unlock();

    dispatch_guaranteed_nonthreadsafe(self, callback);
}
