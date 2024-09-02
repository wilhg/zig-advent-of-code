const std = @import("std");

// Define your struct
const Person = struct {
    name: []const u8,
    age: u32,
};

pub fn main() !void {
    // JSON string
    const json_string =
        \\{"name": "John Doe", "age": 30}
    ;

    // Parse the JSON string
    var parsed = try std.json.parseFromSlice(std.json.Value, std.heap.page_allocator, json_string, .{});
    defer parsed.deinit();

    // Access the root object
    const root = parsed.value.object;

    // Create a Person struct from the parsed JSON
    const person = Person{
        .name = root.get("name").?.string,
        .age = @intCast(root.get("age").?.integer),
    };

    // Use the parsed data
    std.debug.print("Name: {s}, Age: {}\n", .{ person.name, person.age });
}
