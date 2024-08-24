const std = @import("std");
const LEN: usize = 21;

fn parseInput(allocator: std.mem.Allocator, file_path: []const u8) ![][]i32 {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var lines = std.ArrayList([]i32).init(allocator);
    errdefer {
        for (lines.items) |line| allocator.free(line);
        lines.deinit();
    }

    var buf: [128]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var numbers = std.ArrayList(i32).init(allocator);
        errdefer numbers.deinit();

        var it = std.mem.tokenize(u8, line, " ");
        while (it.next()) |num_str| {
            const num = try std.fmt.parseInt(i32, num_str, 10);
            try numbers.append(num);
        }

        // Part 2:Reverse the order of numbers in the row
        std.mem.reverse(i32, numbers.items);

        try lines.append(try numbers.toOwnedSlice());
    }

    return try lines.toOwnedSlice();
}

inline fn notZeros(arr: []const i32) bool {
    return !std.mem.allEqual(i32, arr, 0);
}

fn extrapolateNext(sequence: []const i32) i32 {
    // 2D array to store the original sequence and all levels of differences
    var diffs: [LEN][LEN]i32 = undefined;

    var level: usize = 0;
    // Copy the input sequence to the first row of diffs
    @memcpy(diffs[0][0..sequence.len], sequence);

    // Calculate differences until we reach a row of all zeros
    while (level == 0 or notZeros(diffs[level][0 .. LEN - level])) : (level += 1) {
        // Calculate the differences for the next level
        for (0..LEN - level - 1) |i| {
            diffs[level + 1][i] = diffs[level][i + 1] - diffs[level][i];
        }
    }

    // Extrapolate the next value by summing the last elements of each level
    var next_value: i32 = 0;

    while (level > 0) {
        level -= 1;
        next_value += diffs[level][LEN - level - 1];
    }

    return next_value;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const data = try parseInput(allocator, "d9_input.txt");
    defer {
        for (data) |sequence| allocator.free(sequence);
        allocator.free(data);
    }

    var sum: i32 = 0;
    for (data) |sequence| {
        sum += extrapolateNext(sequence);
    }

    std.debug.print("Result: {d}\n", .{sum});
}
