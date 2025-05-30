const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("utils");

const CallbackManager = @import("callback_manager");

const Task = @import("main.zig");
const Future = @import("../future/main.zig");
const Loop = @import("../loop/main.zig");

const std = @import("std");

pub const Data = struct {
    task: *Task.PythonTaskObject,
    exc_value: ?PyObject = null
};


pub const LeviathanPyTaskWakeupMethod = python_c.PyMethodDef{
    .ml_name = "wake_up_task\x00",
    .ml_meth = @ptrCast(&py_wake_up),
    .ml_doc = "Wakeup the task.\x00",
    .ml_flags = python_c.METH_O
};

inline fn set_fut_waiter(
    task: *Task.PythonTaskObject, future: PyObject
) void {
    if (task.fut_waiter) |_| {
        @panic("task.fut_waiter is not null");
    }else{
        task.fut_waiter = python_c.py_newref(future);
    }
}

inline fn set_result(
    task: *Task.PythonTaskObject, future_data: *Future,
    result: PyObject
) !void {
    if (task.must_cancel) {
        _ = try Future.Python.Cancel.future_fast_cancel(&task.fut, future_data, task.fut.cancel_msg_py_object);
    }else{
        Future.Python.Result.future_fast_set_result(future_data, result);
    }
}

fn create_new_py_exception_and_add_event(
    loop: *Loop, allocator: std.mem.Allocator, comptime fmt: []const u8,
    task: *Task.PythonTaskObject,
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

    const exception = python_c.PyObject_CallOneArg(python_c.PyExc_RuntimeError, py_message)
        orelse return error.PythonError;
    errdefer python_c.py_decref(exception);

    const callback: CallbackManager.Callback = .{
        .func = &execute_task_throw,
        .cleanup = &cleanup_task,
        .data = .{
            .user_data = task,
            .exception_context = .{
                .callback_ptr = task.coro.?,
                .exc_message = Task.ExceptionMessage,
                .module_name = Task.ModuleName,
                .module_ptr = @ptrCast(task)
            }
        }
    };

    try Loop.Scheduling.Soon.dispatch(loop, &callback);
    python_c.py_incref(@ptrCast(task));
} 

inline fn cancel_future_object(
    task: *Task.PythonTaskObject, future: anytype
) !void {
    if (@TypeOf(future) == *Future.Python.FutureObject) {
        const cancel_msg = task.fut.cancel_msg_py_object;
        python_c.py_xincref(cancel_msg);

        _ = try Future.Python.Cancel.future_fast_cancel(
            future, utils.get_data_ptr(Future, &task.fut), cancel_msg
        );
    }else{
        const cancel_function: PyObject = python_c.PyObject_GetAttrString(
            future, "cancel\x00"
        ) orelse return error.PythonError;
        defer python_c.py_decref(cancel_function);

        const ret: PyObject = blk: {
            if (task.fut.cancel_msg_py_object) |msg| {
                break :blk python_c.PyObject_CallOneArg(cancel_function, msg) orelse {
                    return error.PythonError;
                };
            }else{
                break :blk python_c.PyObject_CallNoArgs(cancel_function) orelse {
                    return error.PythonError;
                };
            }
        };
        python_c.py_decref(ret);
    }
}

fn create_wake_up_task_callback(task: *Task.PythonTaskObject) !PyObject {
    const wrapper = python_c.PyCFunction_New(
        @constCast(&LeviathanPyTaskWakeupMethod), @ptrCast(task)
    ) orelse return error.PythonError;

    task.wake_up_task_callback = wrapper;
    return wrapper;
}

