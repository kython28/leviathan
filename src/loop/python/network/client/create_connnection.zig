const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../../../utils/utils.zig");

const CallbackManager = @import("../../../../callback_manager.zig");

const Loop = @import("../../../main.zig");
const LoopObject = Loop.Python.LoopObject;

const Future = @import("../../../../future/main.zig");
const FutureObject = Future.Python.FutureObject;

const Stream = @import("../../../../transports/stream/main.zig");

const SocketCreationData = struct {
    py_host: ?PyObject = null,
    py_port: ?PyObject = null,
    py_ssl: ?PyObject = null,
    py_family: ?PyObject = null,
    py_proto: ?PyObject = null,
    py_local_addr: ?PyObject = null,
    py_server_hostname: ?PyObject = null,
    py_ssl_handshake_timeout: ?PyObject = null,
    py_ssl_shutdown_timeout: ?PyObject = null,
    py_happy_eyeballs_delay: ?PyObject = null, // Happy eyeballs? hahaha
    py_interleave: ?PyObject = null,
    py_all_errors: ?PyObject = null,

    protocol: PyObject = undefined,
    future: *FutureObject = undefined
};

const TransportCreationData = struct {
    protocol: PyObject,
    future: *FutureObject,
    loop: *LoopObject,
    socket_fd: u32,
    zero_copying: bool,
    fd_created: bool = true
};

fn create_socket_connection(
    data: ?*anyopaque, status: CallbackManager.ExecuteCallbacksReturn
) CallbackManager.ExecuteCallbacksReturn {
    _ = data;
    return status;
}

fn create_transport_and_set_future_result(
    data: ?*anyopaque, status: CallbackManager.ExecuteCallbacksReturn
) CallbackManager.ExecuteCallbacksReturn {
    if (status != .Continue) return status;

    const transport_creation_data: *TransportCreationData = @alignCast(@ptrCast(data.?));

    const loop = transport_creation_data.loop;
    const loop_data = utils.get_data_ptr(Loop, loop);
    const allocator = loop_data.allocator;

    defer {
        python_c.py_decref(@ptrCast(loop));
        if (transport_creation_data.fd_created) {
            std.posix.close(@intCast(transport_creation_data.socket_fd));
        }

        allocator.destroy(transport_creation_data);
    }

    const future = transport_creation_data.future;
    defer python_c.py_decref(@ptrCast(future));

    const protocol = transport_creation_data.protocol;
    defer python_c.py_decref(protocol);

    const transport = Stream.Constructors.new_stream_transport(
        protocol, loop, transport_creation_data.socket_fd, transport_creation_data.zero_copying
    ) catch |err| {
        return utils.handle_zig_function_error(err, CallbackManager.ExecuteCallbacksReturn.Exception);
    };
    defer python_c.py_decref(@ptrCast(transport));

    const result_tuple = python_c.PyTuple_New(2) orelse return CallbackManager.ExecuteCallbacksReturn.Exception;
    defer python_c.py_decref(result_tuple);

    var ret = python_c.PyTuple_SetItem(result_tuple, 0, @ptrCast(transport));
    if (ret != 0) {
        return CallbackManager.ExecuteCallbacksReturn.Exception;
    }
    python_c.py_incref(@ptrCast(transport));

    ret = python_c.PyTuple_SetItem(result_tuple, 1, protocol);
    if (ret != 0) {
        return CallbackManager.ExecuteCallbacksReturn.Exception;
    }
    python_c.py_incref(protocol);

    const future_data = utils.get_data_ptr(Future, future);
    Future.Python.Result.future_fast_set_result(future_data, result_tuple) catch |err| {
        return utils.handle_zig_function_error(err, CallbackManager.ExecuteCallbacksReturn.Exception);
    };

    return .Continue;
}


