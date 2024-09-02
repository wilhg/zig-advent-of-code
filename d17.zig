const std = @import("std");

const SIZE: usize = 141;

var weights: [SIZE][SIZE]u16 = undefined;
var scores: [SIZE][SIZE]u64 = undefined;
var done: [SIZE][SIZE]bool = undefined;

const Position = struct {
    y: usize,
    x: usize,
};
const Direction = enum { up, down, left, right };

const QueueItem = struct {
    p: Position,
    last_dir: Direction,
    straight_count: u2,
};

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
            scores[y][x] = 0xFFFFFFFFFFFFFFFF;
            done[y][x] = false;
        }
    }

    scores[0][0] = weights[0][0];
}

fn bfs() void {
    var queue = std.ArrayList(QueueItem).init(std.heap.page_allocator);
    defer queue.deinit();

    queue.append(QueueItem{ .p = Position{ .y = 0, .x = 0 }, .last_dir = .down, .straight_count = 0 }) catch unreachable;

    while (queue.items.len > 0) {
        const item = queue.orderedRemove(0);
        const p = item.p;
        const last_dir = item.last_dir;
        const straight_count = item.straight_count;

        if (done[p.y][p.x]) continue;

        // up
        var sc_up: ?u2 = null;
        std.debug.print("up\n", .{});
        if (p.y > 0 and last_dir != .down and (last_dir != .up or (last_dir == .up and straight_count < 3))) {
            const np = Position{ .y = p.y - 1, .x = p.x };
            if (!done[np.y][np.x]) {
                scores[np.y][np.x] = @min(scores[np.y][np.x], scores[p.y][p.x] + weights[np.y][np.x]);
                sc_up = if (last_dir != .up) 0 else straight_count + 1;
            }
        }

        // down
        var sc_down: ?u2 = null;
        std.debug.print("down\n", .{});
        if (p.y < SIZE - 1 and last_dir != .up and (last_dir != .down or (last_dir == .down and straight_count < 3))) {
            const np = Position{ .y = p.y + 1, .x = p.x };
            if (!done[np.y][np.x]) {
                scores[np.y][np.x] = @min(scores[np.y][np.x], scores[p.y][p.x] + weights[np.y][np.x]);
                sc_down = if (last_dir != .down) 0 else straight_count + 1;
            }
        }

        // left
        var sc_left: ?u2 = null;
        std.debug.print("left\n", .{});
        if (p.x > 0 and last_dir != .right and (last_dir != .left or (last_dir == .left and straight_count < 3))) {
            const np = Position{ .y = p.y, .x = p.x - 1 };
            if (!done[np.y][np.x]) {
                scores[np.y][np.x] = @min(scores[np.y][np.x], scores[p.y][p.x] + weights[np.y][np.x]);
                sc_left = if (last_dir != .left) 0 else straight_count + 1;
            }
        }

        // right
        var sc_right: ?u2 = null;
        std.debug.print("right\n", .{});
        if (p.x < SIZE - 1 and last_dir != .left and (last_dir != .right or (last_dir == .right and straight_count < 3))) {
            const np = Position{ .y = p.y, .x = p.x + 1 };
            if (!done[np.y][np.x]) {
                scores[np.y][np.x] = @min(scores[np.y][np.x], scores[p.y][p.x] + weights[np.y][np.x]);
                sc_right = if (last_dir != .right) 0 else straight_count + 1;
            }
        }

        std.debug.print("done\n", .{});

        done[p.y][p.x] = true;

        if (sc_up) |n| queue.append(QueueItem{ .p = Position{ .y = p.y - 1, .x = p.x }, .last_dir = .up, .straight_count = n }) catch unreachable;
        if (sc_down) |n| queue.append(QueueItem{ .p = Position{ .y = p.y + 1, .x = p.x }, .last_dir = .down, .straight_count = n }) catch unreachable;
        if (sc_left) |n| queue.append(QueueItem{ .p = Position{ .y = p.y, .x = p.x - 1 }, .last_dir = .left, .straight_count = n }) catch unreachable;
        if (sc_right) |n| queue.append(QueueItem{ .p = Position{ .y = p.y, .x = p.x + 1 }, .last_dir = .right, .straight_count = n }) catch unreachable;
    }
}

pub fn main() !void {
    initData();

    bfs();

    std.debug.print("{d}\n", .{scores[SIZE - 1][SIZE - 1]});

    // for (scores) |row| {
    //     for (row) |tile| {
    //         std.debug.print("{x}", .{tile & 0xF});
    //     }
    //     std.debug.print("\n", .{});
    // }

}
