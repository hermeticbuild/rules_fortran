# Gate 4: Flang ruleset path

This gate implements the agreed Flang path in `rules_fortran`. It does not
qualify GNU Fortran or the full BLAS/LAPACK consumer. The Hermetic LLVM inputs
come from the source-backed implementation on PR #959 at
`f680c314f32d81a6e3e060c28c698155a7774201` (LLVM 23.1.2). The minimal
Flang release has not been published, so a prebuilt compiler was not tested.

## Reproduce the qualified pair

Run from `tests/integration` with Bazel 9.3.2. Set `<llvm-checkout>` to the
Hermetic LLVM checkout containing PR #959 and `<llvm-bazelrc>` to that
checkout's `.bazelrc`:

```sh
bazel --bazelrc=<llvm-bazelrc> test //... \
  --override_module=llvm=<llvm-checkout> \
  --repo_env=HERMETIC_LLVM_INCLUDE_FLANG=1 \
  --@llvm//toolchain:bootstrap_stage=stage1_from_source \
  --platforms=//:linux_x86_64_musl_remote \
  --config=remote \
  --extra_execution_platforms=//:linux_x86_64_musl_remote \
  --experimental_output_paths=strip
```

The explicit execution platform matters on an Apple Silicon host: the
Hermetic LLVM remote default otherwise selected an ARM platform, which does
not match this gate's x86_64 Fortran toolchain registration.

## Observed behavior

- The positive suite passed all 14 tests with mapped output paths. It passed
  again after the `rules_cc` toolchain helper change (BuildBuddy invocation
  `baba4b0e-47ed-4a1a-bf18-816e62a73b17`). It covers a Fortran main,
  transitive and diamond module use, an empty aggregate, independent
  sources in one library, fixed and preprocessed sources, a generated source,
  submodules, declared INCLUDE data, C calling a `bind(C)` Fortran library,
  C header propagation through `CcInfo`, `alwayslink` BLOCK DATA, linker
  inputs/options, and test runfiles, arguments, and environment.
- `chain_binary` built after the final `CcInfo` merge change (invocation
  `6ad2188a-0bec-4097-9d21-dd1a8e89a9ba`). `file` and `llvm readelf -h -d`
  show an ELF64 x86_64 static executable with no dynamic `NEEDED` or
  interpreter entry. The PIC object contains an x86_64 GOT-relative
  relocation; the library is an `ar` archive.
- `aquery` of `chain_test` and `c_transitive_headers_test` shows Clang++ from
  the selected CC toolchain as the final linker, 88 Flang-RT runtime object
  arguments in each link, and the Fortran library's probe link option in the
  C test link (invocations `cde64baf-1629-4941-9520-af95723aa2df` and,
  after the helper change, `1e9fbf3d-3dfd-4276-af73-321d473c1c08`). The
  Fortran compiler does not drive these links.
- `aquery` of the compile actions shows one action per source, with only that
  source, the compiler runfiles, intrinsic module tree, and dependency module
  trees as declared inputs. The arguments pass file and tree artifacts through
  Bazel `Args`; each action advertises `supports-path-mapping`. A two-source
  library produces two independent actions. No rule implementation calls
  `.to_list()` or converts a `File` to `.path` for command construction.
- A missing module and undeclared textual include fail during compilation;
  a target without a matching Fortran toolchain fails during resolution.
  Unsupported `thin_lto`, `-fno-pic`, and coverage requests fail at analysis.
  Coverage was confirmed to proceed before the audit fix (invocation
  `5f22fe05-9163-4ef8-9beb-ae5ab05e28e1`) and to fail with the intended
  diagnostic after it (invocation
  `37e47484-ed37-43f4-866f-b7138ff1d858`).
- In `dbg`, the compile action has `-O0 -g`; in `opt`, it has `-O2` (aquery
  invocations `4ad29d21-3585-4e67-aaff-06e29a199640` and
  `e2c3d254-e36e-4eee-a758-d8d71971adc3`). `hello_test` also built and
  ran in `opt` and `dbg` (invocations
  `3eb01c11-edeb-4e72-b4db-48ebd0a2b14b` and
  `8145b943-09ac-4748-b89e-d50646a72b9b`). User `copts` follow those
  defaults. The `fastbuild` default is `-O0`.

`buildifier -mode=check -lint=warn` passes for the Starlark and BUILD files.
The rule code keeps propagated modules and definitions as depsets until
`Args` or provider consumption. Source-to-source module dependencies still
need explicit target edges; module collision and compiler-format validation
remain v2 work.

Fortran rules declare the mandatory CC dependency with `use_cc_toolchain()`.
The link implementation obtains `CcToolchainInfo` with `find_cc_toolchain(ctx)`
and configures features from that result, following the public `rules_cc` helper
contract rather than accessing `ctx.toolchains` by a manually written key.

## Remaining qualification

- The actual Flang prebuilt release path and all platforms beyond Linux
  x86_64 execution to Linux x86_64 musl target are unproven.
- Full `rules_ml_toolchain` BLAS/LAPACK builds belong to gate 5. GNU Fortran
  belongs to gate 6.
- Source path remapping in compiler debug metadata is not claimed; the proven
  path mapping here is Bazel action input/output path mapping. User `copts`
  containing literal output paths may prevent mapping and are outside the
  current guarantee.
