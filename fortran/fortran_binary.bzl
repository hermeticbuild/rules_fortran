"""Fortran executables linked by the selected CC toolchain."""

load("//fortran/private:attrs.bzl", "COMMON_ATTRS")
load("//fortran/private:executable.bzl", "fortran_executable_impl")

fortran_binary = rule(
    implementation = fortran_executable_impl,
    doc = "Compile a Fortran program and link a native executable.",
    attrs = COMMON_ATTRS,
    executable = True,
    toolchains = ["//fortran:toolchain_type", "@rules_cc//cc:toolchain_type"],
    fragments = ["cpp"],
)
