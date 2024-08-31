const std = @import("std");

const Pair = struct {
    key: []const u8,
    value: u4,
};

const HashMap = [256]?std.ArrayList(Pair);

pub fn main() !void {
    // Open the file
    const file = try std.fs.cwd().openFile("d15_input.txt", .{});
    defer file.close();

    // Read the entire file content
    const content = try file.readToEndAlloc(std.heap.page_allocator, 32 * 1024); // 32kb limit
    defer std.heap.page_allocator.free(content);

    var map: HashMap = .{null} ** 256;

    var it = std.mem.split(u8, content, ",");
    while (it.next()) |step| {
        const key = getKey(step);
        const h = hash(key);
        if (map[h] == null) {
            map[h] = std.ArrayList(Pair).init(std.heap.page_allocator);
        }

        var list = &map[h].?;

        // if step ends with '-', remove the pair from the hashmap
        if (step[step.len - 1] == '-') {
            for (list.items, 0..) |*pair, i| {
                if (std.mem.eql(u8, pair.key, key)) {
                    _ = list.orderedRemove(i);
                    break;
                }
            }
        } else { // with =
            const value = try std.fmt.parseInt(u4, step[step.len - 1 ..], 10);
            // if key is already in the list, update the value, else append
            var found = false;
            for (list.items) |*pair| {
                if (std.mem.eql(u8, pair.key, key)) {
                    pair.value = value;
                    found = true;
                    break;
                }
            }
            if (!found) {
                try list.append(.{ .key = key, .value = value });
            }
        }
    }

    // print the content of the map
    var total_power: usize = 0;
    for (map, 1..) |maybe_list, box_number| {
        if (maybe_list) |list| {
            for (list.items, 1..) |pair, slot| {
                const lens_power = box_number * slot * pair.value;
                total_power += lens_power;
                std.debug.print("Box {}: {s} {} (power: {})\n", .{ box_number, pair.key, pair.value, lens_power });
            }
        }
    }
    std.debug.print("Total focusing power: {}\n", .{total_power});
}

fn hash(step: []const u8) u8 {
    var sum: u16 = 0;
    for (step) |c| {
        sum = (sum + c) * 17 % 256;
    }
    return @intCast(sum);
}

fn getKey(step: []const u8) []const u8 {
    // if step ends with '-', return the step without the last character
    // else return the step without the last two characters (=X)
    return if (step[step.len - 1] == '-') step[0 .. step.len - 1] else step[0 .. step.len - 2];
}
