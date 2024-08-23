const std = @import("std");

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

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var numbers = std.ArrayList(i32).init(allocator);
        errdefer numbers.deinit();

        var it = std.mem.tokenize(u8, line, " ");
        while (it.next()) |num_str| {
            const num = try std.fmt.parseInt(i32, num_str, 10);
            try numbers.append(num);
        }
        try lines.append(try numbers.toOwnedSlice());
    }

    return try lines.toOwnedSlice();
}

fn extrapolateNext(sequence: []const i32) i32 {
    if (std.mem.allEqual(i32, sequence, 0)) return 0;

    var diffs = std.heap.stackFallback(20 * @sizeOf(i32), std.heap.page_allocator);
    const allocator = diffs.get();

    var diff_seq = allocator.alloc(i32, sequence.len - 1) catch unreachable;
    defer if (diffs.fixed_buffer_allocator.end_index == 0) allocator.free(diff_seq);

    for (sequence[1..], 0..) |v, i| {
        diff_seq[i] = v - sequence[i];
    }

    return sequence[sequence.len - 1] + extrapolateNext(diff_seq);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const data = try parseInput(allocator, "d9_input.txt");

    var sum: i32 = 0;
    for (data) |sequence| {
        sum += extrapolateNext(sequence);
    }

    std.debug.print("Result: {d}\n", .{sum});
}
