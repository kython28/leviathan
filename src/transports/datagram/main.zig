const std = @import("std");
const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

pub const Constructors = @import("constructors.zig");

const PythonDatagramMethods: []const python_c.PyMethodDef = &[_]python_c.PyMethodDef{
    python_c.PyMethodDef{
        .ml_name = null, .ml_meth = null, .ml_doc = null, .ml_flags = 0
    }
};

pub const DatagramTransport = extern struct {
    ob_base: python_c.PyObject,
    // Add transport-specific fields here
};

const PythonDatagramMembers: []const python_c.PyMemberDef = &[_]python_c.PyMemberDef{
    python_c.PyMemberDef{
        .name = null, .flags = 0, .offset = 0, .doc = null
    }
};

pub var DatagramType = python_c.PyTypeObject{
    .tp_name = "leviathan.Datagram\x00",
    .tp_doc = "Leviathan's Datagram Transport\x00",
    .tp_basicsize = @sizeOf(DatagramTransport),
    .tp_itemsize = 0,
    .tp_flags = python_c.Py_TPFLAGS_DEFAULT | python_c.Py_TPFLAGS_BASETYPE,
    .tp_new = &Constructors.datagram_new,
    .tp_init = @ptrCast(&Constructors.datagram_init),
    .tp_clear = @ptrCast(&Constructors.datagram_clear),
    .tp_dealloc = @ptrCast(&Constructors.datagram_dealloc),
    .tp_methods = @constCast(PythonDatagramMethods.ptr),
    .tp_members = @constCast(PythonDatagramMembers.ptr),
};
