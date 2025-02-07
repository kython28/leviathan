const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../utils/main.zig");

const Loop = @import("../../loop/main.zig");

const Stream = @import("main.zig");
const StreamTransportObject = Stream.StreamTransportObject;

const Lifecyle = @import("lifecycle.zig");

const WriteTransport = @import("../write_transport.zig");
const ReadTransport = @import("../read_transport.zig");

pub fn read_operation_completed(read_transport: *ReadTransport, data: []const u8, err: std.os.linux.E) !void {
    const transport: *StreamTransportObject = @ptrFromInt(read_transport.parent_transport);

    var protocol_buffer = transport.protocol_buffer;
    transport.protocol_buffer = comptime std.mem.zeroes(python_c.Py_buffer);
    defer {
        if (protocol_buffer.buf != null) {
            python_c.PyBuffer_Release(&protocol_buffer);
        }
    }

    // When `read_transport` is closing, data length will be always 0
    if (err != .SUCCESS or data.len == 0) {
        return;
    }

    switch (transport.protocol_type) {
        .Buffered => {
            const nbytes_obj = python_c.PyLong_FromUnsignedLongLong(@intCast(data.len))
                orelse return error.PythonError;
            defer python_c.py_decref(nbytes_obj);

            const ret = python_c.PyObject_CallOneArg(transport.protocol_buffer_updated.?, nbytes_obj)
                orelse return error.PythonError;
            python_c.py_decref(ret);

            const new_buffer = python_c.PyObject_CallOneArg(
                transport.protocol_get_buffer.?, transport.protocol_max_read_constant.?
            ) orelse return error.PythonError;
            defer python_c.py_decref(new_buffer);

            if (python_c.PyObject_CheckBuffer(new_buffer) == 0) {
                python_c.raise_python_value_error(
                    "Invalid buffer obtained from protocol. Must be Buffer Protocol compatible\x00"
                );
                return error.PythonError;
            }

            var py_buffer: python_c.Py_buffer = comptime std.mem.zeroes(python_c.Py_buffer);
            if (python_c.PyObject_GetBuffer(new_buffer, &py_buffer, python_c.PyBUF_WRITABLE) < 0) {
                return error.PythonError;
            }
            errdefer python_c.PyBuffer_Release(&py_buffer);

            const buffer_to_read: [*]u8 = @ptrCast(py_buffer.buf.?);
            try read_transport.perform(buffer_to_read[0..@intCast(py_buffer.len)]);

            transport.protocol_buffer = py_buffer;
        },
        .Legacy => {
            const py_bytes = python_c.PyBytes_FromStringAndSize(data.ptr, @intCast(data.len))
                orelse return error.PythonError;
            defer python_c.py_decref(py_bytes);

            const ret = python_c.PyObject_CallOneArg(transport.protocol_data_received.?, py_bytes)
                orelse return error.PythonError;
            python_c.py_decref(ret);

            try read_transport.perform(null);
        }
    }


}

pub fn transport_is_reading(self: ?*StreamTransportObject) callconv(.C) ?PyObject {
    const instance = self.?;

    const read_transport = utils.get_data_ptr2(ReadTransport, "read_transport", instance);

    const is_reading = (read_transport.blocking_task_id != 0);
    return python_c.PyBool_FromLong(@intCast(@intFromBool(is_reading)));
}
