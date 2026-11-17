"""Shared implementation of Fortran binaries and Bazel tests."""

load(":compile.bzl", "compile_sources")
load(":link.bzl", "executable_link")
load(":runfiles.bzl", "rule_runfiles")

def fortran_executable_impl(ctx):
    """Compile a Fortran main and link it with the selected CC toolchain.

    Args:
        ctx: Rule analysis context.

    Returns:
        A list containing the executable's DefaultInfo.
    """
    if not ctx.files.srcs:
        fail("Fortran binary/test requires at least one source")
    toolchain = ctx.toolchains["//fortran:toolchain_type"].fortran
    compiled = compile_sources(ctx, toolchain)
    executable = executable_link(ctx, compiled.compilation_outputs, toolchain)
    return [DefaultInfo(
        executable = executable,
        files = depset([executable]),
        runfiles = rule_runfiles(ctx),
    )]
