#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing system dependencies (Linux) ==="
sudo apt-get update -q
sudo apt-get install -y build-essential ninja-build cmake pwsh

# Install Clang if the preset requires it
if [[ "$CONFIG_PRESET" == *clang* ]]; then
    echo "=== Installing Clang ==="
    sudo apt-get install -y clang
fi

echo "=== Running common test logic ==="
pwsh -NonInteractive -File "$(dirname "$0")/common.ps1"