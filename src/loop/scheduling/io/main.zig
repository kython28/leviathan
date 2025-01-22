const std = @import("std");
const builtin = @import("builtin");

const linked_list =  @import("../../../utils/linked_list.zig");
pub const BlockingTasksSetLinkedList = linked_list.init(*BlockingTasksSet);
pub const BlockingTaskDataLinkedList = linked_list.init(BlockingTaskData);

const CallbackManger = @import("../../../callback_manager.zig");
const Loop = @import("../../main.zig");

pub const Read = @import("read.zig");
pub const Write = @import("write.zig");
pub const Timer = @import("timer.zig");

pub const BlockingTaskData = CallbackManger.Callback;

pub const TotalItems = 1024;

pub const BlockingTasksSet = struct {
    allocator: std.mem.Allocator,
    ring: std.os.linux.IoUring,
    tasks_data: BlockingTaskDataLinkedList,
    free_items: BlockingTaskDataLinkedList,

    eventfd: std.posix.fd_t,

    node: BlockingTasksSetLinkedList.Node,

    pub fn init(allocator: std.mem.Allocator, node: BlockingTasksSetLinkedList.Node) !*BlockingTasksSet {
        const set = allocator.create(BlockingTasksSet) catch unreachable;
        errdefer allocator.destroy(set);

        const eventfd = try std.posix.eventfd(0, std.os.linux.EFD.NONBLOCK|std.os.linux.EFD.CLOEXEC);
        errdefer std.posix.close(eventfd);

        set.* = .{
            .allocator = allocator,
            .ring = try std.os.linux.IoUring.init(TotalItems, 0),
            .tasks_data = BlockingTaskDataLinkedList.init(allocator),
            .free_items = BlockingTaskDataLinkedList.init(allocator),
            .node = node,
            .eventfd = eventfd
        };
        errdefer set.ring.deinit();

        try set.ring.register_eventfd(eventfd);
        errdefer {
            while (set.free_items.len > 0) {
                _ = set.free_items.pop() catch unreachable;
            }
        }

        for (0..TotalItems) |_| {
            try set.free_items.append(undefined);
        }

        node.data = set;
        return set;
    }

    pub fn deinit(self: *BlockingTasksSet) BlockingTasksSetLinkedList.Node {
        if (self.tasks_data.len > 0) {
            @panic("Free items count is not equal to total items");
        }

        while (self.free_items.len > 0) {
            _ = self.free_items.pop() catch unreachable;
        }

        const node = self.node;

        self.ring.deinit();
        std.posix.close(self.eventfd);
        self.allocator.destroy(self);
        return node;
    }

    pub fn push(self: *BlockingTasksSet, data: CallbackManger.Callback) !BlockingTaskDataLinkedList.Node {
        const free_items = &self.free_items;
        if (free_items.len == 0) {
            return error.NoFreeItems;
        }

        const node = try free_items.popleft_node();
        node.data = data;
        self.tasks_data.append_node(node);

        return node;
    }

    pub inline fn pop(self: *BlockingTasksSet, node: BlockingTaskDataLinkedList.Node) !void {
        const tasks_data = &self.tasks_data;
        if (tasks_data.len == 0) {
            return error.NoBusyItems;
        }

        try tasks_data.unlink_node(node);
        self.free_items.append_node(node);
    }

    pub fn cancel_all(self: *BlockingTasksSet, loop: *Loop) !void {
        while (self.tasks_data.len > 0) {
            var callback = try self.tasks_data.pop();
            CallbackManger.cancel_callback(&callback, true);

            try Loop.Scheduling.Soon.dispatch(loop, callback);
        }
    }
};

pub const BlockingOperation = enum {
    WaitReadable,
    WaitWritable,
    PerformRead,
    PerformWrite,
    WaitTimer
};

pub const WaitData = struct {
    callback: CallbackManger.Callback,
    fd: std.os.linux.fd_t
};

pub const BlockingOperationData = union(BlockingOperation) {
    WaitReadable: WaitData,
    WaitWritable: WaitData,
    PerformRead: Read.PerformData,
    PerformWrite: Write.PerformData,
    WaitTimer: Timer.WaitData
};

inline fn get_blocking_tasks_set(
    allocator: std.mem.Allocator, epoll_fd: std.posix.fd_t,
    blocking_tasks_queue: *BlockingTasksSetLinkedList
) !*BlockingTasksSet {
    if (blocking_tasks_queue.last) |node| {
        const set: *BlockingTasksSet = node.data;
        if (set.free_items.len > 0) {
            return set;
        }
    }

    const new_node = try blocking_tasks_queue.create_new_node(undefined);
    errdefer blocking_tasks_queue.release_node(new_node);

    const new_set = try BlockingTasksSet.init(allocator, new_node);
    errdefer {
        _ = new_set.deinit();
        blocking_tasks_queue.unlink_node(new_node) catch unreachable;
        blocking_tasks_queue.release_node(new_node);
    }

    var epoll_event: std.os.linux.epoll_event = .{
        .events = std.os.linux.EPOLL.IN | std.os.linux.EPOLL.ET,
        .data = std.os.linux.epoll_data{
            .ptr = @intFromPtr(new_set)
        }
    };

    blocking_tasks_queue.append_node(new_node);
    errdefer _ = blocking_tasks_queue.pop_node() catch unreachable;

    try std.posix.epoll_ctl(epoll_fd, std.os.linux.EPOLL.CTL_ADD, new_set.eventfd, &epoll_event);
    return new_set;
}

pub inline fn remove_tasks_set(
    epoll_fd: std.posix.fd_t, blocking_tasks_queue: *BlockingTasksSetLinkedList,
    blocking_tasks_set: *BlockingTasksSet
) void {
    std.posix.epoll_ctl(epoll_fd, std.os.linux.EPOLL.CTL_DEL, blocking_tasks_set.eventfd, null) catch unreachable;
    const node = blocking_tasks_set.deinit();
    blocking_tasks_queue.unlink_node(node) catch unreachable;
    blocking_tasks_queue.release_node(node);
}

pub fn queue(self: *Loop, event: BlockingOperationData) !void {
    const blocking_tasks_queue = &self.blocking_tasks_queue;
    const epoll_fd = self.blocking_tasks_epoll_fd;
    const blocking_tasks_set = try get_blocking_tasks_set(
        self.allocator, epoll_fd, blocking_tasks_queue
    );
    errdefer {
        if (blocking_tasks_set.tasks_data.len > 0) {
            remove_tasks_set(epoll_fd, blocking_tasks_queue, blocking_tasks_set);
        }
    }

    switch (event) {
        .WaitReadable => |data| try Read.wait_ready(blocking_tasks_set, data),
        .WaitWritable => |data| try Write.wait_ready(blocking_tasks_set, data),
        .PerformRead => |data| try Read.perform(blocking_tasks_set, data),
        .PerformWrite => |data| try Write.perform(blocking_tasks_set, data),
        .WaitTimer => |data| try Timer.wait(blocking_tasks_set, data),
    }
}
