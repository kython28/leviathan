const Loop = @import("main.zig");
const CallbackManager = @import("../callback_manager.zig");

const BlockingTasksSetLinkedList = Loop.Scheduling.IO.BlockingTasksSetLinkedList;
const CallbacksSetLinkedList = CallbackManager.LinkedList;

const Lock = @import("../utils/lock.zig").Mutex;

const utils = @import("../utils/utils.zig");
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

pub inline fn call_once(
    allocator: std.mem.Allocator, ready_queue: *CallbackManager.CallbacksSetsQueue,
    max_number_of_callbacks_set_ptr: *usize, ready_tasks_queue_min_bytes_capacity: usize,
) CallbackManager.ExecuteCallbacksReturn {
    const ret = CallbackManager.execute_callbacks(allocator, ready_queue, .Continue, true);
    if (ret == .None) {
        prune_callbacks_sets(
            allocator, ready_queue, max_number_of_callbacks_set_ptr,
            ready_tasks_queue_min_bytes_capacity
        );
    }

    return ret;
}

inline fn check_io_uring_result(
    operation: Loop.Scheduling.IO.BlockingOperation, callback: *CallbackManager.Callback,
    result: std.os.linux.E, comptime can_cancel: bool
) void {
    switch (operation) {
        .WaitTimer => |op| {
            switch (result) {
                .TIME => {},
                .CANCELED => {
                    if (can_cancel) {
                        CallbackManager.cancel_callback(callback, null);
                    }
                },
                .SUCCESS => unreachable, // Just to debug. This timeout isn't linked to any task
                else => |code| {
                    std.log.err("Unexpected errno ({}) while checking result for operation {}", .{code, op});
                    unreachable;
                }
            }
        },
        .Cancel => unreachable, // Cancel operation doesn't have any callback
        .PerformWriteV, .PerformWrite => |op| {
            switch (result) {
                .SUCCESS => {},
                .CANCELED, .BADF, .FBIG, .INTR, .IO, .NOSPC, .INVAL, .CONNRESET,  // Expected errors
                .PIPE, .NOBUFS, .NXIO, .ACCES, .NETDOWN, .NETUNREACH,
                .SPIPE => {
                    if (can_cancel) {
                        CallbackManager.cancel_callback(callback, null);
                    }
                },
                .AGAIN => unreachable, // This should not happen. Filtered by debugging porpuse
                else => |code| {
                    std.log.err("Unexpected errno ({}) while checking result for operation {}", .{code, op});
                    unreachable;
                }
            }
        },
        .PerformRead => |op| {
            switch (result) {
                .SUCCESS => {},
                .CANCELED, .BADF, .BADMSG, .INTR, .INVAL, .IO, .ISDIR,
                .OVERFLOW, .SPIPE, .CONNRESET, .NOTCONN, .TIMEDOUT,
                .NOBUFS, .NOMEM, .NXIO => {
                    if (can_cancel) {
                        CallbackManager.cancel_callback(callback, null);
                    }
                },
                .AGAIN => unreachable, // This should not happen. Filtered by debugging porpuse
                else => |code| {
                    std.log.err("Unexpected errno ({}) while checking result for operation {}", .{code, op});
                    unreachable;
                }
            }
        },
        .SocketShutdown => |op| {
            switch (result) {
                .SUCCESS => {},
                .CANCELED, .INVAL, .NOTCONN, .NOTSOCK, .BADF, .NOBUFS => {
                    if (can_cancel) {
                        CallbackManager.cancel_callback(callback, null);
                    }
                },
                .AGAIN => unreachable, // This should not happen. Filtered by debugging porpuse
                else => |code| {
                    std.log.err("Unexpected errno ({}) while checking result for operation {}", .{code, op});
                    unreachable;
                }
            }
        },
        else => |op| {
            switch (result) {
                .SUCCESS => {},
                .CANCELED, .BADF, .INTR => {
                    if (can_cancel) {
                        CallbackManager.cancel_callback(callback, null);
                    }
                },
                else => |code| {
                    std.log.err("Unexpected errno ({}) while checking result for operation {}", .{code, op});
                    unreachable;
                }
            }
        }
    }
}

inline fn fetch_completed_tasks(
    allocator: std.mem.Allocator, blocking_tasks_set: *Loop.Scheduling.IO.BlockingTasksSet,
    blocking_ready_tasks: []std.os.linux.io_uring_cqe, ready_queue: *CallbackManager.CallbacksSetsQueue
) !void {
    const ring = &blocking_tasks_set.ring;
    const nevents = try ring.copy_cqes(blocking_ready_tasks, 0);
    for (blocking_ready_tasks[0..nevents]) |cqe| {
        const user_data = cqe.user_data;
        const err: std.os.linux.E = @call(.always_inline, std.os.linux.io_uring_cqe.err, .{cqe});

        const blocking_task_data_node: Loop.Scheduling.IO.BlockingTaskDataLinkedList.Node = @ptrFromInt(user_data);

        const blocking_task_data = blocking_task_data_node.data;
        blocking_tasks_set.push_in_quarantine(blocking_task_data_node);

        var callback = blocking_task_data.callback_data orelse continue;

        switch (callback) {
            .ZigGenericIO => |*data| {
                check_io_uring_result(blocking_task_data.operation, &callback, err, false);
                data.io_uring_res = cqe.res;
                data.io_uring_err = err;
            },
            else => {
                check_io_uring_result(blocking_task_data.operation, &callback, err, true);
            }
        }

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

    var nevents: usize = blocking_ready_epoll_events.len;
    while (nevents == blocking_ready_epoll_events.len) {
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

        const allocator = loop.allocator;
        const blocking_ready_tasks = loop.blocking_ready_tasks;

        for (blocking_ready_epoll_events[0..nevents]) |event| {
            const set = (@as(?*Loop.Scheduling.IO.BlockingTasksSet, @ptrFromInt(event.data.ptr)) orelse continue);
            try fetch_completed_tasks(
                allocator, set, blocking_ready_tasks, ready_queue
            );

            try quarantine_array.append(set);
        }
    }
}

pub fn start(self: *Loop) !void {
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
                if (set.tasks_data.len == 0) {
                    Loop.Scheduling.IO.remove_tasks_set(self.blocking_tasks_epoll_fd, &self.blocking_tasks_queue, set);
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

        wait_for_blocking_events = switch (
            call_once(
                allocator, ready_tasks_queue, &max_callbacks_set_per_queue[old_index],
                ready_tasks_queue_min_bytes_capacity,
            )
        ) {
            .Continue => false,
            .Stop => break,
            .Exception => return error.PythonError,
            .None => true,
        };
    }
}
