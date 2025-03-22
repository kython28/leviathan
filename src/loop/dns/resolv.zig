const std = @import("std");

const Loop = @import("../main.zig");
const CallbackManager = @import("callback_manager");

const Parsers = @import("parsers.zig");
const Cache = @import("cache.zig");

// TODO: Implement EDNS0 and DNSSEC

const DEFAULT_TIMEOUT: std.os.linux.kernel_timespec = .{
    .sec = 5,
    .nsec = 0,
};

const Header = packed struct {
    id: u16,
    flags: u16,
    qdcount: u16,
    ancount: u16,
    nscount: u16,
    arcount: u16,
};

const ResultHeader = packed struct {
    type: u16,
    class: u16,
    ttl: u32,
    data_len: u16,
};

const QuestionType = enum(u16) {
    ipv4 = 1,
    ipv6 = 28,
};

const QuestionTypeClass = packed struct {
    type: u16,
    class: u16,
};

const Hostname = struct {
    hostname: [255]u8,
    hostname_len: u8,
    original_hostname_len: u8,
};

const HostnamesArray = struct {
    array: []Hostname,
    len: u32,
    processed: u32 = 0,
};

pub const UserCallback = struct {
    callback: *const fn (?*anyopaque, ?[]const std.net.Address) void,
    user_data: ?*anyopaque,
};

const ResponseProcessingState = enum {
    process_header,
    process_body,
};

const ServerQueryData = struct {
    loop: *Loop,

    socket_fd: std.posix.fd_t,

    hostnames_array: HostnamesArray,

    control_data: *ControlData,

    payload: []u8,
    payload_len: usize,
    payload_offset: usize = 0,

    results: std.ArrayList(std.net.Address),
    results_to_process: u16 = 0,

    min_ttl: u32 = std.math.maxInt(u32),

    pub inline fn cancel(self: *ServerQueryData) void {
        const socket_fd = self.socket_fd;
        if (socket_fd >= 0) {
            std.posix.close(socket_fd);
            self.socket_fd = -1;
        }
    }

    pub fn release(self: *ServerQueryData) void {
        self.cancel();

        const control_data = self.control_data;
        control_data.tasks_finished += 1;

        const finalized = (control_data.tasks_finished == control_data.queries_data.len);
        if (finalized) {
            self.control_data.release();
        }
    }
};

pub const ControlData = struct {
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,

    record: *Cache.Record,

    user_callbacks: std.ArrayList(UserCallback),

    queries_data: []ServerQueryData,
    tasks_finished: usize = 0,
    resolved: bool = false,

    pub fn release(self: *ControlData) void {
        if (!self.resolved) {
            self.record.discard();

            for (self.user_callbacks.items) |*v| {
                v.callback(v.user_data, null);
            }
        }

        self.arena.deinit();
        self.allocator.destroy(self);
    }
};

fn cleanup_server_query_data(ptr: ?*anyopaque) void {
    const server_data: *ServerQueryData = @alignCast(@ptrCast(ptr.?));
    server_data.release();
}

fn mark_resolved_and_execute_user_callbacks(server_data: *ServerQueryData) !void {
    const control_data = server_data.control_data;
    control_data.resolved = true;
    errdefer control_data.resolved = false;

    for (control_data.queries_data) |*sd| {
        sd.cancel();
    }

    const address_list = try control_data.allocator.dupe(std.net.Address, server_data.results.items);

    control_data.record.set_resolved_data(
        address_list, server_data.min_ttl
    );

    for (control_data.user_callbacks.items) |*v| {
        v.callback(v.user_data, address_list);
    }

    server_data.release();
}

fn check_send_operation_result(data: *const CallbackManager.CallbackData) !void {
    const io_uring_err = data.io_uring_err;
    const io_uring_res = data.io_uring_res;

    const server_data: *ServerQueryData = @alignCast(@ptrCast(data.user_data.?));

    const control_data = server_data.control_data;
    if (io_uring_err != .SUCCESS or control_data.resolved or data.cancelled) {
        server_data.release();
        return;
    }

    const data_sent = server_data.payload_offset + @as(usize, @intCast(io_uring_res));
    server_data.payload_offset = data_sent;

    var operation_data: Loop.Scheduling.IO.BlockingOperationData = undefined;

    const payload_len = server_data.payload_len;
    if (data_sent == payload_len) {
        server_data.payload_offset = 0;
        server_data.payload_len = 0;

        operation_data = .{
            .PerformRead = .{
                .callback = .{
                    .func = &process_dns_response,
                    .cleanup = &cleanup_server_query_data,
                    .data = .{
                        .user_data = server_data,
                        .exception_context = null,
                    },
                },
                .data = .{
                    .buffer = server_data.payload,
                },
                .fd = server_data.socket_fd,
                .zero_copy = true,
                .timeout = DEFAULT_TIMEOUT,
            },
        };
    } else if (data_sent < payload_len) {
        operation_data = .{
            .PerformWrite = .{
                .callback = .{
                    .func = &check_send_operation_result,
                    .cleanup = &cleanup_server_query_data,
                    .data = .{
                        .user_data = server_data,
                        .exception_context = null,
                    },
                },
                .data = server_data.payload[data_sent..payload_len],
                .fd = server_data.socket_fd,
                .zero_copy = true,
                .timeout = DEFAULT_TIMEOUT,
            },
        };
    } else {
        unreachable; // Just in case hahah
    }

    _ = try server_data.loop.io.queue(operation_data);
}

