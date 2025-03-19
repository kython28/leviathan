const std = @import("std");

const CallbackManager = @import("callback_manager");

const Handle = @import("../handle.zig");


pub const FDWatcher = struct {
    handle: *Handle.PythonHandleObject,
    loop_data: *Loop,
    blocking_task_id: usize = 0,
    event_type: u32,
    fd: std.posix.fd_t
};

const utils = @import("utils");
const WatchersBTree = utils.BTree(std.posix.fd_t, *FDWatcher, 11);

const lock = @import("../utils/lock.zig");

allocator: std.mem.Allocator,

ready_tasks_queue_index: u8 = 0,

ready_tasks_queues: [2]CallbackManager.CallbacksSetsQueue,
reserved_slots: usize = 0,

io: Scheduling.IO,

reader_watchers: WatchersBTree,
writer_watchers: WatchersBTree,

ready_tasks_queue_max_capacity: usize,

mutex: lock.Mutex,

unix_signals: UnixSignals,

running: bool = false,
stopping: bool = false,
initialized: bool = false,


pub fn init(self: *Loop, allocator: std.mem.Allocator, rtq_max_capacity: usize) !void {
    if (self.initialized) {
        @panic("Loop is already initialized");
    }

    var reader_watchers = try WatchersBTree.init(allocator);
    errdefer reader_watchers.deinit() catch |err| {
        std.debug.panic("Unexpected error while releasing reader watchers: {s}", .{@errorName(err)});
    };

    var writer_watchers = try WatchersBTree.init(allocator);
    errdefer writer_watchers.deinit() catch |err| {
        std.debug.panic("Unexpected error while releasing writer watchers: {s}", .{@errorName(err)});
    };

    self.* = .{
        .allocator = allocator,
        .mutex = lock.init(),
        .ready_tasks_queues = .{
            CallbackManager.CallbacksSetsQueue.init(allocator),
            CallbackManager.CallbacksSetsQueue.init(allocator)
        },
        .ready_tasks_queue_max_capacity = rtq_max_capacity / @sizeOf(CallbackManager.Callback),
        .reader_watchers = reader_watchers,
        .writer_watchers = writer_watchers,
        .unix_signals = undefined,
        .io = undefined
    };

    try self.io.init(self, allocator);
    errdefer self.io.deinit();

    try self.io.register_eventfd_callback();

    try UnixSignals.init(self);
    errdefer self.unix_signals.deinit();

    self.initialized = true;
}

pub fn release(self: *Loop) void {
    if (self.running) {
        @panic("Loop is running, can't be deallocated");
    }

    self.io.deinit();
    self.unix_signals.deinit();

    const allocator = self.allocator;
    for (&self.ready_tasks_queues) |*ready_tasks_queue| {
        CallbackManager.release_sets_queue(allocator, ready_tasks_queue);
    }

    self.reader_watchers.deinit() catch |err| {
        std.debug.panic("Unexpected error while releasing reader watchers: {s}", .{@errorName(err)});
    };
    self.writer_watchers.deinit() catch |err| {
        std.debug.panic("Unexpected error while releasing writer watchers: {s}", .{@errorName(err)});
    };

    self.initialized = false;
}

pub inline fn reserve_slots(self: *Loop, amount: usize) !void {
    const new_value = self.reserved_slots + amount;
    try self.ready_tasks_queues[self.ready_tasks_queue_index].ensure_capacity(new_value);
    self.reserved_slots = new_value;
}

pub const Runner = @import("runner.zig");
pub const Scheduling = @import("scheduling/main.zig");
pub const UnixSignals = @import("unix_signals.zig");
pub const Python = @import("python/main.zig");
// pub const DNS = @import("dns/main.zig");

const Loop = @This();
