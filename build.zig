// const std = @import("std");
// const builtin = @import("builtin");
// pub fn build(b: *std.Build) !void {
//     const optimize = b.standardOptimizeOption(.{});
//     const target = b.standardTargetOptions(.{});

//     const pdx_file_name = "roguelike.pdx";

//     const ecs_mod = b.addModule("ecs", .{ .root_source_file = .{ .path = "../zig-ecs/src/ecs.zig" }, .imports = &.{} });

//     const lib = b.addSharedLibrary(.{
//         .name = "pdex",
//         .root_source_file = .{ .path = "src/main.zig" },
//         .optimize = optimize,
//         .target = target,
//     });

//     lib.root_module.addImport("ecs", ecs_mod);

//     const output_path = "Source";
//     const lib_step = b.addInstallArtifact(lib, .{});
//     lib_step.dest_dir = .{ .custom = output_path };

//     const playdate_query = try std.zig.CrossTarget.parse(.{
//         .arch_os_abi = "thumb-freestanding-eabihf",
//         .cpu_features = "cortex_m7-fp64-fp_armv8d16-fpregs64-vfp2-vfp3d16-vfp4d16",
//     });
//     const pd_target = b.resolveTargetQuery(playdate_query);
//     const game_elf = b.addExecutable(.{ .name = "pdex.elf", .root_source_file = .{ .path = "src/main.zig" }, .target = pd_target, .optimize = optimize });
//     game_elf.root_module.addImport("ecs", ecs_mod);

//     game_elf.step.dependOn(&lib_step.step);
//     // game_elf.pie = true;
//     game_elf.root_module.pic = true;
//     game_elf.link_emit_relocs = true;
//     game_elf.setLinkerScriptPath(.{ .path = "link_map.ld" });
//     const game_elf_step = b.addInstallArtifact(game_elf, .{});
//     game_elf_step.dest_dir = .{ .custom = output_path };
//     if (optimize == .ReleaseFast) {
//         game_elf.root_module.omit_frame_pointer = true;
//     }

//     const playdate_sdk_path = try std.process.getEnvVarOwned(b.allocator, "PLAYDATE_SDK_PATH");

//     var previous_step = &game_elf_step.step;
//     if (remove_lib_prefix_step(b)) |step| {
//         step.step.dependOn(&game_elf_step.step);
//         previous_step = &step.step;
//     }

//     // Install Step
//     const copy_assets = b.addSystemCommand(&.{ "cp", "assets/playdate_image.png", "assets/pdxinfo", "assets/icon.png", "assets/tilemap-table-16-16.png", "assets/inv.png", "zig-out/Source" });
//     copy_assets.step.dependOn(previous_step);
//     const pdc_path = try std.fmt.allocPrint(b.allocator, "{s}/bin/pdc{s}", .{
//         playdate_sdk_path,
//         if (builtin.target.os.tag == .windows) ".exe" else "",
//     });
//     const pdc = b.addSystemCommand(&.{ pdc_path, "zig-out/Source", "zig-out/" ++ pdx_file_name }); // "--skip-unknown",
//     pdc.step.dependOn(&copy_assets.step);
//     b.getInstallStep().dependOn(&pdc.step);

//     // Run Step
//     const run_cmd = b: {
//         switch (builtin.target.os.tag) {
//             .windows => {
//                 const pd_simulator_path = try std.fmt.allocPrint(b.allocator, "{s}/bin/PlaydateSimulator.exe", .{playdate_sdk_path});
//                 break :b b.addSystemCommand(&.{ pd_simulator_path, "zig-out/" ++ pdx_file_name });
//             },
//             .macos => {
//                 break :b b.addSystemCommand(&.{ "open", "zig-out/" ++ pdx_file_name });
//             },
//             .linux => {
//                 const pd_simulator_path = try std.fmt.allocPrint(b.allocator, "{s}/bin/PlaydateSimulator", .{playdate_sdk_path});
//                 break :b b.addSystemCommand(&.{ pd_simulator_path, "zig-out/" ++ pdx_file_name });
//             },
//             else => {
//                 @panic("Unsupported OS!");
//             },
//         }
//     };
//     run_cmd.step.dependOn(&pdc.step);
//     const run_step = b.step("run", "Run the app");
//     run_step.dependOn(&run_cmd.step);

//     //clean step
//     {
//         const clean_step = b.step("clean", "Clean all artifacts");
//         const rm_zig_cache = b.addRemoveDirTree("zig-cache");
//         clean_step.dependOn(&rm_zig_cache.step);
//         const rm_zig_out = b.addRemoveDirTree("zig-out");
//         clean_step.dependOn(&rm_zig_out.step);
//     }
// }

