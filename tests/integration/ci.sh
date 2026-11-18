#!/usr/bin/env bash
set -euo pipefail

: "${FLANG_ARCHIVE:?Set FLANG_ARCHIVE to the expected Flang repository suffix}"

bazel=(bazelisk --nosystem_rc --nohome_rc)
if [[ "${RUNNER_OS:-}" == Windows ]]; then
  # Keep Bazel's paths short and pass labels literally through Git Bash.
  bazel+=(--output_user_root=C:/bazel --windows_enable_symlinks)
  export MSYS2_ARG_CONV_EXCL='*'
fi

output_base=$("${bazel[@]}" info output_base | tr -d '\r')

matched=0
while read -r platform os cpu triple format driver; do
  if [[ -n "${TARGET_FILTER:-}" ]]; then
    [[ "$platform" == "$TARGET_FILTER" ]] || continue
  elif [[ "$os" != "${NATIVE_OS:-}" || "$cpu" != "${NATIVE_CPU:-}" ]]; then
    continue
  fi
  matched=1
  echo "=== $FLANG_ARCHIVE -> $platform ==="
  flags=("--platforms=@llvm//platforms:$platform")
  if [[ "${RUNNER_OS:-}" != Windows ]]; then
    # Bazel needs sandboxing for mapped MinGW actions. Windows runners
    # execute these actions locally.
    flags+=(--experimental_output_paths=strip)
  fi
  if [[ "${NATIVE_OS:-}" == linux ]]; then
    # Build the module merge tool for the local CPU with static musl.
    flags+=("--host_platform=@llvm//platforms:linux_${NATIVE_CPU}_musl")
  fi
  if [[ "$driver" == clang-cl ]]; then
    flags+=(--repo_env=BAZEL_MSVC_RUNTIME_VISUAL_STUDIO_EULA=1 --repo_env=BAZEL_WINDOWS_SDK_EULA=1)
  fi
  if [[ "$os" == "${NATIVE_OS:-}" && "$cpu" == "${NATIVE_CPU:-}" ]]; then
    flags+=("--extra_toolchains=//toolchains/native_test:${os}_${cpu}")
    if [[ "$os" == windows ]]; then
      flags+=(--enable_runfiles)
    fi
    "${bazel[@]}" test "${flags[@]}" //...
  else
    "${bazel[@]}" build "${flags[@]}" //:chain_binary
  fi

  # Check the compiler and native link for the same module consumer.
  actions=$("${bazel[@]}" aquery "${flags[@]}" \
    'mnemonic("FortranCompile|CppLink", //:chain_binary)')
  grep -Fq "flang-toolchain-minimal-${FLANG_ARCHIVE}/bin/flang" <<<"$actions"
  grep -F -- "--target=$triple" <<<"$actions"
  grep -Fq '/flang-rt/lib/runtime/' <<<"$actions"

  # The same LLVM archive supplies a reader for ELF, Mach-O and PE.
  llvm_bin=$(grep -oE "external/[^/[:space:]]*llvm-toolchain-minimal-${FLANG_ARCHIVE}/bin/" <<<"$actions" | sort -u)
  grep -Fq "${llvm_bin}${driver}" <<<"$actions"
  artifact=$("${bazel[@]}" cquery "${flags[@]}" --output=files //:chain_binary | tr -d '\r')
  readobj="$output_base/${llvm_bin}llvm-readobj"
  if [[ "${RUNNER_OS:-}" == Windows ]]; then
    readobj+=.exe
  fi
  headers=$("$readobj" --file-headers "$artifact" | tr -d '\r')
  grep -F "Format: $format" <<<"$headers"
  grep -Fx "Arch: $cpu" <<<"$headers"

done <<'TARGETS'
linux_x86_64_musl    linux   x86_64  x86_64-linux-musl         elf64-  clang++
linux_aarch64_musl   linux   aarch64 aarch64-linux-musl        elf64-  clang++
linux_riscv64_musl   linux   riscv64 riscv64-linux-musl        elf64-  clang++
linux_x86_64         linux   x86_64  x86_64-linux-gnu          elf64-  clang++
linux_aarch64        linux   aarch64 aarch64-linux-gnu        elf64-  clang++
linux_riscv64        linux   riscv64 riscv64-linux-gnu         elf64-  clang++
macos_x86_64         macos   x86_64  x86_64-apple-darwin       Mach-O  clang++
macos_aarch64        macos   aarch64 aarch64-apple-darwin      Mach-O  clang++
windows_x86_64       windows x86_64  x86_64-w64-windows-gnu    COFF-   clang++
windows_aarch64      windows aarch64 aarch64-w64-windows-gnu   COFF-   clang++
windows_x86_64_msvc  windows x86_64  x86_64-pc-windows-msvc     COFF-   clang-cl
windows_aarch64_msvc windows aarch64 aarch64-pc-windows-msvc    COFF-   clang-cl
TARGETS

if [[ "$matched" == 0 ]]; then
  echo "No target for filter '${TARGET_FILTER:-}' and native host '${NATIVE_OS:-}/${NATIVE_CPU:-}'" >&2
  exit 1
fi
