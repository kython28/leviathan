const Loop = @import("main.zig");
const CallbackManager = @import("callback_manager");

const BlockingTasksSetLinkedList = Loop.Scheduling.IO.BlockingTasksSetLinkedList;
const CallbacksSetLinkedList = CallbackManager.CallbacksSetLinkedList;

const Lock = @import("../utils/lock.zig").Mutex;

const utils = @import("utils");
const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const std = @import("std");
const builtin = @import("builtin");

const BlockingTasksSetQuarantineArray = std.ArrayList(*Loop.Scheduling.IO.BlockingTasksSet);

// ------------------------------------------------------------
// https://github.com/ziglang/zig/issues/1499
const PyThreadState = opaque {};
extern fn PyEval_SaveThread() ?*PyThreadState;
extern fn PyEval_RestoreThread(?*PyThreadState) void;
// ------------------------------------------------------------

inline fn free_callbacks_set(
    allocator: std.mem.Allocator, node: CallbacksSetLinkedList.Node,
    comptime field_name: []const u8
) CallbacksSetLinkedList.Node {
    const callbacks_set: CallbackManager.CallbacksSet = node.data;
    CallbackManager.release_set(allocator, callbacks_set);

    const next_node = @field(node, field_name).?;
    allocator.destroy(node);

    return next_node;
}

pub fn prune_callbacks_sets(
    allocator: std.mem.Allocator, ready_tasks: *CallbackManager.CallbacksSetsQueue,
    max_number_of_callbacks_set_ptr: *usize, ready_tasks_queue_min_bytes_capacity: usize
) void {
    const queue = &ready_tasks.queue;
    var queue_len = queue.len;
    const max_number_of_callbacks_set = max_number_of_callbacks_set_ptr.*;
    if (queue_len <= max_number_of_callbacks_set) return;

    if (max_number_of_callbacks_set == 1) {
        var node = queue.last.?;
        while (queue_len > max_number_of_callbacks_set) : (queue_len -= 1) {
            node = free_callbacks_set(allocator, node, "prev");
        }
        node.next = null;
        queue.last = node;
        queue.len = queue_len;
    }else{
        var node = queue.first.?;
        while (queue_len > max_number_of_callbacks_set) : (queue_len -= 1) {
            node = free_callbacks_set(allocator, node, "next");
        }

        const callbacks_set: CallbackManager.CallbacksSet = node.data;
        node.prev = null;
        queue.first = node;
        ready_tasks.last_set = node;
        queue.len = queue_len;

        max_number_of_callbacks_set_ptr.* = CallbackManager.get_max_callbacks_sets(
            ready_tasks_queue_min_bytes_capacity, callbacks_set.callbacks.len
        );
    }
}

fn exception_handler(
    err: anyerror, py_exception_handler: ?*anyopaque,
    context: ?CallbackManager.CallbackExceptionContext
) !void {
    utils.handle_zig_function_error(err, {});
    const exception = python_c.PyErr_GetRaisedException() orelse return error.PythonError;

    if (
        python_c.PyErr_GivenExceptionMatches(exception, python_c.PyExc_SystemExit) > 0 or
        python_c.PyErr_GivenExceptionMatches(exception, python_c.PyExc_KeyboardInterrupt) > 0
    ) {
        python_c.PyErr_SetRaisedException(exception);
        return;
    }

    const message_kname: PyObject = python_c.PyUnicode_FromString("message\x00")
        orelse return error.PythonError;
    defer python_c.py_decref(message_kname);

    const callback_kname: PyObject = python_c.PyUnicode_FromString("callback\x00")
        orelse return error.PythonError;
    defer python_c.py_decref(callback_kname);

    var args: [4]PyObject = undefined;
    args[0] = exception;

    var knames_len: python_c.Py_ssize_t = 1;
    var module_kname: ?PyObject = null;
    var exc_message: PyObject = undefined;
    defer {
        python_c.py_xdecref(module_kname);
        python_c.py_decref(exc_message);
    }

    if (context) |ctx| {
        module_kname = python_c.PyUnicode_FromString(ctx.module_name)
            orelse return error.PythonError;

        exc_message = python_c.PyUnicode_FromString(ctx.exc_message)
            orelse return error.PythonError;

        args[2] = ctx.module_ptr;
        if (ctx.callback_ptr) |c_ptr| {
            args[3] = c_ptr;
            knames_len = 3;
        }else{
            knames_len = 2;
        }
    }else{
        exc_message = python_c.PyUnicode_FromString("Exception ocurred executing an event\x00")
            orelse return error.PythonError;
    }

    args[1] = exc_message;

    const knames: PyObject = python_c.PyTuple_Pack(
        knames_len, message_kname, module_kname, callback_kname
    ) orelse return error.PythonError;
    defer python_c.py_decref(knames);

    const exc_handler_ret: PyObject = python_c.PyObject_Vectorcall(
        @alignCast(@ptrCast(py_exception_handler.?)), &args, 1, knames
    ) orelse return error.PythonError;
    python_c.py_decref(exc_handler_ret);
}

