const std = @import("std");

pub fn build(b: *std.Build) void {
    const arch = b.option(std.Target.Cpu.Arch, "arch", "The target kernel arch") orelse .x86_64;
    const linker_path: std.Build.LazyPath = b.path(b.fmt("src/arch/{s}/linker.ld", .{@tagName(arch)}));
    const code_model: std.builtin.CodeModel = .kernel;

    var target_query: std.Target.Query = .{
        .cpu_arch = arch,
        .os_tag = .freestanding,
        .abi = .none,
    };

    switch (arch) {
        .x86_64 => {
            const Feature = std.Target.x86.Feature;
            target_query.cpu_features_add.addFeature(@intFromEnum(Feature.soft_float));
            target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.mmx));
            target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.sse));
            target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.sse2));
            target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.avx));
            target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.avx2));
        },
        else => std.debug.panic("Unsupported kernel arch: {s}", .{@tagName(arch)}),
    }

    const target = b.resolveTargetQuery(target_query);
    const optimize = b.standardOptimizeOption(.{});
    const limine = b.dependency("limine", .{});

    const kernel = b.addExecutable(.{
        .name = "kurisu.kernel",
        .root_source_file = b.path("src/entry.zig"),
        .target = target,
        .optimize = optimize,
        .code_model = code_model,
    });
    kernel.want_lto = false;
    kernel.root_module.addImport("limine", limine.module("limine"));
    kernel.setLinkerScriptPath(linker_path);
    b.installArtifact(kernel);

    const check_step = b.step("check", "zls check step");
    check_step.dependOn(&kernel.step);
}
