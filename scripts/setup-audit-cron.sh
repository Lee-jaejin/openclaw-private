#!/bin/bash
# Install/refresh a cron entry that runs egress audit every 15 minutes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUT_DIR="$PROJECT_DIR/logs/audit"
CRON_LOG="$OUT_DIR/cron.log"
JOB="*/15 * * * * cd \"$PROJECT_DIR\" && bash \"$PROJECT_DIR/scripts/audit-egress.sh\" --window 15 >> \"$CRON_LOG\" 2>&1"

mkdir -p "$OUT_DIR"

TMP_CRON="$(mktemp)"
trap 'rm -f "$TMP_CRON"' EXIT

crontab -l 2>/dev/null | grep -v "scripts/audit-egress.sh" > "$TMP_CRON" || true
echo "$JOB" >> "$TMP_CRON"
crontab "$TMP_CRON"

echo "Installed cron job:"
echo "$JOB"
