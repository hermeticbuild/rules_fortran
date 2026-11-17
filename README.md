# rules_fortran

Fortran rules that use a registered compiler for compilation and Bazel's selected
C/C++ toolchain for native archives and final links. This repository currently
implements the Flang path for a Linux x86_64 execution platform and a Linux
x86_64 musl target. GNU Fortran is planned in a later gate.

The [gate 4 evidence](docs/gate-4-evidence.md) records the qualified source
build, action inspection, and remaining limits.

## Public rules and providers

Load rules individually:

```starlark
load("@rules_fortran//fortran:fortran_library.bzl", "fortran_library")
load("@rules_fortran//fortran:fortran_binary.bzl", "fortran_binary")
load("@rules_fortran//fortran:fortran_test.bzl", "fortran_test")
```

`fortran_library` returns `FortranInfo` and `CcInfo`. `FortranInfo.module_dirs`
is a depset of compiler-readable module directory artifacts;
`FortranInfo.defines` propagates preprocessor definitions. `CcInfo` contains
the archive, native dependencies, and Flang runtime linking context. A C or
C++ rule can depend on a `fortran_library` through an ordinary `cc_library`
wrapper that declares the C header for any `bind(C)` procedures. The ruleset
does not generate C headers.

Each source has its own PIC object and module-output tree. A source using a
module from another source needs a `deps` edge to that source's target, so the
module tree is a declared compile input. Independent sources may share a
library target. Empty `fortran_library` targets merge dependencies without
creating an archive. Final Fortran binaries and tests use `cc_common.link`,
including the CC toolchain's CRT, libc, builtins, sysroot, and linker policy.

## Toolchain registration

The ruleset owns the toolchain type and provider. A consuming repository
declares execution/target pairs explicitly:

```starlark
load("@rules_fortran//fortran/toolchains:fortran_toolchain.bzl", "fortran_toolchain")

fortran_toolchain(
    name = "flang_linux_x86_64_to_linux_x86_64_musl",
    compiler_kind = "flang",
    compiler = "@llvm//tools:flang",
    intrinsic_modules = "@llvm//runtimes/flang:intrinsic_modules",
    runtime = "@llvm//runtimes/flang:runtime",
)

toolchain(
    name = "flang_linux_x86_64_to_linux_x86_64_musl_registration",
    toolchain = ":flang_linux_x86_64_to_linux_x86_64_musl",
    toolchain_type = "@rules_fortran//fortran:toolchain_type",
    exec_compatible_with = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
        "@llvm//constraints/libc:musl",
    ],
)
```

The root module registers that package with
`register_toolchains("//toolchains:all")` and separately registers a compatible
Hermetic LLVM CC toolchain. The compiler is execution configured; intrinsic
modules and runtime are target configured. The Flang adapter derives its LLVM
triple from the selected target constraints. It does not read a deprecated GNU
system-name field or store a manually supplied triple in the toolchain.

The minimal Flang prebuilt release is not yet published. Until it is indexed,
source-bootstrap builds select source-built ThinLTO Flang with
`--@llvm//toolchain:bootstrap_stage=stage1_from_source` and
`--repo_env=HERMETIC_LLVM_INCLUDE_FLANG=1`. The same source opt-in builds
target intrinsic modules and Flang-RT. The integration module in
`tests/integration` can use an unmerged Hermetic LLVM checkout through Bazel's
`--override_module=llvm=<checkout>` flag; no checkout path is stored in this
repository.

## Current boundaries

- Qualified pair: Flang 23.1.2, Linux x86_64 execution, Linux x86_64 musl
  target, static archives and executables.
- Libraries compile PIC objects only. Separate PIC and non-PIC outputs remain
  a later design decision.
- Module-name collision and arbitrary compiler/module-format mismatch checks
  are deferred. The source graph must express inter-target module use.
- GNU Fortran, shared libraries, Flang-driven linking, OpenMP, coarrays, MPI,
  coverage, sanitizers, and Fortran ThinLTO are not implemented.
- Path mapping is advertised for Fortran compile actions. File arguments and
  dependency module trees use Bazel `Args` and `File` values. CC archive and
  link action mapping follows the selected CC toolchain. User supplied
  `copts` containing literal output paths are outside this guarantee.
- `fastbuild` uses `-O0`, `dbg` uses `-O0 -g`, and `opt` uses `-O2` for Flang
  compilation. User `copts` follow the mode defaults. Bazel coverage requests
  fail during analysis until the ruleset supports Fortran instrumentation.
