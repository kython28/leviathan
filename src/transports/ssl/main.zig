const std = @import("std");
const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

pub const Constructors = @import("constructors.zig");

const PythonSSLMethods: []const python_c.PyMethodDef = &[_]python_c.PyMethodDef{
    python_c.PyMethodDef{
        .ml_name = null, .ml_meth = null, .ml_doc = null, .ml_flags = 0
    }
};

pub const SSLTransport = extern struct {
    ob_base: python_c.PyObject,
    // Add transport-specific fields here
};

const PythonSSLMembers: []const python_c.PyMemberDef = &[_]python_c.PyMemberDef{
    python_c.PyMemberDef{
        .name = null, .flags = 0, .offset = 0, .doc = null
    }
};

pub var SSLType = python_c.PyTypeObject{
    .tp_name = "leviathan.SSL\x00",
    .tp_doc = "Leviathan's SSL Transport\x00",
    .tp_basicsize = @sizeOf(SSLTransport),
    .tp_itemsize = 0,
    .tp_flags = python_c.Py_TPFLAGS_DEFAULT | python_c.Py_TPFLAGS_BASETYPE,
    .tp_new = &Constructors.ssl_new,
    .tp_init = @ptrCast(&Constructors.ssl_init),
    .tp_clear = @ptrCast(&Constructors.ssl_clear),
    .tp_dealloc = @ptrCast(&Constructors.ssl_dealloc),
    .tp_methods = @constCast(PythonSSLMethods.ptr),
    .tp_members = @constCast(PythonSSLMembers.ptr),
};
