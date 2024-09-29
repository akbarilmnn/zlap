const std = @import("std");
const Allocator = std.mem.Allocator;
// Iterate over CLI to find flags (options).
pub const FlagIterator = struct {
    const Self = @This();
    args: []const []const u8,
    allocator: ?Allocator = null,
    counter: usize = 0,

    // struct representation of an option that may have a value.
    const Flag = struct {
        flag: []const u8,
        value: ?[]const u8 = null,

        fn flag(name: []const u8) Flag {
            return Flag{
                .flag = name,
            };
        }

        fn pairs(key: []const u8, value: []const u8) Flag {
            return Flag{
                .flag = key,
                .value = value,
            };
        }
    };

    pub fn init(allocator: Allocator) Self {
        const args: []const []const u8 = std.process.argsAlloc(allocator) catch |err|
            catcher("ERROR: out of memory!", err);
        return Self{
            .args = args,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.allocator) |allocator| {
            std.process.argsFree(allocator, @ptrCast(self.args));
        }
    }

    pub fn init_with_args(args: []const []const u8) Self {
        return Self{
            .args = @ptrCast(args),
            .allocator = null,
        };
    }

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
        const optname = self.args[idx];
        // strip `--` prefix
        const stripped = optname[2..];
        if (idx == self.args.len - 1) {
            self.args = self.args[idx + 1 ..];
            return Flag.flag(stripped);
        }

        const value = self.args[idx + 1];

        if (!isOption(value)) {
            self.args = self.args[idx + 1 ..];
            return Flag.pairs(stripped, value);
        }

        self.args = self.args[idx + 1 ..];
        return Flag.flag(stripped);
    }

    fn handleShortOption(self: *Self, idx: usize) Flag {
        // can either be single (e.g: -t) or combined (e.g: -xvf or -xvf 10).
        const optname = self.args[idx];
        // strip `-` prefix
        const stripped = optname[1..];

        // for the combined case we want to transform it into (e.g: -x -v -f or -x -v -f 10).
        if (stripped.len == 0) {
            self.args = self.args[idx + 1 ..];
            self.counter = 0;
            return Flag.flag("-");
        }

        if (stripped.len == 1) {
            if (idx == self.args.len - 1) {
                self.args = self.args[idx + 1 ..];
                self.counter = 0;
                return Flag.flag(stripped);
            }

            const value = self.args[idx + 1];

            if (!isOption(value)) {
                self.args = self.args[idx + 1 ..];
                self.counter = 0;
                return Flag.pairs(stripped, value);
            }

            self.args = self.args[idx + 1 ..];
            self.counter = 0;
            return Flag.flag(stripped);
        }

        for (stripped) |_| {
            // start and middle part of combined flag.
            const flag = stripped[self.counter .. self.counter + 1];
            if (self.counter != stripped.len - 1) {
                self.counter += 1;
                return Flag.flag(flag);
            }
            // end part of combined flag.
            if (idx == self.args.len - 1) {
                self.args = self.args[idx + 1 ..];
                self.counter = 0;
                return Flag.flag(flag);
            }

            const value = self.args[idx + 1];

            if (!isOption(value)) {
                self.args = self.args[idx + 1 ..];
                self.counter = 0;
                return Flag.pairs(flag, value);
            }

            self.args = self.args[idx + 1 ..];
            self.counter = 0;
            return Flag.flag(flag);
        }
        unreachable;
    }

    fn catcher(comptime msg: []const u8, err: anyerror) noreturn {
        std.debug.panic(msg ++ "{s}", .{@errorName(err)});
    }

    fn isOption(str: []const u8) bool {
        return isLongOption(str) or isShortOption(str);
    }

    fn isLongOption(str: []const u8) bool {
        return std.mem.startsWith(u8, str, "--") and str.len >= 4;
    }

    fn isShortOption(str: []const u8) bool {
        return std.mem.startsWith(u8, str, "-") and str.len >= 2;
    }
};
