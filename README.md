# rules_fortran

Build Fortran libraries, executables, and tests with Bazel. Compile with
Flang and link with Bazel's selected C/C++ toolchain. C and C++ targets can
link against Fortran libraries through ordinary Bazel dependencies.

## Quickstart

Install [Bazelisk](https://github.com/bazelbuild/bazelisk), then try the
included examples on Linux x86_64 or macOS Arm64.

```sh
git clone https://github.com/hermeticbuild/rules_fortran.git
cd rules_fortran/tests/integration
bazelisk test //:hello_test //:chain_test //:c_main_test
```

The examples use the published Flang compiler and build the target modules
and runtime with Hermetic LLVM.

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

## Platforms

Flang works on x86_64 and Arm64 for Linux (glibc and musl), macOS, and
Windows (MinGW and MSVC). GNU Fortran and shared libraries are planned.

## License

[MIT](LICENSE)
