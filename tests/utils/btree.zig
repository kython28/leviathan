const BTree = @import("leviathan").utils.BTree;

const std = @import("std");

const allocator = std.testing.allocator;

test "Create and release" {
    var new_btree = try BTree.init(usize, usize, 3).init(allocator);
    defer new_btree.deinit() catch unreachable;

    try std.testing.expectEqual(0, new_btree.parent.nkeys);
    try std.testing.expectEqual(null, new_btree.parent.parent);
    for (new_btree.parent.childs) |v| try std.testing.expectEqual(null, v);
}

test "Inserting elements and removing" {
    var new_btree = try BTree.init(usize, usize, 3).init(allocator);
    defer new_btree.deinit() catch unreachable;

    for (0..20) |v| {
        const value = (v + 1) * 23;
        const inserted = new_btree.insert(v, value);
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

test "Insert, search, partial delete, reinsert and full delete" {
    var new_btree = try BTree.init(usize, usize, 3).init(allocator);
    defer new_btree.deinit() catch unreachable;

    // Initial insertion of elements
    for (0..15) |v| {
        const value = v * 100 + 50;
        const inserted = new_btree.insert(v, value);
        try std.testing.expect(inserted);
    }

    // Verify all elements are present
    for (0..15) |v| {
        const value = new_btree.get_value(v, null);
        try std.testing.expectEqual(v * 100 + 50, value);
    }

    // Delete some elements (even numbers)
    for (0..15) |v| {
        if (v % 2 == 0) {
            const value = new_btree.delete(v);
            try std.testing.expectEqual(v * 100 + 50, value);
        }
    }

    // Verify odd numbers still present, even numbers gone
    for (0..15) |v| {
        const value = new_btree.get_value(v, null);
        if (v % 2 == 0) {
            try std.testing.expectEqual(null, value);
        } else {
            try std.testing.expectEqual(v * 100 + 50, value);
        }
    }

    // Reinsert even numbers with new values
    for (0..15) |v| {
        if (v % 2 == 0) {
            const value = v * 200 + 25;
            const inserted = new_btree.insert(v, value);
            try std.testing.expect(inserted);
        }
    }

    // Verify all numbers present with correct values
    for (0..15) |v| {
        const value = new_btree.get_value(v, null);
        if (v % 2 == 0) {
            try std.testing.expectEqual(v * 200 + 25, value);
        } else {
            try std.testing.expectEqual(v * 100 + 50, value);
        }
    }

    // Delete all elements
    for (0..15) |v| {
        const value = new_btree.delete(v);
        if (v % 2 == 0) {
            try std.testing.expectEqual(v * 200 + 25, value);
        } else {
            try std.testing.expectEqual(v * 100 + 50, value);
        }
    }

    // Verify tree is empty
    for (0..15) |v| {
        const value = new_btree.get_value(v, null);
        try std.testing.expectEqual(null, value);
    }
}

test "Inserting in random order, searching and removing" {
    var new_btree = try BTree.init(usize, usize, 3).init(allocator);
    defer new_btree.deinit() catch unreachable;

    var values: [30]usize = undefined;
    for (&values, 0..) |*v, i| v.* = i * 3;

    const randpgr = std.crypto.random;
    randpgr.shuffle(usize, &values);

    for (values) |v| {
        const value = (v + 1) * 23;
        const inserted = new_btree.insert(v, value);
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
    var new_btree = try BTree.init(f64, f64, 3).init(allocator);
    defer new_btree.deinit() catch unreachable;

    const randpgr = std.crypto.random;
    var values: [100]f64 = undefined;
    for (&values) |*v| v.* = -10.0 + randpgr.float(f64) * 20.0;

    randpgr.shuffle(f64, &values);

    for (values) |v| {
        const value = v * 33.0 + 10.0;
        const inserted = new_btree.insert(v, value);
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
