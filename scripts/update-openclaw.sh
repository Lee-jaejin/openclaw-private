#!/bin/bash
# Check the latest openclaw version on npm and rebuild the container if a newer version is available.
# Usage: bash scripts/update-openclaw.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

ENV_FILE="${PROJECT_DIR}/.env"
COMPOSE_FILE="${PROJECT_DIR}/infra/openclaw/docker-compose.yml"

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "Error: .env not found. Copy .env.example to .env first." >&2
    exit 1
fi

CURRENT_VERSION=$(grep '^OPENCLAW_VERSION=' "${ENV_FILE}" | cut -d'=' -f2)
if [[ -z "${CURRENT_VERSION}" ]]; then
    echo "Error: OPENCLAW_VERSION not set in .env" >&2
    exit 1
fi

echo "Current version: ${CURRENT_VERSION}"
echo "Checking latest version on npm..."

LATEST_VERSION=$(npm view openclaw version 2>/dev/null || true)
if [[ -z "${LATEST_VERSION}" ]]; then
    echo "Error: Could not fetch latest version from npm. Check network/proxy settings." >&2
    exit 1
fi

echo "Latest version:  ${LATEST_VERSION}"

if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    echo "Already up to date."
    exit 0
fi

NEWER=$(printf '%s\n%s\n' "${CURRENT_VERSION}" "${LATEST_VERSION}" | sort -V | tail -n1)
if [[ "${NEWER}" != "${LATEST_VERSION}" ]]; then
    echo "Installed version ${CURRENT_VERSION} is newer than npm version ${LATEST_VERSION}, nothing to do."
    exit 0
fi

echo "Updating ${CURRENT_VERSION} → ${LATEST_VERSION}"

TMP=$(mktemp)
sed "s/^OPENCLAW_VERSION=.*/OPENCLAW_VERSION=${LATEST_VERSION}/" "${ENV_FILE}" > "${TMP}"
mv "${TMP}" "${ENV_FILE}"
echo "Updated OPENCLAW_VERSION in .env"

podman compose -f "${COMPOSE_FILE}" build --no-cache
podman compose -f "${COMPOSE_FILE}" up -d
echo "openclaw updated to ${LATEST_VERSION}"
