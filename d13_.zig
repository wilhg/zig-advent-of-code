const std = @import("std");

pub fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList([][]u1) {
    var blocks = std.ArrayList([][]u1).init(allocator);
    var lines = std.mem.split(u8, input, "\n");

    var current_block = std.ArrayList([]u1).init(allocator);
    while (lines.next()) |line| {
        if (line.len == 0) {
            if (current_block.items.len > 0) {
                try blocks.append(try current_block.toOwnedSlice());
                current_block = std.ArrayList([]u1).init(allocator);
            }
            continue;
        }

        var row = try allocator.alloc(u1, line.len);
        for (line, 0..) |char, i| {
            row[i] = switch (char) {
                '.' => 0,
                '#' => 1,
                else => return error.InvalidCharacter,
            };
        }
        try current_block.append(row);
    }

    if (current_block.items.len > 0) {
        try blocks.append(try current_block.toOwnedSlice());
    } else {
        current_block.deinit();
    }

    return blocks;
}

fn transpose(allocator: std.mem.Allocator, matrix: []const []const u1) ![][]u1 {
    if (matrix.len == 0 or matrix[0].len == 0) return &[_][]u1{};

    const rows = matrix[0].len;
    const cols = matrix.len;

    const transposed = try allocator.alloc([]u1, rows);
    errdefer {
        for (transposed) |row| {
            allocator.free(row);
        }
        allocator.free(transposed);
    }

    for (transposed, 0..) |*row, i| {
        row.* = try allocator.alloc(u1, cols);
        for (row.*, 0..) |*cell, j| {
            cell.* = matrix[j][i];
        }
    }

    return transposed;
}

fn rowToU16(row: []const u1) u16 {
    var result: u16 = 0;
    for (row) |bit| {
        result = (result << 1) | bit;
    }
    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("d13_input.txt");
    var blocks = try parseInput(allocator, input);
    defer {
        for (blocks.items) |block| {
            for (block) |row| {
                allocator.free(row);
            }
            allocator.free(block);
        }
        blocks.deinit();
    }

    var reuslt: usize = 0;
    // Print the original and transposed blocks
    for (blocks.items, 0..) |block, i| {
        std.debug.print("Block {}:\n", .{i + 1});

        var last_value: usize = 0;
        std.debug.print("Block {} as u16 values:\n", .{i + 1});
        for (block, 0..) |row, j| {
            const value = rowToU16(row);
            if (value == last_value) {
                reuslt += j * 100;
                break;
            }
            std.debug.print("{b:0>16} ({d})\n", .{ value, value });
            last_value = value;
        }

        const transposed = try transpose(allocator, block);
        defer {
            for (transposed) |row| {
                allocator.free(row);
            }
            allocator.free(transposed);
        }

        var last_value2: usize = 0;
        std.debug.print("Block {} (Transposed) as u16 values:\n", .{i + 1});
        for (transposed, 0..) |row, j| {
            const value = rowToU16(row);
            if (value == last_value2) {
                reuslt += j;
                break;
            }
            last_value2 = value;
            std.debug.print("{b:0>16} ({d})\n", .{ value, value });
        }

        std.debug.print("\n", .{});
    }
    std.debug.print("{d}\n", .{reuslt});
}

fn printBlock(block: []const []const u1) void {
    for (block) |row| {
        for (row) |cell| {
            std.debug.print("{}", .{cell});
        }
        std.debug.print("\n", .{});
    }
}
