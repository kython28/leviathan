const std = @import("std");
const builtin = @import("builtin");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Loop = @import("../loop/main.zig");
const CallbackManager = @import("callback_manager");
const utils = @import("utils");

pub const ReadCompletedCallback = *const fn (*ReadTransport, []const u8, std.os.linux.E) anyerror!void;

pub const MAX_READ = switch (builtin.mode) {
    .Debug => (1 << 16),
    else => (2 * 1000 * 1000)
};

const ConnectionLostCallback = *const fn (PyObject, PyObject) anyerror!void;

const ExceptionMessage: [:0]const u8 = "Failed to complete read operation on transport";
const ModuleName: [:0]const u8 = "transport";

loop: *Loop,
parent_transport: PyObject,
exception_handler: PyObject,

connection_lost_callback: ?ConnectionLostCallback,

read_completed_callback: ReadCompletedCallback,
buffer: []u8,

buffer_to_read: []u8,

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
        .buffer_to_read = undefined,

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

fn cleanup_resources_callback(ptr: ?*anyopaque) !void {
    const self: *ReadTransport = @alignCast(@ptrCast(ptr.?));
    python_c.py_decref(self.parent_transport);

    self.blocking_task_id = 0;
    self.cancelling = false;
}

fn read_operation_completed(data: *const CallbackManager.CallbackData) !void {
    const self: *ReadTransport = @alignCast(@ptrCast(data.user_data.?));
    const io_uring_err = data.io_uring_err;
    const io_uring_res = data.io_uring_res;

    self.blocking_task_id = 0;
    self.cancelling = false;

    var bytes_read: usize = 0;
    if (io_uring_err == .SUCCESS and !data.cancelled) {
        bytes_read = @intCast(io_uring_res);
    }

    var exception: PyObject = undefined;
    const ret = self.read_completed_callback(self, self.buffer_to_read[0..bytes_read], io_uring_err);

    const parent_transport = self.parent_transport;

    if (ret) |_| {
        const is_closing = self.is_closing;
        if (io_uring_err == .SUCCESS or io_uring_err == .CANCELED or is_closing) {
            if (is_closing) {
                self.closed = true;
            }

            python_c.py_decref(parent_transport);
            return;
        }

        exception = python_c.PyObject_CallFunction(
            python_c.PyExc_OSError, "Ls\x00", @as(c_long, @intFromEnum(io_uring_err)), "Read operation failed\x00"
        ) orelse return error.PythonError;
    }else |err| {
        utils.handle_zig_function_error(err, {});
        exception = python_c.PyErr_GetRaisedException() orelse return error.PythonError;
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

pub inline fn perform(self: *ReadTransport, buffer: ?[]u8) !void {
    const buffer_to_read = buffer orelse self.buffer;

    self.blocking_task_id = try Loop.Scheduling.IO.queue(
        self.loop, .{
            .PerformRead = .{
                .callback = .{
                    .func = &read_operation_completed,
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
                .data = .{
                    .buffer = buffer_to_read
                },
                .zero_copy = self.zero_copying
            }
        }
    );

    self.buffer_to_read = buffer_to_read;
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
