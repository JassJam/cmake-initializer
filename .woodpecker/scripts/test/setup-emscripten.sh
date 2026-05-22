#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing system dependencies (Emscripten/Linux) ==="
apt-get update -q
apt-get install -y build-essential ninja-build cmake curl git libicu-dev libssl-dev python3

curl -fsSL https://xmake.io/shget.text | bash
export PATH="$HOME/.local/bin:$PATH"
