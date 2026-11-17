"""Shared public attributes."""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

COMMON_ATTRS = {
    "srcs": attr.label_list(
        allow_files = [".f", ".F", ".f90", ".F90"],
        doc = "Fortran sources, including generated sources with supported suffixes.",
    ),
    "deps": attr.label_list(
        providers = [CcInfo],
        doc = "Native and Fortran libraries required by this target.",
    ),
    "copts": attr.string_list(doc = "Compiler options local to this target."),
    "defines": attr.string_list(doc = "Preprocessor definitions propagated to dependents."),
    "local_defines": attr.string_list(doc = "Preprocessor definitions local to this target."),
    "additional_compiler_inputs": attr.label_list(
        allow_files = True,
        doc = "Additional declared compile inputs, such as private include files.",
    ),
    "additional_linker_inputs": attr.label_list(
        allow_files = True,
        doc = "Additional declared native link inputs, such as linker scripts.",
    ),
    "linkopts": attr.string_list(doc = "Native link options propagated by libraries."),
    "data": attr.label_list(
        allow_files = True,
        doc = "Runtime files added to runfiles; never compile inputs.",
    ),
}
