const std = @import("std");

pub fn main() !void {
    const input = @embedFile("d13_input.txt");
    const result = try solvePuzzle(input);
    std.debug.print("Result: {}\n", .{result});
}

fn solvePuzzle(input: []const u8) !usize {
    var total: usize = 0;
    var patterns = std.mem.split(u8, input, "\n\n");

    while (patterns.next()) |pattern| {
        total += try findSmudgedReflection(pattern);
    }

    return total;
}

// Use a fixed-size buffer for the grid
const MAX_GRID_SIZE = 32;
const MAX_LINE_LENGTH = 32;

fn findSmudgedReflection(pattern: []const u8) !usize {
    var grid: [MAX_GRID_SIZE][MAX_LINE_LENGTH]u8 = undefined;
    var grid_width: usize = 0;
    var grid_height: usize = 0;

    var lines = std.mem.split(u8, pattern, "\n");
    while (lines.next()) |line| {
        if (grid_height >= MAX_GRID_SIZE) return error.GridTooLarge;
        if (line.len > MAX_LINE_LENGTH) return error.LineTooLong;

        @memcpy(grid[grid_height][0..line.len], line);
        grid_width = @max(grid_width, line.len);
        grid_height += 1;
    }

    // Check for horizontal reflection with one smudge
    for (1..grid_height) |i| {
        if (isSmudgedHorizontalReflection(grid[0..grid_height], i)) {
            return i * 100;
        }
    }

    // Check for vertical reflection with one smudge
    for (1..grid_width) |i| {
        if (isSmudgedVerticalReflection(grid[0..grid_height], grid_width, i)) {
            return i;
        }
    }

    return error.NoReflectionFound;
}

fn isSmudgedHorizontalReflection(grid: [][MAX_LINE_LENGTH]u8, row: usize) bool {
    var smudges: usize = 0;
    var top = row - 1;
    var bottom = row;
    while (top < grid.len and bottom < grid.len) {
        smudges += countDifferences(grid[top][0..], grid[bottom][0..]);
        if (smudges > 1) return false;
        if (top == 0) break;
        top -= 1;
        bottom += 1;
    }
    return smudges == 1;
}

fn isSmudgedVerticalReflection(grid: [][MAX_LINE_LENGTH]u8, width: usize, col: usize) bool {
    var smudges: usize = 0;
    var left = col - 1;
    var right = col;
    while (left < width and right < width) {
        for (grid) |row| {
            if (row[left] != row[right]) {
                smudges += 1;
                if (smudges > 1) return false;
            }
        }
        if (left == 0) break;
        left -= 1;
        right += 1;
    }
    return smudges == 1;
}

fn countDifferences(a: []const u8, b: []const u8) usize {
    var diff: usize = 0;
    for (a[0..@min(a.len, b.len)], b[0..@min(a.len, b.len)]) |char_a, char_b| {
        if (char_a != char_b) diff += 1;
    }
    return diff;
}
