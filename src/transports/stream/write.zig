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

    const instance: *StreamTransportObject = @ptrCast(write_transport.parent_transport);

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

pub fn transport_get_write_buffer_limits(self: ?*StreamTransportObject) callconv (.C) ?PyObject {
    const instance = self.?;

    const tuple = python_c.PyTuple_New(2)
        orelse return null;
    defer python_c.py_decref(tuple);

    const low_water_mark = python_c.PyLong_FromUnsignedLongLong(@intCast(instance.writing_low_water_mark))
        orelse return null;
    defer python_c.py_decref(low_water_mark);

    const high_water_mark = python_c.PyLong_FromUnsignedLongLong(@intCast(instance.writing_high_water_mark))
        orelse return null;
    defer python_c.py_decref(high_water_mark);

    if (python_c.PyTuple_SetItem(tuple, 0, low_water_mark) < 0) {
        return null;
    }

    if (python_c.PyTuple_SetItem(tuple, 1, high_water_mark) < 0) {
        return null;
    }

    return python_c.py_newref(tuple);
}

inline fn z_transport_set_write_buffer_limits(
    self: *StreamTransportObject, args: []?PyObject,
    knames: ?PyObject
) !PyObject {
    if (args.len > 2) {
        python_c.raise_python_value_error("Invalid number of arguments\x00");
        return error.PythonError;
    }

    var py_high_water_mark: ?PyObject = null;
    var py_low_water_mark: ?PyObject = null;

    if (args.len >= 1) {
        py_high_water_mark = args[0].?;
    }

    if (args.len == 2) {
        py_low_water_mark = args[1].?;
    }

    try python_c.parse_vector_call_kwargs(
        knames, args.ptr + args.len,
        &.{"high\x00", "low\x00"},
        &.{&py_high_water_mark, &py_low_water_mark}
    );
    defer {
        python_c.py_xdecref(py_high_water_mark);
        python_c.py_xdecref(py_low_water_mark);
    }

    const watermark = (comptime std.math.maxInt(usize))/2;
    const py_long_error = comptime std.math.maxInt(c_ulonglong);

    var high_water_mark: usize = watermark;
    var low_water_mark: usize = watermark;
    if (py_high_water_mark) |obj| {
        const value = python_c.PyLong_AsUnsignedLongLong(obj);
        if (value == py_long_error) {
            return error.PythonError;
        }

        high_water_mark = @intCast(value);
        if (high_water_mark < low_water_mark) {
            low_water_mark = high_water_mark;
        }
    }

    if (py_low_water_mark) |obj| {
        const value = python_c.PyLong_AsUnsignedLongLong(obj);
        if (value == py_long_error) {
            return error.PythonError;
        }

        low_water_mark = @min(high_water_mark, @as(usize, @intCast(value)));
    }

    self.writing_high_water_mark = high_water_mark;
    self.writing_low_water_mark = low_water_mark;

    return python_c.get_py_none();
}

pub fn transport_set_write_buffer_limits(
    self: ?*StreamTransportObject, args: ?[*]?PyObject, nargs: isize, knames: ?PyObject
) callconv(.C) ?PyObject {
    return utils.execute_zig_function(z_transport_set_write_buffer_limits, .{
        self.?, args.?[0..@as(usize, @intCast(nargs))], knames
    });
}

pub fn transport_write(self: ?*StreamTransportObject, py_buffer: ?PyObject) callconv(.C) ?PyObject {
    const instance = self.?;

    const write_transport = utils.get_data_ptr2(WriteTransport, "write_transport", instance);
    if (write_transport.is_closing) {
        return python_c.get_py_none();
    }

    if (!instance.is_writing) {
        python_c.raise_python_runtime_error("Writing operations are paused\x00");
        return null;
    }

    const new_buffer_size = write_transport.append_new_buffer_to_write(py_buffer.?) catch |err| {
        return utils.handle_zig_function_error(err, null);
    };

    if (new_buffer_size >= instance.writing_high_water_mark) {
        instance.is_writing = false;

        const ret = python_c.PyObject_CallNoArgs(instance.protocol_pause_writing.?)
            orelse return null;
        python_c.py_decref(ret);
    }

    return python_c.get_py_none();
}

pub fn transport_write_lines(self: ?*StreamTransportObject, py_buffers: ?PyObject) callconv(.C) ?PyObject {
    const instance = self.?;

    const write_transport = utils.get_data_ptr2(WriteTransport, "write_transport", instance);
    if (write_transport.is_closing) {
        return python_c.get_py_none();
    }

    if (!instance.is_writing) {
        python_c.raise_python_runtime_error("Writing operations are paused\x00");
        return null;
    }

    const iter: PyObject = python_c.PyObject_GetIter(py_buffers.?) orelse return null;
    defer python_c.py_decref(iter);

    var new_buffer_size: usize = 0;
    while (true) {
        const py_buffer: PyObject = python_c.PyIter_Next(iter) orelse break;
        defer python_c.py_decref(py_buffer);

        new_buffer_size = write_transport.append_new_buffer_to_write(py_buffer) catch |err| {
            return utils.handle_zig_function_error(err, null);
        };
    }

    if (new_buffer_size >= instance.writing_high_water_mark) {
        instance.is_writing = false;

        const ret = python_c.PyObject_CallNoArgs(instance.protocol_pause_writing.?)
            orelse return null;
        python_c.py_decref(ret);
    }

    return python_c.get_py_none();
}
