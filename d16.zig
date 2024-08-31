const std = @import("std");

const SIZE = 110;

const Tile = struct {
    position: Position,
    mirror: u8,
    charged: bool,
};

const Grid = struct {
    tiles: [SIZE][SIZE]Tile,
};

const Direction = enum { Up, Down, Left, Right };

const Position = struct { y: usize, x: usize };

const PassResult = struct {
    one: *Beam,
    two: ?*Beam,
};

fn one(beam: *Beam) PassResult {
    return PassResult{ .one = beam, .two = null };
}

fn two(a: *Beam, b: *Beam) PassResult {
    return PassResult{ .one = a, .two = b };
}

const Beam = struct {
    start: Position,
    direction: Direction,

    fn birth(self: *Beam, dir: Direction) *Beam {
        return &Beam{
            .start = self.start,
            .direction = dir,
        };
    }

    fn pass(self: *Beam, tile: *Tile) PassResult {
        tile.charged = true;

        return switch (tile.mirror) {
            '.' => one(self),

            '/' => one(self.birth(switch (self.direction) {
                .Up => .Right,
                .Down => .Left,
                .Left => .Up,
                .Right => .Down,
            })),

            '\\' => one(self.birth(switch (self.direction) {
                .Up => .Left,
                .Down => .Right,
                .Left => .Down,
                .Right => .Up,
            })),

            '-' => {
                if (self.direction == .Left or self.direction == .Right) {
                    return one(self);
                } else {
                    return two(self.birth(.Up), self.birth(.Down));
                }
            },

            '|' => {
                if (self.direction == .Up or self.direction == .Down) {
                    return one(self);
                } else {
                    return two(self.birth(.Left), self.birth(.Right));
                }
            },

            else => unreachable,
        };
    }
};

pub fn main() !void {
    const input = @embedFile("d16_input.txt");
    var grid: Grid = undefined;

    var y: usize = 0;
    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| : (y += 1) {
        for (line, 0..) |char, x| {
            grid.tiles[y][x] = Tile{ .mirror = char, .charged = false };
        }
    }

    // Print the parsed input
    for (0..SIZE) |row| {
        for (0..SIZE) |col| {
            std.debug.print("{c}", .{grid.tiles[row][col].mirror});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}
