"""Flang compilation options for the qualified Hermetic LLVM target pair."""

def target_triple(ctx):
    """Derive the qualified LLVM target triple from platform constraints."""
    if (ctx.target_platform_has_constraint(ctx.attr._linux[platform_common.ConstraintValueInfo]) and
        ctx.target_platform_has_constraint(ctx.attr._x86_64[platform_common.ConstraintValueInfo]) and
        ctx.target_platform_has_constraint(ctx.attr._musl[platform_common.ConstraintValueInfo])):
        return "x86_64-linux-musl"
    fail("Flang currently supports only the Linux x86_64 musl target platform")

def add_compile_arguments(args, ctx, src, obj, module_dir, intrinsic_modules, dep_module_dirs, propagated_defines):
    """Add Flang target, module, and source options to an action Args.

    Args:
        args: Mutable Bazel Args for the compile action.
        ctx: Rule analysis context.
        src: Fortran source File.
        obj: Declared object File.
        module_dir: Declared module directory tree.
        intrinsic_modules: Target intrinsic module directory tree.
        dep_module_dirs: Lazy depset of dependency module trees.
        propagated_defines: Lazy depset of propagated definitions.
    """
    args.add("--target=" + target_triple(ctx))
    args.add("-fPIC")
    compilation_mode = ctx.var["COMPILATION_MODE"]
    if compilation_mode == "dbg":
        args.add_all(["-O0", "-g"])
    elif compilation_mode == "opt":
        args.add("-O2")
    elif compilation_mode == "fastbuild":
        args.add("-O0")
    else:
        fail("Unsupported Fortran compilation mode '{}'".format(compilation_mode))
    args.add_all([intrinsic_modules], format_each = "-fintrinsic-modules-path=%s", expand_directories = False)
    args.add("-module-dir")
    args.add_all([module_dir], expand_directories = False)
    args.add_all([module_dir], before_each = "-I", expand_directories = False)
    args.add_all(dep_module_dirs, before_each = "-I", expand_directories = False)
    if propagated_defines or ctx.attr.defines or ctx.attr.local_defines:
        args.add("-cpp")
        args.add_all(propagated_defines, format_each = "-D%s")
        args.add_all(ctx.attr.defines + ctx.attr.local_defines, format_each = "-D%s")
    args.add_all(ctx.attr.copts)
    args.add("-c")
    args.add(src)
    args.add("-o", obj)
