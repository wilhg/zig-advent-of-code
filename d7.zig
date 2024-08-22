const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const fs = std.fs;
const io = std.io;

const Hand = struct {
    cards: [5]u8,
    bid: u32,
};

fn cardValue(card: u8) u8 {
    return switch (card) {
        'A' => 14,
        'K' => 13,
        'Q' => 12,
        'T' => 10,
        'J' => 1, // Joker is now the lowest value
        else => card - '0',
    };
}

fn handType(hand: *const Hand) u8 {
    var counts: [15]u8 = .{0} ** 15;
    var jokers: u8 = 0;
    for (hand.cards) |card| {
        if (card == 'J') {
            jokers += 1;
        } else {
            counts[cardValue(card)] += 1;
        }
    }

    var max_count: u8 = 0;
    var second_max_count: u8 = 0;
    for (counts) |count| {
        if (count >= max_count) {
            second_max_count = max_count;
            max_count = count;
        } else if (count > second_max_count) {
            second_max_count = count;
        }
    }

    max_count += jokers;

    if (max_count == 5) return 6; // Five of a kind
    if (max_count == 4) return 5; // Four of a kind
    if (max_count == 3 and second_max_count == 2) return 4; // Full house
    if (max_count == 3) return 3; // Three of a kind
    if (max_count == 2 and second_max_count == 2) return 2; // Two pair
    if (max_count == 2) return 1; // One pair
    return 0; // High card
}

fn compareHands(context: void, a: Hand, b: Hand) bool {
    _ = context;
    const type_a = handType(&a);
    const type_b = handType(&b);
    if (type_a != type_b) {
        return type_a < type_b;
    }
    for (a.cards, b.cards) |card_a, card_b| {
        if (card_a != card_b) {
            return cardValue(card_a) < cardValue(card_b);
        }
    }
    return false;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file = try fs.cwd().openFile("d7_input.txt", .{});
    defer file.close();

    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var hands = std.ArrayList(Hand).init(allocator);
    defer hands.deinit();

    var buf: [256]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = mem.split(u8, line, " ");
        const cards = it.next().?;
        const bid = try fmt.parseInt(u32, it.next().?, 10);
        try hands.append(Hand{ .cards = cards[0..5].*, .bid = bid });
    }

    mem.sort(Hand, hands.items, {}, compareHands);

    var total_winnings: u64 = 0;
    for (hands.items, 0..) |hand, i| {
        total_winnings += hand.bid * @as(u64, i + 1);
    }

    std.debug.print("Total winnings (Part 2): {d}\n", .{total_winnings});
}
