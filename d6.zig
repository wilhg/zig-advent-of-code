// The quadratic formula is used in this problem to efficiently solve for the winning hold times. Here's a concise explanation:
// Race physics:
// Hold time (t) + Travel time = Total time (T)
// Distance traveled = Speed Travel time
// Speed = Hold time (t)
// Equation:
// t (T - t) > D
// where T is total time, D is distance to beat
// Expanded:
// -t² + Tt - D > 0
// Quadratic formula solves:
// -t² + Tt - D = 0

const std = @import("std");

const Race = struct {
    time: u64,
    distance: u64,
};

fn countWaysToWin(race: Race) u64 {
    // Use quadratic formula to find the roots
    const a: f64 = -1;
    const b: f64 = @as(f64, @floatFromInt(race.time));
    const c: f64 = -@as(f64, @floatFromInt(race.distance));

    const discriminant = b * b - 4 * a * c;
    if (discriminant < 0) return 0;

    const sqrt_discriminant = @sqrt(discriminant);
    const x1 = (-b + sqrt_discriminant) / (2 * a);
    const x2 = (-b - sqrt_discriminant) / (2 * a);

    // Find the integer range of winning hold times
    const min_hold_time = @as(u64, @intFromFloat(@floor(x1))) + 1;
    const max_hold_time = @as(u64, @intFromFloat(@ceil(x2))) - 1;

    return max_hold_time - min_hold_time + 1;
}

pub fn main() !void {
    const races = [_]Race{
        .{ .time = 40, .distance = 233 },
        .{ .time = 82, .distance = 1011 },
        .{ .time = 84, .distance = 1110 },
        .{ .time = 92, .distance = 1487 },
    };

    var total_ways: u64 = 1;
    for (races) |race| {
        const ways = countWaysToWin(race);
        total_ways *= ways;
    }

    std.debug.print("Total ways to win: {d}\n", .{total_ways});

    // Part 2: Treat the input as a single race
    const big_race = Race{
        .time = 40828492,
        .distance = 233101111101487,
    };

    const big_race_ways = countWaysToWin(big_race);
    std.debug.print("Ways to win the big race: {d}\n", .{big_race_ways});
}
