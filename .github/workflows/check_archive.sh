#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
version=$(sed -n 's/^    version = "\([^"]*\)",$/\1/p' "$root/MODULE.bazel")
tag="v$version"
scratch=$(mktemp -d "${TMPDIR:-/tmp}/rules-fortran-release.XXXXXX")
echo "Archive verification: $scratch"
cd "$scratch"

bash "$root/.github/workflows/release_prep.sh" "$tag" HEAD >release-notes.md
tar -tzf "rules_fortran-$tag.docs.tar.gz" | LC_ALL=C sort >actual-docs.txt
printf '%s\n' \
  fortran/common/fortran_info.doc_extract.binaryproto \
  fortran/fortran_binary.doc_extract.binaryproto \
  fortran/fortran_library.doc_extract.binaryproto \
  fortran/fortran_test.doc_extract.binaryproto \
  fortran/toolchains/fortran_toolchain.doc_extract.binaryproto \
  fortran/toolchains/fortran_toolchain_info.doc_extract.binaryproto >expected-docs.txt
diff -u expected-docs.txt actual-docs.txt

tar -xzf "rules_fortran-$tag.tar.gz"
cd "rules_fortran-$version"
test -f LICENSE
test -f .bcr/presubmit.yml
test -f .bcr/source.template.json
test -f fortran/private/merge_modules.cc
cd tests/integration
trap 'bazel --nosystem_rc --nohome_rc shutdown >/dev/null 2>&1' EXIT
bazel --nosystem_rc --nohome_rc test //:chain_test //:c_main_test --lockfile_mode=off "$@"
