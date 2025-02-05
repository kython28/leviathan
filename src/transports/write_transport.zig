const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Loop = @import("../loop/main.zig");
const CallbackManager = @import("../callback_manager.zig");
const utils = @import("../utils/main.zig");

const BuffersArrayList = std.ArrayList(std.posix.iovec_const);
const PyObjectsArrayList = std.ArrayList(PyObject);

loop: *Loop,
parent_transport: PyObject,
exception_handler: PyObject,

free_buffers: *BuffersArrayList,
free_py_objects: *PyObjectsArrayList,

busy_buffers: *BuffersArrayList,
busy_py_objects: *PyObjectsArrayList,

fd: std.posix.fd_t,

ready_to_queue_write_op: bool = true,

initialized: bool = false,


pub fn init(
    self: *WriteTransport, loop: *Loop, fd: std.posix.fd_t,
    parent_transport: PyObject, exception_handler: PyObject
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

        .free_buffers = free_buffers,
        .free_py_objects = free_py_objects,

        .busy_buffers = busy_buffers,
        .busy_py_objects = busy_py_objects,

        .fd = fd,
        .initialized = true
    };
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

    if (io_uring_err == .SUCCESS) {
        self.queue_buffers_and_swap() catch |err| {
            return utils.handle_zig_function_error(err, CallbackManager.ExecuteCallbacksReturn.Exception);
        };
        return .Continue;
    }

    const exc_message: PyObject = python_c.PyUnicode_FromString("Exception ocurred trying to write\x00")
        orelse return .Exception;
    defer python_c.py_decref(exc_message);

    const exception: PyObject = python_c.PyObject_CallFunction(
        python_c.PyExc_OSError, "LO\x00", @as(c_long, @intFromEnum(io_uring_err)), exc_message
    ) orelse return .Exception;
    defer python_c.py_decref(exception);

    var args: [3]PyObject = undefined;
    args[0] = exception;
    args[1] = exc_message;
    args[2] = self.parent_transport;

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

    std.posix.close(self.fd);
    return .Continue;
}

pub fn queue_buffers_and_swap(self: *WriteTransport) !void {
    const current_free_buffers = self.free_buffers;
    if (current_free_buffers.items.len == 0) {
        self.ready_to_queue_write_op = true;
        return;
    }

    const current_free_py_objects = self.free_py_objects;

    const current_busy_buffers = self.busy_buffers;
    const current_busy_py_objects = self.busy_py_objects;

    try Loop.Scheduling.IO.queue(
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

const WriteTransport = @This();
