const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(std.ArrayList(u8)).init(allocator);
    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit();
        }
        map.deinit();
    }

    // Add some data to the map
    try addToMap(&map, "key1", &[_]u8{ 1, 2, 3 });
    try addToMap(&map, "key2", &[_]u8{ 4, 5, 6, 7 });
    try addToMap(&map, "key3", &[_]u8{ 8, 9 });

    // Print the contents of the map
    var it = map.iterator();
    while (it.next()) |entry| {
        std.debug.print("Key: {s}, Value: ", .{entry.key_ptr.*});
        for (entry.value_ptr.items) |item| {
            std.debug.print("{d} ", .{item});
        }
        std.debug.print("\n", .{});
    }
}

fn addToMap(map: *std.StringHashMap(std.ArrayList(u8)), key: []const u8, values: []const u8) !void {
    var list = try map.getOrPut(key);
    if (!list.found_existing) {
        list.value_ptr.* = std.ArrayList(u8).init(map.allocator);
    }
    for (values) |value| {
        try list.value_ptr.append(value);
    }
}
