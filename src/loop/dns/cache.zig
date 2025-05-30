const std = @import("std");

const utils = @import("utils");

const Resolv = @import("resolv.zig");
const CallbackManager = @import("callback_manager");

const RecordState = union(enum) {
    pending: *Resolv.ControlData,
    resolved: []std.net.Address,
    none,
};

pub const Record = struct {
    hostname: []u8,
    state: RecordState,
    expire_at: i64,

    pub inline fn get_address_list(self: *Record) ?[]const std.net.Address {
        return switch (self.state) {
            .pending => null,
            .resolved => |d| d,
            .none => @panic("Attempt to get data from empty record") // Read `get` Cache's method
        };
    }

    pub inline fn append_callback(self: *Record, user_callback: *const CallbackManager.Callback) !void {
        try self.state.pending.user_callbacks.append(user_callback.*);
    }

    pub inline fn set_resolved_data(self: *Record, address_list: []std.net.Address, ttl: u32) void {
        var expire_at: i64 = std.math.maxInt(i64);
        if (ttl < std.math.maxInt(u32)) {
            expire_at = std.time.timestamp() + ttl;
        }

        self.expire_at = expire_at;
        self.state = .{
            .resolved = address_list
        };
    }

    pub inline fn discard(self: *Record) void {
        self.state = .none;
        self.expire_at = 0;
    }
};

const RecordLinkedList = utils.LinkedList(Record);

allocator: std.mem.Allocator,
records_list: RecordLinkedList,

pub fn init(self: *Cache, allocator: std.mem.Allocator) void {
    self.records_list = RecordLinkedList.init(allocator);
}

pub fn create_new_record(self: *Cache, hostname: []const u8, control_data: *Resolv.ControlData) !*Record {
    const allocator = self.allocator;
    const new_hostname = try allocator.dupe(u8, hostname);
    errdefer allocator.free(new_hostname);

    const new_record = Record{
        .hostname = new_hostname,
        .expire_at = std.math.maxInt(i64),
        .state = .{
            .pending = control_data
        }
    };

    const new_node = try self.records_list.create_new_node(new_record);
    self.records_list.append_node(new_node);
    return &new_node.data;
}

pub fn get(self: *Cache, hostname: []const u8) ?*Record {
    const current_time = std.time.timestamp();

    const allocator = self.allocator;
    var node = self.records_list.first;
    while (node) |n| {
        node = n.next;

        const data = &n.data;
        if (data.expire_at < current_time) {
            switch (data.state) {
                .resolved => |v| allocator.free(v),
                .none => {}, // When it is none, `expire_at` must be 0

                // At this point the hostname should be resolved. Also when it is pending state,
                // `expire_at` is MAX_I64
                .pending => unreachable
            }

            allocator.free(data.hostname);

            self.records_list.unlink_node(n);
            self.records_list.release_node(n);
            continue;
        }

        if (!std.mem.eql(u8, hostname, data.hostname)) {
            continue;
        }

        return data;
    }

    return null;
}

const Cache = @This();

const testing = std.testing;

test "create_new_record" {
    var cache = Cache{
        .allocator = testing.allocator,
        .records_list = undefined,
    };
    cache.init(testing.allocator);
    defer {
        var node = cache.records_list.first;
        while (node) |n| {
            node = n.next;
            testing.allocator.free(n.data.hostname);
            switch (n.data.state) {
                .resolved => |d| {
                    testing.allocator.free(d);
                },
                else => {}
            }
            cache.records_list.release_node(n);
        }
    }

    const record = try cache.create_new_record("example.com", undefined);

    try testing.expectEqualStrings("example.com", record.hostname);
    try testing.expect(record.state == .pending);
    try testing.expect(record.expire_at == std.math.maxInt(i64));
}

test "set_resolved_data" {
    var cache = Cache{
        .allocator = testing.allocator,
        .records_list = undefined,
    };
    cache.init(testing.allocator);
    defer {
        var node = cache.records_list.first;
        while (node) |n| {
            node = n.next;
            testing.allocator.free(n.data.hostname);
            switch (n.data.state) {
                .resolved => |d| {
                    testing.allocator.free(d);
                },
                else => {}
            }
            cache.records_list.release_node(n);
        }
    }

    const record = try cache.create_new_record("example.com", undefined);

    const addresses = try testing.allocator.alloc(std.net.Address, 2);
    addresses[0] = std.net.Address.initIp4(.{8, 8, 8, 8}, 53);
    addresses[1] = std.net.Address.initIp4(.{1, 1, 1, 1}, 53);

    record.set_resolved_data(addresses, 300);

    try testing.expect(record.state == .resolved);
    try testing.expectEqual(@as(usize, 2), record.get_address_list().?.len);
    try testing.expectEqual(std.posix.AF.INET, record.get_address_list().?[0].any.family);
    try testing.expectEqual(std.posix.AF.INET, record.get_address_list().?[1].any.family);
    try testing.expect(record.expire_at > std.time.timestamp());
}

test "get record from cache" {
    var cache = Cache{
        .allocator = testing.allocator,
        .records_list = undefined,
    };
    cache.init(testing.allocator);
    defer {
        var node = cache.records_list.first;
        while (node) |n| {
            node = n.next;
            testing.allocator.free(n.data.hostname);
            switch (n.data.state) {
                .resolved => |d| {
                    testing.allocator.free(d);
                },
                else => {}
            }
            cache.records_list.release_node(n);
        }
    }

    const record = try cache.create_new_record("example.com", undefined);

    const addresses = try testing.allocator.alloc(std.net.Address, 2);
    addresses[0] = std.net.Address.initIp4(.{8, 8, 8, 8}, 53);
    addresses[1] = std.net.Address.initIp4(.{1, 1, 1, 1}, 53);

    record.set_resolved_data(addresses, 300);

    const retrieved_record = cache.get("example.com").?;
    try testing.expectEqualStrings("example.com", retrieved_record.hostname);
    try testing.expect(retrieved_record.state == .resolved);
    try testing.expectEqual(@as(usize, 2), retrieved_record.get_address_list().?.len);
}

test "get expired record" {
    var cache = Cache{
        .allocator = testing.allocator,
        .records_list = undefined,
    };
    cache.init(testing.allocator);
    defer {
        var node = cache.records_list.first;
        while (node) |n| {
            node = n.next;
            testing.allocator.free(n.data.hostname);
            switch (n.data.state) {
                .resolved => |d| {
                    testing.allocator.free(d);
                },
                else => {}
            }
            cache.records_list.release_node(n);
        }
    }

    const record = try cache.create_new_record("example.com", undefined);

    const addresses = try testing.allocator.alloc(std.net.Address, 2);
    addresses[0] = std.net.Address.initIp4(.{8, 8, 8, 8}, 53);
    addresses[1] = std.net.Address.initIp4(.{1, 1, 1, 1}, 53);

    record.set_resolved_data(addresses, 0);  // Immediately expire
    record.expire_at = 0;  // Force expiration

    const retrieved_record = cache.get("example.com");
    try testing.expect(retrieved_record == null);
}
