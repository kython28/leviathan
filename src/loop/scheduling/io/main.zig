const std = @import("std");
const builtin = @import("builtin");

const utils =  @import("utils");

pub const BlockingTasksSetLinkedList = utils.LinkedList(*BlockingTasksSet);
pub const BlockingTaskDataLinkedList = utils.LinkedList(BlockingTaskData);

const CallbackManger = @import("../../../callback_manager.zig");
const Loop = @import("../../main.zig");

pub const Read = @import("read.zig");
pub const Write = @import("write.zig");
pub const Timer = @import("timer.zig");
pub const Cancel = @import("cancel.zig");
pub const Socket = @import("socket.zig");

pub const BlockingTaskData = struct {
    callback_data: ?CallbackManger.Callback,
    set: *BlockingTasksSet, // Cancel helper
    operation: BlockingOperation
};

pub const TotalItems = switch (builtin.mode) {
    .Debug => 4,
    else => 8192
};

pub const BlockingTasksSet = struct {
    allocator: std.mem.Allocator,
    ring: std.os.linux.IoUring,

    tasks_data: BlockingTaskDataLinkedList,
    free_items: BlockingTaskDataLinkedList,
    free_cancel_items: BlockingTaskDataLinkedList,

    quarantine_items: BlockingTaskDataLinkedList,
    quarantine_cancel_items: BlockingTaskDataLinkedList,

    eventfd: std.posix.fd_t,

    available_blocking_tasks_queue: *BlockingTasksSetLinkedList,
    busy_blocking_tasks_queue: *BlockingTasksSetLinkedList,
    node: BlockingTasksSetLinkedList.Node,

    pub fn init(
        allocator: std.mem.Allocator, available_blocking_tasks_queue: *BlockingTasksSetLinkedList,
        busy_blocking_tasks_queue: *BlockingTasksSetLinkedList, node: BlockingTasksSetLinkedList.Node
    ) !*BlockingTasksSet {
        const set = allocator.create(BlockingTasksSet) catch unreachable;
        errdefer allocator.destroy(set);

        const eventfd = try std.posix.eventfd(0, std.os.linux.EFD.NONBLOCK|std.os.linux.EFD.CLOEXEC);
        errdefer std.posix.close(eventfd);

        set.* = BlockingTasksSet{
            .allocator = allocator,
            .ring = try std.os.linux.IoUring.init(TotalItems * 2, 0),
            .tasks_data = BlockingTaskDataLinkedList.init(allocator),

            .free_items = BlockingTaskDataLinkedList.init(allocator),
            .free_cancel_items = BlockingTaskDataLinkedList.init(allocator),

            .quarantine_items = BlockingTaskDataLinkedList.init(allocator),
            .quarantine_cancel_items = BlockingTaskDataLinkedList.init(allocator),

            .node = node,
            .available_blocking_tasks_queue = available_blocking_tasks_queue,
            .busy_blocking_tasks_queue = busy_blocking_tasks_queue,
            .eventfd = eventfd
        };
        errdefer set.ring.deinit();

        try set.ring.register_eventfd(eventfd);

        const free_items = &set.free_items;
        const free_cancel_items = &set.free_cancel_items;
        errdefer {
            free_items.clear();
            free_cancel_items.clear();
        }

        for (0..TotalItems) |_| {
            try free_items.append(.{
                .callback_data = null,
                .set = set,
                .operation = undefined
            });

            try free_cancel_items.append(.{
                .callback_data = null,
                .set = set,
                .operation = undefined
            });
        }

        node.data = set;
        return set;
    }

    pub fn deinit(self: *BlockingTasksSet, comptime can_release_node: bool) void {
        if (self.tasks_data.len > 0) {
            @panic("Tasks set is not empty");
        }

        if (can_release_node) {
            const node = self.node;
            const available_blocking_tasks_queue = self.available_blocking_tasks_queue;
            if (self.free_items.len > 0) {
                available_blocking_tasks_queue.unlink_node(node);
            }else if (self.quarantine_items.len > 0) {
                self.busy_blocking_tasks_queue.unlink_node(node);
            }

            available_blocking_tasks_queue.release_node(node);
        }

        self.free_items.clear();
        self.free_cancel_items.clear();

        self.quarantine_cancel_items.clear();
        self.quarantine_items.clear();

        self.ring.deinit();
        std.posix.close(self.eventfd);
        self.allocator.destroy(self);
    }

    pub fn push(
        self: *BlockingTasksSet, operation: BlockingOperation,
        data: ?CallbackManger.Callback
    ) !BlockingTaskDataLinkedList.Node {
        const free_items = switch (operation) {
            .Cancel => &self.free_cancel_items,
            else => &self.free_items
        };

        const free_items_len = free_items.len;
        if (free_items_len == 0) {
            return error.NoFreeItems;
        }

        const node = try free_items.popleft_node();
        node.data = .{
            .callback_data = data,
            .set = self,
            .operation = operation
        };
        self.tasks_data.append_node(node);

        if (operation != .Cancel and free_items_len == 1) {
            self.available_blocking_tasks_queue.unlink_node(self.node);
            self.busy_blocking_tasks_queue.append_node(self.node);
        }

        return node;
    }

    pub fn pop(self: *BlockingTasksSet, node: BlockingTaskDataLinkedList.Node) void {
        const tasks_data = &self.tasks_data;
        tasks_data.unlink_node(node);

        switch (node.data.operation) {
            .Cancel => self.free_cancel_items.append_node(node),
            else => {
                const free_items = &self.free_items;
                free_items.append_node(node);
                if (free_items.len == 1) {
                    self.busy_blocking_tasks_queue.unlink_node(self.node);
                    self.available_blocking_tasks_queue.append_node(self.node);
                }
            },
        }
    }

    pub inline fn push_in_quarantine(self: *BlockingTasksSet, node: BlockingTaskDataLinkedList.Node) void {
        const tasks_data = &self.tasks_data;
        tasks_data.unlink_node(node);

        const free_items = switch (node.data.operation) {
            .Cancel => &self.quarantine_cancel_items,
            else => &self.quarantine_items
        };

        free_items.append_node(node);
    }

    pub inline fn clear_quarantine(self: *BlockingTasksSet) void {
        const free_items = &self.free_items;
        const quarantine_items = &self.quarantine_items;
        if (quarantine_items.len > 0) {
            if (free_items.len == 0) {
                self.busy_blocking_tasks_queue.unlink_node(self.node);
                self.available_blocking_tasks_queue.append_node(self.node);
            }

            free_items.extend(&self.quarantine_items);
        }

        self.free_cancel_items.extend(&self.quarantine_cancel_items);
    }

    pub fn cancel_all(self: *BlockingTasksSet, loop: *Loop) !void {
        const allocator = self.allocator;
        var node = self.tasks_data.first;

        errdefer {
            self.tasks_data.first = node;
            if (node) |n| {
                n.prev = null;
            }
        }

        while (node) |n| {
            node = n.next;
            defer allocator.destroy(n);

            var task_data = n.data;
            if (task_data.callback_data) |*callback| {
                CallbackManger.cancel_callback(callback, true);
                try Loop.Scheduling.Soon.dispatch(loop, callback.*);
            }
        }

        self.tasks_data = BlockingTaskDataLinkedList.init(allocator);
    }
};

