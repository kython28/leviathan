const std = @import("std");

const Loop = @import("../main.zig");
const CallbackManager = @import("callback_manager");

const Parsers = @import("parsers.zig");
const DNS = @import("main.zig");

// TODO: Implement EDNS0 and DNSSEC

const Header = packed struct {
    id: u16,
    flags: u16,
    qdcount: u16,
    ancount: u16,
    nscount: u16,
    arcount: u16
};

const ResultHeader = packed struct {
    @"type": u16,
    class: u16,
    ttl: u32,
    data_len: u16
};

const QuestionType = enum(u16) {
    ipv4 = 1,
    ipv6 = 28
};

const QuestionTypeClass = packed struct {
    @"type": u16,
    class: u16
};

const Hostname = struct {
    hostname: [255]u8,
    hostname_len: u8,
    original_hostname_len: u8,
};

const HostnamesArray = struct {
    array: []Hostname,
    len: u32,
    processed: u32 = 0
};

pub const UserCallback = struct {
    callback: *const fn (?*anyopaque, ?[]const std.posix.sockaddr) anyerror!void,
    user_data: ?*anyopaque
};


const ResponseProcessingState = enum {
    ProcessHeader, ProcessBody
};

const ServerQueryData = struct {
    loop: *Loop,

    address: *const std.posix.sockaddr,
    socket_fd: std.posix.fd_t,

    hostnames_array: HostnamesArray,

    control_data: *ControlData,

    payload: []u8,
    payload_len: usize,
    payload_bytes_sent: usize = 0,

    response: []u8,
    response_bytes_received: usize,
    response_offset: usize = 0,

    results: std.ArrayList(std.posix.sockaddr),
    results_to_process: u16,

    min_ttl: u32 = std.math.maxInt(u32),
};

const ControlData = struct {
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,

    dns: *DNS,

    user_callback: UserCallback,
    user_callback_called: bool = false,


    queries_data: []ServerQueryData,
    tasks_finished: usize = 0,
    resolved: bool = false,
};

fn acquire_and_execute_callback(
    server_data: *ServerQueryData,
    results: []const std.posix.sockaddr,
    min_ttl: u32
) !void {
    const control_data = server_data.control_data;
    control_data.resolved = true;

    for (control_data.queries_data) |*sd| {
        const socket_fd = sd.socket_fd;
        if (sd == server_data or socket_fd < 0) continue;

        std.posix.close(socket_fd);
        sd.socket_fd = -1;
    }

    const hostname_info = &server_data.hostnames_array.array[0];
    try control_data.dns.add_to_cache(
        hostname_info.hostname[0..hostname_info.original_hostname_len],
        results, min_ttl
    );

    control_data.user_callback_called = true;
    const user_callback = control_data.user_callback;
    user_callback.callback(user_callback.user_data, results);

    try release_server_query_resources(server_data);
}

fn release_server_query_resources(data: ?*anyopaque) !void {
    const server_data: *ServerQueryData = @alignCast(@ptrCast(data.?));

    const socket_fd = server_data.socket_fd;
    if (socket_fd > 0) {
        std.posix.close(socket_fd);
        server_data.socket_fd = -1;
    }

    const control_data = server_data.control_data;
    control_data.tasks_finished += 1;

    if (control_data.tasks_finished < control_data.blocking_task_id.len) {
        return;
    }

    if (!control_data.user_callback_called) {
        const user_callback = control_data.user_callback;
        try user_callback.callback(user_callback.user_data, null);
    }

    control_data.arena.deinit();
    control_data.allocator.destroy(control_data);
}

fn check_send_operation_result(data: *const CallbackManager.CallbackData) !void {
    const io_uring_err = data.io_uring_err;
    const io_uring_res = data.io_uring_res;

    const server_data: *ServerQueryData = @alignCast(@ptrCast(data.user_data.?));

    const control_data = server_data.control_data;
    if (io_uring_err != .SUCCESS or control_data.resolved) {
        try release_server_query_resources(server_data);
        return;
    }

    const data_sent = server_data.payload_bytes_sent + @as(usize, @intCast(io_uring_res));
    server_data.payload_bytes_sent = data_sent;

    const payload_len = server_data.payload_len;

    var operation_data: Loop.Scheduling.IO.BlockingOperationData = undefined;

    if (data_sent == payload_len) {
        operation_data = .{
            .PerformRead = .{
                .callback = .{
                    .func = &process_dns_response,
                    .cleanup = &release_server_query_resources,
                    .data = .{
                        .user_data = server_data,
                        .exception_context = null
                    }
                },
                .data = .{
                    .buffer = server_data.response
                },
                .fd = server_data.socket_fd,
                .zero_copy = true,
            }
        };
    }else{
        operation_data = .{
            .PerformWrite = .{
                .callback = .{
                    .func = &check_send_operation_result,
                    .data = .{
                        .user_data = server_data,
                        .exception_context = null
                    },
                    .cleanup = &release_server_query_resources
                },
                .data = server_data.payload[data_sent..payload_len],
                .fd = server_data.socket_fd,
                .zero_copy = true
            }
        };
    }

    _  = try Loop.Scheduling.IO.queue(server_data.loop, operation_data);
}

