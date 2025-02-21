const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../utils/main.zig");

const Loop = @import("../../loop/main.zig");
const LoopObject = Loop.Python.LoopObject;

const Stream = @import("main.zig");
const StreamTransportObject = Stream.StreamTransportObject;

const Read = @import("read.zig");
const Write = @import("write.zig");
const Lifecyle = @import("lifecycle.zig");

const WriteTransport = @import("../write_transport.zig");
const ReadTransport = @import("../read_transport.zig");

inline fn check_protocol_compatibility(protocol: PyObject, protocol_type: *Stream.ProtocolType) bool {
    const compatible_protocols = .{"asyncio_protocol", "asyncio_buffered_protocol"};
    const protocol_types = .{Stream.ProtocolType.Legacy, Stream.ProtocolType.Buffered};
    inline for (compatible_protocols, protocol_types) |name, @"type"| {
        switch (python_c.PyObject_IsInstance(protocol, @field(utils.PythonImports, name))) {
            1 => {
                protocol_type.* = @"type";
                return false;
            },
            0 => {},
            else => return true
        }
    }

    python_c.raise_python_type_error("Invalid protocol\x00");
    return true;
}

pub fn set_protocol(self: *StreamTransportObject, protocol: PyObject) !Stream.ProtocolType {
    var protocol_type: Stream.ProtocolType = undefined;
    if (check_protocol_compatibility(protocol, &protocol_type)) {
        return error.PythonError;
    }

    const previous_protocol = self.protocol;
    const previous_protocol_type = self.protocol_type;
    const previous_protocol_get_buffer = self.protocol_get_buffer;
    const previous_protocol_buffer_updated = self.protocol_buffer_updated;
    const previous_protocol_data_received = self.protocol_data_received;
    const previous_protocol_eof_received = self.protocol_eof_received;
    const previous_protocol_connection_lost = self.protocol_connection_lost;
    const previous_protocol_pause_writing = self.protocol_pause_writing;
    const previous_protocol_resume_writing = self.protocol_resume_writing;

    errdefer {
        self.protocol = previous_protocol;
        self.protocol_type = previous_protocol_type;
        self.protocol_get_buffer = previous_protocol_get_buffer;
        self.protocol_buffer_updated = previous_protocol_buffer_updated;
        self.protocol_data_received = previous_protocol_data_received;
        self.protocol_eof_received = previous_protocol_eof_received;
        self.protocol_connection_lost = previous_protocol_connection_lost;
        self.protocol_pause_writing = previous_protocol_pause_writing;
        self.protocol_resume_writing = previous_protocol_resume_writing;
    }

    self.protocol_type = protocol_type;

    self.protocol = protocol;
    errdefer python_c.py_decref(protocol);

    switch (protocol_type) {
        .Buffered => {
            const get_buffer_func = python_c.PyObject_GetAttrString(protocol, "get_buffer\x00")
                orelse return error.PythonError;
            errdefer python_c.py_decref(get_buffer_func);

            const buffer_updated_func = python_c.PyObject_GetAttrString(protocol, "buffer_updated\x00")
                orelse return error.PythonError;
            errdefer python_c.py_decref(buffer_updated_func);

            self.protocol_buffer_updated = buffer_updated_func;
            self.protocol_get_buffer = get_buffer_func;
            self.protocol_data_received = null;
        },
        .Legacy => {
            const data_received_func = python_c.PyObject_GetAttrString(protocol, "data_received\x00")
                orelse return error.PythonError;

            self.protocol_data_received = data_received_func;
            self.protocol_buffer_updated = null;
            self.protocol_get_buffer = null;
        }
    }
    errdefer {
        python_c.py_xdecref(self.protocol_get_buffer);
        python_c.py_xdecref(self.protocol_buffer_updated);
        python_c.py_xdecref(self.protocol_data_received);
    }

    self.protocol_eof_received = python_c.PyObject_GetAttrString(protocol, "eof_received\x00")
        orelse return error.PythonError;
    errdefer python_c.py_decref(self.protocol_eof_received.?);

    self.protocol_connection_lost = python_c.PyObject_GetAttrString(protocol, "connection_lost\x00")
        orelse return error.PythonError;
    errdefer python_c.py_decref(self.protocol_connection_lost.?);

    self.protocol_pause_writing = python_c.PyObject_GetAttrString(protocol, "pause_writing\x00")
        orelse return error.PythonError;
    errdefer python_c.py_decref(self.protocol_pause_writing.?);

    self.protocol_resume_writing = python_c.PyObject_GetAttrString(protocol, "resume_writing\x00")
        orelse return error.PythonError;
    errdefer python_c.py_decref(self.protocol_resume_writing.?);

    python_c.py_xdecref(previous_protocol);
    python_c.py_xdecref(previous_protocol_get_buffer);
    python_c.py_xdecref(previous_protocol_buffer_updated);
    python_c.py_xdecref(previous_protocol_data_received);
    python_c.py_xdecref(previous_protocol_eof_received);
    python_c.py_xdecref(previous_protocol_connection_lost);
    python_c.py_xdecref(previous_protocol_pause_writing);
    python_c.py_xdecref(previous_protocol_resume_writing);

    return protocol_type;
}

