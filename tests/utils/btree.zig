const BTree = @import("leviathan").utils.BTree;

const std = @import("std");

const allocator = std.testing.allocator;

test "Create and release" {
    const new_btree = try BTree.init(usize, usize, 3).init(allocator);
    defer new_btree.deinit() catch unreachable;

    try std.testing.expectEqual(0, new_btree.parent.nkeys);
    try std.testing.expectEqual(null, new_btree.parent.parent);
    for (new_btree.parent.childs) |v| try std.testing.expectEqual(null, v);
}

test "Inserting elements and removing" {
    const new_btree = try BTree.init(usize, usize, 3).init(allocator);
    defer new_btree.deinit() catch unreachable;

    for (0..20) |v| {
        const value = (v + 1) * 23;
        const inserted = new_btree.insert(v, value, false);
        try std.testing.expect(inserted);
    }

    for (0..20) |v| {
        const value = new_btree.get_value(v, null);
        try std.testing.expectEqual((v + 1) * 23, value);
    }

    for (0..20) |v| {
        const value = new_btree.delete(v);
        try std.testing.expectEqual((v + 1) * 23, value);
    }
}

test "Inserting in random order, searching and removing" {
    const new_btree = try BTree.init(usize, usize, 3).init(allocator);
    defer new_btree.deinit() catch unreachable;

    var values: [30]usize = undefined;
    for (&values, 0..) |*v, i| v.* = i * 3;

    const randpgr = std.crypto.random;
    randpgr.shuffle(usize, &values);

    for (values) |v| {
        const value = (v + 1) * 23;
        const inserted = new_btree.insert(v, value, false);
        try std.testing.expect(inserted);
    }

    randpgr.shuffle(usize, &values);

    for (values) |v| {
        const value = new_btree.get_value(v, null);
        try std.testing.expectEqual((v + 1) * 23, value);
    }

    randpgr.shuffle(usize, &values);
    for (values) |v| {
        const value = new_btree.delete(v);
        try std.testing.expectEqual((v + 1) * 23, value);
    }
}

test "Inserting in random float elements, searching and removing" {
    const new_btree = try BTree.init(f64, f64, 3).init(allocator);
    defer new_btree.deinit() catch unreachable;

    const randpgr = std.crypto.random;
    var values: [100]f64 = undefined;
    for (&values) |*v| v.* = -10.0 + randpgr.float(f64) * 20.0;

    randpgr.shuffle(f64, &values);

    for (values) |v| {
        const value = v * 33.0 + 10.0;
        const inserted = new_btree.insert(v, value, false);
        try std.testing.expect(inserted);
    }

    randpgr.shuffle(f64, &values);

    for (values) |v| {
        const value = new_btree.get_value(v, null);
        const value_expected = v * 33.0 + 10.0;
        const diff = @abs(value.? - value_expected);
        try std.testing.expect(diff <= std.math.floatEps(f64));
    }

    randpgr.shuffle(f64, &values);
    for (values) |v| {
        const value = new_btree.delete(v);
        const value_expected = v * 33.0 + 10.0;

        const diff = @abs(value.? - value_expected);
        try std.testing.expect(diff <= std.math.floatEps(f64));
    }
}
