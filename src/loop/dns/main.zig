const std = @import("std");
const builtin = @import("builtin");

const Loop = @import("../main.zig");

const Cache = @import("cache.zig");

const DNSCacheEntries = switch (builtin.mode) {
    .Debug => 8,
    else => 65536
};

const CACHE_MASK = DNSCacheEntries - 1;

const Server = struct {
    address: std.posix.sockaddr,
    port: u16,
};

loop: *Loop,
arena: std.heap.ArenaAllocator,
allocator: std.mem.Allocator,

servers: []Server,

cache_entries: [DNSCacheEntries]Cache,
parsed_hostname: [255]u8,

ipv6_supported: bool,

pub fn init(self: *DNS, loop: *Loop) !void {
    self.arena = std.heap.ArenaAllocator.init(loop.allocator);
    self.allocator = self.arena.allocator();

    for (self.cache_entries) |*entry| {
        entry.init(self.allocator);
    }

    // TODO: Figure out if there is a better way
    const ret = std.posix.socket(std.posix.AF.INET6, std.posix.SOCK.STREAM, 0);
    if (ret) |sock| {
        self.ipv6_supported = true;
        std.posix.close(sock);
    } else {
        self.ipv6_supported = false;
    }
}

fn parse_configuration(self: *DNS, content: []const u8) !void {
    const State = enum {
        nameserver, search, comment, nothing
    };

    var current_state = State.nothing;
    var index: usize = 0;
    loop: while (index < content.len) {
        switch (current_state) {
            .nothing => {
                while (index < content.len) {
                    const chr = content[index];
                    index += 1;
                    if (chr == ';' or chr == '#') {
                        current_state = .comment;
                        continue :loop;
                    }else if (chr < 'a' or chr > 'z') {
                        continue :loop;
                    }
                }

                const start = index;
                while (index < content.len) {
                    if (content[index] == ' ') {
                        break;
                    }
                    index += 1;
                }

                if (index == content.len) break :loop;

                const attr = content[start..(index - 1)];
                if (std.mem.eql(u8, "nameserver", attr)) {
                    current_state = .nameserver;
                }else if (std.mem.eql(u8, "search", attr)) {
                    current_state = .search;
                }

                continue :loop;
            },
            .comment => {
                while (index < content.len) {
                    const chr = content[index];
                    index += 1;
                    if (chr == '\n') {
                        current_state = .nothing;
                        continue :loop;
                    }
                }
            },
            .search => {

            }
        }
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

    try self.parse_configuration(content);
}

fn parse_hostname(self: *DNS, hostname: []const u8) ?[]const u8 {
    if (hostname.len > 255) {
        return null;
    }

    const parsed_hostname = try std.ascii.lowerString(&self.parsed_hostname, hostname);

    if (std.mem.count(u8, parsed_hostname, ".") == 0) {
        return null;
    }

    const iter = std.mem.splitScalar(u8, parsed_hostname, '|');
    while (iter.next()) |label| {
        if (label.len < 1 or label.len > 63) {
            return null;
        }

        if (label[0] == '-' or label[label.len - 1] == '-') {
            return null;
        }

        for (label) |c| {
            if (!(
                (c >= 'a' and c <= 'z') or
                (c >= 'A' and c <= 'Z') or
                (c >= '0' and c <= '9') or
                (c == '-')
            )) {
                return null;
            }
        }
    }

    return parsed_hostname;
}

fn get_from_cache(self: *DNS, parsed_hostname: []const u8) ?[]const std.posix.sockaddr {
    const h = std.hash.XxHash3.init(0);
    h.update(parsed_hostname);
    const index = h.final();

    return self.cache_entries[index & CACHE_MASK].get(parsed_hostname);
}

fn add_to_cache(self: *DNS, parsed_hostname: []const u8, address_list: []std.posix.sockaddr) !void {
    const h = std.hash.XxHash3.init(0);
    h.update(parsed_hostname);
    const index = h.final();

    try self.cache_entries[index & CACHE_MASK].add(parsed_hostname, address_list);
}

pub fn lookup(self: *DNS, hostname: []const u8) ![]const std.posix.sockaddr {
    const parsed_hostname = self.parse_hostname(hostname) orelse return error.InvalidDomain;

    if (self.get_from_cache(parsed_hostname)) |addr_info| {
        return addr_info;
    }


}

pub fn deinit(self: *DNS) void {
    self.arena.deinit();
}

const DNS = @This();
