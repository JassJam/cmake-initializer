#!/usr/bin/env bash
set -euo pipefail

SDK_VERSION="${MACOS_SDK_VERSION:-26.0}"
PREFIX=/opt/osxcross

apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
  clang lld llvm-dev cmake make ninja-build git patch python3 xz-utils bzip2 cpio \
  libssl-dev libxml2-dev zlib1g-dev liblzma-dev libbz2-dev uuid-dev \
  ca-certificates wget gzip sed tar

git clone --depth 1 https://github.com/tpoechtrager/osxcross "$PREFIX"

wget -q "https://github.com/joseluisq/macosx-sdks/releases/download/${SDK_VERSION}/MacOSX${SDK_VERSION}.sdk.tar.xz" \
  -O "$PREFIX/tarballs/MacOSX${SDK_VERSION}.sdk.tar.xz"

(cd "$PREFIX" && UNATTENDED=1 TARGET_DIR="$PREFIX/target" ./build.sh)

BIN="$PREFIX/target/bin"
CC_PATH=$(ls "$BIN"/aarch64-apple-darwin*-clang 2>/dev/null | head -1 || true)
[ -n "$CC_PATH" ] || { echo "no arm64 clang wrapper found; available:"; ls "$BIN"; exit 1; }
TRIPLE=$(basename "$CC_PATH" -clang)

cat > ./.osxcross-env <<ENV
export PATH="$BIN:\$PATH"
export CC=${TRIPLE}-clang
export CXX=${TRIPLE}-clang++
export AR=${TRIPLE}-ar
export RANLIB=${TRIPLE}-ranlib
export INSTALL_NAME_TOOL=${TRIPLE}-install_name_tool
ENV
