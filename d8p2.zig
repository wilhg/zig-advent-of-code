const std = @import("std");

// Define a Node structure to represent each node in the network
const Node = struct {
    left: []const u8,
    right: []const u8,
};

// Calculate the Greatest Common Divisor (GCD) of two numbers
fn gcd(a: usize, b: usize) usize {
    if (b == 0) return a;
    return gcd(b, a % b);
}

// Calculate the Least Common Multiple (LCM) of two numbers
fn lcm(a: usize, b: usize) usize {
    return (a * b) / gcd(a, b);
}

pub fn main() !void {
    // Initialize a Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    const allocator = arena.allocator();

    // Read the input file
    const input = @embedFile("d8_input.txt");
    var lines = std.mem.split(u8, input, "\n");

    // Get the navigation instructions from the first line
    const instructions = lines.next().?;
    _ = lines.next(); // Skip empty line

    // Initialize a hash map to store the network
    var network = std.StringHashMap(Node).init(allocator);
    defer network.deinit();

    // Initialize an array list to store starting nodes
    var starting_nodes = std.ArrayList([]const u8).init(allocator);
    defer starting_nodes.deinit();

    // Parse the input and build the network
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const name = line[0..3];
        const left = line[7..10];
        const right = line[12..15];
        try network.put(name, .{ .left = left, .right = right });
        // If the node ends with 'A', it's a starting node
        if (name[2] == 'A') {
            try starting_nodes.append(name);
        }
    }

    // Initialize an array list to store cycle lengths
    var cycle_lengths = std.ArrayList(usize).init(allocator);
    defer cycle_lengths.deinit();

    // Calculate cycle length for each starting node
    for (starting_nodes.items) |start| {
        var current = start;
        var steps: usize = 0;
        var instruction_index: usize = 0;

        // Follow instructions until reaching a node ending with 'Z'
        while (current[2] != 'Z') {
            const node = network.get(current).?;
            current = if (instructions[instruction_index] == 'L') node.left else node.right;
            steps += 1;
            instruction_index = (instruction_index + 1) % instructions.len;
        }

        try cycle_lengths.append(steps);
    }

    // Calculate the LCM of all cycle lengths
    var result: usize = cycle_lengths.items[0];
    for (cycle_lengths.items[1..]) |length| {
        result = lcm(result, length);
    }

    // Print the result
    std.debug.print("Steps required for all paths to end at Z: {}\n", .{result});
}
