const std = @import("std");

// Localhost addresses for quick reference
const localhost_address_list: []const std.net.Address = &[_]std.net.Address{
    std.net.Address.initIp4(
        .{ 127, 0, 0, 1 },
        0,
    ),
    std.net.Address.initIp6(
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
        0,
        0,
        0,
    ),
};

var tmp_address: std.net.Address = undefined;

// TODO: Implement resolv options
pub const Configuration = struct {
    servers: []std.net.Address,
    search: [][]u8,
};

pub fn validate_hostname(hostname: []const u8) bool {
    var iter = std.mem.splitScalar(u8, hostname, '.');
    while (iter.next()) |label| {
        if (label.len < 1 or label.len > 63) {
            return false;
        }

        if (label[0] == '-' or label[label.len - 1] == '-') {
            return false;
        }

        var has_hyphen = false;
        for (label) |c| {
            const hyphen = (c == '-');
            if (hyphen and has_hyphen) return false;
            has_hyphen = hyphen;

            if (!((c >= 'a' and c <= 'z') or
                (c >= '0' and c <= '9') or
                hyphen))
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

pub fn resolve_address(hostname: []const u8, allow_ipv6: bool) !?[]const std.net.Address {
    // 1. Check for localhost
    if (std.mem.eql(u8, hostname, "localhost")) {
        return localhost_address_list[0..(1 + @as(usize, @intFromBool(allow_ipv6)))];
    }

    // 2. Check for IPv4
    if (is_ipv4(hostname)) {
        tmp_address = try std.net.Address.resolveIp(hostname, 0);
        return @as([*]const std.net.Address, @ptrCast(&tmp_address))[0..1];
    }

    // 3. Check for IPv6
    if (allow_ipv6 and is_ipv6(hostname)) {
        tmp_address = try std.net.Address.resolveIp6(hostname, 0);
        return @as([*]const std.net.Address, @ptrCast(&tmp_address))[0..1];
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

    var servers = std.ArrayList(std.net.Address).init(allocator);
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

            switch (address.any.family) {
                std.posix.AF.INET, std.posix.AF.INET6 => {},
                else => unreachable
            }
            
            try servers.append(address);
        } else if (std.mem.eql(u8, first_word, "search")) {
            while (words_iter.next()) |word| {
                chr = word[0];
                if (chr == '#' or chr == ';') {
                    continue :loop;
                }

                const parsed_hostname = std.ascii.lowerString(search_tmp_buf, word);
                if (!validate_hostname(parsed_hostname)) return error.InvalidConfiguration;

                const host = try allocator.dupe(u8, parsed_hostname);
                errdefer allocator.free(host);

                try search_hosts.append(host);
            }
        }
    }

    if (servers.items.len == 0) {
        try servers.append(try std.net.Address.parseIp("1.1.1.1", 53));
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

test "parse valid resolv.conf with nameservers and search domains" {
    const content =
        \\nameserver 8.8.8.8
        \\nameserver 1.1.1.1
        \\search example.com test.com
    ;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const config = try parse_resolv_configuration(allocator, content);

    try std.testing.expectEqual(@as(usize, 2), config.servers.len);
    try std.testing.expectEqual(@as(usize, 2), config.search.len);
    try std.testing.expectEqualStrings("example.com", config.search[0]);
    try std.testing.expectEqualStrings("test.com", config.search[1]);

    // Verify first nameserver details
    const first_server = config.servers[0];
    try std.testing.expectEqual(std.posix.AF.INET, first_server.any.family);
    const first_ip_bytes: [4]u8 = @bitCast(first_server.in.sa.addr);
    try std.testing.expectEqual(@as(u8, 8), first_ip_bytes[0]);
    try std.testing.expectEqual(@as(u8, 8), first_ip_bytes[1]);
    try std.testing.expectEqual(@as(u8, 8), first_ip_bytes[2]);
    try std.testing.expectEqual(@as(u8, 8), first_ip_bytes[3]);

    // Verify second nameserver details
    const second_server = config.servers[1];
    try std.testing.expectEqual(std.posix.AF.INET, second_server.any.family);
    const second_ip_bytes: [4]u8 = @bitCast(second_server.in.sa.addr);
    try std.testing.expectEqual(@as(u8, 1), second_ip_bytes[0]);
    try std.testing.expectEqual(@as(u8, 1), second_ip_bytes[1]);
    try std.testing.expectEqual(@as(u8, 1), second_ip_bytes[2]);
    try std.testing.expectEqual(@as(u8, 1), second_ip_bytes[3]);
}

test "parse resolv.conf with comments" {
    const content =
        \\# This is a comment
        \\nameserver 8.8.8.8
        \\; Another comment
        \\nameserver 1.1.1.1
        \\search example.com
    ;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const config = try parse_resolv_configuration(allocator, content);

    try std.testing.expectEqual(@as(usize, 2), config.servers.len);
    try std.testing.expectEqual(@as(usize, 1), config.search.len);
    try std.testing.expectEqualStrings("example.com", config.search[0]);

    // Verify first nameserver details
    const first_server = config.servers[0];
    try std.testing.expectEqual(std.posix.AF.INET, first_server.any.family);
    const first_ip_bytes: [4]u8 = @bitCast(first_server.in.sa.addr);
    try std.testing.expectEqual(@as(u8, 8), first_ip_bytes[0]);
    try std.testing.expectEqual(@as(u8, 8), first_ip_bytes[1]);
    try std.testing.expectEqual(@as(u8, 8), first_ip_bytes[2]);
    try std.testing.expectEqual(@as(u8, 8), first_ip_bytes[3]);

    // Verify second nameserver details
    const second_server = config.servers[1];
    try std.testing.expectEqual(std.posix.AF.INET, second_server.any.family);
    const second_ip_bytes: [4]u8 = @bitCast(second_server.in.sa.addr);
    try std.testing.expectEqual(@as(u8, 1), second_ip_bytes[0]);
    try std.testing.expectEqual(@as(u8, 1), second_ip_bytes[1]);
    try std.testing.expectEqual(@as(u8, 1), second_ip_bytes[2]);
    try std.testing.expectEqual(@as(u8, 1), second_ip_bytes[3]);
}

test "parse resolv.conf with invalid nameserver" {
    const content =
        \\nameserver invalid.ip
    ;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try std.testing.expectError(
        error.InvalidIPAddressFormat, 
        parse_resolv_configuration(allocator, content),
    );
}

test "parse resolv.conf with invalid search domain" {
    const content =
        \\nameserver 8.8.8.8
        \\search invalid--domain
    ;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try std.testing.expectError(
        error.InvalidConfiguration, 
        parse_resolv_configuration(allocator, content),
    );
}

test "parse empty resolv.conf" {
    const content = "";

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const config = try parse_resolv_configuration(allocator, content);
    defer {
        allocator.free(config.search);
        allocator.free(config.servers);
    }

    try std.testing.expectEqual(@as(usize, 1), config.servers.len);
    try std.testing.expectEqual(@as(usize, 0), config.search.len);
    
    // Verify default DNS server
    const default_dns = config.servers[0];
    try std.testing.expectEqual(std.posix.AF.INET, default_dns.any.family);
    
    const ip_bytes: [4]u8 = @bitCast(default_dns.in.sa.addr);
    try std.testing.expectEqual(@as(u8, 1), ip_bytes[0]);
    try std.testing.expectEqual(@as(u8, 1), ip_bytes[1]);
    try std.testing.expectEqual(@as(u8, 1), ip_bytes[2]);
    try std.testing.expectEqual(@as(u8, 1), ip_bytes[3]);
}

test "validate_hostname valid domains" {
    const valid_domains = [_][]const u8{
        "example.com",
        "sub.example.com",
        "test-domain.co.uk",
        "my-domain.org",
        "a.b.c.d",
        "x1.y2.z3",
    };

    for (valid_domains) |domain| {
        try std.testing.expect(validate_hostname(domain));
    }
}

test "validate_hostname invalid domains" {
    const invalid_domains = [_][]const u8{
        "-example.com",     // Starts with hyphen
        "example-.com",     // Ends with hyphen
        "example--test.com", // Consecutive hyphens
        "exam!ple.com",     // Invalid characters
        "exam ple.com",     // Space in domain
        ".example.com",     // Starts with dot
        "example.com.",     // Ends with dot
    };

    for (invalid_domains) |domain| {
        try std.testing.expect(!validate_hostname(domain));
    }
}

test "validate_hostname edge cases" {
    const edge_cases = [_]struct { domain: []const u8, expected: bool }{
        .{ .domain = "a.com", .expected = true },           // Minimum valid length
        .{ .domain = "a-1.com", .expected = true },          // Hyphen with number
        .{ .domain = "a" ** 63 ++ ".com", .expected = true }, // Maximum label length
        .{ .domain = "a" ** 64 ++ ".com", .expected = false }, // Exceeds maximum label length
    };

    for (edge_cases) |case| {
        try std.testing.expectEqual(case.expected, validate_hostname(case.domain));
    }
}