fn parse_individual_dns_result(data: []const u8, result: *std.posix.sockaddr, new_result: *bool, ttl: *u32) ?usize {
    var offset: usize = 0;
    if (data[offset]&0xC0 == 0xC0) {
        offset += 2;
    }else{
        while (true) {
            if (offset >= data.len) {
                return null;
            }

            const lenght = data[offset];
            if (lenght == 0) {
                offset += 1;
                break;
            }

            offset += @intCast(lenght + 1);
        }
    }

    if ((offset + @sizeOf(ResultHeader)) >= data.len) return null;

    const result_header: *ResultHeader = @alignCast(@ptrCast(data.ptr + offset));
    offset += @sizeOf(ResultHeader);

    const r_type = std.mem.bigToNative(u16, result_header.@"type");
    const r_class = std.mem.bigToNative(u16, result_header.class);

    if (r_class == 1) {
        switch (r_type) {
            1 => {
                const sockaddr_in: *std.posix.sockaddr.in = @ptrCast(result);
                sockaddr_in.* = .{
                    .addr = @as(*align(1) const u32, @ptrCast(data.ptr + offset)),
                    .port = 0
                };
                new_result.* = true;
                ttl.* = std.mem.bigToNative(u32, result_header.ttl);
            },
            28 => {
                const sockaddr_in6: *std.posix.sockaddr.in6 = @ptrCast(result);
                sockaddr_in6.* = std.posix.sockaddr.in6{
                    .addr = undefined,
                    .port = 0,
                    .flowinfo = 0,
                    .scope_id = 0
                };
                @memcpy(&sockaddr_in6.addr, data[offset..(offset + 16)]);
                new_result.* = true;
                ttl.* = std.mem.bigToNative(u32, result_header.ttl);
            },
            else => {}
        }
    }

    return offset + @as(usize, @intCast(std.mem.bigToNative(u16, result_header.data_len)));
}

fn process_dns_response(data: *const CallbackManager.CallbackData) !void {
    const io_uring_err = data.io_uring_err;
    const io_uring_res = data.io_uring_res;

    const server_data: *ServerQueryData = @alignCast(@ptrCast(data.user_data.?));

    const control_data = server_data.control_data;
    if (io_uring_err != .SUCCESS or control_data.resolved) {
        release_server_query_resources(server_data);
        return;
    }

    const data_received = server_data.response_bytes_received + @as(usize, @intCast(io_uring_res));
    var offset = server_data.response_offset;

    const hostnames_len = server_data.hostnames_array.len;

    var hostnames_processed = server_data.hostnames_array.processed;
    defer server_data.hostnames_array.processed = hostnames_processed;

    const response = server_data.response;

    var results_to_process: u16 = server_data.results_to_process;
    defer server_data.results_to_process = results_to_process;

    var state: ResponseProcessingState = ResponseProcessingState.ProcessHeader;
    if (results_to_process > 0) {
        state = ResponseProcessingState.ProcessBody;
    }

    loop: switch (state) {
        .ProcessHeader => while (hostnames_processed < hostnames_len) {
            const diff = (data_received - offset);
            if (diff < @sizeOf(Header)) {
                break;
            }

            const header: *Header = response[offset..(offset + @sizeOf(Header))];
            const results_len: u16 = std.mem.bigToNative(header.ancount);
            offset += @sizeOf(Header);

            // Check if there aren't results
            if (results_len == 0) {
                hostnames_processed += 1;
                continue;
            }

            // Skip query domain
            while (true) {
                const length = response[offset];
                if (length == 0) break;

                offset += @intCast(length + 1);
            }

            offset += 5; // Skip some stuffs
            results_to_process = results_len;
            continue :loop ResponseProcessingState.ProcessBody;
        },
        .ProcessBody => while (results_to_process > 0) {
            var result: std.posix.sockaddr = undefined;
            var new_result: bool = true;
            var ttl: u32 = std.math.maxInt(u32);

            if (parse_individual_dns_result(response[offset..], &result, &new_result, &ttl)) |new_offset| {
                offset = new_offset;
                if (new_result) {
                    try server_data.results.append(result);
                    server_data.min_ttl = @min(server_data.min_ttl, ttl);
                }

                results_to_process -= 1;
                continue;
            }

            break :loop;
        } else {
            hostnames_processed += 1;
            continue :loop ResponseProcessingState.ProcessHeader;
        }
    }

    if (hostnames_processed < hostnames_len) {
        server_data.task_id.* = try Loop.Scheduling.IO.queue(
            server_data.loop, .{
                .PerformRead = .{
                    .data = .{
                        .buffer = response[offset..],
                    },
                    .fd = server_data.socket_fd,
                    .zero_copy = true,
                    .callback = .{
                        .func = &process_dns_response,
                        .data = .{
                            .user_data = server_data,
                            .exception_context = null
                        },
                        .cleanup = &release_server_query_resources
                    }
                }
            }
        );
        return;
    }



}

