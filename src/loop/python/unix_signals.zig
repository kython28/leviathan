const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../utils/utils.zig");

const CallbackManager = @import("../../callback_manager.zig");
const Handle = @import("../../handle.zig");
const Loop = @import("../main.zig");
const LoopObject = Loop.Python.LoopObject;

const Scheduling = @import("scheduling.zig");

const std = @import("std");

inline fn z_loop_add_signal_handler(
    self: *LoopObject, args: []?PyObject
) !PyObject {
    if (args.len < 2) {
        python_c.raise_python_value_error("Invalid number of arguments\x00");
        return error.PythonError;
    }
    const loop_data = utils.get_data_ptr(Loop, self);

    const py_sig: PyObject = args[0].?;
    if (python_c.long_check(py_sig)) {
        python_c.raise_python_runtime_error("Invalid signal\x00");
        return error.PythonError;
    }

    const sig = python_c.PyLong_AsLong(py_sig);
    if (sig < 0) {
        python_c.raise_python_value_error("Invalid signal\x00");
        return error.PythonError;
    }

    const context: PyObject = python_c.PyContext_CopyCurrent()
        orelse return error.PythonError;
    errdefer python_c.py_decref(context);

    const allocator = loop_data.allocator;
    const callback_info = try Scheduling.get_callback_info(allocator, args[2..]);
    errdefer {
        if (callback_info) |_args| {
            for (_args) |arg| {
                python_c.py_decref(@ptrCast(arg));
            }
            allocator.free(_args);
        }
    }
    const py_handle: *Handle.PythonHandleObject = try Handle.fast_new_handle(context, loop_data);
    errdefer python_c.py_decref(@ptrCast(py_handle));

    const py_callback = python_c.py_newref(args[1].?);
    errdefer python_c.py_decref(py_callback);

    if (python_c.PyCallable_Check(py_callback) < 0) {
        python_c.raise_python_runtime_error("Invalid callback\x00");
        return error.PythonError;
    }

    const mutex = &loop_data.mutex;
    mutex.lock();
    defer mutex.unlock();
    if (!loop_data.initialized) {
        python_c.raise_python_runtime_error("Loop is closed\x00");
        return error.PythonError;
    }

    if (loop_data.stopping) {
        python_c.raise_python_runtime_error("Loop is stopping\x00");
        return error.PythonError;
    }

    const callback: CallbackManager.Callback = .{
        .PythonGeneric = .{
            .args = callback_info,
            .exception_handler = self.exception_handler.?,
            .py_callback = py_callback,
            .py_context = context,
            .py_handle = py_handle,
            .cancelled = &py_handle.cancelled,
            .can_release = false
        }
    };

    try loop_data.unix_signals.link(@intCast(sig), callback);

    return python_c.get_py_none();
}

pub fn loop_add_signal_handler(
    self: ?*LoopObject, args: ?[*]?PyObject, nargs: isize
) callconv(.C) ?PyObject {
    return utils.execute_zig_function(z_loop_add_signal_handler, .{
        self.?, args.?[0..@as(usize, @intCast(nargs))]
    });
}

pub fn loop_remove_signal_handler(
    self: ?*LoopObject, py_sig: ?PyObject
) callconv(.C) ?PyObject {
    if (python_c.long_check(py_sig.?)) {
        python_c.raise_python_type_error("Invalid signal\x00");
        return null;
    }

    const sig = python_c.PyLong_AsUnsignedLong(py_sig.?);

    const loop_data = utils.get_data_ptr(Loop, self.?);
    const mutex = &loop_data.mutex;
    mutex.lock();
    defer mutex.unlock();

    loop_data.unix_signals.unlink(@intCast(sig)) catch |err| {
        if (err == error.KeyNotFound) {
            return python_c.get_py_false();
        }
        return utils.handle_zig_function_error(err, null);
    };

    return python_c.get_py_true();
}