inline fn handle_legacy_future_object(
    task: *Task.PythonTaskObject, future: PyObject
) !void { 
    const py_loop: *Loop.Python.LoopObject = @ptrCast(task.fut.py_loop.?);
    const loop_data = utils.get_data_ptr(Loop, py_loop);
    const allocator = loop_data.allocator;

    const asyncio_future_blocking: PyObject = python_c.PyObject_GetAttrString(
        future, "_asyncio_future_blocking\x00"
    ) orelse return error.PythonError;

    if (!python_c.type_check(asyncio_future_blocking, &python_c.PyBool_Type)) {
        try create_new_py_exception_and_add_event(
            loop_data, allocator, "Task {s} got bad yield: {s}\x00",
            task, asyncio_future_blocking
        );

        return;
    }

    if (python_c.Py_IsTrue(asyncio_future_blocking) != 0) {
        const add_done_callback_func: PyObject = python_c.PyObject_GetAttrString(
            future, "add_done_callback\x00"
        ) orelse return error.PythonError;
        defer python_c.py_decref(add_done_callback_func);
        
        const wrapper = task.wake_up_task_callback orelse try create_wake_up_task_callback(task);

        const ret: PyObject = python_c.PyObject_CallOneArg(add_done_callback_func, wrapper)
            orelse return error.PythonError;
        python_c.py_decref(ret);
        python_c.py_incref(@ptrCast(task));

        if (python_c.PyObject_SetAttrString(future, "_asyncio_future_blocking", python_c.get_py_false()) < 0) {
            return error.PythonError;
        }

        set_fut_waiter(task, future);
        if (task.must_cancel) {
            return cancel_future_object(task, future);
        }

        return;
    }

    try create_new_py_exception_and_add_event(
        loop_data, allocator, "Yield was used instead of yield from in Task {s} with Future {s}\x00",
        task, future
    );

    return;
}

inline fn handle_leviathan_future_object(
    task: *Task.PythonTaskObject,
    future: *Future.Python.FutureObject,
    loop_data: *Loop
) !void {
    const allocator = loop_data.allocator;
    const future_data = utils.get_data_ptr(Future, future);

    const py_loop: *Loop.Python.LoopObject = @ptrCast(future.py_loop.?);
    if (loop_data != utils.get_data_ptr(Loop, py_loop)) {
        try create_new_py_exception_and_add_event(
            loop_data, allocator, "Task {s} and Future {s} are not in the same loop\x00",
            task, @as(PyObject, @ptrCast(future))
        );
        return;
    }

    if (future.blocking > 0) {
        if (@intFromPtr(future) == @intFromPtr(task)) {
            try create_new_py_exception_and_add_event(
                loop_data, allocator, "Task {s} and Future {s} are the same object. Task cannot await on itself\x00",
                task, @as(PyObject, @ptrCast(future))
            );
            return;
        }

        try Future.Callback.add_done_callback(future_data, .{
            .ZigGeneric = .{
                .callback = &wakeup_task,
                .ptr = task
            }
        });
        python_c.py_incref(@ptrCast(task));

        set_fut_waiter(task, @ptrCast(future));
        future.blocking = 0;

        if (task.must_cancel) {
            try cancel_future_object(task, future);
        }

        return;
    }

    try create_new_py_exception_and_add_event(
        loop_data, allocator, "Yield was used instead of yield from in Task {s} with Future {s}\x00",
        task, @as(PyObject, @ptrCast(future))
    );
}

inline fn successfully_execution(
    task: *Task.PythonTaskObject, loop_data: *Loop, result: PyObject
) !void {
    if (python_c.type_check(result, &Future.Python.FutureType)) {
        try handle_leviathan_future_object(task, @ptrCast(result), loop_data);
        return;
    }else if (python_c.is_none(result)) {
        const callback = CallbackManager.Callback{
            .func = &execute_task_send,
            .cleanup = &cleanup_task,
            .data = .{
                .user_data = task,
                .exception_context = .{
                    .callback_ptr = task.coro.?,
                    .exc_message = Task.ExceptionMessage,
                    .module_name = Task.ModuleName,
                    .module_ptr = @ptrCast(task)
                }
            }
        };

        try Loop.Scheduling.Soon.dispatch(loop_data, &callback);
        python_c.py_incref(@ptrCast(task));
        return;
    }

    try handle_legacy_future_object(task, result);
}

