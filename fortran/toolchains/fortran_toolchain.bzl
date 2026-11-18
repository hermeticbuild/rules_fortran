"""Declare a Fortran compiler and its target-side dependencies."""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load(":fortran_toolchain_info.bzl", "FortranToolchainInfo")

def _fortran_toolchain_impl(ctx):
    modules = ctx.file.intrinsic_modules
    if not modules.is_directory:
        fail("intrinsic_modules must provide exactly one directory tree artifact")

    info = FortranToolchainInfo(
        compiler = ctx.attr.compiler[DefaultInfo].files_to_run,
        compiler_kind = ctx.attr.compiler_kind,
        intrinsic_modules = modules,
        runtime = ctx.attr.runtime[CcInfo],
        target_flags = ctx.attr.target_flags,
    )
    return [platform_common.ToolchainInfo(fortran = info)]

fortran_toolchain = rule(
    implementation = _fortran_toolchain_impl,
    doc = "Combines an execution compiler with target modules and runtime.",
    attrs = {
        "compiler": attr.label(
            executable = True,
            allow_single_file = True,
            cfg = "exec",
            mandatory = True,
            doc = "Fortran compiler executable on the execution platform.",
        ),
        "compiler_kind": attr.string(
            mandatory = True,
            values = ["flang", "gfortran"],
            doc = "Compiler adapter selected by the consuming rules.",
        ),
        "intrinsic_modules": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "Target-configured intrinsic module directory.",
        ),
        "runtime": attr.label(
            providers = [CcInfo],
            mandatory = True,
            doc = "Target-configured Fortran runtime linking closure.",
        ),
        "target_flags": attr.string_list(
            doc = "Compiler target options selected for this target platform.",
        ),
    },
)
