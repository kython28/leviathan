const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("utils");

pub const CallbacksSetLinkedList = utils.LinkedList(CallbacksSet);

pub const CallbackExceptionContext = struct {
    module_name: [:0]const u8,
    module_ptr: *python_c.PyObject,

    callback_ptr: ?PyObject,
    exc_message: [:0]const u8
};

pub const ExceptionHandler = *const fn (anyerror, ?*anyopaque, ?CallbackExceptionContext) anyerror!void;

pub const CallbackData = struct {
    io_uring_res: i32 = 0,
    io_uring_err: std.os.linux.E = .SUCCESS,

    user_data: ?*anyopaque,

    exception_context: ?CallbackExceptionContext,
    cancelled: bool = false,
};

pub const GenericCallback = *const fn (data: *const CallbackData) anyerror!void;
pub const GenericCleanUpCallback = *const fn (user_data: ?*anyopaque) void;

pub const Callback = struct {
    func: GenericCallback,
    cleanup: ?GenericCleanUpCallback,
    data: CallbackData
};

pub const CallbacksSet = struct {
    callbacks: []Callback,
    callbacks_num: usize,
    offset: usize,

    pub fn init(self: *CallbacksSet, allocator: std.mem.Allocator, capacity: usize) !void {
        self.callbacks = try allocator.alloc(Callback, capacity);
        errdefer allocator.free(self.callbacks);

        self.callbacks_num = 0;
        self.offset = 0;
    }

    pub inline fn deinit(self: *CallbacksSet, allocator: std.mem.Allocator) void {
        allocator.free(self.callbacks);
    }
};

pub const CallbacksSetsQueue = struct {
    queue: CallbacksSetLinkedList,
    capacity: usize,
    available_slots: usize,

    last_set: ?CallbacksSetLinkedList.Node = null,
    first_set: ?CallbacksSetLinkedList.Node = null,

    pub fn init(allocator: std.mem.Allocator) CallbacksSetsQueue {
        return CallbacksSetsQueue{
            .queue = CallbacksSetLinkedList.init(allocator),
            .capacity = 0,
            .available_slots = 0
        };
    }

    pub inline fn empty(self: *CallbacksSetsQueue) bool {
        return (self.available_slots == self.capacity);
    }

    pub fn try_append(self: *CallbacksSetsQueue, callback: *const Callback) ?*Callback {
        var node = self.last_set;
        while (node) |n| {
            const callbacks = &n.data;
            const callbacks_num = callbacks.callbacks_num;

            if (callbacks_num < callbacks.callbacks.len) {
                callbacks.callbacks[callbacks_num] = callback.*;
                callbacks.callbacks_num = callbacks_num + 1;

                self.last_set = n;
                self.available_slots -= 1;
                return &callbacks.callbacks[callbacks_num];
            }
            node = n.next;
        }

        return null;
    }

    pub fn increase_capacity(self: *CallbacksSetsQueue, min_capacity: usize) !void {
        const new_node = try self.queue.create_new_node(undefined);
        errdefer self.queue.release_node(new_node);

        const extra_capacity = @max(self.capacity * 2, min_capacity);

        try new_node.data.init(self.queue.allocator, extra_capacity);
        errdefer new_node.data.deinit();

        self.queue.append_node(new_node);
        if (self.first_set == null) {
            self.first_set = new_node;
        }
        self.last_set = new_node;

        self.available_slots += extra_capacity;
        self.capacity += extra_capacity;
    }

    pub inline fn ensure_capacity(self: *CallbacksSetsQueue, min_capacity: usize) !void {
        if (self.capacity < min_capacity) {
            try self.increase_capacity(min_capacity);
        }
    }

    pub inline fn append(self: *CallbacksSetsQueue, callback: *const Callback, min_capacity: usize) !*Callback {
        if (self.try_append(callback)) |new_callback| {
            return new_callback;
        }

        try self.increase_capacity(min_capacity);
        return self.try_append(callback) orelse unreachable;
    }

    inline fn free_callbacks_set(
        allocator: std.mem.Allocator, node: CallbacksSetLinkedList.Node,
        removed: *usize, comptime field_name: []const u8
    ) CallbacksSetLinkedList.Node {
        removed.* = node.data.callbacks.len;
        node.data.deinit(allocator);

        const next_node = @field(node, field_name).?;
        allocator.destroy(node);

        return next_node;
    }

    pub fn prune(self: *CallbacksSetsQueue, max_capacity: usize) void {
        var capacity = self.capacity;
        if (capacity >= max_capacity and self.available_slots < capacity) return;
        defer self.capacity = capacity;

        const allocator = self.queue.allocator;
        if (((capacity * 2) / 3) <= max_capacity) {
            var queue_len = self.queue.len;
            var node = self.queue.first.?;

            defer {
                node.prev = null;
                self.queue.first = node;
                self.queue.len = queue_len;
            }

            while (capacity > max_capacity) {
                var removed: usize = undefined;
                node = free_callbacks_set(allocator, node, &removed, "next");

                capacity -= removed;
                queue_len -= 1;
            }
        }else{
            var queue_len = self.queue.len;
            var node = self.queue.last.?;

            defer {
                node.next = null;
                self.queue.last = node;
                self.queue.len = queue_len;
            }

            while (capacity > max_capacity) {
                var removed: usize = undefined;
                node = free_callbacks_set(allocator, node, &removed, "prev");

                capacity -= removed;
                queue_len -= 1;
            }
        }
    }
};

