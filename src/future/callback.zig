const std = @import("std");

const CallbackManager = @import("callback_manager");
const Loop = @import("../loop/main.zig");
const Future = @import("main.zig");

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
    callback: *const fn (?*Future.Python.FutureObject, ?*anyopaque) anyerror!void,
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

inline fn execute_python_callback(context: PyObject, callback: PyObject, future: PyObject) !void {
    defer {
        python_c.py_decref(context);
        python_c.py_decref(callback);
    }

    if (python_c.PyContext_Enter(context) < 0) {
        return error.PythonError;
    }

    const result: ?PyObject = python_c.PyObject_CallOneArg(callback, future);

    if (python_c.PyContext_Exit(context) < 0) {
        return error.PythonError;
    }

    if (result) |v| {
        python_c.py_decref(v);
    }else{
        return error.PythonError;
    }
}

fn run_python_future_set_callbacks(data: *const CallbackManager.CallbackData) !void {
    const future: *Future = @alignCast(@ptrCast(data.user_data.?));
    const py_future = utils.get_parent_ptr(Future.Python.FutureObject, future);

    if (data.cancelled) {
        release_callbacks_queue(&future.callbacks_queue);
        python_c.py_decref(@ptrCast(py_future));
        return;
    }
    const callbacks_items = future.callbacks_queue.items;

    var exceptions_array = std.ArrayList(?PyObject).init(future.loop.allocator);
    defer {
        for (exceptions_array.items) |exc| {
            python_c.py_xdecref(exc);
        }

        exceptions_array.deinit();
    }

    for (callbacks_items) |*callback| {
        if (callback.cancelled) continue;

        switch (callback.data) {
            .PythonGeneric => |py_data| {
                execute_python_callback(py_data.context, py_data.callback, @ptrCast(py_future)) catch |err| {
                    utils.handle_zig_function_error(err, {});

                    const exc = python_c.PyErr_GetRaisedException() orelse return error.PythonError;
                    exceptions_array.append(exc) catch |err2| {
                        python_c.py_decref(exc);
                        return err2;
                    };
                };
            },
            .ZigGeneric => |z_data| {
                z_data.callback(py_future, z_data.ptr) catch |err| {
                    utils.handle_zig_function_error(err, {});

                    const exc = python_c.PyErr_GetRaisedException() orelse return error.PythonError;
                    exceptions_array.append(exc) catch |err2| {
                        python_c.py_decref(exc);
                        return err2;
                    };
                };
            }
        }
    }

    const exceptions_len = exceptions_array.items.len;
    if (exceptions_len > 0) {
        const exc_tuple = python_c.PyTuple_New(@intCast(exceptions_len)) orelse return error.PythonError;
        defer python_c.py_decref(exc_tuple);

        for (0.., exceptions_array.items) |i, *exc| {
            if (python_c.PyTuple_SetItem(exc_tuple, @intCast(i), exc.*) < 0) {
                return error.PythonError;
            }

            exc.* = null;
        }

        const exception_message = python_c.PyUnicode_FromString("Multiple exceptions occurred while executing future callbacks\x00")
            orelse return error.PythonError;
        defer python_c.py_decref(exception_message);

        const exc = python_c.PyObject_CallFunctionObjArgs(python_c.PyExc_BaseExceptionGroup, exception_message, exc_tuple)
            orelse return error.PythonError;
        python_c.PyErr_SetRaisedException(exc);
        
        return error.PythonError;
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
                data.callback(null, data.ptr) catch |err| {
                    std.debug.panic("Unexpected error while releasing future callbacks: {s}", .{@errorName(err)});
                };
            }
        }
    }
}

pub inline fn add_done_callback(self: *Future, callback_data: Data) !void {
    if (self.status != .pending) return error.FutureAlreadyFinished;

    try self.callbacks_queue.append(.{
        .data = callback_data
    });
}

pub fn remove_done_callback(self: *Future, callback_id: u64) usize {
    if (self.status != .pending) return 0;

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

pub inline fn call_done_callbacks(self: *Future, new_status: Future.FutureStatus) void {
    if (self.status != .pending) unreachable;

    self.status = new_status;

    if (self.callbacks_queue.items.len == 0) {
        return;
    }

    const pyfut = utils.get_parent_ptr(Future.Python.FutureObject, self);
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

    Loop.Scheduling.Soon.dispatch_guaranteed(self.loop, &callback);
    python_c.py_incref(@ptrCast(pyfut));
}
