// https://adventofcode.com/2023/day/3

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

fn getNumber(matrix: *const Matrix, p: Point) ?Number {
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

    for (&matrix) |*row| {
        _ = try in_stream.readNoEof(row);
        _ = try in_stream.skipUntilDelimiterOrEof('\n');
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

inline fn isGear(cell: u8) bool {
    return cell == '*';
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const matrix = try loadMatrix();

    var map = AutoHashMap(u16, u16).init(allocator);
    defer map.deinit();

    var sum: u32 = 0;
    var ratio_sum: u64 = 0;

    for (0..LEN) |y| {
        for (0..LEN) |x| {
            if (isSymbol(matrix[y][x])) {
                var gear_count: u8 = 0;
                var gear_ratio: u64 = 1;
                var last_gear_number: u16 = 0;

                for (squareAround(.{ .x = x, .y = y })) |adj_point| {
                    if (adj_point.x >= LEN or adj_point.y >= LEN) continue;
                    if (getNumber(&matrix, adj_point)) |num| {
                        if (!map.contains(num.pointHash)) {
                            try map.put(num.pointHash, num.value);
                            sum += num.value;
                        }
                        if (isGear(matrix[y][x]) and last_gear_number != num.value) {
                            last_gear_number = num.value;
                            gear_count += 1;
                            gear_ratio *= num.value;
                        }
                    }
                }

                if (gear_count == 2) {
                    ratio_sum += gear_ratio;
                }
            }
        }
    }

    debug.print("Sum of all values: {}\n", .{sum});
    debug.print("Sum of ratio: {}\n", .{ratio_sum});
}
