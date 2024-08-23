const std = @import("std");
const ArrayList = std.ArrayList;

fn parseInput(allocator: std.mem.Allocator, file_path: []const u8) !ArrayList(ArrayList(i32)) {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var lines = ArrayList(ArrayList(i32)).init(allocator);

    var buf: [4096]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.tokenize(u8, line, " ");
        var row = ArrayList(i32).init(allocator);
        while (it.next()) |num_str| {
            const num = try std.fmt.parseInt(i32, num_str, 10);
            try row.append(num);
        }
        try lines.append(row);
    }

    return lines;
}

fn areAllZeroes(data: ArrayList(i32)) bool {
    for (data.items) |num| {
        if (num != 0) return false;
    }
    return true;
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
    for (data.items) |row| {
        for (row.items) |num| {
            std.debug.print("{d} ", .{num});
        }
        std.debug.print("\n", .{});
    }
}
