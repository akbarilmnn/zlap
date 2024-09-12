const std = @import("std");

pub fn build(b: *std.Build) void {
    const build_target = b.standardTargetOptions(.{});
    const optimization_target = b.standardOptimizeOption(.{});

    // do test for now. compile a library later.
    const tests = b.addTest(.{
        .name = "unit tests",
        .target = build_target,
        .optimize = optimization_target,
        .root_source_file = b.path("src/unit_tests.zig"),
    });

    const runner_tests = b.addRunArtifact(tests);

    const run_step = b.step("t", "run all unit tests in unit_tests.zig");
    run_step.dependOn(&runner_tests.step);
}