// fn remove_lib_prefix_step(b: *std.Build) ?*std.Build.Step.Run {
//     const extension = if (builtin.target.os.tag == .macos) "dylib" else "so";
//     return switch (builtin.target.os.tag) {
//         .macos, .linux => b.addSystemCommand(&.{ "mv", "zig-out/Source/libpdex." ++ extension, "zig-out/Source/pdex." ++ extension }),
//         else => null,
//     };
// }

const std = @import("std");

const os_tag = @import("builtin").os.tag;
const name = "roguelike";
pub fn build(b: *std.Build) !void {
    const pdx_file_name = name ++ ".pdx";
    const optimize = b.standardOptimizeOption(.{});

    const writer = b.addWriteFiles();
    const source_dir = writer.getDirectory();
    writer.step.name = "write source directory";

    const lib = b.addSharedLibrary(.{
        .name = "pdex",
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = optimize,
        .target = b.host,
    });
    const ecs_mod = b.addModule("ecs", .{ .root_source_file = .{ .path = "../zig-ecs/src/ecs.zig" }, .imports = &.{} });
    lib.root_module.addImport("ecs", ecs_mod);

    _ = writer.addCopyFile(lib.getEmittedBin(), "pdex" ++ switch (os_tag) {
        .windows => ".dll",
        .macos => ".dylib",
        .linux => ".so",
        else => @panic("Unsupported OS"),
    });

    const playdate_target = b.resolveTargetQuery(try std.zig.CrossTarget.parse(.{
        .arch_os_abi = "thumb-freestanding-eabihf",
        .cpu_features = "cortex_m7-fp64-fp_armv8d16-fpregs64-vfp2-vfp3d16-vfp4d16",
    }));
    const elf = b.addExecutable(.{
        .name = "pdex.elf",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = playdate_target,
        .optimize = optimize,
        .pic = true,
    });
    elf.link_emit_relocs = true;
    elf.entry = .{ .symbol_name = "eventHandler" };
    elf.root_module.addImport("ecs", ecs_mod);

    elf.setLinkerScriptPath(.{ .path = "link_map.ld" });
    if (optimize == .ReleaseFast) {
        elf.root_module.omit_frame_pointer = true;
    }
    _ = writer.addCopyFile(elf.getEmittedBin(), "pdex.elf");

    try addCopyDirectory(writer, "assets", ".");

    const playdate_sdk_path = try std.process.getEnvVarOwned(b.allocator, "PLAYDATE_SDK_PATH");
    const pdc_path = b.pathJoin(&.{ playdate_sdk_path, "bin", if (os_tag == .windows) "pdc.exe" else "pdc" });
    const pd_simulator_path = switch (os_tag) {
        .linux => b.pathJoin(&.{ playdate_sdk_path, "bin", "PlaydateSimulator" }),
        .macos => "open", // `open` focuses the window, while running the simulator directry doesn't.
        .windows => b.pathJoin(&.{ playdate_sdk_path, "bin", "PlaydateSimulator.exe" }),
        else => @panic("Unsupported OS"),
    };

    const pdc = b.addSystemCommand(&.{pdc_path});
    pdc.addDirectorySourceArg(source_dir);
    pdc.setName("pdc");
    const pdx = pdc.addOutputFileArg(pdx_file_name);

    b.installDirectory(.{
        .source_dir = pdx,
        .install_dir = .prefix,
        .install_subdir = pdx_file_name,
    });

    const run_cmd = b.addSystemCommand(&.{pd_simulator_path});
    run_cmd.addDirectorySourceArg(pdx);
    run_cmd.setName("PlaydateSimulator");
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    run_step.dependOn(b.getInstallStep());

    const clean_step = b.step("clean", "Clean all artifacts");
    clean_step.dependOn(b.getUninstallStep());
    clean_step.dependOn(&b.addRemoveDirTree("zig-cache").step);
    clean_step.dependOn(&b.addRemoveDirTree("zig-out").step);
}

pub fn addCopyDirectory(
    wf: *std.Build.Step.WriteFile,
    src_path: []const u8,
    dest_path: []const u8,
) !void {
    const b = wf.step.owner;
    var dir = try b.build_root.handle.openDir(src_path, .{ .iterate = true });
    defer dir.close();
    var it = dir.iterate();
    while (try it.next()) |entry| {
        const new_src_path = b.pathJoin(&.{ src_path, entry.name });
        const new_dest_path = b.pathJoin(&.{ dest_path, entry.name });
        const new_src = .{ .path = new_src_path };
        switch (entry.kind) {
            .file => {
                _ = wf.addCopyFile(new_src, new_dest_path);
            },
            .directory => {
                try addCopyDirectory(
                    wf,
                    new_src_path,
                    new_dest_path,
                );
            },
            //TODO: possible support for sym links?
            else => {},
        }
    }
}
