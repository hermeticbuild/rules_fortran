# Release preparation

## Check the API reference

After changing Starlark loads, run Gazelle from the repository root.

```sh
bazel run //tools/gazelle:update
bazel run //tools/gazelle:check
bazel build //docs:api
```

Gazelle scans only `fortran/`. Keep the explicit dependencies marked
with `# keep` in sync with their loads. The
[`//docs:api` filegroup](BUILD.bazel) selects the six public entry points
for the [BCR API reference](https://github.com/bazelbuild/bazel-central-registry/blob/main/docs/stardoc.md).

## Check a release candidate

Commit the candidate and run the archive check. It packages `HEAD`,
generates API docs from the source archive, and runs the module and
C interoperability tests from an extracted copy.

```sh
bash .github/workflows/check_archive.sh
```

The script prints the directory containing the archives and release
notes. The integration module uses its pinned Hermetic LLVM revision
to fetch Flang and build the target runtime. The registry module itself
can be loaded without Hermetic LLVM.

## Release workflow

Use a `vX.Y.Z` tag that matches the root `MODULE.bazel` version.
The [release workflow](../.github/workflows/release.yml) runs native
CI and the archive check, then creates a draft GitHub release with
attestations for the source and docs archives. Publish to BCR opens
a draft registry PR and attaches attestations for the registry
files. The workflow then publishes the GitHub release so the BCR
presubmit can fetch its assets. Confirm that the repository has access
to `BCR_PUBLISH_TOKEN` before tagging.

The [BCR templates](../.bcr) point to the GitHub release assets and
reuse the integration module for the registry presubmit.
