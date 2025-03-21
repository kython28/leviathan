const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("utils");

const Lifecyle = @import("lifecycle.zig");
const Stream = @import("main.zig");
const StreamTransportObject = Stream.StreamTransportObject;

const ReadTransport = @import("../read_transport.zig");
const WriteTransport = @import("../write_transport.zig");

pub inline fn queue_read_operation(
    transport: *StreamTransportObject,
    read_transport: *ReadTransport,
    protocol_type: Stream.ProtocolType
) !void {
    if (!transport.is_reading or read_transport.is_closing) {
        return;
    }

    switch (protocol_type) {
        .Buffered => {
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
            try read_transport.perform(null);
        }
    }
}

pub fn read_operation_completed(read_transport: *ReadTransport, data: []const u8, err: std.os.linux.E) !void {
    const transport: *StreamTransportObject = @ptrCast(read_transport.parent_transport);

    var protocol_buffer = transport.protocol_buffer;
    transport.protocol_buffer = comptime std.mem.zeroes(python_c.Py_buffer);
    defer {
        if (protocol_buffer.buf != null) {
            python_c.PyBuffer_Release(&protocol_buffer);
        }
    }

    // When `read_transport` is closing, data length will be always 0
    const is_closing = read_transport.is_closing;
    if (err != .SUCCESS or is_closing) {
        if (err == .CANCELED) {
            try queue_read_operation(transport, read_transport, transport.protocol_type);
        }
        return;
    }

    if (data.len == 0) {
        const ret = python_c.PyObject_CallNoArgs(transport.protocol_eof_received.?)
            orelse return error.PythonError;
        defer python_c.py_decref(ret);

        if (python_c.Py_IsTrue(ret) == 0) {
            // TODO: use instance
            const write_transport = utils.get_data_ptr2(WriteTransport, "write_transport", transport);
            const exc = python_c.get_py_none();
            defer python_c.py_decref(exc);

            try Lifecyle.close_transports(
                transport, read_transport, write_transport, exc
            );
        } 

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

            try queue_read_operation(transport, read_transport, .Buffered);
        },
        .Legacy => {
            const py_bytes = python_c.PyBytes_FromStringAndSize(data.ptr, @intCast(data.len))
                orelse return error.PythonError;
            defer python_c.py_decref(py_bytes);

            const ret = python_c.PyObject_CallOneArg(transport.protocol_data_received.?, py_bytes)
                orelse return error.PythonError;
            python_c.py_decref(ret);

            try queue_read_operation(transport, read_transport, .Legacy);
        }
    }
}

pub fn transport_is_reading(self: ?*StreamTransportObject) callconv(.C) ?PyObject {
    return python_c.PyBool_FromLong(@intCast(@intFromBool(self.?.is_reading)));
}

pub fn transport_pause_reading(self: ?*StreamTransportObject) callconv(.C) ?PyObject {
    const instance = self.?;

    if (instance.closed) {
        python_c.raise_python_runtime_error("Transport is closed\x00");
        return null;
    }

    if (!instance.is_reading) {
        return python_c.get_py_none();
    }

    const read_transport = utils.get_data_ptr2(ReadTransport, "read_transport", instance);
    read_transport.cancel() catch |err| {
        return utils.handle_zig_function_error(err, null);
    };

    instance.is_reading = false;
    return python_c.get_py_none();
}

pub fn transport_resume_reading(self: ?*StreamTransportObject) callconv(.C) ?PyObject {
    const instance = self.?;

    if (instance.closed) {
        python_c.raise_python_runtime_error("Transport is closed\x00");
        return null;
    }

    instance.is_reading = true;

    const read_transport = utils.get_data_ptr2(ReadTransport, "read_transport", instance);
    if (read_transport.blocking_task_id != 0) {
        return python_c.get_py_none();
    }

    queue_read_operation(instance, read_transport, instance.protocol_type) catch |err| {
        instance.is_reading = false;
        return utils.handle_zig_function_error(err, null);
    };
    return python_c.get_py_none();
}
