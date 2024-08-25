const std = @import("std");

const ORIGIN_LEN = 140;
const OriginGrid = [ORIGIN_LEN][ORIGIN_LEN]u1;

fn parseGrid(input: []const u8) !OriginGrid {
    var grid: OriginGrid = std.mem.zeroes(OriginGrid);
    var row: usize = 0;
    var col: usize = 0;

    for (input) |char| {
        if (row >= ORIGIN_LEN) return error.TooManyRows;

        switch (char) {
            '.' => {
                if (col >= ORIGIN_LEN) return error.RowTooLong;
                grid[row][col] = 0;
                col += 1;
            },
            '#' => {
                if (col >= ORIGIN_LEN) return error.RowTooLong;
                grid[row][col] = 1;
                col += 1;
            },
            '\n' => {
                row += 1;
                col = 0;
            },
            else => return error.InvalidCharacter,
        }
    }

    if (row < ORIGIN_LEN - 1) return error.NotEnoughRows;
    return grid;
}

fn printGrid(grid: OriginGrid) void {
    for (grid) |row| {
        for (row) |cell| {
            const char: u8 = if (cell == 0) '.' else '#';
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }
}

fn expandGrid(allocator: std.mem.Allocator, origin: OriginGrid) ![][]u1 {
    var empty_rows = [_]bool{false} ** ORIGIN_LEN;
    var empty_cols = [_]bool{true} ** ORIGIN_LEN;
    var new_rows: usize = ORIGIN_LEN;
    var new_cols: usize = ORIGIN_LEN;

    // Find empty rows and columns in a single pass
    for (origin, 0..) |row, i| {
        var row_empty = true;
        for (row, 0..) |cell, j| {
            if (cell == 1) {
                row_empty = false;
                empty_cols[j] = false;
            }
        }
        if (row_empty) {
            empty_rows[i] = true;
            new_rows += 1;
        }
    }

    // Count new columns
    for (empty_cols) |is_empty| {
        if (is_empty) new_cols += 1;
    }

    // Allocate expanded grid
    var expanded = try allocator.alloc([]u1, new_rows);
    errdefer allocator.free(expanded);

    for (expanded) |*row| {
        row.* = try allocator.alloc(u1, new_cols);
    }
    errdefer {
        for (expanded) |row| {
            allocator.free(row);
        }
    }

    // Fill expanded grid
    var exp_row: usize = 0;
    for (origin, 0..) |row, i| {
        var exp_col: usize = 0;
        for (row, 0..) |cell, j| {
            expanded[exp_row][exp_col] = cell;
            exp_col += 1;
            if (empty_cols[j]) {
                expanded[exp_row][exp_col] = 0;
                exp_col += 1;
            }
        }
        exp_row += 1;
        if (empty_rows[i]) {
            @memset(expanded[exp_row], 0);
            exp_row += 1;
        }
    }

    return expanded;
}

const Position = struct { y: usize, x: usize };

fn distance(a: Position, b: Position) usize {
    const dy = if (a.y > b.y) a.y - b.y else b.y - a.y;
    const dx = if (a.x > b.x) a.x - b.x else b.x - a.x;
    return dy + dx;
}

fn allStars(allocator: std.mem.Allocator, grid: [][]u1) ![]Position {
    var stars = std.ArrayList(Position).init(allocator);
    errdefer stars.deinit();

    for (grid, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell == 1) {
                try stars.append(.{ .y = y, .x = x });
            }
        }
    }

    return try stars.toOwnedSlice();
}

fn sumStarDistances(stars: []Position) usize {
    var sum: usize = 0;
    for (0..stars.len) |i| {
        for (i..stars.len) |j| {
            sum += distance(stars[i], stars[j]);
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

    const grid = parseGrid(input) catch |err| {
        std.debug.print("Error parsing grid: {}\n", .{err});
        return err;
    };
    printGrid(grid);

    std.debug.print("\nExpanded grid:\n", .{});
    const expanded_grid = try expandGrid(allocator, grid);
    defer {
        for (expanded_grid) |row| {
            allocator.free(row);
        }
        allocator.free(expanded_grid);
    }
    for (expanded_grid) |row| {
        for (row) |cell| {
            const char: u8 = if (cell == 0) '.' else '#';
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }

    const stars = try allStars(allocator, expanded_grid);
    defer allocator.free(stars);

    const sum = sumStarDistances(stars);
    std.debug.print("Sum of star distances: {}\n", .{sum});
}
