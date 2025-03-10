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
    callback: *const fn (?*anyopaque, ?std.posix.sockaddr) anyerror!void,
    user_data: ?*anyopaque
};

const ControlData = struct {
    user_callback: UserCallback,
    blocking_task_id: []usize,
    tasks_finished: usize = 0,
    resolved: bool = false,
};

const ResponseStep = enum {
    ReadingHeader, ReadingResult
};

const ServerQueryData = struct {
    allocator: std.mem.Allocator,

    loop: *Loop,
    dns: *DNS,

    address: *const std.posix.sockaddr,
    socket_fd: std.posix.fd_t,

    hostnames_array: HostnamesArray,

    control_data: *ControlData,
    task_id: *usize,

    payload: []u8,
    payload_len: usize,
    payload_bytes_sent: usize = 0,

    response: []u8,
    response_bytes_received: usize,
    response_offset: usize = 0,
    response_step: ResponseStep,

    results: []std.posix.sockaddr,
    result_offset: u16,
};

fn acquire_and_execute_callback(control_data: *ControlData, result: ?std.posix.sockaddr) !void {
    control_data.resolved = true;


}

fn release_server_query_resources(data: *ServerQueryData) !void {
    const allocator = data.allocator;

    const control_data = data.control_data;
    var user_callback: ?UserCallback = null;

    control_data.tasks_finished += 1;

    if (control_data.tasks_finished == control_data.blocking_task_id.len) {
        if (!control_data.resolved) {
            user_callback = control_data.user_callback;
        }
        allocator.free(control_data.blocking_task_id);
        allocator.destroy(control_data);

        allocator.free(data.hostnames_array.array);
    }

    std.posix.close(data.socket_fd);
    allocator.free(data.payload);
    allocator.free(data.results);
    allocator.destroy(data);

    if (user_callback) |v| {
        try v.callback(v.user_data, null);
    }
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
                    .cleanup = null,
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
                    .cleanup = null
                },
                .data = server_data.payload[data_sent..payload_len],
                .fd = server_data.socket_fd,
                .zero_copy = true
            }
        };
    }

    const new_task_id = Loop.Scheduling.IO.queue(server_data.loop, operation_data) catch |err| {
        release_server_query_resources(server_data) catch |err2| return err2;
        return err;
    };

    server_data.task_id.* = new_task_id;
}

inline fn parse_result(data: []const u8) ?usize {
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
            1 => {},
            28 => {},
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
        try release_server_query_resources(server_data);
        return;
    }

    const data_received = server_data.response_bytes_received + @as(usize, @intCast(io_uring_res));
    var offset = server_data.response_offset;

    const hostnames_len = server_data.hostnames_array.len;

    var hostnames_processed = server_data.hostnames_array.processed;
    defer server_data.hostnames_array.processed = hostnames_processed;

    var response_step = server_data.response_step;
    defer server_data.response_step = response_step;

    const finished: bool = blk: while (hostnames_processed < hostnames_len) {
        switch (response_step) {
            .ReadingHeader => {
                const diff = (data_received - offset);
                if (diff < @sizeOf(Header)) {
                    break :blk false;
                }

                const header: *Header = server_data.response[offset..(offset + @sizeOf(Header))];
                if (header.ancount == 0) {
                    hostnames_processed += 1;
                    offset += @sizeOf(Header);
                    if (diff >= 2*@sizeOf(Header)) {
                        continue :blk;
                    }
                    break :blk false;
                }

                response_step = .ReadingResult;
                continue :blk;
            },
            .ReadingResponse => {

            }
        }
    };


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
    loop: *Loop,
    hostname: []const u8,
    user_callback: UserCallback,
    configuration: Parsers.Configuration
) !void {
    const allocator = loop.allocator;
    const hostnames_array = try get_hostname_array(allocator, hostname, configuration.search);
    errdefer allocator.free(hostnames_array.array);

    const control_data = try allocator.create(ControlData);
    errdefer allocator.destroy(control_data);

    control_data.* = .{
        .user_callback = user_callback
    };
}
