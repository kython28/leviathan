const std = @import("std");
const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

pub const Constructors = @import("constructors.zig");

const PythonPipeMethods: []const python_c.PyMethodDef = &[_]python_c.PyMethodDef{
    python_c.PyMethodDef{
        .ml_name = null, .ml_meth = null, .ml_doc = null, .ml_flags = 0
    }
};

pub const PipeTransport = extern struct {
    ob_base: python_c.PyObject,
    // Add transport-specific fields here
};

const PythonPipeMembers: []const python_c.PyMemberDef = &[_]python_c.PyMemberDef{
    python_c.PyMemberDef{
        .name = null, .flags = 0, .offset = 0, .doc = null
    }
};

pub var PipeType = python_c.PyTypeObject{
    .tp_name = "leviathan.Pipe\x00",
    .tp_doc = "Leviathan's Pipe Transport\x00",
    .tp_basicsize = @sizeOf(PipeTransport),
    .tp_itemsize = 0,
    .tp_flags = python_c.Py_TPFLAGS_DEFAULT | python_c.Py_TPFLAGS_BASETYPE,
    .tp_new = &Constructors.pipe_new,
    .tp_init = @ptrCast(&Constructors.pipe_init),
    .tp_clear = @ptrCast(&Constructors.pipe_clear),
    .tp_dealloc = @ptrCast(&Constructors.pipe_dealloc),
    .tp_methods = @constCast(PythonPipeMethods.ptr),
    .tp_members = @constCast(PythonPipeMembers.ptr),
};
