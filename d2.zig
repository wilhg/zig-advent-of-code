// https://adventofcode.com/2023/day/2

const std = @import("std");
const ArrayList = std.ArrayList;
const mem = std.mem;
const fmt = std.fmt;

const Cubes = struct {
    red: u8 = 0,
    green: u8 = 0,
    blue: u8 = 0,
};

const Game = struct {
    id: u8,
    rounds: []Cubes,
};

fn parseLine(allocator: mem.Allocator, line: []const u8) !Game {
    var game_parts = mem.splitScalar(u8, line, ':');
    const game_id = try fmt.parseInt(u8, game_parts.next().?[5..], 10);

    var rounds = ArrayList(Cubes).init(allocator);
    errdefer rounds.deinit();

    var rounds_str = mem.splitScalar(u8, game_parts.next().?, ';');
    while (rounds_str.next()) |round| {
        var cubes = Cubes{};
        var colors = mem.splitScalar(u8, round, ',');
        while (colors.next()) |color| {
            var color_parts = mem.splitScalar(u8, mem.trim(u8, color, " "), ' ');
            const count = try fmt.parseInt(u8, color_parts.next().?, 10);
            const color_name = color_parts.next().?;
            switch (color_name[0]) {
                'r' => cubes.red = count,
                'g' => cubes.green = count,
                'b' => cubes.blue = count,
                else => unreachable,
            }
        }
        try rounds.append(cubes);
    }

    return Game{ .id = game_id, .rounds = try rounds.toOwnedSlice() };
}

fn readInput(allocator: mem.Allocator, filename: []const u8) !ArrayList(Game) {
    var games = ArrayList(Game).init(allocator);
    errdefer {
        for (games.items) |game| {
            allocator.free(game.rounds);
        }
        games.deinit();
    }

    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [256]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try games.append(try parseLine(allocator, line));
    }

    return games;
}

fn sumValidGameId(games: []const Game) u32 {
    const totalCubes = Cubes{ .red = 12, .green = 13, .blue = 14 };
    var sum: u32 = 0;

    for (games) |game| {
        var valid = true;
        for (game.rounds) |round| {
            if (round.red > totalCubes.red or round.green > totalCubes.green or round.blue > totalCubes.blue) {
                valid = false;
                break;
            }
        }
        if (valid) sum += game.id;
    }
    return sum;
}

fn powerOfGames(games: []const Game) u32 {
    var sum_of_power: u32 = 0;
    for (games) |game| {
        var max = Cubes{};
        for (game.rounds) |cubes| {
            max.red = @max(max.red, cubes.red);
            max.green = @max(max.green, cubes.green);
            max.blue = @max(max.blue, cubes.blue);
        }
        sum_of_power += @as(u32, max.red) * @as(u32, max.green) * @as(u32, max.blue);
    }
    return sum_of_power;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var games = try readInput(allocator, "d2_input.txt");
    defer {
        for (games.items) |game| {
            allocator.free(game.rounds);
        }
        games.deinit();
    }

    const sum = sumValidGameId(games.items);
    const power_sum = powerOfGames(games.items);

    try std.io.getStdOut().writer().print("Sum of valid game IDs: {d}\nSum of game powers: {d}\n", .{ sum, power_sum });
}
