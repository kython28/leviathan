const std = @import("std");
const builtin = @import("builtin");

const utils =  @import("utils");

const CallbackManager = @import("callback_manager");
const Loop = @import("../../main.zig");

pub const Read = @import("read.zig");
pub const Write = @import("write.zig");
pub const Timer = @import("timer.zig");
pub const Cancel = @import("cancel.zig");
pub const Socket = @import("socket.zig");

pub const TotalTasksItems = switch (builtin.mode) {
    .Debug => 4,
    .ReleaseSmall => 1024,
    else => 8192
};

pub const BlockingOperation = enum {
    WaitReadable,
    WaitWritable,
    PerformRead,
    PerformWrite,
    PerformWriteV,
    WaitTimer,
    Cancel,
    SocketShutdown,
    SocketConnect,
};

pub const BlockingTaskData = union(enum) {
    callback: CallbackManager.Callback,
    none,
};

pub const BlockingTask = struct {
    data: BlockingTaskData,
    operation: BlockingOperation,
    index: u16,

    inline fn reset(self: *BlockingTask) *BlockingTasksSet {
        const set: *BlockingTasksSet = @ptrFromInt(
            @intFromPtr(self) - @as(usize, self.index) * @sizeOf(BlockingTask)
        );

        self.data = .none;
        self.operation = undefined;

        return set;
    }

    pub fn discard(self: *BlockingTask) void {
        const set = self.reset();
        set.pop();
    }
    
    pub fn deinit(self: *BlockingTask) void {
        const set = self.reset();
        set.inc_finished_tasks_counter();
    }

    pub fn check_result(self: *BlockingTask, result: std.os.linux.E) void {
        switch (self.operation) {
            .WaitTimer => |op| {
                switch (result) {
                    .TIME => {},
                    .CANCELED => {},
                    .SUCCESS => unreachable, // Just to debug. This timeout isn't linked to any task
                    else => |code| {
                        std.debug.panic("Unexpected errno ({}) while checking result for operation {}", .{code, op});
                    }
                }
            },
            .Cancel => unreachable, // Cancel operation doesn't have any callback
            .PerformWriteV, .PerformWrite => |op| {
                switch (result) {
                    .SUCCESS => {},
                    .CANCELED, .BADF, .FBIG, .INTR, .IO, .NOSPC, .INVAL, .CONNRESET,  // Expected errors
                    .PIPE, .NOBUFS, .NXIO, .ACCES, .NETDOWN, .NETUNREACH,
                    .SPIPE => {},
                    .AGAIN => unreachable, // This should not happen. Filtered by debugging porpuse
                    else => |code| {
                        std.debug.panic("Unexpected errno ({}) while checking result for operation {}", .{code, op});
                    }
                }
            },
            .PerformRead => |op| {
                switch (result) {
                    .SUCCESS => {},
                    .CANCELED, .BADF, .BADMSG, .INTR, .INVAL, .IO, .ISDIR,
                    .OVERFLOW, .SPIPE, .CONNRESET, .NOTCONN, .TIMEDOUT,
                    .NOBUFS, .NOMEM, .NXIO => {},
                    .AGAIN => unreachable, // This should not happen. Filtered by debugging porpuse
                    else => |code| {
                        std.debug.panic("Unexpected errno ({}) while checking result for operation {}", .{code, op});
                    }
                }
            },
            .SocketShutdown => |op| {
                switch (result) {
                    .SUCCESS => {},
                    .CANCELED, .INVAL, .NOTCONN, .NOTSOCK, .BADF, .NOBUFS => {},
                    .AGAIN => unreachable, // This should not happen. Filtered by debugging porpuse
                    else => |code| {
                        std.debug.panic("Unexpected errno ({}) while checking result for operation {}", .{code, op});
                    }
                }
            },
            .SocketConnect => |op| {
                switch (result) {
                    .SUCCESS => {},
                    .ACCES, .PERM, .ADDRINUSE, .ADDRNOTAVAIL, .AFNOSUPPORT, .ALREADY,
                    .BADF, .CONNREFUSED, .FAULT, .INPROGRESS, .INTR, .ISCONN,
                    .NETUNREACH, .NOTSOCK, .PROTOTYPE, .TIMEDOUT => {},
                    .AGAIN => unreachable, // This should not happen. Filtered by debugging porpuse
                    else => |code| {
                        std.debug.panic("Unexpected errno ({}) while checking result for operation {}", .{code, op});
                    }
                }
            },
            else => |op| {
                switch (result) {
                    .SUCCESS => {},
                    .CANCELED, .BADF, .INTR => {},
                    else => |code| {
                        std.debug.panic("Unexpected errno ({}) while checking result for operation {}", .{code, op});
                    }
                }
            }
        }
    }
};

