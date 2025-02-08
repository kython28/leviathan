const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Loop = @import("../loop/main.zig");
const CallbackManager = @import("../callback_manager.zig");
const utils = @import("../utils/main.zig");

pub const ReadCompletedCallback = *const fn (*ReadTransport, []const u8, std.os.linux.E) anyerror!void;

pub const MAX_READ = (1 << 16);

loop: *Loop,
parent_transport: usize,
exception_handler: PyObject,

read_completed_callback: ReadCompletedCallback,
buffer: []u8,

buffer_being_read: []u8,

fd: std.posix.fd_t,

blocking_task_id: usize = 0,

closed: bool = false,
is_closing: bool = false,
initialized: bool = false,

pub fn init(
    self: *ReadTransport, loop: *Loop, fd: std.posix.fd_t, callback: ReadCompletedCallback,
    parent_transport: usize, exception_handler: PyObject
) !void {
    const allocator = loop.allocator;

    const buffer = try allocator.alloc(u8, MAX_READ);
    errdefer allocator.free(buffer);

    self.* = .{
        .loop = loop,
        .parent_transport = parent_transport,
        .exception_handler = exception_handler,

        .read_completed_callback = callback,
        .buffer = buffer,
        .buffer_being_read = undefined,

        .fd = fd,
        .initialized = true
    };
}

pub fn close(self: *ReadTransport) !void {
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

    const is_closing = self.is_closing;
    if (is_closing) {
        self.closed = true;
    }

    var bytes_read: usize = 0;
    if (io_uring_err == .SUCCESS and !is_closing) {
        bytes_read = @intCast(io_uring_res);
    }

    var exception: PyObject = undefined;
    var exc_message: PyObject = undefined;

    const ret = self.read_completed_callback(self, self.buffer_being_read[0..bytes_read], io_uring_err);
    if (ret) |_| {
        if (io_uring_err == .SUCCESS or io_uring_err == .CANCELED or is_closing) {
            return .Continue;
        }

        self.is_closing = true;
        self.closed = true;

        exc_message = python_c.PyUnicode_FromString("Exception ocurred while reading\x00")
            orelse return .Exception;

        exception = python_c.PyObject_CallFunction(
            python_c.PyExc_OSError, "LO\x00", @as(c_long, @intFromEnum(io_uring_err)), exc_message
        ) orelse {
            python_c.py_decref(exc_message);
            return .Exception;
        };
    }else |err| {
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

    var args: [3]PyObject = undefined;
    args[0] = exception;
    args[1] = exc_message;
    args[2] = @ptrFromInt(self.parent_transport);

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
                .offset = 0
            }
        }
    );

    self.buffer_being_read = buffer_being_read;
}

pub inline fn cancel(self: *ReadTransport) !void {
    if (self.blocking_task_id == 0) {
        return;
    }

    _ = try Loop.Scheduling.IO.queue(
        self.loop, .{
            .Cancel = self.blocking_task_id
        }
    );
}

const ReadTransport = @This();
