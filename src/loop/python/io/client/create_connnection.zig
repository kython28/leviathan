const std = @import("std");

const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("utils");

const CallbackManager = @import("callback_manager");

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

    protocol_factory: PyObject = undefined,
    future: *FutureObject = undefined,
    loop: *LoopObject = undefined,

    pub fn deinit(self: *SocketCreationData) void {
        const loop_data = utils.get_data_ptr(Loop, self.loop);
        const allocator = loop_data.allocator;

        python_c.deinitialize_object_fields(self, &.{});
        allocator.destroy(self);
    }
};

const TransportCreationData = struct {
    protocol_factory: PyObject,
    future: *FutureObject,
    loop: *LoopObject,
    socket_fd: std.posix.fd_t,
    zero_copying: bool,
    fd_created: bool = true
};

fn set_future_exception(err: anyerror, future: *FutureObject) !void {
    utils.handle_zig_function_error(err, {});
    const exc = python_c.PyErr_GetRaisedException() orelse return error.PythonError;

    const future_data = utils.get_data_ptr(Future, future);
    Future.Python.Result.future_fast_set_exception(future, future_data, exc);
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
    defer {
        python_c.py_xdecref(py_sock);
        python_c.py_xdecref(protocol_factory);
    }
    errdefer python_c.deinitialize_object_fields(&creation_data, &.{"future", "protocol_factory"});

    if (python_c.PyCallable_Check(protocol_factory) <= 0) {
        python_c.raise_python_value_error("Invalid protocol_factory. It must be a callable");
        return error.PythonError;
    }

    const loop_data = utils.get_data_ptr(Loop, self);
    const allocator = loop_data.allocator;

    const fut = try Future.Python.Constructors.fast_new_future(self);
    errdefer python_c.py_decref(@ptrCast(fut));

    if (py_sock) |v| {
        if (creation_data.py_host != null or creation_data.py_port != null) {
            python_c.raise_python_value_error("host/port and sock can not be specified at the same time");
            return error.PythonError;
        }

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
            .protocol_factory = protocol_factory,
            .future = fut,
            .loop = python_c.py_newref(self),
            .socket_fd = @intCast(fd),
            .zero_copying = false
        };
        errdefer python_c.py_decref(@ptrCast(self));

        const callback = CallbackManager.Callback{
            .func = &create_transport_and_set_future_result,
            .cleanup = null,
            .data = .{
                .user_data = transport_creation_data,
                .exception_context = null,
            },
        };
        try Loop.Scheduling.Soon.dispatch(loop_data, &callback);

        python_c.deinitialize_object_fields(&creation_data, &.{"future", "protocol_factory"});
        return python_c.py_newref(fut);
    }

    creation_data.loop = python_c.py_newref(self);
    creation_data.future = fut;
    creation_data.protocol_factory = protocol_factory;

    const creation_data_ptr = try allocator.create(SocketCreationData);
    creation_data_ptr.* = creation_data;
    errdefer allocator.destroy(creation_data_ptr);

    const callback = CallbackManager.Callback{
        .func = &create_socket_connection,
        .cleanup = null,
        .data = .{
            .user_data = creation_data_ptr,
            .exception_context = null,
        },
    };
    try Loop.Scheduling.Soon.dispatch(loop_data, &callback);

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

// -----------------------------------------------------------------
// STEP#1: Try resolve host

const SocketConnectionMethod = union(enum) {
    Single: usize, // Blocking task id
    HappyEyeballs: []usize, // Blocking task id per address
};

const SocketConnectionData = struct {
    creation_data: *SocketCreationData,
    address_list: ?[]std.net.Address,
    local_addr_list: ?[]std.net.Address,
    method: SocketConnectionMethod,

    pub fn deinit(self: *SocketConnectionData) void {
        const loop_data = utils.get_data_ptr(Loop, self.creation_data.loop);
        const allocator = loop_data.allocator;

        self.creation_data.deinit();
        if (self.address_list) |v| {
            allocator.free(v);
        }

        if (self.local_addr_list) |v| {
            allocator.free(v);
        }

        allocator.destroy(self);
    }
};

