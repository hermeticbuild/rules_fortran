"""Provider for compiler-readable Fortran interfaces."""

FortranInfo = provider(
    doc = "Fortran module inputs and propagated preprocessor definitions.",
    fields = {
        "module_dirs": "Depset of module-output directory tree artifacts.",
        "defines": "Depset of propagated preprocessor definitions.",
    },
)
