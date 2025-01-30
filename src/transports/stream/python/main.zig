const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Constructors = @import("constructors.zig");

const PythonStreamMethods: []const python_c.PyMethodDef = &[_]python_c.PyMethodDef{
    python_c.PyMethodDef{
        .ml_name = null, .ml_meth = null, .ml_doc = null, .ml_flags = 0
    }
};

pub const StreamTransport = extern struct {
    ob_base: python_c.PyObject,
};

const PythonStreamMembers: []const python_c.PyMemberDef = &[_]python_c.PyMemberDef{
    python_c.PyMemberDef{
        .name = null, .flags = 0, .offset = 0, .doc = null
    }
};

pub var StreamType = python_c.PyTypeObject{
    .tp_name = "leviathan.Stream\x00",
    .tp_doc = "Leviathan's Stream Transport\x00",
    .tp_basicsize = @sizeOf(StreamTransport),
    .tp_itemsize = 0,
    .tp_flags = python_c.Py_TPFLAGS_DEFAULT | python_c.Py_TPFLAGS_BASETYPE,
    .tp_new = &Constructors.stream_new,
    .tp_init = @ptrCast(&Constructors.stream_init),
    .tp_clear = @ptrCast(&Constructors.stream_clear),
    .tp_dealloc = @ptrCast(&Constructors.stream_dealloc),
    .tp_methods = @constCast(PythonStreamMethods.ptr),
    .tp_members = @constCast(PythonStreamMembers.ptr),
};
