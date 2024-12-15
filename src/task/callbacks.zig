const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../utils/utils.zig");

const CallbackManager = @import("../callback_manager.zig");

const Task = @import("main.zig");
const Future = @import("../future/main.zig");
const Loop = @import("../loop/main.zig");

const std = @import("std");
const builtin = @import("builtin");

pub const TaskCallbackData = struct {
    task: *Task.constructors.PythonTaskObject,
    exc_value: ?PyObject = null
};


const LeviathanPyTaskWakeupMethod = python_c.PyMethodDef{
    .ml_name = "wake_up_task\x00",
    .ml_meth = @ptrCast(&py_wake_up),
    .ml_doc = "Wakeup the task.\x00",
    .ml_flags = python_c.METH_O
};


fn create_new_py_exception_and_add_event(
    loop: *Loop, allocator: std.mem.Allocator, comptime fmt: []const u8,
    task: *Task.constructors.PythonTaskObject,
    result: PyObject
) !void {
    const task_repr: PyObject = python_c.PyObject_Repr(@ptrCast(task)) orelse return error.PythonError;
    defer python_c.py_decref(task_repr);

    const result_repr: PyObject = python_c.PyObject_Repr(result) orelse return error.PythonError;
    defer python_c.py_decref(result_repr);

    const task_repr_unicode: [*c]const u8 = python_c.PyUnicode_AsUTF8(task_repr) orelse return error.PythonError;
    const result_repr_unicode: [*c]const u8 = python_c.PyUnicode_AsUTF8(result_repr) orelse return error.PythonError;

    const task_repr_unicode_len = std.mem.len(task_repr_unicode);
    const result_repr_unicode_len = std.mem.len(result_repr_unicode);

    const message = try std.fmt.allocPrint(
        allocator, fmt, .{
            task_repr_unicode[0..task_repr_unicode_len],
            result_repr_unicode[0..result_repr_unicode_len]
        }
    );
    defer allocator.free(message);

    const py_message: PyObject = python_c.PyUnicode_FromString(message.ptr) orelse return error.PythonError;
    defer python_c.py_decref(py_message);

    const exception = python_c.PyObject_CallOneArg(python_c.PyExc_RuntimeError, task_repr)
        orelse return error.PythonError;
    errdefer python_c.py_decref(exception);

    const callback = .{
        .PythonTask = .{
            .task = task,
            .exc_value = exception
        }
    };

    if (builtin.single_threaded) {
        try loop.call_soon(callback);
    }else{
        try loop.call_soon_threadsafe(callback);
    }
    python_c.py_incref(@ptrCast(task));
} 

inline fn execute_zig_function(
    comptime function: anytype, args: anytype
) CallbackManager.ExecuteCallbacksReturn {
    @call(.auto, function, args) catch |err| {
        if (err != error.PythonError) {
            utils.put_python_runtime_error_message(@errorName(err));
        }
        return .Exception;
    };

    return .Continue;
}

inline fn cancel_future_object(
    task: *Task.constructors.PythonTaskObject, future: anytype
) CallbackManager.ExecuteCallbacksReturn {
    if (@TypeOf(future) == *Future.constructors.PythonFutureObject) {
        if (!Future.cancel.future_fast_cancel(future, future.future_obj.?, task.fut.cancel_msg_py_object)) {
            return .Exception;
        }
    }else{
        const cancel_function: PyObject = python_c.PyObject_GetAttrString(
            future, "cancel\x00"
        );
        defer python_c.py_decref(cancel_function);

        const ret: PyObject = blk: {
            if (task.fut.cancel_msg_py_object) |msg| {
                break :blk python_c.PyObject_CallOneArg(cancel_function, msg) orelse {
                    return .Exception;
                };
            }else{
                break :blk python_c.PyObject_CallNoArgs(cancel_function) orelse {
                    return .Exception;
                };
            }
        };
        python_c.py_decref(ret);
    }

    return .Continue;
}

