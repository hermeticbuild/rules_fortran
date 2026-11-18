"""Fortran executables linked by the selected CC toolchain."""

load("@rules_cc//cc:find_cc_toolchain.bzl", "use_cc_toolchain")
load("//fortran/private:attrs.bzl", "COMMON_ATTRS")
load("//fortran/private:executable.bzl", "fortran_executable_impl")

fortran_binary = rule(
    implementation = fortran_executable_impl,
    doc = "Compile a Fortran program and link a native executable.",
    attrs = COMMON_ATTRS,
    executable = True,
    toolchains = ["//fortran:toolchain_type"] + use_cc_toolchain(),
    fragments = ["cpp"],
)
