#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing system dependencies (macOS) ==="
brew install ninja cmake pwsh git

if [[ "$CONFIG_PRESET" == *clang* ]]; then
    echo "=== Ensuring Xcode CLI tools are available ==="
    xcode-select --install 2>/dev/null || true
fi

echo "=== Running common test logic ==="
pwsh -NonInteractive -File "$(dirname "$0")/common.ps1"