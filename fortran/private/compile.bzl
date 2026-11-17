"""Declared one-source Fortran compilation actions."""

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load(":flang.bzl", "add_compile_arguments")
load(":modules.bzl", "dependency_modules", "propagated_defines")

_RESERVED_COPTS = [
    "-o",
    "-module-dir",
    "-fintrinsic-modules-path",
    "--target",
    "-target",
    "-fno-pic",
    "-fno-PIC",
]

_UNSUPPORTED_COPTS = [
    "-flto",
    "-fopenmp",
    "-fsanitize",
    "-fcoarray",
]

_UNSUPPORTED_FEATURES = [
    "asan",
    "coverage",
    "fdo_instrument",
    "fdo_optimize",
    "openmp",
    "thin_lto",
    "tsan",
    "ubsan",
]

def _check_options(ctx):
    if ctx.configuration.coverage_enabled:
        fail("Fortran compilation does not support coverage yet")
    for feature in ctx.features:
        if feature in _UNSUPPORTED_FEATURES:
            fail("Fortran compilation does not support feature '{}' yet".format(feature))
    for option in ctx.attr.copts:
        for prefix in _RESERVED_COPTS:
            if option == prefix or option.startswith(prefix + "=") or (prefix == "-o" and option.startswith("-o")):
                fail("copts cannot override compiler-owned option '{}'".format(prefix))
        for prefix in _UNSUPPORTED_COPTS:
            if option.startswith(prefix):
                fail("Fortran compilation does not support '{}' yet".format(prefix))

def compile_sources(ctx, toolchain):
    """Compile each source to a PIC object and module-output tree.

    Args:
        ctx: Rule analysis context.
        toolchain: Resolved FortranToolchainInfo.

    Returns:
        A struct with compilation_outputs, objects, and module_dirs.
    """
    if toolchain.compiler_kind != "flang":
        fail("Compiler adapter '{}' is not implemented yet".format(toolchain.compiler_kind))
    _check_options(ctx)

    dep_module_dirs = dependency_modules(ctx.attr.deps)
    defines = propagated_defines(ctx.attr.deps)

    objects = []
    module_dirs = []
    for index, src in enumerate(ctx.files.srcs):
        obj = ctx.actions.declare_file("{}_objects/{}.o".format(ctx.label.name, index))
        module_dir = ctx.actions.declare_directory("{}_modules/{}".format(ctx.label.name, index))
        args = ctx.actions.args()
        add_compile_arguments(args, ctx, src, obj, module_dir, toolchain.intrinsic_modules, dep_module_dirs, defines)
        inputs = depset(
            direct = [toolchain.intrinsic_modules, src] + ctx.files.additional_compiler_inputs,
            transitive = [dep_module_dirs],
        )
        ctx.actions.run(
            executable = toolchain.compiler,
            arguments = [args],
            inputs = inputs,
            tools = [toolchain.compiler],
            outputs = [obj, module_dir],
            mnemonic = "FortranCompile",
            progress_message = "Compiling Fortran {}".format(src.short_path),
            execution_requirements = {"supports-path-mapping": "1"},
        )
        objects.append(obj)
        module_dirs.append(module_dir)

    outputs = cc_common.create_compilation_outputs(
        objects = depset(objects),
        pic_objects = depset(objects),
    )
    return struct(compilation_outputs = outputs, objects = objects, module_dirs = module_dirs)
