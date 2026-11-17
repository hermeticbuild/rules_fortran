"""Fortran libraries exporting modules and native CcInfo."""

load("//fortran/private:attrs.bzl", "COMMON_ATTRS")
load("//fortran/private:compile.bzl", "compile_sources")
load("//fortran/private:link.bzl", "library_link")
load("//fortran/private:modules.bzl", "fortran_info")
load("//fortran/private:runfiles.bzl", "rule_runfiles")

def _fortran_library_impl(ctx):
    toolchain = ctx.toolchains["//fortran:toolchain_type"].fortran
    compiled = compile_sources(ctx, toolchain)
    cc_info, archives = library_link(ctx, compiled.compilation_outputs, toolchain)
    return [
        DefaultInfo(
            files = depset(archives + compiled.module_dirs),
            runfiles = rule_runfiles(ctx),
        ),
        fortran_info(ctx, compiled.module_dirs),
        cc_info,
    ]

fortran_library = rule(
    implementation = _fortran_library_impl,
    doc = "Compile a Fortran library, exporting modules and a native archive.",
    attrs = COMMON_ATTRS | {
        "alwayslink": attr.bool(doc = "Retain all objects from this library at final link."),
    },
    toolchains = ["//fortran:toolchain_type", "@rules_cc//cc:toolchain_type"],
    fragments = ["cpp"],
)
