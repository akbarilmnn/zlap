const std = @import("std");
const expect = std.testing.expect;
const CliParser = @import("cli_parser.zig").CliParser;

test "basic test" {
    _ = CliParser.init_with_args(&.{ "hello", "world" });
    try expect(true);
}

test "another basic test" {
    std.debug.print("another basic test\n", .{});
    const allocator = std.testing.allocator;
    var clip = CliParser.init(allocator);
    defer clip.deinit();
    std.debug.print("\n", .{});
    try expect(true);
}

test "parse long options" {
    std.debug.print("parse long options\n", .{});
    var clip = CliParser.init_with_args(&.{ "prigram", "--boot", "grub", "--start", "10" });
    try clip.parse();
    std.debug.print("\n", .{});
    try expect(true);
}

test "parse trailing long options" {
    std.debug.print("parse trailing long options\n", .{});
    var clip = CliParser.init_with_args(&.{ "program", "--foo", "10", "--exec" });
    try clip.parse();
    std.debug.print("\n", .{});
    try expect(true);
}

test "parse short options" {
    std.debug.print("parse short options\n", .{});
    var clip = CliParser.init_with_args(&.{ "program", "-l", "-t", "-a", "10" });
    try clip.parse();
    std.debug.print("\n", .{});
    try expect(true);
}

test "parse trailing short options" {
    std.debug.print("parse trailing short options\n", .{});
    var clip = CliParser.init_with_args(&.{ "program", "-l", "-t", "-a" });
    try clip.parse();
    std.debug.print("\n", .{});
    try expect(true);
}

test "parse combined short options" {
    std.debug.print("parse combined short options\n", .{});
    var clip = CliParser.init_with_args(&.{ "program", "-lta" });
    try clip.parse();
    std.debug.print("\n", .{});
    try expect(true);
}

test "parse combined short options with value at the last option" {
    std.debug.print("parse combined short options with value at the last option\n", .{});
    var clip = CliParser.init_with_args(&.{ "program", "-lta", "10" });
    try clip.parse();
    std.debug.print("\n", .{});
    try expect(true);
}
