const std = @import("std");

const Node = struct {
    left: []const u8,
    right: []const u8,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("d8_input.txt");
    var lines = std.mem.split(u8, input, "\n");

    const instructions = lines.next().?;
    _ = lines.next(); // Skip empty line

    var network = std.StringHashMap(Node).init(allocator);
    defer network.deinit();

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const name = line[0..3];
        const left = line[7..10];
        const right = line[12..15];
        try network.put(name, .{ .left = left, .right = right });
    }

    var current: []const u8 = "AAA";
    var steps: usize = 0;
    var instruction_index: usize = 0;

    while (!std.mem.eql(u8, current, "ZZZ")) {
        const node = network.get(current).?;
        current = if (instructions[instruction_index] == 'L') node.left else node.right;
        steps += 1;
        instruction_index = (instruction_index + 1) % instructions.len;
    }

    std.debug.print("Steps required to reach ZZZ: {}\n", .{steps});
}
