const std = @import("std");
const Allocator = std.mem.Allocator;
// Iterate over CLI to find flags (options).
pub const FlagIterator = struct {
    const Self = @This();
    // Holds user-input CLI arguments.
    args: []const []const u8,
    // Used to allocate CLI arguments when initialized using `init`.
    allocator: ?Allocator = null,
    // A counter specifically to handle combined options.
    counter: usize = 0,

    // Struct representation of an option that may have a value.
    const Flag = struct {
        flag: []const u8,
        argument: ?[]const u8 = null,

        fn flag(name: []const u8) Flag {
            return Flag{
                .flag = name,
            };
        }

        fn pairs(key: []const u8, value: []const u8) Flag {
            return Flag{
                .flag = key,
                .argument = value,
            };
        }
    };

    // Initialize heap-allocated CLI arguments from the user.
    pub fn init(allocator: Allocator) Self {
        const args: []const []const u8 = std.process.argsAlloc(allocator) catch |err|
            err_catch("ERROR: out of memory!", err);
        return Self{
            .args = args,
            .allocator = allocator,
        };
    }

    // Free heap-allocated CLI arguments (does nothing if invoked other than `init`).
    pub fn deinit(self: *Self) void {
        if (self.allocator) |allocator| {
            std.process.argsFree(allocator, @ptrCast(self.args));
        }
    }

    // Initialize hypothetical CLI arguments (useful for testing).
    pub fn initWithArgs(args: []const []const u8) Self {
        return Self{
            .args = @ptrCast(args),
            .allocator = null,
        };
    }

    // For zig's iterator interface.
    pub fn next(self: *Self) ?Flag {
        for (self.args, 0..) |arg, idx| {
            if (isLongOption(arg)) {
                return self.handleLongOption(idx);
            }
            if (isShortOption(arg)) {
                return self.handleShortOption(idx);
            }
        }
        return null;
    }

    /////////////////////////////////////////////////
    //          Private Helper Functions           //
    /////////////////////////////////////////////////

    fn handleLongOption(self: *Self, idx: usize) Flag {
        // Get detected flag / option by accessing self.args using an index (idx).
        const optname = self.args[idx];
        // Strip `--` prefix
        const stripped = optname[2..];
        return self.getFlagGotoNext(idx, stripped);
    }

    fn handleShortOption(self: *Self, idx: usize) Flag {
        // Can either be single (e.g: -t) or combined (e.g: -xvf or -xvf 10).
        const optname = self.args[idx];
        // Strip `-` prefix
        const stripped = optname[1..];

        // Single flag case.
        if (stripped.len == 1) {
            return self.getFlagGotoNext(idx, stripped);
        }

        // for the combined case we want to interpret it as: -x -v -f or -x -v -f 10
        for (stripped) |_| {
            // start and middle part of combined flag.
            const flag = stripped[self.counter .. self.counter + 1];
            if (self.counter != stripped.len - 1) {
                self.counter += 1;
                return Flag.flag(flag);
            }
            // end part of combined flag.
            return self.getFlagGotoNext(idx, flag);
        }
        unreachable;
    }

    // A helper function to minimalize duplication for `handleLongOption` and `handleShortOption`.
    fn getFlagGotoNext(self: *Self, idx: usize, stripped_flag: []const u8) Flag {
        // Reset counter used for handling combined options.
        self.counter = 0;
        // Case 1: when it is an option that doesn't have any arguments but it is in the end of `self.args`.
        if (idx == self.args.len - 1) {
            self.args = self.args[idx + 1 ..];
            return Flag.flag(stripped_flag);
        }

        // Case 2: when it is an option that has arguments and it isn't in the end of `self.args`.
        // It is now safe to access the value i.e arguments of the flag because of a guard placed above.
        const value = self.args[idx + 1];
        if (!isOption(value)) {
            self.args = self.args[idx + 1 ..];
            return Flag.pairs(stripped_flag, value);
        }

        // Case 3: when the argument position of a flag is another flag.
        self.args = self.args[idx + 1 ..];
        return Flag.flag(stripped_flag);
    }

    // Helper fucntion to catch unrecoverable errors (panics).
    fn err_catch(comptime msg: []const u8, err: anyerror) noreturn {
        std.debug.panic(msg ++ "{s}", .{@errorName(err)});
    }

    // Helper function to check how valid an option's argument.
    fn isOption(str: []const u8) bool {
        return isLongOption(str) or isShortOption(str);
    }

    // Check for long flags/options. It is considered to be when
    // it has `--` prefix and it has at least 2 characters after the prefix.
    fn isLongOption(str: []const u8) bool {
        return std.mem.startsWith(u8, str, "--") and str.len >= 4;
    }

    // Check for short flags/options. It is considered to be when
    // it has `-` prefix and it has at least 1 characters after the prefix.
    fn isShortOption(str: []const u8) bool {
        return std.mem.startsWith(u8, str, "-") and str.len >= 2;
    }
};
