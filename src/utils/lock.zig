const std = @import("std");
const builtin = @import("builtin");

const DummyLock = struct {
    pub inline fn tryLock(_: *DummyLock) bool {
        return true;
    }

    pub inline fn lock(_: *DummyLock) void {}
    pub inline fn unlock(_: *DummyLock) void {}
};

pub const Mutex = switch (builtin.mode) {
    .Debug => std.Thread.Mutex,
    else => if (builtin.single_threaded) DummyLock else std.Thread.Mutex,
};

pub inline fn init() Mutex {
    return switch (builtin.mode) {
        .Debug => std.Thread.Mutex{},
        else => if (builtin.single_threaded) DummyLock{} else std.Thread.Mutex{},
    };
}
