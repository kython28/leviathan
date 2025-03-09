const std = @import("std");

// TODO: Implement resolv options
pub const Configuration = struct {
    servers: []std.posix.sockaddr,
    search: [][]u8,
};

pub fn parse_hostname(buf: []u8, hostname: []const u8) ?[]const u8 {
    if (hostname.len > buf.len) {
        return null;
    }

    const parsed_hostname = try std.ascii.lowerString(buf, hostname);

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
        }else if (std.mem.eql(u8, first_word, "search")) {
            while (words_iter.next()) |word| {
                chr = word[0];
                if (chr == '#' or chr == ';') {
                    continue :loop;
                }

                const parsed_hostname = try parse_hostname(search_tmp_buf, word) orelse
                    return error.InvalidConfiguration;

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
        .servers = servers_slice
    };
}