// pub fn append_new_callback(
//     allocator: std.mem.Allocator, sets_queue: *CallbacksSetsQueue, callback: Callback,
//     max_callbacks: usize
// ) !*Callback {
//     var callbacks: CallbacksSet = undefined;
//     var last_callbacks_set_len: usize = max_callbacks;
//     var node = sets_queue.last_set;
//     while (node) |n| {
//         callbacks = n.data;
//         const callbacks_num = callbacks.callbacks_num;

//         if (callbacks_num < callbacks.callbacks.len) {
//             callbacks.callbacks[callbacks_num] = callback;
//             n.data.callbacks_num = callbacks_num + 1;

//             sets_queue.last_set = n;
//             return &callbacks.callbacks[callbacks_num];
//         }
//         last_callbacks_set_len = (callbacks_num * 2);
//         node = n.next;
//     }

//     callbacks = try create_new_set(allocator, last_callbacks_set_len);
//     errdefer allocator.free(callbacks.callbacks);

//     callbacks.callbacks_num = 1;
//     callbacks.callbacks[0] = callback;

//     try sets_queue.queue.append(callbacks);
//     if (sets_queue.first_set == null) {
//         sets_queue.first_set = sets_queue.queue.first;
//     }
//     sets_queue.last_set = sets_queue.queue.last;

//     return &callbacks.callbacks[0];
// }

pub fn release_sets_queue(
    allocator: std.mem.Allocator, sets_queue: *CallbacksSetsQueue,
) void {
    var _node: ?CallbacksSetLinkedList.Node = sets_queue.first_set orelse return;
    var _node2: ?CallbacksSetLinkedList.Node = sets_queue.queue.first.?;

    while (_node2 != _node) {
        const node = _node2.?;
        _node2 = node.next;
        allocator.destroy(node);
    }

    while (_node) |node| {
        _node = node.next;
        const callbacks_set = &node.data;
        const callbacks_num = callbacks_set.callbacks_num;

        for (callbacks_set.callbacks[callbacks_set.offset..callbacks_num]) |*callback| {
            callback.data.cancelled = true;
            callback.func(&callback.data) catch |err| {
                std.debug.panic("Unexpected error while releasing events queues: {s}", .{@errorName(err)});
            };
        }

        callbacks_set.deinit(allocator);
        allocator.destroy(node);
    }
}

