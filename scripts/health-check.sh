#!/bin/bash
# Health check script with exit codes for cron/automation
# Exit 0 = all healthy, Exit 1 = issues found

set -euo pipefail

ISSUES=0
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"

check() {
    local name="$1"
    local result="$2"

    if [[ "$result" == "ok" ]]; then
        echo "[OK] $name"
    else
        echo "[FAIL] $name: $result"
        ISSUES=$((ISSUES + 1))
    fi
}

echo "=== Health Check: $(date) ==="
echo ""

# 1. Headscale
if docker ps --format '{{.Names}}' | grep -q "^headscale$"; then
    STATUS=$(docker inspect --format='{{.State.Status}}' headscale)
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
    check "Tailscale" "not installed"
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
if docker ps --format '{{.Names}}' | grep -q "^openclaw$"; then
    STATUS=$(docker inspect --format='{{.State.Status}}' openclaw)
    if [[ "$STATUS" == "running" ]]; then
        if curl -sf "http://localhost:18789/health" > /dev/null 2>&1; then
            check "OpenClaw" "ok"
        else
            check "OpenClaw" "container running but API not responding"
        fi
    else
        check "OpenClaw" "container status: $STATUS"
    fi
else
    check "OpenClaw" "container not found"
fi

# 6. Disk space (warn if <10GB free)
if [[ "$OSTYPE" == "darwin"* ]]; then
    FREE_GB=$(df -g / | awk 'NR==2 {print $4}')
else
    FREE_GB=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
fi
if [[ "$FREE_GB" -ge 10 ]]; then
    check "Disk Space" "ok (${FREE_GB}GB free)"
else
    check "Disk Space" "low (${FREE_GB}GB free)"
fi

echo ""
if [[ "$ISSUES" -eq 0 ]]; then
    echo "=== All checks passed ==="
    exit 0
else
    echo "=== $ISSUES issue(s) found ==="
    exit 1
fi
