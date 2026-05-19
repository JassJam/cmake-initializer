#!/usr/bin/env bash
set -euo pipefail

apt-get update -q && apt-get install -y git
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Homebrew if not present
if ! command -v brew &>/dev/null; then
    echo "=== Installing Homebrew ==="
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for Apple Silicon or Intel
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null
fi

echo "=== Installing system dependencies (macOS) ==="
brew install ninja cmake pwsh

if [[ "$CONFIG_PRESET" == *clang* ]]; then
    echo "=== Ensuring Xcode CLI tools are available ==="
    xcode-select --install 2>/dev/null || true
fi

echo "=== Running common test logic ==="
pwsh -NonInteractive -File "$(dirname "$0")/common.ps1"