fn eventfd_callback(data: *const CallbackManager.CallbackData) !void {
    if (data.cancelled) return;

    const io: *IO = @alignCast(@ptrCast(data.user_data.?));
    try io.register_eventfd_callback();
}

const BlockingTasksSetLinkedList = utils.LinkedList(BlockingTasksSet);

pub const BlockingTasksSet = struct {
    task_data_pool: [TotalTasksItems]BlockingTask,

    loop: *Loop,
    index: u16,
    finished_tasks: u16,

    disattached: bool,

    list: *BlockingTasksSetLinkedList,

    pub fn init(self: *BlockingTasksSet, list: *BlockingTasksSetLinkedList, loop: *Loop) void {
        for (&self.task_data_pool, 0..) |*task, index| {
            task.* = .{
                .data = .none,
                .operation = undefined,
                .index = @intCast(index)
            };
        }

        self.index = 0;
        self.finished_tasks = 0;
        self.disattached = false;

        self.loop = loop;
        self.list = list;
    }

    pub fn deinit(self: *BlockingTasksSet) void { 
        const node: BlockingTasksSetLinkedList.Node = @ptrFromInt(
            @intFromPtr(self) - @offsetOf(BlockingTasksSetLinkedList._linked_list_node, "data")
        );

        if (self.disattached) {
            self.list.unlink_node(node);
        }

        self.list.release_node(node);
    }

    pub fn cancel_all(self: *BlockingTasksSet, loop: *Loop) void {
        for (self.task_data_pool[0..self.index]) |*task| {
            switch (task.data) {
                .callback => |*data| {
                    data.data.cancelled = true;
                    Loop.Scheduling.Soon.dispatch_guaranteed(loop, data);
                },
                .none => {}
            }
        }
    }

    inline fn reset(self: *BlockingTasksSet) void {
        self.index = 0;
        self.finished_tasks = 0;
    }

    pub fn push(
        self: *BlockingTasksSet,
        operation: BlockingOperation,
        callback: ?*const CallbackManager.Callback
    ) !*BlockingTask {
        if (self.index == TotalTasksItems) @panic("Trying to push more items than allowed in BlockingTaksSet");

        try self.loop.reserve_slots(1);

        const index = self.index;
        self.index = index + 1;

        const data_slot = &self.task_data_pool[index];
        if (callback) |v| {
            data_slot.data = .{
                .callback = v.*
            };
        }
        data_slot.operation = operation;

        return data_slot;
    }

    pub inline fn pop(self: *BlockingTasksSet) void {
        self.index -= 1;
        self.loop.reserved_slots -= 1;
    }

    pub inline fn inc_finished_tasks_counter(self: *BlockingTasksSet) void {
        const finished_tasks = self.finished_tasks + 1;
        if (finished_tasks == TotalTasksItems and self.disattached) {
            self.deinit();
            return;
        }

        if (finished_tasks == self.index) {
            self.reset();
            return;
        }

        self.finished_tasks = finished_tasks;
    }

    pub inline fn free(self: *BlockingTasksSet) bool {
        if (self.index == TotalTasksItems) {
            self.disattached = true;
            return false;
        }

        return true;
    }
};

pub const WaitData = struct {
    callback: CallbackManager.Callback,
    fd: std.os.linux.fd_t,
    timeout: ?std.os.linux.kernel_timespec = null
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
    SocketConnect: Socket.ConnectData,
};

