const std = @import("std");

const GRID_SIZE = 100;
const Direction = enum { North, West, South, East };

pub fn main() !void {
    const input = @embedFile("d14_input.txt");
    const result = try calculateTotalLoadAfterCycles(input, 1_000_000_000);
    std.debug.print("{}\n", .{result});
}

fn calculateTotalLoadAfterCycles(input: []const u8, cycles: usize) !usize {
    var grid: [GRID_SIZE][GRID_SIZE]u8 = undefined;

    var row: usize = 0;
    var col: usize = 0;
    for (input) |char| {
        if (char == '\n') {
            row += 1;
            col = 0;
        } else {
            grid[row][col] = char;
            col += 1;
        }
    }

    var seen = std.AutoHashMap([GRID_SIZE][GRID_SIZE]u8, usize).init(std.heap.page_allocator);
    defer seen.deinit();

    var cycle: usize = 0;
    while (cycle < cycles) : (cycle += 1) {
        performCycle(&grid);

        if (seen.get(grid)) |seenCycle| {
            const cycleLength = cycle - seenCycle;
            const remainingCycles = (cycles - cycle - 1) % cycleLength;
            cycle = cycles - remainingCycles - 1;
        } else {
            try seen.put(grid, cycle);
        }
    }

    return calculateLoad(&grid);
}

fn performCycle(grid: *[GRID_SIZE][GRID_SIZE]u8) void {
    tilt(grid, .North);
    tilt(grid, .West);
    tilt(grid, .South);
    tilt(grid, .East);
}

fn tilt(grid: *[GRID_SIZE][GRID_SIZE]u8, direction: Direction) void {
    switch (direction) {
        .North => {
            for (0..GRID_SIZE) |col| {
                var emptyRow: usize = 0;
                for (0..GRID_SIZE) |row| {
                    switch (grid[row][col]) {
                        'O' => {
                            if (row != emptyRow) {
                                grid[emptyRow][col] = 'O';
                                grid[row][col] = '.';
                            }
                            emptyRow += 1;
                        },
                        '#' => {
                            emptyRow = row + 1;
                        },
                        else => {},
                    }
                }
            }
        },
        .West => {
            for (0..GRID_SIZE) |row| {
                var emptyCol: usize = 0;
                for (0..GRID_SIZE) |col| {
                    switch (grid[row][col]) {
                        'O' => {
                            if (col != emptyCol) {
                                grid[row][emptyCol] = 'O';
                                grid[row][col] = '.';
                            }
                            emptyCol += 1;
                        },
                        '#' => {
                            emptyCol = col + 1;
                        },
                        else => {},
                    }
                }
            }
        },
        .South => {
            for (0..GRID_SIZE) |col| {
                var emptyRow: usize = GRID_SIZE - 1;
                var row: usize = GRID_SIZE;
                while (row > 0) {
                    row -= 1;
                    switch (grid[row][col]) {
                        'O' => {
                            if (row != emptyRow) {
                                grid[emptyRow][col] = 'O';
                                grid[row][col] = '.';
                            }
                            if (emptyRow > 0) emptyRow -= 1;
                        },
                        '#' => {
                            emptyRow = if (row > 0) row - 1 else 0;
                        },
                        else => {},
                    }
                }
            }
        },
        .East => {
            for (0..GRID_SIZE) |row| {
                var emptyCol: usize = GRID_SIZE - 1;
                var col: usize = GRID_SIZE;
                while (col > 0) {
                    col -= 1;
                    switch (grid[row][col]) {
                        'O' => {
                            if (col != emptyCol) {
                                grid[row][emptyCol] = 'O';
                                grid[row][col] = '.';
                            }
                            if (emptyCol > 0) emptyCol -= 1;
                        },
                        '#' => {
                            emptyCol = if (col > 0) col - 1 else 0;
                        },
                        else => {},
                    }
                }
            }
        },
    }
}

fn calculateLoad(grid: *const [GRID_SIZE][GRID_SIZE]u8) usize {
    var totalLoad: usize = 0;

    for (grid, 0..) |row, i| {
        for (row) |cell| {
            if (cell == 'O') {
                totalLoad += GRID_SIZE - i;
            }
        }
    }

    return totalLoad;
}
