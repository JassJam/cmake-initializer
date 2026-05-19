#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing system dependencies (Emscripten/Linux) ==="
sudo apt-get update -q
sudo apt-get install -y build-essential ninja-build cmake git python3 pwsh

echo "Node.js version: $(node --version)"
echo "npm version:     $(npm --version)"

echo "=== Running common test logic ==="
pwsh -NonInteractive -File "$(dirname "$0")/common.ps1"