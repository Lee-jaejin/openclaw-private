# 모니터링

Private AI System 상태 모니터링 및 알림 설정.

## 모니터링 대상

| 컴포넌트 | 체크 항목 | 임계값 |
|----------|----------|--------|
| Headscale | 프로세스, 포트 443 | 응답 없음 |
| Ollama | 프로세스, 포트 11434 | 응답 없음 |
| OpenClaw | 컨테이너 상태, 포트 18789 | 응답 없음 |
| 시스템 | RAM, CPU, 디스크 | RAM 90%, 디스크 85% |

## 상태 체크 스크립트

### 전체 상태 확인

```bash
#!/bin/bash
# check-status.sh

echo "=== Private AI System Status ==="
echo "시간: $(date)"
echo ""

# Ollama
echo -n "Ollama: "
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
  MODELS=$(curl -s http://localhost:11434/api/tags | jq -r '.models[].name' | wc -l)
  echo "✅ 실행중 (모델 ${MODELS}개)"
else
  echo "❌ 응답 없음"
fi

# Headscale (서버에서)
echo -n "Headscale: "
if curl -s https://headscale.local/health > /dev/null 2>&1; then
  echo "✅ 실행중"
else
  echo "❌ 응답 없음"
fi

# OpenClaw 컨테이너
echo -n "OpenClaw: "
if podman ps | grep -q openclaw; then
  echo "✅ 실행중"
else
  echo "⚪ 중지됨"
fi

# 시스템 리소스
echo ""
echo "=== 시스템 리소스 ==="
echo "RAM: $(vm_stat | awk '/Pages active/ {print $3}' | tr -d '.') pages active"
echo "디스크: $(df -h ~ | tail -1 | awk '{print $5}') 사용"
```

### Ollama 모델 상태

```bash
#!/bin/bash
# ollama-status.sh

echo "=== Ollama 모델 상태 ==="

# 로드된 모델
echo "현재 로드된 모델:"
curl -s http://localhost:11434/api/ps | jq -r '.models[] | "\(.name) - \(.size) bytes"'

# 사용 가능한 모델
echo ""
echo "설치된 모델:"
ollama list
```

## 로그 수집

### 로그 위치

| 컴포넌트 | 로그 위치 |
|----------|----------|
| Headscale | `/var/log/headscale/` |
| Ollama | `~/.ollama/logs/` |
| OpenClaw | 컨테이너 stdout |
| 시스템 | `/var/log/system.log` |

### 로그 확인 명령어

```bash
# Ollama 로그 (macOS)
log show --predicate 'process == "ollama"' --last 1h

# OpenClaw 컨테이너 로그
podman logs openclaw --tail 100

# Headscale 로그
journalctl -u headscale -n 100
```

## 알림 설정

### 간단한 알림 (macOS)

```bash
#!/bin/bash
# alert.sh

check_service() {
  if ! curl -s "$1" > /dev/null 2>&1; then
    osascript -e "display notification \"$2 응답 없음\" with title \"Private AI Alert\""
  fi
}

check_service "http://localhost:11434/api/tags" "Ollama"
check_service "https://headscale.local/health" "Headscale"
```

### cron으로 주기적 체크

```bash
# 5분마다 체크
*/5 * * * * /path/to/alert.sh
```

## 대시보드 (선택)

### 간단한 웹 대시보드

```bash
# btop (터미널 대시보드)
brew install btop
btop

# 또는 htop
brew install htop
htop
```

### Grafana + Prometheus (고급)

복잡한 설정이 필요하므로 나중에 필요 시 구축.

## 체크리스트

- [ ] check-status.sh 배포
- [ ] alert.sh 배포
- [ ] cron 설정
- [ ] 로그 로테이션 설정
