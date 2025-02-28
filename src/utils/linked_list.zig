const std = @import("std");
const builtin = @import("builtin");

pub fn LinkedList(comptime T: type) type {
    return struct {
        const _linked_list_node = struct {
            data: T,

            prev: ?*_linked_list_node,
            next: ?*_linked_list_node
        };

        pub const Node = *_linked_list_node;

        pub const errors = error {
            CannotHasElementsWhenRealasing,
            LinkedListEmpty
        };

        allocator: std.mem.Allocator,
        first: ?Node = null,
        last: ?Node = null,
        len: usize = 0,

        pub fn init(allocator: std.mem.Allocator) @This() {
            return @This(){
                .allocator = allocator,
            };
        }

        pub fn create_new_node(self: *const @This(), data: T) !Node {
            const new_node = try self.allocator.create(_linked_list_node);
            new_node.data = data;
            return new_node;
        }

        pub fn release_node(self: *const @This(), node: Node) void {
            self.allocator.destroy(node);
        }

        pub fn unlink_node(self: *@This(), node: Node) void {
            if (builtin.mode == .Debug and self.len == 0) {
                @panic("Trying to pop elements while linked list is empty");
            }

            const prev_node = node.prev;
            const next_node = node.next;

            if (prev_node) |n| {
                n.next = next_node;
            }else{
                self.first = next_node;
            }

            if (next_node) |n| {
                n.prev = prev_node;
            }else{
                self.last = prev_node;
            }

            self.len -= 1;
        }

        pub fn append_node(self: *@This(), new_node: Node) void {
            if (self.last) |last_node| {
                last_node.next = new_node;
            }

            new_node.prev = self.last;
            new_node.next = null;

            self.last = new_node;

            if (self.first == null) {
                self.first = new_node;
            }

            self.len += 1;

        }

        pub fn append(self: *@This(), data: T) !void {
            const new_node = try self.create_new_node(data);
            self.append_node(new_node);
        }

        pub fn appendleft_node(self: *@This(), new_node: Node) void {
            if (self.first) |first_node| {
                first_node.prev = new_node;
            }

            new_node.prev = null;
            new_node.next = self.first;

            self.first = new_node;
            if (self.last == null) {
                self.last = new_node;
            }
            self.len += 1;
        }

        pub fn appendleft(self: *@This(), data: T) !void {
            const new_node = try self.create_new_node(data);
            self.appendleft_node(new_node);
        }

        pub fn pop_node(self: *@This()) !Node {
            const last_node = self.last orelse return errors.LinkedListEmpty;

            if (last_node.prev) |prev_node| {
                prev_node.next = null;
                self.last = prev_node;
                last_node.prev = null;
            }else{
                self.first = null;
                self.last = null;
            }
            self.len -= 1;

            return last_node;
        }

        pub fn pop(self: *@This()) !T {
            const last_node = try self.pop_node();
            const data = last_node.data;
            self.allocator.destroy(last_node);
            return data;
        }

        pub fn popleft_node(self: *@This()) !Node {
            const first_node = self.first orelse return errors.LinkedListEmpty;

            if (first_node.next) |next_node| {
                next_node.prev = null;
                self.first = next_node;
                first_node.next = null;
            }else{
                self.first = null;
                self.last = null;
            }
            self.len -= 1;
            return first_node;
        }

        pub fn popleft(self: *@This()) !T {
            const first_node = try self.popleft_node();

            const data = first_node.data;
            self.allocator.destroy(first_node);
            return data;
        }

        pub fn is_empty(self: *@This()) bool {
            return (self.len == 0);
        }

        pub fn clear(self: *@This()) void {
            const allocator = self.allocator;
            var node = self.first;
            while (node) |n| {
                node = n.next;
                allocator.destroy(n);
            }
            self.* = @This().init(allocator);
        }

        pub fn extend(self: *@This(), list: *@This()) void {
            const f_node2 = list.first orelse return;
            const l_node2 = list.last.?;
            const new_len = list.len;

            list.first = null;
            list.last = null;
            list.len = 0;

            if (self.last) |l_node| {
                f_node2.prev = l_node;
                l_node.next = f_node2;
            }else{
                self.first = f_node2;
            }

            self.last = l_node2;
            self.len += new_len;
        }
    };
}

test "LinkedList initialization creates empty list" {
    const list: LinkedList(usize) = LinkedList(usize).init(std.testing.allocator);

    try std.testing.expect(list.first == null);
    try std.testing.expect(list.last == null);
    try std.testing.expect(list.len == 0);
}

test "LinkedList append adds elements in order" {
    var list = LinkedList(usize).init(std.testing.allocator);
    defer list.clear();

    const elements = [_]usize{10, 20, 100, 10, 10, 20};
    for (elements) |elem| {
        try list.append(elem);
    }

    var node = list.first;
    var elements_total: usize = 0;
    while (node != null) : (elements_total += 1) {
        try std.testing.expectEqual(elements[elements_total], node.?.data);
        node = node.?.next;
    }

    try std.testing.expectEqual(elements.len, elements_total);
}

test "LinkedList appendleft adds elements in reverse order" {
    var list = LinkedList(usize).init(std.testing.allocator);
    defer list.clear();

    const elements = [_]usize{10, 20, 100, 10, 10, 20};
    for (elements) |elem| {
        try list.appendleft(elem);
    }

    var node = list.last;
    var elements_total: usize = 0;
    while (node != null) : (elements_total += 1) {
        try std.testing.expectEqual(elements[elements_total], node.?.data);
        node = node.?.prev;
    }

    try std.testing.expectEqual(elements.len, elements_total);
}

test "LinkedList pop and popleft remove elements correctly" {
    var list = LinkedList(usize).init(std.testing.allocator);
    defer list.clear();

    try std.testing.expectError(LinkedList(usize).errors.LinkedListEmpty, list.pop());
    try std.testing.expectError(LinkedList(usize).errors.LinkedListEmpty, list.popleft());

    const elements = [_]usize{2, 3, 10, 40};
    for (elements) |elem| {
        try list.append(elem);
    }

    try std.testing.expectEqual(@as(usize, 2), try list.popleft());
    try std.testing.expectEqual(@as(usize, 40), try list.pop());
    try std.testing.expectEqual(@as(usize, 3), try list.popleft());
    try std.testing.expectEqual(@as(usize, 10), try list.pop());

    try std.testing.expect(list.first == null);
    try std.testing.expect(list.last == null);
}

test "LinkedList is_empty method works correctly" {
    var list = LinkedList(usize).init(std.testing.allocator);
    defer list.clear();

    try std.testing.expect(list.is_empty());

    try list.append(3);
    try std.testing.expect(!list.is_empty());

    _ = try list.pop();
    try std.testing.expect(list.is_empty());
}

test "LinkedList clear method removes all elements" {
    var list = LinkedList(usize).init(std.testing.allocator);
    defer list.clear();

    const elements = [_]usize{1, 2, 3, 4, 5};
    for (elements) |elem| {
        try list.append(elem);
    }

    try std.testing.expectEqual(@as(usize, elements.len), list.len);
    try std.testing.expect(!list.is_empty());

    list.clear();

    try std.testing.expectEqual(@as(usize, 0), list.len);
    try std.testing.expect(list.is_empty());
    try std.testing.expect(list.first == null);
    try std.testing.expect(list.last == null);
}

