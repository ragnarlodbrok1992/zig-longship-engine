const std = @import("std");
const Sdk = @import("libs/SDL.zig/Sdk.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const sdk = Sdk.init(b);
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zig-longship-engine", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    sdk.link(exe, .dynamic);
    exe.addPackage(sdk.getNativePackage("sdl2"));
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
