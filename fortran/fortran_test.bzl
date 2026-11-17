"""Bazel tests compiled from Fortran programs."""

load("//fortran/private:attrs.bzl", "COMMON_ATTRS")
load("//fortran/private:executable.bzl", "fortran_executable_impl")

def _fortran_test_impl(ctx):
    return fortran_executable_impl(ctx) + [RunEnvironmentInfo(environment = ctx.attr.env)]

fortran_test = rule(
    implementation = _fortran_test_impl,
    doc = "Compile and run a Fortran program as a Bazel test.",
    attrs = COMMON_ATTRS | {
        "env": attr.string_dict(doc = "Environment variables supplied to the test process."),
    },
    test = True,
    toolchains = ["//fortran:toolchain_type", "@rules_cc//cc:toolchain_type"],
    fragments = ["cpp"],
)
