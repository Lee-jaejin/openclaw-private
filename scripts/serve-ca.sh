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
echo "iOS profile:       http://${LAN_IP}:${PORT}/headscale-ca.mobileconfig"
echo "Press Ctrl+C to stop."

# Custom server: .mobileconfig must be served as application/x-apple-aspen-config
# otherwise iOS treats it as a file download instead of a configuration profile
python3 - "${PORT}" "${CA_DIR}" << 'PYEOF'
import sys, os
from http.server import HTTPServer, SimpleHTTPRequestHandler

port = int(sys.argv[1])
directory = sys.argv[2]

class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=directory, **kwargs)
    def guess_type(self, path):
        if str(path).endswith('.mobileconfig'):
            return 'application/x-apple-aspen-config'
        return super().guess_type(path)
    def log_message(self, fmt, *args):
        print(fmt % args)

HTTPServer(('', port), Handler).serve_forever()
PYEOF
