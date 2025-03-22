const std = @import("std");

const utils = @import("utils");

const Resolv = @import("resolv.zig");

const RecordState = union(enum) {
    pending: *Resolv.ControlData,
    resolved: []std.posix.sockaddr,
    none,
};

pub const Record = struct {
    hostname: []u8,
    state: RecordState,
    expire_at: i64,

    pub inline fn get_address_list(self: *Record) ?[]const std.posix.sockaddr {
        return switch (self.state) {
            .pending => null,
            .resolved => |d| d,
            .none => @panic("Attempt to get data from empty record") // Read `get` Cache's method
        };
    }

    pub inline fn append_callback(self: *Record, user_callback: *const Resolv.UserCallback) !void {
        const control_data = self.state.pending;
        try control_data.user_callbacks.append(user_callback.*);
    }

    pub inline fn set_resolved_data(self: *Record, address_list: []std.posix.sockaddr, ttl: u32) void {
        var expire_at: i64 = std.math.maxInt(i64);
        if (ttl < std.math.maxInt(u32)) {
            expire_at = std.time.timestamp() + ttl;
        }

        self.expire_at = expire_at;
        self.state = address_list;
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

pub fn create_new_record(self: *Cache, hostname: []const u8, control_data: *Resolv.ControlData) !void {
    const allocator = self.allocator;
    const new_hostname = try allocator.dupe(hostname);
    errdefer allocator.free(new_hostname);

    const new_record = Record{
        .hostname = new_hostname,
        .expire_at = std.math.maxInt(i64),
        .state = .{
            .Pending = control_data
        }
    };

    try self.records_list.append(new_record);
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

            allocator.destroy(data.hostname);

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
