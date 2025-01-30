const std = @import("std");
const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

pub const Constructors = @import("constructors.zig");

const PythonSubprocessMethods: []const python_c.PyMethodDef = &[_]python_c.PyMethodDef{
    python_c.PyMethodDef{
        .ml_name = null, .ml_meth = null, .ml_doc = null, .ml_flags = 0
    }
};

pub const SubprocessTransport = extern struct {
    ob_base: python_c.PyObject,
    // Add transport-specific fields here
};

const PythonSubprocessMembers: []const python_c.PyMemberDef = &[_]python_c.PyMemberDef{
    python_c.PyMemberDef{
        .name = null, .flags = 0, .offset = 0, .doc = null
    }
};

pub var SubprocessType = python_c.PyTypeObject{
    .tp_name = "leviathan.Subprocess\x00",
    .tp_doc = "Leviathan's Subprocess Transport\x00",
    .tp_basicsize = @sizeOf(SubprocessTransport),
    .tp_itemsize = 0,
    .tp_flags = python_c.Py_TPFLAGS_DEFAULT | python_c.Py_TPFLAGS_BASETYPE,
    .tp_new = &Constructors.subprocess_new,
    .tp_init = @ptrCast(&Constructors.subprocess_init),
    .tp_clear = @ptrCast(&Constructors.subprocess_clear),
    .tp_dealloc = @ptrCast(&Constructors.subprocess_dealloc),
    .tp_methods = @constCast(PythonSubprocessMethods.ptr),
    .tp_members = @constCast(PythonSubprocessMembers.ptr),
};