fn stream_init_configuration(
    self: *StreamTransportObject, protocol: PyObject, loop: *LoopObject,
    fd: u32, zero_copying: bool
) !void {
    self.loop = @ptrCast(python_c.py_newref(loop));
    errdefer python_c.py_decref_and_set_null(&self.loop);

    self.protocol_max_read_constant = python_c.PyLong_FromUnsignedLongLong(ReadTransport.MAX_READ)
        orelse return error.PythonError;
    errdefer python_c.py_decref_and_set_null(&self.protocol_max_read_constant);

    const loop_data = utils.get_data_ptr(Loop, loop);

    const write_transport_data = utils.get_data_ptr2(WriteTransport, "write_transport", self);
    try write_transport_data.init(
        loop_data, @intCast(fd), &Write.write_operation_completed, @ptrCast(self),
        loop.exception_handler.?, &Lifecyle.connection_lost_callback,
        zero_copying
    );
    errdefer write_transport_data.deinit();

    const read_transport_data = utils.get_data_ptr2(ReadTransport, "read_transport", self);
    try read_transport_data.init(
        loop_data, @intCast(fd), &Read.read_operation_completed, @ptrCast(self),
        loop.exception_handler.?, &Lifecyle.connection_lost_callback,
        zero_copying
    );
    errdefer read_transport_data.deinit();

    const protocol_type = try set_protocol(self, protocol);
    errdefer {
        python_c.py_decref_and_set_null(&self.protocol);
        python_c.py_decref_and_set_null(&self.protocol_get_buffer);
        python_c.py_decref_and_set_null(&self.protocol_buffer_updated);
        python_c.py_decref_and_set_null(&self.protocol_data_received);
        python_c.py_decref_and_set_null(&self.protocol_eof_received);
        python_c.py_decref_and_set_null(&self.protocol_connection_lost);
        python_c.py_decref_and_set_null(&self.protocol_pause_writing);
        python_c.py_decref_and_set_null(&self.protocol_resume_writing);
    }

    const watermark = (comptime std.math.maxInt(usize))/2;

    self.writing_low_water_mark = watermark;
    self.writing_high_water_mark = watermark;

    self.is_writing = true;
    self.is_reading = true;
    self.closed = false;
    self.fd = @intCast(fd);

    try Read.queue_read_operation(self, read_transport_data, protocol_type);
}

pub fn new_stream_transport(protocol: PyObject, loop: *LoopObject, fd: u32, zero_copying: bool) !*StreamTransportObject {
    const instance: *StreamTransportObject = @ptrCast(
        Stream.StreamType.tp_alloc.?(Stream.StreamType, 0) orelse return error.PythonError
    );
    errdefer Stream.StreamType.tp_free.?(instance);

    try stream_init_configuration(
        instance, protocol, loop, fd, zero_copying
    );

    return instance;
}