pub inline fn call_once(
    allocator: std.mem.Allocator, ready_queue: *CallbackManager.CallbacksSetsQueue,
    max_number_of_callbacks_set_ptr: *usize, ready_tasks_queue_min_bytes_capacity: usize,
    py_exception_handler: PyObject
) !usize {
    const chunks_executed = try CallbackManager.execute_callbacks(
        ready_queue, &exception_handler, py_exception_handler
    );
    if (chunks_executed == 0) {
        prune_callbacks_sets(
            allocator, ready_queue, max_number_of_callbacks_set_ptr,
            ready_tasks_queue_min_bytes_capacity
        );
    }

    return chunks_executed;
}

fn fetch_completed_tasks(
    allocator: std.mem.Allocator, blocking_tasks_set: *Loop.Scheduling.IO.BlockingTasksSet,
    blocking_ready_tasks: []std.os.linux.io_uring_cqe, ready_queue: *CallbackManager.CallbacksSetsQueue
) !void {
    const ring = &blocking_tasks_set.ring;
    const nevents = try ring.copy_cqes(blocking_ready_tasks, 0);
    for (blocking_ready_tasks[0..nevents]) |cqe| {
        const user_data = cqe.user_data;
        const err: std.os.linux.E = @call(.always_inline, std.os.linux.io_uring_cqe.err, .{cqe});

        const blocking_task_data: *Loop.Scheduling.IO.BlockingTaskData = @ptrFromInt(user_data);
        defer blocking_tasks_set.push_in_quarantine(blocking_task_data);

        Loop.Scheduling.IO.check_io_uring_result(blocking_task_data.operation, err);

        var callback = blocking_task_data.callback_data orelse continue;
        callback.data.io_uring_err = err;
        callback.data.io_uring_res = cqe.res;

        _ = try CallbackManager.append_new_callback(
            allocator, ready_queue, callback, Loop.MaxCallbacks
        );
    }
}

fn poll_blocking_events(
    loop: *Loop, mutex: *Lock, wait: bool, ready_queue: *CallbackManager.CallbacksSetsQueue,
    quarantine_array: *BlockingTasksSetQuarantineArray
) !void {
    const epoll_fd = loop.blocking_tasks_epoll_fd;
    const blocking_ready_epoll_events = loop.blocking_ready_epoll_events;

    var nevents: usize = undefined;
    if (wait) {
        loop.epoll_locked = true;
        mutex.unlock();
        defer {
            mutex.lock();
            loop.epoll_locked = false;
        }

        const py_thread_state = PyEval_SaveThread();
        defer PyEval_RestoreThread(py_thread_state);

        nevents = std.posix.epoll_wait(epoll_fd, blocking_ready_epoll_events, -1);
    }else{
        nevents = std.posix.epoll_wait(epoll_fd, blocking_ready_epoll_events, 0);
    }

    while (nevents > 0) {
        const allocator = loop.allocator;
        const blocking_ready_tasks = loop.blocking_ready_tasks;

        for (blocking_ready_epoll_events[0..nevents]) |event| {
            const set = (@as(?*Loop.Scheduling.IO.BlockingTasksSet, @ptrFromInt(event.data.ptr)) orelse continue);
            try fetch_completed_tasks(
                allocator, set, blocking_ready_tasks, ready_queue
            );

            try quarantine_array.append(set);
        }

        if (nevents == blocking_ready_epoll_events.len) {
            nevents = std.posix.epoll_wait(epoll_fd, blocking_ready_epoll_events, 0);
        }else{
            break;
        }
    }
}