fn failed_execution(task: *Task.PythonTaskObject) error{PythonError}!void {
    const exc_match = python_c.PyErr_GivenExceptionMatches;

    const fut: *Future.Python.FutureObject = &task.fut;
    const future_data = utils.get_data_ptr(Future, fut);
    const exception: PyObject = python_c.PyErr_GetRaisedException() orelse return error.PythonError;

    if (exc_match(exception, python_c.PyExc_StopIteration) > 0) {
        const stop_iteration: *python_c.PyStopIterationObject = @ptrCast(exception);
        set_result(task, future_data, stop_iteration.value orelse unreachable) catch |err| {
            utils.handle_zig_function_error(err, {});

            const exc = python_c.PyErr_Occurred() orelse unreachable;
            python_c.PyException_SetCause(exc, exception);

            return error.PythonError;
        };

        python_c.py_decref(exception);
        return;
    }

    const cancelled_error = utils.PythonImports.cancelled_error_exc;
    if (exc_match(exception, cancelled_error) > 0) {
        _ = Future.Python.Cancel.future_fast_cancel(fut, future_data, null) catch |err| {
            utils.handle_zig_function_error(err, {});

            const exc = python_c.PyErr_Occurred() orelse unreachable;
            python_c.PyException_SetCause(exc, exception);

            return error.PythonError;
        };
        python_c.py_decref(exception);
        return;
    }

    Future.Python.Result.future_fast_set_exception(fut, future_data, exception);
    if (
        exc_match(exception, python_c.PyExc_SystemExit) > 0 or
        exc_match(exception, python_c.PyExc_KeyboardInterrupt) > 0
    ) {
        python_c.PyErr_SetRaisedException(python_c.py_newref(exception));
        return error.PythonError;
    }
}

pub fn cleanup_task(ptr: ?*anyopaque) void {
    const task: *Task.PythonTaskObject = @alignCast(@ptrCast(ptr.?));
    python_c.py_decref(@ptrCast(task));
}

inline fn check_gen_ret(
    gen_ret: python_c.PySendResult,
    task: *Task.PythonTaskObject,
    future_data: *Future,
    loop_data: *Loop,
    coro_ret: ?PyObject,
) !void {
    switch (gen_ret) {
        python_c.PYGEN_RETURN => try set_result(task, future_data, coro_ret.?),
        python_c.PYGEN_ERROR => try failed_execution(task),
        else => {
            if (coro_ret) |result| {
                try successfully_execution(task, loop_data, result);
            }else{
                try failed_execution(task);
            }
        }
    }
}

