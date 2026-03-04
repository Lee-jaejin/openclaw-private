#!/bin/bash
# Generate headscale TLS certificates (CA + server cert).
# Run this once on the control tower before starting services.
# Usage: ./scripts/setup-certs.sh
#
# Skips generation if certs already exist.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="${SCRIPT_DIR}/../infra/headscale/certs"
CONFIG_YAML="${SCRIPT_DIR}/../infra/headscale/config/config.yaml"

# Already generated?
if [[ -f "${CERTS_DIR}/ca.crt" && -f "${CERTS_DIR}/headscale.crt" ]]; then
    echo "Certs already exist. Skipping generation."
    echo "  CA:     ${CERTS_DIR}/ca.crt"
    echo "  Server: ${CERTS_DIR}/headscale.crt"
    exit 0
fi

# Load .env
ENV_FILE="${SCRIPT_DIR}/../.env"
if [[ -f "${ENV_FILE}" ]]; then
    set -a; source "${ENV_FILE}"; set +a
fi

# LAN IP: .env의 HEADSCALE_HOST_IP 우선, 없으면 오류
if [[ -z "${HEADSCALE_HOST_IP:-}" ]]; then
    echo "Error: HEADSCALE_HOST_IP is not set." >&2
    echo "  .env 에 HEADSCALE_HOST_IP=<이 장비의 LAN IP> 를 추가하세요." >&2
    exit 1
fi
LAN_IP="${HEADSCALE_HOST_IP}"

# Podman VM gateway IP (192.168.64.1 is default on macOS Podman)
PODMAN_GW=$(ipconfig getifaddr podman1 2>/dev/null || echo "192.168.64.1")

echo "=== Generating headscale TLS certificates ==="
echo "  LAN IP:     ${LAN_IP}"
echo "  Podman GW:  ${PODMAN_GW}"
echo "  Output dir: ${CERTS_DIR}"
echo ""

# 1. Generate server-openssl.cnf with detected IPs
cat > "${CERTS_DIR}/server-openssl.cnf" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
CN = headscale.local

[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = headscale.local
IP.1 = 127.0.0.1
IP.2 = ${PODMAN_GW}
IP.3 = ${LAN_IP}
EOF

# 2. Generate CA key and cert
echo "[1/3] Generating CA..."
openssl genrsa -out "${CERTS_DIR}/ca.key" 4096 2>/dev/null
openssl req -new -x509 -days 3650 \
    -key "${CERTS_DIR}/ca.key" \
    -out "${CERTS_DIR}/ca.crt" \
    -config "${CERTS_DIR}/ca-openssl.cnf"

# 3. Generate server key and CSR
echo "[2/3] Generating server key and CSR..."
openssl genrsa -out "${CERTS_DIR}/headscale.key" 2048 2>/dev/null
openssl req -new \
    -key "${CERTS_DIR}/headscale.key" \
    -out "${CERTS_DIR}/headscale.csr" \
    -config "${CERTS_DIR}/server-openssl.cnf"

# 4. Sign server cert with CA
echo "[3/3] Signing server cert with CA..."
openssl x509 -req -days 825 \
    -in "${CERTS_DIR}/headscale.csr" \
    -CA "${CERTS_DIR}/ca.crt" \
    -CAkey "${CERTS_DIR}/ca.key" \
    -CAcreateserial \
    -out "${CERTS_DIR}/headscale.crt" \
    -extensions v3_req \
    -extfile "${CERTS_DIR}/server-openssl.cnf" 2>/dev/null

# 5. Update server_url in headscale config
if [[ -f "${CONFIG_YAML}" ]]; then
    sed -i.bak "s|server_url:.*|server_url: https://${LAN_IP}:8080|" "${CONFIG_YAML}"
    rm -f "${CONFIG_YAML}.bak"
    echo "  Updated server_url to https://${LAN_IP}:8080 in config.yaml"
fi

echo ""
echo "Done."
echo "  Next: sudo ./scripts/setup-macos-ca.sh"