pub fn start(self: *Loop, py_exception_handler: PyObject) !void {
    const mutex = &self.mutex;
    mutex.lock();
    defer mutex.unlock();

    if (!self.initialized) {
        python_c.raise_python_runtime_error("Loop is closed\x00");
        return error.PythonError;
    }

    if (self.stopping) {
        python_c.raise_python_runtime_error("Loop is stopping\x00");
        return error.PythonError;
    }

    if (self.running) {
        python_c.raise_python_runtime_error("Loop is already running\x00");
        return error.PythonError;
    }

    self.running = true;
    defer {
        self.running = false;
        self.stopping = false;
    }

    const ready_tasks_queues: []CallbackManager.CallbacksSetsQueue = &self.ready_tasks_queues;
    const max_callbacks_set_per_queue: []usize = &self.max_callbacks_sets_per_queue;
    const ready_tasks_queue_min_bytes_capacity = self.ready_tasks_queue_min_bytes_capacity;
    const allocator = self.allocator;

    var quanrantine_blocking_tasks = BlockingTasksSetQuarantineArray.init(allocator);
    defer quanrantine_blocking_tasks.deinit();

    var ready_tasks_queue_index = self.ready_tasks_queue_index;
    var wait_for_blocking_events: bool = false;
    while (!self.stopping) {
        const old_index = ready_tasks_queue_index;
        const ready_tasks_queue = &ready_tasks_queues[old_index];


        try poll_blocking_events(self, mutex, wait_for_blocking_events, ready_tasks_queue, &quanrantine_blocking_tasks);
        defer {
            for (quanrantine_blocking_tasks.items) |set| {
                if (set.empty()) {
                    Loop.Scheduling.IO.remove_tasks_set(self.blocking_tasks_epoll_fd, set);
                }else{
                    set.clear_quarantine();
                }
            }

            quanrantine_blocking_tasks.clearRetainingCapacity();
        }

        ready_tasks_queue_index = 1 - ready_tasks_queue_index;
        self.ready_tasks_queue_index = ready_tasks_queue_index;

        mutex.unlock();
        defer mutex.lock();

        const chunks_executed = try call_once(
            allocator, ready_tasks_queue, &max_callbacks_set_per_queue[old_index],
            ready_tasks_queue_min_bytes_capacity, py_exception_handler
        );

        wait_for_blocking_events = (chunks_executed == 0);
    }
}


test "Prune sets when maximum is 1" {
    const allocator = std.testing.allocator;

    var ready_tasks = CallbackManager.CallbacksSetsQueue{
        .queue = CallbackManager.CallbacksSetLinkedList.init(allocator),
    };
    defer {
        for (0..ready_tasks.queue.len) |_| {
            const set: CallbackManager.CallbacksSet = ready_tasks.queue.pop() catch unreachable;
            CallbackManager.release_set(allocator, set);
        }
    }

    var number: usize = 0;
    for (0..3) |_| {
        _ = try CallbackManager.append_new_callback(allocator, &ready_tasks, .{
            .ZigGeneric = .{
                .data = &number,
                .callback = undefined
            }
        }, 1);
    }

    try std.testing.expect(ready_tasks.queue.len > 1);

    var max_number_of_callbacks_set_ptr: usize = 1;
    Loop.Runner.prune_callbacks_sets(allocator, &ready_tasks, &max_number_of_callbacks_set_ptr, 0);

    try std.testing.expectEqual(ready_tasks.queue.len, 1);
}

