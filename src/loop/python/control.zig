const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("utils");

const Loop = @import("../main.zig");
const LoopObject = Loop.Python.LoopObject;

const Hooks = @import("hooks.zig");

const CallbackManager = @import("callback_manager");

const std = @import("std");

inline fn z_loop_run_forever(self: *LoopObject) !PyObject {
    const loop_data = utils.get_data_ptr(Loop, self);

    try Hooks.setup_asyncgen_hooks(self);

    const set_running_loop = utils.PythonImports.set_running_loop;
    if (python_c.PyObject_CallOneArg(set_running_loop, @ptrCast(self))) |v| {
        python_c.py_decref(v);
    }else{
        const exc = python_c.PyErr_GetRaisedException();
        Hooks.cleanup_asyncgen_hooks(self);
        python_c.PyErr_SetRaisedException(exc);
        return error.PythonError;
    }

    var py_exception: ?PyObject = null;
    Loop.Runner.start(loop_data, self.exception_handler.?) catch |err| {
        utils.handle_zig_function_error(err, {});
        py_exception = python_c.PyErr_GetRaisedException() orelse unreachable;
    };

    if (python_c.PyObject_CallOneArg(set_running_loop, python_c.get_py_none_without_incref())) |v| {
        python_c.py_decref(v);
    }else{
        const py_exc = python_c.PyErr_GetRaisedException() orelse unreachable;
        if (py_exception) |v| {
            python_c.PyException_SetCause(py_exc, v);
        }

        py_exception = py_exc;
    }

    Hooks.cleanup_asyncgen_hooks(self);
    if (py_exception) |v| {
        python_c.PyErr_SetRaisedException(v);
        return error.PythonError;
    }

    return python_c.get_py_none();
}

pub fn loop_run_forever(self: ?*LoopObject, _: ?PyObject) callconv(.C) ?PyObject {
    return utils.execute_zig_function(z_loop_run_forever, .{self.?});
}

pub fn loop_stop(self: ?*LoopObject, _: ?PyObject) callconv(.C) ?PyObject {
    const loop_data = utils.get_data_ptr(Loop, self.?);

    const mutex = &loop_data.mutex;
    mutex.lock();
    defer mutex.unlock();

    loop_data.stopping = true;
    return python_c.get_py_none();
}

pub fn loop_is_running(self: ?*LoopObject, _: ?PyObject) callconv(.C) ?PyObject {
    const loop_data = utils.get_data_ptr(Loop, self.?);
    const mutex = &loop_data.mutex;
    mutex.lock();
    defer mutex.unlock();

    return python_c.PyBool_FromLong(@intCast(@intFromBool(loop_data.running)));
}

pub fn loop_is_closed(self: ?*LoopObject, _: ?PyObject) callconv(.C) ?PyObject {
    const loop_data = utils.get_data_ptr(Loop, self.?);

    const mutex = &loop_data.mutex;
    mutex.lock();
    defer mutex.unlock();

    return python_c.PyBool_FromLong(@intCast(@intFromBool(!loop_data.initialized)));
}

pub fn loop_close(self: ?*LoopObject, _: ?PyObject) callconv(.C) ?PyObject {
    const instance = self.?;

    const loop_data = utils.get_data_ptr(Loop, instance);

    {
        const mutex = &loop_data.mutex;
        mutex.lock();
        defer mutex.unlock();

        if (loop_data.running) {
            python_c.raise_python_runtime_error("Loop is running\x00");
            return null;
        }
    }

    loop_data.release();
    return python_c.get_py_none();
}
