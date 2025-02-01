const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Loop = @import("../../loop/main.zig");

const StreamBuffersArrayList = std.ArrayList(std.posix.iovec_const);
const StreamPyObjectsArrayList = std.ArrayList(PyObject);

loop: *Loop,

free_buffers: *StreamBuffersArrayList,
free_py_objects: *StreamPyObjectsArrayList,

busy_buffers: *StreamBuffersArrayList,
busy_py_objects: *StreamPyObjectsArrayList,

fd: std.posix.fd_t,

is_reading: bool = true,
ready_to_queue_write_op: bool = true,

initialized: bool = false,


pub fn init(self: *Stream, loop: *Loop, fd: std.posix.fd_t) void {
    const allocator = loop.allocator;

    const free_buffers = try allocator.create(StreamBuffersArrayList);
    errdefer allocator.destroy(free_buffers);

    const busy_buffers = try allocator.create(StreamBuffersArrayList);
    errdefer allocator.destroy(busy_buffers);

    const free_py_objects = try allocator.create(StreamPyObjectsArrayList);
    errdefer allocator.destroy(free_py_objects);

    const busy_py_objects = try allocator.create(StreamPyObjectsArrayList);
    errdefer allocator.destroy(busy_py_objects);

    self.* = Stream{
        .loop = loop,

        .free_buffers = free_buffers,
        .free_py_objects = free_py_objects,

        .busy_buffers = busy_buffers,
        .busy_py_objects = busy_py_objects,

        .fd = fd,
        .initialized = true
    };
}

pub fn deinit(self: *Stream) void {
    if (!self.initialized) {
        @panic("Stream transport is not initialized");
    }

    const allocator = self.loop.allocator;
    allocator.destroy(self.free_buffers);
    allocator.destroy(self.free_py_objects);

    allocator.destroy(self.busy_buffers);
    allocator.destroy(self.busy_py_objects);

    self.initialized = false;
}


pub const Python = @import("python/main.zig");
const CallbacksManagement = @import("callbacks.zig");

const Stream = @This();
