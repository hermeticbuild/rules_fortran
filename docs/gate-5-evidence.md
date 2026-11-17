# Gate 5: downstream Fortran consumer

The consumer is `google-ml-infra/rules_ml_toolchain` at upstream revision
`e5c395b948974af5fc7498fe93e7a6807ba4f7d5`, adapted in the isolated
`cerisier/fortran-gate5` branch. Its old `miinso/rules_fortran` override and
`defs.bzl` loads were replaced with this ruleset's individual rule files and
an explicit Linux x86_64 execution / Linux x86_64 musl target registration.
The consumer module uses Hermetic LLVM as a dev dependency. This gate uses
source-built Flang 23.1.2, target intrinsic modules, Flang-RT and the
Hermetic LLVM CC toolchain. It does not test an unpublished Flang prebuilt.

## Failures reproduced before the fixes

- `//fortran/tests:preprocessed_test` could not load `iso_c_binding.mod` when
  reading a dependency's `math_mod.mod`, although the intrinsic tree was a
  declared input and contained the file. It failed with mapped output paths
  (invocation `44209108-e860-4f4e-92cb-df1e4d4b502f`) and without mapping
  (invocation `22e84a72-35ed-45cf-95b5-3973ef5b87b4`). Flang's
  `flang/lib/Semantics/mod-file.cpp` locates a hashed intrinsic dependency
  under a relative directory, then passes that located path to `Prescan`.
  `flang/lib/Parser/source.cpp` searches relative paths under the configured
  directories again. A trailing `-fintrinsic-modules-path=.` lets the second
  search open that located path. The generated intrinsic tree stays first in
  the search order. The regression makes `base_m` use `iso_c_binding`, then
  compiles transitive consumers through the existing `chain_test`.
- The first complete BLAS/LAPACK/LAPACKE build completed 6,009 of 6,015
  top-level targets (invocation `6a838fb6-bbf8-4d54-bef9-a07d4dc95000`).
  Six LAPACK targets failed because a source action inherited over 4,000
  per-source module directories; Flang's compiler spawn failed with
  `Argument list too long`. Each library now merges its source module files
  into one declared tree using an execution-platform CC-built tool. A
  dependent compile receives one `-I` per library, while its merged trees
  remain declared inputs. Duplicate filenames within one library fail at
  merge instead of silently replacing a module. Binaries and tests do not
  run an unused merge action.

## Reproduce

From the consumer checkout, set `<consumer-bazelrc>` and `<llvm-bazelrc>` to
the respective `.bazelrc` files and `<rules-fortran>` and `<llvm-checkout>` to
the local module paths. The consumer's `.bazelrc` defines `bzlmod` and
`bazel9`; Hermetic LLVM's defines `remote`:

```sh
bazel --bazelrc=<consumer-bazelrc> --bazelrc=<llvm-bazelrc> \
  test //fortran/tests:all \
  --config=bzlmod --config=bazel9 --config=remote \
  --override_module=rules_fortran=<rules-fortran> \
  --override_module=llvm=<llvm-checkout> \
  --repo_env=HERMETIC_LLVM_INCLUDE_FLANG=1 \
  --@llvm//toolchain:bootstrap_stage=stage1_from_source \
  --platforms=//fortran/tests/toolchains:linux_x86_64_musl_remote \
  --extra_execution_platforms=//fortran/tests/toolchains:linux_x86_64_musl_remote \
  --experimental_output_paths=strip
```

Use the same flags with `build '@blas//:*' '@lapack//:*' '@lapacke//:*'` for
the full target set. The runtime examples use `test
//third_party/rules_fortran/examples/blas:all` plus the four LAPACK targets
`lu`, `chol`, `svd`, and `mixed` under
`//third_party/rules_fortran/examples/lapack`.

## Observed after the fixes

- The consumer's five Fortran/C++ integration tests passed (invocation
  `6b37dfa7-d89f-484a-a38b-526d24d2b5ab`). Its C++ test uses
  `fully_static_link` and `linkstatic` with this musl CC toolchain.
- The formerly failing `@lapack//:tmg_complex16` built its archive and
  merged tree (invocation `3e60f85d-5f46-4adc-884f-1d58abece77e`). The
  complete 6,015-target BLAS/LAPACK/LAPACKE build passed (invocation
  `ebe1dd87-a6b2-4fac-9d0d-f6ec5a7d0eaa`). All 17 BLAS and LAPACK
  example tests passed (invocation
  `98e179ee-1eaa-4b75-97e8-f8640438321e`).
- The ruleset's own integration module built 19 targets and ran all 14 tests
  successfully with mapped paths and `--nocache_test_results` after this
  change (invocation `208667ba-33d8-45bb-95e7-e7515d8a259b`).
- `aquery` for the consumer's preprocessed test shows the Flang executable
  and runfiles, intrinsic tree, merged `math_mod` tree, and source as declared
  compile inputs. The command uses `--target=x86_64-linux-musl`, both
  intrinsic paths, and a single dependency `-I`; the action still advertises
  `supports-path-mapping` (invocation
  `43b38c87-c760-491d-84b6-4e0d1798e79f`). The merge action declares
  its source tree and execution tool as inputs and a tree artifact as output.
- `aquery` for the LAPACK `lu` demo shows `CppLink` executed by the selected
  Hermetic LLVM `clang++`, with Flang-RT objects among its link inputs
  (invocation `f6d31a4d-7011-429b-a727-d958908a9eac`). `file` and
  `llvm readelf` show an x86-64 static ELF executable with no `INTERP` or
  dynamic segment. The `la_constants` merged tree contains
  `la_constants.mod`.

The full LAPACK target graph was built, while runtime validation covered its
four demo tests, not every LAPACK numerical test-data wrapper. This gate
qualifies only the stated execution/target pair. GNU Fortran, the unpublished
prebuilt archive, other platforms, and arbitrary compiler/module compatibility
remain unqualified. The final dependency gate will remove the normal
`@llvm` module dependency from this ruleset; LLVM-specific inputs belong in
integration/dev setup or the consumer's selected toolchain.
