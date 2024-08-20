const std = @import("std");
const mem = std.mem;
const fs = std.fs;
const io = std.io;
const debug = std.debug;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const LEN = 140;
const Matrix = [LEN][LEN]u8;

const Point = struct {
    x: usize,
    y: usize,
};

const Number = struct {
    pointHash: u16,
    value: u16,
};

inline fn getNumber(matrix: *const Matrix, p: Point) ?Number {
    if (!isNumeric(matrix[p.y][p.x])) return null;

    var start_x = p.x;
    while (start_x > 0 and isNumeric(matrix[p.y][start_x - 1])) {
        start_x -= 1;
    }

    var value: u16 = 0;
    var x = start_x;
    while (x < LEN and isNumeric(matrix[p.y][x])) : (x += 1) {
        value = value * 10 + (matrix[p.y][x] - '0');
    }

    return Number{
        .pointHash = @intCast(p.y * LEN + start_x),
        .value = value,
    };
}

inline fn squareAround(p: Point) [8]Point {
    return .{
        .{ .x = p.x -| 1, .y = p.y -| 1 },
        .{ .x = p.x, .y = p.y -| 1 },
        .{ .x = p.x + 1, .y = p.y -| 1 },
        .{ .x = p.x -| 1, .y = p.y },
        .{ .x = p.x + 1, .y = p.y },
        .{ .x = p.x -| 1, .y = p.y + 1 },
        .{ .x = p.x, .y = p.y + 1 },
        .{ .x = p.x + 1, .y = p.y + 1 },
    };
}

fn loadMatrix() !Matrix {
    const file = try fs.cwd().openFile("d3_input.txt", .{});
    defer file.close();

    var matrix: Matrix = undefined;
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [LEN + 1]u8 = undefined;

    var row: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (row >= LEN) break;
        @memcpy(&matrix[row], line);
        row += 1;
    }

    return matrix;
}

inline fn isDot(cell: u8) bool {
    return cell == '.';
}

inline fn isNumeric(cell: u8) bool {
    return cell >= '0' and cell <= '9';
}

inline fn isSymbol(cell: u8) bool {
    return !isDot(cell) and !isNumeric(cell);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const matrix = try loadMatrix();

    var map = AutoHashMap(u16, u16).init(allocator);
    defer map.deinit();

    for (0..LEN) |y| {
        for (0..LEN) |x| {
            if (isSymbol(matrix[y][x])) {
                for (squareAround(.{ .x = x, .y = y })) |adj_point| {
                    if (adj_point.x >= LEN or adj_point.y >= LEN) continue;
                    if (getNumber(&matrix, adj_point)) |num| {
                        try map.put(num.pointHash, num.value);
                    }
                }
            }
        }
    }

    var sum: u32 = 0;
    var iterator = map.valueIterator();
    while (iterator.next()) |value| {
        sum += value.*;
    }
    debug.print("Sum of all values: {}\n", .{sum});
}
