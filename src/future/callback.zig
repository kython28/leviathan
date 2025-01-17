const std = @import("std");

const CallbackManager = @import("../callback_manager.zig");
const Loop = @import("../loop/main.zig");
const Future = @import("main.zig");

const CallbacksSetLinkedList = CallbackManager.LinkedList;
const utils = @import("../utils/utils.zig");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const MaxCallbacks = 8;

pub const CallbacksSetData = struct {
    sets_queue: *CallbackManager.CallbacksSetsQueue,
    future: *Future.Python.FutureObject,
};

pub const Data = struct {
    py_future: PyObject,
    py_callback: PyObject,
    py_context: PyObject,
    exception_handler: PyObject,
    can_execute: bool = true,
    dec_future: bool = false
};

pub inline fn release_python_future_callback(data: Data) void {
    python_c.py_decref(data.py_callback);
    python_c.py_decref(data.py_context);
    if (data.dec_future) python_c.py_decref(data.py_future);
}

pub fn callback_for_python_future_callbacks(data: Data) CallbackManager.ExecuteCallbacksReturn {
    defer release_python_future_callback(data);
    if (!data.can_execute) return .Continue;

    const py_future = data.py_future;
    const py_callback = data.py_callback;
    const py_context = data.py_context;

    if (python_c.PyContext_Enter(py_context) < 0) {
        return .Exception;
    }

    const result: ?PyObject = python_c.PyObject_CallOneArg(py_callback, py_future);

    if (python_c.PyContext_Exit(py_context) < 0) {
        python_c.py_xdecref(result);
        return .Exception;
    }

    if (result) |value| {
        python_c.py_decref(value);
    }else{
        if (
            python_c.PyErr_ExceptionMatches(python_c.PyExc_SystemExit) > 0 or
            python_c.PyErr_ExceptionMatches(python_c.PyExc_KeyboardInterrupt) > 0
        ) {
            return .Exception;
        }

        const exception: PyObject = python_c.PyErr_GetRaisedException()
            orelse return .Exception;
        defer python_c.py_decref(exception);

        const exc_message: PyObject = python_c.PyUnicode_FromString("Exception ocurred executing future done callback\x00")
            orelse return .Exception;
        defer python_c.py_decref(exc_message);

        var exc_args: [4]PyObject = undefined;
        exc_args[0] = exception;
        exc_args[1] = exc_message;
        exc_args[2] = py_callback;
        exc_args[3] = py_future;

        const message_kname: PyObject = python_c.PyUnicode_FromString("message\x00")
            orelse return .Exception;
        defer python_c.py_decref(message_kname);

        const callback_kname: PyObject = python_c.PyUnicode_FromString("callback\x00")
            orelse return .Exception;
        defer python_c.py_decref(callback_kname);

        const future_kname: PyObject = python_c.PyUnicode_FromString("future\x00")
            orelse return .Exception;
        defer python_c.py_decref(future_kname);

        const knames: PyObject = python_c.PyTuple_Pack(3, message_kname, callback_kname, future_kname)
            orelse return .Exception;
        defer python_c.py_decref(knames);

        const exc_handler_ret: PyObject = python_c.PyObject_Vectorcall(data.exception_handler, &exc_args, 1, knames)
            orelse return .Exception;
        python_c.py_decref(exc_handler_ret);
    }

    return .Continue;
}

pub inline fn run_python_future_set_callbacks(
    allocator: std.mem.Allocator, data: CallbacksSetData, status: CallbackManager.ExecuteCallbacksReturn
) CallbackManager.ExecuteCallbacksReturn {
    defer python_c.py_decref(@ptrCast(data.future));
    return CallbackManager.execute_callbacks(allocator, data.sets_queue, status, false);
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

pub inline fn add_done_callback(
    self: *Future, callback: CallbackManager.Callback
) !void {
    if (self.status != .PENDING) return error.FutureAlreadyFinished;

    const allocator = self.callbacks_arena_allocator;
    _ = try CallbackManager.append_new_callback(
        allocator, &self.callbacks_queue, callback, MaxCallbacks
    );
}

pub fn remove_done_callback(self: *Future, callback_id: u64) usize {
    if (self.status != .PENDING) return 0;

    const callbacks_queue = &self.callbacks_queue.queue;
    var node = callbacks_queue.first;
    var removed_count: usize = 0;
    while (node) |n| {
        node = n.next;
        const queue: CallbackManager.CallbacksSet = n.data;
        for (queue.callbacks[0..queue.callbacks_num]) |*callback| {
            switch (@as(CallbackManager.CallbackType, callback.*)) {
                .ZigGeneric => {
                    if (@as(u64, @intFromPtr(callback.ZigGeneric.callback)) == callback_id) {
                        callback.ZigGeneric.can_execute = false;
                        removed_count += 1;
                    }
                },
                .PythonFuture => {
                    if (@as(u64, @intFromPtr(callback.PythonFuture.py_callback)) == callback_id) {
                        callback.PythonFuture.can_execute = false;
                        removed_count += 1;
                    }
                },
                else => unreachable
            }
        }
    }

    return removed_count;
}

pub inline fn call_done_callbacks(self: *Future, new_status: Future.FutureStatus) !void {
    if (self.status != .PENDING) return error.FutureAlreadyFinished;
    defer self.status = new_status;

    if (self.callbacks_queue.last_set == null) {
        return;
    }

    const pyfut = utils.get_parent_ptr(Future.Python.FutureObject, self);
    python_c.py_incref(@ptrCast(pyfut));
    errdefer python_c.py_decref(@ptrCast(pyfut));

    const callback: CallbackManager.Callback = .{
        .PythonFutureCallbacksSet = .{
            .sets_queue = &self.callbacks_queue,
            .future = pyfut
        }
    };

    try Loop.Scheduling.Soon.dispatch(self.loop, callback);
}
