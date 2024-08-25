const std = @import("std");

const C_RATIO: u32 = 1000000;
const Pixel = struct { isGalaxy: bool, cRatio: u32 };

const LEN = 140;
const Grid = [LEN][LEN]Pixel;

fn loadGrid(input: []const u8) !Grid {
    var grid: Grid = std.mem.zeroes(Grid);
    var row: usize = 0;
    var col: usize = 0;

    for (input) |char| {
        if (row >= LEN) return error.TooManyRows;

        switch (char) {
            '.' => {
                if (col >= LEN) return error.RowTooLong;
                grid[row][col] = Pixel{ .isGalaxy = false, .cRatio = 1 };
                col += 1;
            },
            '#' => {
                if (col >= LEN) return error.RowTooLong;
                grid[row][col] = Pixel{ .isGalaxy = true, .cRatio = 1 };
                col += 1;
            },
            '\n' => {
                row += 1;
                col = 0;
            },
            else => return error.InvalidCharacter,
        }
    }

    if (row < LEN - 1) return error.NotEnoughRows;
    return grid;
}

fn loadGridRatio(grid: *Grid) void {
    var empty_rows = [_]bool{false} ** LEN;
    var empty_cols = [_]bool{true} ** LEN;

    // Find empty rows and columns in a single pass
    for (grid, 0..) |row, i| {
        var row_empty = true;
        for (row, 0..) |cell, j| {
            if (cell.isGalaxy) {
                row_empty = false;
                empty_cols[j] = false;
            }
        }
        if (row_empty) {
            empty_rows[i] = true;
        }
    }

    // Set ratio to C_RATIO for empty rows
    for (empty_rows, 0..) |is_empty, i| {
        if (is_empty) {
            for (&grid[i]) |*cell| {
                cell.cRatio = C_RATIO;
            }
        }
    }

    // Set ratio to C_RATIO for empty columns
    for (empty_cols, 0..) |is_empty, j| {
        if (is_empty) {
            for (grid) |*row| {
                row[j].cRatio = C_RATIO;
            }
        }
    }
}

fn printGrid(grid: *const Grid) void {
    for (grid) |row| {
        for (row) |cell| {
            const char: u8 = if (cell.isGalaxy) '#' else '.';
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }
}

fn printGridRatio(grid: *const Grid) void {
    for (grid) |row| {
        for (row) |cell| {
            const char: u8 = if (cell.cRatio >= C_RATIO) 'M' else '1';
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }
}

const Position = struct { y: usize, x: usize };

fn distance(grid: *const Grid, a: Position, b: Position) usize {
    return distanceX(grid, a, b) + distanceY(grid, a, b);
}

fn distanceY(grid: *const Grid, a: Position, b: Position) usize {
    const y2 = if (a.y > b.y) a.y else b.y;
    const y1 = if (a.y > b.y) b.y else a.y;

    var sum: u32 = 0;
    for (grid[y1 + 1 .. y2 + 1]) |row| {
        sum += row[a.x].cRatio;
    }
    return sum;
}

fn distanceX(grid: *const Grid, a: Position, b: Position) usize {
    const x2 = if (a.x > b.x) a.x else b.x;
    const x1 = if (a.x > b.x) b.x else a.x;

    var sum: u32 = 0;
    for (grid[a.y][x1 + 1 .. x2 + 1]) |cell| {
        sum += cell.cRatio;
    }

    return sum;
}

fn allStars(allocator: std.mem.Allocator, grid: *const Grid) ![]Position {
    var stars = std.ArrayList(Position).init(allocator);
    errdefer stars.deinit();

    for (grid, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell.isGalaxy) {
                try stars.append(.{ .y = y, .x = x });
            }
        }
    }

    return try stars.toOwnedSlice();
}

fn sumStarDistances(grid: *const Grid, stars: []Position) u64 {
    var sum: u64 = 0;
    for (0..stars.len) |i| {
        for (i..stars.len) |j| {
            sum += distance(grid, stars[i], stars[j]);
        }
    }
    return sum;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    const allocator = arena.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "d11_input.txt", 141 * 141);
    defer allocator.free(input);

    var grid = loadGrid(input) catch |err| {
        std.debug.print("Error parsing grid: {}\n", .{err});
        return err;
    };
    loadGridRatio(&grid);

    // printGrid(&grid);
    printGridRatio(&grid);

    const stars = try allStars(allocator, &grid);
    defer allocator.free(stars);

    const sum = sumStarDistances(&grid, stars);
    std.debug.print("Sum of star distances: {}\n", .{sum});
}
