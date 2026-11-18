# Toolchains and integration

## Set up a Bzlmod consumer

This example uses Linux x86_64 with glibc or macOS Arm64. Clone
[`rules_fortran`](https://github.com/hermeticbuild/rules_fortran) next to your
project and copy its [`.bazelversion`](../.bazelversion) into your project.

Set up your `MODULE.bazel` as shown below. Copy the `llvm` and `platforms`
dependencies and the LLVM archive override from the
[integration module](../tests/integration/MODULE.bazel).

```starlark
module(name = "fortran_example")

# Copy the llvm and platforms dependencies and the LLVM archive override here.
bazel_dep(name = "rules_fortran", version = "0.0.0")

local_path_override(
    module_name = "rules_fortran",
    path = "../rules_fortran",
)

llvm_toolchains = use_extension("@llvm//extensions:toolchain.bzl", "toolchain")
use_repo(llvm_toolchains, "llvm_toolchains")

register_toolchains("@llvm_toolchains//:all")

register_toolchains("//toolchains:all")
```

Add this to your `.bazelrc`. It enables the source files used to build the
target intrinsic modules and Flang runtime, and disables local C/C++
toolchain discovery.

```text
common --repo_env=HERMETIC_LLVM_INCLUDE_FLANG=1
common --repo_env=BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN=1
```

Create `toolchains/BUILD.bazel`.

```starlark
load("@rules_fortran//fortran/toolchains:fortran_toolchain.bzl", "fortran_toolchain")

fortran_toolchain(
    name = "flang",
    compiler = "@llvm//tools:flang",
    compiler_kind = "flang",
    intrinsic_modules = "@llvm//runtimes/flang:intrinsic_modules",
    runtime = "@llvm//runtimes/flang:runtime",
    target_flags = select({
        "@llvm//platforms/config:linux_x86_64_gnu": ["--target=x86_64-linux-gnu"],
        "@llvm//platforms/config:linux_x86_64_musl": ["--target=x86_64-linux-musl"],
        "@llvm//platforms/config:macos_aarch64": [
            "--target=aarch64-apple-darwin",
            "-mmacosx-version-min=14.0",
        ],
    }),
)

toolchain(
    name = "linux_x86_64",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
    target_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
    toolchain = ":flang",
    toolchain_type = "@rules_fortran//fortran:toolchain_type",
)

toolchain(
    name = "macos_aarch64",
    exec_compatible_with = [
        "@platforms//cpu:aarch64",
        "@platforms//os:macos",
    ],
    target_compatible_with = [
        "@platforms//cpu:aarch64",
        "@platforms//os:macos",
    ],
    toolchain = ":flang",
    toolchain_type = "@rules_fortran//fortran:toolchain_type",
)
```

Copy the [module and test example](../README.md#build-a-module-and-test-it)
into the project root and run the test.

```sh
bazelisk test //:arithmetic_test
```

The [integration registrations](../tests/integration/toolchains/BUILD.bazel)
show how to select flags and runtime options for other targets.

## How compilation and linking fit together

- The Fortran toolchain selects a compiler executable for the execution
  platform, plus intrinsic modules, runtime and compiler flags for the
  target. The ruleset's public rules accept that toolchain without a direct
  dependency on Hermetic LLVM.
- `fortran_library` exposes module directories and definitions through
  [`FortranInfo`](../fortran/common/fortran_info.bzl). It exposes the archive,
  native dependencies and runtime through `CcInfo`. An empty library can
  merge dependencies without producing an archive.
- Each source produces a native object and a module directory. The selected
  C/C++ toolchain determines whether to compile with PIC. A library merges
  its own module outputs into one directory and rejects duplicate names
  there. Use a `deps` edge for module imports between targets.
- `fortran_binary` and `fortran_test` use `cc_common.link` for startup code,
  libc, builtins and linker configuration. For C interoperability, write
  the matching header for your `bind(C)` procedures and depend on the
  Fortran library through a `cc_library` that exports the header.

## Current limits

The ruleset produces one object per source. Separate PIC and non-PIC
outputs, module-name checks across libraries, and arbitrary
compiler/module-format validation are deferred. Shared libraries, Flang
driver linking, GNU Fortran, OpenMP, coarrays, MPI, coverage, sanitizers,
and Fortran ThinLTO are outside the current implementation.

Flang uses `-O0` for `fastbuild`, `-O0 -g` for `dbg`, and `-O2` for
`opt`. Local `copts` follow those defaults. Compile actions support Bazel
path mapping. Use label inputs instead of literal output paths in
`copts`. Archive and executable link mapping follow the C/C++ toolchain.
