const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../utils/main.zig");

const Loop = @import("../../loop/main.zig");

const Stream = @import("main.zig");
const StreamTransportObject = Stream.StreamTransportObject;

const WriteTransport = @import("../write_transport.zig");
const ReadTransport = @import("../read_transport.zig");

fn read_operation_completed(transport: *ReadTransport, data_read: usize, err: std.os.linux.E) !void {
    _ = transport;
    _ = data_read;
    _ = err;
}

inline fn z_stream_new(@"type": *python_c.PyTypeObject) !*StreamTransportObject {
    const instance: *StreamTransportObject = @ptrCast(@"type".tp_alloc.?(@"type", 0) orelse return error.PythonError);
    errdefer @"type".tp_free.?(instance);

    @memset(&instance.write_data, 0);

    instance.fd = -1;
    instance.protocol = null;

    return instance;
}

pub fn stream_new(
    @"type": ?*python_c.PyTypeObject, _: ?PyObject,
    _: ?PyObject
) callconv(.C) ?*StreamTransportObject {
    return utils.execute_zig_function(z_stream_new, .{@"type".?});
}
 
pub fn stream_traverse(self: ?*StreamTransportObject, visit: python_c.visitproc, arg: ?*anyopaque) callconv(.C) c_int {
    const instance = self.?;
    return python_c.py_visit(
        &[_]?PyObject{
            instance.protocol,
        }, visit, arg
    );
}

pub fn stream_clear(self: ?*StreamTransportObject) callconv(.C) c_int {
    const py_transport = self.?;
    const write_transport_data = utils.get_data_ptr2(WriteTransport, "write_data", py_transport);
    if (write_transport_data.initialized) {
        write_transport_data.deinit();
    }

    const fd = py_transport.fd;
    if (fd >= 0) {
        std.posix.close(fd);
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

inline fn check_protocol_compatibility(protocol: PyObject) bool {
    const compatible_protocols = .{"asyncio_protocol", "asyncio_buffered_protocol"};
    inline for (compatible_protocols) |protocol_name| {
        switch (python_c.PyObject_IsInstance(protocol, @field(utils.PythonImports, protocol_name))) {
            1 => return false,
            0 => {},
            else => return true
        }
    }

    python_c.raise_python_type_error("Invalid protocol\x00");
    return true;
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

    if (!python_c.is_type(loop.?, Loop.Python.LoopType)) {
        python_c.raise_python_type_error("Invalid event loop. Only Leviathan's loops are allow\x00");
        return error.PythonError;
    }

    const leviathan_loop: *Loop.Python.LoopObject = @ptrCast(loop.?);

    if (fd < 0) {
        python_c.raise_python_value_error("Invalid fd\x00");
        return error.PythonError;
    }

    if (check_protocol_compatibility(py_protocol.?)) {
        return error.PythonError;
    }

    const loop_data = utils.get_data_ptr(Loop, leviathan_loop);

    const write_transport_data = utils.get_data_ptr2(WriteTransport, "write_data", self);
    try write_transport_data.init(loop_data, @intCast(fd), @ptrCast(self), leviathan_loop.exception_handler.?);
    errdefer write_transport_data.deinit();

    const read_transport_data = utils.get_data_ptr2(ReadTransport, "read_data", self);
    try read_transport_data.init(
        loop_data, @intCast(fd), &read_operation_completed, @ptrCast(self),
        leviathan_loop.exception_handler.?
    );
    errdefer read_transport_data.deinit();

    return 0;
}

pub fn stream_init(self: ?*StreamTransportObject, args: ?PyObject, kwargs: ?PyObject) callconv(.C) c_int {
    return utils.execute_zig_function(z_stream_init, .{self.?, args, kwargs});
}
