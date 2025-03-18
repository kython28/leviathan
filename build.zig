const std = @import("std");

fn create_build_step(
    b: *std.Build,
    name: []const u8,
    path: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    single_threaded: bool,
    modules_name: []const []const u8,
    modules: []const *std.Build.Module,
    comptime emit_bin: bool,
    step: *std.Build.Step
) void {
    const lib = b.addSharedLibrary(.{
        .name = name,
        .optimize = optimize,
        .target = target,
        .root_source_file = b.path(path),
        .single_threaded = single_threaded,
    });

    lib.linkLibC();
    for (modules_name, modules) |module_name, module| {
        lib.root_module.addImport(module_name, module);
    }

    if (emit_bin) {
        const compile_python_lib = b.addInstallArtifact(lib, .{});
        step.dependOn(&compile_python_lib.step);
    }else{
        step.dependOn(&lib.step);
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    if (target.result.os.tag != .linux) {
        @panic("Only Linux is supported");
    }else if (target.result.os.isAtLeast(.linux, .{ .major = 5, .minor = 11, .patch = 0 })) |_is_at_least| {
        if (!_is_at_least) {
            @panic("Only Linux >= 5.1.0 is supported");
        }
    }else{
        @panic("Not able to detect Linux version");
    }

    const python_include_dir = b.option([]const u8, "python-include-dir", "Path to python include directory")
        orelse "/usr/include/python3.13";

    const python_lib_dir = b.option([]const u8, "python-lib-dir", "Path to python library directory");

    const python_lib= b.option([]const u8, "python-lib", "Name of the python library")
        orelse "/usr/lib/libpython3.13.so";

    const python_is_gil_disabled = b.option(bool, "python-gil-disabled", "Is GIL disabled")
        orelse false;

    const jdz_allocator = b.dependency("jdz_allocator", .{
        .target = target,
        .optimize = optimize
    });
    const jdz_allocator_module = jdz_allocator.module("jdz_allocator");

    const python_c_module = b.addModule("python_c", .{
        .root_source_file = b.path("src/python_c.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true
    });

    python_c_module.addIncludePath(.{
        .cwd_relative = python_include_dir
    });

    if (python_lib_dir) |dir| {
        python_c_module.addLibraryPath(.{
            .cwd_relative = dir
        });
    }

    python_c_module.addObjectFile(.{
        .cwd_relative = python_lib
    });

    const utils_module = b.addModule("python_c", .{
        .root_source_file = b.path("src/utils/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true
    });
    utils_module.addImport("python_c", python_c_module);
    utils_module.addImport("jdz_allocator", jdz_allocator_module);

    const callback_manager_module = b.addModule("callback_manager", .{
        .root_source_file = b.path("src/callback_manager.zig"),
        .target = target,
        .optimize = optimize,
    });
    callback_manager_module.addImport("python_c", python_c_module);
    callback_manager_module.addImport("utils", utils_module);

    const leviathan_module = b.addModule("leviathan", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize
    });
    leviathan_module.addImport("python_c", python_c_module);
    leviathan_module.addImport("utils", utils_module);
    leviathan_module.addImport("callback_manager", callback_manager_module);

    const modules_name = .{ "leviathan", "python_c", "jdz_allocator", "utils" };
    const modules = .{ leviathan_module, python_c_module, jdz_allocator_module, utils_module };
    const install_step = b.getInstallStep();

    create_build_step(
        b, "leviathan", "src/lib.zig", target, optimize, !python_is_gil_disabled,
        &modules_name, &modules, true, install_step
    );

    const check_step = b.step("check", "Run checking for ZLS");
    create_build_step(
        b, "leviathan", "src/lib.zig", target, optimize, true,
        &modules_name, &modules, false, check_step
    );

    const leviathan_module_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .single_threaded = !python_is_gil_disabled
    });
    leviathan_module_unit_tests.root_module.addImport("callback_manager", callback_manager_module);
    leviathan_module_unit_tests.root_module.addImport("python_c", python_c_module);
    leviathan_module_unit_tests.root_module.addImport("utils", utils_module);

    const utils_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/utils/main.zig"),
        .target = target,
        .optimize = optimize,
        .single_threaded = !python_is_gil_disabled
    });
    utils_unit_tests.root_module.addImport("python_c", python_c_module);
    utils_unit_tests.root_module.addImport("utils", utils_module);

    const callback_manager_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/callback_manager.zig"),
        .target = target,
        .optimize = optimize,
        .single_threaded = !python_is_gil_disabled
    });
    callback_manager_unit_tests.root_module.addImport("python_c", python_c_module);
    callback_manager_unit_tests.root_module.addImport("utils", utils_module);

    const run_leviathan_module_unit_tests = b.addRunArtifact(leviathan_module_unit_tests);
    const run_callback_manager_unit_tests = b.addRunArtifact(callback_manager_unit_tests);
    const run_utils_unit_tests = b.addRunArtifact(utils_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_leviathan_module_unit_tests.step);
    test_step.dependOn(&run_callback_manager_unit_tests.step);
    test_step.dependOn(&run_utils_unit_tests.step);

    check_step.dependOn(&run_leviathan_module_unit_tests.step);
    check_step.dependOn(&run_callback_manager_unit_tests.step);
    check_step.dependOn(&run_utils_unit_tests.step);
}
