const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../utils/main.zig");

const Loop = @import("../../loop/main.zig");

const Lifecyle = @import("lifecycle.zig");

const Stream = @import("main.zig");
const StreamTransportObject = Stream.StreamTransportObject;

const WriteTransport = @import("../write_transport.zig");


pub fn transport_can_write_eof(_: ?*StreamTransportObject) callconv(.C) ?PyObject {
    return python_c.get_py_true();
}

pub fn transport_write_eof(self: ?*StreamTransportObject) callconv(.C) ?PyObject {
    const instance = self.?;

    const write_transport = utils.get_data_ptr2(WriteTransport, "write_transport", instance);
    if (write_transport.closed) {
        python_c.raise_python_runtime_error("Transport is closed\x00");
        return null;
    }

    write_transport.queue_eof();
    return python_c.get_py_none();
}

pub fn transport_write(self: ?*StreamTransportObject, py_buffer: ?PyObject) callconv(.C) ?PyObject {
    const instance = self.?;

    const write_transport = utils.get_data_ptr2(WriteTransport, "write_transport", instance);
    if (write_transport.closed) {
        python_c.raise_python_runtime_error("Transport is closed\x00");
        return null;
    }

    const _py_buffer = py_buffer.?;
    if (!python_c.is_type(_py_buffer, python_c.PyBytes_Type)) {
        python_c.raise_python_type_error("Invalid buffer object\x00");
        return null;
    }

    var buffer: [*]u8 = undefined;
    var buffer_size: python_c.Py_ssize_t = undefined;
    if (python_c.PyBytes_AsStringAndSize(_py_buffer, &buffer, &buffer_size) < 0) {
        return null;
    }

    if (buffer_size == 0) {
        write_transport.queue_eof();
    }else{
        write_transport.append_new_buffer_to_write(_py_buffer, buffer[0..@intCast(buffer_size)]) catch |err| {
            return utils.handle_zig_function_error(err, null);
        };
        python_c.py_incref(_py_buffer);
    }

    return python_c.get_py_none();
}
