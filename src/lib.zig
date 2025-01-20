const std = @import("std");
const builtin = @import("builtin");

const python_c = @import("python_c");
const leviathan = @import("leviathan");

const utils = leviathan.utils.utils;
const future = leviathan.Future;
const task = leviathan.Task;
const loop = leviathan.Loop;
const handle = leviathan.Handle;
const timer_handle = leviathan.TimerHandle;

const leviathan_types = .{
    &future.Python.FutureType,
    &task.PythonTaskType,
    &loop.Python.LoopType,
    &handle.PythonHandleType,
    &timer_handle.PythonTimerHandleType
};

fn on_module_exit() callconv(.C) void {
    _ = utils.gpa.deinit();
}

var leviathan_module = python_c.PyModuleDef{
    .m_name = "leviathan_zig\x00",
    .m_doc = "Leviathan: A lightning-fast Zig-powered event loop for Python's asyncio.\x00",
    .m_size = -1,
};

fn initialize_leviathan_types() !void {
    inline for (leviathan_types) |v| {
        if (python_c.PyType_Ready(v) < 0) {
            return error.PythonError;
        }
    }
}

fn deinitialize_leviathan_types() void {
    inline for (leviathan_types) |v| {
        python_c.py_decref(@ptrCast(v));
    }
}

fn initialize_python_module() !*python_c.PyObject {
    const module: *python_c.PyObject = python_c.PyModule_Create(&leviathan_module) orelse return error.PythonError;
    errdefer python_c.py_decref(module);

    if (!builtin.single_threaded) {
        if (python_c.PyUnstable_Module_SetGIL(module, python_c.Py_MOD_GIL_NOT_USED) < 0) {
            return error.PythonError;
        }
    }

    const leviathan_modules_name = .{
        "Future\x00",
        "Task\x00",
        "Loop\x00",
        "Handle\x00",
        "TimerHandle\x00"
    };

    inline for (leviathan_modules_name, leviathan_types) |leviathan_module_name, leviathan_module_obj| {
        if (
            python_c.PyModule_AddObject(
                module, leviathan_module_name, @as(*python_c.PyObject, @ptrCast(leviathan_module_obj))
            ) < 0
        ) {
            return error.PythonError;
        }
    }

    if (python_c.Py_AtExit(&on_module_exit) < 0) {
        return error.PythonError;
    }

    return module;
}

export fn PyInit_leviathan_zig() ?*python_c.PyObject {
    initialize_leviathan_types() catch return null;
    return initialize_python_module() catch return null;
} 
