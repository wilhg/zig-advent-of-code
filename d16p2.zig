const std = @import("std");

const SIZE: usize = 110;

var tiles: [SIZE][SIZE]u8 = undefined;
var charged: [SIZE][SIZE]bool = undefined;
var cachedBeams: [SIZE][SIZE]?Direction = undefined;

fn countChargedAndReset() usize {
    var count: usize = 0;
    for (0..SIZE) |y| {
        for (0..SIZE) |x| {
            if (charged[y][x]) {
                count += 1;
                charged[y][x] = false;
                cachedBeams[y][x] = null;
            }
        }
    }
    std.debug.print("count: {d}\n", .{count});
    return count;
}

const Direction = enum { Up, Down, Left, Right };

const Position = struct { y: usize, x: usize };

const Beam = struct {
    start: Position,
    dir: Direction,
};

fn pass(b: *const Beam, p: Position) void {
    if (cachedBeams[p.y][p.x] != null and cachedBeams[p.y][p.x] == b.dir) {
        return;
    }
    cachedBeams[p.y][p.x] = b.dir;
    charged[p.y][p.x] = true;

    switch (b.dir) {
        .Up => if (p.y == 0) return,
        .Down => if (p.y == SIZE - 1) return,
        .Left => if (p.x == 0) return,
        .Right => if (p.x == SIZE - 1) return,
    }

    // next position
    const np = switch (b.dir) {
        .Up => Position{ .y = p.y - 1, .x = p.x },
        .Down => Position{ .y = p.y + 1, .x = p.x },
        .Left => Position{ .y = p.y, .x = p.x - 1 },
        .Right => Position{ .y = p.y, .x = p.x + 1 },
    };

    // next direction
    switch (tiles[np.y][np.x]) {
        '/' => switch (b.dir) {
            .Up => pass(&Beam{ .start = np, .dir = .Right }, np),
            .Down => pass(&Beam{ .start = np, .dir = .Left }, np),
            .Left => pass(&Beam{ .start = np, .dir = .Down }, np),
            .Right => pass(&Beam{ .start = np, .dir = .Up }, np),
        },
        '\\' => switch (b.dir) {
            .Up => pass(&Beam{ .start = np, .dir = .Left }, np),
            .Down => pass(&Beam{ .start = np, .dir = .Right }, np),
            .Left => pass(&Beam{ .start = np, .dir = .Up }, np),
            .Right => pass(&Beam{ .start = np, .dir = .Down }, np),
        },
        '-' => switch (b.dir) {
            .Up, .Down => {
                pass(&Beam{ .start = np, .dir = .Left }, np);
                pass(&Beam{ .start = np, .dir = .Right }, np);
            },
            .Left, .Right => pass(b, np),
        },
        '|' => switch (b.dir) {
            .Left, .Right => {
                pass(&Beam{ .start = np, .dir = .Up }, np);
                pass(&Beam{ .start = np, .dir = .Down }, np);
            },
            .Up, .Down => pass(b, np),
        },
        '.' => pass(b, np),
        else => unreachable,
    }
}

fn launch(p: Position, dir: Direction) void {
    pass(&Beam{ .start = p, .dir = dir }, p);
}

fn initTiles() void {
    const input = @embedFile("d16_input.txt");
    var i: usize = 0;
    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| : (i += 1) {
        @memcpy(&tiles[i], line);
    }
}

pub fn main() !void {
    _ = countChargedAndReset();
    initTiles();

    var max_count: usize = 0;
    // from top
    for (0..SIZE) |x| {
        const p = Position{ .y = 0, .x = x };
        switch (tiles[0][x]) {
            '.', '|' => launch(p, .Down),
            '/' => launch(p, .Left),
            '\\' => launch(p, .Right),
            '-' => {
                launch(p, .Left);
                launch(p, .Right);
            },
            else => unreachable,
        }
        max_count = @max(max_count, countChargedAndReset());
    }

    // from bottom
    for (0..SIZE) |x| {
        const p = Position{ .y = SIZE - 1, .x = x };
        switch (tiles[SIZE - 1][x]) {
            '.', '|' => launch(p, .Up),
            '/' => launch(p, .Right),
            '\\' => launch(p, .Left),
            '-' => {
                launch(p, .Left);
                launch(p, .Right);
            },
            else => unreachable,
        }
        max_count = @max(max_count, countChargedAndReset());
    }

    // from left
    for (0..SIZE) |y| {
        const p = Position{ .y = y, .x = 0 };
        switch (tiles[y][0]) {
            '.', '-' => launch(p, .Right),
            '/' => launch(p, .Up),
            '\\' => launch(p, .Down),
            '|' => {
                launch(p, .Up);
                launch(p, .Down);
            },
            else => unreachable,
        }
        max_count = @max(max_count, countChargedAndReset());
    }

    // from right
    for (0..SIZE) |y| {
        const p = Position{ .y = y, .x = SIZE - 1 };
        switch (tiles[y][SIZE - 1]) {
            '.', '-' => launch(p, .Left),
            '/' => launch(p, .Down),
            '\\' => launch(p, .Up),
            '|' => {
                launch(p, .Up);
                launch(p, .Down);
            },
            else => unreachable,
        }
        max_count = @max(max_count, countChargedAndReset());
    }

    std.debug.print("max count: {}\n", .{max_count});
}
