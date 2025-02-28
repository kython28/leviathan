const std = @import("std");

pub fn BTree(
    comptime Key: type,
    comptime Value: type,
    comptime Degree: usize
) type {
    if (Degree == 1) {
        @compileError("Degree must be greater than 1");
    }else if (Degree&@as(usize, 1) == 0) {
        @compileError("Degree must be a odd number");
    }

    return struct {
        pub const Node = struct {
            parent: ?*Node,

            keys: [Degree]Key,
            values: [Degree]Value,
            childs: [Degree + 1]?*Node,

            nkeys: std.meta.Int(.unsigned, 1 + std.math.log2(Degree)),
        };

        allocator: std.mem.Allocator,
        parent: *Node,

        pub fn init(allocator: std.mem.Allocator) !@This() {
            return .{
                .allocator = allocator,
                .parent = try create_node(allocator)
            };
        }

        pub fn deinit(self: *@This()) !void {
            if (self.parent.nkeys > 0) return error.BTreeHasElements;

            const allocator = self.allocator;
            allocator.destroy(self.parent);
        }

        fn create_node(allocator: std.mem.Allocator) !*Node {
            const new_node = try allocator.create(Node);
            new_node.parent = null;
            @memset(&new_node.childs, null);
            new_node.nkeys = 0;

            return new_node;
        }

        pub fn get_value_ptr(self: *@This(), key: Key, node: ?**Node) ?*Value {
            var current_node: *Node = self.parent;
            var value: ?*Value = null;
            loop: while (true) {
                const nkeys = current_node.nkeys;
                if (nkeys == 0) break;

                if (@typeInfo(Key) == .float) {
                    const eps = std.math.floatEps(Key);
                    for (
                        current_node.keys[0..nkeys], current_node.values[0..nkeys],
                        current_node.childs[0..nkeys]
                    ) |k, *v, ch| {
                        const diff = k - key;
                        if (@abs(diff) <= eps) {
                            value = v;
                            break :loop;
                        }else if (diff > eps) {
                            current_node = ch orelse break :loop;
                            continue :loop;
                        }
                    }
                }else{
                    for (
                        current_node.keys[0..nkeys], current_node.values[0..nkeys],
                        current_node.childs[0..nkeys]
                    ) |k, *v, ch| {
                        if (k == key) {
                            value = v;
                            break :loop;
                        }else if (k > key) {
                            current_node = ch orelse break :loop;
                            continue :loop;
                        }
                    }
                }

                current_node = current_node.childs[nkeys] orelse break;
            }

            if (node) |v| {
                v.* = current_node;
            }
            return value;
        }

        pub inline fn get_value(self: *@This(), key: Key, node: ?**Node) ?Value {
            const value_ptr = self.get_value_ptr(key, node)
                orelse return null;
            return value_ptr.*;
        }

        inline fn find_max_from_node(node: *Node, key: ?*Key, ret_node: ?**Node) ?*Value {
            var current_node: *Node = node;
            while (true) {
                const nkeys = current_node.nkeys;
                if (nkeys == 0) break;
                current_node = current_node.childs[nkeys] orelse break;
            }

            if (ret_node) |v| {
                v.* = current_node;
            }

            const nkeys = current_node.nkeys;
            if (nkeys == 0) return null;

            if (key) |k| k.* = current_node.keys[nkeys - 1];
            return &current_node.values[nkeys - 1];
        }

        pub fn get_max_value_ptr(self: *@This(), key: ?*Key, node: ?**Node) ?*Value {
            return find_max_from_node(self.parent, key, node);
        }

        pub inline fn get_max_value(self: *@This(), key: ?*Key, node: ?**Node) ?Value {
            const value_ptr = self.get_max_value_ptr(key, node)
                orelse return null;
            return value_ptr.*;
        }

        inline fn find_min_from_node(node: *Node, key: ?*Key, ret_node: ?**Node) ?*Value {
            var current_node: *Node = node;
            while (true) {
                if (current_node.nkeys == 0) break;
                current_node = current_node.childs[0] orelse break;
            }

            if (ret_node) |v| {
                v.* = current_node;
            }
            if (current_node.nkeys == 0) return null;
            if (key) |k| k.* = current_node.keys[0];
            return &current_node.values[0];
        }

        pub fn get_min_value_ptr(self: *@This(), key: ?*Key, node: ?**Node) ?Value {
            return find_min_from_node(self.parent, key, node);
        }

        pub inline fn get_min_value(self: *@This(), key: ?*Key, node: ?**Node) ?Value {
            const value_ptr = self.get_min_value_ptr(key, node)
                orelse return null;
            return value_ptr.*;
        }

        inline fn insert_in_empty_node(node: *Node, keys: []const Key, values: []const Value) void {
            if (keys.len != values.len) unreachable;

            @memcpy(node.keys[0..keys.len], keys);
            @memcpy(node.values[0..values.len], values);
            node.nkeys = @intCast(keys.len);
        }

        fn do_insertion(node: *Node, key: Key, value: Value, new_child: ?*Node) void {
            if (new_child) |ch| {
                ch.parent = node;
            }

            const nkeys = node.nkeys;
            if (nkeys == 0) {
                insert_in_empty_node(node, &.{key}, &.{value});
                node.childs[1] = new_child;
                return;
            }

            defer node.nkeys += 1;

            const keys = &node.keys;
            const values = &node.values;
            const childs = &node.childs;

            if (@typeInfo(Key) == .float) {
                const eps = std.math.floatEps(Key);
                for (0..nkeys) |index| {
                    const diff = key - keys[index];
                    if (diff < -eps) {
                        var i: usize = nkeys;
                        while (i > index) : (i -= 1) {
                            keys[i] = keys[i - 1];
                            values[i] = values[i - 1];
                            childs[i + 1] = childs[i];
                        }

                        keys[index] = key;
                        values[index] = value;
                        childs[index + 1] = new_child;
                        return;
                    }
                }
            }else{
                for (0..nkeys) |index| {
                    if (key < keys[index]) {
                        var i: usize = nkeys;
                        while (i > index) : (i -= 1) {
                            keys[i] = keys[i - 1];
                            values[i] = values[i - 1];
                            childs[i + 1] = childs[i];
                        }

                        keys[index] = key;
                        values[index] = value;
                        childs[index + 1] = new_child;
                        return;
                    }
                }
            }

            keys[nkeys] = key;
            values[nkeys] = value;
            childs[nkeys + 1] = new_child;
        }

        inline fn change_parent(new_parent: *Node) void {
            for (new_parent.childs) |node| {
                if (node) |v| {
                    v.parent = new_parent;
                }
            }
        }

        inline fn split_root_node(
            keys: []Key, values: []Value, childs: []?*Node,
            child_node1: *Node, child_node2: *Node
        ) void {
            const middle_index = (Degree - 1)/2;
            const middle_index_plus_one = middle_index + 1;

            insert_in_empty_node(child_node1, keys[0..middle_index], values[0..middle_index]);
            insert_in_empty_node(child_node2, keys[middle_index_plus_one..], values[middle_index_plus_one..]);

            @memcpy(child_node1.childs[0..middle_index_plus_one], childs[0..middle_index_plus_one]);
            @memcpy(child_node2.childs[0..middle_index_plus_one], childs[middle_index_plus_one..]);

            change_parent(child_node1);
            change_parent(child_node2);

            keys[0] = keys[middle_index];
            values[0] = values[middle_index];
            childs[0] = child_node1;
            childs[1] = child_node2;

            @memset(childs[2..], null);
        }

        inline fn split_node(
            keys: []Key, values: []Value, childs: []?*Node,
            parent: *Node, new_child: *Node
        ) void {
            const middle_index = (Degree - 1)/2;
            const middle_index_plus_one = middle_index + 1;

            insert_in_empty_node(new_child, keys[middle_index_plus_one..], values[middle_index_plus_one..]);
            @memcpy(new_child.childs[0..middle_index_plus_one], childs[middle_index_plus_one..]);

            change_parent(new_child);

            @memset(childs[middle_index_plus_one..], null);
            do_insertion(parent, keys[middle_index], values[middle_index], new_child);
        }

        fn split_nodes(allocator: std.mem.Allocator, node: *Node) void {
            var current_node = node;
            while (current_node.nkeys == Degree) {
                const keys = &current_node.keys;
                const values = &current_node.values;
                const childs = &current_node.childs;

                const new_node1 = create_node(allocator) catch unreachable;
                const parent = current_node.parent;
                if (parent) |p_node| {
                    split_node(keys, values, childs, p_node, new_node1);
                    change_parent(current_node);
                    new_node1.parent = p_node;
                }else{
                    const new_node2 = create_node(allocator) catch unreachable;
                    split_root_node(keys, values, childs, new_node1, new_node2);
                    new_node1.parent = current_node;
                    new_node2.parent = current_node;
                }
                current_node.nkeys = 1;

                current_node = parent orelse break;
            }
        }

        inline fn insert_in_node(allocator: std.mem.Allocator, node: *Node, key: Key, value: Value) void {
            do_insertion(node, key, value, null);
            split_nodes(allocator, node);
        }

        pub fn insert(self: *@This(), key: Key, value: Value) bool {
            const allocator = self.allocator;

            var node: *Node = self.parent;
            if (node.nkeys > 0) {
                const previous_value_ptr = get_value_ptr(self, key, &node);
                if (previous_value_ptr != null) {
                    return false;
                }
            }

            insert_in_node(allocator, node, key, value);
            return true;
        }

        pub fn replace(self: *@This(), key: Key, value: Value) ?Value {
            const allocator = self.allocator;

            var node: *Node = self.parent;
            if (node.nkeys > 0) {
                const previous_value_ptr = get_value_ptr(self, key, &node);
                if (previous_value_ptr) |v| {
                    const previous_value = v.*;
                    v.* = value;
                    return previous_value;
                }
            }

            insert_in_node(allocator, node, key, value);
            return null;
        }

        inline fn delete_from_left(allocator: std.mem.Allocator, node: *?*Node, key: *Key, value: *Value) void {
            var node_with_bigger_value: *Node = undefined;
            value.* = find_max_from_node(node.*.?, key, &node_with_bigger_value).?.*;

            node_with_bigger_value.nkeys -= 1;
            if (node_with_bigger_value.nkeys == 0) {
                const p_node = node_with_bigger_value.parent.?;
                const p_last_node = &p_node.childs[p_node.nkeys];
                const rem_child = node_with_bigger_value.childs[0];
                if (p_last_node.* == node_with_bigger_value) {
                    p_last_node.* = rem_child;
                }else{
                    node.* = rem_child;
                }
                if (rem_child) |child| child.parent = p_node;

                allocator.destroy(node_with_bigger_value);
            }
        }

        inline fn delete_from_right(allocator: std.mem.Allocator, node: *?*Node, key: *Key, value: *Value) void {
            var node_with_smaller_value: *Node = undefined;
            value.* = find_min_from_node(node.*.?, key, &node_with_smaller_value).?.*;

            const nkeys = node_with_smaller_value.nkeys - 1;
            node_with_smaller_value.nkeys = nkeys;

            if (nkeys == 0) {
                const p_node = node_with_smaller_value.parent.?;
                const p_first_node = &p_node.childs[0];
                const rem_child = node_with_smaller_value.childs[1];
                if (p_first_node.* == node_with_smaller_value) {
                    p_first_node.* = rem_child;
                }else{
                    node.* = rem_child;
                }
                if (rem_child) |child| child.parent = p_node;

                allocator.destroy(node_with_smaller_value);
            }else{
                const keys = &node_with_smaller_value.keys;
                const values = &node_with_smaller_value.values;
                const childs = &node_with_smaller_value.childs;
                for (0..nkeys) |i| {
                    keys[i] = keys[i + 1];
                    values[i] = values[i + 1];
                    childs[i] = childs[i + 1];
                }
                childs[nkeys] = childs[nkeys + 1];
            }
        }

        inline fn perform_delete(
            allocator: std.mem.Allocator, node: *?*Node, func: anytype,
            keys: []Key, values: []Value, index: usize
        ) void {
            var key: Key = undefined;
            var value: Value = undefined;
            func(allocator, node, &key, &value);

            keys[index] = key;
            values[index] = value;
        }

        inline fn delete_key_from_node(
            allocator: std.mem.Allocator, node: *Node, keys: []Key,
            values: []Value, childs: []?*Node, index: usize
        ) void {
            const left_child = &childs[index];
            const right_child = &childs[index + 1];
            if (left_child.* != null) {
                perform_delete(allocator, left_child, delete_from_left, keys, values, index);
                return;
            }else if (right_child.* != null) {
                perform_delete(allocator, right_child, delete_from_right, keys, values, index);
                return;
            }

            const nkeys = node.nkeys - 1;
            node.nkeys = nkeys;

            if (nkeys == 0) {
                const p_node = node.parent orelse return;

                for (p_node.childs[0..(p_node.nkeys + 1)]) |*child| {
                    if (child.* == node) {
                        allocator.destroy(node);
                        child.* = null;
                        break;
                    }
                }
            }else{
                for (index..nkeys) |i| {
                    keys[i] = keys[i + 1];
                    values[i] = values[i + 1];
                    childs[i] = childs[i + 1];
                }
                childs[nkeys] = childs[nkeys + 1];
            }
        }

        pub fn delete(self: *@This(), key: Key) ?Value {
            var node: *Node = undefined;
            const value = get_value(self, key, &node)
                orelse return null;

            const keys = &node.keys;
            const values = &node.values;
            const childs = &node.childs;

            const nkeys = node.nkeys;
            if (@typeInfo(Key) == .float) {
                const eps = std.math.floatEps(Key);
                for (0..nkeys) |i| {
                    const diff = key - keys[i];
                    if (@abs(diff) <= eps) {
                        delete_key_from_node(self.allocator, node, keys, values, childs, i);
                        break;
                    }
                }
            }else{
                for (0..nkeys) |i| {
                    if (key == keys[i]) {
                        delete_key_from_node(self.allocator, node, keys, values, childs, i);
                        break;
                    }
                }
            }

            return value;
        }

        pub fn pop(self: *@This(), key: ?*Key) ?Value {
            var node: *Node = undefined;
            const value = get_max_value(self, key, &node)
                orelse return null;

            const keys = &node.keys;
            const values = &node.values;
            const childs = &node.childs;
            delete_key_from_node(self.allocator, node, keys, values, childs, node.nkeys - 1);

            return value;
        }
    };
}

