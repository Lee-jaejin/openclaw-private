#!/bin/bash
# Add the headscale CA certificate to the macOS System Keychain.
# Run this once on the control tower (macbook) after initial setup.
# Usage: sudo ./scripts/setup-macos-ca.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CA_CERT="${SCRIPT_DIR}/../infra/headscale/certs/ca.crt"

if [[ ! -f "${CA_CERT}" ]]; then
    echo "Error: CA cert not found at ${CA_CERT}" >&2
    exit 1
fi

echo "Adding headscale CA to macOS System Keychain..."
security add-trusted-cert -d -r trustRoot \
    -k /Library/Keychains/System.keychain \
    "${CA_CERT}"
echo "Done. macOS now trusts the headscale TLS certificate."