pub fn execute_callbacks(
    sets_queue: *CallbacksSetsQueue,
    comptime exception_handler: ?ExceptionHandler,
    exception_handler_data: ?*anyopaque
) !usize {
    if (sets_queue.empty()) return 0;

    var _node: ?CallbacksSetLinkedList.Node = sets_queue.first_set;
    defer {
        if (sets_queue.first_set == sets_queue.queue.first) {
            sets_queue.last_set = sets_queue.queue.first;
        }
    }

    var callbacks_executed: usize = 0;
    defer sets_queue.available_slots += callbacks_executed;

    while (_node) |node| {
        _node = node.next;
        const callbacks_set: CallbacksSet = node.data;
        const callbacks_num = callbacks_set.callbacks_num;
        if (callbacks_num == 0) {
            break;
        }

        for (callbacks_set.callbacks[callbacks_set.offset..callbacks_num]) |*callback| {
            callback.func(&callback.data) catch |err| {
                defer {
                    if (callback.cleanup) |cleanup| {
                        cleanup(callback.data.user_data);
                    }
                }

                const new_offset = (
                    @intFromPtr(callback) - @intFromPtr(callbacks_set.callbacks.ptr)
                ) / @sizeOf(Callback) + 1;

                errdefer {
                    sets_queue.first_set = node;
                    node.data.offset = new_offset;
                    callbacks_executed += new_offset;
                }

                const handler = exception_handler orelse return err;

                handler(err, exception_handler_data, callback.data.exception_context) catch |err2| {
                    return err2;
                };
            };
        }
        callbacks_executed += callbacks_num;

        node.data.callbacks_num = 0;
        node.data.offset = 0;
    }

    sets_queue.first_set = sets_queue.queue.first;
    return callbacks_executed;
}


test "Creating a new callback set" {
    var callbacks_set: CallbacksSet = undefined;
    try callbacks_set.init(std.testing.allocator, 10);
    defer callbacks_set.deinit(std.testing.allocator);

    try std.testing.expectEqual(0, callbacks_set.callbacks_num);
    try std.testing.expectEqual(10, callbacks_set.callbacks.len);
}

fn test_callback(data: *const CallbackData) !void {
    if (data.cancelled) return;

    const executed_ptr: *usize = @alignCast(@ptrCast(data.user_data.?));
    executed_ptr.* += 1;
    return;
}

fn test_callback2(_: *const CallbackData) !void {
    return error.Test;
}

fn test_exception_handler(err: anyerror, data: ?*anyopaque, _: ?CallbackExceptionContext) !void {
    try std.testing.expectEqual(error.Test, err);


    const executed_ptr: *usize = @alignCast(@ptrCast(data.?));
    executed_ptr.* += 1;
}

test "Append multiple sets" {
    var set_queue = CallbacksSetsQueue.init(std.testing.allocator);
    defer {
        for (0..set_queue.queue.len) |_| {
            const callbacks_set: CallbacksSet = set_queue.queue.pop() catch unreachable;
            callbacks_set.deinit(std.testing.allocator);
        }
    }

    for (0..70) |_| {
        _ = try set_queue.append(std.testing.allocator, &set_queue, .{
            .func = &test_callback,
            .cleanup = null,
            .data = .{
                .user_data = null,
                .exception_context = null
            }
            // .ZigGeneric = .{
            //     .data = null,
            //     .callback = &test_callback
            // }
        }, 10);
    }

    try std.testing.expectEqual(3, set_queue.queue.len);
    var node = set_queue.queue.first;
    var callbacks_len: usize = 10;
    while (node) |n| {
        const callbacks_set: CallbacksSet = n.data;
        try std.testing.expectEqual(callbacks_len, callbacks_set.callbacks.len);
        try std.testing.expectEqual(callbacks_len, callbacks_set.callbacks_num);
        callbacks_len *= 2;
        node = n.next;
    }
}

