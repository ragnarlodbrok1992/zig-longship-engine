const std = @import("std");
const Sdk = @import("libs/SDL.zig/Sdk.zig");
const freetype = @import("libs/mach-freetype/build.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const sdk = Sdk.init(b);
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zig-longship-engine", "src/main.zig");

    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackage(sdk.getNativePackage("sdl2"));
    sdk.link(exe, .dynamic);

    exe.addPackage(freetype.pkg);
    freetype.link(b, exe, .{});

    exe.addPackage(freetype.harfbuzz_pkg);
    freetype.link(b, exe, .{ .harfbuzz = .{} });

    exe.addIncludePath("libs/x86_64-windows-gnu/include/SDL2");
    exe.addLibraryPath("libs/x86_64-windows-gnu/lib");
    exe.addLibraryPath("libs/x86_64-windows-gnu/bin");
    exe.linkSystemLibraryName("SDL2_ttf");
    exe.linkSystemLibraryName("SDL2_image");

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
