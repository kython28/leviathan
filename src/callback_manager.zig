const std = @import("std");
const builtin = @import("builtin");

const python_c = @import("python_c");

const Future = @import("future/main.zig");
const Task = @import("task/main.zig");
const Handle = @import("handle.zig");

pub const LinkedList = @import("utils/linked_list.zig").init(CallbacksSet);

pub const ExecuteCallbacksReturn = enum {
    Stop,
    Exception,
    Continue,
    None
};

pub const CallbackType = enum {
    ZigGeneric, ZigGenericIO, PythonGeneric, PythonFutureCallbacksSet, PythonFuture, PythonTask
};

const ZigGenericCallback = *const fn (?*anyopaque, status: ExecuteCallbacksReturn) ExecuteCallbacksReturn;
pub const ZigGenericCallbackData = struct {
    callback: ZigGenericCallback,
    data: ?*anyopaque,
    can_execute: bool = true,
};

const ZigGenericIOCallback = *const fn (
    ?*anyopaque, std.os.linux.E
) ExecuteCallbacksReturn;
pub const ZigGenericIOCallbackData = struct {
    callback: ZigGenericIOCallback,
    data: ?*anyopaque,

    io_uring_res: std.os.linux.E = .SUCCESS,
};

pub const Callback = union(CallbackType) {
    ZigGeneric: ZigGenericCallbackData,
    ZigGenericIO: ZigGenericIOCallbackData,
    PythonGeneric: Handle.GenericCallbackData,
    PythonFutureCallbacksSet: Future.Callback.CallbacksSetData,
    PythonFuture: Future.Callback.Data,
    PythonTask: Task.Callback.Data
};

pub const CallbacksSet = struct {
    callbacks: []Callback,
    callbacks_num: usize = 0,
};

pub const CallbacksSetsQueue = struct {
    queue: LinkedList,
    last_set: ?LinkedList.Node = null,
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

pub inline fn cancel_callback(callback: *Callback, can_release: ?bool) void {
    const type_info = @typeInfo(CallbackType);
    const tag = @intFromEnum(callback.*);
    inline for (type_info.@"enum".fields) |field| {
        if (field.value == tag) {
            const data = &@field(callback, field.name);
            const data_type = @TypeOf(data.*);
            if (@hasField(data_type, "can_execute")) { // Any other event
                data.can_execute = false;
            }else if (@hasField(data_type, "cancelled")) { // Handle
                if (builtin.single_threaded) {
                    data.cancelled.* = true;
                }else{
                    @atomicStore(bool, data.cancelled, true, .monotonic);
                }
            }else if (@hasField(data_type, "io_uring_res")) {
                data.io_uring_res = std.os.linux.E.CANCELED;
            }

            if (@hasField(data_type, "can_release")) {
                if (can_release) |_can_release| {
                    data.can_release = _can_release;
                }
            }
        }
    }
}

pub inline fn is_callback_cancelled(callback: Callback) bool {
    const type_info = @typeInfo(CallbackType);
    const tag = @intFromEnum(callback);
    inline for (type_info.@"enum".fields) |field| {
        if (field.value == tag) {
            const data = &@field(callback, field.name);
            const data_type = @TypeOf(data.*);
            if (@hasField(data_type, "can_execute")) { // Any other event
                return !data.can_execute;
            }else if (@hasField(data_type, "cancelled")) { // Handle
                if (builtin.single_threaded) {
                    data.cancelled.* = true;
                    return !data.cancelled.*;
                }else{
                    return @atomicLoad(bool, data.cancelled, .monotonic);
                }
            }else{
                @compileError(
                    "Invalid callback type: callback must have either 'can_execute' or 'cancelled' field"
                );
            }
        }
    }
}

pub inline fn append_new_callback(
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
    sets_queue.last_set = sets_queue.queue.last;

    return &callbacks.callbacks[0];
}

pub inline fn run_callback(
    allocator: std.mem.Allocator, callback: Callback, status: ExecuteCallbacksReturn
) ExecuteCallbacksReturn {
    return switch (status) {
        .Continue => switch (callback) {
            .ZigGeneric => |data| blk: {
                if (data.can_execute) {
                    break :blk data.callback(data.data, status);
                }else{
                    break :blk switch (data.callback(data.data, .Stop)) {
                        .Exception => .Exception,
                        else => .Continue
                    };
                }
            },
            .ZigGenericIO => |data| data.callback(data.data, data.io_uring_res),
            .PythonGeneric => |data| Handle.callback_for_python_generic_callbacks(allocator, data),
            .PythonFutureCallbacksSet => |data| Future.Callback.run_python_future_set_callbacks(
                allocator, data, status
            ),
            .PythonFuture => |data| Future.Callback.callback_for_python_future_callbacks(data),
            .PythonTask => |data| Task.Callback.step_run_and_handle_result(data.task, data.exc_value),
        },
        else => blk: {
            const ret: ExecuteCallbacksReturn = switch (callback) {
                .ZigGeneric => |data| data.callback(data.data, .Stop),
                .ZigGenericIO => |data| data.callback(data.data, std.os.linux.E.CANCELED),
                .PythonGeneric => |data| {
                    Handle.release_python_generic_callback(allocator, data);
                    break :blk .Continue;
                },
                .PythonFutureCallbacksSet => |data| Future.Callback.run_python_future_set_callbacks(
                    allocator, data, .Stop
                ),
                .PythonFuture => |data| {
                    Future.Callback.release_python_future_callback(data);
                    break :blk .Continue;
                },
                .PythonTask => |data| blk2: {
                    data.task.must_cancel = true;
                    break :blk2 Task.Callback.step_run_and_handle_result(data.task, data.exc_value);
                }
            };

            if (ret == .Exception) {
                @panic("Unexpected exception status. Can't exists exception status while releasing resources.");
            }

            break :blk .Continue;
        }
    };
}

pub fn execute_callbacks(
    allocator: std.mem.Allocator, sets_queue: *CallbacksSetsQueue, _exec_status: ExecuteCallbacksReturn,
    comptime can_restart: bool
) ExecuteCallbacksReturn {
    const queue = &sets_queue.queue;
    var _node: ?LinkedList.Node = queue.first orelse return .None;
    defer {
        if (can_restart) {
            sets_queue.last_set = queue.first;
        }
    }

    var status: ExecuteCallbacksReturn = _exec_status;
    var chunks_executed: usize = 0;
    while (_node) |node| : (chunks_executed += 1) {
        _node = node.next;
        const callbacks_set: CallbacksSet = node.data;
        const callbacks_num = callbacks_set.callbacks_num;
        if (callbacks_num == 0) {
            if (chunks_executed == 0) {
                return .None;
            }
            return status;
        }

        for (callbacks_set.callbacks[0..callbacks_num]) |callback| {
            switch (run_callback(allocator, callback, status)) {
                .Continue => {},
                .Stop, .Exception => |v| {
                    status = v;
                },
                else => unreachable
            }
        }
        node.data.callbacks_num = 0;
    }

    return status;
}
