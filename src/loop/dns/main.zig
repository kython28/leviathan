const std = @import("std");
const builtin = @import("builtin");

const Loop = @import("../main.zig");

const Cache = @import("cache.zig");
const Parsers = @import("parsers.zig");
const Resolv = @import("resolv.zig");
const CallbackManager = @import("callback_manager");

const DNSCacheEntries = switch (builtin.mode) {
    .Debug => 4,
    else => 65536,
};

const CACHE_MASK = DNSCacheEntries - 1;

loop: *Loop,
arena: std.heap.ArenaAllocator,
allocator: std.mem.Allocator,

configuration: Parsers.Configuration,

cache_entries: [DNSCacheEntries]Cache,
parsed_hostname_buf: [255]u8,

ipv6_supported: bool,

pub fn init(self: *DNS, loop: *Loop) !void {
    self.arena = std.heap.ArenaAllocator.init(loop.allocator);
    self.allocator = self.arena.allocator();

    for (&self.cache_entries) |*entry| {
        entry.init(self.allocator);
    }

    try self.load_configuration(self.allocator);

    // TODO: Figure out if there is a better way
    const ret = std.posix.socket(std.posix.AF.INET6, std.posix.SOCK.STREAM, 0);
    if (ret) |sock| {
        self.ipv6_supported = true;
        std.posix.close(sock);
    } else |_| {
        self.ipv6_supported = false;
    }
}

fn load_configuration(self: *DNS, allocator: std.mem.Allocator) !void {
    const file = try std.fs.openFileAbsolute("/etc/resolv.conf", .{
        .mode = .read_only,
    });
    defer file.close();

    const metadata = try file.metadata();
    const size = metadata.size();

    const content = try allocator.alloc(u8, size);
    defer allocator.free(content);

    _ = try file.readAll(content);

    self.configuration = try Parsers.parse_resolv_configuration(allocator, content);
}

fn get_cache_slot(self: *DNS, hostname: []const u8) *Cache {
    var h = std.hash.XxHash3.init(0);
    h.update(hostname);
    const index = h.final();

    return &self.cache_entries[index & CACHE_MASK];
}

pub fn lookup(
    self: *DNS,
    hostname: []const u8,
    callback: ?*const CallbackManager.Callback,
) !?[]const std.net.Address {
    const parsed_hostname = std.ascii.lowerString(&self.parsed_hostname_buf, hostname);

    const cache_slot = self.get_cache_slot(parsed_hostname);
    const record = cache_slot.get(parsed_hostname) orelse {
        if (callback == null) return null;

        const ipv6_supported: bool = self.ipv6_supported;

        const address_resolved = try Parsers.resolve_address(parsed_hostname, ipv6_supported);
        if (address_resolved) |v| {
            return v;
        }

        try Resolv.queue(
            cache_slot,
            self.loop,
            hostname,
            callback.?,
            self.configuration,
            ipv6_supported,
        );
        return null;
    };

    const address_list = record.get_address_list() orelse {
        if (callback == null) return null;

        try self.loop.reserve_slots(1);
        errdefer self.loop.reserved_slots -= 1;

        try record.append_callback(callback.?);
        return null;
    };

    return address_list;
}

pub fn deinit(self: *DNS) void {
    self.arena.deinit();
}

const DNS = @This();

test "get_cache_slot returns consistent slot for same hostname" {
    var dns = DNS{
        .loop = undefined,
        .arena = undefined,
        .allocator = std.testing.allocator,
        .configuration = undefined,
        .cache_entries = undefined,
        .parsed_hostname_buf = undefined,
        .ipv6_supported = false,
    };

    const hostname1 = "example.com";
    const hostname2 = "example.com";

    const slot1 = dns.get_cache_slot(hostname1);
    const slot2 = dns.get_cache_slot(hostname2);

    try std.testing.expectEqual(slot1, slot2);
}

test "get_cache_slot distributes hostnames across slots" {
    var dns = DNS{
        .loop = undefined,
        .arena = undefined,
        .allocator = std.testing.allocator,
        .configuration = undefined,
        .cache_entries = undefined,
        .parsed_hostname_buf = undefined,
        .ipv6_supported = false,
    };

    const hostnames = [_][]const u8{
        "example1.com",
        "example2.com",
        "example3.com",
        "example4.com",
        "example5.com",
    };

    var slots = [_]*Cache{undefined} ** hostnames.len;

    for (hostnames, 0..) |hostname, i| {
        slots[i] = dns.get_cache_slot(hostname);
    }

    // Check that not all slots are the same
    var unique_slots = std.ArrayList(*Cache).init(std.testing.allocator);
    defer unique_slots.deinit();

    loop: for (slots) |slot| {
        for (unique_slots.items) |existing_slot| {
            if (slot == existing_slot) {
                continue :loop;
            }
        }
        try unique_slots.append(slot);
    }

    try std.testing.expect(unique_slots.items.len > 1);
}

test "get_cache_slot handles different hostname lengths" {
    var dns = DNS{
        .loop = undefined,
        .arena = undefined,
        .allocator = std.testing.allocator,
        .configuration = undefined,
        .cache_entries = undefined,
        .parsed_hostname_buf = undefined,
        .ipv6_supported = false,
    };

    const hostnames = [_][]const u8{
        "a",
        "ab",
        "abc",
        "abcd",
        "abcde",
        "a" ** 63,
        "a" ** 255,
    };

    var slots = [_]*Cache{undefined} ** hostnames.len;

    for (hostnames, 0..) |hostname, i| {
        slots[i] = dns.get_cache_slot(hostname);
    }

    // Check that different length hostnames can map to different slots
    var unique_slots = std.ArrayList(*Cache).init(std.testing.allocator);
    defer unique_slots.deinit();

    loop: for (slots) |slot| {
        for (unique_slots.items) |existing_slot| {
            if (slot == existing_slot) {
                continue :loop;
            }
        }
        try unique_slots.append(slot);
    }

    try std.testing.expect(unique_slots.items.len > 1);
}

test {
    std.testing.refAllDecls(Parsers);
    std.testing.refAllDecls(Cache);
}
