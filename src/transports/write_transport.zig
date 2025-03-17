const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Loop = @import("../loop/main.zig");
const CallbackManager = @import("callback_manager");
const utils = @import("utils");

const BuffersArrayList = std.ArrayList(std.posix.iovec_const);
const PyBuffersArrayList = std.ArrayList(python_c.Py_buffer);

pub const WriteCompletedCallback = *const fn (*WriteTransport, usize, usize, std.os.linux.E) anyerror!void;
const ConnectionLostCallback = *const fn (PyObject, PyObject) anyerror!void;

const ExceptionMessage: [:0]const u8 = "Failed to complete write operation on transport";
const ModuleName: [:0]const u8 = "transport";

loop: *Loop,
parent_transport: PyObject,
exception_handler: PyObject,

connection_lost_callback: ?ConnectionLostCallback,

write_completed_callback: WriteCompletedCallback,

free_buffers: *BuffersArrayList,
free_py_buffers: *PyBuffersArrayList,
free_buffers_size: usize = 0,

busy_buffers: *BuffersArrayList,
busy_py_buffers: *PyBuffersArrayList,
busy_buffers_size: usize = 0,
busy_buffers_data_written: usize = 0,
current_iovec_index: usize = 0,

buffer_size: usize = 0,

fd: std.posix.fd_t,

ready_to_queue_write_op: bool = true,
zero_copying: bool,

blocking_task_id: usize = 0,

is_closing: bool = false,
closed: bool = false,
initialized: bool = false,


pub fn init(
    self: *WriteTransport, loop: *Loop, fd: std.posix.fd_t,
    callback: WriteCompletedCallback, parent_transport: PyObject,
    exception_handler: PyObject, connection_lost_callback: ConnectionLostCallback,
    zero_copying: bool
) !void {
    const allocator = loop.allocator;

    const free_buffers = try allocator.create(BuffersArrayList);
    errdefer allocator.destroy(free_buffers);

    const busy_buffers = try allocator.create(BuffersArrayList);
    errdefer allocator.destroy(busy_buffers);

    const free_py_objects = try allocator.create(PyBuffersArrayList);
    errdefer allocator.destroy(free_py_objects);

    const busy_py_objects = try allocator.create(PyBuffersArrayList);
    errdefer allocator.destroy(busy_py_objects);

    free_buffers.* = BuffersArrayList.init(allocator);
    busy_buffers.* = BuffersArrayList.init(allocator);

    free_py_objects.* = PyBuffersArrayList.init(allocator);
    busy_py_objects.* = PyBuffersArrayList.init(allocator);

    self.* = WriteTransport{
        .loop = loop,
        .parent_transport = parent_transport,
        .exception_handler = exception_handler,

        .connection_lost_callback = connection_lost_callback,

        .write_completed_callback = callback,

        .free_buffers = free_buffers,
        .free_py_buffers = free_py_objects,

        .busy_buffers = busy_buffers,
        .busy_py_buffers = busy_py_objects,

        .fd = fd,
        .zero_copying = zero_copying,
        .initialized = true,
    };
}

pub fn close(self: *WriteTransport) !void {
    if (self.is_closing or self.closed) return;

    const blocking_task_id = self.blocking_task_id;
    if (blocking_task_id == 0) {
        self.closed = true;
        self.is_closing = true;
        return;
    }

    _ = try Loop.Scheduling.IO.queue(
        self.loop, .{
            .Cancel = blocking_task_id
        }
    );

    self.is_closing = true;
    self.connection_lost_callback = null;
}

pub fn deinit(self: *WriteTransport) void {
    if (!self.initialized) {
        @panic("WriteTransport is not initialized");
    }

    const allocator = self.loop.allocator;

    for (self.free_py_buffers.items) |*v| {
        python_c.PyBuffer_Release(v);
    }

    for (self.busy_py_buffers.items) |*v| {
        python_c.PyBuffer_Release(v);
    }

    self.free_buffers.deinit();
    self.free_py_buffers.deinit();

    self.busy_buffers.deinit();
    self.busy_py_buffers.deinit();

    allocator.destroy(self.free_buffers);
    allocator.destroy(self.free_py_buffers);

    allocator.destroy(self.busy_buffers);
    allocator.destroy(self.busy_py_buffers);

    self.initialized = false;
}

inline fn queue_remaining_data(self: *WriteTransport, data_written: usize) !void {
    var current_ioves_index = self.current_iovec_index;
    var remaining: usize = data_written;
    for (self.busy_buffers.items) |*iovec| {
        const len = iovec.len;
        if (remaining > len) {
            remaining -= len;
            current_ioves_index += 1;
        }else{
            iovec.base += remaining;
            iovec.len -= remaining;
            break;
        }
    }
    self.current_iovec_index = current_ioves_index;

    self.blocking_task_id = try Loop.Scheduling.IO.queue(
        self.loop, .{
            .PerformWriteV = .{
                .callback = .{
                    .func = &write_operation_completed,
                    .cleanup = &cleanup_resources_callback,
                    .data = .{
                        .user_data = self,
                        .exception_context = .{
                            .callback_ptr = null,
                            .exc_message = ExceptionMessage,
                            .module_name = ModuleName,
                            .module_ptr = self.parent_transport
                        }
                    }
                },
                .fd = self.fd,
                .data = self.busy_buffers.items[current_ioves_index..],
                .zero_copy = ((remaining >= 10_000) and self.zero_copying)
            }
        }
    );

    python_c.py_incref(self.parent_transport);
}

fn cleanup_resources_callback(ptr: ?*anyopaque) void {
    const self: *WriteTransport = @alignCast(@ptrCast(ptr.?));
    python_c.py_decref(self.parent_transport);

    self.blocking_task_id = 0;
}

