"""Flang compilation options from the selected Fortran toolchain."""

def add_compile_arguments(args, ctx, src, obj, module_dir, intrinsic_modules, target_flags, dep_module_dirs, propagated_defines, pic):
    """Add Flang target, module, and source options to an action Args.

    Args:
        args: Mutable Bazel Args for the compile action.
        ctx: Rule analysis context.
        src: Fortran source File.
        obj: Declared object File.
        module_dir: Declared module directory tree.
        intrinsic_modules: Target intrinsic module directory tree.
        target_flags: Compiler target flags selected by the toolchain.
        dep_module_dirs: Lazy depset of dependency module trees.
        propagated_defines: Lazy depset of propagated definitions.
        pic: Whether to request position-independent code.
    """
    args.add_all(target_flags)
    if pic:
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

    # Flang reopens hashed intrinsic dependencies using their located relative
    # path. Keep "." after the module directory so that path remains readable.
    args.add("-fintrinsic-modules-path=.")
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
