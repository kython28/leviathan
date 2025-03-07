const Loop = @import("../main.zig");

const CallbackManager = @import("callback_manager");

const std = @import("std");
const builtin = @import("builtin");

inline fn unlock_epoll(self: *Loop) !void {
    const data: [8]u8 = .{1} ** 8;
    _ = try std.posix.write(self.unlock_epoll_fd, &data);
}

pub inline fn _dispatch(self: *Loop, callback: CallbackManager.Callback) !void {
    if (self.epoll_locked) {
        try unlock_epoll(self);
    }

    const ready_queue = &self.ready_tasks_queues[self.ready_tasks_queue_index];
    _ = try CallbackManager.append_new_callback(self.allocator, ready_queue, callback, Loop.MaxCallbacks);
}

pub inline fn _dispatch_threadsafe(self: *Loop, callback: CallbackManager.Callback) !void {
    const mutex = &self.mutex;
    mutex.lock();
    defer mutex.unlock();


    try _dispatch(self, callback);
}

pub const dispatch = if (builtin.single_threaded) _dispatch else _dispatch_threadsafe;
