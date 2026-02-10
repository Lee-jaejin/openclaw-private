#!/bin/bash
# Monitoring script for Private AI System
# Checks: Headscale, Tailscale, Ollama, OpenClaw

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Private AI System Monitor ==="
echo "Time: $(date)"
echo ""

# 1. Headscale status
echo ">>> Headscale"
if podman ps --format '{{.Names}}' | grep -q "^headscale$"; then
    HEADSCALE_STATUS=$(podman inspect --format='{{.State.Status}}' headscale)
    if [[ "$HEADSCALE_STATUS" == "running" ]]; then
        echo -e "    Status: ${GREEN}Running${NC}"
        NODE_COUNT=$(podman exec headscale headscale nodes list 2>/dev/null | tail -n +2 | wc -l || echo "0")
        echo "    Nodes: $NODE_COUNT"
    else
        echo -e "    Status: ${RED}$HEADSCALE_STATUS${NC}"
    fi
else
    echo -e "    Status: ${RED}Not running${NC}"
fi
echo ""

# 2. Tailscale status
echo ">>> Tailscale"
if command -v tailscale &> /dev/null; then
    TS_STATUS=$(tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null || echo "Unknown")
    if [[ "$TS_STATUS" == "Running" ]]; then
        echo -e "    Status: ${GREEN}Connected${NC}"
        TS_IP=$(tailscale ip -4 2>/dev/null || echo "N/A")
        echo "    IP: $TS_IP"
    else
        echo -e "    Status: ${YELLOW}$TS_STATUS${NC}"
    fi
else
    echo -e "    Status: ${RED}Not installed${NC}"
fi
echo ""

# 3. Ollama status
echo ">>> Ollama"
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
if curl -s "$OLLAMA_HOST/api/tags" > /dev/null 2>&1; then
    echo -e "    Status: ${GREEN}Running${NC}"

    # Loaded models
    LOADED=$(curl -s "$OLLAMA_HOST/api/ps" 2>/dev/null | jq -r '.models[].name' 2>/dev/null || echo "None")
    if [[ -n "$LOADED" && "$LOADED" != "None" ]]; then
        echo "    Loaded: $LOADED"
    else
        echo "    Loaded: None"
    fi

    # Model count
    MODEL_COUNT=$(curl -s "$OLLAMA_HOST/api/tags" 2>/dev/null | jq '.models | length' 2>/dev/null || echo "0")
    echo "    Models: $MODEL_COUNT"
else
    echo -e "    Status: ${RED}Not running${NC}"
fi
echo ""

# 4. OpenClaw status
echo ">>> OpenClaw"
if podman ps --format '{{.Names}}' | grep -q "^openclaw$"; then
    OC_STATUS=$(podman inspect --format='{{.State.Status}}' openclaw)
    if [[ "$OC_STATUS" == "running" ]]; then
        echo -e "    Status: ${GREEN}Running${NC}"
        OC_HEALTH=$(curl -sf "http://localhost:18789/health" 2>/dev/null && echo "healthy" || echo "unhealthy")
        echo "    API: $OC_HEALTH"
        OC_UPTIME=$(podman inspect --format='{{.State.StartedAt}}' openclaw 2>/dev/null | cut -d'.' -f1 | tr 'T' ' ')
        echo "    Since: $OC_UPTIME"
    else
        echo -e "    Status: ${YELLOW}$OC_STATUS${NC}"
    fi
else
    echo -e "    Status: ${RED}Not running${NC}"
fi
echo ""

# 5. System resources
echo ">>> System Resources"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    MEM_USED=$(vm_stat | awk '/Pages active/ {print $3}' | tr -d '.')
    MEM_TOTAL=$(sysctl -n hw.memsize)
    MEM_PERCENT=$((MEM_USED * 4096 * 100 / MEM_TOTAL))
    echo "    Memory: ~${MEM_PERCENT}% used"

    CPU_USAGE=$(top -l 1 | grep "CPU usage" | awk '{print $3}')
    echo "    CPU: $CPU_USAGE"
else
    # Linux
    MEM_INFO=$(free -m | awk '/Mem:/ {printf "%.0f%%", $3/$2*100}')
    echo "    Memory: $MEM_INFO used"

    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    echo "    CPU: ${CPU_USAGE}%"
fi
echo ""

echo "=== Monitor Complete ==="
