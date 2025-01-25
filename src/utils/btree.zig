const std = @import("std");

pub fn init(
    comptime Key: type,
    comptime Value: type,
    comptime degree: usize
) type {
    return struct {
        pub const BTree = @This();

        pub const Node = struct {
            parent: ?*Node = null,
            keys: [degree]Key,
            values: [degree]Value,
            childs: [degree + 1]bool,

            nkeys: usize = 0
        };

        allocator: std.mem.Allocator,
        nodes: []Node,
        items: usize = 0,
        items_per_level: []usize,

        pub fn init(allocator: std.mem.Allocator) !*BTree {
            const new_btree = try allocator.create(BTree);
            errdefer allocator.destroy(new_btree);

            const nodes = try allocator.alloc(Node, 1);
            errdefer allocator.free(nodes);

            const items_per_level = try allocator.alloc(usize, 1);
            errdefer allocator.free(items_per_level);

            new_btree.* = .{
                .allocator = allocator,
                .nodes = nodes,
                .items_per_level = items_per_level
            };

            return new_btree;
        }

        fn create_new_childs(self: *BTree) !void {
            const allocator = self.allocator;

            const nodes = self.nodes;
            const items_per_level = self.items_per_level;
            const levels = items_per_level.len;

            const old_items_len = nodes.len;
            const new_nodes_len = old_items_len + std.math.pow(usize, (degree + 1), levels);

            nodes = try allocator.realloc(nodes, new_nodes_len);
            items_per_level = allocator.realloc(items_per_level, levels + 1) catch unreachable;

            for (nodes[old_items_len..]) |*node| {
                node.* = .{
                    .parent = null,
                    .keys = .{ undefined, } ** 3,
                    .values = .{ undefined, } ** 3,
                    .childs = .{ false, } ** (degree + 1),
                    .nkeys = 0,
                };
            }

            items_per_level[levels] = 0;

            self.items_per_level = items_per_level;
            self.nodes = nodes;
        }

        fn remove_childs(self: *BTree) !void {
            const allocator = self.allocator;

            const nodes = self.nodes;
            const items_per_level = self.items_per_level;

            const levels = items_per_level.len;

            const new_nodes_len = nodes.len - std.math.pow(usize, (degree + 1), levels - 1);

            self.nodes = try allocator.realloc(nodes, new_nodes_len);
            self.items_per_level = allocator.realloc(items_per_level, levels - 1) catch unreachable;
        }

        pub fn deinit(self: *BTree) void {
            if (self.items > 0) {
                @panic("BTree is not empty");
            }

            const allocator = self.allocator;
            allocator.free(self.nodes);
            allocator.destroy(self);
        }

        pub fn search(self: *BTree, key: Key) ?Value {
            if (self.items == 0) {
                return null;
            }

            var current_node_index: usize = 0;
            const nodes = self.nodes;

            loop: while (true) {
                const current_node = &nodes[current_node_index];
                const nkeys = current_node.nkeys;
                if (nkeys == 0) {
                    unreachable;
                }

                if (@typeInfo(Key) == .float) {
                    const epsilon: comptime_float = comptime std.math.floatEps(Key);
                    for (
                        current_node.keys[0..nkeys], current_node.values[0..nkeys],
                        current_node.childs[0..nkeys], 0..
                    ) |k, v, ch, i| {
                        const diff = k - key;
                        if (@abs(diff) < epsilon) {
                            return v;
                        }else if (diff > epsilon) {
                            if (!ch) return null;

                            current_node_index = (degree + 1) * current_node_index + i + 1;
                            continue :loop;
                        }
                    }
                }else{
                    for (
                        current_node.keys[0..nkeys], current_node.values[0..nkeys],
                        current_node.childs[0..nkeys], 0..
                    ) |k, v, ch, i| {
                        if (k == key) {
                            return v;
                        }else if (k > key) {
                            if (!ch) return null;

                            current_node_index = (degree + 1) * current_node_index + i + 1;
                            continue :loop;
                        }
                    }
                }

                const is_last_child_active = current_node.childs[nkeys];
                if (!is_last_child_active) return null;
                current_node_index = (degree + 1) * current_node_index + nkeys + 1;
            }

            unreachable;
        }

        inline fn find_max_from_node(
            nodes: []Node, current_node_index: usize,
            key: ?*Key, ret_node_index: ?*usize
        ) ?Value {
            var index = current_node_index;
            while (true) {
                const current_node: *Node = &nodes[index];
                const nkeys = current_node.nkeys;
                if (nkeys == 0) {
                    unreachable;
                }

                const is_last_child_active = current_node.childs[nkeys];
                if (!is_last_child_active) {
                    break;
                }

                index = (degree + 1) * index + nkeys + 1;
            }

            if (ret_node_index) |new_node_index| {
                new_node_index.* = index;
            }

            const current_node = &nodes[index];
            const nkeys = current_node.nkeys;
            if (nkeys == 0) return null;

            if (key) |k| k.* = current_node.keys[nkeys - 1];
            return current_node.values[nkeys - 1];
        }

        pub fn find_max(self: *BTree, key: ?*Key, ret_node_index: ?*usize) ?Value {
            if (self.items == 0) {
                return null;
            }

            return find_max_from_node(self.nodes, 0, key, ret_node_index);
        }

        inline fn find_min_from_node(
            nodes: []Node, current_node_index: usize,
            key: ?*Key, ret_node_index: ?*usize
        ) ?Value {
            var index = current_node_index;
            while (true) {
                const current_node: *Node = &nodes[index];
                const nkeys = current_node.nkeys;
                if (nkeys == 0) {
                    unreachable;
                }

                const is_first_child_active = current_node.childs[0];
                if (!is_first_child_active) {
                    break;
                }

                index = (degree + 1) * index + 1;
            }

            if (ret_node_index) |new_node_index| {
                new_node_index.* = index;
            }

            const current_node = &nodes[index];
            const nkeys = current_node.nkeys;
            if (nkeys == 0) return null;

            if (key) |k| k.* = current_node.keys[0];
            return current_node.values[0];
        }

        pub fn find_min(self: *BTree, key: ?*Key, ret_node_index: ?*usize) ?Value {
            if (self.items == 0) {
                return null;
            }

            return find_min_from_node(self.nodes, 0, key, ret_node_index);
        }

        inline fn insert_in_empty_node(node: *Node, key: Key, value: Value) void {
            node.keys[0] = key;
            node.values[0] = value;
            node.nkeys = 1;
        }

        inline fn append_key_and_value(
            nkeys: usize, index: usize,
            keys: []Key, values: []Value, 
            childs: []bool, new_key: Key,
            new_value: Value, has_child: bool,
        ) void {
            var i: usize = nkeys;
            while (i > index) : (i -= 1) {
                keys[i] = keys[i - 1];
                values[i] = values[i - 1];
                childs[i + 1] = childs[i];
            }
            
            keys[index] = new_key;
            values[index] = new_value;
            childs[index + 1] = has_child;
        }

        fn do_insertion(node: *Node, key: Key, value: Value, has_child: bool) void {
            const nkeys = node.nkeys;
            if (nkeys == 0) {
                return insert_in_empty_node(node, key, value);
            }

            defer node.nkeys += 1;

            const keys = &node.keys;
            const values = &node.values;
            const childs = &node.childs;

            if (@typeInfo(Key) == .float) {
                const epsilon = comptime std.math.floatEps(Key);
                for (0..nkeys) |index| {
                    if ((key - keys[index]) < epsilon) {
                        return append_key_and_value(
                            nkeys, index, keys, values, childs, key, value, has_child,
                        );
                    }
                }
            }else{
                for (0..nkeys) |index| {
                    if (key < keys[index]) {
                        return append_key_and_value(
                            nkeys, index, keys, values, childs, key, value, has_child,
                        );
                    }
                }
            }
        }

    };
}
