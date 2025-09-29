const std = @import("std");
const print = std.debug.print;
const zigDSA = @import("zigDSA");
const lists = zigDSA.lists;

// Testing the Library here:
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // LinkedList:
    var I32List = lists.LinkedList(i32).init(allocator);
    defer I32List.deinit();

    _ = try I32List.push(2);
    _ = try I32List.push(10);
    _ = try I32List.push(4);
    _ = try I32List.push_front(7);

    var current = I32List.head;
    while (current) |node| {
        print("{} -> ", .{node.data});
        current = node.next;
    }

    print("null\n", .{});
    print("List length: {d}\n", .{I32List.len()});
}
