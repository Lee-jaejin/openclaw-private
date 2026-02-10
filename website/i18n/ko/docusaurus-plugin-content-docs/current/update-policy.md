---
id: update-policy
title: 업데이트 정책
sidebar_position: 11
---

# 업데이트 정책

Private AI 시스템 컴포넌트의 버전 관리 및 업데이트 절차입니다.

## 업데이트 일정

| 컴포넌트 | 권장 | 자동화 | 중요도 |
|---------|------|--------|-------|
| Headscale | 월간 | 수동 | 높음 |
| Tailscale 클라이언트 | 자동 | 자동 | 중간 |
| Ollama | 월간 | 수동 | 중간 |
| Ollama 모델 | 필요시 | 수동 | 낮음 |
| OpenClaw 이미지 | 필요시 | 수동 | 중간 |
| macOS/시스템 | 분기 | 수동 | 높음 |

## 업데이트 절차

### Headscale

```bash
# 1. 현재 버전 확인
headscale version

# 2. 먼저 백업
sudo cp /var/lib/headscale/db.sqlite ~/backups/headscale-$(date +%Y%m%d).db

# 3. 업데이트 (패키지 관리자에 따라)
# Debian/Ubuntu
sudo apt update && sudo apt upgrade headscale

# 또는 직접 바이너리
wget https://github.com/juanfont/headscale/releases/latest/download/headscale_linux_amd64
sudo mv headscale_linux_amd64 /usr/local/bin/headscale
sudo chmod +x /usr/local/bin/headscale

# 4. 서비스 재시작
sudo systemctl restart headscale

# 5. 확인
headscale version
sudo systemctl status headscale
```

### Tailscale 클라이언트

```bash
# macOS (자동 업데이트 활성화)
# 수동 업데이트:
brew upgrade tailscale

# App Store 버전은 자동 업데이트
```

### Ollama

```bash
# 1. 현재 버전
ollama --version

# 2. 실행 중인 모델 확인
curl -s http://localhost:11434/api/ps

# 3. 업데이트
brew upgrade ollama

# 4. 서비스 재시작
brew services restart ollama

# 5. 확인
ollama --version
```

### Ollama 모델

```bash
# 새 버전 수동 확인
# https://ollama.com/library

# 모델 업데이트 (같은 이름으로 pull하면 최신 버전)
ollama pull codellama:34b
ollama pull llama3.3:latest

# 이전 버전 정리
ollama list
ollama rm <old-model>
```

### OpenClaw 컨테이너 이미지

```bash
# 1. 소스 업데이트
cd ~/Study/ai/openclaw
git pull origin main

# 2. 이미지 재빌드
podman build -t openclaw:local .

# 3. 이전 이미지 정리
podman image prune
```

## 롤백 절차

### Headscale 롤백

```bash
# 1. 서비스 중지
sudo systemctl stop headscale

# 2. 이전 바이너리 복원 (백업한 경우)
sudo cp ~/backups/headscale-prev /usr/local/bin/headscale

# 3. DB 복원 (필요시)
sudo cp ~/backups/headscale-YYYYMMDD.db /var/lib/headscale/db.sqlite

# 4. 서비스 시작
sudo systemctl start headscale
```

### OpenClaw 롤백

```bash
# 이전 커밋으로 복원
cd ~/Study/ai/openclaw
git checkout <previous-commit>
podman build -t openclaw:local .
```

## 버전 추적

### 버전 확인 스크립트

```bash
#!/bin/bash
# check-versions.sh

echo "=== Private AI 시스템 버전 ==="
echo "날짜: $(date)"
echo ""

echo "Headscale: $(headscale version 2>/dev/null || echo 'N/A')"
echo "Tailscale: $(tailscale version 2>/dev/null | head -1 || echo 'N/A')"
echo "Ollama: $(ollama --version 2>/dev/null || echo 'N/A')"
echo "Podman: $(podman --version 2>/dev/null || echo 'N/A')"
echo ""

echo "Ollama 모델:"
ollama list 2>/dev/null || echo "N/A"
```

## 업데이트 전 체크리스트

- [ ] 백업 완료 확인
- [ ] 현재 버전 기록
- [ ] 변경 로그 확인 (breaking changes)
- [ ] 스테이징에서 테스트 (가능한 경우)
- [ ] 롤백 계획 준비
