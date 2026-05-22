#!/usr/bin/env bash
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends gcc-multilib g++-multilib libc6-dev-i386
apt-get clean
rm -rf /var/lib/apt/lists/*