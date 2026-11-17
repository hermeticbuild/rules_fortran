"""Explicitly declare execution/target Fortran toolchain pairs."""

load(":fortran_toolchain.bzl", "fortran_toolchain")

# This macro declares multiple independently named pairs, as agreed by its API.
# buildifier: disable=unnamed-macro
def declare_toolchains(toolchains):
    """Declare one Fortran toolchain and Bazel registration per pair.

    Args:
        toolchains: List of dictionaries with name, compiler_kind, compiler,
            intrinsic_modules, runtime, exec_compatible_with, and
            target_compatible_with entries.
    """
    for pair in toolchains:
        name = pair["name"]
        fortran_toolchain(
            name = name,
            compiler_kind = pair["compiler_kind"],
            compiler = pair["compiler"],
            intrinsic_modules = pair["intrinsic_modules"],
            runtime = pair["runtime"],
        )
        native.toolchain(
            name = name + "_registration",
            toolchain = ":" + name,
            toolchain_type = Label("//fortran:toolchain_type"),
            exec_compatible_with = pair["exec_compatible_with"],
            target_compatible_with = pair["target_compatible_with"],
        )
