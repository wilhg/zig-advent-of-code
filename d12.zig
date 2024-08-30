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
        const repeatedSprings = try repeat(allocator, springs, '?', 5);
        defer allocator.free(repeatedSprings);
        const groups: []const usize = try parseGroups(allocator, parts.next().?);
        defer allocator.free(groups);
        const repeatedGroups: []const usize = try repeatGroups(allocator, groups, 5);
        defer allocator.free(repeatedGroups);

        total += countArrangements(repeatedSprings, repeatedGroups);
    }

    std.debug.print("Total arrangements: {}\n", .{total});
}

fn repeat(allocator: std.mem.Allocator, springs: []const u8, spliter: u8, times: usize) ![]const u8 {
    var repeated = try std.ArrayList(u8).initCapacity(allocator, (springs.len + 1) * times - 1);
    errdefer repeated.deinit();

    for (0..times) |i| {
        try repeated.appendSlice(springs);
        if (i < times - 1) try repeated.append(spliter);
    }

    return repeated.toOwnedSlice();
}

fn repeatGroups(allocator: std.mem.Allocator, groups: []const usize, times: usize) ![]usize {
    const repeatedGroups = try allocator.alloc(usize, groups.len * times);
    errdefer allocator.free(repeatedGroups);

    for (0..times) |i| {
        @memcpy(repeatedGroups[i * groups.len .. (i + 1) * groups.len], groups);
    }

    return repeatedGroups;
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
        // We've processed all groups
        // AND we're not in the middle of a run of damaged springs
        if (state.group == groups.len and state.run == 0) {
            return 1;
        }

        // We're on the last group
        // AND the current run of damaged springs exactly matches the length of the last group
        if (state.group == groups.len - 1 and state.run == groups[state.group]) {
            return 1;
        }

        return 0;
    }

    var result: u64 = 0;
    for ([_]u8{ '.', '#' }) |c| {
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
