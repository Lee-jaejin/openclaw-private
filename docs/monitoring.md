# Monitoring

Status monitoring and alerting for Private AI System.

## Monitoring Targets

| Component | Check Items | Threshold |
|-----------|-------------|-----------|
| Headscale | Process, port 443 | No response |
| Ollama | Process, port 11434 | No response |
| OpenClaw | Container status, port 18789 | No response |
| System | RAM, CPU, Disk | RAM 90%, Disk 85% |

## Status Check Scripts

### Full Status Check

```bash
#!/bin/bash
# check-status.sh

echo "=== Private AI System Status ==="
echo "Time: $(date)"
echo ""

# Ollama
echo -n "Ollama: "
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
  MODELS=$(curl -s http://localhost:11434/api/tags | jq -r '.models[].name' | wc -l)
  echo "✅ Running (${MODELS} models)"
else
  echo "❌ No response"
fi

# Headscale (on server)
echo -n "Headscale: "
if curl -s https://headscale.local/health > /dev/null 2>&1; then
  echo "✅ Running"
else
  echo "❌ No response"
fi

# OpenClaw container
echo -n "OpenClaw: "
if docker ps | grep -q openclaw; then
  echo "✅ Running"
else
  echo "⚪ Stopped"
fi

# System resources
echo ""
echo "=== System Resources ==="
echo "RAM: $(vm_stat | awk '/Pages active/ {print $3}' | tr -d '.') pages active"
echo "Disk: $(df -h ~ | tail -1 | awk '{print $5}') used"
```

### Ollama Model Status

```bash
#!/bin/bash
# ollama-status.sh

echo "=== Ollama Model Status ==="

# Loaded models
echo "Currently loaded:"
curl -s http://localhost:11434/api/ps | jq -r '.models[] | "\(.name) - \(.size) bytes"'

# Available models
echo ""
echo "Installed models:"
ollama list
```

## Log Collection

### Log Locations

| Component | Log Location |
|-----------|--------------|
| Headscale | `/var/log/headscale/` |
| Ollama | `~/.ollama/logs/` |
| OpenClaw | Container stdout |
| System | `/var/log/system.log` |

### Log Commands

```bash
# Ollama logs (macOS)
log show --predicate 'process == "ollama"' --last 1h

# OpenClaw container logs
docker logs openclaw --tail 100

# Headscale logs
journalctl -u headscale -n 100
```

## Alert Setup

### Simple Alerts (macOS)

```bash
#!/bin/bash
# alert.sh

check_service() {
  if ! curl -s "$1" > /dev/null 2>&1; then
    osascript -e "display notification \"$2 not responding\" with title \"Private AI Alert\""
  fi
}

check_service "http://localhost:11434/api/tags" "Ollama"
check_service "https://headscale.local/health" "Headscale"
```

### Periodic Checks with cron

```bash
# Check every 5 minutes
*/5 * * * * /path/to/alert.sh
```

## Dashboard (Optional)

### Simple Terminal Dashboard

```bash
# btop (terminal dashboard)
brew install btop
btop

# or htop
brew install htop
htop
```

### Grafana + Prometheus (Advanced)

Requires complex setup - implement when needed.

## Checklist

- [ ] Deploy check-status.sh
- [ ] Deploy alert.sh
- [ ] Configure cron
- [ ] Set up log rotation

---

## 한국어 (Korean)

### 모니터링 대상
- Headscale: 프로세스, 포트 443
- Ollama: 프로세스, 포트 11434
- OpenClaw: 컨테이너 상태
- 시스템: RAM, CPU, 디스크