inline fn z_loop_create_connection(
    self: *LoopObject, args: []?PyObject, knames: ?PyObject
) !*FutureObject {
    if (args.len < 1) {
        python_c.raise_python_value_error("Invalid number of arguments\x00");
        return error.PythonError;
    } 

    const protocol_factory: PyObject = args[0].?;
    var py_sock: ?PyObject = null;

    var creation_data = SocketCreationData{};

    if (args.len > 1) {
        creation_data.py_host = args[1].?;
    }

    if (args.len > 2) {
        creation_data.py_port = args[2].?;
    }

    try python_c.parse_vector_call_kwargs(
        knames, args.ptr + args.len,
        &.{
            "host\x00",
            "port\x00",
            "ssl\x00",
            "family\x00",
            "proto\x00",
            "sock\x00",
            "local_addr\x00",
            "server_hostname\x00",
            "ssl_handshake_timeout\x00",
            "ssl_shutdown_timeout\x00",
            "happy_eyeballs_delay\x00",
            "interleave\x00",
            "all_errors\x00"
        },
        &.{
            &creation_data.py_host,
            &creation_data.py_port,
            &creation_data.py_ssl,
            &creation_data.py_family,
            &creation_data.py_proto,
            &py_sock,
            &creation_data.py_local_addr,
            &creation_data.py_server_hostname,
            &creation_data.py_ssl_handshake_timeout,
            &creation_data.py_ssl_shutdown_timeout,
            &creation_data.py_happy_eyeballs_delay,
            &creation_data.py_interleave,
            &creation_data.py_all_errors
        },
    );
    defer python_c.py_xdecref(py_sock);
    errdefer python_c.deinitialize_object_fields(&creation_data, &.{"future", "protocol"});

    if (python_c.PyCallable_Check(protocol_factory) <= 0) {
        python_c.raise_python_value_error("Invalid protocol_factory. It must be a callable");
        return error.PythonError;
    }

    const protocol = python_c.PyObject_CallNoArgs(protocol_factory) orelse return error.PythonError;
    errdefer python_c.py_decref(protocol);

    const loop_data = utils.get_data_ptr(Loop, self);
    const allocator = loop_data.allocator;

    const fut = try Future.Python.Constructors.fast_new_future(self);
    errdefer python_c.py_decref(@ptrCast(fut));

    if (py_sock) |v| {
        const fileno_func = python_c.PyObject_GetAttrString(v, "fileno\x00")
            orelse return error.PythonError;
        defer python_c.py_decref(fileno_func);

        const py_fd = python_c.PyObject_CallNoArgs(fileno_func)
            orelse return error.PythonError;
        defer python_c.py_decref(py_fd);

        const fd = python_c.PyLong_AsLongLong(py_fd);
        if (fd <= 0) {
            _ = python_c.PyErr_Occurred() orelse {
                python_c.raise_python_value_error("Invalid fd\x00");
            };
            return error.PythonError;
        }

        const transport_creation_data = try allocator.create(TransportCreationData);
        errdefer allocator.destroy(transport_creation_data);

        transport_creation_data.* = .{
            .protocol = protocol,
            .future = fut,
            .loop = python_c.py_newref(self),
            .socket_fd = @intCast(fd),
            .zero_copying = false
        };

        try Loop.Scheduling.Soon.dispatch(loop_data, CallbackManager.Callback{
            .ZigGeneric = .{
                .callback = &create_transport_and_set_future_result,
                .data = transport_creation_data
            }
        });

        python_c.deinitialize_object_fields(&creation_data, &.{"future", "protocol"});
        return python_c.py_newref(fut);
    }

    creation_data.future = fut;
    creation_data.protocol = protocol;

    const creation_data_ptr = try allocator.create(SocketCreationData);
    creation_data_ptr.* = creation_data;
    errdefer allocator.destroy(creation_data_ptr);

    try Loop.Scheduling.Soon.dispatch(loop_data, CallbackManager.Callback{
        .ZigGeneric = .{
            .callback = &create_socket_connection,
            .data = creation_data_ptr
        }
    });

    return python_c.py_newref(fut);
}

pub fn loop_create_connection(
    self: ?*LoopObject, args: ?[*]?PyObject, nargs: isize, knames: ?PyObject
) callconv(.C) ?*FutureObject {
    return utils.execute_zig_function(
        z_loop_create_connection, .{
            self.?, args.?[0..@as(usize, @intCast(nargs))], knames,
        }
    );
}
