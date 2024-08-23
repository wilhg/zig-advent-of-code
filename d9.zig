const std = @import("std");
const ArrayList = std.ArrayList;

fn parseInput(allocator: std.mem.Allocator, file_path: []const u8) !ArrayList(ArrayList(i64)) {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var lines = ArrayList(ArrayList(i64)).init(allocator);

    var buf: [128]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.tokenize(u8, line, " ");
        var row = ArrayList(i64).init(allocator);
        while (it.next()) |num_str| {
            const num = try std.fmt.parseInt(i64, num_str, 10);
            try row.append(num);
        }
        try lines.append(row);
    }

    return lines;
}

fn areAllZeroes(data: ArrayList(i64)) bool {
    for (data.items) |num| {
        if (num != 0) return false;
    }
    return true;
}

fn subRow(allocator: std.mem.Allocator, data: ArrayList(i64)) !ArrayList(i64) {
    var new_row = ArrayList(i64).init(allocator);
    for (0..data.items.len - 1) |i| {
        // std.debug.print("x={d}, i: {d}, i+1: {d}, diff: {d}\n", .{ i, data.items[i], data.items[i + 1], data.items[i + 1] - data.items[i] });
        try new_row.append(data.items[i + 1] - data.items[i]);
    }
    return new_row;
}

fn recur(allocator: std.mem.Allocator, row: *const ArrayList(i64)) !ArrayList(i64) {
    var new_row = try ArrayList(i64).initCapacity(allocator, row.items.len + 1);
    try new_row.appendSlice(row.items);

    if (areAllZeroes(new_row)) {
        try new_row.append(0);
        return new_row;
    }

    const sub_row = try subRow(allocator, new_row);
    defer sub_row.deinit();

    const last = new_row.items[new_row.items.len - 1];
    const sub_last = sub_row.items[sub_row.items.len - 1];
    // std.debug.print("last: {d}, sub_last: {d}\n", .{ last, sub_last });
    try new_row.append(last + sub_last);
    return recur(allocator, &new_row);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const data = try parseInput(allocator, "d9_input.txt");
    defer {
        for (data.items) |line| {
            line.deinit();
        }
        data.deinit();
    }
    // Print parsed data for verification
    // for (data.items) |row| {
    //     for (row.items) |num| {
    //         std.debug.print("{d} ", .{num});
    //     }
    //     std.debug.print("\n", .{});
    // }

    var result = try recur(allocator, &data.items[0]);
    defer result.deinit();
    std.debug.print("Result: {d}\n", .{result.items[result.items.len - 1]});
}
