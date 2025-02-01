const std = @import("std");

const Loop = @import("../main.zig");

const utils = @import("../../utils/main.zig");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Constructors = @import("constructors.zig");
const Scheduling = @import("scheduling.zig");
const Control = @import("control.zig");
const Utils = @import("utils/main.zig");
const UnixSignal = @import("unix_signals.zig");
const Watchers = @import("io/watchers.zig");
pub const Hooks = @import("hooks.zig");

const PythonLoopMethods: []const python_c.PyMethodDef = &[_]python_c.PyMethodDef{
    // --------------------- Control ---------------------
    python_c.PyMethodDef{
        .ml_name = "run_forever\x00",
        .ml_meth = @ptrCast(&Control.loop_run_forever),
        .ml_doc = "Run the event loop forever.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "stop\x00",
        .ml_meth = @ptrCast(&Control.loop_stop),
        .ml_doc = "Stop the event loop.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "is_running\x00",
        .ml_meth = @ptrCast(&Control.loop_is_running),
        .ml_doc = "Return True if the event loop is currently running.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "is_closed\x00",
        .ml_meth = @ptrCast(&Control.loop_is_closed),
        .ml_doc = "Return True if the event loop was closed.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "close\x00",
        .ml_meth = @ptrCast(&Control.loop_close),
        .ml_doc = "Close the event loop\x00",
        .ml_flags = python_c.METH_NOARGS
    },

    // --------------------- Sheduling ---------------------
    python_c.PyMethodDef{
        .ml_name = "call_soon\x00",
        .ml_meth = @ptrCast(&Scheduling.loop_call_soon),
        .ml_doc = "Schedule callback to be called with args arguments at the next iteration of the event loop.\x00",
        .ml_flags = python_c.METH_FASTCALL | python_c.METH_KEYWORDS
    },
    python_c.PyMethodDef{
        .ml_name = "call_soon_threadsafe\x00",
        .ml_meth = @ptrCast(&Scheduling.loop_call_soon_threadsafe),
        .ml_doc = "Thread-safe variant of `call_soon`.\x00",
        .ml_flags = python_c.METH_FASTCALL | python_c.METH_KEYWORDS
    },
    python_c.PyMethodDef{
        .ml_name = "call_later\x00",
        .ml_meth = @ptrCast(&Scheduling.loop_call_later),
        .ml_doc = "Thread-safe variant of `call_soon`.\x00",
        .ml_flags = python_c.METH_FASTCALL | python_c.METH_KEYWORDS
    },
    python_c.PyMethodDef{
        .ml_name = "call_at\x00",
        .ml_meth = @ptrCast(&Scheduling.loop_call_at),
        .ml_doc = "Thread-safe variant of `call_soon`.\x00",
        .ml_flags = python_c.METH_FASTCALL | python_c.METH_KEYWORDS
    },

    // --------------------- Utils ---------------------
    python_c.PyMethodDef{
        .ml_name = "time\x00",
        .ml_meth = @ptrCast(&Utils.Time.loop_time),
        .ml_doc = "Return the current time, as a float value, according to the event loop’s internal monotonic clock.\x00",
        .ml_flags = python_c.METH_NOARGS
    },

    python_c.PyMethodDef{
        .ml_name = "create_future\x00",
        .ml_meth = @ptrCast(&Utils.Future.loop_create_future),
        .ml_doc = "Schedule callback to be called with args arguments at the next iteration of the event loop.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "create_task\x00",
        .ml_meth = @ptrCast(&Utils.Task.loop_create_task),
        .ml_doc = "Schedule callback to be called with args arguments at the next iteration of the event loop.\x00",
        .ml_flags = python_c.METH_FASTCALL | python_c.METH_KEYWORDS
    },


    python_c.PyMethodDef{
        .ml_name = "add_signal_handler\x00",
        .ml_meth = @ptrCast(&UnixSignal.loop_add_signal_handler),
        .ml_doc = "Schedule callback to be called with args arguments at the next iteration of the event loop.\x00",
        .ml_flags = python_c.METH_FASTCALL
    },
    python_c.PyMethodDef{
        .ml_name = "remove_signal_handler\x00",
        .ml_meth = @ptrCast(&UnixSignal.loop_remove_signal_handler),
        .ml_doc = "Schedule callback to be called with args arguments at the next iteration of the event loop.\x00",
        .ml_flags = python_c.METH_O
    },

    // --------------------- Watchers ---------------------
    python_c.PyMethodDef{
        .ml_name = "add_reader\x00",
        .ml_meth = @ptrCast(&Watchers.loop_add_reader),
        .ml_doc = "Start monitoring the fd file descriptor for read availability\x00",
        .ml_flags = python_c.METH_FASTCALL
    },
    python_c.PyMethodDef{
        .ml_name = "add_writer\x00",
        .ml_meth = @ptrCast(&Watchers.loop_add_writer),
        .ml_doc = "Start monitoring the fd file descriptor for write availability\x00",
        .ml_flags = python_c.METH_FASTCALL
    },

    python_c.PyMethodDef{
        .ml_name = "remove_reader\x00",
        .ml_meth = @ptrCast(&Watchers.loop_remove_reader),
        .ml_doc = "Stop monitoring the fd file descriptor for read availability\x00",
        .ml_flags = python_c.METH_O
    },
    python_c.PyMethodDef{
        .ml_name = "remove_writer\x00",
        .ml_meth = @ptrCast(&Watchers.loop_remove_writer),
        .ml_doc = "Stop monitoring the fd file descriptor for write availability\x00",
        .ml_flags = python_c.METH_O
    },
    // --------------------- Sentinel ---------------------
    python_c.PyMethodDef{
        .ml_name = null, .ml_meth = null, .ml_doc = null, .ml_flags = 0
    }
};


