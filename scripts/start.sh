#!/bin/bash
# Start all OpenClaw services in the correct order.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

echo "=== Starting OpenClaw services ==="

# 1. Containers (headscale → egress-proxy → openclaw via depends_on)
echo "[1/3] Starting containers..."
podman compose -f "${PROJECT_DIR}/docker-compose.yml" up -d

# 2. VM proxy (skip if already running)
echo "[2/3] Starting VM proxy..."
VM_PROXY_PID=$(pgrep -f "headscale-vm-proxy.mjs" || true)
if [[ -n "${VM_PROXY_PID}" ]]; then
    echo "  VM proxy already running (PID ${VM_PROXY_PID}), skipping"
else
    mkdir -p "${PROJECT_DIR}/logs"
    nohup node "${SCRIPT_DIR}/headscale-vm-proxy.mjs" \
        > "${PROJECT_DIR}/logs/headscale-vm-proxy.log" 2>&1 &
    echo "  VM proxy started (PID $!)"
fi

# 3. Status
echo "[3/3] Status:"
podman compose -f "${PROJECT_DIR}/docker-compose.yml" ps
echo ""
echo "Done. Run 'pnpm health' to verify."
