const Stream = @import("main.zig");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Loop = @import("../../loop/main.zig");
const CallbackManager = @import("../../callback_manager.zig");

fn stream_transport_write_operation_completed(
    data: ?*anyopaque, status: CallbackManager.ExecuteCallbacksReturn
) CallbackManager.ExecuteCallbacksReturn {
    _ = data;
    _ = status;

    return .Continue;
}

pub fn queue_buffers_and_swap(self: *Stream) !void {
    const current_free_buffers = self.free_buffers;
    const current_free_py_objects = self.free_py_objects;

    const current_busy_buffers = self.busy_buffers;
    const current_busy_py_objects = self.busy_py_objects;

    try Loop.Scheduling.IO.queue(
        self.loop, .{
            .PerformWriteV = .{
                .callback = .{
                    .ZigGeneric = .{
                        .callback = &stream_transport_write_operation_completed,
                        .data = self,
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

pub inline fn append_new_buffer_to_write(self: *Stream, py_object: PyObject, buffer: []const u8) !void {
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
