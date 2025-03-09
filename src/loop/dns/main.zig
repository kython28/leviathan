const std = @import("std");
const builtin = @import("builtin");

const Loop = @import("../main.zig");

const Cache = @import("cache.zig");
const Parsers = @import("parsers.zig");

const DNSCacheEntries = switch (builtin.mode) {
    .Debug => 8,
    else => 65536
};

const CACHE_MASK = DNSCacheEntries - 1;

loop: *Loop,
arena: std.heap.ArenaAllocator,
allocator: std.mem.Allocator,

configuration: Parsers.Configuration,

cache_entries: [DNSCacheEntries]Cache,
parsed_hostname: [255]u8,

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
    } else {
        self.ipv6_supported = false;
    }
}

fn load_configuration(self: *DNS, allocator: std.mem.Allocator) !void {
    const file = try std.fs.openFileAbsolute("/etc/resolv.conf", .{
        .mode = .read_only
    });
    defer file.close();

    const metadata = try file.metadata();
    const size = metadata.size();

    const content = try allocator.alloc(u8, size);
    defer allocator.free(content);

    _ = try file.readAll(content);

    self.configuration = try Parsers.parse_resolv_configuration(allocator, content);
}

fn get_from_cache(self: *DNS, parsed_hostname: []const u8) ?[]const std.posix.sockaddr {
    var h = std.hash.XxHash3.init(0);
    h.update(parsed_hostname);
    const index = h.final();

    return self.cache_entries[index & CACHE_MASK].get(parsed_hostname);
}

fn add_to_cache(self: *DNS, parsed_hostname: []const u8, address_list: []std.posix.sockaddr) !void {
    var h = std.hash.XxHash3.init(0);
    h.update(parsed_hostname);
    const index = h.final();

    try self.cache_entries[index & CACHE_MASK].add(parsed_hostname, address_list);
}

pub fn lookup(self: *DNS, hostname: []const u8) ![]const std.posix.sockaddr {
    const parsed_hostname = Parsers.parse_hostname(&self.parsed_hostname, hostname) orelse
        return error.InvalidDomain;

    if (self.get_from_cache(parsed_hostname)) |addr_info| {
        return addr_info;
    }


}

pub fn deinit(self: *DNS) void {
    self.arena.deinit();
}

const DNS = @This();
