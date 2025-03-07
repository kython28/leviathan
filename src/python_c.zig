pub usingnamespace @cImport({
    @cDefine("PY_SSIZE_T_CLEAN", {});
    @cInclude("Python.h");
});

const builtin = @import("builtin");
const std = @import("std");

pub inline fn get_type(obj: *Python.PyObject) *Python.PyTypeObject {
    return obj.ob_type orelse unreachable;
}

pub inline fn is_type(obj: *Python.PyObject, @"type": *Python.PyTypeObject) bool {
    return get_type(obj) == @"type";
}

pub inline fn type_check(obj: *Python.PyObject, @"type": *Python.PyTypeObject) bool {
    return is_type(obj, @"type") or Python.PyType_IsSubtype(get_type(obj), @"type") != 0;
}

// -------------------------------------------------
// Problems when compiling with Python3.13.1t
inline fn type_hasfeature(arg_type: *Python.PyTypeObject, arg_feature: c_ulong) bool {
    const flags: c_ulong = blk: {
        if (builtin.single_threaded) {
            break :blk arg_type.tp_flags;
        }else{
            break :blk @atomicLoad(c_ulong, &arg_type.tp_flags, .unordered);
        }
    };
    return (flags & arg_feature) == 0;
}

pub inline fn long_check(obj: *Python.PyObject) bool {
    return type_hasfeature(get_type(obj), Python.Py_TPFLAGS_LONG_SUBCLASS);
}

pub inline fn unicode_check(obj: *Python.PyObject) bool {
    return type_hasfeature(get_type(obj), Python.Py_TPFLAGS_UNICODE_SUBCLASS);
}

pub inline fn exception_check(obj: *Python.PyObject) bool {
    return type_hasfeature(get_type(obj), Python.Py_TPFLAGS_BASE_EXC_SUBCLASS);
}
// -------------------------------------------------

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

pub inline fn get_py_none_without_incref() *Python.PyObject {
    return @ptrCast(&Python._Py_NoneStruct);
}

pub inline fn is_none(obj: *Python.PyObject) bool {
    const py_none_struct: *Python.PyObject = @ptrCast(&Python._Py_NoneStruct);
    return obj == py_none_struct;
}

inline fn get_refcnt_ptr(obj: *Python.PyObject) *Python.Py_ssize_t {
    return @ptrCast(obj);
}

inline fn get_refcnt_split(obj: *Python.PyObject) *[2]u32 {
    return @ptrCast(obj);
}

pub inline fn py_incref(op: *Python.PyObject) void {
    if (builtin.single_threaded) {
        const refcnt_ptr = get_refcnt_split(op);
        refcnt_ptr.*[0] +|= 1;
    }else{
        const new_local = @atomicLoad(u32, &op.ob_ref_local, .unordered) +| 1;
        if (op.ob_tid == std.Thread.getCurrentId()) {
            @atomicStore(u32, &op.ob_ref_local, new_local, .unordered);
        }else{
            _ = @atomicRmw(
                Python.Py_ssize_t, &op.ob_ref_shared, .Add,
                @as(Python.Py_ssize_t, @bitCast(@as(c_long, @as(c_int, 1) << @intCast(2)))),
                .monotonic
            );
        }
    }
}

pub inline fn py_xincref(op: ?*Python.PyObject) void {
    if (op) |o| {
        py_incref(o);
    }
}

inline fn _Py_IsImmortal(refcnt: Python.Py_ssize_t) bool {
    return @as(i32, @bitCast(@as(c_int, @truncate(refcnt)))) < @as(c_int, 0);
}

