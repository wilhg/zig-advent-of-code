// https://adventofcode.com/2023/day/1

const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayList;

const Replacement = struct {
    from: []const u8,
    to: u8,
};
const rs = [10]Replacement{ .{ .from = "zero", .to = '0' }, .{ .from = "one", .to = '1' }, .{ .from = "two", .to = '2' }, .{ .from = "three", .to = '3' }, .{ .from = "four", .to = '4' }, .{ .from = "five", .to = '5' }, .{ .from = "six", .to = '6' }, .{ .from = "seven", .to = '7' }, .{ .from = "eight", .to = '8' }, .{ .from = "nine", .to = '9' } };

pub fn main() !void {
    const file = try std.fs.cwd().openFile("d1_input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [8192]u8 = undefined;
    var sum: u16 = 0;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Memory leak detected");
    }
    const allocator = gpa.allocator();
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const new_line = try replaceSubStrings(allocator, line, &rs);
        defer allocator.free(new_line);

        const first = try firstNumber(new_line);
        const last = try lastNumber(new_line);
        sum += combineNumbers(first, last);
    }

    std.debug.print("{d}\n", .{sum});
}

fn replaceSubStrings(allocator: mem.Allocator, input: []const u8, replacements: []const Replacement) ![]const u8 {
    var result = ArrayList(u8).init(allocator);
    errdefer result.deinit();

    var i: usize = 0;
    while (i < input.len) {
        var replaced = false;
        for (replacements) |r| {
            if (mem.startsWith(u8, input[i..], r.from)) {
                try result.append(r.to);
                i += 1;
                replaced = true;
                break;
            }
        }
        if (!replaced) {
            try result.append(input[i]);
            i += 1;
        }
    }
    return result.toOwnedSlice();
}

fn firstNumber(line: []const u8) !u8 {
    for (line) |char| {
        if (std.ascii.isDigit(char)) {
            return char - '0';
        }
    }
    return error.NumberNotFound;
}

fn lastNumber(line: []const u8) !u8 {
    var i: usize = line.len;
    while (i > 0) {
        i -= 1;
        if (std.ascii.isDigit(line[i])) {
            return line[i] - '0';
        }
    }
    return error.NumberNotFound;
}

fn combineNumbers(first: u8, last: u8) u8 {
    return first * 10 + last;
}
