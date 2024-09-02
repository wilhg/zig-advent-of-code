const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const Direction = enum { Up, Down, Left, Right };
const Position = struct { x: i32, y: i32 };
const State = struct {
    pos: Position,
    dir: Direction,
    straight: u16, // Changed from u8 to u16
    heat_loss: u32,
};

fn solvePuzzle(allocator: std.mem.Allocator, grid: []const []const u8) !u32 {
    const rows: i32 = @intCast(grid.len);
    const cols: i32 = @intCast(grid[0].len);

    var queue = ArrayList(State).init(allocator);
    defer queue.deinit();

    var visited = AutoHashMap(struct { Position, Direction, u16 }, void).init(allocator); // Changed u8 to u16
    defer visited.deinit();

    try queue.append(.{ .pos = .{ .x = 0, .y = 0 }, .dir = .Right, .straight = 0, .heat_loss = 0 });
    try queue.append(.{ .pos = .{ .x = 0, .y = 0 }, .dir = .Down, .straight = 0, .heat_loss = 0 });

    while (queue.items.len > 0) {
        const current = queue.orderedRemove(0);

        if (current.pos.x == cols - 1 and current.pos.y == rows - 1 and current.straight >= 4) {
            return current.heat_loss;
        }

        const key = .{ current.pos, current.dir, current.straight };
        if (visited.contains(key)) continue;
        try visited.put(key, {});

        const directions = [_]Direction{ .Up, .Down, .Left, .Right };
        for (directions) |new_dir| {
            if (oppositeDirection(current.dir) == new_dir) continue;
            if (current.dir == new_dir and current.straight == 10) continue; // Changed from 3 to 10
            if (current.dir != new_dir and current.straight < 4) continue; // Add this line

            const new_pos = nextPosition(current.pos, new_dir);
            if (new_pos.x < 0 or new_pos.y < 0 or new_pos.x >= cols or new_pos.y >= rows) continue; // This line is crucial

            const new_straight = if (current.dir == new_dir) current.straight + 1 else 1;
            const new_heat_loss = current.heat_loss + (grid[@intCast(new_pos.y)][@intCast(new_pos.x)] - '0');

            try queue.append(.{
                .pos = new_pos,
                .dir = new_dir,
                .straight = new_straight,
                .heat_loss = new_heat_loss,
            });
        }

        std.mem.sort(State, queue.items, {}, compareFn);
    }

    return error.NoSolutionFound;
}

fn oppositeDirection(dir: Direction) Direction {
    return switch (dir) {
        .Up => .Down,
        .Down => .Up,
        .Left => .Right,
        .Right => .Left,
    };
}

fn nextPosition(pos: Position, dir: Direction) Position {
    return switch (dir) {
        .Up => .{ .x = pos.x, .y = pos.y - 1 },
        .Down => .{ .x = pos.x, .y = pos.y + 1 },
        .Left => .{ .x = pos.x - 1, .y = pos.y },
        .Right => .{ .x = pos.x + 1, .y = pos.y },
    };
}

fn compareFn(context: void, a: State, b: State) bool {
    _ = context;
    return a.heat_loss < b.heat_loss;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input_file = @embedFile("d17_input.txt");
    var lines = std.mem.tokenize(u8, input_file, "\n");
    var input = std.ArrayList([]const u8).init(allocator);
    defer input.deinit();

    while (lines.next()) |line| {
        try input.append(line);
    }

    const result = try solvePuzzle(allocator, input.items);
    print("Least heat loss: {}\n", .{result});
}