fn _execute_task_throw(task: *Task.PythonTaskObject, task_exception: ?PyObject) !void {
    var exception_value: ?PyObject = task_exception;
    if (task.must_cancel) {
        if (
            exception_value == null or
            python_c.PyErr_GivenExceptionMatches(exception_value, utils.PythonImports.cancelled_error_exc) <= 0
        ) {
            python_c.py_xdecref(exception_value);
            if (task.fut.cancel_msg_py_object) |value| {
                exception_value = python_c.PyObject_CallOneArg(
                    utils.PythonImports.cancelled_error_exc, value
                ) orelse return error.PythonError;
            }else{
                exception_value = python_c.PyObject_CallNoArgs(utils.PythonImports.cancelled_error_exc)
                    orelse return error.PythonError;
            }
        }
    }
    defer python_c.py_decref(exception_value.?);

    const py_fut = &task.fut;
    const py_loop: *Loop.Python.LoopObject = @ptrCast(py_fut.py_loop.?);

    const loop_data = utils.get_data_ptr(Loop, py_loop);
    const future_data = utils.get_data_ptr(Future, py_fut);

    if (future_data.status != .pending) {
        python_c.raise_python_runtime_error("Task already finished");
        try failed_execution(task);
        python_c.py_decref(@ptrCast(task));
        return;
    }

    const enter_task_args: [2]PyObject = .{
        @ptrCast(py_loop), @ptrCast(task)
    };

    const enter_ret: PyObject = python_c.PyObject_Vectorcall(
        utils.PythonImports.enter_task_func, &enter_task_args, enter_task_args.len, null
    ) orelse return error.PythonError;
    python_c.py_decref(enter_ret);

    const context = task.py_context.?;
    if (python_c.PyContext_Enter(context) < 0) {
        return error.PythonError;
    }

    var coro_ret: ?PyObject = null;
    defer python_c.py_xdecref(coro_ret);

    var gen_ret: python_c.PySendResult = python_c.PYGEN_ERROR;
    const coro_throw: PyObject = python_c.PyObject_GetAttrString(task.coro.?, "throw\x00")
        orelse return error.PythonError;
    defer python_c.py_decref(coro_throw);

    if (python_c.PyObject_CallOneArg(coro_throw, exception_value)) |v| {
        coro_ret = v;
        gen_ret = python_c.PYGEN_NEXT;
    }

    if (python_c.PyContext_Exit(context) < 0) {
        return error.PythonError;
    }

    var exception: ?PyObject = null;
    check_gen_ret(
        gen_ret,
        task,
        future_data,
        loop_data,
        coro_ret
    ) catch |err| {
        utils.handle_zig_function_error(err, {});

        exception = python_c.PyErr_GetRaisedException() orelse return error.PythonError;
    };

    const leave_ret = python_c.PyObject_Vectorcall(
        utils.PythonImports.leave_task_func, &enter_task_args, enter_task_args.len, null
    ) orelse return error.PythonError;
    python_c.py_decref(leave_ret);


    if (exception) |exc| {
        python_c.PyErr_SetRaisedException(exc);
        return error.PythonError;
    }

    python_c.py_decref(@ptrCast(task));
}

pub fn execute_task_throw(data: *const CallbackManager.CallbackData) !void {
    const task: *Task.PythonTaskObject = @alignCast(@ptrCast(data.user_data.?));
    @call(.always_inline, _execute_task_throw, .{task, task.exception.?}) catch |err| {
        utils.handle_zig_function_error(err, {});

        const exc = python_c.PyErr_GetRaisedException() orelse return error.PythonError;

        const fut = utils.get_data_ptr(Future, &task.fut);
        Future.Python.Result.future_fast_set_exception(&task.fut, fut, exc);
        python_c.py_decref(@ptrCast(task));
    };
}

fn _execute_task_send(task: *Task.PythonTaskObject) !void {
    if (task.must_cancel) {
        return try _execute_task_throw(task, null);
    }

    const py_fut = &task.fut;
    const py_loop: *Loop.Python.LoopObject = @ptrCast(py_fut.py_loop.?);

    const loop_data = utils.get_data_ptr(Loop, py_loop);
    const future_data = utils.get_data_ptr(Future, py_fut);

    if (future_data.status != .pending) {
        python_c.raise_python_runtime_error("Task already finished");
        try failed_execution(task);
        python_c.py_decref(@ptrCast(task));
        return;
    }

    const enter_task_args: [2]PyObject = .{
        @ptrCast(py_loop), @ptrCast(task)
    };

    const py_none = python_c.get_py_none_without_incref();

    const enter_ret: PyObject = python_c.PyObject_Vectorcall(
        utils.PythonImports.enter_task_func, &enter_task_args, enter_task_args.len, null
    ) orelse return error.PythonError;
    python_c.py_decref(enter_ret);

    const context = task.py_context.?;
    if (python_c.PyContext_Enter(context) < 0) {
        return error.PythonError;
    }

    var coro_ret: ?PyObject = null;
    defer python_c.py_xdecref(coro_ret);

    const gen_ret: python_c.PySendResult = python_c.PyIter_Send(task.coro.?, py_none, &coro_ret);

    if (python_c.PyContext_Exit(context) < 0) {
        return error.PythonError;
    }

    var exception: ?PyObject = null;
    check_gen_ret(
        gen_ret,
        task,
        future_data,
        loop_data,
        coro_ret
    ) catch |err| {
        utils.handle_zig_function_error(err, {});

        exception = python_c.PyErr_GetRaisedException() orelse return error.PythonError;
    };

    const leave_ret = python_c.PyObject_Vectorcall(
        utils.PythonImports.leave_task_func, &enter_task_args, enter_task_args.len, null
    ) orelse return error.PythonError;
    python_c.py_decref(leave_ret);


    if (exception) |exc| {
        python_c.PyErr_SetRaisedException(exc);
        return error.PythonError;
    }

    python_c.py_decref(@ptrCast(task));
}

