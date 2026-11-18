# Toolchains and integration

## Set up a Bzlmod consumer

This example supports Linux x86_64 with musl and macOS Arm64. Clone
[`rules_fortran`](https://github.com/hermeticbuild/rules_fortran) next to your
project. Use Bazelisk with `9.3.2` in your project's `.bazelversion`.

Add the following to your `MODULE.bazel`. The Hermetic LLVM override
selects the revision that indexes the published Flang 23.1.6 archive.

```starlark
module(name = "fortran_example")

bazel_dep(name = "llvm", version = "0.8.27")
bazel_dep(name = "platforms", version = "1.1.0")
bazel_dep(name = "rules_fortran", version = "0.0.0")

archive_override(
    module_name = "llvm",
    integrity = "sha256-zNZTSmBqcpp8ZyCAGPx/isIo13grecZzU1aXCkZnyN0=",
    strip_prefix = "hermetic-llvm-d316387adbe84b7754ef183c366396bda120962e",
    urls = ["https://github.com/hermeticbuild/hermetic-llvm/archive/d316387adbe84b7754ef183c366396bda120962e.tar.gz"],
)

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
        "@llvm//platforms/config:linux_x86_64_musl": ["--target=x86_64-linux-musl"],
        "@llvm//platforms/config:macos_aarch64": [
            "--target=aarch64-apple-darwin",
            "-mmacosx-version-min=14.0",
        ],
    }),
)

toolchain(
    name = "linux_x86_64_musl",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
    target_compatible_with = [
        "@llvm//constraints/libc:musl",
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
into the project root. On a Linux x86_64 host, run the test with both
platforms set to musl.

```sh
bazelisk test //:arithmetic_test \
  --platforms=@llvm//platforms:linux_x86_64_musl \
  --host_platform=@llvm//platforms:linux_x86_64_musl
```

On macOS Arm64, use `--platforms=@llvm//platforms:macos_aarch64` and omit
`--host_platform`.

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

## Reproduce integration CI

Run [`ci.sh`](../tests/integration/ci.sh) from `tests/integration`.
For example, on an Arm64 Mac, run the following.

```sh
FLANG_ARCHIVE=darwin-arm64 NATIVE_OS=macos NATIVE_CPU=aarch64 bash ci.sh
```

The script builds and runs the suite on the matching platform and checks
the Flang archive, compiler target, link inputs and executable headers.
`TARGET_FILTER` selects a single target for a local probe. See the
[Gate 4 evidence](gate-4-evidence.md) for the source build and the
[Gate 5 evidence](gate-5-evidence.md) for downstream and prebuilt checks.
