const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const fs = std.fs;
const io = std.io;

const STPair = struct {
    source: i64,
    target: i64,
    range: i64,

    fn withinRange(self: STPair, source: i64) bool {
        return source >= self.source and source < self.source + self.range;
    }

    fn calcTarget(self: STPair, source: i64) i64 {
        const diff = self.target - self.source;
        return source + diff;
    }
};

const STMap = struct {
    pairs: std.ArrayList(STPair),

    fn calcTarget(self: STMap, source: i64) i64 {
        for (self.pairs.items) |pair| {
            if (pair.withinRange(source)) {
                return pair.calcTarget(source);
            }
        }
        return source;
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

    // Print parsed data
    // std.debug.print("Seeds: {any}\n", .{seeds.items});
    // for (maps.items, 0..) |map, i| {
    //     std.debug.print("Map {d}:\n", .{i + 1});
    //     for (map.pairs.items) |pair| {
    //         std.debug.print("  {d} {d} {d}\n", .{ pair.target, pair.source, pair.range });
    //     }
    // }
}
