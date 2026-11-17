# Gate 5: downstream Fortran consumer

The consumer is `google-ml-infra/rules_ml_toolchain` at upstream revision
`e5c395b948974af5fc7498fe93e7a6807ba4f7d5`, adapted in the isolated
`cerisier/fortran-gate5` branch. Its old `miinso/rules_fortran` override and
`defs.bzl` loads were replaced with this ruleset's individual rule files and
an explicit Linux x86_64 execution / Linux x86_64 musl target registration.
The consumer module uses Hermetic LLVM as a dev dependency. This gate uses
source-built Flang 23.1.2, target intrinsic modules, Flang-RT and the
Hermetic LLVM CC toolchain. It does not test an unpublished Flang prebuilt.
The toolchain integration selects Flang's `--target` flag from target platform
constraints. The production ruleset accepts those flags through the generic
`fortran_toolchain.target_flags` attribute and has no `@llvm` labels. Its LLVM
module dependency is development-only; an independent consumer can load the
public rules without depending on LLVM.

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
`//third_party/rules_fortran/examples/lapack`. Use `test
//third_party/rules_fortran/examples/lapack:all` for the complete LAPACK
numerical test-data wrappers.

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
- After moving target selection into the toolchain registration, the ruleset's
  14 integration tests passed uncached (invocation
  `d251d292-bf19-4b6c-8550-b164f6cb19fa`), as did all 22 consumer and
  BLAS/LAPACK example tests (invocation
  `b1fc7f8b-015f-4fd9-9a2c-ec1b91ecdb4c`). An independent temporary
  Bzlmod consumer depending only on `rules_fortran` loaded all public rule
  files; its module graph contained no LLVM dependency (invocation
  `c1c1d2b7-7463-46cb-b6c4-f19b96ad4078`). The complete 6,015-target
  BLAS/LAPACK/LAPACKE build passed again (invocation
  `5a6292b6-d89a-4e5e-a7dd-e2c5b3967270`). The `FortranCompile` action for
  the consumer's preprocessed test contains the selected
  `--target=x86_64-linux-musl` flag (invocation
  `b2a77f83-e3fa-4c30-bc48-d1c5a24374f4`).
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
- All 98 LAPACK tests built and ran. 97 passed. The `dgd` numerical wrapper
  failed: `DDRGES` reported `DGGES` returning `INFO=9` for the same case and
  `1 out of 1555` DGS driver checks failed (invocation
  `8c418131-c180-471d-90c4-7ce9d5c272c5`). An uncached fastbuild rerun
  reproduced it (invocation `1b67fb46-095c-44af-ab12-877bdb1c5925`).
  Rebuilding and rerunning that test in Bazel `opt` mode reproduced the same
  case (invocation `5b911a0a-d442-4d45-b8d5-8dafe67a3f82`). The failure
  occurs after a successful compile, native link, and remote execution. Its
  numerical cause has not been established; this gate does not claim the
  complete LAPACK numerical suite is green.

The full LAPACK target graph was built, and every declared numerical wrapper
ran with the one failure above. This gate qualifies only the stated
execution/target pair. GNU Fortran, the unpublished prebuilt archive, other
platforms, and arbitrary compiler/module compatibility remain unqualified.
The consumer used Bazel 9.1.0 and the ruleset integration
used Bazel 9.3.2. The module's declared Bazel 8 compatibility has not been
validated here. Other execution/target pairs will be qualified after the
minimal Flang prebuilts are available. Their toolchain registrations must
select their own compiler flags, intrinsic modules, and runtime.