pub fn execute_task_send(data: *const CallbackManager.CallbackData) !void {
    const task: *Task.PythonTaskObject = @alignCast(@ptrCast(data.user_data.?));
    @call(.always_inline, _execute_task_send, .{task}) catch |err| {
        utils.handle_zig_function_error(err, {});

        const exc = python_c.PyErr_GetRaisedException() orelse return error.PythonError;

        const fut = utils.get_data_ptr(Future, &task.fut);
        Future.Python.Result.future_fast_set_exception(&task.fut, fut, exc);
        python_c.py_decref(@ptrCast(task));
    };
}

fn wakeup_task(fut: ?*Future.Python.FutureObject, ptr: ?*anyopaque) !void {
    const task: *Task.PythonTaskObject = @alignCast(@ptrCast(ptr.?));
    python_c.py_decref_and_set_null(&task.fut_waiter);

    const leviathan_fut = fut orelse {
        python_c.py_decref(@ptrCast(task));
        return;
    };
    errdefer python_c.py_decref(@ptrCast(task));

    if (leviathan_fut.exception) |exception| {
        _execute_task_throw(task, python_c.py_newref(exception)) catch |err| {
            utils.handle_zig_function_error(err, {});

            const exc = python_c.PyErr_GetRaisedException() orelse return error.PythonError;

            const future_data = utils.get_data_ptr(Future, &task.fut);
            Future.Python.Result.future_fast_set_exception(&task.fut, future_data, exc);
            python_c.py_decref(@ptrCast(task));
        };
        return;
    }

    _execute_task_send(task) catch |err| {
        utils.handle_zig_function_error(err, {});

        const exc = python_c.PyErr_GetRaisedException() orelse return error.PythonError;

        const future_data = utils.get_data_ptr(Future, &task.fut);
        Future.Python.Result.future_fast_set_exception(&task.fut, future_data, exc);
        python_c.py_decref(@ptrCast(task));
    };
}

fn py_wake_up(
    self: ?*Task.PythonTaskObject, fut: ?PyObject
) callconv(.C) ?PyObject {
    const instance = self.?;
    const py_future = fut.?;

    python_c.py_decref_and_set_null(&instance.fut_waiter);

    const get_result_func: PyObject = python_c.PyObject_GetAttrString(py_future, "result\x00")
        orelse return null;
    defer python_c.py_decref(get_result_func);

    const ret: ?PyObject = python_c.PyObject_CallNoArgs(get_result_func);
    if (ret) |result| {
        python_c.py_decref(result);

        _execute_task_send(instance) catch |err| {
            python_c.py_decref(@ptrCast(instance));
            return utils.handle_zig_function_error(err, null);
        };
    }else{
        const exc_value = python_c.PyErr_GetRaisedException() orelse return null;
        _execute_task_throw(instance, exc_value) catch |err| {
            python_c.py_decref(@ptrCast(instance));
            return utils.handle_zig_function_error(err, null);
        };
    }

    return python_c.get_py_none();
}
