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
        total += try findReflection(pattern);
    }

    return total;
}

fn findReflection(pattern: []const u8) !usize {
    var lines = std.mem.split(u8, pattern, "\n");
    var grid = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer grid.deinit();

    while (lines.next()) |line| {
        try grid.append(line);
    }

    // Check for horizontal reflection
    for (1..grid.items.len) |i| {
        if (isHorizontalReflection(grid.items, i)) {
            return i * 100;
        }
    }

    // Check for vertical reflection
    for (1..grid.items[0].len) |i| {
        if (isVerticalReflection(grid.items, i)) {
            return i;
        }
    }

    return error.NoReflectionFound;
}

fn isHorizontalReflection(grid: []const []const u8, row: usize) bool {
    var top = row - 1;
    var bottom = row;
    while (top < grid.len and bottom < grid.len) {
        if (!std.mem.eql(u8, grid[top], grid[bottom])) {
            return false;
        }
        if (top == 0) break;
        top -= 1;
        bottom += 1;
    }
    return true;
}

fn isVerticalReflection(grid: []const []const u8, col: usize) bool {
    var left = col - 1;
    var right = col;
    while (left < grid[0].len and right < grid[0].len) {
        for (grid) |row| {
            if (row[left] != row[right]) {
                return false;
            }
        }
        if (left == 0) break;
        left -= 1;
        right += 1;
    }
    return true;
}
