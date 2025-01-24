const std = @import("std");

pub fn init(
    comptime Key: type,
    comptime Value: type
) type {
    return struct {
        pub const BTree = @This();

        pub const Node = struct {
            parent: ?*Node = null,
            keys: [3]Key,
            values: [3]Value,
            childs: [4]bool,

            nkeys: u2 = 0
        };

        allocator: std.mem.Allocator,
        nodes: []Node,
        items: usize = 0,

        pub fn init(allocator: std.mem.Allocator) !*BTree {
            const new_btree = try allocator.create(BTree);
            errdefer allocator.destroy(new_btree);

            new_btree.* = .{
                .allocator = allocator,
                .nodes = try allocator.alloc(Node, 1)
            };

            return new_btree;
        }

        fn create_child_nodes(self: *BTree, childs_num: usize) !void {
            self.nodes = try self.allocator.realloc(self.nodes, childs_num);
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
            var current_node_index: usize = 0;
            const nodes = self.nodes;

            loop: while (true) {
                const current_node = &nodes[current_node_index];
                const nkeys = current_node.nkeys;
                if (nkeys == 0) {
                    if (current_node_index != 0) unreachable;
                }

                for (
                    current_node.keys[0..nkeys], current_node.values[0..nkeys],
                    current_node.childs[0..nkeys], 0..
                ) |k, v, ch, i| {
                    if (@typeInfo(@TypeOf(Key)) == .float) {
                        const epsilon: comptime_float = comptime std.math.floatEps(Key);
                        if (@abs(k - key) < epsilon) {
                            return v;
                        }else if ((k - key) > epsilon) {
                            if (!ch) return null;

                            current_node_index = 4 * current_node_index + i + 1;
                            continue :loop;
                        }
                    }else{
                        if (k == key) {
                            return v;
                        }else if (k > key) {
                            if (!ch) return null;

                            current_node_index = 4 * current_node_index + i + 1;
                            continue :loop;
                        }
                    }
                }

                const is_last_child_active = current_node.childs[nkeys];
                if (!is_last_child_active) return null;
                current_node_index = 4 * current_node_index + nkeys + 1;
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
                    if (index != 0) unreachable;
                }

                const is_last_child_active = current_node.childs[nkeys];
                if (!is_last_child_active) {
                    break;
                }

                index = 4 * index + nkeys + 1;
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
                    if (index != 0) unreachable;
                }

                const is_first_child_active = current_node.childs[0];
                if (!is_first_child_active) {
                    break;
                }

                index = 4 * index + 1;
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
            return find_min_from_node(self.nodes, 0, key, ret_node_index);
        }

    };
}
