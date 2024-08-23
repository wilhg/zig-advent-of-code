const std = @import("std");

fn parseInput(allocator: std.mem.Allocator, file_path: []const u8) ![][]i32 {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var lines = std.ArrayList([]i32).init(allocator);
    defer lines.deinit();

    var buf: [128]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var numbers = std.ArrayList(i32).init(allocator);
        defer numbers.deinit();

        var it = std.mem.tokenize(u8, line, " ");
        while (it.next()) |num_str| {
            const num = try std.fmt.parseInt(i32, num_str, 10);
            try numbers.append(num);
        }
        try lines.append(try numbers.toOwnedSlice());
    }

    return try lines.toOwnedSlice();
}

fn areAllZeroes(data: []const i32) bool {
    for (data) |num| {
        if (num != 0) return false;
    }
    return true;
}

fn subRow(allocator: std.mem.Allocator, data: []const i32) ![]i32 {
    var new_row = try allocator.alloc(i32, data.len - 1);
    for (0..data.len - 1) |i| {
        new_row[i] = data[i + 1] - data[i];
    }
    return new_row;
}

fn recur(allocator: std.mem.Allocator, row: []const i32) !i32 {
    if (areAllZeroes(row)) {
        return 0;
    }

    const sub_row = try subRow(allocator, row);
    defer allocator.free(sub_row);

    const sub_result = try recur(allocator, sub_row);
    return row[row.len - 1] + sub_result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const data = try parseInput(allocator, "d9_input.txt");
    defer {
        for (data) |line| {
            allocator.free(line);
        }
        allocator.free(data);
    }

    var result: i32 = 0;
    for (data) |row| {
        result += try recur(allocator, row);
    }
    std.debug.print("Result: {d}\n", .{result});
}
