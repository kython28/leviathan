pub usingnamespace @cImport({
    @cDefine("PY_SSIZE_T_CLEAN", {});
    @cInclude("Python.h");
});

pub inline fn get_type(obj: *Python.PyObject) *Python.PyTypeObject {
    return obj.ob_type orelse unreachable;
}

pub inline fn is_type(obj: *Python.PyObject, @"type": *Python.PyTypeObject) bool {
    return get_type(obj) == @"type";
}

pub inline fn type_check(obj: *Python.PyObject, @"type": *Python.PyTypeObject) bool {
    return is_type(obj, @"type") or Python.PyType_IsSubtype(get_type(obj), @"type") != 0;
}

pub inline fn get_py_true() *Python.PyObject {
    const py_true_struct: *Python.PyObject = @ptrCast(&Python._Py_TrueStruct);
    Python.py_incref(py_true_struct);
    return py_true_struct;
}

pub inline fn get_py_false() *Python.PyObject {
    const py_false_struct: *Python.PyObject = @ptrCast(&Python._Py_FalseStruct);
    Python.py_incref(py_false_struct);
    return py_false_struct;
}

pub inline fn get_py_none() *Python.PyObject {
    const py_none_struct: *Python.PyObject = @ptrCast(&Python._Py_NoneStruct);
    Python.py_incref(py_none_struct);
    return py_none_struct;
}

pub inline fn is_none(obj: *Python.PyObject) bool {
    const py_none_struct: *Python.PyObject = @ptrCast(&Python._Py_NoneStruct);
    return obj == py_none_struct;
}

pub inline fn py_incref(op: *Python.PyObject) void {
    const new_refcnt = op.unnamed_0.ob_refcnt_split[0] +| 1;
    if (new_refcnt == 0) {
        return;
    }

    op.unnamed_0.ob_refcnt_split[0] = new_refcnt;
}

pub inline fn py_xinref(op: ?*Python.PyObject) void {
    if (op) |o| {
        py_incref(o);
    }
}

inline fn _Py_IsImmortal(arg_op: *Python.PyObject) bool {
    return @as(i32, @bitCast(@as(c_int, @truncate(arg_op.unnamed_0.ob_refcnt)))) < @as(c_int, 0);
}

pub inline fn py_decref(op: *Python.PyObject) void {
    var ref = op.unnamed_0.ob_refcnt;
    if (_Py_IsImmortal(op)) {
        return;
    }

    ref -= 1;
    op.unnamed_0.ob_refcnt = ref;
    if (ref == 0) {
        op.ob_type.*.tp_dealloc.?(op);
    }
}

pub inline fn py_xdecref(op: ?*Python.PyObject) void {
    if (op) |o| {
        py_decref(o);
    }
}

pub inline fn py_decref_and_set_null(op: *?*Python.PyObject) void {
    if (op.*) |o| {
        py_decref(o);
        op.* = null;
    }
}

pub inline fn py_newref(op: anytype) @TypeOf(op) {
    Python.py_incref(@ptrCast(op));
    return op;
}

pub inline fn py_visit(objects: []const ?*Python.PyObject, visit: Python.visitproc, arg: ?*anyopaque) c_int {
    for (objects) |obj| {
        if (obj) |_obj| {
            const vret = visit.?(_obj, arg);
            if (vret != 0) {
                return vret;
            }
        }
    }

    return 0;
}

pub inline fn parse_vector_call_kwargs(
    knames: ?*Python.PyObject, args_ptr: [*]?*Python.PyObject,
    comptime names: []const []const u8,
    py_objects: []const *?*Python.PyObject
) !void {
    const len = names.len;
    if (len != py_objects.len) {
        return error.InvalidLength;
    }

    var _py_objects: [len]?*Python.PyObject = .{null} ** len;

    if (knames) |kwargs| {
        const kwargs_len = Python.PyTuple_Size(kwargs);
        const args = args_ptr[0..@as(usize, @intCast(kwargs_len))];
        if (kwargs_len < 0) {
            return error.PythonError;
        }else if (kwargs_len <= len) {
            loop: for (args, 0..) |arg, i| {
                const key = Python.PyTuple_GetItem(kwargs, @intCast(i)) orelse return error.PythonError;
                inline for (names, &_py_objects) |name, *obj| {
                    if (Python.PyUnicode_CompareWithASCIIString(key, @ptrCast(name)) == 0) {
                        obj.* = arg.?;
                        continue :loop;
                    }
                }

                Python.raise_python_value_error("Invalid keyword argument\x00");
                return error.PythonError;
            }
        }else if (kwargs_len > len) {
            Python.raise_python_value_error("Too many keyword arguments\x00");
            return error.PythonError;
        }
    }

    for (py_objects, &_py_objects) |py_obj, py_obj2| {
        if (py_obj2) |v| {
            py_obj.* = py_newref(v);
        }
    }
}

pub inline fn raise_python_error(exception: *Python.PyObject, message: ?[:0]const u8) void {
    if (message) |msg| {
        Python.PyErr_SetString(exception, @ptrCast(msg));
    }else{
        Python.PyErr_SetNone(exception);
    }
}

pub inline fn raise_python_value_error(message: ?[:0]const u8) void {
    raise_python_error(Python.PyExc_ValueError, message);
}

pub inline fn raise_python_type_error(message: ?[:0]const u8) void {
    raise_python_error(Python.PyExc_TypeError, message);
}

pub inline fn raise_python_runtime_error(message: ?[:0]const u8) void {
    raise_python_error(Python.PyExc_RuntimeError, message);
}

const Python = @This();
