const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../utils/main.zig");

const Loop = @import("../../loop/main.zig");

const Stream = @import("main.zig");
const StreamTransportObject = Stream.StreamTransportObject;

const WriteTransport = @import("../write_transport.zig");
const ReadTransport = @import("../read_transport.zig");

pub fn transport_close(self: ?*StreamTransportObject) callconv(.C) ?PyObject {
    const instance = self.?;

    if (instance.closed) {
        python_c.raise_python_runtime_error("Transport already closed\x00");
        return null;
    }

    const read_transport = utils.get_data_ptr2(ReadTransport, "read_transport", instance);
    const write_transport = utils.get_data_ptr2(WriteTransport, "write_transport", instance);

    if (read_transport.closed and write_transport.closed) {
        std.posix.close(instance.fd);
        instance.closed = true;

        python_c.raise_python_runtime_error("Transport already closed\x00");
        return null;
    }

    read_transport.close() catch |err| {
        return utils.handle_zig_function_error(err, null);
    };

    write_transport.close() catch |err| {
        return utils.handle_zig_function_error(err, null);
    };

    return python_c.get_py_none();
}

pub fn transport_is_closing(self: ?*StreamTransportObject) callconv(.C) ?PyObject {
    const instance = self.?;

    if (instance.closed) {
        return python_c.get_py_true();
    }

    const read_transport = utils.get_data_ptr2(ReadTransport, "read_transport", instance);
    const write_transport = utils.get_data_ptr2(WriteTransport, "write_transport", instance);

    const closed = read_transport.closed and write_transport.closed;
    if (closed) {
        std.posix.close(instance.fd);
        instance.closed = closed;
    }

    return python_c.PyBool_FromLong(@intCast(@intFromBool(closed)));
}
