const std = @import("std");
const builtin = @import("builtin");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Handle = @import("handle.zig");
const utils = @import("utils/utils.zig");


pub const PythonTimerHandleObject = extern struct {
    handle: Handle.PythonHandleObject,
    when: std.posix.timespec
};

pub inline fn fast_new_timer_handle(time: std.posix.timespec, contextvars: PyObject) !*PythonTimerHandleObject {
    const instance: *PythonTimerHandleObject = @ptrCast(
        PythonTimerHandleType.tp_alloc.?(&PythonTimerHandleType, 0) orelse return error.PythonError
    );
    instance.handle.contextvars = contextvars;
    instance.handle.cancelled = false;
    instance.when = time;

    return instance;
}

inline fn z_timer_handle_init(
    self: *PythonTimerHandleObject, args: ?PyObject, kwargs: ?PyObject
) !c_int {
    var kwlist: [3][*c]u8 = undefined;
    kwlist[0] = @constCast("ts\x00");
    kwlist[1] = @constCast("context\x00");
    kwlist[2] = null;

    var ts: f64 = 0.0;
    var py_context: ?PyObject = null;

    if (python_c.PyArg_ParseTupleAndKeywords(
            args, kwargs, "dO\x00", @ptrCast(&kwlist), &ts, &py_context
    ) < 0) {
        return error.PythonError;
    }

    if (py_context) |ctx| {
        if (python_c.is_none(ctx)) {
            python_c.raise_python_type_error("context cannot be None\x00");
            return error.PythonError;
        }
    }

    self.handle.contextvars = python_c.py_newref(py_context.?);

    const ts_sec = @trunc(ts);
    self.when = .{
        .sec = @intFromFloat(ts_sec),
        .nsec = @as(@FieldType(std.posix.timespec, "nsec"), @intFromFloat((ts - ts_sec) * std.time.ns_per_s))
    };

    return 0;
}

fn handle_init(self: ?*PythonTimerHandleObject, args: ?PyObject, kwargs: ?PyObject) callconv(.C) c_int {
    return utils.execute_zig_function(z_timer_handle_init, .{self.?, args, kwargs});
}

pub fn timer_handle_when(self: ?*PythonTimerHandleObject, _: ?PyObject) callconv(.C) ?PyObject {
    const time = self.?.when;
    const when = @as(f64, @floatFromInt(time.sec)) + @as(f64, @floatFromInt(time.nsec)) / std.time.ns_per_s;
    return python_c.PyFloat_FromDouble(when);
}

const PythonTimerHandleMethods: []const python_c.PyMethodDef = &[_]python_c.PyMethodDef{
    python_c.PyMethodDef{
        .ml_name = "when\x00",
        .ml_meth = @ptrCast(&timer_handle_when),
        .ml_doc = "Return a scheduled callback time as float seconds.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = null, .ml_meth = null, .ml_doc = null, .ml_flags = 0
    }
};

pub var PythonTimerHandleType = python_c.PyTypeObject{
    .tp_name = "leviathan.TimerHandle\x00",
    .tp_doc = "Leviathan's handle class\x00",
    .tp_base = &Handle.PythonHandleType,
    .tp_basicsize = @sizeOf(PythonTimerHandleObject),
    .tp_itemsize = 0,
    .tp_flags = python_c.Py_TPFLAGS_DEFAULT | python_c.Py_TPFLAGS_BASETYPE,
    .tp_new = &python_c.PyType_GenericNew,
    .tp_init = @ptrCast(&handle_init),
    .tp_methods = @constCast(PythonTimerHandleMethods.ptr),
    .tp_members = null
};

