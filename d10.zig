const std = @import("std");

const Direction = enum(u2) { north, south, east, west };

const Color = enum(u2) {
    border,
    inside,
    none,
};

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
    color: Color,

    fn isConnectedOn(self: Tile, object: Tile, direction: Direction) bool {
        const self_dirs = self.directions orelse return false;
        const obj_dirs = object.directions orelse return false;
        const opposite_dir = opposite(direction);

        return (self_dirs[0] == direction or self_dirs[1] == direction) and
            (obj_dirs[0] == opposite_dir or obj_dirs[1] == opposite_dir);
    }

    fn exitDirection(self: Tile, entry: Direction) ?Direction {
        const dirs = self.directions orelse return null;
        return if (dirs[0] == entry) dirs[1] else dirs[0];
    }
};

const TileNS = Tile{ .symbol = '|', .directions = .{ .north, .south }, .color = .none };
const TileEW = Tile{ .symbol = '-', .directions = .{ .east, .west }, .color = .none };
const TileNE = Tile{ .symbol = 'L', .directions = .{ .north, .east }, .color = .none };
const TileNW = Tile{ .symbol = 'J', .directions = .{ .north, .west }, .color = .none };
const TileSE = Tile{ .symbol = 'F', .directions = .{ .south, .east }, .color = .none };
const TileSW = Tile{ .symbol = '7', .directions = .{ .south, .west }, .color = .none };
const TileNone = Tile{ .symbol = '.', .directions = null, .color = .none };

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

// because the grid is large, it's hard to tell which is inside and which is outside
// the solution will be color the two sides at the same time
// if one color touches the border, it's outside
const INIT_STATE = State{
    .position = Position{ .y = 49, .x = 96 },
    .forward = .west,
};

const LEN: usize = 140;

const Grid = struct {
    data: [LEN][LEN]Tile,

    fn getTile(self: *Grid, p: Position) *Tile {
        return &self.data[p.y][p.x];
    }

    fn nextState(self: *Grid, state: State) ?State {
        const p = state.position;
        const tile = self.getTile(p);
        if (tile.directions == null) return null;

        const np = switch (state.forward) {
            .north => if (p.y > 0) Position{ .y = p.y - 1, .x = p.x } else return null,
            .south => if (p.y < LEN - 1) Position{ .y = p.y + 1, .x = p.x } else return null,
            .east => if (p.x < LEN - 1) Position{ .y = p.y, .x = p.x + 1 } else return null,
            .west => if (p.x > 0) Position{ .y = p.y, .x = p.x - 1 } else return null,
        };

        const next_tile = self.getTile(np);

        if (!tile.isConnectedOn(next_tile.*, state.forward)) return null;

        const next_dir = next_tile.exitDirection(opposite(state.forward)) orelse return null;
        return State{ .position = np, .forward = next_dir };
    }

    fn stepsInCircle(self: *Grid, start_state: State) ?usize {
        var cs = start_state; // cs = current state
        var count: usize = 0;
        while (self.nextState(cs)) |ns| { // ns = next state
            if (ns.position.eql(start_state.position)) return count;
            count += 1;
            cs = ns;
        }
        return null;
    }

    fn stroke(self: *Grid, start_state: State) void {
        var cs = start_state; // cs = current state
        self.getTile(cs.position).color = .border;
        while (self.nextState(cs)) |ns| { // ns = next state
            if (ns.position.eql(start_state.position)) return;
            self.getTile(cs.position).color = .border;
            cs = ns;
        }
        return;
    }

    fn inkjetNorth(self: *Grid, p: Position) void {
        var y: usize = p.y -| 1;
        while (y > 0) : (y -= 1) {
            var tile = self.getTile(.{ .y = y, .x = p.x });
            if (tile.color == .border) break;
            tile.color = .inside;
        }
    }

    fn inkjetSouth(self: *Grid, p: Position) void {
        var y = p.y +| 1;
        while (y < LEN - 1) : (y += 1) {
            var tile = self.getTile(.{ .y = y, .x = p.x });
            if (tile.color == .border) break;
            tile.color = .inside;
        }
    }

    fn inkjetWest(self: *Grid, p: Position) void {
        var x = p.x -| 1;
        while (x > 0) : (x -= 1) {
            var tile = self.getTile(.{ .y = p.y, .x = x });
            if (tile.color == .border) break;
            tile.color = .inside;
        }
    }

    fn inkjetEast(self: *Grid, p: Position) void {
        var x = p.x +| 1;
        while (x < LEN - 1) : (x += 1) {
            var tile = self.getTile(.{ .y = p.y, .x = x });
            if (tile.color == .border) break;
            tile.color = .inside;
        }
    }

    // inkjet to all the right side tiles until we hit the border
    fn inkjetCircle(self: *Grid, start_state: State) void {
        var cs = start_state; // cs = current state
        while (self.nextState(cs)) |ns| { // ns = next state
            if (ns.position.eql(start_state.position)) return;

            // Inkjet to the right side
            switch (cs.forward) {
                .north => self.inkjetEast(cs.position),
                .east => self.inkjetSouth(cs.position),
                .south => self.inkjetWest(cs.position),
                .west => self.inkjetNorth(cs.position),
            }

            // Inkjet to the right side after moving before turning
            switch (cs.forward) {
                .north => self.inkjetEast(ns.position),
                .east => self.inkjetSouth(ns.position),
                .south => self.inkjetWest(ns.position),
                .west => self.inkjetNorth(ns.position),
            }

            cs = ns;
        }
    }

    fn findAllInside(self: *Grid) usize {
        var count: usize = 0;
        for (self.data) |row| {
            for (row) |tile| {
                if (tile.color == .inside) count += 1;
            }
        }
        return count;
    }

    fn printColor(self: *const Grid) void {
        for (self.data) |row| {
            for (row) |tile| {
                const c: u8 = switch (tile.color) {
                    .border => 'B',
                    .inside => 'I',
                    .none => '.',
                };
                std.debug.print("{c}", .{c});
            }
            std.debug.print("\n", .{});
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
    var grid = try loadGrid();

    const steps = grid.stepsInCircle(INIT_STATE);

    grid.stroke(INIT_STATE); // 描边
    grid.inkjetCircle(INIT_STATE); // 喷墨
    const inside_dots = grid.findAllInside(); // 计数

    grid.printColor();

    std.debug.print("Farthest Steps: {d}\n", .{@ceil(@as(f32, @floatFromInt(steps.?)) / 2)});
    std.debug.print("Inside dots: {d}\n", .{inside_dots});
}