fn get_host_slice(data: *SocketCreationData) ![]const u8 {
    const py_host = data.py_host orelse {
        python_c.raise_python_value_error("Host is required");
        return error.PythonError;
    };

    if (python_c.unicode_check(py_host)) {
        python_c.raise_python_value_error("Host must be a valid string");
        return error.PythonError;
    }

    var host_ptr_lenght: python_c.Py_ssize_t = undefined;
    const host_ptr = python_c.PyUnicode_AsUTF8AndSize(py_host, &host_ptr_lenght)
        orelse return error.PythonError;

    return host_ptr[0..@intCast(host_ptr_lenght)];
}


fn z_try_resolv_host(creation_data: *SocketCreationData) !void {
    const hostname = try get_host_slice(creation_data);

    const loop_data = utils.get_data_ptr(Loop, creation_data.loop);
    const allocator = loop_data.allocator;

    const connection_data = try allocator.create(SocketConnectionData);
    errdefer allocator.destroy(connection_data);
    connection_data.creation_data = creation_data;
    connection_data.address_list = null;
    connection_data.local_addr_list = null;

    const resolver_callback = CallbackManager.Callback{
        .func = &host_resolved_callback,
        .cleanup = null,
        .data = .{
            .user_data = connection_data,
            .exception_context = null,
        },
    };
    const address_list = try loop_data.dns.lookup(hostname, &resolver_callback) orelse return;

    connection_data.address_list = try allocator.dupe(std.net.Address, address_list);
    errdefer allocator.free(connection_data.address_list.?);

    const callback = CallbackManager.Callback{
        .func = &create_socket_connection,
        .cleanup = null,
        .data = .{
            .user_data = connection_data,
            .exception_context = null,
        },
    };
    try Loop.Scheduling.Soon.dispatch(loop_data, &callback);
}

fn try_resolv_host(data: *const CallbackManager.CallbackData) !void {
    const socket_creation_data_ptr: *SocketCreationData = @alignCast(@ptrCast(data.user_data.?));
    errdefer python_c.deinitialize_object_fields(socket_creation_data_ptr, &.{});

    if (data.cancelled) {
        python_c.raise_python_runtime_error("Event for trying host resolution cancelled");
        return set_future_exception(error.PythonError, socket_creation_data_ptr.future);
    }

    z_try_resolv_host(socket_creation_data_ptr) catch |err| {
        return set_future_exception(err, socket_creation_data_ptr.future);
    };
}

// -----------------------------------------------------------------
// Step#2: Process host resolution result

fn z_host_resolved_callback(connection_data: *SocketConnectionData) !void {
    const creation_data = connection_data.creation_data;
    const loop_data = utils.get_data_ptr(Loop, creation_data.loop);
    const allocator = loop_data.allocator;

    const host = try get_host_slice(creation_data);
    const address_list = try loop_data.dns.lookup(host, null) orelse {
        python_c.raise_python_runtime_error("Failed to resolve host");
        return set_future_exception(error.PythonError, creation_data.future);
    };

    connection_data.address_list = try allocator.dupe(std.net.Address, address_list);
    const callback = CallbackManager.Callback{
        .func = &create_socket_connection,
        .cleanup = null,
        .data = .{
            .user_data = connection_data,
            .exception_context = null,
        },
    };
    Loop.Scheduling.Soon.dispatch(loop_data, &callback);
}

fn host_resolved_callback(data: *const CallbackManager.CallbackData) !void {
    const connection_data: *SocketConnectionData = @alignCast(@ptrCast(data.user_data.?));
    errdefer connection_data.deinit();

    if (data.cancelled) {
        python_c.raise_python_runtime_error("Host resolution failed");
        return set_future_exception(error.PythonError, connection_data.creation_data.?.future);
    }

    z_host_resolved_callback(connection_data) catch |err| {
        return set_future_exception(err, connection_data.creation_data.?.future);
    };
}

// -----------------------------------------------------------------
// STEP#3: Create socket and submit connect events

fn interleave_address_list(allocator: std.mem.Allocator, address_list: []std.net.Address, interleave: usize) !void {
    const tmp_list = try allocator.alloc(std.net.Address, address_list.len * 2);
    defer allocator.free(tmp_list);

    var ipv4_addresses: usize = 0;
    var ipv6_addresses: usize = 0;

    for (address_list) |*address| {
        switch (address.any.family) {
            std.posix.AF.INET => {
                tmp_list[ipv4_addresses] = address.*;
                ipv4_addresses += 1;
            },
            std.posix.AF.INET6 => {
                tmp_list[address_list.len + ipv6_addresses] = address.*;
                ipv6_addresses += 1;
            },
            else => unreachable
        }
    }

    if (ipv6_addresses == 0 or ipv4_addresses == 0) {
        return;
    }

    var interleave_count: usize = interleave;
    for (address_list) |*v| {
        if (interleave_count == 0 or ipv6_addresses == 0) {
            ipv4_addresses -= 1;
            v.* = tmp_list[ipv4_addresses];
            interleave_count = interleave;
        }else{
            ipv6_addresses -= 1;
            v.* = tmp_list[address_list.len + ipv6_addresses];
            interleave_count -= 1;
        }
    }
}


