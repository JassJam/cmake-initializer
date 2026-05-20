#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing system dependencies (Emscripten/Linux) ==="
apt-get update -q
apt-get install -y build-essential ninja-build cmake curl git libicu-dev libssl-dev python3

# Install xmake/xrepo
curl -fsSL https://xmake.io/shget.text | bash
export PATH="$HOME/.local/bin:$PATH"

PWSH_VERSION="7.6.1"
curl -fsSL "https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}/powershell-${PWSH_VERSION}-linux-x64.tar.gz" \
    -o /tmp/powershell.tar.gz
mkdir -p /opt/powershell
tar -xzf /tmp/powershell.tar.gz -C /opt/powershell
chmod +x /opt/powershell/pwsh
ln -sf /opt/powershell/pwsh /usr/local/bin/pwsh
rm /tmp/powershell.tar.gz

# Verify xrepo is working
xrepo --version

echo "Node.js version: $(node --version)"
echo "npm version:     $(npm --version)"

echo "=== Running common test logic ==="
pwsh -NonInteractive -File "$(dirname "$0")/common.ps1"