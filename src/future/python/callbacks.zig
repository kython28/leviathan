const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const Future = @import("../main.zig");
const Handle = @import("../../handle.zig");
const Loop = @import("../../loop/main.zig");
const PythonFutureObject = Future.Python.FutureObject;

const CallbackManager = @import("callback_manager");

const utils = @import("utils");

inline fn z_future_add_done_callback(
    self: *PythonFutureObject, args: []?PyObject,
    knames: ?PyObject
) !PyObject {
    if (args.len != 1) {
        python_c.raise_python_value_error("Invalid number of arguments\x00");
        return error.PythonError;
    }

    const future_data = utils.get_data_ptr(Future, self);

    var context: ?PyObject = null;
    try python_c.parse_vector_call_kwargs(
        knames, args.ptr + args.len,
        &.{"context\x00"},
        &.{&context},
    );

    var py_callback: PyObject = undefined;
    {
        errdefer python_c.py_xdecref(context);

        if (context) |py_ctx| {
            if (python_c.is_none(py_ctx)) {
                context = python_c.PyContext_CopyCurrent()
                    orelse return error.PythonError;
                python_c.py_decref(py_ctx);
            }else if (!python_c.is_type(py_ctx, &python_c.PyContext_Type)) {
                python_c.raise_python_type_error("Invalid context\x00");
                return error.PythonError;
            }
        }else {
            context = python_c.PyContext_CopyCurrent() orelse return error.PythonError;
        }

        py_callback = python_c.py_newref(args[0].?);
        errdefer python_c.py_decref(py_callback);

        if (python_c.PyCallable_Check(py_callback) <= 0) {
            python_c.raise_python_type_error("Invalid callback\x00");
            return error.PythonError;
        }
    }

    switch (future_data.status) {
        .pending => try Future.Callback.add_done_callback(future_data, .{
            .PythonGeneric = .{
                .callback = py_callback,
                .context = context.?
            }
        }),
        else => {
            const loop_data = future_data.loop;
            const handle = blk: {
                errdefer {
                    python_c.py_decref(context.?);
                    python_c.py_decref(py_callback);
                }

                const callback_args = try loop_data.allocator.alloc(PyObject, 1);
                errdefer loop_data.allocator.free(callback_args);

                callback_args[0] = @ptrCast(self);

                break :blk try Handle.fast_new_handle(
                    context.?, loop_data, py_callback, callback_args, false
                );
            };
            python_c.py_incref(@ptrCast(self));
            errdefer python_c.py_decref(@ptrCast(handle));

            const callback = CallbackManager.Callback{
                .func = &Handle.callback_for_python_generic_callbacks,
                .cleanup = &Handle.release_python_generic_callback,
                .data = .{
                    .user_data = handle,
                    .exception_context = .{
                        .callback_ptr = py_callback,
                        .module_name = Handle.ModuleName,
                        .exc_message = Handle.ExceptionMessage,
                        .module_ptr = @ptrCast(handle)
                    }
                }
            };
            try Loop.Scheduling.Soon.dispatch(future_data.loop, &callback);
        }
    }

    return python_c.get_py_none();
}

pub fn future_add_done_callback(
    self: ?*PythonFutureObject, args: ?[*]?PyObject, nargs: isize, knames: ?PyObject
) callconv(.C) ?PyObject {
    return utils.execute_zig_function(z_future_add_done_callback, .{
        self.?, args.?[0..@as(usize, @intCast(nargs))], knames
    });
}

pub fn future_remove_done_callback(self: ?*PythonFutureObject, callback: ?PyObject) callconv(.C) ?PyObject {
    const future_data = utils.get_data_ptr(Future, self.?);
    const removed_count = Future.Callback.remove_done_callback(
        future_data, @intCast(@intFromPtr(callback.?))
    );

    return python_c.PyLong_FromUnsignedLongLong(@intCast(removed_count));
}
