const builtin = @import("builtin");
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
    callbacks_num: usize = 0,
    offset: usize = 0,
};

pub const CallbacksSetsQueue = struct {
    queue: CallbacksSetLinkedList,
    last_set: ?CallbacksSetLinkedList.Node = null,
    first_set: ?CallbacksSetLinkedList.Node = null
};

pub inline fn get_max_callbacks_sets(rtq_min_capacity: usize, callbacks_set_length: usize) usize {
    return @max(
        @as(usize, @intFromFloat(
            @ceil(
                @log2(
                    @as(f64, @floatFromInt(rtq_min_capacity)) / @as(f64, @floatFromInt(callbacks_set_length * @sizeOf(Callback))) + 1.0
                )
            )
        )), 1
    );
}

pub inline fn create_new_set(allocator: std.mem.Allocator, size: usize) !CallbacksSet {
    return .{
        .callbacks = try allocator.alloc(Callback, size),
        .callbacks_num = 0
    };
}

pub inline fn release_set(allocator: std.mem.Allocator, set: CallbacksSet) void {
    allocator.free(set.callbacks);
}

pub fn append_new_callback(
    allocator: std.mem.Allocator, sets_queue: *CallbacksSetsQueue, callback: Callback,
    max_callbacks: usize
) !*Callback {
    var callbacks: CallbacksSet = undefined;
    var last_callbacks_set_len: usize = max_callbacks;
    var node = sets_queue.last_set;
    while (node) |n| {
        callbacks = n.data;
        const callbacks_num = callbacks.callbacks_num;

        if (callbacks_num < callbacks.callbacks.len) {
            callbacks.callbacks[callbacks_num] = callback;
            n.data.callbacks_num = callbacks_num + 1;

            sets_queue.last_set = n;
            return &callbacks.callbacks[callbacks_num];
        }
        last_callbacks_set_len = (callbacks_num * 2);
        node = n.next;
    }

    callbacks = try create_new_set(allocator, last_callbacks_set_len);
    errdefer allocator.free(callbacks.callbacks);

    callbacks.callbacks_num = 1;
    callbacks.callbacks[0] = callback;

    try sets_queue.queue.append(callbacks);
    if (sets_queue.first_set == null) {
        sets_queue.first_set = sets_queue.queue.first;
    }
    sets_queue.last_set = sets_queue.queue.last;

    return &callbacks.callbacks[0];
}

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
        const callbacks_set: CallbacksSet = node.data;
        const callbacks_num = callbacks_set.callbacks_num;

        for (callbacks_set.callbacks[callbacks_set.offset..callbacks_num]) |*callback| {
            callback.data.cancelled = true;
            callback.func(&callback.data) catch unreachable;
        }

        release_set(allocator, callbacks_set);
        allocator.destroy(node);
    }
}

pub fn execute_callbacks(
    sets_queue: *CallbacksSetsQueue,
    comptime exception_handler: ?ExceptionHandler,
    exception_handler_data: ?*anyopaque
) !usize {
    const queue = &sets_queue.queue;
    var _node: ?CallbacksSetLinkedList.Node = sets_queue.first_set orelse return 0;
    defer {
        if (sets_queue.first_set == queue.first) {
            sets_queue.last_set = queue.first;
        }
    }

    var chunks_executed: usize = 0;
    while (_node) |node| {
        _node = node.next;
        const callbacks_set: CallbacksSet = node.data;
        const callbacks_num = callbacks_set.callbacks_num;
        if (callbacks_num == 0) {
            break;
        }

        chunks_executed += 1;
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

                if (exception_handler) |handler| {
                    handler(err, exception_handler_data, callback.data.exception_context) catch |err2| {
                        sets_queue.first_set = node;
                        node.data.offset = new_offset;
                        return err2;
                    };

                    continue;
                }

                sets_queue.first_set = node;
                node.data.offset = new_offset;
                return err;
            };
        }

        node.data.callbacks_num = 0;
        node.data.offset = 0;
    }

    sets_queue.first_set = queue.first;
    return chunks_executed;
}


test "Creating a new callback set" {
    const callback_set = try create_new_set(std.testing.allocator, 10);
    defer release_set(std.testing.allocator, callback_set);

    try std.testing.expectEqual(0, callback_set.callbacks_num);
    try std.testing.expectEqual(10, callback_set.callbacks.len);
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
    var set_queue = CallbacksSetsQueue{
        .queue = CallbacksSetLinkedList.init(std.testing.allocator)
    };
    defer {
        for (0..set_queue.queue.len) |_| {
            const callbacks_set: CallbacksSet = set_queue.queue.pop() catch unreachable;
            release_set(std.testing.allocator, callbacks_set);
        }
    }

    for (0..70) |_| {
        _ = try append_new_callback(std.testing.allocator, &set_queue, .{
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
            release_set(std.testing.allocator, callbacks_set);
        }
    }

    var executed: usize = 0;

    const ret = try append_new_callback(std.testing.allocator, &set_queue, .{
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
            release_set(std.testing.allocator, callbacks_set);
        }
    }

    var executed: usize = 0;
    for (0..70) |i| {
        const callback = try append_new_callback(std.testing.allocator, &set_queue, .{
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
            release_set(std.testing.allocator, callbacks_set);
        }
    }

    var executed: usize = 0;
    var executed2: usize = 0;
    for (0..70) |i| {
        const callback = try append_new_callback(std.testing.allocator, &set_queue, .{
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
