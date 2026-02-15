#!/bin/bash
# Stop all OpenClaw services.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

echo "=== Stopping OpenClaw services ==="

# 1. Containers
echo "[1/2] Stopping containers..."
podman compose -f "${PROJECT_DIR}/docker-compose.yml" down

# 2. VM proxy
echo "[2/2] Stopping VM proxy..."
VM_PROXY_PID=$(pgrep -f "headscale-vm-proxy.mjs" || true)
if [[ -n "${VM_PROXY_PID}" ]]; then
    kill "${VM_PROXY_PID}"
    echo "  VM proxy stopped (PID ${VM_PROXY_PID})"
else
    echo "  VM proxy not running, skipping"
fi

echo ""
echo "Done."
