#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing system dependencies (Emscripten/Linux) ==="
apt-get update -q
apt-get install -y build-essential ninja-build cmake curl git libicu-dev libssl-dev python3

# Install xmake/xrepo
_saved_EMSDK="${EMSDK:-}"
unset EMSDK

curl -fsSL https://xmake.io/shget.text | bash
export PATH="$HOME/.local/bin:$PATH"
xmake update -v dev

export EMSDK="$_saved_EMSDK"

# Verify xrepo is working
xrepo --version

echo "Node.js version: $(node --version)"
echo "npm version:     $(npm --version)"
