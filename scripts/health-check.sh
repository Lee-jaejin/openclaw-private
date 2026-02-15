#!/bin/bash
# Health check script with exit codes for cron/automation
# Exit 0 = all healthy, Exit 1 = issues found

set -uo pipefail

ISSUES=0
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
AUDIT_LATEST_REPORT="${AUDIT_LATEST_REPORT:-$PROJECT_DIR/logs/audit/latest.md}"
AUDIT_MAX_AGE_MIN="${AUDIT_MAX_AGE_MIN:-90}"

check() {
    local name="$1"
    local result="$2"

    if [[ "$result" == ok* ]]; then
        echo "[OK] $name${result:2}"
    elif [[ "$result" == skip:* ]]; then
        echo "[SKIP] $name: ${result#skip:}"
    else
        echo "[FAIL] $name: $result"
        ISSUES=$((ISSUES + 1))
    fi
}

echo "=== Health Check: $(date) ==="
echo ""

# 1. Headscale
if podman ps --format '{{.Names}}' | grep -q "^headscale$"; then
    STATUS=$(podman inspect --format='{{.State.Status}}' headscale)
    if [[ "$STATUS" == "running" ]]; then
        check "Headscale" "ok"
    else
        check "Headscale" "container status: $STATUS"
    fi
else
    check "Headscale" "container not found"
fi

# 2. Tailscale connectivity
if command -v tailscale &> /dev/null; then
    TS_STATUS=$(tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null || echo "error")
    if [[ "$TS_STATUS" == "Running" ]]; then
        check "Tailscale" "ok"
    else
        check "Tailscale" "status: $TS_STATUS"
    fi
else
    check "Tailscale" "skip:not installed"
fi

# 3. Ollama API
if curl -sf "$OLLAMA_HOST/api/tags" > /dev/null 2>&1; then
    check "Ollama API" "ok"
else
    check "Ollama API" "not responding at $OLLAMA_HOST"
fi

# 4. Ollama models available
MODEL_COUNT=$(curl -s "$OLLAMA_HOST/api/tags" 2>/dev/null | jq '.models | length' 2>/dev/null || echo "0")
if [[ "$MODEL_COUNT" -gt 0 ]]; then
    check "Ollama Models" "ok ($MODEL_COUNT available)"
else
    check "Ollama Models" "no models found"
fi

# 5. OpenClaw container
if podman ps -a --format '{{.Names}}' | grep -q "^openclaw$"; then
    STATUS=$(podman inspect --format='{{.State.Status}}' openclaw 2>/dev/null || echo "unknown")
    if [[ "$STATUS" == "running" ]]; then
        # OpenClaw gateway uses WebSocket — check TCP port connectivity
        if (echo > /dev/tcp/localhost/18789) 2>/dev/null; then
            check "OpenClaw" "ok (gateway ws://localhost:18789)"
        else
            check "OpenClaw" "container running but port 18789 not reachable"
        fi
    elif [[ "$STATUS" == "exited" ]]; then
        EXIT_CODE=$(podman inspect --format='{{.State.ExitCode}}' openclaw 2>/dev/null || echo "?")
        check "OpenClaw" "exited (code: $EXIT_CODE)"
    else
        check "OpenClaw" "container status: $STATUS"
    fi
else
    check "OpenClaw" "container not found"
fi

# 6. Egress proxy container
if podman ps --format '{{.Names}}' | grep -q "^egress-proxy$"; then
    check "Egress Proxy" "ok"
else
    check "Egress Proxy" "container not running"
fi

# 7. Egress audit freshness
if [[ -f "$AUDIT_LATEST_REPORT" ]]; then
    NOW_EPOCH=$(date +%s)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        FILE_EPOCH=$(stat -f %m "$AUDIT_LATEST_REPORT" 2>/dev/null || echo 0)
    else
        FILE_EPOCH=$(stat -c %Y "$AUDIT_LATEST_REPORT" 2>/dev/null || echo 0)
    fi

    if [[ "$FILE_EPOCH" -gt 0 ]]; then
        AGE_MIN=$(( (NOW_EPOCH - FILE_EPOCH) / 60 ))
        if [[ "$AGE_MIN" -le "$AUDIT_MAX_AGE_MIN" ]]; then
            check "Egress Audit" "ok (latest report ${AGE_MIN}m ago)"
        else
            check "Egress Audit" "latest report too old (${AGE_MIN}m ago)"
        fi
    else
        check "Egress Audit" "unable to read report timestamp"
    fi
else
    check "Egress Audit" "report not found at $AUDIT_LATEST_REPORT"
fi

# 8. Disk space (warn if <10GB free)
if [[ "$OSTYPE" == "darwin"* ]]; then
    FREE_GB=$(df -g / | awk 'NR==2 {print $4}')
else
    FREE_GB=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
fi
if [[ -n "$FREE_GB" ]] && [[ "$FREE_GB" -ge 10 ]] 2>/dev/null; then
    check "Disk Space" "ok (${FREE_GB}GB free)"
elif [[ -n "$FREE_GB" ]]; then
    check "Disk Space" "low (${FREE_GB}GB free)"
else
    check "Disk Space" "unable to determine"
fi

echo ""
if [[ "$ISSUES" -eq 0 ]]; then
    echo "=== All checks passed ==="
    exit 0
else
    echo "=== $ISSUES issue(s) found ==="
    exit 1
fi
