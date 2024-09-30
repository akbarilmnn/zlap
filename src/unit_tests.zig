const std = @import("std");
const expect = std.testing.expect;
const eql = std.mem.eql;
const Iter = @import("iter.zig").FlagIterator;

test "initialize Iter using init_with_args" {
    const it = Iter.initWithArgs(&.{ "hello", "world" });
    _ = it;
    try expect(true);
}

test "initialize Iter using init" {
    const allocator = std.testing.allocator;
    var it = Iter.init(allocator);
    defer it.deinit();
    try expect(true);
}

test "parse long options" {
    var iter = Iter.initWithArgs(&.{ "program", "--boot", "grub", "--start", "10", "-" });
    const pair = iter.next().?;
    try expect(eql(u8, pair.flag, "boot"));
    try expect(eql(u8, pair.argument.?, "grub"));
    const another_pair = iter.next().?;
    try expect(eql(u8, another_pair.flag, "start"));
    try expect(eql(u8, another_pair.argument.?, "10"));
    // doens't catch the last one!
    try expect(iter.next() == null);
}

test "parse trailing long options" {
    var iter = Iter.initWithArgs(&.{ "program", "--foo", "10", "--exec" });
    const pair = iter.next().?;
    try expect(eql(u8, pair.flag, "foo"));
    try expect(eql(u8, pair.argument.?, "10"));
    const another_pair = iter.next().?;
    try expect(eql(u8, another_pair.flag, "exec"));
    try expect(another_pair.argument == null);
}

test "parse short options" {
    var iter = Iter.initWithArgs(&.{ "program", "-l", "-t", "-a" });
    const pair = iter.next().?;
    try expect(eql(u8, pair.flag, "l"));
    const another_pair = iter.next().?;
    try expect(eql(u8, another_pair.flag, "t"));
    const yet_another = iter.next().?;
    try expect(eql(u8, yet_another.flag, "a"));
}

test "parse combined trailing short options" {
    var iter = Iter.initWithArgs(&.{ "program", "-lta" });
    const pair = iter.next().?;
    try expect(eql(u8, pair.flag, "l"));
    const another_pair = iter.next().?;
    try expect(eql(u8, another_pair.flag, "t"));
    const yet_another = iter.next().?;
    try expect(eql(u8, yet_another.flag, "a"));
}

test "parse trailing short options with value at the end" {
    var iter = Iter.initWithArgs(&.{ "program", "-lta", "10", "-bcd", "20" });
    const l = iter.next().?;
    try expect(eql(u8, l.flag, "l"));
    const t = iter.next().?;
    try expect(eql(u8, t.flag, "t"));
    const a = iter.next().?;
    try expect(eql(u8, a.flag, "a"));
    try expect(eql(u8, a.argument.?, "10"));

    const b = iter.next().?;
    try expect(eql(u8, b.flag, "b"));
    const c = iter.next().?;
    try expect(eql(u8, c.flag, "c"));
    const d = iter.next().?;
    try expect(eql(u8, d.flag, "d"));
    try expect(eql(u8, d.argument.?, "20"));
}