fn create_socket_and_submit_connect_req(address: *const std.net.Address, data: *SocketData, loop: *Loop) !usize {
    const flags = std.posix.SOCK.STREAM | std.posix.SOCK.NONBLOCK | std.posix.SOCK.CLOEXEC;
    const socket_fd = try std.posix.socket(address.any.family, flags, std.posix.IPPROTO.TCP);
    errdefer std.posix.close(socket_fd);

    data.socket_fd = socket_fd;
    errdefer data.socket_fd = -1;

    const task_id = try Loop.Scheduling.IO.queue(
        loop, .{
            .SocketConnect = .{
                .address = address,
                .socket_fd = socket_fd,
                .callback = .{
                    .ZigGenericIO = .{
                        .callback = &socket_connected_callback,
                        .data = data
                    }
                }
            }
        }
    );

    return task_id;
}

fn z_create_socket_connection(data: *SocketConnectionData, connection_submitted: *usize) !void {
    const creation_data = data.creation_data;

    const port: u16 = blk: {
        const py_port = creation_data.py_port orelse break :blk 0;
        const value = python_c.PyLong_AsInt(py_port);
        if (value == -1) {
            if (python_c.PyErr_Occurred()) |_| {
                return error.PythonError;
            }
        }

        break :blk @intCast(value);
    };

    const interleave: usize = blk: {
        const py_interleave = creation_data.py_interleave orelse break :blk 0;
        const value = python_c.PyLong_AsUnsignedLongLong(py_interleave);
        if (@as(c_longlong, @bitCast(value)) == -1) {
            if (python_c.PyErr_Occurred()) |_| {
                return error.PythonError;
            }
        }

        break :blk @intCast(value);
    };

    const loop = creation_data.loop;
    const loop_data = utils.get_data_ptr(Loop, loop);
    const allocator = loop_data.allocator;

    if (interleave > 0) {
        try interleave_address_list(allocator, data.address_list.?, interleave);
    }

    if (creation_data.py_happy_eyeballs_delay) |py_delay| {
        if (interleave == 0) {
            try interleave_address_list(allocator, data.address_list.?, 1);
        }

        var delay = python_c.PyFloat_AsDouble(py_delay);
        const eps = comptime std.math.floatEps(f64);
        if ((delay + 1.0) < eps) {
            if (python_c.PyErr_Occurred() != null) {
                return error.PythonError;
            }

            delay = 0;
        }
    }else{

    }
}

fn create_socket_connection(data: *const CallbackManager.CallbackData) !void {
    const socket_creation_data: *SocketConnectionData = @alignCast(@ptrCast(data.user_data.?));

    var connections_submitted: usize = 0;
    errdefer {
        if (connections_submitted == 0) {
            socket_creation_data.deinit();
        }
    }

    if (data.cancelled) {
        python_c.raise_python_runtime_error("Event for socket creation cancelled");
        return set_future_exception(error.PythonError, socket_creation_data.creation_data.future);
    }

    z_create_socket_connection(socket_creation_data, &connections_submitted) catch |err| {
        return set_future_exception(err, socket_creation_data.future);
    };
}

// -----------------------------------------------------------------
// STEP#4: Socket connected (or failed to connect)

const SocketData = struct {
    connection_data: *SocketConnectionData,
    socket_fd: std.posix.fd_t
};

fn socket_connected_callback(
    data: ?*anyopaque, io_uring_res: i32, io_uring_err: std.os.linux.E
) CallbackManager.ExecuteCallbacksReturn {
    _ = data;
    _ = io_uring_res;
    _ = io_uring_err;

    return .Continue;
}

// -----------------------------------------------------------------
// STEP#5: Create transport and set future result

