const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const fs = std.fs;
const io = std.io;

const STPair = struct {
    source: u32,
    target: u32,
    range: u64,

    fn withinRange(self: STPair, source: u64) bool {
        return source >= self.source and source < @as(u64, self.target) + @as(u64, self.source);
    }

    fn calcTarget(self: STPair, source: u64) u64 {
        const diff = @as(i64, @intCast(self.target)) - @as(i64, @intCast(self.source));
        return @as(u64, @intCast(@as(i64, @intCast(source)) + diff));
    }
};

const STMap = struct {
    pairs: std.ArrayList(STPair),

    fn calcTarget(self: STMap, source: u64) u64 {
        var n = source;
        for (self.pairs.items) |pair| {
            if (pair.withinRange(n)) {
                n = pair.calcTarget(n);
            }
        }
        return n;
    }
};

fn parseInput(allocator: std.mem.Allocator, file_path: []const u8) !struct { seeds: std.ArrayList(u64), maps: std.ArrayList(STMap) } {
    const file = try fs.cwd().openFile(file_path, .{});
    defer file.close();

    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var seeds = std.ArrayList(u64).init(allocator);
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
                const num = try fmt.parseInt(u64, num_str, 10);
                try seeds.append(num);
            }
        } else if (mem.endsWith(u8, line, "map:")) {
            try maps.append(STMap{ .pairs = std.ArrayList(STPair).init(allocator) });
        } else if (line.len > 0) {
            var it = mem.tokenize(u8, line, " ");
            const target = try fmt.parseInt(u32, it.next().?, 10);
            const source = try fmt.parseInt(u32, it.next().?, 10);
            const range = try fmt.parseInt(u32, it.next().?, 10);
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
    var lowest_result: u64 = std.math.maxInt(u64);
    for (seeds.items) |seed| {
        var n: u64 = seed;
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
