const std = @import("std");

const CallbackManager = @import("callback_manager");
const Handle = @import("../handle.zig");
const Loop = @import("../loop/main.zig");
const Future = @import("main.zig");

const CallbacksSetLinkedList = CallbackManager.CallbacksSetLinkedList;
const utils = @import("utils");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const ExceptionMessage: [:0]const u8 = "An error ocurred while executing future callbacks";
const ModuleName: [:0]const u8 = "future";

// pub const Data = struct {
//     py_future: PyObject,
//     py_callback: PyObject,
//     py_context: PyObject,
//     exception_handler: PyObject,
//     can_execute: bool = true,
//     dec_future: bool = false
// };

const PythonGenericData = struct {
    callback: PyObject,
    context: PyObject,
};

const ZigGenericData = struct {
    callback: *const fn (?*Future, ?*anyopaque) anyerror!void,
    ptr: ?*anyopaque
};

pub const Data = union(enum) {
    PythonGeneric: PythonGenericData,
    ZigGeneric: ZigGenericData,
};

pub const Callback = struct {
    data: Data,
    cancelled: bool = false
};

pub const CallbacksSetData = std.ArrayList(Callback);

fn release_python_future_data(data: ?*anyopaque) void {
    const future: *Future = @alignCast(@ptrCast(data.?));
    const py_future = utils.get_parent_ptr(Future.Python.FutureObject, future);
    python_c.py_decref(@ptrCast(py_future));
}

fn run_python_future_set_callbacks(data: *const CallbackManager.CallbackData) !void {
    const future: *Future = @alignCast(@ptrCast(data.user_data.?));
    const py_future = utils.get_parent_ptr(Future.Python.FutureObject, future);

    for (future.callbacks_queue.items) |callback| {
        if (callback.cancelled) continue;

        switch (callback.data) {
            .PythonGeneric => |py_data| {
                if (python_c.PyContext_Enter(py_data.context) < 0) {
                    return error.PythonError;
                }

                const result: ?PyObject = python_c.PyObject_CallOneArg(py_data.callback, @ptrCast(py_future));

                if (python_c.PyContext_Exit(py_data.context) < 0) {
                    return error.PythonError;
                }

                if (result) |v| {
                    python_c.py_decref(v);
                }else{
                    return error.PythonError;
                }
            },
            .ZigGeneric => |z_data| try z_data.callback(future, z_data.ptr)
        }
    }

    python_c.py_decref(@ptrCast(py_future));
}

pub fn release_callbacks_queue(queue: *const CallbacksSetData) void {
    for (queue.items) |callback| {
        switch (callback.data) {
            .PythonGeneric => |data| {
                python_c.py_decref(data.callback);
                python_c.py_decref(data.context);
            },
            .ZigGeneric => |data| {
                data.callback(null, data.ptr) catch unreachable;
            }
        }
    }
}

pub fn create_python_handle(self: *Future, callback_data: PyObject) !CallbackManager.Callback {
    var py_callback: ?PyObject = null;
    var py_context: ?PyObject = null;
    const ret = python_c.PyArg_ParseTuple(callback_data, "(OO)\x00", &py_callback, &py_context);
    if (ret < 0) {
        return error.PythonError;
    }

    return .{
        .PythonFuture = .{
            .exception_handler = self.loop.?.py_loop.?.exception_handler.?,
            .contextvars = python_c.py_newref(py_context.?),
            .py_callback = python_c.py_newref(py_callback.?),
            .py_future = @ptrCast(self.py_future.?),
        }
    };
}

pub inline fn add_done_callback(self: *Future, callback: Data) !void {
    if (self.status != .PENDING) return error.FutureAlreadyFinished;

    try self.callbacks_queue.append(callback);
}

pub fn remove_done_callback(self: *Future, callback_id: u64) usize {
    if (self.status != .PENDING) return 0;

    var removed_count: usize = 0;
    for (self.callbacks_queue.items) |*callback| {
        switch (callback.data) {
            .ZigGeneric => |*value| {
                if (callback_id == @intFromPtr(value.callback)) {
                    callback.cancelled = true;
                    removed_count += 1;
                }
            },
            .PythonGeneric => |*value| {
                if (callback_id == @intFromPtr(value.callback)) {
                    callback.cancelled = true;
                    removed_count += 1;
                }
            }
        }
    }

    return removed_count;
}

pub inline fn call_done_callbacks(self: *Future, new_status: Future.FutureStatus) !void {
    if (self.status != .PENDING) return error.FutureAlreadyFinished;
    defer self.status = new_status;

    if (self.callbacks_queue.items.len > 0) {
        return;
    }

    const pyfut = utils.get_parent_ptr(Future.Python.FutureObject, self);
    python_c.py_incref(@ptrCast(pyfut));
    errdefer python_c.py_decref(@ptrCast(pyfut));

    const callback = CallbackManager.Callback{
        .func = &run_python_future_set_callbacks,
        .cleanup = &release_python_future_data,
        .data = .{
            .user_data = self,
            .exception_context = .{
                .callback_ptr = null,
                .exc_message = ExceptionMessage,
                .module_name = ModuleName,
                .module_ptr = @ptrCast(utils.get_parent_ptr(Future.Python.FutureObject, self)),
            }
        }
    };

    try Loop.Scheduling.Soon.dispatch(self.loop, callback);
}
