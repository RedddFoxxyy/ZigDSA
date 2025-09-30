const std = @import("std");
const print = std.debug.print;

// ----Linked List(Doubly)----
pub fn LinkedList(comptime T: type) type {
    return struct {
        // Using this we can do *Self instead of *LinkedList.
        const Self = @This();

        pub const Node = struct {
            prev: ?*Node = null,
            next: ?*Node = null,
            data: T,
        };

        head: ?*Node = null,
        tail: ?*Node = null,
        length: usize = 0,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            var current = self.head;
            while (current) |node| {
                const next_node = node.next;
                self.allocator.destroy(node);
                current = next_node;
            }
            self.* = undefined;
        }

        pub fn len(self: *Self) usize {
            return self.length;
        }

        pub fn is_empty(self: *Self) bool {
            return self.length == 0;
        }

        pub fn push_front(self: *Self, data: T) !void {
            const new_node = try self.allocator.create(Node);
            new_node.* = .{ .data = data };

            if (self.head) |old_head| {
                old_head.prev = new_node;
                new_node.next = old_head;
                self.head = new_node;
            } else {
                self.head = new_node;
                self.tail = new_node;
            }
            self.length += 1;
        }

        pub fn push(self: *Self, data: T) !void {
            if (self.tail) |old_tail| {
                const new_node = try self.allocator.create(Node);
                new_node.* = .{ .prev = old_tail, .data = data };
                old_tail.next = new_node;
                self.tail = new_node;
                self.length += 1;
            } else {
                _ = try self.push_front(data);
            }
        }

        pub fn pop(self: *Self) *Node {
            const popped_tail = self.tail.?;
            var prev_node = popped_tail.prev.?;
            prev_node.next = null;
            self.tail = prev_node;
            self.length -= 1;
            return popped_tail;
        }

        pub fn pop_and_destroy(self: *Self) void {
            self.allocator.destroy(self.pop());
        }

        pub fn pop_front(self: *Self) *Node {
            const popped_head = self.head.?;
            var next_node = popped_head.next.?;
            next_node.prev = null;
            self.head = next_node;
            self.length -= 1;
            return popped_head;
        }

        pub fn pop_front_and_destroy(self: *Self) void {
            self.allocator.destroy(self.pop_front());
        }

        pub fn pretty_print(self: *Self) void {
            var current = self.head;
            while (current) |node| {
                print("{} -> ", .{node.data});
                current = node.next;
            }
            print("null\n", .{});
        }

        pub fn pretty_print_verbose(self: *Self) void {
            self.pretty_print();
            print("List length: {d}\n", .{self.len()});
        }
    };
}

// ----Tests----

test "Linked List" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;
    const expectEqual = std.testing.expectEqual;

    // 1. Test Initialization
    var list = LinkedList(i32).init(allocator);
    try expect(list.is_empty());
    try expectEqual(@as(usize, 0), list.len());

    // Deinit must be called to free memory from subsequent tests
    list.deinit();

    // 2. Test push (append to the end)
    list = LinkedList(i32).init(allocator);
    defer list.deinit(); // Ensures deinit is called even if a test fails

    try list.push(10);
    // After one push, head and tail should be the same node
    try expect(!list.is_empty());
    try expectEqual(@as(usize, 1), list.len());
    try expect(list.head != null);
    try expect(list.head == list.tail);
    try expectEqual(10, list.head.?.data);

    try list.push(20);
    // After two pushes, head and tail are different
    try expectEqual(@as(usize, 2), list.len());
    try expect(list.head != list.tail);
    try expectEqual(10, list.head.?.data);
    try expectEqual(20, list.tail.?.data);
    // Check links
    try expect(list.head.?.next == list.tail);
    try expect(list.tail.?.prev == list.head);

    // 3. Test push_front
    var list2 = LinkedList(u8).init(allocator);
    defer list2.deinit();

    try list2.push_front(5);
    try list2.push_front(3);
    // List should be: 3 -> 5
    try expectEqual(@as(usize, 2), list2.len());
    try expectEqual(@as(i32, 3), list2.head.?.data);
    try expectEqual(@as(i32, 5), list2.tail.?.data);

    // 4. Test pop
    var list3 = LinkedList(i32).init(allocator);
    defer list3.deinit();

    try list3.push(10);
    try list3.push(20);
    try list3.push(450);
    try list3.push_front(5);
    try list3.push_front(3);
    try list3.push_front(7);

    // List should be: 7 -> 3 -> 5 -> 10 -> 20 -> 450
    try expectEqual(@as(usize, 6), list3.len());
    try expectEqual(@as(i32, 7), list3.head.?.data);
    try expectEqual(@as(i32, 450), list3.tail.?.data);

    // Pop last 2 nodes and destroy them.
    allocator.destroy(list3.pop());
    list3.pop_and_destroy();

    // Pop first 2 nodes and destroy them.
    allocator.destroy(list3.pop_front());
    list3.pop_front_and_destroy();

    // List should be: 5 -> 10
    try expectEqual(@as(usize, 2), list3.len());
    try expectEqual(@as(i32, 5), list3.head.?.data);
    try expectEqual(@as(i32, 10), list3.tail.?.data);

    // 5. Test Mixed Operations and Traversal
    var list4 = LinkedList(i32).init(allocator);
    defer list4.deinit();

    try list4.push(2); // list: 2
    try list4.push(3); // list: 2 -> 3
    try list4.push_front(1); // list: 1 -> 2 -> 3

    try expectEqual(@as(usize, 3), list4.len());
    try expectEqual(1, list4.head.?.data);
    try expectEqual(3, list4.tail.?.data);

    // Traverse forward
    var current = list4.head;
    try expectEqual(1, current.?.data);
    current = current.?.next;
    try expectEqual(2, current.?.data);
    current = current.?.next;
    try expectEqual(3, current.?.data);

    // Traverse backward
    current = list4.tail;
    try expectEqual(3, current.?.data);
    current = current.?.prev;
    try expectEqual(2, current.?.data);
}
