const std = @import("std");
const builtin = @import("builtin");

const _Lock = enum {
    unlocked,
    locked,

    pub inline fn tryLock(self: *_Lock) bool {
        if (builtin.single_threaded) return true;
        return @cmpxchgStrong(_Lock, self, .unlocked, .locked, .acquire, .monotonic) == null;
    }

    pub inline fn lock(self: *_Lock) void {
        if (builtin.single_threaded) return;

        while (@cmpxchgWeak(_Lock, self, .unlocked, .locked, .acquire, .monotonic) != null) {
            std.atomic.spinLoopHint();
        }
    }

    pub inline fn unlock(self: *_Lock) void {
        if (builtin.single_threaded) return;

        @atomicStore(_Lock, self, .unlocked, .release);
    }
};

pub const Mutex = switch (builtin.mode) {
    .Debug => std.Thread.Mutex,
    else => _Lock,
};

pub inline fn init() Mutex {
    return switch (builtin.mode) {
        .Debug => std.Thread.Mutex{},
        else => _Lock.unlocked,
    };
}