fn z_create_transport_and_set_future_result(data: *const TransportCreationData) !void {
    var transport_added_to_tuple: bool = false;
    var protocol_added_to_tuple: bool = false;

    const transport = try Stream.Constructors.new_stream_transport(
        data.protocol_factory, data.loop, data.socket_fd, data.zero_copying
    );
    errdefer {
        // PyTuple_SetItem steal reference
        if (!transport_added_to_tuple) {
            python_c.py_decref(@ptrCast(transport));
        }
    }

    const protocol = python_c.PyObject_CallNoArgs(data.protocol_factory) orelse return error.PythonError;
    errdefer {
        if (!protocol_added_to_tuple) {
            python_c.py_decref(protocol);
        }
    }

    const connection_made_func = python_c.PyObject_GetAttrString(protocol, "connection_made\x00")
        orelse return error.PythonError;
    defer python_c.py_decref(connection_made_func);

    const ret = python_c.PyObject_CallOneArg(connection_made_func, @ptrCast(transport))
        orelse return error.PythonError;
    defer python_c.py_decref(ret);

    const result_tuple = python_c.PyTuple_New(2) orelse return error.PythonError;
    errdefer python_c.py_decref(result_tuple);

    if (python_c.PyTuple_SetItem(result_tuple, 0, @ptrCast(transport)) != 0) {
        return error.PythonError;
    }
    transport_added_to_tuple = true;

    if (python_c.PyTuple_SetItem(result_tuple, 1, protocol) != 0) {
        return error.PythonError;
    }
    protocol_added_to_tuple = true;

    const future_data = utils.get_data_ptr(Future, data.future);
    Future.Python.Result.future_fast_set_result(future_data, result_tuple);
}

fn create_transport_and_set_future_result(
    data: *const CallbackManager.CallbackData
) !void {
    const transport_creation_data_ptr: *TransportCreationData = @alignCast(@ptrCast(data.user_data.?));

    const loop = transport_creation_data_ptr.loop;
    const loop_data = utils.get_data_ptr(Loop, loop);
    const allocator = loop_data.allocator;

    defer allocator.destroy(transport_creation_data_ptr);

    const transport_creation_data = transport_creation_data_ptr.*;
    defer {
        python_c.py_decref(transport_creation_data.protocol_factory);
        python_c.py_decref(@ptrCast(transport_creation_data.loop));
        python_c.py_decref(@ptrCast(transport_creation_data.future));

        if (transport_creation_data.fd_created) {
            std.posix.close(@intCast(transport_creation_data.socket_fd));
        }
    }
    if (data.cancelled) return;

    z_create_transport_and_set_future_result(&transport_creation_data) catch |err| {
        return set_future_exception(err, transport_creation_data.future);
    };
}

// -----------------------------------------------------------------

test "interleave_address_list with mixed IPv4 and IPv6" {
    const allocator = std.testing.allocator;
    const addresses = try allocator.alloc(std.net.Address, 5);
    defer allocator.free(addresses);

    addresses[0] = std.net.Address{ .any = .{ .family = std.posix.AF.INET, .data = undefined } };
    addresses[1] = std.net.Address{ .any = .{ .family = std.posix.AF.INET6, .data = undefined } };
    addresses[2] = std.net.Address{ .any = .{ .family = std.posix.AF.INET, .data = undefined } };
    addresses[3] = std.net.Address{ .any = .{ .family = std.posix.AF.INET6, .data = undefined } };
    addresses[4] = std.net.Address{ .any = .{ .family = std.posix.AF.INET, .data = undefined } };

    try interleave_address_list(allocator, addresses, 1);

    try std.testing.expectEqual(std.posix.AF.INET6, addresses[0].any.family);
    try std.testing.expectEqual(std.posix.AF.INET, addresses[1].any.family);
    try std.testing.expectEqual(std.posix.AF.INET6, addresses[2].any.family);
    try std.testing.expectEqual(std.posix.AF.INET, addresses[3].any.family);
    try std.testing.expectEqual(std.posix.AF.INET, addresses[4].any.family);
}

