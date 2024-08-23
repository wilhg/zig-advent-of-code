const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) @panic("Memory leak detected");
    }
    const allocator = gpa.allocator();

    // Create a 2D ArrayList
    var array_2d = std.ArrayList(std.ArrayList(u8)).init(allocator);
    defer {
        for (array_2d.items) |row| {
            row.deinit();
        }
        array_2d.deinit();
    }

    // Fill the 2D ArrayList with some data
    try fillArray2D(&array_2d, 3, 4);

    // Print the contents of the 2D ArrayList
    for (array_2d.items, 0..) |row, i| {
        std.debug.print("Row {d}: ", .{i});
        for (row.items) |item| {
            std.debug.print("{d} ", .{item});
        }
        std.debug.print("\n", .{});
    }
}

fn fillArray2D(array: *std.ArrayList(std.ArrayList(u8)), rows: usize, cols: usize) !void {
    try array.ensureTotalCapacity(rows);

    var value: u8 = 1;
    for (0..rows) |_| {
        var row = std.ArrayList(u8).init(array.allocator);
        try row.ensureTotalCapacity(cols);

        for (0..cols) |_| {
            try row.append(value);
            value += 1;
        }

        try array.append(row);
    }
}
