const std = @import("std");
const builtin = @import("builtin");

const CallbackManager = @import("callback_manager");
const python_c = @import("python_c");

const Handle = @import("../handle.zig");


const CallbacksSetLinkedList = CallbackManager.CallbacksSetLinkedList;
const BlockingTasksSetLinkedList = Scheduling.IO.BlockingTasksSetLinkedList;

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

pub const MaxCallbacks = switch (builtin.mode) {
    .Debug => 128,//4,
    else => 128
};

allocator: std.mem.Allocator,

ready_tasks_queue_index: u8 = 0,

ready_tasks_queues: [2]CallbackManager.CallbacksSetsQueue,

blocking_tasks_epoll_fd: std.posix.fd_t = -1,
blocking_ready_epoll_events: []std.os.linux.epoll_event,
available_blocking_tasks_queue: BlockingTasksSetLinkedList,
busy_blocking_tasks_queue: BlockingTasksSetLinkedList,
blocking_ready_tasks: []std.os.linux.io_uring_cqe,

reader_watchers: WatchersBTree,
writer_watchers: WatchersBTree,

unlock_epoll_fd: std.posix.fd_t = -1,
epoll_locked: bool = false,

max_callbacks_sets_per_queue: [2]usize,
ready_tasks_queue_min_bytes_capacity: usize,

mutex: lock.Mutex,

unix_signals: UnixSignals,

running: bool = false,
stopping: bool = false,
initialized: bool = false,


pub fn init(self: *Loop, allocator: std.mem.Allocator, rtq_min_capacity: usize) !void {
    if (self.initialized) {
        @panic("Loop is already initialized");
    }

    const max_callbacks_sets_per_queue = CallbackManager.get_max_callbacks_sets(
        rtq_min_capacity, MaxCallbacks
    );

    const blocking_ready_tasks = try allocator.alloc(std.os.linux.io_uring_cqe, Scheduling.IO.TotalTasksItems * 2);
    errdefer allocator.free(blocking_ready_tasks);

    const blocking_ready_epoll_events = try allocator.alloc(std.os.linux.epoll_event, switch (builtin.mode) {
        .Debug => 256,//8,
        else => 256
    });
    errdefer allocator.free(blocking_ready_epoll_events);

    const unlock_epoll_fd = try std.posix.eventfd(0, std.os.linux.EFD.NONBLOCK|std.os.linux.EFD.CLOEXEC);
    errdefer std.posix.close(unlock_epoll_fd);

    const blocking_tasks_epoll_fd = try std.posix.epoll_create1(0);
    errdefer std.posix.close(blocking_tasks_epoll_fd);

    var reader_watchers = try WatchersBTree.init(allocator);
    errdefer reader_watchers.deinit() catch unreachable;

    var writer_watchers = try WatchersBTree.init(allocator);
    errdefer writer_watchers.deinit() catch unreachable;

    self.* = .{
        .allocator = allocator,
        .mutex = lock.init(),
        .ready_tasks_queues = .{
            .{
                .queue = CallbacksSetLinkedList.init(allocator),
            },
            .{
                .queue = CallbacksSetLinkedList.init(allocator),
            },
        },
        .max_callbacks_sets_per_queue = .{
            max_callbacks_sets_per_queue,
            max_callbacks_sets_per_queue,
        },
        .ready_tasks_queue_min_bytes_capacity = rtq_min_capacity,
        .available_blocking_tasks_queue = BlockingTasksSetLinkedList.init(allocator),
        .busy_blocking_tasks_queue = BlockingTasksSetLinkedList.init(allocator),
        .blocking_ready_tasks = blocking_ready_tasks,
        .blocking_tasks_epoll_fd = try std.posix.epoll_create1(0),
        .blocking_ready_epoll_events = blocking_ready_epoll_events,
        .reader_watchers = reader_watchers,
        .writer_watchers = writer_watchers,
        .unix_signals = undefined,
        .unlock_epoll_fd = unlock_epoll_fd
    };
    errdefer {
        std.posix.close(self.blocking_tasks_epoll_fd);
    }

    try UnixSignals.init(self);

    self.initialized = true;

    var epoll_event: std.os.linux.epoll_event = .{
        .events = std.os.linux.EPOLL.IN | std.os.linux.EPOLL.ET,
        .data = std.os.linux.epoll_data{
            .ptr = 0
        }
    };

    try std.posix.epoll_ctl(self.blocking_tasks_epoll_fd, std.os.linux.EPOLL.CTL_ADD, unlock_epoll_fd, &epoll_event);
}

pub fn release(self: *Loop) void {
    if (self.running) {
        @panic("Loop is running, can't be deallocated");
    }

    const allocator = self.allocator;
    const available_blocking_tasks_queue = &self.available_blocking_tasks_queue;
    for (0..available_blocking_tasks_queue.len) |_| {
        const set = available_blocking_tasks_queue.pop() catch unreachable;
        set.cancel_all(self) catch unreachable;
        set.deinit(false);
    }

    const busy_blocking_tasks_queue = &self.busy_blocking_tasks_queue;
    for (0..busy_blocking_tasks_queue.len) |_| {
        const set = busy_blocking_tasks_queue.pop() catch unreachable;
        set.cancel_all(self) catch unreachable;
        set.deinit(false);
    }

    self.unix_signals.deinit() catch unreachable;

    for (&self.ready_tasks_queues) |*ready_tasks_queue| {
        CallbackManager.release_sets_queue(allocator, ready_tasks_queue);
    }

    self.reader_watchers.deinit() catch unreachable;
    self.writer_watchers.deinit() catch unreachable;

    if (self.blocking_tasks_epoll_fd != -1) {
        std.posix.close(self.blocking_tasks_epoll_fd);
    }

    if (self.unlock_epoll_fd != -1) {
        std.posix.close(self.unlock_epoll_fd);
    }

    allocator.free(self.blocking_ready_epoll_events);
    allocator.free(self.blocking_ready_tasks);

    self.initialized = false;
}

pub const Runner = @import("runner.zig");
pub const Scheduling = @import("scheduling/main.zig");
pub const UnixSignals = @import("unix_signals.zig");
pub const Python = @import("python/main.zig");
// pub const DNS = @import("dns/main.zig");

const Loop = @This();
