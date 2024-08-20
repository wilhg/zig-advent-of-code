const std = @import("std");
const ArrayList = std.ArrayList;
const mem = std.mem;
const fmt = std.fmt;

const Cubes = struct {
    red: u8,
    green: u8,
    blue: u8,
};

const Game = struct {
    id: u8,
    rounds: []Cubes,
};

fn parseLine(loc: std.mem.Allocator, line: []const u8) !Game {
    var game_parts = mem.split(u8, line, ":");
    const game_id = try fmt.parseInt(u8, game_parts.next().?[5..], 10);

    var rounds = ArrayList(Cubes).init(loc);
    errdefer rounds.deinit();

    var rounds_str = mem.split(u8, game_parts.next().?, ";");
    while (rounds_str.next()) |round| {
        var cubes = Cubes{ .red = 0, .green = 0, .blue = 0 };
        var colors = mem.split(u8, round, ",");
        while (colors.next()) |color| {
            var color_parts = mem.split(u8, mem.trim(u8, color, " "), " ");
            const count = try fmt.parseInt(u8, color_parts.next().?, 10);
            const color_name = color_parts.next().?;
            if (mem.eql(u8, color_name, "red")) {
                cubes.red = count;
            } else if (mem.eql(u8, color_name, "green")) {
                cubes.green = count;
            } else if (mem.eql(u8, color_name, "blue")) {
                cubes.blue = count;
            }
        }
        try rounds.append(cubes);
    }

    return Game{ .id = game_id, .rounds = try rounds.toOwnedSlice() };
}

fn readInput(loc: std.mem.Allocator, filename: []const u8) !ArrayList(Game) {
    var games = ArrayList(Game).init(loc);
    errdefer {
        for (games.items) |game| {
            loc.free(game.rounds);
        }
        games.deinit();
    }

    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [256]u8 = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try games.append(try parseLine(loc, line));
    }

    return games;
}

fn printGames(games: ArrayList(Game)) void {
    for (games.items) |game| {
        std.debug.print("Game {}: ", .{game.id});
        for (game.rounds) |round| {
            std.debug.print("(red: {}, green: {}, blue: {}); ", .{ round.red, round.green, round.blue });
        }
        std.debug.print("\n", .{});
    }
}

fn sumValidGameId(games: ArrayList(Game)) u16 {
    var sum: u16 = 0;
    for (games.items) |game| {
        if (isGameValid(game)) {
            sum += game.id;
        }
    }
    return sum;
}

fn isGameValid(game: Game) bool {
    for (game.rounds) |round| {
        if (!isCubesValid(round)) {
            return false;
        }
    }
    return true;
}

fn isCubesValid(c: Cubes) bool {
    const totalCubes = Cubes{ .red = 12, .green = 13, .blue = 14 };
    return c.red <= totalCubes.red and c.green <= totalCubes.green and c.blue <= totalCubes.blue;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const loc = arena.allocator();

    var games = try readInput(loc, "d2_input.txt");
    defer {
        for (games.items) |game| {
            loc.free(game.rounds);
        }
        games.deinit();
    }

    // printGames(games);

    const sum = sumValidGameId(games);
    std.debug.print("{d}\n", .{sum});
}
