const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const WriteStream = @import("../write_transport.zig");
const ReadStream = @import("../read_transport.zig");
const utils = @import("../../utils/main.zig");

const Constructors = @import("constructors.zig");

const PythonStreamMethods: []const python_c.PyMethodDef = &[_]python_c.PyMethodDef{
    python_c.PyMethodDef{
        .ml_name = null, .ml_meth = null, .ml_doc = null, .ml_flags = 0
    }
};

pub const StreamTransportObject = extern struct {
    ob_base: python_c.PyObject,

    write_data: [@sizeOf(WriteStream)]u8,
    read_data: [@sizeOf(ReadStream)]u8,

    protocol: ?PyObject,
    fd: std.posix.fd_t
};

// const PythonStreamMembers: []const python_c.PyMemberDef = &[_]python_c.PyMemberDef{
//     python_c.PyMemberDef{
//         .name = null, .flags = 0, .offset = 0, .doc = null
//     }
// };

const stream_slots = [_]python_c.PyType_Slot{
    .{ .slot = python_c.Py_tp_doc, .pfunc = @constCast("Leviathan's Stream Transport\x00") },
    .{ .slot = python_c.Py_tp_new, .pfunc = @constCast(&Constructors.stream_new) },
    // .{ .slot = python_c.Py_tp_traverse, .pfunc = @constCast(&Constructors.stream_traverse) },
    .{ .slot = python_c.Py_tp_clear, .pfunc = @constCast(&Constructors.stream_clear) },
    .{ .slot = python_c.Py_tp_init, .pfunc = @constCast(&Constructors.stream_init) },
    .{ .slot = python_c.Py_tp_dealloc, .pfunc = @constCast(&Constructors.stream_dealloc) },
    .{ .slot = python_c.Py_tp_methods, .pfunc = @constCast(PythonStreamMethods.ptr) },
    // .{ .slot = python_c.Py_tp_members, .pfunc = @constCast(LoopMembers.ptr) },
    .{ .slot = 0, .pfunc = null },
};

const stream_spec = python_c.PyType_Spec{
    .name = "leviathan.StreamTransport\x00",
    .basicsize = @sizeOf(StreamTransportObject),
    .itemsize = 0,
    .flags = python_c.Py_TPFLAGS_DEFAULT | python_c.Py_TPFLAGS_BASETYPE | python_c.Py_TPFLAGS_HAVE_GC,
    .slots = @constCast(&stream_slots),
};

pub var StreamType: *python_c.PyTypeObject = undefined;

pub fn create_type() !void {
    const type_stream_transport = python_c.PyType_FromSpecWithBases(
        @constCast(&stream_spec), utils.PythonImports.asyncio_transport
    ) orelse return error.PythonError;
    StreamType = @ptrCast(type_stream_transport);
}
