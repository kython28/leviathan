const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../utils/utils.zig");
const Future = @import("../future/main.zig");
const Task = @import("main.zig");
const Loop = @import("../loop/main.zig");

const std = @import("std");


pub fn task_not_implemented_method(
    _: ?*Task.PythonTaskObject, _: ?PyObject, _: ?PyObject
) callconv(.C) ?PyObject {
    python_c.PyErr_SetString(python_c.PyExc_NotImplementedError, "This method is not supported for tasks\x00");
    return null;
}

pub fn task_get_coro(self: ?*Task.PythonTaskObject) callconv(.C) ?PyObject {
    return python_c.py_newref(self.?.coro);
}

pub fn task_get_context(self: ?*Task.PythonTaskObject) callconv(.C) ?PyObject {
    return python_c.py_newref(self.?.py_context);
}

pub fn task_get_name(self: ?*Task.PythonTaskObject) callconv(.C) ?PyObject {
    const instance = self.?;
    if (instance.name) |name| {
        return python_c.py_newref(name);
    }

    const loop = instance.fut.py_loop.?;
    const loop_data = utils.get_data_ptr(Loop, loop);
    const allocator = loop_data.allocator;
    
    const task_id = @atomicRmw(u64, &loop.task_name_counter, .Add, 1, .monotonic);
    const random_str = std.fmt.allocPrint(allocator, "Leviathan.Task_{x:0>16}\x00", .{task_id}) catch |err| {
        return utils.handle_zig_function_error(err, null);
    };
    defer allocator.free(random_str);

    const py_name: PyObject = python_c.PyUnicode_FromStringAndSize(random_str.ptr, @intCast(random_str.len))
        orelse return null;
    instance.name = py_name;

    return python_c.py_newref(py_name);
}

pub fn task_set_name(self: ?*Task.PythonTaskObject, args: ?PyObject) callconv(.C) ?PyObject {
    const instance = self.?;

    var name: ?PyObject = null;
    if (python_c.PyArg_ParseTuple(args, "O\x00", &name) < 0) {
        return null;
    }

    const future_data = utils.get_data_ptr(Future, &instance.fut);
    const mutex = &future_data.mutex;
    mutex.lock();
    defer mutex.unlock();

    instance.name = python_c.PyObject_Str(name.?) orelse return null;
    return python_c.get_py_none();
}

pub fn task_get_stack(self: ?*Task.PythonTaskObject, args: ?PyObject, kwargs: ?PyObject) callconv(.C) ?PyObject {
    const instance = self.?;

    var kwlist: [2][*c]u8 = undefined;
    kwlist[0] = @constCast("limit\x00");
    kwlist[1] = null;

    var limit: ?PyObject = python_c.get_py_none();

    if (python_c.PyArg_ParseTupleAndKeywords(args, kwargs, "|$O\x00", @ptrCast(&kwlist), &limit) < 0) {
        return null;
    }

    const asyncio_module = instance.fut.asyncio_module.?;
    
    const base_tasks_module: PyObject = python_c.PyObject_GetAttrString(asyncio_module, "base_tasks\x00")
        orelse return null;
    defer python_c.py_decref(base_tasks_module);

    const get_stack_func: PyObject = python_c.PyObject_GetAttrString(base_tasks_module, "_task_get_stack\x00")
        orelse return null;
    defer python_c.py_decref(get_stack_func);

    const stack: PyObject = python_c.PyObject_CallFunctionObjArgs(get_stack_func, instance, limit, @as(?PyObject, null))
        orelse return null;

    return stack;
}

pub fn task_print_stack(self: ?*Task.PythonTaskObject, args: ?PyObject, kwargs: ?PyObject) callconv(.C) ?PyObject {
    const instance = self.?;

    var kwlist: [3][*c]u8 = undefined;
    kwlist[0] = @constCast("limit\x00");
    kwlist[1] = @constCast("file\x00");
    kwlist[2] = null;

    var limit: ?PyObject = python_c.get_py_none();
    var file: ?PyObject = python_c.get_py_none();

    if (python_c.PyArg_ParseTupleAndKeywords(args, kwargs, "|$OO\x00", @ptrCast(&kwlist), &limit, &file) < 0) {
        return null;
    }

    const asyncio_module = instance.fut.asyncio_module.?;
    
    const base_tasks_module: PyObject = python_c.PyObject_GetAttrString(asyncio_module, "base_tasks\x00")
        orelse return null;
    defer python_c.py_decref(base_tasks_module);

    const print_stack_func: PyObject = python_c.PyObject_GetAttrString(base_tasks_module, "_task_print_stack\x00")
        orelse return null;
    defer python_c.py_decref(print_stack_func);

    const result: ?PyObject = python_c.PyObject_CallFunctionObjArgs(
        print_stack_func, instance, limit, file, @as(?PyObject, null)
    );
    return result;
}
