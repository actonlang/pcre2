const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const build_pcre2grep = b.option(bool, "build_pcre2grep", "") orelse false;

    var flags = std.ArrayList([]const u8).init(b.allocator);
    defer flags.deinit();
    flags.append("-std=c99") catch unreachable;
    flags.append("-DHAVE_CONFIG_H") catch unreachable;
    flags.append("-DPCRE2_CODE_UNIT_WIDTH=8") catch unreachable;
    flags.append("-DPCRE2_STATIC") catch unreachable;
    flags.append("-DMAX_VARLOOKBEHIND=255") catch unreachable;

    const copyFiles = b.addWriteFiles();
    copyFiles.addCopyFileToSource(.{ .path = "src/config.h.generic" }, "src/config.h");
    copyFiles.addCopyFileToSource(.{ .path = "src/pcre2.h.generic" }, "src/pcre2.h");
    copyFiles.addCopyFileToSource(.{ .path = "src/pcre2_chartables.c.dist" }, "src/pcre2_chartables.c");

    const lib = b.addStaticLibrary(.{
        .name = "pcre2",
        .target = target,
        .optimize = optimize,
    });
    lib.addIncludePath(.{ .path = "src" });
    lib.addCSourceFiles(.{
        .files = &.{
            "src/pcre2_auto_possess.c",
            "src/pcre2_chkdint.c",
            "src/pcre2_compile.c",
            "src/pcre2_config.c",
            "src/pcre2_context.c",
            "src/pcre2_convert.c",
            "src/pcre2_dfa_match.c",
            "src/pcre2_error.c",
            "src/pcre2_extuni.c",
            "src/pcre2_find_bracket.c",
            "src/pcre2_maketables.c",
            "src/pcre2_match.c",
            "src/pcre2_match_data.c",
            "src/pcre2_newline.c",
            "src/pcre2_ord2utf.c",
            "src/pcre2_pattern_info.c",
            "src/pcre2_script_run.c",
            "src/pcre2_serialize.c",
            "src/pcre2_string_utils.c",
            "src/pcre2_study.c",
            "src/pcre2_substitute.c",
            "src/pcre2_substring.c",
            "src/pcre2_tables.c",
            "src/pcre2_ucd.c",
            "src/pcre2_valid_utf.c",
            "src/pcre2_xclass.c",
            "src/pcre2_chartables.c",
        },
        .flags = flags.items
    });
    lib.step.dependOn(&copyFiles.step);
    // TODO: isn't it nicer to install src/pcre2.h instead, which we "generate"
    // above by copying? However, it doesn't work for some reason, ending up in
    // a racy build that sometimes fails with src/pcre2.h not found.
    lib.installHeader("src/pcre2.h.generic", "pcre2.h");
    lib.linkLibC();
    b.installArtifact(lib);

    if (build_pcre2grep) {
        const exe_pcre2grep = b.addExecutable(.{
            .name = "pcre2grep",
            .target = target,
            .optimize = optimize,
        });
        exe_pcre2grep.addIncludePath(.{ .path = "src" });
        exe_pcre2grep.addCSourceFiles(.{
            .files = &.{
                "src/pcre2grep.c",
            },
            .flags = flags.items
        });
        exe_pcre2grep.linkLibrary(lib);
        exe_pcre2grep.linkLibC();
        b.installArtifact(exe_pcre2grep);
    }
}
