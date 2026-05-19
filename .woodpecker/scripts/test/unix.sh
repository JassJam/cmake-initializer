#!/usr/bin/env bash
set -euo pipefail


echo "=== Installing system dependencies (Linux) ==="
apt-get update -q
apt-get install -y build-essential ninja-build cmake \
    curl apt-transport-https software-properties-common

# Get Ubuntu version
PWSH_VERSION="7.6.1"
curl -fsSL "https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}/powershell-${PWSH_VERSION}-linux-x64.tar.gz" \
    -o /tmp/powershell.tar.gz
mkdir -p /opt/powershell
tar -xzf /tmp/powershell.tar.gz -C /opt/powershell
chmod +x /opt/powershell/pwsh
ln -sf /opt/powershell/pwsh /usr/local/bin/pwsh
rm /tmp/powershell.tar.gz

# Install Clang if the preset requires it
if [[ "$CONFIG_PRESET" == *clang* ]]; then
    echo "=== Installing Clang ==="
    apt-get install -y clang
fi

echo "=== Running common test logic ==="
pwsh -NonInteractive -File "$(dirname "$0")/common.ps1"