inline fn z_stream_new(@"type": *python_c.PyTypeObject) !*StreamTransportObject {
    const instance: *StreamTransportObject = @ptrCast(@"type".tp_alloc.?(@"type", 0) orelse return error.PythonError);
    errdefer @"type".tp_free.?(instance);

    python_c.initialize_object_fields(instance, &.{"ob_base", "fd", "protocol_type", "closed"});

    instance.fd = -1;
    instance.protocol_type = undefined;
    instance.closed = true;

    return instance;
}

pub fn stream_new(
    @"type": ?*python_c.PyTypeObject, _: ?PyObject,
    _: ?PyObject
) callconv(.C) ?*StreamTransportObject {
    return utils.execute_zig_function(z_stream_new, .{@"type".?});
}
 
pub fn stream_traverse(self: ?*StreamTransportObject, visit: python_c.visitproc, arg: ?*anyopaque) callconv(.C) c_int {
    return python_c.py_visit(self.?, visit, arg);
}

pub fn stream_clear(self: ?*StreamTransportObject) callconv(.C) c_int {
    const py_transport = self.?;
    const write_transport_data = utils.get_data_ptr2(WriteTransport, "write_transport", py_transport);
    if (write_transport_data.initialized) {
        write_transport_data.deinit();
    }

    const read_transport_data = utils.get_data_ptr2(ReadTransport, "read_transport", py_transport);
    if (read_transport_data.initialized) {
        read_transport_data.deinit();
    }

    if (py_transport.protocol_buffer.buf != null) {
        python_c.PyBuffer_Release(&py_transport.protocol_buffer);
    }

    python_c.deinitialize_object_fields(py_transport, &.{"protocol_buffer"});
    py_transport.protocol_type = undefined;

    const fd = py_transport.fd;
    if (fd >= 0) {
        _ = std.os.linux.close(fd);
        py_transport.fd = -1;
    }

    return 0;
}

pub fn stream_dealloc(self: ?*StreamTransportObject) callconv(.C) void {
    const instance = self.?;

    python_c.PyObject_GC_UnTrack(instance);
    _ = stream_clear(instance);

    const @"type" = python_c.get_type(@ptrCast(instance));
    @"type".tp_free.?(@ptrCast(instance));

    python_c.py_decref(@ptrCast(instance));
}


inline fn z_stream_init(self: *StreamTransportObject, args: ?PyObject, kwargs: ?PyObject) !c_int {
    var kwlist: [4][*c]u8 = undefined;
    kwlist[0] = @constCast("fd\x00");
    kwlist[1] = @constCast("protocol\x00");
    kwlist[2] = @constCast("loop\x00");
    kwlist[3] = null;

    var fd: i64 = -1;
    var py_protocol: ?PyObject = null;
    var loop: ?PyObject = null;

    if (python_c.PyArg_ParseTupleAndKeywords(args, kwargs, "LOO\x00", @ptrCast(&kwlist), &fd, &py_protocol, &loop) < 0) {
        return error.PythonError;
    }

    if (fd < 0) {
        python_c.raise_python_value_error("Invalid fd\x00");
        return error.PythonError;
    }

    if (!python_c.type_check(loop.?, Loop.Python.LoopType)) {
        python_c.raise_python_type_error("Invalid event loop. Only Leviathan's loops are allow\x00");
        return error.PythonError;
    }

    const leviathan_loop: *LoopObject = @ptrCast(loop.?);
    try stream_init_configuration(self, py_protocol.?, leviathan_loop, @intCast(fd), false);

    return 0;
}

pub fn stream_init(self: ?*StreamTransportObject, args: ?PyObject, kwargs: ?PyObject) callconv(.C) c_int {
    return utils.execute_zig_function(z_stream_init, .{self.?, args, kwargs});
}
