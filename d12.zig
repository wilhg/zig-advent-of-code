const std = @import("std");

const State = struct {
    pos: usize,
    group: usize,
    run: usize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("d12_input.txt");
    var lines = std.mem.tokenize(u8, input, "\n");

    var total: u64 = 0;
    while (lines.next()) |line| {
        var parts = std.mem.split(u8, line, " ");
        const springs = parts.next().?;
        const groups = try parseGroups(allocator, parts.next().?);
        defer allocator.free(groups);

        total += countArrangements(springs, groups);
    }

    std.debug.print("Total arrangements: {}\n", .{total});
}

fn parseGroups(allocator: std.mem.Allocator, groupStr: []const u8) ![]usize {
    var groups = std.ArrayList(usize).init(allocator);
    var nums = std.mem.tokenize(u8, groupStr, ",");
    while (nums.next()) |num| {
        try groups.append(try std.fmt.parseInt(usize, num, 10));
    }
    return groups.toOwnedSlice();
}

fn countArrangements(springs: []const u8, groups: []const usize) u64 {
    var cache = std.AutoHashMap(State, u64).init(std.heap.page_allocator);
    defer cache.deinit();

    return dfs(springs, groups, &cache, State{ .pos = 0, .group = 0, .run = 0 });
}

fn dfs(springs: []const u8, groups: []const usize, cache: *std.AutoHashMap(State, u64), state: State) u64 {
    if (cache.get(state)) |count| {
        return count;
    }

    if (state.pos == springs.len) {
        if (state.group == groups.len and state.run == 0) {
            return 1;
        }
        if (state.group == groups.len - 1 and state.run == groups[state.group]) {
            return 1;
        }
        return 0;
    }

    var result: u64 = 0;
    const chars = [_]u8{ '.', '#' };
    for (chars) |c| {
        if (springs[state.pos] == c or springs[state.pos] == '?') {
            if (c == '.' and state.run == 0) {
                result += dfs(springs, groups, cache, State{ .pos = state.pos + 1, .group = state.group, .run = 0 });
            } else if (c == '.' and state.run > 0 and state.group < groups.len and state.run == groups[state.group]) {
                result += dfs(springs, groups, cache, State{ .pos = state.pos + 1, .group = state.group + 1, .run = 0 });
            } else if (c == '#') {
                result += dfs(springs, groups, cache, State{ .pos = state.pos + 1, .group = state.group, .run = state.run + 1 });
            }
        }
    }

    cache.put(state, result) catch unreachable;
    return result;
}
