const python_c = @import("../../utils/python_c.zig");
const PyObject = *python_c.PyObject;

const utils = @import("../../utils/utils.zig");
const allocator = utils.allocator;

const Loop = @import("../main.zig");

pub const LEVIATHAN_LOOP_MAGIC = 0x4C4F4F5000000001;

pub const PythonLoopObject = extern struct {
    ob_base: python_c.PyObject,
    magic: u64,
    loop_obj: ?*Loop,

    running: bool,
    stopping: bool,
    closed: bool,

    exception_handler: ?PyObject
};

inline fn z_loop_new(
    @"type": *python_c.PyTypeObject, _: ?PyObject,
    _: ?PyObject
) !*PythonLoopObject {
    const instance: *PythonLoopObject = @ptrCast(@"type".tp_alloc.?(@"type", 0) orelse return error.PythonError);
    errdefer @"type".tp_free.?(instance);

    instance.magic = LEVIATHAN_LOOP_MAGIC;
    instance.loop_obj = null;

    instance.running = false;
    instance.stopping = false;
    instance.closed = false;

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

pub fn loop_traverse(self: ?*PythonLoopObject, visit: python_c.visitproc, arg: ?*anyopaque) callconv(.C) c_int {
    const instance = self.?;
    return visit.?(@ptrCast(instance), arg);
}

pub fn loop_clear(self: ?*PythonLoopObject) callconv(.C) c_int {
    const instance = self.?;
    const py_loop = instance;

    if (py_loop.loop_obj) |loop| {
        if (!loop.closed) {
            @panic("Loop is not closed, can't be deallocated");
        }

        if (loop.running) {
            @panic("Loop is running, can't be deallocated");
        }

        allocator.destroy(loop);
        py_loop.loop_obj = null;
    }

    python_c.py_xdecref(py_loop.exception_handler);
    py_loop.exception_handler = null;

    return 0;
}

pub fn loop_dealloc(self: ?*PythonLoopObject) callconv(.C) void {
    const instance = self.?;
    // python_c.PyObject_GC_UnTrack(instance);
    _ = loop_clear(instance);

    const @"type": *python_c.PyTypeObject = @ptrCast(python_c.Py_TYPE(@ptrCast(instance)) orelse unreachable);
    @"type".tp_free.?(@ptrCast(instance));
}

inline fn z_loop_init(
    self: *PythonLoopObject, args: ?PyObject, kwargs: ?PyObject
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
        utils.put_python_runtime_error_message("Invalid exception handler\x00");
        return error.PythonError;
    }

    self.exception_handler = python_c.Py_NewRef(exception_handler.?) orelse return error.PythonError;
    errdefer python_c.py_decref(exception_handler.?);

    self.loop_obj = try Loop.init(allocator, @intCast(ready_tasks_queue_min_bytes_capacity));
    self.loop_obj.?.py_loop = self;
    return 0;
}

pub fn loop_init(
    self: ?*PythonLoopObject, args: ?PyObject, kwargs: ?PyObject
) callconv(.C) c_int {
    return utils.execute_zig_function(z_loop_init, .{self.?, args, kwargs});
}

