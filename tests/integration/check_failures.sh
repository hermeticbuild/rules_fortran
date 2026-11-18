#!/usr/bin/env bash
set -euo pipefail

if output=$(bazelisk --nosystem_rc --nohome_rc build \
  --keep_going --experimental_output_paths=strip --strategy=FortranCompile=sandboxed "$@" \
  //:duplicate_module //:missing_module_test //:undeclared_include_test \
  //:unsupported_feature_test //:disable_pic_test 2>&1); then
  printf '%s\nExpected the negative fixtures to fail.\n' "$output" >&2
  exit 1
fi

# Verify each failure so an unrelated error cannot satisfy the check.
for diagnostic in \
  'merge_modules: create module (duplicate name?)' \
  "Source file 'left_m.mod' was not found" \
  "INCLUDE: Source file 'value.inc' was not found" \
  "Fortran compilation does not support feature 'thin_lto' yet" \
  "copts cannot override compiler-owned option '-fno-pic'"; do
  if ! grep -Fq -- "$diagnostic" <<<"$output"; then
    printf '%s\nMissing expected diagnostic: %s\n' "$output" "$diagnostic" >&2
    exit 1
  fi
  printf 'Observed expected diagnostic: %s\n' "$diagnostic"
done