fn build_query(id: u16, payload: []u8, question: QuestionType, hostname: []const u8) usize {
    const header: *Header = @alignCast(@ptrCast(payload.ptr));
    header.* = .{
        .id = id,
        .flags = comptime std.mem.nativeToBig(u16, 0x0100),
        .qdcount = comptime std.mem.nativeToBig(u16, 1),
        .ancount = 0,
        .nscount = 0,
        .arcount = 0
    };

    const encode_domain_buf = payload[@sizeOf(Header)..(@sizeOf(Header) + hostname.len + 2)];
    var labels_iter = std.mem.tokenizeScalar(u8, hostname, '.');
    var offset: usize = 0;

    while (labels_iter.next()) |label| {
        encode_domain_buf[offset] = @intCast(label.len);

        const off = offset + 1;
        const new_off = off + label.len;
        @memcpy(encode_domain_buf[off..new_off], label);

        offset = new_off;
    }
    encode_domain_buf[offset] = 0;

    const question_type_class: *QuestionTypeClass = @alignCast(@ptrCast(encode_domain_buf.ptr + encode_domain_buf.len));
    question_type_class.* = .{
        .@"type" = std.mem.nativeToBig(u16, @intFromEnum(question)),
        .class = comptime std.mem.nativeToBig(u16, 1)
    };

    return @intFromPtr(question_type_class) + @sizeOf(QuestionTypeClass);
}

fn send_queries_to_server(
    loop: *Loop,
    ipv6_supported: bool,
    allocator: std.mem.Allocator,
    hostnames_array: HostnamesArray,
    server: *const std.posix.sockaddr,
    control_data: *ControlData
) !void {
    const socket_fd = try std.posix.socket(
        @enumFromInt(server.family), std.posix.SOCK.DGRAM|std.posix.SOCK.CLOEXEC,
        std.posix.IPPROTO.UDP
    );
    errdefer std.posix.close(socket_fd);

    try std.posix.connect(socket_fd, server, switch (server.family) {
        std.posix.AF.INET => @sizeOf(std.posix.sockaddr.in),
        std.posix.AF.INET6 => @sizeOf(std.posix.sockaddr.in6),
        else => unreachable
    });

    const payload = try allocator.alloc(u8, 2 * 512 * hostnames_array.len);
    errdefer allocator.free(payload);

    var offset: usize = 0;

    for (0.., hostnames_array.array[0..hostnames_array.len]) |index, hostname_info| {
        offset += build_query(@intCast(index), payload[offset..], .ipv4, hostname_info.hostname);
        
        if (ipv6_supported) {
            offset += build_query(@intCast(index), payload[offset..], .ipv4, hostname_info.hostname);
        }
    }


}

inline fn build_hostname(data: *Hostname, hostname: []const u8, suffix: []const u8) bool {
    const new_len = hostname.len + suffix.len + 1;
    if (new_len > 255) {
        return false;
    }

    @memcpy(data.hostname[0..hostname.len], hostname);
    data.original_hostname_len = @intCast(hostname.len);

    if (suffix.len > 0) {
        data.hostname[hostname.len] = '.';
        @memcpy(data.hostname[(hostname.len + 1)..new_len], suffix);
        data.hostname_len = @intCast(new_len);
    }else{
        data.hostname_len = @intCast(hostname.len);
    }

    return true;
}

fn get_hostname_array(
    allocator: std.mem.Allocator,
    hostname: []const u8,
    suffixes: []const []const u8
) !HostnamesArray {
    const total: usize = suffixes.len + 1;
    var hostnames_array = HostnamesArray{
        .array = try allocator.alloc(Hostname, total),
        .len = 0
    };
    errdefer allocator.free(hostnames_array.array);

    if (std.mem.indexOfScalar(u8, hostname, '.')) |_| {
        if (build_hostname(&hostnames_array.array[hostnames_array.len], hostname, &.{})) {
            hostnames_array.len += 1;
        }
    }

    for (suffixes) |suffix| {
        if (build_hostname(&hostnames_array.array[hostnames_array.len], hostname, suffix)) {
            hostnames_array.len += 1;
        }
    }

    return hostnames_array;
}

pub fn resolv_hostname(
    dns: *DNS,
    loop: *Loop,
    hostname: []const u8,
    user_callback: UserCallback,
    configuration: Parsers.Configuration
) !void {
    const allocator = loop.allocator;

    const control_data = try allocator.create(ControlData);
    errdefer allocator.destroy(control_data);

    control_data.* = .{
        .allocator = allocator,
        .arena = std.heap.ArenaAllocator.init(allocator),
        .dns = dns,
        .user_callback = user_callback,
        .queries_data = undefined
    };
    errdefer control_data.arena.deinit();

    const arena_allocator = control_data.arena.allocator();

    const queries_data = try arena_allocator.alloc(ServerQueryData, configuration.servers.len);

    const hostnames_array = try get_hostname_array(arena_allocator, hostname, configuration.search);
    errdefer allocator.free(hostnames_array.array);

    const ipv6_supported = dns.ipv6_supported;

    var queries_sent: usize = 0;
    for (configuration.servers) |*server| {
        try send_queries_to_server(loop, ipv6_supported, arena_allocator, hostnames_array, server, control_data);
        queries_sent += 1;
    }
}
