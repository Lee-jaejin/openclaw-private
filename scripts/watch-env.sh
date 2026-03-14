#!/bin/bash
# Watch .env for changes and restart openclaw to apply.
# Polls every 2 seconds using file checksum.
# Usage: bash scripts/watch-env.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
ENV_FILE="${PROJECT_DIR}/.env"

checksum() {
    if command -v md5 &>/dev/null; then
        md5 -q "${ENV_FILE}"
    else
        md5sum "${ENV_FILE}" | cut -d' ' -f1
    fi
}

restart_openclaw() {
    if ! podman ps --format '{{.Names}}' | grep -q '^openclaw$'; then
        echo "[$(date '+%H:%M:%S')] .env changed — openclaw not running, skipping."
        return
    fi
    echo "[$(date '+%H:%M:%S')] .env changed — restarting openclaw..."
    podman compose -f "${PROJECT_DIR}/docker-compose.yml" up -d openclaw
    echo "[$(date '+%H:%M:%S')] Done."
}

echo "Watching ${ENV_FILE} (Ctrl-C to stop)"
LAST="$(checksum)"

while true; do
    sleep 2
    CURRENT="$(checksum)"
    if [[ "${CURRENT}" != "${LAST}" ]]; then
        LAST="${CURRENT}"
        restart_openclaw
    fi
done
