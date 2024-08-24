const std = @import("std");

const Direction = enum { north, south, east, west };

fn opposite(direction: Direction) Direction {
    return switch (direction) {
        .north => .south,
        .south => .north,
        .east => .west,
        .west => .east,
    };
}

const Tile = struct {
    symbol: u8,
    directions: ?[2]Direction,

    fn isConnectedOn(self: Tile, object: Tile, direction: Direction) bool {
        const self_dirs = self.directions orelse return false;
        const obj_dirs = object.directions orelse return false;
        const opposite_dir = opposite(direction);

        return (self_dirs[0] == direction or self_dirs[1] == direction) and
            (obj_dirs[0] == opposite_dir or obj_dirs[1] == opposite_dir);
    }

    fn exitDirection(self: Tile, entry: Direction) ?Direction {
        const dirs = self.directions orelse return null;
        if (dirs[0] == entry) return dirs[1];
        return dirs[0];
    }
};

const TileNS = Tile{ .symbol = '|', .directions = .{ .north, .south } };
const TileEW = Tile{ .symbol = '-', .directions = .{ .east, .west } };
const TileNE = Tile{ .symbol = 'L', .directions = .{ .north, .east } };
const TileNW = Tile{ .symbol = 'J', .directions = .{ .north, .west } };
const TileSE = Tile{ .symbol = 'F', .directions = .{ .south, .east } };
const TileSW = Tile{ .symbol = '7', .directions = .{ .south, .west } };
const TileNone = Tile{ .symbol = '.', .directions = null };

fn parseTile(c: u8) Tile {
    return switch (c) {
        '|' => TileNS,
        '-' => TileEW,
        'L' => TileNE,
        'J' => TileNW,
        '7' => TileSW,
        'F' => TileSE,
        '.' => TileNone,
        else => TileNone,
    };
}

const Position = struct {
    y: usize,
    x: usize,

    fn eql(self: Position, other: Position) bool {
        return self.y == other.y and self.x == other.x;
    }
};

const State = struct {
    position: Position,
    forward: Direction,
};

const INIT_STATE = State{
    .position = Position{ .y = 50, .x = 95 },
    .forward = .south,
};

const LEN: usize = 140;
const Grid = struct {
    data: [LEN][LEN]Tile,

    fn getTile(self: Grid, p: Position) Tile {
        return self.data[p.y][p.x];
    }

    // If it's a circle, return the number of steps
    // If it's not a circle, return null
    fn stepsInCircle(self: Grid, start_state: State) ?usize {
        var state = start_state;
        var count: usize = 0;
        while (self.nextMove(state.position, state.forward)) |next| {
            // std.debug.print("{}: {any}\n", .{ count, next });
            if (next.position.eql(start_state.position)) {
                return count;
            }
            count += 1;
            state = next;
        } else {
            return null;
        }
    }

    fn nextMove(self: Grid, p: Position, dir: Direction) ?State {
        const tile = self.getTile(p);
        // std.debug.print("p={}, t={c}, d={any}\n", .{ p, tile.symbol, dir });
        if (tile.directions == null) {
            return null;
        }

        const np = switch (dir) {
            .north => if (p.y > 0) Position{ .y = p.y - 1, .x = p.x } else null,
            .south => if (p.y < LEN - 1) Position{ .y = p.y + 1, .x = p.x } else null,
            .east => if (p.x < LEN - 1) Position{ .y = p.y, .x = p.x + 1 } else null,
            .west => if (p.x > 0) Position{ .y = p.y, .x = p.x - 1 } else null,
        };
        if (np == null) return null;

        const next_tile = self.getTile(np.?);

        if (np != null and tile.isConnectedOn(next_tile, dir)) {
            return State{ .position = np.?, .forward = next_tile.exitDirection(opposite(dir)).? };
        } else {
            return null;
        }
    }
};

fn loadGrid() !Grid {
    const input = @embedFile("d10_input.txt");
    var rows = std.mem.split(u8, input, "\n");
    var data: [LEN][LEN]Tile = undefined;
    var y: usize = 0;
    while (rows.next()) |row| {
        for (row, 0..) |c, x| {
            data[y][x] = parseTile(c);
        }
        y += 1;
    }
    return Grid{ .data = data };
}

pub fn main() !void {
    const grid = try loadGrid();
    const steps = grid.stepsInCircle(INIT_STATE);

    std.debug.print("Steps: {d}\n", .{@ceil(@as(f32, @floatFromInt(steps.?)) / 2)});
}
