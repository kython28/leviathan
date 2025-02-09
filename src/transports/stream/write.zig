const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../utils/main.zig");

const Loop = @import("../../loop/main.zig");

const Lifecyle = @import("lifecycle.zig");

const Stream = @import("main.zig");
const StreamTransportObject = Stream.StreamTransportObject;

const WriteTransport = @import("../write_transport.zig");


pub fn write_operation_completed(
    write_transport: *WriteTransport,
    data_written: usize, remaining_data: usize,
    err: std.os.linux.E
) !void {
    if (err != .SUCCESS or data_written == 0) {
        return;
    }

    const instance: *StreamTransportObject = @ptrFromInt(write_transport.parent_transport);

    if (!instance.is_writing) {
        if (remaining_data <= instance.writing_low_water_mark) {
            instance.is_writing = true;

            const ret = python_c.PyObject_CallNoArgs(instance.protocol_resume_writing.?)
                orelse return error.PythonError;
            python_c.py_decref(ret);
        }
    }
}

pub fn transport_can_write_eof(_: ?*StreamTransportObject) callconv(.C) ?PyObject {
    return python_c.get_py_true();
}

pub fn transport_write_eof(self: ?*StreamTransportObject) callconv(.C) ?PyObject {
    const instance = self.?;

    const write_transport = utils.get_data_ptr2(WriteTransport, "write_transport", instance);
    if (write_transport.is_closing) {
        python_c.raise_python_runtime_error("Transport is closed\x00");
        return null;
    }

    write_transport.queue_eof() catch |err| {
        return utils.handle_zig_function_error(err, null);
    };

    return python_c.get_py_none();
}

pub fn transport_get_write_buffer_size(self: ?*StreamTransportObject) callconv (.C) ?PyObject {
    const instance = self.?;

    const write_transport = utils.get_data_ptr2(WriteTransport, "write_transport", instance);
    return python_c.PyLong_FromUnsignedLongLong(@intCast(write_transport.buffer_size));
}

// pub fn transport_get_write_buffer_limits(self: ?*StreamTransportObject) callconv (.C) ?PyObject {}


pub fn transport_write(self: ?*StreamTransportObject, py_buffer: ?PyObject) callconv(.C) ?PyObject {
    const instance = self.?;

    if (!instance.is_writing) {
        python_c.raise_python_runtime_error("Writing operations are paused\x00");
        return null;
    }


    const write_transport = utils.get_data_ptr2(WriteTransport, "write_transport", instance);
    if (write_transport.is_closing or write_transport.must_write_eof) {
        python_c.raise_python_runtime_error("Transport is closed\x00");
        return null;
    }

    const _py_buffer = py_buffer.?;

    var buffer: [*]u8 = undefined;
    var buffer_size: python_c.Py_ssize_t = undefined;
    if (python_c.PyBytes_AsStringAndSize(_py_buffer, @ptrCast(&buffer), &buffer_size) < 0) {
        return null;
    }

    if (buffer_size == 0) {
        write_transport.queue_eof() catch |err| {
            return utils.handle_zig_function_error(err, null);
        };
    }else{
        const new_buffer_size = write_transport.append_new_buffer_to_write(_py_buffer, buffer[0..@intCast(buffer_size)]) catch |err| {
            return utils.handle_zig_function_error(err, null);
        };
        python_c.py_incref(_py_buffer);

        if (new_buffer_size >= instance.writing_high_water_mark) {
            instance.is_writing = false;

            const ret = python_c.PyObject_CallNoArgs(instance.protocol_pause_writing.?)
                orelse return null;
            python_c.py_decref(ret);
        }
    }

    return python_c.get_py_none();
}

pub fn transport_write_lines(self: ?*StreamTransportObject, py_buffers: ?PyObject) callconv(.C) ?PyObject {
    const instance = self.?;

    if (!instance.is_writing) {
        python_c.raise_python_runtime_error("Writing operations are paused\x00");
        return null;
    }

    const _py_buffers = py_buffers.?;
    if (python_c.PyIter_Check(_py_buffers) == 0) {
        python_c.raise_python_type_error("Invalid iterable object\x00");
        return null;
    }

    const write_transport = utils.get_data_ptr2(WriteTransport, "write_transport", instance);
    if (write_transport.is_closing or write_transport.must_write_eof) {
        python_c.raise_python_runtime_error("Transport is closed\x00");
        return null;
    }

    const iter: PyObject = python_c.PyObject_GetIter(_py_buffers) orelse return null;
    var new_buffer_size: usize = 0;
    while (true) {
        const py_buffer: PyObject = python_c.PyIter_Next(iter) orelse break;

        var buffer: [*]u8 = undefined;
        var buffer_size: python_c.Py_ssize_t = undefined;
        if (python_c.PyBytes_AsStringAndSize(py_buffer, @ptrCast(&buffer), &buffer_size) < 0) {
            return null;
        }

        if (buffer_size == 0) {
            write_transport.queue_eof() catch |err| {
                return utils.handle_zig_function_error(err, null);
            };
        }else{
            new_buffer_size = write_transport.append_new_buffer_to_write(py_buffer, buffer[0..@intCast(buffer_size)]) catch |err| {
                return utils.handle_zig_function_error(err, null);
            };
            python_c.py_incref(py_buffer);

        }
    }

    if (new_buffer_size >= instance.writing_high_water_mark) {
        instance.is_writing = false;

        const ret = python_c.PyObject_CallNoArgs(instance.protocol_pause_writing.?)
            orelse return null;
        python_c.py_decref(ret);
    }

    return python_c.get_py_none();
}
