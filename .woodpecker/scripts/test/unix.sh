#!/usr/bin/env bash
set -euo pipefail


echo "=== Installing system dependencies (Linux) ==="
apt-get update -q
apt-get install -y build-essential ninja-build cmake \
    curl apt-transport-https software-properties-common

# Get Ubuntu version
source /etc/os-release
curl -fsSL "https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb" \
    -o /tmp/packages-microsoft-prod.deb
dpkg -i /tmp/packages-microsoft-prod.deb
rm /tmp/packages-microsoft-prod.deb
apt-get update -q
apt-get install -y powershell

# Install Clang if the preset requires it
if [[ "$CONFIG_PRESET" == *clang* ]]; then
    echo "=== Installing Clang ==="
    apt-get install -y clang
fi

echo "=== Running common test logic ==="
pwsh -NonInteractive -File "$(dirname "$0")/common.ps1"