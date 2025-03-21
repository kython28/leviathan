const std = @import("std");
const builtin = @import("builtin");

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

    pub inline fn deinit(self: *const CallbacksSet, allocator: std.mem.Allocator) void {
        allocator.free(self.callbacks);
    }
};

pub const MinCapacity = switch (builtin.mode) {
    .Debug => 4,
    .ReleaseSmall => 16,
    else => 128
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

        var extra_capacity = @max(self.capacity * 2, switch (builtin.mode) {
            .Debug => 4,
            .ReleaseSmall => 32,
            else => 128
        });
        while (extra_capacity < min_capacity) {
            extra_capacity *= 2;
        }

        try new_node.data.init(self.queue.allocator, extra_capacity);
        errdefer new_node.data.deinit();

        self.queue.append_node(new_node);
        if (self.first_set == null) {
            self.first_set = new_node;
            self.last_set = new_node;
        }

        self.available_slots += extra_capacity;
        self.capacity += extra_capacity;
    }

    pub inline fn ensure_capacity(self: *CallbacksSetsQueue, min_capacity: usize) !void {
        if (self.available_slots < min_capacity) {
            try self.increase_capacity(min_capacity);
        }
    }

    pub inline fn append(self: *CallbacksSetsQueue, callback: *const Callback, min_capacity: usize) !*Callback {
        try self.ensure_capacity(min_capacity);
        return self.try_append(callback) orelse std.debug.panic(
            "Appening after increasing capacity failed. Min capacity requested: {d} - Available slots: {d}",
            .{min_capacity, self.available_slots}
        );
    }

    pub fn prune(self: *CallbacksSetsQueue, max_capacity: usize) void {
        var capacity = self.capacity;
        if (max_capacity == 0 or capacity <= max_capacity) return;

        var queue_len = self.queue.len;
        if (queue_len == 1) return;

        defer self.capacity = capacity;
        const allocator = self.queue.allocator;

        var available_slots = self.available_slots;
        defer self.available_slots = available_slots;

        if (((capacity * 2) / 3) <= max_capacity) {
            var node = self.queue.first.?;

            defer {
                node.prev = null;
                self.queue.first = node;
                self.queue.len = queue_len;
            }

            while (capacity > max_capacity and queue_len > 1) {
                const data = &node.data;
                const removed = data.callbacks.len;
                const slots_in_use = data.callbacks_num;

                data.deinit(allocator);

                const next_node = node.next.?;
                allocator.destroy(node);
                node = next_node;

                capacity -= removed;
                available_slots -= removed - slots_in_use;
                queue_len -= 1;
            }
        }else{
            var node = self.queue.last.?;

            defer {
                node.next = null;
                self.queue.last = node;
                self.queue.len = queue_len;
            }

            while (capacity > max_capacity and queue_len > 1) {
                const data = &node.data;
                const removed = data.callbacks.len;
                const slots_in_use = data.callbacks_num;

                data.deinit(allocator);

                const prev_node = node.prev.?;
                allocator.destroy(node);
                node = prev_node;

                capacity -= removed;
                available_slots -= removed - slots_in_use;
                queue_len -= 1;
            }
        }

        self.first_set = self.queue.first;
        self.last_set = self.queue.first;
    }
};

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

    var callbacks_executed: usize = 0;
    defer sets_queue.available_slots += callbacks_executed;

    while (_node) |node| {
        _node = node.next;
        const callbacks_set = &node.data;
        const callbacks_num = callbacks_set.callbacks_num;
        if (callbacks_num == 0) {
            break;
        }

        const offset = callbacks_set.offset;
        for (callbacks_set.callbacks[offset..callbacks_num]) |*callback| {
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
        callbacks_executed += callbacks_num - offset;

        node.data.callbacks_num = 0;
        node.data.offset = 0;
    }

    sets_queue.first_set = sets_queue.queue.first;
    sets_queue.last_set = sets_queue.queue.first;
    return callbacks_executed;
}


