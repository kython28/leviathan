const Loop = @import("../main.zig");

const CallbackManager = @import("callback_manager");

const std = @import("std");

inline fn unlock_epoll(self: *Loop) !void {
    const data: [8]u8 = .{1} ** 8;
    _ = try std.posix.write(self.unlock_epoll_fd, &data);
}

pub inline fn dispatch_nonthreadsafe(self: *Loop, callback: *const CallbackManager.Callback) !void {
    if (self.epoll_locked) {
        try unlock_epoll(self);
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
    _ = ready_queue.try_append(callback) orelse unreachable;

    self.reserved_slots -= 1;
}

pub inline fn dispatch_guaranteed(self: *Loop, callback: *const CallbackManager.Callback) void {
    const mutex = &self.mutex;
    mutex.lock();
    defer mutex.unlock();

    dispatch_guaranteed_nonthreadsafe(self, callback);
}