const LoopMembers: []const python_c.PyMemberDef = &[_]python_c.PyMemberDef{
    python_c.PyMemberDef{ // Just for be supported by asyncio.isfuture
        .name = "_asyncgens\x00",
        .type = python_c.Py_T_OBJECT_EX,
        .offset = @offsetOf(LoopObject, "asyncgens_set"),
        .doc = null,
    },
    python_c.PyMemberDef{
        .name = null, .flags = 0, .offset = 0, .doc = null
    }
};

pub const LoopObject = extern struct {
    ob_base: python_c.PyObject,
    data: [@sizeOf(Loop)]u8,

    asyncgens_set: ?PyObject,
    asyncgens_set_add: ?PyObject,
    asyncgens_set_discard: ?PyObject,
    old_asyncgen_hooks: ?PyObject,

    exception_handler: ?PyObject,
    task_name_counter: u64,
};

const loop_slots = [_]python_c.PyType_Slot{
    .{ .slot = python_c.Py_tp_doc, .pfunc = @constCast("Leviathan's loop class\x00") },
    .{ .slot = python_c.Py_tp_new, .pfunc = @constCast(&Constructors.loop_new) },
    .{ .slot = python_c.Py_tp_traverse, .pfunc = @constCast(&Constructors.loop_traverse) },
    .{ .slot = python_c.Py_tp_clear, .pfunc = @constCast(&Constructors.loop_clear) },
    .{ .slot = python_c.Py_tp_init, .pfunc = @constCast(&Constructors.loop_init) },
    .{ .slot = python_c.Py_tp_dealloc, .pfunc = @constCast(&Constructors.loop_dealloc) },
    .{ .slot = python_c.Py_tp_methods, .pfunc = @constCast(PythonLoopMethods.ptr) },
    .{ .slot = python_c.Py_tp_members, .pfunc = @constCast(LoopMembers.ptr) },
    .{ .slot = 0, .pfunc = null },
};

const loop_spec = python_c.PyType_Spec{
    .name = "leviathan.Loop\x00",
    .basicsize = @sizeOf(LoopObject),
    .itemsize = 0,
    .flags = python_c.Py_TPFLAGS_DEFAULT | python_c.Py_TPFLAGS_BASETYPE | python_c.Py_TPFLAGS_HAVE_GC,
    .slots = @constCast(&loop_slots),
};

pub var LoopType: *python_c.PyTypeObject = undefined;

pub fn create_type() !void {
    const type_obj = python_c.PyType_FromSpecWithBases(@constCast(&loop_spec), utils.PythonImports.base_event_loop)
        orelse return error.PythonError;
    LoopType = @ptrCast(type_obj);
}

