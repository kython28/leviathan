const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const WriteStream = @import("../write_transport.zig");
const ReadStream = @import("../read_transport.zig");
const utils = @import("../../utils/main.zig");

const Constructors = @import("constructors.zig");
const Lifecyle = @import("lifecycle.zig");
const ExtraInfo = @import("extra_info.zig");
const Read = @import("read.zig");
const Write = @import("write.zig");

const PythonStreamMethods: []const python_c.PyMethodDef = &[_]python_c.PyMethodDef{
    // -------------------------- lifecycle --------------------------
    python_c.PyMethodDef{
        .ml_name = "close\x00",
        .ml_meth = @ptrCast(&Lifecyle.transport_close),
        .ml_doc = "Close the transport\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "is_closing\x00",
        .ml_meth = @ptrCast(&Lifecyle.transport_close),
        .ml_doc = "Return True if the transport is closing or is closed\x00",
        .ml_flags = python_c.METH_NOARGS
    },

    // -------------------------- read --------------------------
    python_c.PyMethodDef{
        .ml_name = "is_reading\x00",
        .ml_meth = @ptrCast(&Read.transport_is_reading),
        .ml_doc = "Return True if the transport is receiving new data.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "pause_reading\x00",
        .ml_meth = @ptrCast(&Read.transport_pause_reading),
        .ml_doc = "Pause the receiving end of the transport.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "resume_reading\x00",
        .ml_meth = @ptrCast(&Read.transport_resume_reading),
        .ml_doc = "Resume the receiving end of the transport.\x00",
        .ml_flags = python_c.METH_NOARGS
    },

    // -------------------------- write --------------------------
    python_c.PyMethodDef{
        .ml_name = "abort\x00",
        .ml_meth = @ptrCast(&Lifecyle.transport_close),
        .ml_doc = "Close the transport immediately.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "can_write_eof\x00",
        .ml_meth = @ptrCast(&Write.transport_can_write_eof),
        .ml_doc = "Return True if the transport supports write_eof(), False if not.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "get_write_buffer_size\x00",
        .ml_meth = @ptrCast(&Write.transport_get_write_buffer_size),
        .ml_doc = "Return the current size of the output buffer used by the transport.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "set_write_buffer_limits\x00",
        .ml_meth = @ptrCast(&Write.transport_set_write_buffer_limits),
        .ml_doc = "Return the current size of the output buffer used by the transport.\x00",
        .ml_flags = python_c.METH_FASTCALL | python_c.METH_KEYWORDS
    },
    python_c.PyMethodDef{
        .ml_name = "set_write_buffer_limits\x00",
        .ml_meth = @ptrCast(&Write.transport_set_write_buffer_limits),
        .ml_doc = "Set the high and low watermarks for write flow control.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "write\x00",
        .ml_meth = @ptrCast(&Write.transport_write),
        .ml_doc = "Write some data bytes to the transport.\x00",
        .ml_flags = python_c.METH_O
    },
    python_c.PyMethodDef{
        .ml_name = "writelines\x00",
        .ml_meth = @ptrCast(&Write.transport_write_lines),
        .ml_doc = "Write a list (or any iterable) of data bytes to the transport.\x00",
        .ml_flags = python_c.METH_O
    },
    python_c.PyMethodDef{
        .ml_name = "write_eof\x00",
        .ml_meth = @ptrCast(&Write.transport_write_eof),
        .ml_doc = "Close the write end of the transport after flushing all buffered data.\x00",
        .ml_flags = python_c.METH_NOARGS
    },

    // -------------------------- extra_info --------------------------
    python_c.PyMethodDef{
        .ml_name = "get_extra_info\x00",
        .ml_meth = @ptrCast(&ExtraInfo.transport_get_extra_info),
        .ml_doc = "Return information about the transport or underlying resources it uses.\x00",
        .ml_flags = python_c.METH_NOARGS
    },

    python_c.PyMethodDef{
        .ml_name = null, .ml_meth = null, .ml_doc = null, .ml_flags = 0
    }
};

pub const ProtocolType = enum(c_int) {
    Legacy, Buffered
};

pub const StreamTransportObject = extern struct {
    ob_base: python_c.PyObject,

    write_transport: [@sizeOf(WriteStream)]u8,
    read_transport: [@sizeOf(ReadStream)]u8,


    protocol_buffer: python_c.Py_buffer,

    socket: ?PyObject,
    peername: ?PyObject,
    sockname: ?PyObject,

    protocol: ?PyObject,
    protocol_max_read_constant: ?PyObject,

    protocol_eof_received: ?PyObject,
    protocol_data_received: ?PyObject,

    protocol_get_buffer: ?PyObject,
    protocol_buffer_updated: ?PyObject,

    protocol_connection_lost: ?PyObject,
    protocol_pause_writing: ?PyObject,
    protocol_resume_writing: ?PyObject,

    writing_high_water_mark: usize,
    writing_low_water_mark: usize,

    fd: std.posix.fd_t,
    protocol_type: ProtocolType,
    is_reading: bool,
    is_writing: bool,
    closed: bool,
};

// const PythonStreamMembers: []const python_c.PyMemberDef = &[_]python_c.PyMemberDef{
//     python_c.PyMemberDef{
//         .name = null, .flags = 0, .offset = 0, .doc = null
//     }
// };

const stream_slots = [_]python_c.PyType_Slot{
    .{ .slot = python_c.Py_tp_doc, .pfunc = @constCast("Leviathan's Stream Transport\x00") },
    .{ .slot = python_c.Py_tp_new, .pfunc = @constCast(&Constructors.stream_new) },
    .{ .slot = python_c.Py_tp_traverse, .pfunc = @constCast(&Constructors.stream_traverse) },
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
