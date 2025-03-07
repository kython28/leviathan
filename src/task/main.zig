const Future = @import("../future/main.zig");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

pub const Constructors = @import("constructors.zig");
const Utils = @import("utils.zig");
pub const Cancel = @import("cancel.zig");
pub const Callback = @import("callbacks.zig");

const PythonTaskMethods: []const python_c.PyMethodDef = &[_]python_c.PyMethodDef{
    python_c.PyMethodDef{
        .ml_name = "set_result\x00",
        .ml_meth = @ptrCast(&Utils.task_not_implemented_method),
        .ml_doc = "Mark the Future as done and set its result.\x00",
        .ml_flags = python_c.METH_VARARGS
    },
    python_c.PyMethodDef{
        .ml_name = "set_exception\x00",
        .ml_meth = @ptrCast(&Utils.task_not_implemented_method),
        .ml_doc = "Mark the Future as done and set its exception.\x00",
        .ml_flags = python_c.METH_VARARGS
    },
    python_c.PyMethodDef{
        .ml_name = "cancel\x00",
        .ml_meth = @ptrCast(&Cancel.task_cancel),
        .ml_doc = "Cancel the Future and schedule callbacks.\x00",
        .ml_flags = python_c.METH_VARARGS | python_c.METH_KEYWORDS
    },
    python_c.PyMethodDef{
        .ml_name = "uncancel\x00",
        .ml_meth = @ptrCast(&Cancel.task_uncancel),
        .ml_doc = "Decrement the number of pending cancellation requests to this Task\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "cancelling\x00",
        .ml_meth = @ptrCast(&Cancel.task_cancelling),
        .ml_doc = "Return the number of pending cancellation requests to this Task.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "get_coro\x00",
        .ml_meth = @ptrCast(&Utils.task_get_coro),
        .ml_doc = "Return the coroutine object wrapped by the Task.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "get_context\x00",
        .ml_meth = @ptrCast(&Utils.task_get_context),
        .ml_doc = "Return the contextvars.Context object associated with the task.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "get_name\x00",
        .ml_meth = @ptrCast(&Utils.task_get_name),
        .ml_doc = "Return the name of the task.\x00",
        .ml_flags = python_c.METH_NOARGS
    },
    python_c.PyMethodDef{
        .ml_name = "set_name\x00",
        .ml_meth = @ptrCast(&Utils.task_set_name),
        .ml_doc = "Set the name of the task\x00",
        .ml_flags = python_c.METH_VARARGS
    },
    python_c.PyMethodDef{
        .ml_name = "get_stack\x00",
        .ml_meth = @ptrCast(&Utils.task_get_stack),
        .ml_doc = "Return the list of stack frames for this Task.\x00",
        .ml_flags = python_c.METH_VARARGS | python_c.METH_KEYWORDS
    },
    python_c.PyMethodDef{
        .ml_name = "print_stack\x00",
        .ml_meth = @ptrCast(&Utils.task_print_stack),
        .ml_doc = "Print the stack or traceback for this Task.",
        .ml_flags = python_c.METH_VARARGS | python_c.METH_KEYWORDS
    },
    python_c.PyMethodDef{
        .ml_name = null, .ml_meth = null, .ml_doc = null, .ml_flags = 0
    }
};

const PythonTaskMembers: []const python_c.PyMemberDef = &[_]python_c.PyMemberDef{
    python_c.PyMemberDef{
        .name = "_coro\x00",
        .type = python_c.Py_T_OBJECT_EX,
        .offset = @offsetOf(PythonTaskObject, "coro"),
        .doc = null,
        .flags = python_c.Py_READONLY
    },
    python_c.PyMemberDef{
        .name = "_exception\x00",
        .type = python_c._Py_T_OBJECT,
        .offset = @offsetOf(Future.Python.FutureObject, "exception"),
        .doc = null,
        .flags = python_c.Py_READONLY
    },
    python_c.PyMemberDef{
        .name = "_fut_waiter\x00",
        .type = python_c._Py_T_OBJECT,
        .offset = @offsetOf(PythonTaskObject, "fut_waiter"),
        .doc = null,
        .flags = python_c.Py_READONLY
    },
    python_c.PyMemberDef{
        .name = null, .flags = 0, .offset = 0, .doc = null
    }
};

pub const ExceptionMessage: [:0]const u8 = "Error while executing coroutine";
pub const ModuleName: [:0]const u8 = "task";

pub const PythonTaskObject = extern struct {
    fut: Future.Python.FutureObject,

    py_context: ?PyObject,
    name: ?PyObject,

    coro: ?PyObject,

    wake_up_task_callback: ?PyObject,
    fut_waiter: ?PyObject,

    exception: ?PyObject,

    weakref_list: ?PyObject,

    cancel_requests: usize,
    must_cancel: bool,
};

pub var PythonTaskType = python_c.PyTypeObject{
    .tp_name = "leviathan.Task\x00",
    .tp_doc = "Leviathan's task class\x00",
    .tp_base = &Future.Python.FutureType,
    .tp_basicsize = @sizeOf(PythonTaskObject),
    .tp_itemsize = 0,
    .tp_flags = python_c.Py_TPFLAGS_DEFAULT | python_c.Py_TPFLAGS_BASETYPE | python_c.Py_TPFLAGS_HAVE_GC,
    .tp_new = &Constructors.task_new,
    .tp_init = @ptrCast(&Constructors.task_init),
    .tp_traverse = @ptrCast(&Constructors.task_traverse),
    .tp_clear = @ptrCast(&Constructors.task_clear),
    .tp_dealloc = @ptrCast(&Constructors.task_dealloc),
    .tp_methods = @constCast(PythonTaskMethods.ptr),
    .tp_members = @constCast(PythonTaskMembers.ptr),
    .tp_weaklistoffset = @offsetOf(PythonTaskObject, "weakref_list"),
};
