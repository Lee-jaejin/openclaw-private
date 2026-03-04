#!/bin/bash
# Disable Tailscale exit node routing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [[ -f "$PROJECT_DIR/.env" ]]; then
    # shellcheck disable=SC1090
    source "$PROJECT_DIR/.env"
fi

HEADSCALE_URL="${HEADSCALE_URL:-https://headscale.local:8080}"

if ! command -v tailscale &> /dev/null; then
    echo "tailscale CLI not found. Install Tailscale first."
    exit 1
fi

SUDO=""
if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    SUDO="sudo"
fi

echo "Disabling exit node routing..."
# tailscale set only changes flags, leaving routing table in inconsistent state.
# tailscale up resets routing properly.
$SUDO tailscale up \
    --login-server="$HEADSCALE_URL" \
    --accept-routes=false \
    --exit-node=

echo ""
echo "Current Tailscale status:"
tailscale status
