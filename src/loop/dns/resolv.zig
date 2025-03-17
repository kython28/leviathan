const std = @import("std");

const Loop = @import("../main.zig");
const CallbackManager = @import("callback_manager");

const Parsers = @import("parsers.zig");
const DNS = @import("main.zig");
const Cache = @import("cache.zig");

// TODO: Implement EDNS0 and DNSSEC

const TIMEOUT: std.os.linux.kernel_timespec = .{
    .sec = 5,
    .nsec = 0
};

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
    process_header, process_body
};

const ServerQueryData = struct {
    loop: *Loop,

    address: *const std.posix.sockaddr,
    socket_fd: std.posix.fd_t,

    hostnames_array: HostnamesArray,

    control_data: *ControlData,

    payload: []u8,
    payload_len: usize,
    payload_offset: usize = 0,

    results: std.ArrayList(std.posix.sockaddr),
    results_to_process: u16 = 0,

    min_ttl: u32 = std.math.maxInt(u32),

    pub fn release(self: *ServerQueryData) bool {
        const socket_fd = self.socket_fd;
        if (socket_fd >= 0) {
            std.posix.close(socket_fd);
            self.socket_fd = -1;
        }

        const control_data = self.control_data;
        control_data.tasks_finished += 1;

        return (control_data.tasks_finished == control_data.queries_data.len);
    }
};

pub const ControlData = struct {
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,

    dns: *DNS,
    record: *Cache.Record,

    user_callbacks: std.ArrayList(UserCallback),

    queries_data: []ServerQueryData,
    tasks_finished: usize = 0,
    resolved: bool = false,

    pub fn release(self: *ControlData) void {
        if (!self.resolved) {
            self.record.discard();
        }

        self.arena.deinit();
        self.allocator.destroy(self);
    }
};

fn cleanup_controldata(ptr: ?*anyopaque) void {
    const control_data: *ControlData = @alignCast(@ptrCast(ptr.?));
    control_data.release();
}

fn cleanup_server_query_data(ptr: ?*anyopaque) void {
    const server_data: *ServerQueryData = @alignCast(@ptrCast(ptr.?));
    const last_one = server_data.release();

    if (last_one) {
        server_data.control_data.release();
    }
}

fn acquire_and_execute_callback(server_data: *ServerQueryData) !void {
    const control_data = server_data.control_data;
    control_data.resolved = true;
    errdefer control_data.resolved = false;

    for (control_data.queries_data) |*sd| {
        const socket_fd = sd.socket_fd;
        if (sd == server_data or socket_fd < 0) continue;

        std.posix.close(socket_fd);
        sd.socket_fd = -1;
    }

    const address_list = try control_data.allocator.dupe(server_data.results.items);
    {
        errdefer control_data.allocator.free(address_list);

        const hostname_info = &server_data.hostnames_array.array[0];
        try control_data.dns.add_to_cache(
            hostname_info.hostname[0..hostname_info.original_hostname_len],
            address_list, server_data.min_ttl
        );
    }

    control_data.user_callbacks_called = true;
    const user_callback = control_data.user_callbacks;
    try user_callback.callback(user_callback.user_data, address_list);

    try release_server_query_resources(server_data);
}

// fn release_server_query_resources(data: ?*anyopaque) !void {
//     const server_data: *ServerQueryData = @alignCast(@ptrCast(data.?));

//     const socket_fd = server_data.socket_fd;
//     if (socket_fd >= 0) {
//         std.posix.close(socket_fd);
//         server_data.socket_fd = -1;
//     }

//     const control_data = server_data.control_data;
//     control_data.tasks_finished += 1;

//     if (control_data.tasks_finished < control_data.queries_data.len) {
//         return;
//     }

//     if (!control_data.user_callbacks_called) {
//         for (control_data.user_callbacks.items) |*v| {
//             try v.callback(v.user_data, null);
//         }
//     }

//     control_data.arena.deinit();
//     control_data.allocator.destroy(control_data);
// }

// fn execute_user_callbacks(data: *const CallbackManager.CallbackData) !void {

// }

