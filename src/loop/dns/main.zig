const std = @import("std");
const builtin = @import("builtin");

const Loop = @import("../main.zig");

const Cache = @import("cache.zig");
const Parsers = @import("parsers.zig");
const Resolv = @import("resolv.zig");

const DNSCacheEntries = switch (builtin.mode) {
    .Debug => 8,
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
    callback: *const Resolv.UserCallback,
) !?[]const std.net.Address {
    const parsed_hostname = std.ascii.lowerString(&self.parsed_hostname_buf, hostname);

    const cache_slot = self.get_cache_slot(parsed_hostname);
    const record = cache_slot.get(parsed_hostname) orelse {
        const ipv6_supported: bool = self.ipv6_supported;

        const address_resolved = try Parsers.resolve_address(parsed_hostname, ipv6_supported);
        if (address_resolved) |v| {
            return v;
        }

        try Resolv.queue(
            cache_slot,
            self.loop,
            hostname,
            callback,
            self.configuration,
            ipv6_supported,
        );
        return null;
    };

    const address_list = record.get_address_list() orelse {
        try record.append_callback(callback);
        return null;
    };

    return address_list;
}

pub fn deinit(self: *DNS) void {
    self.arena.deinit();
}

const DNS = @This();

test {
    std.testing.refAllDecls(Parsers);
    std.testing.refAllDecls(Cache);
}


