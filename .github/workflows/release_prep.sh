#!/usr/bin/env bash
# The release workflow calls this script with a tag. A local dry run may supply a ref.
set -euo pipefail

tag=${1:?usage: release_prep.sh vVERSION [git-ref]}
ref=${2:-$tag}
root=$(cd "$(dirname "$0")/../.." && pwd)
if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Expected a release tag of the form vX.Y.Z, got $tag" >&2
  exit 1
fi

version=${tag#v}
if ! git -C "$root" show "$ref:MODULE.bazel" | grep -Fxq "    version = \"$version\","; then
  echo "$ref has a MODULE.bazel version that does not match $tag" >&2
  exit 1
fi

prefix="rules_fortran-$version"
archive="rules_fortran-$tag.tar.gz"
git -C "$root" archive --format=tar --prefix="$prefix/" "$ref" | gzip -n >"$archive"
checksum=$(shasum -a 256 "$archive" | cut -d ' ' -f 1)

# Generate docs from exactly the committed source distribution.
docs_archive="$PWD/${archive%.tar.gz}.docs.tar.gz"
source_dir=$(mktemp -d "${TMPDIR:-/tmp}/rules-fortran-docs.XXXXXX")
tar -xzf "$archive" -C "$source_dir"
(
  cd "$source_dir/$prefix"
  trap 'bazel --nosystem_rc --nohome_rc shutdown >/dev/null 2>&1' EXIT
  bash docs/package.sh "$docs_archive" --lockfile_mode=off
)

cat <<EOF
## Bzlmod

After the BCR submission merges, add this dependency:

\`\`\`starlark
bazel_dep(name = "rules_fortran", version = "$version")
\`\`\`

See the [toolchain setup guide](https://github.com/hermeticbuild/rules_fortran/blob/$tag/docs/toolchains.md) to register a Fortran compiler and C/C++ toolchain.

Source archive SHA-256: \`$checksum\`
EOF