pub const BlockingOperation = enum {
    WaitReadable,
    WaitWritable,
    PerformRead,
    PerformWrite,
    PerformWriteV,
    WaitTimer,
    Cancel,
    SocketShutdown
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
    PerformWriteV: Write.PerformVData,
    WaitTimer: Timer.WaitData,
    Cancel: usize,
    SocketShutdown: Socket.ShutdownData,
};

inline fn get_blocking_tasks_set(
    allocator: std.mem.Allocator, epoll_fd: std.posix.fd_t,
    available_blocking_tasks_queue: *BlockingTasksSetLinkedList,
    busy_blocking_tasks_queue: *BlockingTasksSetLinkedList
) !*BlockingTasksSet {
    if (available_blocking_tasks_queue.first) |node| {
        return node.data;
    }

    const new_node = try available_blocking_tasks_queue.create_new_node(undefined);
    errdefer available_blocking_tasks_queue.release_node(new_node);

    const new_set = try BlockingTasksSet.init(
        allocator, available_blocking_tasks_queue, busy_blocking_tasks_queue, new_node
    );
    errdefer new_set.deinit(false);

    var epoll_event: std.os.linux.epoll_event = .{
        .events = std.os.linux.EPOLL.IN | std.os.linux.EPOLL.ET,
        .data = std.os.linux.epoll_data{
            .ptr = @intFromPtr(new_set)
        }
    };

    available_blocking_tasks_queue.append_node(new_node);
    errdefer _ = available_blocking_tasks_queue.pop_node() catch unreachable;

    try std.posix.epoll_ctl(epoll_fd, std.os.linux.EPOLL.CTL_ADD, new_set.eventfd, &epoll_event);
    return new_set;
}

pub inline fn remove_tasks_set(epoll_fd: std.posix.fd_t, blocking_tasks_set: *BlockingTasksSet) void {
    std.posix.epoll_ctl(epoll_fd, std.os.linux.EPOLL.CTL_DEL, blocking_tasks_set.eventfd, null) catch unreachable;
    blocking_tasks_set.deinit(true);
}

pub fn queue(self: *Loop, event: BlockingOperationData) !usize {
    if (event == .Cancel) {
        return try Cancel.perform(event.Cancel);
    }

    const epoll_fd = self.blocking_tasks_epoll_fd;
    const blocking_tasks_set = try get_blocking_tasks_set(
        self.allocator, epoll_fd, &self.available_blocking_tasks_queue,
        &self.busy_blocking_tasks_queue

    );
    errdefer {
        if (blocking_tasks_set.tasks_data.len == 0) {
            remove_tasks_set(epoll_fd, blocking_tasks_set);
        }
    }

    return switch (event) {
        .WaitReadable => |data| try Read.wait_ready(blocking_tasks_set, data),
        .WaitWritable => |data| try Write.wait_ready(blocking_tasks_set, data),
        .PerformRead => |data| try Read.perform(blocking_tasks_set, data),
        .PerformWrite => |data| try Write.perform(blocking_tasks_set, data),
        .PerformWriteV => |data| try Write.perform_with_iovecs(blocking_tasks_set, data),
        .WaitTimer => |data| try Timer.wait(blocking_tasks_set, data),
        .SocketShutdown => |data| try Socket.shutdown(blocking_tasks_set, data),
        else => unreachable
    };
}
