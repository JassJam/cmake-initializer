#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing system dependencies (Linux) ==="
apt-get update -q
apt-get install -y build-essential ninja-build cmake curl git libicu-dev libssl-dev

# Install Clang if the preset requires it
if [[ "$CONFIG_PRESET" == *clang* ]]; then
    echo "=== Installing Clang ==="
    apt-get install -y clang
fi