fn parse_individual_dns_result(data: []const u8, result: *std.net.Address, new_result: *bool, ttl: *u32) ?usize {
    var offset: usize = 0;
    if (data[offset] & 0xC0 == 0xC0) {
        offset += 2;
    } else {
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

    const result_header: *const ResultHeader = @alignCast(@ptrCast(data.ptr + offset));
    offset += @sizeOf(ResultHeader);

    const r_type = std.mem.bigToNative(u16, result_header.type);
    const r_class = std.mem.bigToNative(u16, result_header.class);

    if (r_class == 1) {
        switch (r_type) {
            1 => {
                var addr: [4]u8 = undefined;
                @memcpy(&addr, data[offset..(offset + 4)]);
                result.* = std.net.Address.initIp4(addr, 0);
                new_result.* = true;
                ttl.* = std.mem.bigToNative(u32, result_header.ttl);
            },
            28 => {
                var addr: [16]u8 = undefined;
                @memcpy(&addr, data[offset..(offset + 16)]);
                result.* = std.net.Address.initIp6(addr, 0, 0, 0);
                new_result.* = true;
                ttl.* = std.mem.bigToNative(u32, result_header.ttl);
            },
            else => {},
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
        server_data.release();
        return;
    }

    const data_received = server_data.payload_len + @as(usize, @intCast(io_uring_res));
    server_data.payload_len = data_received;

    var offset = server_data.payload_offset;

    const hostnames_len = server_data.hostnames_array.len;
    var hostnames_processed = server_data.hostnames_array.processed;

    const response = server_data.payload;

    var results_to_process: u16 = server_data.results_to_process;

    var state: ResponseProcessingState = ResponseProcessingState.process_header;
    if (results_to_process > 0) {
        state = ResponseProcessingState.process_body;
    }

    loop: switch (state) {
        .process_header => while (hostnames_processed < hostnames_len) {
            const diff = (data_received - offset);
            if (diff < @sizeOf(Header)) {
                break;
            }

            const header: *const Header = @alignCast(@ptrCast(response.ptr + offset));
            const results_len: u16 = std.mem.bigToNative(u16, header.ancount);
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
            continue :loop ResponseProcessingState.process_body;
        },
        .process_body => while (results_to_process > 0) {
            var result: std.net.Address = undefined;
            var new_result: bool = true;
            var ttl: u32 = std.math.maxInt(u32);

            const new_offset = parse_individual_dns_result(
                response[offset..],
                &result,
                &new_result,
                &ttl,
            ) orelse break;

            offset = new_offset;
            if (new_result) {
                try server_data.results.append(result);
                server_data.min_ttl = @min(server_data.min_ttl, ttl);
            }

            results_to_process -= 1;
        },
    }
    server_data.payload_offset = offset;
    server_data.hostnames_array.processed = hostnames_processed;
    server_data.results_to_process = results_to_process;

    if (hostnames_processed == hostnames_len) {
        server_data.release();
    } else if (results_to_process > 0 or server_data.results.items.len == 0) {
        _ = try server_data.loop.io.queue(
            .{
                .PerformRead = .{
                    .data = .{
                        .buffer = response[offset..],
                    },
                    .fd = server_data.socket_fd,
                    .zero_copy = true,
                    .callback = .{
                        .func = &process_dns_response,
                        .cleanup = &cleanup_server_query_data,
                        .data = .{
                            .user_data = server_data,
                            .exception_context = null,
                        },
                    },
                    .timeout = DEFAULT_TIMEOUT,
                },
            },
        );
    } else {
        try mark_resolved_and_execute_user_callbacks(server_data);
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
        .arcount = 0,
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
        .type = std.mem.nativeToBig(u16, @intFromEnum(question)),
        .class = comptime std.mem.nativeToBig(u16, 1),
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
    server_address: *const std.net.Address,
) !void {
    const socket_fd = try std.posix.socket(
        server_address.any.family,
        std.posix.SOCK.DGRAM | std.posix.SOCK.CLOEXEC,
        std.posix.IPPROTO.UDP,
    );
    errdefer std.posix.close(socket_fd);

    try std.posix.connect(socket_fd, &server_address.any, server_address.getOsSockLen());

    const payload = try allocator.alloc(u8, (1 + @as(usize, @intFromBool(ipv6_supported))) * 512 * hostnames_array.len);
    errdefer allocator.free(payload);

    var offset: usize = 0;
    for (0.., hostnames_array.array[0..hostnames_array.len]) |index, hostname_info| {
        const hostname = hostname_info.hostname[0..hostname_info.hostname_len];
        offset += build_query(@intCast(index), payload[offset..], .ipv4, hostname);

        if (ipv6_supported) {
            offset += build_query(@intCast(index), payload[offset..], .ipv6, hostname);
        }
    }

    server_data.* = .{
        .loop = loop,

        .payload = payload,

        .socket_fd = socket_fd,
        .payload_len = offset,

        .control_data = control_data,
        .hostnames_array = hostnames_array,

        .results = std.ArrayList(std.net.Address).init(allocator),
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
    } else {
        data.hostname_len = @intCast(hostname.len);
    }

    return true;
}

fn get_hostname_array(allocator: std.mem.Allocator, hostname: []const u8, suffixes: []const []const u8) !HostnamesArray {
    const total: usize = suffixes.len + 1;
    var hostnames_array = HostnamesArray{ .array = try allocator.alloc(Hostname, total), .len = 0 };
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
    cache_slot: *Cache,
    loop: *Loop,
    hostname: []const u8,
    user_callback: *const UserCallback,
    configuration: Parsers.Configuration,
    ipv6_supported: bool,
) !*ControlData {
    const allocator = cache_slot.allocator;

    const control_data = try allocator.create(ControlData);
    errdefer allocator.destroy(control_data);

    control_data.allocator = allocator;
    control_data.arena = std.heap.ArenaAllocator.init(allocator);
    const arena_allocator = control_data.arena.allocator();

    control_data.user_callbacks = std.ArrayList(UserCallback).init(arena_allocator);
    control_data.record = try cache_slot.create_new_record(hostname, control_data);

    control_data.resolved = false;
    control_data.tasks_finished = 0;
    errdefer {
        control_data.release();
    }

    try control_data.user_callbacks.append(user_callback.*);
    errdefer control_data.user_callbacks.clearRetainingCapacity();

    const queries_data = try arena_allocator.alloc(ServerQueryData, configuration.servers.len);
    const hostnames_array = try get_hostname_array(arena_allocator, hostname, configuration.search);

    control_data.queries_data = queries_data;

    var queries_built: usize = 0;
    errdefer {
        for (queries_data[0..queries_built]) |*server_data| {
            std.posix.close(server_data.socket_fd);
        }
    }

    for (configuration.servers, queries_data) |*server_address, *server_data| {
        try build_queries(
            arena_allocator,
            loop,
            control_data,
            server_data,
            ipv6_supported,
            hostnames_array,
            server_address,
        );

        queries_built += 1;
    }

    return control_data;
}

pub fn queue(
    cache_slot: *Cache,
    loop: *Loop,
    hostname: []const u8,
    user_callback: *const UserCallback,
    configuration: Parsers.Configuration,
    ipv6_supported: bool,
) !void {
    const control_data = try prepare_data(
        cache_slot,
        loop,
        hostname,
        user_callback,
        configuration,
        ipv6_supported,
    );

    var queries_sent: usize = 0;
    errdefer {
        for (control_data.queries_data[0..queries_sent]) |*server_data| {
            server_data.cancel();
        }

        if (queries_sent == 0) {
            control_data.release();
        }
    }

    for (control_data.queries_data) |*server_data| {
        _ = try loop.io.queue(.{
            .PerformWrite = .{
                .zero_copy = true,
                .fd = server_data.socket_fd,
                .data = server_data.payload[0..server_data.payload_len],
                .callback = .{
                    .func = &check_send_operation_result,
                    .cleanup = &cleanup_server_query_data,
                    .data = .{
                        .user_data = server_data,
                        .exception_context = null,
                    },
                },
                .timeout = DEFAULT_TIMEOUT,
            },
        });

        queries_sent += 1;
    }
}
