#!/bin/bash
# Disable Tailscale exit node routing.

set -euo pipefail

if ! command -v tailscale &> /dev/null; then
    echo "tailscale CLI not found. Install Tailscale first."
    exit 1
fi

SUDO=""
if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    SUDO="sudo"
fi

echo "Disabling exit node routing..."
$SUDO tailscale set --exit-node=

echo ""
echo "Current Tailscale status:"
tailscale status
