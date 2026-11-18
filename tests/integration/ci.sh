#!/usr/bin/env bash
set -euo pipefail

: "${FLANG_ARCHIVE:?Set FLANG_ARCHIVE to the expected Flang repository suffix}"

bazel=(bazelisk --nosystem_rc --nohome_rc)
if [[ "${RUNNER_OS:-}" == Windows ]]; then
  # Keep Bazel's paths short and pass labels literally through Git Bash.
  bazel+=(--output_user_root=C:/bazel)
  export MSYS2_ARG_CONV_EXCL='*'
fi

for cpu in x86_64 aarch64; do
  flags=(
    "--platforms=@llvm//platforms:linux_${cpu}_musl"
    --experimental_output_paths=strip
  )
  if [[ -n "${NATIVE_LINUX_CPU:-}" ]]; then
    # Build the module merge tool for the local CPU with static musl.
    flags+=("--host_platform=@llvm//platforms:linux_${NATIVE_LINUX_CPU}_musl")
  fi
  command=build
  if [[ "$cpu" == "${NATIVE_LINUX_CPU:-}" ]]; then
    command=test
  fi
  "${bazel[@]}" "$command" "${flags[@]}" //...

  # Check the compiler and native link for the same module consumer.
  actions=$("${bazel[@]}" aquery "${flags[@]}" \
    'mnemonic("FortranCompile|CppLink", //:chain_binary)')
  grep -F "flang-toolchain-minimal-${FLANG_ARCHIVE}/bin/flang" <<<"$actions" | cut -c1-160
  grep -F -- "--target=${cpu}-linux-musl" <<<"$actions"
  grep -Fq "llvm-toolchain-minimal-${FLANG_ARCHIVE}/bin/clang++" <<<"$actions"
  grep -Fq '/flang-rt/lib/runtime/_objs/flang_rt.runtime/' <<<"$actions"

  elf=$("${bazel[@]}" cquery "${flags[@]}" --output=files //:chain_binary | tr -d '\r')
  # ELF magic, ELF64 class and little endian encoding.
  [[ "$(od -An -tx1 -N6 "$elf" | tr -d '[:space:]')" == 7f454c460201 ]]
  machine=$(od -An -tx1 -j18 -N2 "$elf" | tr -d '[:space:]')
  case "$cpu:$machine" in
    x86_64:3e00 | aarch64:b700) ;;
    *)
      echo "Unexpected ELF machine for $cpu: $machine ($elf)" >&2
      exit 1
      ;;
  esac
done
