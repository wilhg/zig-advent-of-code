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

    fn hash() u16 {
        return .x * .y;
    }
};

const Square = struct {
    topLeft: Point,
    bottomRight: Point,
};

const Number = struct {
    pointHash: u16, // y * 140 + x
    value: u16,
};

// get the attached number from the point,
// if the point not belongs to a number, return null
fn getNumber(matrix: Matrix, p: Point) ?Number {
    if (!isNumeric(matrix[p.y][p.x])) {
        return null;
    }

    var x0 = p.x;
    var start_x = x0;
    while (isNumeric(matrix[p.y][x0])) {
        start_x = x0;
        if (x0 > 0) {
            x0 -= 1;
        } else {
            break;
        }
    }
    debug.print("start_x = {}\n", .{start_x});
    var x1 = start_x;
    var value: u16 = 0;
    while (x1 < LEN and isNumeric(matrix[p.y][x1])) {
        value = value * 10 + (matrix[p.y][x1] - '0');
        x1 += 1;
    }

    return Number{ .pointHash = @intCast(p.y * LEN + start_x), .value = value };
}

fn squareAround(p: Point) Square {
    var left: usize = undefined;
    var right: usize = undefined;
    var top: usize = undefined;
    var bottom: usize = undefined;

    if (p.x == 0) {
        left = 0;
        right = p.x + 1;
    } else if (p.x == LEN - 1) {
        left = p.x - 1;
        right = LEN - 1;
    } else {
        left = p.x - 1;
        right = p.x + 1;
    }

    if (p.y == 0) {
        top = 0;
        bottom = p.y + 1;
    } else if (p.y == LEN - 1) {
        top = p.y - 1;
        bottom = LEN - 1;
    } else {
        top = p.y - 1;
        bottom = p.y + 1;
    }

    return Square{ .topLeft = Point{ .x = left, .y = top }, .bottomRight = Point{ .x = right, .y = bottom } };
}

fn loadMatrix() !Matrix {
    // Open the file
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

fn isDot(cell: u8) bool {
    return cell == '.';
}

fn isNumeric(cell: u8) bool {
    return !isDot(cell) and cell >= '0' and cell <= '9';
}

fn isSymbol(cell: u8) bool {
    return !isDot(cell) and !(cell >= '0' and cell <= '9');
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const loc = arena.allocator();

    const matrix = try loadMatrix();
    // Print the 2D array to verify
    // for (matrix) |row_data| {
    //     for (row_data) |cell| {
    //         try std.io.getStdOut().writer().print("{c}", .{cell});
    //     }
    //     try std.io.getStdOut().writer().print("\n", .{});
    // }

    var squares = ArrayList(Square).init(loc);
    for (0..LEN) |y| {
        for (0..LEN) |x| {
            if (isSymbol(matrix[y][x])) {
                try squares.append(squareAround(Point{ .x = x, .y = y }));
            }
        }
    }

    var map = AutoHashMap(u16, u16).init(loc);

    for (squares.items) |sq| {
        for (sq.topLeft.y..(sq.bottomRight.y + 1)) |y| {
            for (sq.topLeft.x..(sq.bottomRight.x + 1)) |x| {
                if (getNumber(matrix, Point{ .x = x, .y = y })) |num| {
                    try map.put(num.pointHash, num.value);
                } else {
                    continue;
                }
            }
        }
    }

    var sum: i32 = 0;
    var iterator = map.valueIterator();
    while (iterator.next()) |value| {
        debug.print("value = {}\n", .{value.*});
        sum += value.*;
    }
    debug.print("Sum of all values: {}\n", .{sum});
}
