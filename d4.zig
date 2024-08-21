// https://adventofcode.com/2023/day/4

const std = @import("std");

const Card = struct {
    id: u8,
    winning_numbers: []const u8,
    numbers_you_have: []const u8,

    fn calcPoints(self: *const Card) u16 {
        var map = std.bit_set.IntegerBitSet(100).initEmpty();
        for (self.winning_numbers) |wn| {
            map.set(wn);
        }

        var points: u16 = 0;
        for (self.numbers_you_have) |nyh| {
            if (map.isSet(nyh)) {
                points = if (points == 0) 1 else points * 2;
            }
        }
        return points;
    }

    fn nextAccCards(self: *const Card) u16 {
        var map = std.bit_set.IntegerBitSet(100).initEmpty();
        for (self.winning_numbers) |wn| {
            map.set(wn);
        }

        var n: u16 = 0;
        for (self.numbers_you_have) |nyh| {
            if (map.isSet(nyh)) n += 1;
        }
        return n;
    }
};

const CardSet = struct {
    card: Card,
    amount: u32,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file = try std.fs.cwd().openFile("d4_input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var card_sets = std.ArrayList(CardSet).init(allocator);
    defer card_sets.deinit();

    var buf: [128]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const card = try parseCard(allocator, line);
        try card_sets.append(CardSet{ .card = card, .amount = 1 });
    }

    var sum: u32 = 0;
    var amount_of_cards: u32 = 0;

    for (card_sets.items, 0..) |*card_set, i| {
        sum += card_set.card.calcPoints();
        amount_of_cards += card_set.amount;
        for (0..card_set.card.nextAccCards()) |j| {
            card_sets.items[i + j + 1].amount += card_set.amount;
        }
    }

    std.debug.print("Sum of points: {}\n", .{sum});
    std.debug.print("Total scratchcards: {}\n", .{amount_of_cards});
}

fn parseCard(allocator: std.mem.Allocator, line: []const u8) !Card {
    var card_parts = std.mem.split(u8, line, ":");
    const id_part = card_parts.next().?;
    const numbers_part = card_parts.next().?;

    var id_iter = std.mem.tokenize(u8, id_part, " ");
    _ = id_iter.next(); // Skip "Card" word
    const id = try std.fmt.parseInt(u8, id_iter.next().?, 10);

    var numbers_split = std.mem.split(u8, numbers_part, "|");
    const winning_numbers_str = numbers_split.next().?;
    const numbers_you_have_str = numbers_split.next().?;

    const winning_numbers = try parseNumbers(allocator, winning_numbers_str);
    const numbers_you_have = try parseNumbers(allocator, numbers_you_have_str);

    return Card{
        .id = id,
        .winning_numbers = winning_numbers,
        .numbers_you_have = numbers_you_have,
    };
}

fn parseNumbers(allocator: std.mem.Allocator, numbers_str: []const u8) ![]const u8 {
    var numbers = std.ArrayList(u8).init(allocator);
    errdefer numbers.deinit();

    var num_iter = std.mem.tokenize(u8, numbers_str, " ");
    while (num_iter.next()) |num_str| {
        const num = try std.fmt.parseInt(u8, num_str, 10);
        try numbers.append(num);
    }

    return numbers.toOwnedSlice();
}
