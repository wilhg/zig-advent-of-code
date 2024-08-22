const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const fs = std.fs;
const io = std.io;

const STPair = struct {
    source: i64,
    target: i64,
    range: i64,

    fn withinRangeS(self: STPair, source: i64) bool {
        return source >= self.source and source < self.source + self.range;
    }

    fn calcTarget(self: STPair, source: i64) i64 {
        const diff = self.target - self.source;
        return source + diff;
    }

    fn withinRangeT(self: STPair, target: i64) bool {
        return target >= self.target and target < self.target + self.range;
    }

    fn calcSource(self: STPair, target: i64) i64 {
        const diff = self.target - self.source;
        return target - diff;
    }
};

const STMap = struct {
    pairs: std.ArrayList(STPair),

    fn calcTarget(self: STMap, source: i64) i64 {
        var left: usize = 0;
        var right: usize = self.pairs.items.len;

        while (left < right) {
            const mid = left + (right - left) / 2;
            const pair = self.pairs.items[mid];
            if (pair.withinRangeS(source)) {
                return pair.calcTarget(source);
            } else if (source < pair.source) {
                right = mid;
            } else {
                left = mid + 1;
            }
        }
        return source;
    }

    fn calcSource(self: STMap, target: i64) i64 {
        var left: usize = 0;
        var right: usize = self.pairs.items.len;

        while (left < right) {
            const mid = left + (right - left) / 2;
            const pair = self.pairs.items[mid];
            if (pair.withinRangeT(target)) {
                return pair.calcSource(target);
            } else if (target < pair.target) {
                right = mid;
            } else {
                left = mid + 1;
            }
        }
        return target;
    }

    fn sortBySource(self: *STMap) void {
        std.sort.sort(STPair, self.pairs.items, {}, struct {
            fn lessThan(_: void, a: STPair, b: STPair) bool {
                return a.source < b.source;
            }
        }.lessThan);
    }

    fn sortByTarget(self: *STMap) void {
        std.sort.sort(STPair, self.pairs.items, {}, struct {
            fn lessThan(_: void, a: STPair, b: STPair) bool {
                return a.target < b.target;
            }
        }.lessThan);
    }
};

fn parseInput(allocator: std.mem.Allocator, file_path: []const u8) !struct { seeds: std.ArrayList(i64), maps: std.ArrayList(STMap) } {
    const file = try fs.cwd().openFile(file_path, .{});
    defer file.close();

    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var seeds = std.ArrayList(i64).init(allocator);
    errdefer seeds.deinit();

    var maps = std.ArrayList(STMap).init(allocator);
    errdefer {
        for (maps.items) |*map| {
            map.pairs.deinit();
        }
        maps.deinit();
    }

    var buf: [256]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (mem.startsWith(u8, line, "seeds:")) {
            var it = mem.tokenize(u8, line[7..], " ");
            while (it.next()) |num_str| {
                const num = try fmt.parseInt(i64, num_str, 10);
                try seeds.append(num);
            }
        } else if (mem.endsWith(u8, line, "map:")) {
            try maps.append(STMap{ .pairs = std.ArrayList(STPair).init(allocator) });
        } else if (line.len > 0) {
            var it = mem.tokenize(u8, line, " ");
            const target = try fmt.parseInt(i64, it.next().?, 10);
            const source = try fmt.parseInt(i64, it.next().?, 10);
            const range = try fmt.parseInt(i64, it.next().?, 10);
            try maps.items[maps.items.len - 1].pairs.append(STPair{
                .source = source,
                .target = target,
                .range = range,
            });
        }
    }

    return .{ .seeds = seeds, .maps = maps };
}

fn foundSeed(seed: i64) bool {
    const real_seeds = [_][2]i64{
        .{ 4043382508, 113348245 },
        .{ 3817519559, 177922221 },
        .{ 3613573568, 7600537 },
        .{ 773371046, 400582097 },
        .{ 2054637767, 162982133 },
        .{ 2246524522, 153824596 },
        .{ 1662955672, 121419555 },
        .{ 2473628355, 846370595 },
        .{ 1830497666, 190544464 },
        .{ 230006436, 483872831 },
    };

    for (real_seeds) |seed_range| {
        if (seed >= seed_range[0] and seed < seed_range[0] + seed_range[1]) {
            return true;
        }
    }
    return false;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const parsed_data = try parseInput(allocator, "d5_input.txt");
    const seeds = parsed_data.seeds;
    const maps = parsed_data.maps;
    defer {
        seeds.deinit();
        for (maps.items) |*map| {
            map.pairs.deinit();
        }
        maps.deinit();
    }

    var lowest_result: i64 = std.math.maxInt(i64);
    for (seeds.items) |seed| {
        var n: i64 = seed;
        for (maps.items) |map| {
            n = map.calcTarget(n);
        }
        lowest_result = @min(lowest_result, n);
    }

    std.debug.print("Lowest result: {d}\n", .{lowest_result});

    // Sort maps for efficient searching
    for (maps.items) |*map| {
        map.sortBySource();
    }

    // Sort maps by target for reverse lookup
    for (maps.items) |*map| {
        map.sortByTarget();
    }

    var location: u64 = 0;
    while (location < std.math.maxInt(u32)) : (location += 1) {
        var n: i64 = @intCast(location);
        var i = maps.items.len;
        while (i > 0) : (i -= 1) {
            n = maps.items[i - 1].calcSource(n);
        }
        if (foundSeed(n)) {
            std.debug.print("Found seed at location {d}\n", .{location});
            break;
        }
    }

    // Print parsed data
    // std.debug.print("Seeds: {any}\n", .{seeds.items});
    // for (maps.items, 0..) |map, i| {
    //     std.debug.print("Map {d}:\n", .{i + 1});
    //     for (map.pairs.items) |pair| {
    //         std.debug.print("  {d} {d} {d}\n", .{ pair.target, pair.source, pair.range });
    //     }
    // }
}
