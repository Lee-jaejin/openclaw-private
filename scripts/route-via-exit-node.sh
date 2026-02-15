#!/bin/bash
# Route all host/container internet traffic through a Tailscale exit node.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [[ -f "$PROJECT_DIR/.env" ]]; then
    # shellcheck disable=SC1090
    source "$PROJECT_DIR/.env"
fi

HEADSCALE_URL="${HEADSCALE_URL:-https://headscale.local:8080}"
EXIT_NODE="${1:-${TAILSCALE_EXIT_NODE:-}}"
ALLOW_LAN="${TAILSCALE_ALLOW_LAN_ACCESS:-false}"

if ! command -v tailscale &> /dev/null; then
    echo "tailscale CLI not found. Install Tailscale first."
    exit 1
fi

if [[ -z "$EXIT_NODE" ]]; then
    echo "Usage: bash scripts/route-via-exit-node.sh <exit-node-ip-or-hostname>"
    echo "or set TAILSCALE_EXIT_NODE in .env"
    exit 1
fi

LAN_FLAG="--exit-node-allow-lan-access=false"
if [[ "$ALLOW_LAN" == "true" ]]; then
    LAN_FLAG="--exit-node-allow-lan-access=true"
fi

echo "Configuring Tailscale to use exit node: $EXIT_NODE"
echo "Headscale login server: $HEADSCALE_URL"

SUDO=""
if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    SUDO="sudo"
fi

$SUDO tailscale up \
    --login-server="$HEADSCALE_URL" \
    --accept-routes \
    --accept-dns=false \
    --exit-node="$EXIT_NODE" \
    "$LAN_FLAG"

echo ""
echo "Current Tailscale status:"
tailscale status
