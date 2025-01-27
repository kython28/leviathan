const python_c = @import("python_c");
const PyObject = *python_c.PyObject;
const PyTypeObject = *python_c.PyTypeObject;

const std = @import("std");

pub var asyncio_module: ?PyObject = null;
pub var sys_module: ?PyObject = null;
pub var weakref_module: ?PyObject = null;

pub var invalid_state_exc: ?PyObject = null;
pub var cancelled_error_exc: ?PyObject = null;

pub var set_running_loop: ?PyObject = null;
pub var enter_task_func: ?PyObject = null;
pub var leave_task_func: ?PyObject = null;
pub var register_task_func: ?PyObject = null;

pub var get_asyncgen_hooks: ?PyObject = null;
pub var set_asyncgen_hooks: ?PyObject = null;

pub var weakref_set_class: ?PyObject = null;
pub var weakref_set: ?PyObject = null;
pub var weakref_add: ?PyObject = null;
pub var weakref_discard: ?PyObject = null;

pub fn initialize_python_imports() !void {
    asyncio_module = python_c.PyImport_ImportModule("asyncio\x00") orelse return error.PythonError;
    sys_module = python_c.PyImport_ImportModule("sys\x00") orelse return error.PythonError;
    weakref_module = python_c.PyImport_ImportModule("weakref\x00") orelse return error.PythonError;

    invalid_state_exc = python_c.PyObject_GetAttrString(asyncio_module.?, "InvalidStateError\x00")
        orelse return error.PythonError;
    cancelled_error_exc = python_c.PyObject_GetAttrString(asyncio_module.?, "CancelledError\x00")
        orelse return error.PythonError;

    set_running_loop = python_c.PyObject_GetAttrString(asyncio_module.?, "_set_running_loop\x00")
        orelse return error.PythonError;
    enter_task_func = python_c.PyObject_GetAttrString(asyncio_module.?, "_enter_task\x00")
        orelse return error.PythonError;
    leave_task_func = python_c.PyObject_GetAttrString(asyncio_module.?, "_leave_task\x00")
        orelse return error.PythonError;
    register_task_func = python_c.PyObject_GetAttrString(asyncio_module.?, "_register_task\x00")
        orelse return error.PythonError;

    get_asyncgen_hooks = python_c.PyObject_GetAttrString(sys_module.?, "get_asyncgen_hooks\x00")
        orelse return error.PythonError;
    set_asyncgen_hooks = python_c.PyObject_GetAttrString(sys_module.?, "set_asyncgen_hooks\x00")
        orelse return error.PythonError;

    weakref_set_class = python_c.PyObject_GetAttrString(weakref_module.?, "WeakSet\x00")
        orelse return error.PythonError;
    weakref_set = python_c.PyObject_CallNoArgs(weakref_set_class.?)
        orelse return error.PythonError;
    weakref_add = python_c.PyObject_GetAttrString(weakref_set.?, "add\x00")
        orelse return error.PythonError;
    weakref_discard = python_c.PyObject_GetAttrString(weakref_set.?, "discard\x00")
        orelse return error.PythonError;
}

pub fn release_python_imports() void {
    const decls = comptime std.meta.declarations(@This());
    inline for (decls) |decl| {
        const decl_value_ptr = &@field(@This(), decl.name);
        const decl_type_info = @typeInfo(@TypeOf(decl_value_ptr.*));
        if (decl_type_info != .optional) continue;
        if (decl_type_info.optional.child != PyObject) continue;

        python_c.py_decref_and_set_null(decl_value_ptr);
    }
}