pub fn py_decref(op: *Python.PyObject) void {
    if (builtin.single_threaded) {
        const ref_ptr = get_refcnt_ptr(op);
        var ref = ref_ptr.*;
        if (_Py_IsImmortal(ref)) {
            return;
        }

        ref -= 1;
        ref_ptr.* = ref;
        if (ref == 0) {
            const ob_type: *Python.PyTypeObject = op.ob_type orelse unreachable;
            ob_type.tp_dealloc.?(op);
        }
    }else{
        var local = @atomicLoad(u32, &op.ob_ref_local, .unordered);
        if (_Py_IsImmortal(local)) {
            return;
        }

        if (op.ob_tid == std.Thread.getCurrentId()) {
            local -= 1;
            @atomicStore(u32, &op.ob_ref_local, local, .unordered);
            if (local == 0) {
                Python._Py_MergeZeroLocalRefcount(op);
            }
        }else{
            Python._Py_DecRefShared(op);
        }
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

pub fn py_visit(object: anytype, visit: Python.visitproc, arg: ?*anyopaque) c_int {
    const visit_ptr = visit.?;
    const fields = comptime std.meta.fields(@typeInfo(@TypeOf(object)).pointer.child);
    loop: inline for (fields) |field| {
        const field_name = field.name;
        const value: ?*Python.PyObject = switch (@typeInfo(field.type)) {
            .optional => |data| blk: {
                switch (@typeInfo(data.child)) {
                    .pointer => |data2| {
                        if (data2.child != Python.PyObject) {
                            continue :loop;
                        }
                        break :blk @field(object, field_name);
                    },
                    else => continue :loop
                }
            },
            .pointer => |data| blk: {
                if (data.child != Python.PyObject) {
                    continue :loop;
                }
                break :blk @field(object, field_name);
            },
            .@"struct" => {
                const vret = py_visit(&@field(object, field_name), visit, arg);
                if (vret != 0) {
                    return vret;
                }

                continue :loop;
            },
            else => continue :loop
        };

        if (value) |v| {
            const vret = visit_ptr(v, arg);
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
    raise_python_error(Python.PyExc_ValueError.?, message);
}

pub inline fn raise_python_type_error(message: ?[:0]const u8) void {
    raise_python_error(Python.PyExc_TypeError.?, message);
}

pub inline fn raise_python_runtime_error(message: ?[:0]const u8) void {
    raise_python_error(Python.PyExc_RuntimeError.?, message);
}

pub inline fn initialize_object_fields(
    object: anytype, comptime exclude_fields: []const []const u8
) void {
    const fields = comptime std.meta.fields(@typeInfo(@TypeOf(object)).pointer.child);
    loop: inline for (fields) |field| {
        const field_name = field.name;

        inline for (exclude_fields) |exclude_field| {
            if (comptime std.mem.eql(u8, field_name, exclude_field)) {
                continue :loop;
            }
        }

        @field(object, field_name) = comptime std.mem.zeroes(field.type);
    }
}

pub fn deinitialize_object_fields(
    object: anytype, comptime exclude_fields: []const []const u8
) void {
    const fields = comptime std.meta.fields(@typeInfo(@TypeOf(object)).pointer.child);
    loop: inline for (fields) |field| {
        const field_name = field.name;

        if (comptime std.mem.eql(u8, field_name, "ob_base")) {
            continue;
        }

        inline for (exclude_fields) |exclude_field| {
            if (comptime std.mem.eql(u8, field_name, exclude_field)) {
                continue :loop;
            }
        }

        switch (@typeInfo(field.type)) {
            .optional => |data| {
                switch (@typeInfo(data.child)) {
                    .pointer => |data2| {
                        if (data2.child == Python.PyObject) {
                            py_decref_and_set_null(&@field(object, field_name));
                        }
                    },
                    else => {}
                }
            },
            .pointer => |data| {
                if (data.child == Python.PyObject) {
                    py_decref(@field(object, field_name));
                    @field(object, field_name) = undefined;
                }else if (@typeInfo(data.child) == .@"struct") {
                    if (@hasField(data.child, "ob_base")) {
                        py_decref(@ptrCast(@field(object, field_name)));
                        continue :loop;
                    }
                    deinitialize_object_fields(@field(object, field_name), exclude_fields);
                }
            },
            .@"struct" => {
                deinitialize_object_fields(&@field(object, field_name), exclude_fields);
            },
            else => {}
        }
    }
}

const Python = @This();
