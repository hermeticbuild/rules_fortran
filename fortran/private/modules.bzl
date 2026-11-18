"""Propagate Fortran modules and preprocessor definitions."""

load("//fortran/common:fortran_info.bzl", "FortranInfo")

def dependency_modules(deps):
    """Return a lazy depset of module trees in dependency-first search order."""
    return depset(
        transitive = [dep[FortranInfo].module_dirs for dep in deps if FortranInfo in dep],
        order = "preorder",
    )

def propagated_defines(deps):
    """Return preprocessor definitions from Fortran dependencies."""
    return depset(
        transitive = [dep[FortranInfo].defines for dep in deps if FortranInfo in dep],
    )

def fortran_info(ctx, own_module_dirs):
    """Build the compile-facing provider for a Fortran target."""
    return FortranInfo(
        module_dirs = depset(
            direct = own_module_dirs,
            transitive = [dep[FortranInfo].module_dirs for dep in ctx.attr.deps if FortranInfo in dep],
            order = "preorder",
        ),
        defines = depset(
            direct = ctx.attr.defines,
            transitive = [propagated_defines(ctx.attr.deps)],
        ),
    )