inline fn handle_legacy_future_object(
    task: *Task.constructors.PythonTaskObject, future: PyObject
) CallbackManager.ExecuteCallbacksReturn {
    const loop = task.fut.py_loop.?.loop_obj.?;
    const allocator = loop.allocator;

    const asyncio_future_blocking: PyObject = python_c.PyObject_GetAttrString(
        future, "_asyncio_future_blocking\x00"
    ) orelse return .Exception;

    if (python_c.PyBool_Check(asyncio_future_blocking) == 0) {
        return execute_zig_function(
            create_new_py_exception_and_add_event, .{
                loop, allocator, "Task {s} got bad yield: {s}\x00",
                task, future
            }
        );
    }

    if (python_c.Py_IsTrue(asyncio_future_blocking) != 1) {
        const add_done_callback_func: PyObject = python_c.PyObject_GetAttrString(
            future, "add_done_callback\x00"
        ) orelse return .Exception;
        defer python_c.py_decref(add_done_callback_func);

        const wrapper: PyObject = python_c.PyCFunction_New(
            @constCast(&LeviathanPyTaskWakeupMethod), @ptrCast(task)
        ) orelse return .Exception;

        const ret: PyObject = python_c.PyObject_CallOneArg(add_done_callback_func, wrapper) orelse {
            python_c.py_decref(wrapper);
            return .Exception;
        };
        python_c.py_decref(ret);
        python_c.py_incref(@ptrCast(task));
        
        if (python_c.PyObject_SetAttrString(future, "_asyncio_future_blocking", python_c.get_py_false()) < 0) {
            return .Exception;
        }

        python_c.py_decref(task.fut_waiter.?);
        task.fut_waiter = python_c.py_newref(future);
        if (task.must_cancel) {
            return cancel_future_object(task, future);
        }

        return .Continue;
    }

    return execute_zig_function(
        create_new_py_exception_and_add_event, .{
            loop, allocator, "Yield was used instead of yield from in Task {s} with Future {s}\x00",
            task, future
        }
    );
}

inline fn handle_leviathan_future_object(
    task: *Task.constructors.PythonTaskObject,
    future: *Future.constructors.PythonFutureObject
) CallbackManager.ExecuteCallbacksReturn {
    const loop = task.fut.py_loop.?.loop_obj.?;
    const allocator = loop.allocator;

    const future_obj = future.future_obj.?;
    const mutex = &future_obj.mutex;

    mutex.lock();
    defer mutex.unlock();

    if (loop != future.py_loop.?.loop_obj.?) {
        return execute_zig_function(
            create_new_py_exception_and_add_event, .{
                loop, allocator, "Task {s} and Future {s} are not in the same loop\x00",
                task, @as(PyObject, @ptrCast(future))
            }
        );
    }

    if (future.blocking > 0) {
        if (@intFromPtr(future) == @intFromPtr(task)) {
            return execute_zig_function(
                create_new_py_exception_and_add_event, .{
                    loop, allocator, "Task {s} and Future {s} are the same object. Task cannot await on itself\x00",
                    task, @as(PyObject, @ptrCast(future))
                }
            );
        }

        const callback: CallbackManager.Callback = .{
            .ZigGeneric = .{
                .callback = &wakeup_task,
                .data = task
            }
        };

        const ret = execute_zig_function(
            Future.add_done_callback, .{future_obj, callback}
        );
        if (ret == .Continue) {
            python_c.py_incref(@ptrCast(task));

            python_c.py_decref(task.fut_waiter.?);
            task.fut_waiter = @ptrCast(python_c.py_newref(future));
            future.blocking = 0;

            if (task.must_cancel) {
                return cancel_future_object(task, future);
            }
        }

        return ret;
    }

    return execute_zig_function(
        create_new_py_exception_and_add_event, .{
            loop, allocator, "Yield was used instead of yield from in Task {s} with Future {s}\x00",
            task, @as(PyObject, @ptrCast(future))
        }
    );
}

inline fn successfully_execution(
    task: *Task.constructors.PythonTaskObject, result: PyObject
) CallbackManager.ExecuteCallbacksReturn {
    if (python_c.PyObject_TypeCheck(result, &Future.PythonFutureType) != 0) {
        return handle_leviathan_future_object(task, @ptrCast(result));
    }else if (python_c.Py_IsNone(result) != 0) {
        const loop = task.fut.py_loop.?.loop_obj.?;

        const callback: CallbackManager.Callback = .{
            .PythonTask = .{
                .task = task
            }
        };
        if (builtin.single_threaded) {
            loop.call_soon(callback) catch |err| {
                utils.put_python_runtime_error_message(@errorName(err));
                return .Exception;
            };
        }else{
            loop.call_soon_threadsafe(callback) catch |err| {
                utils.put_python_runtime_error_message(@errorName(err));
                return .Exception;
            };
        }

        python_c.py_incref(@ptrCast(task));
        return .Continue;
    }

    return handle_legacy_future_object(task, result);
}

inline fn failed_execution(task: *Task.constructors.PythonTaskObject) CallbackManager.ExecuteCallbacksReturn {
    const exc_match = python_c.PyErr_ExceptionMatches;

    const fut: *Future.constructors.PythonFutureObject = &task.fut;
    const future_obj = fut.future_obj.?;
    const exception = python_c.PyErr_GetRaisedException() orelse return .Exception;
    defer python_c.py_decref(exception);

    if (exc_match(python_c.PyExc_StopIteration) > 0) {
        if (task.must_cancel) {
            if (!Future.cancel.future_fast_cancel(fut, future_obj, fut.cancel_msg_py_object)) {
                return .Exception;
            }
        }else{
            const value: PyObject = python_c.PyObject_GetAttrString(exception, "value\x00")
                orelse return .Exception;
            return execute_zig_function(
                Future.result.future_fast_set_result, .{future_obj, value}
            );
        }

        return .Continue;
    }

    const cancelled_error = task.fut.py_loop.?.cancelled_error_exc.?;
    if (exc_match(cancelled_error) > 0) {
        if (!Future.cancel.future_fast_cancel(fut, future_obj, null)) {
            return .Exception;
        }
        return .Continue;
    }

    if (
        utils.execute_zig_function(
            Future.result.future_fast_set_exception, .{fut, future_obj, exception}
        ) < 0 or
        exc_match(python_c.PyExc_SystemExit) > 0 or
        exc_match(python_c.PyExc_KeyboardInterrupt) > 0
    ) {
        return .Exception;
    }

    return .Continue;
}

