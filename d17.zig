const std = @import("std");

const SIZE: usize = 141;

var weights: [SIZE][SIZE]u16 = undefined;
var scores: [SIZE][SIZE]u16 = undefined;

const Position = struct {
    y: usize,
    x: usize,
};
const Direction = enum { up, down, left, right };

fn initData() void {
    const input = @embedFile("d17_input.txt");
    var i: usize = 0;
    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| : (i += 1) {
        for (line, 0..) |c, j| {
            weights[i][j] = @intCast(c - '0');
        }
    }

    for (0..SIZE) |y| {
        for (0..SIZE) |x| {
            scores[y][x] = 0xFF; // Set to maximum value for u16
        }
    }
}

fn go(p: Position, last_dir: Direction, straight_count: u2) void {
    // up
    if (p.y > 0 and last_dir != .down and (last_dir != .up or (last_dir == .up and straight_count < 3))) {
        const np = Position{ .y = p.y - 1, .x = p.x };
        scores[np.y][np.x] = @min(scores[np.y][np.x], scores[p.y][p.x] + weights[np.y][np.x]);
        go(np, .up, if (last_dir != .up) 0 else straight_count + 1);
    }

    // down
    if (p.y < SIZE - 1 and last_dir != .up and (last_dir != .down or (last_dir == .down and straight_count < 3))) {
        const np = Position{ .y = p.y + 1, .x = p.x };
        scores[np.y][np.x] = @min(scores[np.y][np.x], scores[p.y][p.x] + weights[np.y][np.x]);
        go(np, .down, if (last_dir != .down) 0 else straight_count + 1);
    }

    // left
    if (p.x > 0 and last_dir != .right and (last_dir != .left or (last_dir == .left and straight_count < 3))) {
        const np = Position{ .y = p.y, .x = p.x - 1 };
        scores[np.y][np.x] = @min(scores[np.y][np.x], scores[p.y][p.x] + weights[np.y][np.x]);
        go(np, .left, if (last_dir != .left) 0 else straight_count + 1);
    }

    // right
    if (p.x < SIZE - 1 and last_dir != .left and (last_dir != .right or (last_dir == .right and straight_count < 3))) {
        const np = Position{ .y = p.y, .x = p.x + 1 };
        scores[np.y][np.x] = @min(scores[np.y][np.x], scores[p.y][p.x] + weights[np.y][np.x]);
        go(np, .right, if (last_dir != .right) 0 else straight_count + 1);
    }
}

pub fn main() !void {
    initData();

    go(Position{ .y = 0, .x = 0 }, .down, 0);

    for (scores) |row| {
        for (row) |tile| {
            std.debug.print("{d}\t", .{tile});
        }
        std.debug.print("\n", .{});
    }
}
