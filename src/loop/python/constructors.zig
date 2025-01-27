const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const python_imports = @import("../../utils/python_imports.zig");

const utils = @import("../../utils/utils.zig");

const Loop = @import("../main.zig");
const LoopObject = Loop.Python.LoopObject;

const std = @import("std");

inline fn z_loop_new(
    @"type": *python_c.PyTypeObject, _: ?PyObject,
    _: ?PyObject
) !*LoopObject {
    const instance: *LoopObject = @ptrCast(@"type".tp_alloc.?(@"type", 0) orelse return error.PythonError);
    errdefer @"type".tp_free.?(instance);

    @memset(&instance.data, 0);

    instance.get_asyncgen_hooks = python_c.py_newref(python_imports.get_asyncgen_hooks.?);
    instance.set_asyncgen_hooks = python_c.py_newref(python_imports.set_asyncgen_hooks.?);

    instance.asyncio_module = python_c.py_newref(python_imports.asyncio_module.?);
    instance.cancelled_error_exc = python_c.py_newref(python_imports.cancelled_error_exc.?);
    instance.invalid_state_exc = python_c.py_newref(python_imports.invalid_state_exc.?);

    instance.set_running_loop = python_c.py_newref(python_imports.set_running_loop.?);

    instance.enter_task_func = python_c.py_newref(python_imports.enter_task_func.?);
    instance.leave_task_func = python_c.py_newref(python_imports.leave_task_func.?);
    instance.register_task_func = python_c.py_newref(python_imports.register_task_func.?);

    instance.asyncgens_set = python_c.py_newref(python_imports.weakref_set.?);
    instance.asyncgens_set_add = python_c.py_newref(python_imports.weakref_add.?);
    instance.asyncgens_set_discard = python_c.py_newref(python_imports.weakref_discard.?);

    instance.old_asyncgen_hooks = null;

    return instance;
}

pub fn loop_new(
    @"type": ?*python_c.PyTypeObject, args: ?PyObject,
    kwargs: ?PyObject
) callconv(.C) ?PyObject {
    const self = utils.execute_zig_function(
        z_loop_new, .{@"type".?, args, kwargs}
    );
    return @ptrCast(self);
}

pub fn loop_clear(self: ?*LoopObject) callconv(.C) c_int {
    const py_loop = self.?;
    const loop_data = utils.get_data_ptr(Loop, py_loop);
    if (loop_data.initialized) {
        loop_data.release();
    }

    python_c.py_decref_and_set_null(&py_loop.get_asyncgen_hooks);
    python_c.py_decref_and_set_null(&py_loop.set_asyncgen_hooks);

    python_c.py_decref_and_set_null(&py_loop.asyncio_module);
    python_c.py_decref_and_set_null(&py_loop.invalid_state_exc);
    python_c.py_decref_and_set_null(&py_loop.cancelled_error_exc);

    python_c.py_decref_and_set_null(&py_loop.set_running_loop);

    python_c.py_decref_and_set_null(&py_loop.enter_task_func);
    python_c.py_decref_and_set_null(&py_loop.leave_task_func);

    python_c.py_decref_and_set_null(&py_loop.exception_handler);

    python_c.py_decref_and_set_null(&py_loop.asyncgens_set);
    python_c.py_decref_and_set_null(&py_loop.asyncgens_set_add);
    python_c.py_decref_and_set_null(&py_loop.asyncgens_set_discard);

    python_c.py_decref_and_set_null(&py_loop.old_asyncgen_hooks);

    return 0;
}

pub fn loop_traverse(self: ?*LoopObject, visit: python_c.visitproc, arg: ?*anyopaque) callconv(.C) c_int {
    const instance = self.?;
    return python_c.py_visit(
        &[_]?*python_c.PyObject{
            instance.get_asyncgen_hooks,
            instance.set_asyncgen_hooks,
            instance.asyncio_module,
            instance.invalid_state_exc,
            instance.cancelled_error_exc,
            instance.set_running_loop,
            instance.enter_task_func,
            instance.leave_task_func,
            instance.exception_handler,
            instance.asyncgens_set,
            instance.asyncgens_set_add,
            instance.asyncgens_set_discard,
            instance.old_asyncgen_hooks
        }, visit, arg
    );
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
    var kwlist: [4][*c]u8 = undefined;
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