pub inline fn release_python_task_callback(task: *Task.constructors.PythonTaskObject, exc_value: ?PyObject) void {
    python_c.py_decref(@ptrCast(task));
    python_c.py_xdecref(exc_value);
}

pub fn step_run_and_handle_result_task(
    task: *Task.constructors.PythonTaskObject, exc_value: ?PyObject
) CallbackManager.ExecuteCallbacksReturn {
    var exception_value: ?PyObject = exc_value;
    defer release_python_task_callback(task, exception_value);

    const future = task.fut.future_obj.?;
    const mutex = &future.mutex;
    mutex.lock();
    defer mutex.unlock();

    if (future.status != .PENDING) {
        utils.put_python_runtime_error_message(
            "Task already finished\x00"
        );
        return .Exception;
    }

    if (task.must_cancel) {
        if (
            exception_value == null or
            python_c.PyObject_TypeCheck(exception_value.?, python_c.Py_TYPE(task.fut.cancelled_error_exc.?)) == 0
        ) {
            python_c.py_decref(exception_value.?);
            exception_value = blk: {
                if (task.fut.cancel_msg_py_object) |value| {
                    break :blk python_c.PyObject_CallOneArg(
                               task.fut.cancelled_error_exc.?, value
                           ) orelse return .Exception;
                }else{
                    break :blk python_c.PyObject_CallNoArgs(task.fut.cancelled_error_exc.?) orelse return .Exception;
                }
            };
        }
        task.must_cancel = false;
    }

    mutex.unlock();
    const ret: ?PyObject = blk: {
        if (exception_value) |value| {
            break :blk python_c.PyObject_CallOneArg(task.coro_throw.?, value);
        }else{
            const py_none = python_c.get_py_none();
            defer python_c.py_decref(py_none);

            break :blk python_c.PyObject_CallOneArg(task.coro_send.?, py_none);
        }
    };
    mutex.lock();

    if (ret) |result| {
        defer python_c.py_decref(result);
        return successfully_execution(task, result);
    }

    return failed_execution(task);
}

fn wakeup_task(
    data: ?*anyopaque, status: CallbackManager.ExecuteCallbacksReturn
) CallbackManager.ExecuteCallbacksReturn {
    const task: *Task.constructors.PythonTaskObject = @alignCast(@ptrCast(data.?));

    const py_future = task.fut_waiter.?;
    if (status != .Continue) {
        python_c.py_decref(py_future);
        python_c.py_decref(@ptrCast(task));
        return status;
    }

    var exc_value: ?PyObject = null;
    defer {
        python_c.py_decref(py_future);
        task.fut_waiter = python_c.get_py_none();
    }

    if (python_c.PyObject_TypeCheck(py_future, &Future.PythonFutureType) != 0) {
        const leviathan_fut: *Future.constructors.PythonFutureObject = @alignCast(@ptrCast(py_future));
        if (leviathan_fut.exception) |exception| {
            if (python_c.Py_IsNone(exception) == 0) { // For task the value can be None
                exc_value = python_c.py_newref(exception);
            }
        }
    }else{
        // Third party future
        const get_result_func: PyObject = python_c.PyObject_GetAttrString(py_future, "result\x00")
            orelse return .Exception;
        defer python_c.py_decref(get_result_func);

        const ret: ?PyObject = python_c.PyObject_CallNoArgs(get_result_func);
        if (ret) |result| {
            python_c.py_decref(result);
        }else{
            exc_value = python_c.PyErr_GetRaisedException() orelse return .Exception;
        }
    }

    return step_run_and_handle_result_task(task, exc_value);
}

fn py_wake_up(
    self: ?*Task.constructors.PythonTaskObject, fut: ?PyObject
) ?PyObject {
    _ = fut.?;
    const ret: CallbackManager.ExecuteCallbacksReturn = @call(.always_inline, wakeup_task, .{self, .Continue});
    return switch (ret) {
        .Continue => python_c.get_py_none(),
        .Stop => blk: {
            utils.put_python_runtime_error_message("Stop signal received\x00");
            break :blk null;
        },
        .Exception => null
    };
}
