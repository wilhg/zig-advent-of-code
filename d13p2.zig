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

fn findSmudgedReflection(pattern: []const u8) !usize {
    var lines = std.mem.split(u8, pattern, "\n");
    var grid = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer grid.deinit();

    while (lines.next()) |line| {
        try grid.append(line);
    }

    // Check for horizontal reflection with one smudge
    for (1..grid.items.len) |i| {
        if (isSmudgedHorizontalReflection(grid.items, i)) {
            return i * 100;
        }
    }

    // Check for vertical reflection with one smudge
    for (1..grid.items[0].len) |i| {
        if (isSmudgedVerticalReflection(grid.items, i)) {
            return i;
        }
    }

    return error.NoReflectionFound;
}

fn isSmudgedHorizontalReflection(grid: []const []const u8, row: usize) bool {
    var smudges: usize = 0;
    var top = row - 1;
    var bottom = row;
    while (top < grid.len and bottom < grid.len) {
        smudges += countDifferences(grid[top], grid[bottom]);
        if (smudges > 1) return false;
        if (top == 0) break;
        top -= 1;
        bottom += 1;
    }
    return smudges == 1;
}

fn isSmudgedVerticalReflection(grid: []const []const u8, col: usize) bool {
    var smudges: usize = 0;
    var left = col - 1;
    var right = col;
    while (left < grid[0].len and right < grid[0].len) {
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
    for (a, 0..) |char, i| {
        if (char != b[i]) diff += 1;
    }
    return diff;
}
