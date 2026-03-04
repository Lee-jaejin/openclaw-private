#!/bin/bash
# Temporarily serve the headscale CA certificate over HTTP so new nodes can download it.
# Run this on the control tower before running node-join.sh on a new node.
# Usage: serve-ca.sh [port]
#
# Example:
#   Control tower: ./scripts/serve-ca.sh
#   New node:      ./scripts/node-join.sh 192.168.1.10 <api-key>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CA_DIR="${SCRIPT_DIR}/../infra/headscale/certs"
PORT="${1:-8880}"
LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')

echo "Serving CA cert at http://${LAN_IP}:${PORT}/ca.crt"
echo "Press Ctrl+C to stop."
python3 -m http.server "${PORT}" --directory "${CA_DIR}"