test "interleave_address_list with only IPv4" {
    const allocator = std.testing.allocator;
    const addresses = try allocator.alloc(std.net.Address, 3);
    defer allocator.free(addresses);

    addresses[0] = std.net.Address{ .any = .{ .family = std.posix.AF.INET, .data = undefined } };
    addresses[1] = std.net.Address{ .any = .{ .family = std.posix.AF.INET, .data = undefined } };
    addresses[2] = std.net.Address{ .any = .{ .family = std.posix.AF.INET, .data = undefined } };

    try interleave_address_list(allocator, addresses, 1);

    // Should remain unchanged
    try std.testing.expectEqual(std.posix.AF.INET, addresses[0].any.family);
    try std.testing.expectEqual(std.posix.AF.INET, addresses[1].any.family);
    try std.testing.expectEqual(std.posix.AF.INET, addresses[2].any.family);
}

test "interleave_address_list with only IPv6" {
    const allocator = std.testing.allocator;
    const addresses = try allocator.alloc(std.net.Address, 3);
    defer allocator.free(addresses);

    addresses[0] = std.net.Address{ .any = .{ .family = std.posix.AF.INET6, .data = undefined } };
    addresses[1] = std.net.Address{ .any = .{ .family = std.posix.AF.INET6, .data = undefined } };
    addresses[2] = std.net.Address{ .any = .{ .family = std.posix.AF.INET6, .data = undefined } };

    try interleave_address_list(allocator, addresses, 1);

    // Should remain unchanged
    try std.testing.expectEqual(std.posix.AF.INET6, addresses[0].any.family);
    try std.testing.expectEqual(std.posix.AF.INET6, addresses[1].any.family);
    try std.testing.expectEqual(std.posix.AF.INET6, addresses[2].any.family);
}

test "interleave_address_list with different interleave values" {
    const allocator = std.testing.allocator;
    const addresses = try allocator.alloc(std.net.Address, 5);
    defer allocator.free(addresses);

    addresses[0] = std.net.Address{ .any = .{ .family = std.posix.AF.INET, .data = undefined } };
    addresses[1] = std.net.Address{ .any = .{ .family = std.posix.AF.INET6, .data = undefined } };
    addresses[2] = std.net.Address{ .any = .{ .family = std.posix.AF.INET, .data = undefined } };
    addresses[3] = std.net.Address{ .any = .{ .family = std.posix.AF.INET6, .data = undefined } };
    addresses[4] = std.net.Address{ .any = .{ .family = std.posix.AF.INET, .data = undefined } };

    try interleave_address_list(allocator, addresses, 2);

    try std.testing.expectEqual(std.posix.AF.INET6, addresses[0].any.family);
    try std.testing.expectEqual(std.posix.AF.INET6, addresses[1].any.family);
    try std.testing.expectEqual(std.posix.AF.INET, addresses[2].any.family);
    try std.testing.expectEqual(std.posix.AF.INET, addresses[3].any.family);
    try std.testing.expectEqual(std.posix.AF.INET, addresses[4].any.family);
}

test "interleave_address_list with multiple IPv6 addresses and interleave value 2" {
    const allocator = std.testing.allocator;
    const addresses = try allocator.alloc(std.net.Address, 7);
    defer allocator.free(addresses);

    addresses[0] = std.net.Address{ .any = .{ .family = std.posix.AF.INET, .data = undefined } };
    addresses[1] = std.net.Address{ .any = .{ .family = std.posix.AF.INET6, .data = undefined } };
    addresses[2] = std.net.Address{ .any = .{ .family = std.posix.AF.INET, .data = undefined } };
    addresses[3] = std.net.Address{ .any = .{ .family = std.posix.AF.INET6, .data = undefined } };
    addresses[4] = std.net.Address{ .any = .{ .family = std.posix.AF.INET6, .data = undefined } };
    addresses[5] = std.net.Address{ .any = .{ .family = std.posix.AF.INET6, .data = undefined } };
    addresses[6] = std.net.Address{ .any = .{ .family = std.posix.AF.INET, .data = undefined } };

    try interleave_address_list(allocator, addresses, 2);

    try std.testing.expectEqual(std.posix.AF.INET6, addresses[0].any.family);
    try std.testing.expectEqual(std.posix.AF.INET6, addresses[1].any.family);
    try std.testing.expectEqual(std.posix.AF.INET, addresses[2].any.family);
    try std.testing.expectEqual(std.posix.AF.INET6, addresses[3].any.family);
    try std.testing.expectEqual(std.posix.AF.INET6, addresses[4].any.family);
    try std.testing.expectEqual(std.posix.AF.INET, addresses[5].any.family);
    try std.testing.expectEqual(std.posix.AF.INET, addresses[6].any.family);
}