fn write_operation_completed(data: *const CallbackManager.CallbackData) !void {
    const self: *WriteTransport = @alignCast(@ptrCast(data.user_data.?));
    if (data.cancelled) {
        cleanup_resources_callback(self);
        return;
    }

    const io_uring_res = data.io_uring_res;
    const io_uring_err = data.io_uring_err;

    self.blocking_task_id = 0;

    const parent_transport = self.parent_transport;

    var exception: PyObject = undefined;

    var data_written: usize = 0;
    var remaining_data = self.buffer_size;
    if (io_uring_res > 0) {
        data_written = self.busy_buffers_data_written + @as(usize, @intCast(io_uring_res));
        remaining_data -= @intCast(io_uring_res);
        self.buffer_size = remaining_data;
        self.busy_buffers_data_written = data_written;

        if (data_written < self.busy_buffers_size) {
            try queue_remaining_data(self, @intCast(io_uring_res));
            python_c.py_decref(parent_transport);
            return;
        }
    }

    for (self.busy_py_buffers.items) |*v| {
        python_c.PyBuffer_Release(v);
    }
    self.busy_py_buffers.clearRetainingCapacity();
    self.busy_buffers.clearRetainingCapacity();

    const ret = self.write_completed_callback(self, data_written, remaining_data, io_uring_err);
    if (ret) |_| {
        switch (io_uring_err) {
            .SUCCESS => {
                if (self.is_closing) {
                    self.closed = true;
                }else{
                    try self.queue_buffers_and_swap();
                }

                python_c.py_decref(parent_transport);
                return;
            },
            .CANCELED => {
                python_c.py_decref(parent_transport);
                self.closed = true;
                return;
            },
            else => {
                if (self.is_closing) {
                    self.closed = true;
                    python_c.py_decref(parent_transport);
                    return;
                }

                exception = python_c.PyObject_CallFunction(
                    python_c.PyExc_OSError, "Ls\x00", @as(c_long, @intFromEnum(io_uring_err)),
                    "Write operation failed\x00"
                ) orelse return error.PythonError;
            }
        }
    }else |err| {
        utils.handle_zig_function_error(err, {});
        exception = python_c.PyErr_GetRaisedException()
            orelse return error.PythonError;
    }

    defer {
        self.is_closing = true;
        self.closed = true;
        python_c.PyErr_SetRaisedException(exception);
    }

    if (self.connection_lost_callback) |callback| {
        try callback(parent_transport, exception);
    }

    return error.PythonError;
}

pub fn queue_buffers_and_swap(self: *WriteTransport) !void {
    const current_free_buffers = self.free_buffers;
    if (current_free_buffers.items.len == 0) {
        self.ready_to_queue_write_op = true;
        return;
    }

    const current_free_py_buffers = self.free_py_buffers;

    const current_busy_buffers = self.busy_buffers;
    const current_busy_py_buffers = self.busy_py_buffers;

    const buffer_size = self.buffer_size;

    self.blocking_task_id = try Loop.Scheduling.IO.queue(
        self.loop, .{
            .PerformWriteV = .{
                .callback = .{
                    .func = &write_operation_completed,
                    .cleanup = &cleanup_resources_callback,
                    .data = .{
                        .user_data = self,
                        .exception_context = .{
                            .callback_ptr = null,
                            .exc_message = ExceptionMessage,
                            .module_name = ModuleName,
                            .module_ptr = self.parent_transport
                        }
                    }
                },
                .fd = self.fd,
                .data = current_free_buffers.items,
                .zero_copy = ((buffer_size >= 10_000) and self.zero_copying)
            }
        }
    );

    self.free_buffers = current_busy_buffers;
    self.free_py_buffers = current_busy_py_buffers;

    self.busy_buffers = current_free_buffers;
    self.busy_py_buffers = current_free_py_buffers;
    self.busy_buffers_data_written = 0;
    self.busy_buffers_size = buffer_size;
    self.current_iovec_index = 0;

    self.ready_to_queue_write_op = false;

    python_c.py_incref(self.parent_transport);
}

pub fn append_new_buffer_to_write(self: *WriteTransport, py_object: PyObject) !usize {
    if (self.closed) {
        return error.TransportClosed;
    }

    const new_buffer_size: usize = blk: {
        var pbuffer: python_c.Py_buffer = undefined;
        if (python_c.PyObject_GetBuffer(py_object, &pbuffer, 0) < 0) {
            return error.PythonError;
        }
        errdefer python_c.PyBuffer_Release(&pbuffer);

        if (pbuffer.len <= 0) {
            python_c.PyBuffer_Release(&pbuffer);
            return self.buffer_size;
        }

        const buffer_len: usize = @intCast(pbuffer.len);

        try self.free_py_buffers.append(pbuffer);
        errdefer _ = self.free_py_buffers.pop();

        try self.free_buffers.append(.{
            .base = @ptrCast(pbuffer.buf.?),
            .len = buffer_len
        });

        break :blk self.buffer_size + buffer_len;
    };
    self.buffer_size = new_buffer_size;

    if (self.ready_to_queue_write_op) {
        try queue_buffers_and_swap(self);
    }

    return new_buffer_size;
}

pub fn queue_eof(self: *WriteTransport) !void {
    if (self.buffer_size > 0) return;

    try self.close();

    _ = try Loop.Scheduling.IO.queue(
        self.loop, .{
            .SocketShutdown = .{
                .socket_fd = self.fd,
                .how = std.os.linux.SHUT.WR
            }
        }
    );
}

const WriteTransport = @This();
