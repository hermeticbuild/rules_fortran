# rules_fortran

Build Fortran libraries, executables, and tests with Bazel. Compile with
Flang and link with Bazel's selected C/C++ toolchain. C and C++ targets can
link against Fortran libraries through ordinary Bazel dependencies.

## Quickstart

Install [Bazelisk](https://github.com/bazelbuild/bazelisk), then try the
included examples on Linux x86_64.

```sh
git clone https://github.com/hermeticbuild/rules_fortran.git
cd rules_fortran/tests/integration
bazelisk test //:hello_test //:chain_test //:c_main_test \
  --platforms=@llvm//platforms:linux_x86_64_musl \
  --host_platform=@llvm//platforms:linux_x86_64_musl
```

On macOS Arm64, use `--platforms=@llvm//platforms:macos_aarch64` and omit
`--host_platform`. The integration module downloads Flang 23.1.6 and uses
Hermetic LLVM to build the target modules and runtime.

To use the rules in your own Bzlmod project, follow the
[toolchain setup guide](docs/toolchains.md). It uses a Git checkout of
`rules_fortran` and a pinned Hermetic LLVM revision.

## Build a module and test it

A target that reads a Fortran module with `use` declares the module's
library in `deps`. Bazel builds the module before compiling its consumer.

**`BUILD.bazel`**

```starlark
load("@rules_fortran//fortran:fortran_library.bzl", "fortran_library")
load("@rules_fortran//fortran:fortran_test.bzl", "fortran_test")

fortran_library(
    name = "arithmetic",
    srcs = ["arithmetic.f90"],
)

fortran_test(
    name = "arithmetic_test",
    srcs = ["arithmetic_test.f90"],
    features = select({
        "@llvm//platforms/config:musl": ["fully_static_link"],
        "//conditions:default": [],
    }),
    deps = [":arithmetic"],
)
```

**`arithmetic.f90`**

```fortran
module arithmetic
  implicit none
contains
  integer function twice(value)
    integer, intent(in) :: value
    twice = 2 * value
  end function twice
end module arithmetic
```

**`arithmetic_test.f90`**

```fortran
program arithmetic_test
  use arithmetic, only: twice
  implicit none
  if (twice(21) /= 42) stop 1
end program arithmetic_test
```

Use [`fortran_binary`](fortran/fortran_binary.bzl) for an executable. For a C
caller, declare the interface in a header and use `bind(C)` in Fortran.
The [interop example](tests/integration/BUILD.bazel) links
[a C main](tests/integration/c_main.c) with
[a Fortran routine](tests/integration/interop.f90).

## Tested platforms

Native CI uses Bazel 9.3.2 and Flang 23.1.6 on x86_64 and Arm64.

| OS | Native targets |
| --- | --- |
| Linux | musl and glibc |
| macOS | macOS system libraries |
| Windows | MinGW and MSVC |

See the [CI workflow](.github/workflows/ci.yml) and
[integration evidence](docs/gate-5-evidence.md) for coverage. GNU Fortran
and shared libraries are planned. The [toolchain guide](docs/toolchains.md)
describes the current rule behavior and limits.

## License

[MIT](LICENSE)
