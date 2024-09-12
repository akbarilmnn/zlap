const std = @import("std");
const expect = std.testing.expect;
const panic = std.debug.panic;
const Allocator = std.mem.Allocator;

/// Parses CLI arguments.
const CliParser = struct {
    const Self = @This();

    // This is inititalized when invoked `init_with_args` function.
    slice: ?[]const []const u8,
    // This is inititalized when invoked `init`.
    args: ?[]const [:0]u8,

    // Only used when the struct is initialized with `init`
    allocator: ?Allocator,

    /// Initialize parser with CLI arguments.
    pub fn init(allocator: Allocator) Self {
        const args = std.process.argsAlloc(allocator) catch |err| oom(err);
        return Self{
            .args = args,
            .slice = null,
            .allocator = allocator,
        };
    }

    /// Initialize parser with hard-coded CLI arguments.
    pub fn init_with_args(slice: []const []const u8) Self {
        return Self{
            .args = null,
            .slice = slice,
            .allocator = null,
        };
    }

    /// Deinitialize parser. This does nothing if the parser is initialized other than `init`.
    pub fn deinit(self: *Self) void {
        if (self.allocator) |allocator| {
            // This won't panic because `self.args` is valid if and only if `self.allocator` is valid.
            std.process.argsFree(allocator, self.args.?);
        }
    }

    // Helper function that handles unrecoverable errors.
    fn oom(err: anyerror) noreturn {
        panic("ERROR: {s}\n", .{@errorName(err)});
    }
};

test "invoke" {
    _ = CliParser.init_with_args(&.{ "hello", "world" });
}

test "invoke again" {
    const allocator = std.testing.allocator;
    var v = CliParser.init(allocator);
    defer v.deinit();
}
