const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../../utils/utils.zig");

const Loop = @import("../../main.zig");
const Task = @import("../../../task/main.zig");

const PythonLoopObject = Loop.Python.LoopObject;
const PythonTaskObject = Task.PythonTaskObject;

inline fn z_loop_create_task(
    self: *PythonLoopObject, args: []?PyObject,
    knames: ?PyObject
) !*PythonTaskObject {
    if (args.len != 1) {
        python_c.raise_python_runtime_error("Invalid number of arguments\x00");
        return error.PythonError;
    }

    var context: ?PyObject = null;
    var name: ?PyObject = null;
    try python_c.parse_vector_call_kwargs(
        knames, args.ptr + args.len,
        &.{"context\x00", "name\x00"},
        &.{&context, &name},
    );
    errdefer python_c.py_xdecref(name);
    errdefer python_c.py_xdecref(context);

    if (context) |py_ctx| {
        if (python_c.is_none(py_ctx)) {
            context = python_c.PyContext_CopyCurrent()
                orelse return error.PythonError;
            python_c.py_decref(py_ctx);
        }else{
            python_c.raise_python_type_error("Invalid context\x00");
            return error.PythonError;
        }
    }else {
        context = python_c.PyContext_CopyCurrent() orelse return error.PythonError;
    }

    if (name) |v| {
        if (python_c.is_none(v)) {
            python_c.py_decref(v);
            name = null;
        }else if (python_c.unicode_check(v)) {
            python_c.raise_python_type_error("name must be a string\x00");
            return error.PythonError;
        }
    }

    const coro: PyObject = python_c.py_newref(args[0].?);
    errdefer python_c.py_decref(coro);

    const task = try Task.Constructors.fast_new_task(self, coro, context.?, name);
    return task;
}

pub fn loop_create_task(
    self: ?*PythonLoopObject, args: ?[*]?PyObject, nargs: isize, knames: ?PyObject
) callconv(.C) ?*PythonTaskObject {
    return utils.execute_zig_function(z_loop_create_task, .{
        self.?, args.?[0..@as(usize, @intCast(nargs))], knames
    });
}
