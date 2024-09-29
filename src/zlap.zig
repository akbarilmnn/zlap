const std = @import("std");
const Allocator = std.mem.Allocator;

/// Parses CLI arguments
pub const CliParser = struct {
    const Self = @This();

    // All possible errors during parsing.
    const ParsingError = error{};

    // Either hard-coded CLI arguments or runtime CLI arguments.
    args: []const []const u8,

    // Only present if initialized with `init`.
    allocator: ?Allocator,

    /// Returns a CliParser that parses CLI arguments (panics if it is not possible to allocate memory)..
    pub fn init(allocator: Allocator) Self {
        const args: []const []const u8 = std.process.argsAlloc(allocator) catch |err|
            panic(err, "ERROR: Could not allocate enough memory! {s}\n");
        return Self{ .args = args, .allocator = allocator };
    }

    /// Returns a CliParser that parses a slice of string which acts as a CLI arguments.
    pub fn init_with_args(args: []const []const u8) Self {
        return Self{
            .args = args,
            .allocator = null,
        };
    }

    pub fn parse(self: *Self) ParsingError!void {
        for (self.args, 0..) |arg, idx| {
            if (isLongOption(arg)) {
                try self.handleLongOption(idx);
            } else if (isShortOption(arg)) {
                try self.handleShortOption(idx);
            }
        }
        // Ignore everything else that is not an option.
    }

    /// Free allocated CLI arguments. Does nothing if it is invoked other than `init`.
    pub fn deinit(self: *Self) void {
        if (self.allocator) |allocator| {
            const args: []const [:0]u8 = @ptrCast(self.args);
            std.process.argsFree(allocator, args);
        }
    }

    fn handleLongOption(self: *Self, idx: usize) ParsingError!void {
        // NOTE: whenever the option is of type boolean, when it is invoked without any value it assumes the value
        // to be negated.
        // TODO: mutate the specific field of the inner struct that matches option
        // and convert option's value to the type of tht specific field of the inner struct.

        // handle trailing options e.g: (foo --base bar --count)
        const flag = self.args[idx];
        if (idx == self.args.len - 1) {
            std.debug.print("last long option detected: {s}\n", .{flag});
            return;
        }

        const value = self.args[idx + 1];

        // check if non-options' arguments is not another flag (e.g: foo --base --address 10)
        if (!isOption(value)) {
            std.debug.print("long option \'{s}\' with value of {s}\n", .{ flag, value });
            return;
        }
        std.debug.print("found a long option without a value: {s}\n", .{flag});
    }

    fn handleShortOption(self: *Self, idx: usize) ParsingError!void {
        // NOTE: whenever the option is of type boolean, when it is invoked without any value it assumes the value
        // to be negated.
        // TODO: mutate the specific field of the inner struct that matches option
        // and convert option's value to the type of tht specific field of the inner struct.

        const flag_or_flags = self.args[idx];

        // potentially, this short options could be a combination of other short options.
        // handle combined options (e.g: ls -lah -> ls -l -a -h ) or (e.g: foo -baz 10 -> foo -b -a -z 10).

        // iterate through combined options.
        const stripped = flag_or_flags[1..];
        for (stripped, 0..) |flag, initial_idx| {
            if (initial_idx == stripped.len - 1) {
                if (idx == self.args.len - 1) {
                    std.debug.print("last short option with no value: {c}\n", .{flag});
                    return;
                }
                const value = self.args[idx + 1];
                if (!isOption(value)) {
                    std.debug.print("found an option \'{c}\' with a value: {s}\n", .{ flag, value });
                    return;
                }
                std.debug.print("found a short option without a value: {c}\n", .{flag});
                return;
            }
            std.debug.print("found a short option: {c}\n", .{flag});
        }
    }

    fn isShortOption(str: []const u8) bool {
        return std.mem.startsWith(u8, str, "-");
    }

    fn isLongOption(str: []const u8) bool {
        return std.mem.startsWith(u8, str, "--");
    }

    fn isOption(str: []const u8) bool {
        return std.mem.startsWith(u8, str, "--") or std.mem.startsWith(u8, str, "-");
    }

    // helper function to pritnn error messages with errorname
    fn panic(err: anyerror, comptime msg: []const u8) noreturn {
        std.debug.panic(msg, .{@errorName(err)});
    }
};
