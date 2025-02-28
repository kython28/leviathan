const std = @import("std");
const builtin = @import("builtin");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Loop = @import("../loop/main.zig");
const CallbackManager = @import("../callback_manager.zig");
const utils = @import("utils");

pub const ReadCompletedCallback = *const fn (*ReadTransport, []const u8, std.os.linux.E) anyerror!void;

pub const MAX_READ = switch (builtin.mode) {
    .Debug => (1 << 16),
    else => (2 * 1000 * 1000)
};

const ConnectionLostCallback = *const fn (PyObject, PyObject) anyerror!void;

loop: *Loop,
parent_transport: PyObject,
exception_handler: PyObject,

connection_lost_callback: ?ConnectionLostCallback,

read_completed_callback: ReadCompletedCallback,
buffer: []u8,

buffer_being_read: []u8,

fd: std.posix.fd_t,

blocking_task_id: usize = 0,

zero_copying: bool,
closed: bool = false,
is_closing: bool = false,
cancelling: bool = false,
initialized: bool = false,

pub fn init(
    self: *ReadTransport, loop: *Loop, fd: std.posix.fd_t, callback: ReadCompletedCallback,
    parent_transport: PyObject, exception_handler: PyObject,
    connection_lost_callback: ConnectionLostCallback,
    zero_copying: bool
) !void {
    const allocator = loop.allocator;

    const buffer = try allocator.alloc(u8, MAX_READ);
    errdefer allocator.free(buffer);

    self.* = .{
        .loop = loop,
        .parent_transport = parent_transport,
        .exception_handler = exception_handler,

        .connection_lost_callback = connection_lost_callback,

        .read_completed_callback = callback,
        .buffer = buffer,
        .buffer_being_read = undefined,

        .zero_copying = zero_copying,

        .fd = fd,
        .initialized = true
    };
}

pub fn close(self: *ReadTransport) !void {
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

pub fn deinit(self: *ReadTransport) void {
    if (!self.initialized) {
        @panic("ReadTransport is not initialized");
    }

    const allocator = self.loop.allocator;
    allocator.free(self.buffer);

    self.initialized = false;
}

fn read_operation_completed(
    data: ?*anyopaque, io_uring_res: i32, io_uring_err: std.os.linux.E
) CallbackManager.ExecuteCallbacksReturn {
    const self: *ReadTransport = @alignCast(@ptrCast(data.?));
    self.blocking_task_id = 0;
    self.cancelling = false;

    const parent_transport = self.parent_transport;
    defer python_c.py_decref(parent_transport);

    var bytes_read: usize = 0;
    if (io_uring_err == .SUCCESS) {
        bytes_read = @intCast(io_uring_res);
    }

    var exception: PyObject = undefined;
    var exc_message: PyObject = undefined;

    const ret = self.read_completed_callback(self, self.buffer_being_read[0..bytes_read], io_uring_err);
    if (ret) |_| {
        const is_closing = self.is_closing;
        if (io_uring_err == .SUCCESS or io_uring_err == .CANCELED or is_closing) {
            if (is_closing) {
                self.closed = true;
            }

            return .Continue;
        }

        exc_message = python_c.PyUnicode_FromString("Exception ocurred while reading\x00")
            orelse return .Exception;

        exception = python_c.PyObject_CallFunction(
            python_c.PyExc_OSError, "LO\x00", @as(c_long, @intFromEnum(io_uring_err)), exc_message
        ) orelse {
            python_c.py_decref(exc_message);
            return .Exception;
        };
    }else |err| {
        // TODO: Optimize this
        utils.handle_zig_function_error(err, {});

        exception = python_c.PyErr_GetRaisedException()
            orelse return .Exception;

        exc_message = python_c.PyUnicode_FromString("Exception ocurred while handling the read data\x00")
            orelse {
                python_c.py_decref(exception);
                return .Exception;
            };
    }
    defer python_c.py_decref(exc_message);
    defer python_c.py_decref(exception);

    defer {
        self.is_closing = true;
        self.closed = true;
    }


    if (self.connection_lost_callback) |callback| {
        callback(parent_transport, exception) catch |err| {
            return utils.handle_zig_function_error(err, CallbackManager.ExecuteCallbacksReturn.Exception);
        };
    }

    var args: [3]PyObject = undefined;
    args[0] = exception;
    args[1] = exc_message;
    args[2] = parent_transport;

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

pub inline fn perform(self: *ReadTransport, buffer: ?[]u8) !void {
    const buffer_being_read = buffer orelse self.buffer;

    self.blocking_task_id = try Loop.Scheduling.IO.queue(
        self.loop, .{
            .PerformRead = .{
                .callback = .{
                    .ZigGenericIO = .{
                        .callback = &read_operation_completed,
                        .data = self
                    }
                },
                .fd = self.fd,
                .data = .{
                    .buffer = buffer_being_read
                },
                .zero_copy = self.zero_copying
            }
        }
    );

    self.buffer_being_read = buffer_being_read;
    python_c.py_incref(self.parent_transport);
}

pub inline fn cancel(self: *ReadTransport) !void {
    const blocking_task_id = self.blocking_task_id;
    if (blocking_task_id == 0 or self.cancelling) {
        return;
    }

    _ = try Loop.Scheduling.IO.queue(
        self.loop, .{
            .Cancel = blocking_task_id
        }
    );

    self.cancelling = true;
}

const ReadTransport = @This();