test "BTree: Initialization creates empty tree" {
    var new_btree = try BTree(usize, usize, 3).init(std.testing.allocator);
    defer new_btree.deinit() catch unreachable;

    try std.testing.expectEqual(@as(usize, 0), new_btree.parent.nkeys);
    try std.testing.expectEqual(null, new_btree.parent.parent);
    for (new_btree.parent.childs) |v| try std.testing.expectEqual(null, v);
}

test "BTree: Insert and delete sequential usize elements" {
    var new_btree = try BTree(usize, usize, 3).init(std.testing.allocator);
    defer new_btree.deinit() catch unreachable;

    const element_count = 20;
    for (0..element_count) |v| {
        const value = (v + 1) * 23;
        const inserted = new_btree.insert(v, value);
        try std.testing.expect(inserted);
    }

    for (0..element_count) |v| {
        const value = new_btree.get_value(v, null);
        try std.testing.expectEqual((v + 1) * 23, value);
    }

    for (0..element_count) |v| {
        const value = new_btree.delete(v);
        try std.testing.expectEqual((v + 1) * 23, value);
    }
}

test "BTree: Complex insertion, partial deletion, and reinsertion" {
    var new_btree = try BTree(usize, usize, 3).init(std.testing.allocator);
    defer new_btree.deinit() catch unreachable;

    const element_count = 15;
    // Initial insertion of elements
    for (0..element_count) |v| {
        const value = v * 100 + 50;
        const inserted = new_btree.insert(v, value);
        try std.testing.expect(inserted);
    }

    // Verify all elements are present
    for (0..element_count) |v| {
        const value = new_btree.get_value(v, null);
        try std.testing.expectEqual(v * 100 + 50, value);
    }

    // Delete even-indexed elements
    for (0..element_count) |v| {
        if (v % 2 == 0) {
            const value = new_btree.delete(v);
            try std.testing.expectEqual(v * 100 + 50, value);
        }
    }

    // Verify odd-indexed elements remain, even-indexed are removed
    for (0..element_count) |v| {
        const value = new_btree.get_value(v, null);
        if (v % 2 == 0) {
            try std.testing.expectEqual(null, value);
        } else {
            try std.testing.expectEqual(v * 100 + 50, value);
        }
    }

    // Reinsert even-indexed elements with new values
    for (0..element_count) |v| {
        if (v % 2 == 0) {
            const value = v * 200 + 25;
            const inserted = new_btree.insert(v, value);
            try std.testing.expect(inserted);
        }
    }

    // Verify all elements with updated values
    for (0..element_count) |v| {
        const value = new_btree.get_value(v, null);
        if (v % 2 == 0) {
            try std.testing.expectEqual(v * 200 + 25, value);
        } else {
            try std.testing.expectEqual(v * 100 + 50, value);
        }
    }

    // Delete all elements
    for (0..element_count) |v| {
        const value = new_btree.delete(v);
        if (v % 2 == 0) {
            try std.testing.expectEqual(v * 200 + 25, value);
        } else {
            try std.testing.expectEqual(v * 100 + 50, value);
        }
    }

    // Verify tree is empty
    for (0..element_count) |v| {
        const value = new_btree.get_value(v, null);
        try std.testing.expectEqual(null, value);
    }
}

test "BTree: Random order insertion and deletion with usize" {
    var new_btree = try BTree(usize, usize, 3).init(std.testing.allocator);
    defer new_btree.deinit() catch unreachable;

    const element_count = 30;
    var values: [element_count]usize = undefined;
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

test "BTree: Random order insertion and deletion with floating point" {
    var new_btree = try BTree(f64, f64, 3).init(std.testing.allocator);
    defer new_btree.deinit() catch unreachable;

    const element_count = 100;
    const randpgr = std.crypto.random;
    var values: [element_count]f64 = undefined;
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
