const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const python_imports = @import("../../utils/python_imports.zig");

const utils = @import("../../utils/utils.zig");

const Loop = @import("../main.zig");
const LoopObject = Loop.Python.LoopObject;

const std = @import("std");

inline fn z_loop_new(@"type": *python_c.PyTypeObject) !*LoopObject {
    const instance: *LoopObject = @ptrCast(@"type".tp_alloc.?(@"type", 0) orelse return error.PythonError);
    errdefer @"type".tp_free.?(instance);

    python_c.initialize_object_fields(
        instance, &.{
            "ob_base", "asyncgens_set",
            "asyncgens_set_add", "asyncgens_set_discard",
            "old_asyncgen_hooks"
        }
    );

    const weakref_set_class = python_c.PyObject_GetAttrString(python_imports.weakref_module, "WeakSet\x00")
        orelse return error.PythonError;
    defer python_c.py_decref(weakref_set_class);

    const weakref_set = python_c.PyObject_CallNoArgs(weakref_set_class)
        orelse return error.PythonError;
    errdefer python_c.py_decref(weakref_set);

    const weakref_add = python_c.PyObject_GetAttrString(weakref_set, "add\x00")
        orelse return error.PythonError;
    errdefer python_c.py_decref(weakref_add);

    const weakref_discard = python_c.PyObject_GetAttrString(weakref_set, "discard\x00")
        orelse return error.PythonError;
    errdefer python_c.py_decref(weakref_discard);

    instance.asyncgens_set = weakref_set;
    instance.asyncgens_set_add = weakref_add;
    instance.asyncgens_set_discard = weakref_discard;

    instance.old_asyncgen_hooks = null;

    return instance;
}

pub fn loop_new(
    @"type": ?*python_c.PyTypeObject, _: ?PyObject,
    _: ?PyObject
) callconv(.C) ?PyObject {
    const self = utils.execute_zig_function(
        z_loop_new, .{@"type".?}
    );
    return @ptrCast(self);
}

pub fn loop_clear(self: ?*LoopObject) callconv(.C) c_int {
    const py_loop = self.?;
    const loop_data = utils.get_data_ptr(Loop, py_loop);
    if (loop_data.initialized) {
        loop_data.release();
    }

    python_c.deinitialize_object_fields(py_loop, &.{});
    // python_c.py_decref_and_set_null(&py_loop.asyncgens_set);
    // python_c.py_decref_and_set_null(&py_loop.asyncgens_set_add);
    // python_c.py_decref_and_set_null(&py_loop.asyncgens_set_discard);
    // python_c.py_decref_and_set_null(&py_loop.old_asyncgen_hooks);

    // python_c.py_decref_and_set_null(&py_loop.exception_handler);

    return 0;
}

pub fn loop_traverse(self: ?*LoopObject, visit: python_c.visitproc, arg: ?*anyopaque) callconv(.C) c_int {
    return python_c.py_visit(self.?, visit, arg);
}

pub fn loop_dealloc(self: ?*LoopObject) callconv(.C) void {
    const instance = self.?;

    python_c.PyObject_GC_UnTrack(instance);
    _ = loop_clear(instance);

    const @"type": *python_c.PyTypeObject = python_c.get_type(@ptrCast(instance));
    @"type".tp_free.?(@ptrCast(instance));

    python_c.py_decref(@ptrCast(@"type"));
}

inline fn z_loop_init(
    self: *LoopObject, args: ?PyObject, kwargs: ?PyObject
) !c_int {
    var kwlist: [3][*c]u8 = undefined;
    kwlist[0] = @constCast("ready_tasks_queue_min_bytes_capacity\x00");
    kwlist[1] = @constCast("exception_handler\x00");
    kwlist[2] = null;

    var ready_tasks_queue_min_bytes_capacity: u64 = 0;
    var exception_handler: ?PyObject = null;

    if (python_c.PyArg_ParseTupleAndKeywords(
            args, kwargs, "KO\x00", @ptrCast(&kwlist), &ready_tasks_queue_min_bytes_capacity,
            &exception_handler
    ) < 0) {
        return error.PythonError;
    }

    if (python_c.PyCallable_Check(exception_handler.?) < 0) {
        python_c.raise_python_runtime_error("Invalid exception handler\x00");
        return error.PythonError;
    }

    self.exception_handler = python_c.py_newref(exception_handler.?);
    errdefer python_c.py_decref(exception_handler.?);

    const allocator = utils.gpa.allocator();
    const loop_data = utils.get_data_ptr(Loop, self);
    try loop_data.init(allocator, @intCast(ready_tasks_queue_min_bytes_capacity));

    return 0;
}

pub fn loop_init(
    self: ?*LoopObject, args: ?PyObject, kwargs: ?PyObject
) callconv(.C) c_int {
    return utils.execute_zig_function(z_loop_init, .{self.?, args, kwargs});
}