test "Append new callback to set queue and execute it" {
    var set_queue = CallbacksSetsQueue{
        .queue = CallbacksSetLinkedList.init(std.testing.allocator)
    };
    defer {
        for (0..set_queue.queue.len) |_| {
            const callbacks_set: CallbacksSet = set_queue.queue.pop() catch unreachable;
            callbacks_set.deinit(std.testing.allocator);
        }
    }

    var executed: usize = 0;

    const ret = try set_queue.append(std.testing.allocator, &set_queue, .{
        .func = &test_callback,
        .cleanup = null,
        .data = .{
            .user_data = &executed,
            .exception_context = null
        }
        // .ZigGeneric = .{
        //     .data = &executed,
        //     .callback = &test_callback
        // }
    }, 10);

    try std.testing.expectEqual(&test_callback, ret.func);
    try std.testing.expectEqual(@intFromPtr(&executed), @intFromPtr(ret.data.user_data));

    try std.testing.expect(set_queue.last_set != null);

    const callbacks_set: *CallbacksSet = &set_queue.last_set.?.data;

    try std.testing.expectEqual(1, callbacks_set.callbacks_num);
    try std.testing.expectEqual(ret, &callbacks_set.callbacks[0]);
    try std.testing.expectEqual(10, callbacks_set.callbacks.len);

    _ = try execute_callbacks(&set_queue, null, null);
    try std.testing.expectEqual(1, executed);
    try std.testing.expectEqual(0, callbacks_set.callbacks_num);

    callbacks_set.callbacks_num = 1;
    executed = 0;
    _ = try execute_callbacks(&set_queue, null, null);
    try std.testing.expectEqual(1, executed);
    try std.testing.expectEqual(0, callbacks_set.callbacks_num);
    try std.testing.expectEqual(set_queue.queue.first, set_queue.last_set);
}

test "Append and cancel callbacks" {
    var set_queue = CallbacksSetsQueue{
        .queue = CallbacksSetLinkedList.init(std.testing.allocator)
    };
    defer {
        for (0..set_queue.queue.len) |_| {
            const callbacks_set: CallbacksSet = set_queue.queue.pop() catch unreachable;
            callbacks_set.deinit(std.testing.allocator);
        }
    }

    var executed: usize = 0;
    for (0..70) |i| {
        const callback = try set_queue.append(std.testing.allocator, &set_queue, .{
            .func = &test_callback,
            .cleanup = null,
            .data = .{
                .user_data = &executed,
                .exception_context = null
            }
            // .ZigGeneric = .{
            //     .data = &executed,
            //     .callback = &test_callback
            // }
        }, 10);

        if (i % 2 == 0) {
            callback.data.cancelled = true;
        }
    }

    _ = try execute_callbacks(&set_queue, null, null);
    try std.testing.expectEqual(35, executed);
}

test "Append and stopping with exception" {
    var set_queue = CallbacksSetsQueue{
        .queue = CallbacksSetLinkedList.init(std.testing.allocator)
    };
    defer {
        for (0..set_queue.queue.len) |_| {
            const callbacks_set: CallbacksSet = set_queue.queue.pop() catch unreachable;
            callbacks_set.deinit(std.testing.allocator, callbacks_set);
        }
    }

    var executed: usize = 0;
    var executed2: usize = 0;
    for (0..70) |i| {
        const callback = try set_queue.append(std.testing.allocator, &set_queue, .{
            .func = blk: {
                if (i == 35) {
                    break :blk &test_callback2;
                }else{
                    break :blk &test_callback;
                }
            },
            .cleanup = null,
            .data = .{
                .user_data = &executed,
                .exception_context = null
            }
        }, 10);

        if (i % 2 == 0) {
            callback.data.cancelled = false;
        }
    }

    _ = try execute_callbacks(&set_queue, &test_exception_handler, &executed2);
    try std.testing.expectEqual(69, executed);
    try std.testing.expectEqual(1, executed2);
}
