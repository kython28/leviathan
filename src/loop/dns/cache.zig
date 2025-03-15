const std = @import("std");

const utils = @import("utils");


const Record = struct {
    hostname: []u8,
    address_list: []std.posix.sockaddr,
    expire_at: i64
};

const RecordLinkedList = utils.LinkedList(Record);

allocator: std.mem.Allocator,
records_list: RecordLinkedList,

pub fn init(self: *Cache, allocator: std.mem.Allocator) void {
    self.records_list = RecordLinkedList.init(allocator);
}

pub fn add(self: *Cache, hostname: []const u8, address_list: []std.posix.sockaddr, ttl: u32) !void {
    const allocator = self.allocator;
    const new_hostname = try allocator.dupe(hostname);
    errdefer allocator.free(new_hostname);

    var expire_at: i64 = std.math.maxInt(i64);
    if (ttl < std.math.maxInt(u32)) {
        expire_at = std.time.timestamp() + ttl;
    }

    const new_record = Record{
        .hostname = new_hostname,
        .address_list = address_list,
        .expire_at = expire_at
    };

    try self.records_list.append(new_record);
}

pub fn get(self: *Cache, hostname: []const u8) ?[]const std.posix.sockaddr {
    const current_time = std.time.timestamp();

    const allocator = self.allocator;
    var node = self.records_list.first;
    while (node) |n| {
        node = n.next;

        const data = n.data;
        if (data.expire_at < current_time) {
            self.records_list.unlink_node(n);
            self.records_list.release_node(n);

            allocator.destroy(data.hostname);
            allocator.destroy(data.address_list);
            continue;
        }

        if (std.mem.eql(u8, hostname, data.hostname)) {
            return data.address_list;
        }
    }

    return null;
}

const Cache = @This();
