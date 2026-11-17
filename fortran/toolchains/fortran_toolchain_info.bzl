"""The compiler, target modules, and target runtime of a Fortran toolchain."""

FortranToolchainInfo = provider(
    doc = "Inputs required to compile Fortran and link its native objects.",
    fields = {
        "compiler": "Execution-platform FilesToRunProvider for the Fortran compiler.",
        "compiler_kind": "Compiler adapter name: flang or gfortran.",
        "intrinsic_modules": "Target-configured intrinsic-module directory tree artifact.",
        "runtime": "Target-configured CcInfo for the Fortran runtime.",
    },
)
