// https://adventofcode.com/2023/day/1

const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayList;

const Replacement = struct {
    from: []const u8,
    to: u8,
};

const rs = [_]Replacement{
    .{ .from = "zero", .to = '0' },
    .{ .from = "one", .to = '1' },
    .{ .from = "two", .to = '2' },
    .{ .from = "three", .to = '3' },
    .{ .from = "four", .to = '4' },
    .{ .from = "five", .to = '5' },
    .{ .from = "six", .to = '6' },
    .{ .from = "seven", .to = '7' },
    .{ .from = "eight", .to = '8' },
    .{ .from = "nine", .to = '9' },
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile("d1_input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [128]u8 = undefined;
    var sum: u32 = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const new_line = try replaceSubStrings(allocator, line);
        sum += try extractNumber(new_line);
    }

    std.debug.print("{d}\n", .{sum});
}

fn replaceSubStrings(allocator: mem.Allocator, input: []const u8) ![]const u8 {
    var result = try ArrayList(u8).initCapacity(allocator, input.len);
    errdefer result.deinit();

    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        for (rs) |r| {
            if (mem.startsWith(u8, input[i..], r.from)) {
                try result.append(r.to);
                break;
            }
        } else {
            try result.append(input[i]);
        }
    }
    return result.items;
}

fn extractNumber(line: []const u8) !u32 {
    var first: ?u8 = null;
    var last: u8 = 0;

    for (line) |char| {
        if (std.ascii.isDigit(char)) {
            if (first == null) {
                first = char - '0';
            }
            last = char - '0';
        }
    }

    if (first) |f| {
        return f * 10 + last;
    }

    return error.NumberNotFound;
}