test "Prune sets when maximum is more than 1" {
    const allocator = std.testing.allocator;

    var ready_tasks = CallbackManager.CallbacksSetsQueue{
        .queue = CallbackManager.CallbacksSetLinkedList.init(allocator),
    };
    defer {
        for (0..ready_tasks.queue.len) |_| {
            const set: CallbackManager.CallbacksSet = ready_tasks.queue.pop() catch unreachable;
            CallbackManager.release_set(allocator, set);
        }
    }

    var number: usize = 0;
    for (0..20) |_| {
        _ = try CallbackManager.append_new_callback(allocator, &ready_tasks, .{
            .ZigGeneric = .{
                .data = &number,
                .callback = undefined
            }
        }, 2);
    }

    try std.testing.expect(ready_tasks.queue.len > 1);

    var max_number_of_callbacks_set: usize = CallbackManager.get_max_callbacks_sets(
        14*@sizeOf(CallbackManager.Callback), 2
    );

    Loop.Runner.prune_callbacks_sets(
        allocator, &ready_tasks, &max_number_of_callbacks_set, 14*@sizeOf(CallbackManager.Callback)
    );

    try std.testing.expectEqual(ready_tasks.queue.len, max_number_of_callbacks_set);
}


test "Prune sets with high limit" {
    const allocator = std.testing.allocator;

    var ready_tasks = CallbackManager.CallbacksSetsQueue{
        .queue = CallbackManager.CallbacksSetLinkedList.init(allocator),
    };
    defer {
        for (0..ready_tasks.queue.len) |_| {
            const set: CallbackManager.CallbacksSet = ready_tasks.queue.pop() catch unreachable;
            CallbackManager.release_set(allocator, set);
        }
    }

    var number: usize = 0;
    for (0..20) |_| {
        _ = try CallbackManager.append_new_callback(allocator, &ready_tasks, .{
            .ZigGeneric = .{
                .data = &number,
                .callback = undefined
            }
        }, 2);
    }

    try std.testing.expect(ready_tasks.queue.len > 1);

    var max_number_of_callbacks_set: usize = CallbackManager.get_max_callbacks_sets(
        40*@sizeOf(CallbackManager.Callback), 2
    );

    Loop.Runner.prune_callbacks_sets(
        allocator, &ready_tasks, &max_number_of_callbacks_set, 30*@sizeOf(CallbackManager.Callback)
    );

    try std.testing.expect(ready_tasks.queue.len < max_number_of_callbacks_set);
}

test "Running callbaks and prune" {
    const allocator = std.testing.allocator;

    var ready_tasks = CallbackManager.CallbacksSetsQueue{
        .queue = CallbackManager.CallbacksSetLinkedList.init(allocator),
    };
    defer {
        for (0..ready_tasks.queue.len) |_| {
            const set: CallbackManager.CallbacksSet = ready_tasks.queue.pop() catch unreachable;
            CallbackManager.release_set(allocator, set);
        }
    }

    const test_callback = struct{
        fn run(data: ?*anyopaque, status: CallbackManager.ExecuteCallbacksReturn) CallbackManager.ExecuteCallbacksReturn {
            std.testing.expectEqual(CallbackManager.ExecuteCallbacksReturn.Continue, status) catch unreachable;

            const number: *usize = @alignCast(@ptrCast(data.?));
            number.* += 1;

            return .Continue;
        }
    }.run;

    var number: usize = 0;
    for (0..20) |_| {
        _ = try CallbackManager.append_new_callback(allocator, &ready_tasks, .{
            .ZigGeneric = .{
                .data = &number,
                .callback = test_callback
            }
        }, 2);
    }

    try std.testing.expect(ready_tasks.queue.len > 1);

    var max_number_of_callbacks_set: usize = CallbackManager.get_max_callbacks_sets(
        14*@sizeOf(CallbackManager.Callback), 2
    );

    const ret = Loop.Runner.call_once(
        allocator, &ready_tasks, &max_number_of_callbacks_set, 14*@sizeOf(CallbackManager.Callback)
    );
    Loop.Runner.prune_callbacks_sets(
        allocator, &ready_tasks, &max_number_of_callbacks_set, 14*@sizeOf(CallbackManager.Callback)
    );

    try std.testing.expectEqual(ret, CallbackManager.ExecuteCallbacksReturn.Continue);
    try std.testing.expect(ready_tasks.queue.len <= max_number_of_callbacks_set);
}
