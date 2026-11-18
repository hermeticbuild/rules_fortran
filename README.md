# rules_fortran

Fortran rules that use a registered compiler for compilation and Bazel's selected
C/C++ toolchain for native archives and final links. The integration module
uses the published Flang compiler to build Linux musl executables for x86_64
and Arm64. GNU Fortran is planned in a later gate.

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

Each source has its own PIC object and module-output tree. A library merges its
source module files into one declared tree for dependents. A source using a
module from another source needs a `deps` edge to that source's target, so the
merged tree is a declared compile input. Independent sources may share a
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
    target_flags = select({
        "@llvm//platforms/config:linux_x86_64_musl": ["--target=x86_64-linux-musl"],
    }),
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
modules and runtime are target configured. The Flang adapter uses target flags
from the selected Fortran toolchain. This integration computes
`--target` from platform constraints with `select()`; production ruleset code
contains no `@llvm` labels. It does not read a deprecated GNU system-name
field. Other Flang target pairs require their own qualified compiler, modules,
runtime, and selected target flags.

The integration module pins a Hermetic LLVM revision that indexes the LLVM
23.1.6 release. The default bootstrap stage downloads the host Flang
executable. The integration Bazelrc sets
`--repo_env=HERMETIC_LLVM_INCLUDE_FLANG=1` so Hermetic LLVM can build target
intrinsic modules and Flang-RT from matching sources.

## Integration CI

Each Linux, macOS, and Windows runner builds the integration suite for both
Linux x86_64 musl and Linux Arm64 musl. The Linux runners also execute the
tests for their own CPU. CI checks the selected Flang archive, compiler
target flag, Hermetic LLVM linker inputs, and ELF architecture of a linked
module consumer. Builds run locally on each runner.

From `tests/integration`, run a cross build with the pinned Bazel version:

```sh
bazelisk build //... --platforms=@llvm//platforms:linux_aarch64_musl
```

On an Arm64 Linux host, add
`--host_platform=@llvm//platforms:linux_aarch64_musl` to build the module
merge tool with static musl. Use `test` in place of `build` to run the matching
target. On x86_64 Linux, use `linux_x86_64_musl` for the host platform.

## Current boundaries

- The integration suite covers static archives and executables targeting
  Linux musl. Other target ABIs require their own qualification.
- Libraries compile PIC objects only. Separate PIC and non-PIC outputs remain
  a later design decision.
- Cross-target module-name collision and arbitrary compiler/module-format
  mismatch checks are deferred. The source graph must express inter-target
  module use. Duplicate module filenames within one library fail at merge.
- GNU Fortran, shared libraries, Flang-driven linking, OpenMP, coarrays, MPI,
  coverage, sanitizers, and Fortran ThinLTO are not implemented.
- Path mapping is advertised for Fortran compile actions. File arguments and
  dependency module trees use Bazel `Args` and `File` values. CC archive and
  link action mapping follows the selected CC toolchain. User supplied
  `copts` containing literal output paths are outside this guarantee.
- `fastbuild` uses `-O0`, `dbg` uses `-O0 -g`, and `opt` uses `-O2` for Flang
  compilation. User `copts` follow the mode defaults. Bazel coverage requests
  fail during analysis until the ruleset supports Fortran instrumentation.
