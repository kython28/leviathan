const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Loop = @import("../loop/main.zig");
const CallbackManager = @import("../callback_manager.zig");
const utils = @import("../utils/main.zig");

const BuffersArrayList = std.ArrayList(std.posix.iovec_const);
const PyObjectsArrayList = std.ArrayList(PyObject);

const ConnectionLostCallback = *const fn (usize, PyObject) anyerror!void;

loop: *Loop,
parent_transport: usize,
exception_handler: PyObject,

connection_lost_callback: ?ConnectionLostCallback,

free_buffers: *BuffersArrayList,
free_py_objects: *PyObjectsArrayList,

busy_buffers: *BuffersArrayList,
busy_py_objects: *PyObjectsArrayList,

fd: std.posix.fd_t,

ready_to_queue_write_op: bool = true,
blocking_task_id: usize = 0,

must_write_eof: bool = false,
is_writing: bool = false,
is_closing: bool = false,
closed: bool = false,
initialized: bool = false,


pub fn init(
    self: *WriteTransport, loop: *Loop, fd: std.posix.fd_t,
    parent_transport: usize, exception_handler: PyObject,
    connection_lost_callback: ConnectionLostCallback
) !void {
    const allocator = loop.allocator;

    const free_buffers = try allocator.create(BuffersArrayList);
    errdefer allocator.destroy(free_buffers);

    const busy_buffers = try allocator.create(BuffersArrayList);
    errdefer allocator.destroy(busy_buffers);

    const free_py_objects = try allocator.create(PyObjectsArrayList);
    errdefer allocator.destroy(free_py_objects);

    const busy_py_objects = try allocator.create(PyObjectsArrayList);
    errdefer allocator.destroy(busy_py_objects);

    self.* = WriteTransport{
        .loop = loop,
        .parent_transport = parent_transport,
        .exception_handler = exception_handler,

        .connection_lost_callback = connection_lost_callback,

        .free_buffers = free_buffers,
        .free_py_objects = free_py_objects,

        .busy_buffers = busy_buffers,
        .busy_py_objects = busy_py_objects,

        .fd = fd,
        .initialized = true
    };
}

pub fn close(self: *WriteTransport) !void {
    if (self.is_closing or self.closed) return;

    const blocking_task_id = self.blocking_task_id;
    if (blocking_task_id == 0) {
        self.closed = true;
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
    allocator.destroy(self.free_buffers);
    allocator.destroy(self.free_py_objects);

    allocator.destroy(self.busy_buffers);
    allocator.destroy(self.busy_py_objects);

    self.initialized = false;
}

fn write_operation_completed(
    data: ?*anyopaque, _: i32, io_uring_err: std.os.linux.E
) CallbackManager.ExecuteCallbacksReturn {
    const self: *WriteTransport = @alignCast(@ptrCast(data.?));
    self.blocking_task_id = 0;

    var exception: PyObject = undefined;
    var exc_message: PyObject = undefined;

    switch (io_uring_err) {
        .SUCCESS => blk: {
            if (self.is_closing) {
                self.closed = true;
            }else{
                self.queue_buffers_and_swap() catch |err| {
                    // TODO: Optimize this
                    utils.handle_zig_function_error(err, {});

                    exception = python_c.PyErr_GetRaisedException()
                        orelse return .Exception;

                    exc_message = python_c.PyUnicode_FromString("Exception ocurred while queueing up data\x00")
                        orelse {
                            python_c.py_decref(exception);
                            return .Exception;
                        };
                    break :blk;
                };
            }

            return .Continue;
        },
        .CANCELED => {
            self.is_closing = true;
            self.closed = true;
            return .Continue;
        },
        else => {
            if (self.is_closing) {
                self.closed = true;
                return .Continue;
            }

            exc_message = python_c.PyUnicode_FromString("Exception ocurred trying to write\x00")
                orelse return .Exception;

            exception = python_c.PyObject_CallFunction(
                python_c.PyExc_OSError, "LO\x00", @as(c_long, @intFromEnum(io_uring_err)), exc_message
            ) orelse return .Exception;
        }
    }
    defer python_c.py_decref(exc_message);
    defer python_c.py_decref(exception);

    self.is_closing = true;
    self.closed = true;

    const parent_transport = self.parent_transport;
    if (self.connection_lost_callback) |callback| {
        callback(parent_transport, exception) catch |err| {
            return utils.handle_zig_function_error(err, CallbackManager.ExecuteCallbacksReturn.Exception);
        };
    }

    var args: [3]PyObject = undefined;
    args[0] = exception;
    args[1] = exc_message;
    args[2] = @ptrFromInt(parent_transport);

    const message_kname: PyObject = python_c.PyUnicode_FromString("message\x00")
        orelse return .Exception;
    defer python_c.py_decref(message_kname);

    const transport_kname: PyObject = python_c.PyUnicode_FromString("transport\x00")
        orelse return .Exception;
    defer python_c.py_decref(transport_kname);

    const knames: PyObject = python_c.PyTuple_Pack(2, message_kname, transport_kname)
        orelse return .Exception;
    defer python_c.py_decref(knames);

    const exc_handler_ret: PyObject = python_c.PyObject_Vectorcall(self.exception_handler, &args, 1, knames)
        orelse return .Exception;
    python_c.py_decref(exc_handler_ret);

    return .Continue;
}

pub fn queue_buffers_and_swap(self: *WriteTransport) !void {
    if (self.must_write_eof) {
        defer self.must_write_eof = false;

        self.blocking_task_id = try Loop.Scheduling.IO.queue(
            self.loop, .{
                .PerformWrite = .{
                    .callback = &write_operation_completed,
                    .data = self
                },
                .fd = self.fd,
            }
        );

        return;
    }

    const current_free_buffers = self.free_buffers;
    if (current_free_buffers.items.len == 0) {
        self.ready_to_queue_write_op = true;
        return;
    }

    const current_free_py_objects = self.free_py_objects;

    const current_busy_buffers = self.busy_buffers;
    const current_busy_py_objects = self.busy_py_objects;

    self.blocking_task_id = try Loop.Scheduling.IO.queue(
        self.loop, .{
            .PerformWriteV = .{
                .callback = .{
                    .ZigGenericIO = .{
                        .callback = &write_operation_completed,
                        .data = self
                    }
                },
                .fd = self.fd,
                .data = current_free_buffers.items
            }
        }
    );

    const old_py_objects = current_busy_py_objects.items;
    if (old_py_objects.len > 0) {
        for (old_py_objects) |v| {
            python_c.py_decref(v);
        }
    }

    current_busy_py_objects.clearRetainingCapacity();
    current_busy_buffers.clearRetainingCapacity();

    self.free_buffers = current_busy_buffers;
    self.free_py_objects = current_busy_py_objects;

    self.busy_buffers = current_free_buffers;
    self.busy_py_objects = current_free_py_objects;

    self.ready_to_queue_write_op = false;
}

pub inline fn append_new_buffer_to_write(self: *WriteTransport, py_object: PyObject, buffer: []const u8) !void {
    if (self.closed) {
        return error.TransportClosed;
    }

    try self.free_py_objects.append(py_object);
    errdefer _ = self.free_py_objects.pop();

    try self.free_buffers.append(.{
        .base = buffer.ptr,
        .len = buffer.len
    });

    if (self.ready_to_queue_write_op) {
        try queue_buffers_and_swap(self);
    }
}

pub inline fn queue_eof(self: *WriteTransport) void {
    self.must_write_eof = true;
}

const WriteTransport = @This();
