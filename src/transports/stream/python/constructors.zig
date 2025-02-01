const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../../utils/main.zig");

const Stream = @import("../main.zig");
const StreamTransportObject = Stream.Python.StreamTransportObject;

inline fn z_stream_new(@"type": *python_c.PyTypeObject) !PyObject {
    const instance: *StreamTransportObject = @ptrCast(@"type".tp_alloc.?(@"type", 0) orelse return error.PythonError);
    errdefer @"type".tp_free.?(instance);

    @memset(&instance.data, 0);
    return instance;
}

pub fn stream_new(
    @"type": ?*python_c.PyTypeObject, _: ?PyObject,
    _: ?PyObject
) callconv(.C) ?PyObject {
    return utils.execute_zig_function(z_stream_new, .{@"type"});
}
 
// pub fn stream_traverse(self: ?*StreamTransportObject, visit: python_c.visitproc, arg: ?*anyopaque) callconv(.C) c_int {
//     _ = self; _ = visit; _ = arg;
//     return 0;
// }

pub fn stream_clear(self: ?*StreamTransportObject) callconv(.C) c_int {
    const py_transport = self.?;
    const transport_data = utils.get_data_ptr(Stream, py_transport);
    if (transport_data.initialized) {
        transport_data.deinit();
    }

    return 0;
}

pub fn stream_dealloc(self: ?PyObject) callconv(.C) void {
    const instance = self.?;

    python_c.PyObject_GC_UnTrack(instance);
    _ = stream_clear();

    const @"type" = python_c.get_type(@ptrCast(instance));
    @"type".tp_free.?(@ptrCast(instance));

    python_c.py_decref(@ptrCast(instance));
}

inline fn z_stream_init(self: *StreamTransportObject, args: ?PyObject, kwargs: ?PyObject) !c_int {
    var kwlist: [3][*c]u8 = undefined;
    kwlist[0] = @constCast("fd\x00");
    kwlist[1] = @constCast("protocol\x00");
    kwlist[2] = null;

    var fd: isize = -1;
    var py_protocol: ?PyObject = null;

    if (python_c.PyArg_ParseTupleAndKeywords(args, kwargs, "LO\x00", @ptrCast(&kwlist), &fd, &py_protocol) < 0) {
        return error.PythonError;
    }

    if (fd < 0) {
        python_c.raise_python_value_error("Invalid fd\x00");
        return error.PythonError;
    }

    const compatible_protocols = .{"asyncio_protocol", "asyncio_buffered_protocol"};
    const _py_protocol = py_protocol.?;
    inline for (compatible_protocols) |protocol_name| {
        switch (python_c.PyObject_IsInstance(_py_protocol, @field(utils.PythonImports, protocol_name))) {
            1 => {},
            0 => {
                python_c.raise_python_value_error("Invalid protocol\x00");
                return error.PythonError;
            },
            else => return error.PythonError
        }
    }

    return 0;
}

pub fn stream_init(self: ?*StreamTransportObject, args: ?PyObject, kwargs: ?PyObject) callconv(.C) c_int {
    return utils.execute_zig_function(z_stream_init, .{self.?, args, kwargs});
}
