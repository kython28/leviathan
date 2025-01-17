const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../utils/utils.zig");

const Loop = @import("../main.zig");
const Task = @import("../../task/main.zig");

const LoopObject = Loop.Python.LoopObject;

const std = @import("std");
const builtin = @import("builtin");

pub fn asyncgen_firstiter_hook(
    self: ?*LoopObject, agen: ?PyObject
) callconv(.C) ?PyObject {
    const instance = self.?;

    const ret: ?PyObject = python_c.PyObject_CallOneArg(instance.asyncgens_set_add.?, agen.?);
    return ret;
}

inline fn append_new_task(
    self: *LoopObject, agen: PyObject
) !PyObject {
    const loop_data = utils.get_data_ptr(Loop, self);
    if (!loop_data.initialized) {
        python_c.raise_python_runtime_error("Loop is closed\x00");
        return error.PythonError;
    }

    const aclose: PyObject = python_c.PyObject_GetAttrString(agen, "aclose\x00")
        orelse return error.PythonError;
    errdefer python_c.py_decref(aclose);

    const context: PyObject = python_c.PyContext_CopyCurrent()
        orelse return error.PythonError;
    errdefer python_c.py_decref(context);

    const task = try Task.Constructors.fast_new_task(self, aclose, context, null);
    python_c.py_decref(@ptrCast(task));

    return python_c.get_py_none();
}

pub fn asyncgen_finalizer_hook(
    self: ?*LoopObject, agen: ?PyObject
) callconv(.C) ?PyObject {
    const instance = self.?;
    const _agen = agen.?;

    const discard_ret: PyObject = python_c.PyObject_CallOneArg(instance.asyncgens_set_discard.?, _agen)
        orelse return null;
    python_c.py_decref(discard_ret);

    if (builtin.single_threaded) {
        const thread_id = std.Thread.getCurrentId();
        if (thread_id != instance.thread_id) {
            python_c.raise_python_runtime_error(
                "Event loop is not thread-safe. Only one thread can be used at the same time.\x00"
            );
            return null;
        }
    }

    return utils.execute_zig_function(append_new_task, .{instance, _agen});
}

const LoopAsyncGenFirstIterHookMethod = python_c.PyMethodDef{
    .ml_name = "_asyncgen_firstiter_hook\x00",
    .ml_meth = @ptrCast(&asyncgen_firstiter_hook),
    .ml_doc = "Hook called when the first iterator is created\x00",
    .ml_flags = python_c.METH_O
};

const LoopAsyncGenFinalizerHookMethod = python_c.PyMethodDef{
    .ml_name = "_asyncgen_finalizer_hook\x00",
    .ml_meth = @ptrCast(&asyncgen_finalizer_hook),
    .ml_doc = "Hook called when the iterator is finalized\x00",
    .ml_flags = python_c.METH_O
};

pub fn setup_asyncgen_hooks(self: *LoopObject) !void {
    if (self.old_asyncgen_hooks != null) {
        @panic("Asyncgen hooks already set\x00");
    }

    self.old_asyncgen_hooks = python_c.PyObject_CallNoArgs(self.get_asyncgen_hooks.?)
        orelse return error.PythonError;

    var args: [2]PyObject = undefined;
    args[0] = python_c.PyCFunction_New(
        @constCast(&LoopAsyncGenFirstIterHookMethod), @ptrCast(self)
    ) orelse return error.PythonError;

    args[1] =  python_c.PyCFunction_New(
        @constCast(&LoopAsyncGenFinalizerHookMethod), @ptrCast(self)
    ) orelse return error.PythonError;

    const ret: PyObject = python_c.PyObject_Vectorcall(
        self.set_asyncgen_hooks.?, &args, args.len, null
    ) orelse return error.PythonError;
    python_c.py_decref(ret);
}

pub fn cleanup_asyncgen_hooks(self: *LoopObject) void {
    const ret: PyObject = python_c.PyObject_CallObject(self.set_asyncgen_hooks.?, self.old_asyncgen_hooks.?)
        orelse return;
    python_c.py_decref(ret);
    python_c.py_decref_and_set_null(&self.old_asyncgen_hooks);
}
