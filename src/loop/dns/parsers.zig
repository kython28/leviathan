const std = @import("std");

// Localhost addresses for quick reference
const localhost_address_list: []const std.posix.sockaddr = &[_]std.posix.sockaddr{
    @bitCast(
        std.net.Ip4Address.init(
            &.{ 127, 0, 0, 1 },
            0,
        ).sa,
    ),
    @bitCast(
        std.net.Ip6Address.init(
            &.{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
            0,
            0,
            0,
        ).sa,
    )
};

var tmp_address: std.posix.sockaddr = undefined;

// TODO: Implement resolv options
pub const Configuration = struct {
    servers: []std.posix.sockaddr,
    search: [][]u8,
};

pub fn validate_hostname(hostname: []const u8) bool {
    const iter = std.mem.splitScalar(u8, hostname, '.');
    while (iter.next()) |label| {
        if (label.len < 1 or label.len > 63) {
            return false;
        }

        if (label[0] == '-' or label[label.len - 1] == '-') {
            return false;
        }

        for (label) |c| {
            if (!((c >= 'a' and c <= 'z') or
                (c >= '0' and c <= '9') or
                (c == '-')))
            {
                return false;
            }
        }
    }

    return true;
}

pub fn is_ipv4(ip: []const u8) bool {
    var iter = std.mem.tokenizeScalar(u8, ip, '.');
    var count: u8 = 0;

    while (iter.next()) |octet| : (count += 1) {
        if (count >= 4) return false;

        _ = std.fmt.parseInt(u8, octet, 10) catch return false;
    }

    return count == 4;
}

pub fn is_ipv6(ip: []const u8) bool {
    var iter = std.mem.splitScalar(u8, ip, ':');
    var count: u8 = 0;
    var compressed_zero_count: u8 = 0;

    while (iter.next()) |segment| : (count += 1) {
        if (count > 8) return false;

        if (segment.len == 0) {
            compressed_zero_count += 1;
            if (compressed_zero_count > 1) return false;
        } else {
            _ = std.fmt.parseInt(u16, segment, 16) catch return false;
        }
    }

    return count <= 8;
}

pub fn resolve_address(hostname: []const u8, allow_ipv6: bool) !?[]const std.posix.sockaddr {
    // 1. Check for localhost
    if (std.mem.eql(u8, hostname, "localhost")) {
        return localhost_address_list[0..(1 + @as(usize, @intFromBool(allow_ipv6)))];
    }

    // 2. Check for IPv4
    if (is_ipv4(hostname)) {
        const address = try std.net.Ip4Address.resolveIp(hostname, 0);
        tmp_address = @bitCast(address.sa);

        return @as([*]const std.posix.sockaddr, @ptrCast(&tmp_address))[0..1];
    }

    // 3. Check for IPv6
    if (allow_ipv6 and is_ipv6(hostname)) {
        const address = try std.net.Ip6Address.resolve(hostname, 0);
        tmp_address = @bitCast(address.sa);

        return @as([*]const std.posix.sockaddr, @ptrCast(&tmp_address))[0..1];
    }

    // 4. Validate hostname
    if (!validate_hostname(hostname)) {
        return error.InvalidHostname;
    }

    // If no match, return null
    return null;
}

pub fn parse_resolv_configuration(allocator: std.mem.Allocator, content: []const u8) !Configuration {
    var lines_iter = std.mem.tokenizeScalar(u8, content, '\n');

    const search_tmp_buf = try allocator.alloc(u8, 255);
    defer allocator.free(search_tmp_buf);

    var servers = std.ArrayList(std.posix.sockaddr).init(allocator);
    defer servers.deinit();

    var search_hosts = std.ArrayList([]u8).init(allocator);
    defer search_hosts.deinit();
    errdefer {
        for (search_hosts.items) |host| {
            allocator.free(host);
        }
    }

    loop: while (lines_iter.next()) |line| {
        var words_iter = std.mem.tokenizeScalar(u8, line, ' ');

        const first_word = words_iter.next() orelse continue;

        var chr = first_word[0];
        if (chr == '#' or chr == ';') {
            continue;
        }

        if (std.mem.eql(u8, first_word, "nameserver")) {
            const ip_str = words_iter.next() orelse return error.InvalidConfiguration;
            const address = try std.net.Address.parseIp(ip_str, 53);
            try servers.append(address.any);
        } else if (std.mem.eql(u8, first_word, "search")) {
            while (words_iter.next()) |word| {
                chr = word[0];
                if (chr == '#' or chr == ';') {
                    continue :loop;
                }

                const parsed_hostname = try std.ascii.lowerString(search_tmp_buf, word);
                if (!validate_hostname(parsed_hostname, true)) return error.InvalidConfiguration;

                const host = try allocator.dupe(parsed_hostname);
                errdefer allocator.free(host);

                try search_hosts.append(host);
            }
        }
    }

    const search_hosts_slice = try search_hosts.toOwnedSlice();
    errdefer {
        for (search_hosts_slice) |host| {
            allocator.free(host);
        }
        allocator.free(search_hosts_slice);
    }

    const servers_slice = try servers.toOwnedSlice();
    errdefer allocator.free(servers_slice);

    return Configuration{
        .search = search_hosts_slice,
        .servers = servers_slice,
    };
}
