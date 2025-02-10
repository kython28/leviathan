const Future = @import("../main.zig");
const Loop = @import("../../loop/main.zig");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

pub const Constructors = @import("constructors.zig");
pub const Result = @import("result.zig");
pub const Cancel = @import("cancel.zig");
const Callbacks = @import("callbacks.zig");

const PythonFutureMethods: []const python_c.PyMethodDef = &[_]python_c.PyMethodDef{
    python_c.PyMethodDef{
        .ml_name = "result\x00",
        .ml_meth = @ptrCast(&Result.future_result),
        .ml_doc = "Return the result of the Future\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "set_result\x00",
        .ml_meth = @ptrCast(&Result.future_set_result),
        .ml_doc = "Mark the Future as done and set its result.\x00",
        .ml_flags = python_c.METH_O
    },
    python_c.PyMethodDef{
        .ml_name = "exception\x00",
        .ml_meth = @ptrCast(&Result.future_exception),
        .ml_doc = "Return the exception raised by the Future\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "set_exception\x00",
        .ml_meth = @ptrCast(&Result.future_set_exception),
        .ml_doc = "Mark the Future as done and set its exception.\x00",
        .ml_flags = python_c.METH_O
    },
    python_c.PyMethodDef{
        .ml_name = "cancel\x00",
        .ml_meth = @ptrCast(&Cancel.future_cancel),
        .ml_doc = "Cancel the Future and schedule callbacks.\x00",
        .ml_flags = python_c.METH_FASTCALL | python_c.METH_KEYWORDS
    },
    python_c.PyMethodDef{
        .ml_name = "cancelled\x00",
        .ml_meth = @ptrCast(&Cancel.future_cancelled),
        .ml_doc = "Return True if the Future was cancelled.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "done\x00",
        .ml_meth = @ptrCast(&Result.future_done),
        .ml_doc = "Return True if the Future is done.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "add_done_callback\x00",
        .ml_meth = @ptrCast(&Callbacks.future_add_done_callback),
        .ml_doc = "Add a callback to be run when the Future is done.\x00",
        .ml_flags = python_c.METH_FASTCALL | python_c.METH_KEYWORDS
    },
    python_c.PyMethodDef{
        .ml_name = "remove_done_callback\x00",
        .ml_meth = @ptrCast(&Callbacks.future_remove_done_callback),
        .ml_doc = "Remove callback from the callbacks list.\x00",
        .ml_flags = python_c.METH_O
    },
    python_c.PyMethodDef{
        .ml_name = "get_loop\x00",
        .ml_meth = @ptrCast(&Constructors.future_get_loop),
        .ml_doc = "Return the event loop.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = null, .ml_meth = null, .ml_doc = null, .ml_flags = 0
    }
};

pub const FutureObject = extern struct {
    ob_base: python_c.PyObject,
    data: [@sizeOf(Future)]u8,

    py_loop: ?PyObject,
    exception: ?PyObject,
    exception_tb: ?PyObject,

    cancel_msg_py_object: ?PyObject,
    blocking: u64,
    log_destroy_pending: u64
};

const PythonFutureMembers: []const python_c.PyMemberDef = &[_]python_c.PyMemberDef{
    python_c.PyMemberDef{ // Just for be supported by asyncio.isfuture
        .name = "_asyncio_future_blocking\x00",
        .type = python_c.Py_T_BOOL,
        .offset = @offsetOf(FutureObject, "blocking"),
        .doc = null,
    },
    python_c.PyMemberDef{ // Just for be supported by asyncio.gather
        .name = "_log_destroy_pending\x00", // This doesn't do anything
        .type = python_c.Py_T_BOOL,
        .offset = @offsetOf(FutureObject, "log_destroy_pending"),
        .doc = null,
    },
    python_c.PyMemberDef{ // Just for be supported by asyncio.gather
        .name = "_cancel_message\x00",
        .type = python_c.Py_T_OBJECT_EX,
        .offset = @offsetOf(FutureObject, "cancel_msg_py_object"),
        .doc = null,
    },
    python_c.PyMemberDef{
        .name = null, .flags = 0, .offset = 0, .doc = null
    }
};

const PythonFutureAsyncMethods = python_c.PyAsyncMethods{
    .am_await = @ptrCast(&Constructors.future_iter),
};

pub var FutureType = python_c.PyTypeObject{
    .tp_name = "leviathan.Future\x00",
    .tp_doc = "Leviathan's future class\x00",
    .tp_basicsize = @sizeOf(FutureObject),
    .tp_itemsize = 0,
    .tp_flags = python_c.Py_TPFLAGS_DEFAULT | python_c.Py_TPFLAGS_BASETYPE | python_c.Py_TPFLAGS_HAVE_GC,
    .tp_new = &Constructors.future_new,
    .tp_init = @ptrCast(&Constructors.future_init),
    .tp_traverse = @ptrCast(&Constructors.future_traverse),
    .tp_clear = @ptrCast(&Constructors.future_clear),
    .tp_dealloc = @ptrCast(&Constructors.future_dealloc),
    .tp_iter = @ptrCast(&Constructors.future_iter),
    .tp_iternext = @ptrCast(&Constructors.future_iternext),
    .tp_as_async = @constCast(&PythonFutureAsyncMethods),
    .tp_methods = @constCast(PythonFutureMethods.ptr),
    .tp_members = @constCast(PythonFutureMembers.ptr),
};