fn check_send_operation_result(data: *const CallbackManager.CallbackData) !void {
    const io_uring_err = data.io_uring_err;
    const io_uring_res = data.io_uring_res;

    const server_data: *ServerQueryData = @alignCast(@ptrCast(data.user_data.?));

    const control_data = server_data.control_data;
    if (io_uring_err != .SUCCESS or control_data.resolved or data.cancelled) {
        try release_server_query_resources(server_data);
        return;
    }

    const data_sent = server_data.payload_offset + @as(usize, @intCast(io_uring_res));
    server_data.payload_offset = data_sent;

    const payload_len = server_data.payload_len;

    var operation_data: Loop.Scheduling.IO.BlockingOperationData = undefined;

    if (data_sent == payload_len) {
        server_data.payload_offset = 0;
        server_data.payload_len = 0;

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
                    .buffer = server_data.payload
                },
                .fd = server_data.socket_fd,
                .zero_copy = true,
                .timeout = TIMEOUT
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
                .zero_copy = true,
                .timeout = TIMEOUT
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
    if (io_uring_err != .SUCCESS or control_data.resolved or data.cancelled) {
        try release_server_query_resources(server_data);
        return;
    }

    const data_received = server_data.payload_len + @as(usize, @intCast(io_uring_res));
    defer server_data.payload_len = data_received;

    var offset = server_data.payload_offset;
    defer server_data.payload_offset = offset;

    const hostnames_len = server_data.hostnames_array.len;
    var hostnames_processed = server_data.hostnames_array.processed;
    defer server_data.hostnames_array.processed = hostnames_processed;

    const response = server_data.payload;

    var results_to_process: u16 = server_data.results_to_process;
    defer server_data.results_to_process = results_to_process;

    var state: ResponseProcessingState = ResponseProcessingState.process_header;
    if (results_to_process > 0) {
        state = ResponseProcessingState.process_body;
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

            const new_offset = parse_individual_dns_result(response[offset..], &result, &new_result, &ttl) orelse break;

            offset = new_offset;
            if (new_result) {
                try server_data.results.append(result);
                server_data.min_ttl = @min(server_data.min_ttl, ttl);
            }

            results_to_process -= 1;
        }
    }

    if (hostnames_processed == hostnames_len) {
        try release_server_query_resources(server_data);
    }else if (results_to_process > 0 or server_data.results.items.len == 0) {
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
                    },
                    .timeout = TIMEOUT
                }
            }
        );
    }else{
        try acquire_and_execute_callback(server_data);
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

fn build_queries(
    allocator: std.mem.Allocator,
    loop: *Loop,
    control_data: *ControlData,
    server_data: *ServerQueryData,
    ipv6_supported: bool,
    hostnames_array: HostnamesArray,
    server_address: *const std.posix.sockaddr,
) !void {
    const socket_fd = try std.posix.socket(
        @enumFromInt(server_address.family), std.posix.SOCK.DGRAM|std.posix.SOCK.CLOEXEC,
        std.posix.IPPROTO.UDP
    );
    errdefer std.posix.close(socket_fd);

    try std.posix.connect(socket_fd, server_address, switch (server_address.family) {
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
            offset += build_query(@intCast(index), payload[offset..], .ipv6, hostname_info.hostname);
        }
    }

    server_data.* = .{
        .loop = loop,

        .payload = payload,
        .address = server_address,

        .socket_fd = socket_fd,
        .payload_len = offset,

        .control_data = control_data,
        .hostnames_array = hostnames_array,

        .results = std.ArrayList(std.posix.sockaddr).init(allocator),
    };
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

fn prepare_data(
    dns: *DNS,
    hostname: []const u8,
    user_callback: UserCallback,
    configuration: Parsers.Configuration
) !*ControlData {
    const allocator = dns.allocator;

    const control_data = try allocator.create(ControlData);
    errdefer allocator.destroy(control_data);

    control_data.* = .{
        .allocator = allocator,
        .arena = std.heap.ArenaAllocator.init(allocator),
        .dns = dns,
        .user_callbacks = std.ArrayList(UserCallback).init(allocator),
        .queries_data = undefined,
        .timeout_task_id = 0,
    };
    errdefer {
        control_data.user_callbacks.deinit();
        control_data.arena.deinit();
    }

    try control_data.user_callbacks.append(user_callback);

    const arena_allocator = control_data.arena.allocator();

    const queries_data = try arena_allocator.alloc(ServerQueryData, configuration.servers.len);
    const hostnames_array = try get_hostname_array(arena_allocator, hostname, configuration.search);

    const ipv6_supported = dns.ipv6_supported;
    control_data.queries_data = queries_data;

    var queries_built: usize = 0;
    errdefer {
        for (queries_data[0..queries_built]) |*server_data| {
            std.posix.close(server_data.socket_fd);
        }
    }

    const loop = dns.loop;
    for (configuration.servers, queries_data) |*server_address, *server_data| {
        try build_queries(
            arena_allocator, loop, control_data, server_data, ipv6_supported, hostnames_array, server_address
        );

        queries_built += 1;
    }

    return control_data;
}

pub fn resolv(
    dns: *DNS,
    hostname: []const u8,
    user_callback: UserCallback,
    configuration: Parsers.Configuration
) !void {
    const control_data = try prepare_data(dns, hostname, user_callback, configuration);

    var queries_sent: usize = 0;
    errdefer {
        for (control_data.queries_data[0..queries_sent]) |*server_data| {
            std.posix.close(server_data.socket_fd);
            server_data.socket_fd = -1;
        }

        if (queries_sent == 0) {
            control_data.arena.deinit();
            control_data.allocator.destroy(control_data);
        }
    }

    const loop = dns.loop;
    for (control_data.queries_data) |*server_data| {
        _ = try Loop.Scheduling.IO.queue(
            loop, .{
                .PerformWrite = .{
                    .zero_copy = true,
                    .fd = server_data.socket_fd,
                    .data = server_data.payload[0..server_data.payload_len],
                    .callback = .{
                        .func = &check_send_operation_result,
                        .cleanup = &release_server_query_resources,
                        .data = .{
                            .user_data = server_data,
                            .exception_context = null
                        }
                    },
                    .timeout = TIMEOUT
                }
            }
        );

        queries_sent += 1;
    }
}
