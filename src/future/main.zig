const std = @import("std");
const Loop = @import("../loop/main.zig");

const python_c = @import("python_c");

pub const FutureStatus = enum {
    pending, finished, canceled
};

result: ?*anyopaque = null,
status: FutureStatus = .pending,

callbacks_arena: std.heap.ArenaAllocator,
callbacks_arena_allocator: std.mem.Allocator = undefined,

callbacks_queue: Callback.CallbacksSetData = undefined,
exceptions_queue: std.ArrayList(?*python_c.PyObject) = undefined,
loop: *Loop,

released: bool = false,


pub fn init(self: *Future, loop: *Loop) !void {
    try loop.reserve_slots(1);

    self.* = .{
        .loop = loop,
        .callbacks_arena = std.heap.ArenaAllocator.init(loop.allocator)
    };

    self.callbacks_arena_allocator = self.callbacks_arena.allocator();
    self.callbacks_queue = Callback.CallbacksSetData.init(self.callbacks_arena_allocator);
    self.exceptions_queue = std.ArrayList(?*python_c.PyObject).init(self.callbacks_arena_allocator);
}

pub fn release(self: *Future) void {
    if (self.status == .pending) {
        Callback.release_callbacks_queue(&self.callbacks_queue);
        self.loop.reserved_slots -= 1;
    }
    self.callbacks_arena.deinit();
    self.released = true;
}

pub const Callback = @import("callback.zig");
pub const Python = @import("python/main.zig");


const Future = @This();