test "Initialize callback set with specific capacity" {
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

test "Dynamically expand callback sets with increasing capacity" {
    var set_queue = CallbacksSetsQueue.init(std.testing.allocator);
    defer {
        for (0..set_queue.queue.len) |_| {
            const callbacks_set: CallbacksSet = set_queue.queue.pop() catch unreachable;
            callbacks_set.deinit(std.testing.allocator);
        }
    }

    for (0..108) |_| {
        const callback = Callback{
            .func = &test_callback,
            .cleanup = null,
            .data = .{
                .user_data = null,
                .exception_context = null
            }
        };
        _ = try set_queue.append(&callback, 1);
    }

    try std.testing.expectEqual(108, set_queue.capacity);
    try std.testing.expectEqual(0, set_queue.available_slots);

    try std.testing.expectEqual(4, set_queue.queue.len);
    var node = set_queue.queue.first;
    var callbacks_len: usize = MinCapacity;
    var capacity: usize = 0;
    while (node) |n| {
        capacity += callbacks_len;

        const callbacks_set: *CallbacksSet = &n.data;
        try std.testing.expectEqual(callbacks_len, callbacks_set.callbacks.len);
        try std.testing.expectEqual(callbacks_len, callbacks_set.callbacks_num);
        callbacks_len = capacity * 2;
        node = n.next;
    }

    try std.testing.expectEqual(capacity, set_queue.capacity);
}

test "Add new callback to queue and immediately execute" {
    var set_queue = CallbacksSetsQueue.init(std.testing.allocator);
    defer {
        for (0..set_queue.queue.len) |_| {
            const callbacks_set: CallbacksSet = set_queue.queue.pop() catch unreachable;
            callbacks_set.deinit(std.testing.allocator);
        }
    }

    var executed: usize = 0;

    const callback = Callback{
        .func = &test_callback,
        .cleanup = null,
        .data = .{
            .user_data = &executed,
            .exception_context = null
        }
    };

    const ret = try set_queue.append(&callback, 10);

    try std.testing.expectEqual(16, set_queue.capacity);
    try std.testing.expectEqual(15, set_queue.available_slots);

    try std.testing.expectEqual(&test_callback, ret.func);
    try std.testing.expectEqual(@intFromPtr(&executed), @intFromPtr(ret.data.user_data));

    try std.testing.expect(set_queue.last_set != null);

    const callbacks_set: *CallbacksSet = &set_queue.last_set.?.data;

    try std.testing.expectEqual(1, callbacks_set.callbacks_num);
    try std.testing.expectEqual(ret, &callbacks_set.callbacks[0]);
    try std.testing.expectEqual(16, callbacks_set.callbacks.len);

    const callbacks_executed  = try execute_callbacks(&set_queue, null, null);
    try std.testing.expectEqual(1, callbacks_executed);
    try std.testing.expectEqual(16, set_queue.capacity);
    try std.testing.expectEqual(16, set_queue.available_slots);

    try std.testing.expectEqual(1, executed);
    try std.testing.expectEqual(0, callbacks_set.callbacks_num);
}

test "Selectively cancel callbacks during addition" {
    var set_queue = CallbacksSetsQueue.init(std.testing.allocator);
    defer {
        for (0..set_queue.queue.len) |_| {
            const callbacks_set: CallbacksSet = set_queue.queue.pop() catch unreachable;
            callbacks_set.deinit(std.testing.allocator);
        }
    }

    var executed: usize = 0;
    for (0..70) |i| {
        const callback = Callback{
            .func = &test_callback,
            .cleanup = null,
            .data = .{
                .user_data = &executed,
                .exception_context = null
            }
        };

        const callback_ptr = try set_queue.append(&callback, 10);
        if (i % 2 == 0) {
            callback_ptr.data.cancelled = true;
        }
    }
    try std.testing.expectEqual(70, (set_queue.capacity - set_queue.available_slots));

    _ = try execute_callbacks(&set_queue, null, null);
    try std.testing.expectEqual(35, executed);
}

test "Handle exceptions during callback execution" {
    var set_queue = CallbacksSetsQueue.init(std.testing.allocator);
    defer {
        for (0..set_queue.queue.len) |_| {
            const callbacks_set: CallbacksSet = set_queue.queue.pop() catch unreachable;
            callbacks_set.deinit(std.testing.allocator);
        }
    }

    var executed: usize = 0;
    var executed2: usize = 0;
    for (0..70) |i| {
        const callback = Callback{
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
        };

        const callback_ptr = try set_queue.append(&callback, 10);
        if (i % 2 == 0) {
            callback_ptr.data.cancelled = false;
        }
    }
    try std.testing.expectEqual(70, (set_queue.capacity - set_queue.available_slots));

    _ = try execute_callbacks(&set_queue, &test_exception_handler, &executed2);
    try std.testing.expectEqual(69, executed);
    try std.testing.expectEqual(1, executed2);
}

test "Reduce callback sets when maximum capacity is 1" {
    const allocator = std.testing.allocator;

    var set_queue = CallbacksSetsQueue.init(allocator);
    defer {
        for (0..set_queue.queue.len) |_| {
            const set: CallbacksSet = set_queue.queue.pop() catch unreachable;
            set.deinit(allocator);
        }
    }

    var number: usize = 0;
    for (0..3) |_| {
        const callback = Callback{
            .func = undefined,
            .cleanup = null,
            .data = .{
                .user_data = &number,
                .exception_context = null
            }
        };
        _ = try set_queue.append(&callback, 1);
    }

    try std.testing.expectEqual(1, set_queue.queue.len);

    set_queue.prune(1);

    try std.testing.expectEqual(1, set_queue.queue.len);
    try std.testing.expectEqual(set_queue.first_set, set_queue.queue.first);
    try std.testing.expectEqual(set_queue.last_set, set_queue.queue.first);
}

test "Reduce callback sets with maximum capacity greater than 1" {
    const allocator = std.testing.allocator;

    var set_queue = CallbacksSetsQueue.init(allocator);
    defer {
        for (0..set_queue.queue.len) |_| {
            const set: CallbacksSet = set_queue.queue.pop() catch unreachable;
            set.deinit(allocator);
        }
    }

    var number: usize = 0;
    for (0..20) |_| {
        const callback = Callback{
            .func = undefined,
            .cleanup = null,
            .data = .{
                .user_data = &number,
                .exception_context = null
            }
        };
        _ = try set_queue.append(&callback, 2);
    }

    try std.testing.expectEqual(3, set_queue.queue.len);

    set_queue.prune(14);

    try std.testing.expectEqual(2, set_queue.queue.len);
    try std.testing.expectEqual(set_queue.first_set, set_queue.queue.first);
    try std.testing.expectEqual(set_queue.last_set, set_queue.queue.first);
}

test "Maintain callback sets when pruning limit is high" {
    const allocator = std.testing.allocator;

    var set_queue = CallbacksSetsQueue.init(allocator);
    defer {
        for (0..set_queue.queue.len) |_| {
            const set: CallbacksSet = set_queue.queue.pop() catch unreachable;
            set.deinit(allocator);
        }
    }

    var number: usize = 0;
    for (0..20) |_| {
        const callback = Callback{
            .func = undefined,
            .cleanup = null,
            .data = .{
                .user_data = &number,
                .exception_context = null
            }
        };
        _ = try set_queue.append(&callback, 2);
    }

    try std.testing.expectEqual(3, set_queue.queue.len);

    set_queue.prune(64);

    try std.testing.expectEqual(3, set_queue.queue.len);
    try std.testing.expectEqual(set_queue.first_set, set_queue.queue.first);
    try std.testing.expectEqual(set_queue.last_set, set_queue.queue.last);
}

test "Execute callbacks and then prune sets" {
    const allocator = std.testing.allocator;

    var set_queue = CallbacksSetsQueue.init(allocator);
    defer {
        for (0..set_queue.queue.len) |_| {
            const set: CallbacksSet = set_queue.queue.pop() catch unreachable;
            set.deinit(allocator);
        }
    }

    var number: usize = 0;
    for (0..20) |_| {
        const callback = Callback{
            .func = &test_callback,
            .cleanup = null,
            .data = .{
                .user_data = &number,
                .exception_context = null
            }
        };
        _ = try set_queue.append(&callback, 2);
    }

    const c_executed = try execute_callbacks(&set_queue, null, null);
    try std.testing.expectEqual(20, c_executed);
    try std.testing.expectEqual(3, set_queue.queue.len);

    const new_av_slots = set_queue.available_slots - set_queue.queue.last.?.data.callbacks.len;

    set_queue.prune(20);

    try std.testing.expectEqual(2, set_queue.queue.len);
    try std.testing.expectEqual(new_av_slots, set_queue.available_slots);
    try std.testing.expectEqual(set_queue.first_set, set_queue.queue.first);
    try std.testing.expectEqual(set_queue.last_set, set_queue.queue.first);
}