loop: *Loop,

busy_sets: BlockingTasksSetLinkedList,
set_node: BlockingTasksSetLinkedList.Node,
set: *BlockingTasksSet,

ring: std.os.linux.IoUring,
ring_blocked: bool,

eventfd: std.posix.fd_t,
eventfd_val: u64,
blocking_ready_tasks: []std.os.linux.io_uring_cqe,

pub fn init(self: *IO, loop: *Loop, allocator: std.mem.Allocator) !void {
    self.busy_sets = BlockingTasksSetLinkedList.init(allocator);

    self.set_node = try self.busy_sets.create_new_node(undefined);
    self.set = &self.set_node.data;
    self.set.init(&self.busy_sets, loop);
    errdefer self.set.deinit();

    self.loop = loop;

    self.ring = try std.os.linux.IoUring.init(TotalTasksItems, 0);
    errdefer self.ring.deinit();

    self.eventfd = try std.posix.eventfd(0, std.os.linux.EFD.NONBLOCK);
    errdefer std.posix.close(self.eventfd);

    self.blocking_ready_tasks = try allocator.alloc(std.os.linux.io_uring_cqe, TotalTasksItems);
    errdefer allocator.free(self.blocking_ready_tasks);

    self.ring_blocked = false;
}

pub fn register_eventfd_callback(self: *IO) !void {
    _ = try self.queue(.{
        .PerformRead = Read.PerformData{
            .data = .{
                .buffer = @as([*]u8, @ptrCast(&self.eventfd_val))[0..@sizeOf(u64)],
            },
            .fd = self.eventfd,
            .callback = .{
                .func = &eventfd_callback,
                .cleanup = null,
                .data = .{
                    .user_data = self,
                    .exception_context = null
                }
            }
        }
    });
}

pub fn wakeup_eventfd(self: *IO) !void {
    const val: u64 = 1;
    _ = try std.posix.write(self.eventfd, @as([*]const u8, @ptrCast(&val))[0..@sizeOf(u64)]);
}

pub fn deinit(self: *IO) void {
    self.set.cancel_all(self.loop);
    self.set.deinit();

    var node: ?BlockingTasksSetLinkedList.Node = self.busy_sets.first;
    while (node) |n| {
        node = n.next;

        const set = &n.data;
        set.cancel_all(self.loop);
        set.deinit();
    }
    
    self.ring.deinit();
    self.busy_sets.allocator.free(self.blocking_ready_tasks);
    std.posix.close(self.eventfd);
}

pub fn get_blocking_tasks_set(self: *IO) !*BlockingTasksSet {
    const set = self.set;
    if (set.free()) {
        return set;
    }
    errdefer set.disattached = false;

    const new_node = try self.busy_sets.create_new_node(undefined);
    errdefer self.busy_sets.release_node(new_node);

    const new_set = &new_node.data;
    new_set.init(&self.busy_sets, self.loop);

    self.busy_sets.append_node(self.set_node);

    self.set_node = new_node;
    self.set = new_set;

    return new_set;
}

pub fn queue(self: *IO, event: BlockingOperationData) !usize {
    const set = try self.get_blocking_tasks_set();

    return switch (event) {
        .WaitReadable => |data| try Read.wait_ready(&self.ring, set, data),
        .WaitWritable => |data| try Write.wait_ready(&self.ring, set, data),
        .PerformRead => |data| try Read.perform(&self.ring, set, data),
        .PerformWrite => |data| try Write.perform(&self.ring, set, data),
        .PerformWriteV => |data| try Write.perform_with_iovecs(&self.ring, set, data),
        .WaitTimer => |data| try Timer.wait(&self.ring, set, data),
        .SocketShutdown => |data| try Socket.shutdown(&self.ring, set, data),
        .Cancel => |data| try Cancel.perform(&self.ring, data),
        .SocketConnect => |data| try Socket.connect(&self.ring, set, data)
    };
}

const IO = @This();
