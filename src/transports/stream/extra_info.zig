const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../utils/main.zig");

const Loop = @import("../../loop/main.zig");

const Stream = @import("main.zig");
const StreamTransportObject = Stream.StreamTransportObject;

fn create_socket_instance(self: *StreamTransportObject) !PyObject {
    const py_fd = python_c.PyLong_FromLong(@intCast(self.fd))
        orelse return error.PythonError;
    defer python_c.py_decref(py_fd);

    const fileno_kname: PyObject = python_c.PyUnicode_FromString("fileno\x00")
        orelse return error.PythonError;
    defer python_c.py_decref(fileno_kname);

    var socket_args: [1]PyObject = undefined;
    socket_args[0] = py_fd;

    const socket_knames = python_c.PyTuple_Pack(1, fileno_kname)
        orelse return error.PythonError;

    const ret = python_c.PyObject_Vectorcall(utils.PythonImports.socket_class, &socket_args, 0, socket_knames)
        orelse return error.PythonError;

    self.socket = ret;

    return ret;
}

inline fn z_transport_get_extra_info(
    self: *StreamTransportObject, args: []?PyObject, knames: ?PyObject
) !PyObject {
    if (args.len < 1) {
        python_c.raise_python_value_error("Invalid number of arguments\x00");
        return error.PythonError;
    }

    const info_name = args[0].?;
    var default_value: ?PyObject = null;

    try python_c.parse_vector_call_kwargs(
        knames, args.ptr + args.len,
        &.{"default\x00"},
        &.{&default_value}
    );

    var info_name_length: python_c.Py_ssize_t = undefined;
    const name_ptr: [*]const u8 = python_c.PyUnicode_AsUTF8AndSize(info_name, &info_name_length)
        orelse return error.PythonError;

    var result: PyObject = undefined;

    const name = name_ptr[0..@intCast(info_name_length)];
    if (std.mem.eql(u8, name, "socket")) {
        if (self.socket) |py_sock| {
            result = python_c.py_newref(py_sock);
        }else{
            result = try create_socket_instance(self);
            python_c.py_incref(result);
        }
    }else if (std.mem.eql(u8, name, "peername")) {
        if (self.peername) |py_peername| {
            result = python_c.py_newref(py_peername);
        }else{
            var socket: PyObject = undefined;
            if (self.socket) |py_sock| {
                socket = py_sock;
            }else{
                socket = try create_socket_instance(self);
            }

            const getpeername_func = python_c.PyObject_GetAttrString(socket, "getpeername\x00")
                orelse return error.PythonError;
            defer python_c.py_decref(getpeername_func);

            result = python_c.PyObject_CallNoArgs(getpeername_func)
                orelse return error.PythonError;
            self.peername = python_c.py_newref(result);
        }
    }else if (std.mem.eql(u8, name, "sockname")) {
        if (self.sockname) |py_sockname| {
            result = py_sockname;
        }else{
            var socket: PyObject = undefined;
            if (self.socket) |py_sock| {
                socket = py_sock;
            }else{
                socket = try create_socket_instance(self);
            }

            const getsockname_func = python_c.PyObject_GetAttrString(socket, "getsockname\x00")
                orelse return error.PythonError;
            defer python_c.py_decref(getsockname_func);

            result = python_c.PyObject_CallNoArgs(getsockname_func)
                orelse return error.PythonError;
            self.sockname = python_c.py_newref(result);
        }
    }else{
        if (default_value) |v| {
            result = v;
        }else{
            result = python_c.get_py_none();
        }
    }

    return result;
}

pub fn transport_get_extra_info(
    self: ?*StreamTransportObject, args: ?[*]?PyObject, nargs: isize, knames: ?PyObject
) callconv(.C) ?PyObject {
    return utils.execute_zig_function(
        z_transport_get_extra_info, .{
            self.?, args.?[0..@as(usize, @intCast(nargs))], knames
        }
    );
}
