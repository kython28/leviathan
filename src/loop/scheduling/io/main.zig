const std = @import("std");
const builtin = @import("builtin");

const utils =  @import("utils");

pub const BlockingTasksSetLinkedList = utils.LinkedList(*BlockingTasksSet);

const CallbackManger = @import("../../../callback_manager.zig");
const Loop = @import("../../main.zig");

pub const Read = @import("read.zig");
pub const Write = @import("write.zig");
pub const Timer = @import("timer.zig");
pub const Cancel = @import("cancel.zig");
pub const Socket = @import("socket.zig");

pub const BlockingTaskData = struct {
    callback_data: ?CallbackManger.Callback,
    operation: BlockingOperation,
    index: u16,
};

pub const TotalTasksItems = switch (builtin.mode) {
    .Debug => 4,
    else => 8192
};

pub const BlockingTasksSet = struct {
    allocator: std.mem.Allocator,
    ring: std.os.linux.IoUring,

    eventfd: std.posix.fd_t,

    task_data_pool: [TotalTasksItems * 2]BlockingTaskData,

    quarantine_indices: [TotalTasksItems * 2]u16,
    free_indices: [TotalTasksItems * 2]u16,

    quarantine_count: u16,
    free_count: u16,

    normal_events_count: u16,
    cancel_events_count: u16,
    quarantine_events_count: [2]u16,

    available_blocking_tasks_queue: *BlockingTasksSetLinkedList,
    busy_blocking_tasks_queue: *BlockingTasksSetLinkedList,
    node: BlockingTasksSetLinkedList.Node,

    pub fn init(
        allocator: std.mem.Allocator, available_blocking_tasks_queue: *BlockingTasksSetLinkedList,
        busy_blocking_tasks_queue: *BlockingTasksSetLinkedList, node: BlockingTasksSetLinkedList.Node
    ) !*BlockingTasksSet {
        const set: *BlockingTasksSet = try allocator.create(BlockingTasksSet);
        errdefer allocator.destroy(set);

        const eventfd = try std.posix.eventfd(0, std.os.linux.EFD.NONBLOCK|std.os.linux.EFD.CLOEXEC);
        errdefer std.posix.close(eventfd);

        set.allocator = allocator;
        set.ring = try std.os.linux.IoUring.init(TotalTasksItems * 2, 0);
        errdefer set.ring.deinit();

        set.eventfd = eventfd;

        set.quarantine_count = 0;
        set.free_count = TotalTasksItems * 2;
        set.normal_events_count = 0;
        set.cancel_events_count = 0;
        set.quarantine_events_count = @splat(0);

        set.available_blocking_tasks_queue = available_blocking_tasks_queue;
        set.busy_blocking_tasks_queue = busy_blocking_tasks_queue;
        set.node = node;

        try set.ring.register_eventfd(eventfd);

        var index: u16 = 0;
        while (index < (TotalTasksItems * 2)) : (index += 1) {
            set.task_data_pool[index] = .{
                .callback_data = null,
                .index = index,
                .operation = undefined
            };

            set.free_indices[index] = index;
        }

        node.data = set;
        return set;
    }

    pub fn deinit(self: *BlockingTasksSet, comptime can_release_node: bool) void {
        if (!self.empty()) {
            @panic("Tasks set is not empty");
        }

        if (can_release_node) {
            const node = self.node;
            const available_blocking_tasks_queue = self.available_blocking_tasks_queue;
            if (self.free_count > 0) {
                available_blocking_tasks_queue.unlink_node(node);
            }else if (self.quarantine_count > 0) {
                self.busy_blocking_tasks_queue.unlink_node(node);
            }

            available_blocking_tasks_queue.release_node(node);
        }

        self.ring.deinit();
        std.posix.close(self.eventfd);
        self.allocator.destroy(self);
    }

    pub inline fn empty(self: *const BlockingTasksSet) bool {
        return (self.free_count == (TotalTasksItems * 2));
    }

    pub fn push(
        self: *BlockingTasksSet, operation: BlockingOperation,
        data: ?CallbackManger.Callback
    ) !*BlockingTaskData {
        var items_count = switch (operation) {
            .Cancel => self.cancel_events_count,
            else => self.normal_events_count,
        };

        if (items_count == TotalTasksItems) {
            return error.NoFreeItems;
        }
        items_count += 1;

        switch (operation) {
            .Cancel => {
                self.cancel_events_count = items_count;
            },
            else => {
                if (items_count == TotalTasksItems) {
                    self.available_blocking_tasks_queue.unlink_node(self.node);
                    self.busy_blocking_tasks_queue.append_node(self.node);
                }

                self.normal_events_count = items_count;
            }
        }

        const count = self.free_count - 1;
        const index = self.free_indices[count];
        self.free_count = count;

        const data_slot = &self.task_data_pool[index];
        data_slot.callback_data = data;
        data_slot.operation = operation;

        return data_slot;
    }

    pub fn pop(self: *BlockingTasksSet, task_data: *BlockingTaskData) void {
        task_data.callback_data = null;
        self.free_indices[self.free_count] = task_data.index;
        self.free_count += 1;

        switch (task_data.operation) {
            .Cancel => {
                self.cancel_events_count -= 1;
            },
            else => {
                const count = self.normal_events_count;
                if (count == TotalTasksItems) {
                    self.busy_blocking_tasks_queue.unlink_node(self.node);
                    self.available_blocking_tasks_queue.append_node(self.node);
                }

                self.normal_events_count = count - 1;
            }
        }
    }

    pub inline fn push_in_quarantine(self: *BlockingTasksSet, task_data: *BlockingTaskData) void {
        const qc_index: usize = switch (task_data.operation) {
            .Cancel => 0,
            else => 1
        };

        self.quarantine_indices[self.quarantine_count] = task_data.index;
        self.quarantine_count += 1;
        self.quarantine_events_count[qc_index] += 1;
    }

    pub fn clear_quarantine(self: *BlockingTasksSet) void {
        const quarantine_count = self.quarantine_count;
        if (quarantine_count == 0) return;

        for (self.quarantine_indices[0..quarantine_count]) |index| {
            self.task_data_pool[index].callback_data = null;
        }

        const free_count = self.free_count;
        @memcpy(
            self.free_indices[free_count..(free_count + quarantine_count)],
            self.quarantine_indices[0..quarantine_count]
        );

        self.quarantine_count = 0;

        self.free_count += quarantine_count;

        self.cancel_events_count -= self.quarantine_events_count[0];

        const q_count = self.quarantine_events_count[1];
        if (q_count > 0) {
            const count = self.normal_events_count;
            self.normal_events_count = count - q_count;

            if (count == TotalTasksItems) {
                self.busy_blocking_tasks_queue.unlink_node(self.node);
                self.available_blocking_tasks_queue.append_node(self.node);
            }
        }
        self.quarantine_events_count = @splat(0);
    }

    pub fn cancel_all(self: *BlockingTasksSet, loop: *Loop) !void {
        for (&self.task_data_pool, &self.free_indices) |*task, *f_index| {
            if (task.callback_data) |*callback| {
                CallbackManger.cancel_callback(callback, true);
                try Loop.Scheduling.Soon.dispatch(loop, callback.*);
                task.callback_data = null;
            } 

            f_index.* = task.index;
        }

        self.cancel_events_count = 0;
        self.normal_events_count = 0;
        self.quarantine_count = 0;
        self.free_count = TotalTasksItems * 2;
        self.quarantine_events_count = @splat(0);
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
    std.debug.dumpCurrentStackTrace(@returnAddress());
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
        if (blocking_tasks_set.empty()) {
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
