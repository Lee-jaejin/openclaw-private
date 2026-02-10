---
id: troubleshooting
title: 문제 해결
sidebar_position: 12
---

# 문제 해결

Private AI 시스템의 일반적인 문제와 해결책입니다.

## 네트워크 문제

### Tailscale 연결 안 됨

```bash
# Headscale 서버 상태 확인
headscale nodes list

# Tailscale 재시작
sudo tailscale down
sudo tailscale up --login-server https://your-headscale-server

# 로그 확인
journalctl -u tailscaled -f
```

### 기기 간 통신 안 됨

```bash
# 양쪽 기기 연결 상태 확인
tailscale status

# ACL 설정 확인
cat /etc/headscale/acl.json

# 연결 테스트
tailscale ping <other-device-ip>
```

## Ollama 문제

### 모델 로드 안 됨

```bash
# 사용 가능한 메모리 확인
free -h

# 모델 상태 확인
curl http://localhost:11434/api/ps

# 더 작은 양자화 시도
ollama pull codellama:34b-q4_0

# 디스크 공간 확인
df -h ~/.ollama
```

### 추론 느림

- Activity Monitor에서 메모리 압력 확인
- 다른 무거운 프로세스가 없는지 확인
- 더 작은 모델 사용 고려
- GPU 가속 확인 (해당되는 경우)

### 연결 거부됨

```bash
# Ollama 실행 중인지 확인
ps aux | grep ollama

# Ollama 시작
ollama serve

# 바인딩 주소 확인
lsof -i :11434
```

## OpenClaw 컨테이너 문제

### 컨테이너 시작 안 됨

```bash
# 컨테이너 로그 확인
podman logs openclaw

# 이미지 존재 확인
podman images | grep openclaw

# 필요시 재빌드
podman build -t openclaw:local .
```

### 컨테이너에서 Ollama 연결 안 됨

```bash
# 컨테이너 내부에서 테스트
podman exec openclaw curl http://host.containers.internal:11434/api/tags

# Podman 네트워크 확인
podman network ls

# docker-compose.yml에서 extra_hosts 확인
```

### 권한 거부됨

```bash
# 볼륨 권한 확인
podman exec openclaw ls -la /home/node/.openclaw

# 소유권 수정
podman exec -u root openclaw chown -R node:node /home/node/.openclaw

# 컨테이너 재시작
podman compose restart openclaw
```

## 모바일 문제

### 모바일에서 VPN 느림

```bash
# DERP 릴레이 사용 중인지 확인
tailscale netcheck

# 같은 네트워크면 직접 연결
# 다른 네트워크면 DERP 사용
```

### 배터리 소모

- iOS: Tailscale의 백그라운드 앱 새로 고침 활성화
- Android: Tailscale을 배터리 최적화에서 제외
- 사용하지 않을 때는 연결 해제 고려

## 일반 디버깅

### 시스템 상태 확인

```bash
# 전체 상태 확인
./scripts/check-status.sh

# 또는 수동으로:
tailscale status
curl http://localhost:11434/api/tags
podman ps
curl http://localhost:18789/health
```

### 로그 수집

```bash
# Headscale 로그
podman logs headscale > ~/logs/headscale.log

# Ollama 로그
journalctl -u ollama > ~/logs/ollama.log

# OpenClaw 로그
podman logs openclaw > ~/logs/openclaw.log

# Tailscale 로그
sudo tailscale bugreport > ~/logs/tailscale-bugreport.txt
```

### 전체 초기화

```bash
# 모든 서비스 중지
podman compose down
sudo tailscale down
pkill ollama

# 데이터 삭제 (주의!)
rm -rf ~/.ollama/models/*
podman volume rm openclaw-config openclaw-sessions

# 새로 시작
./scripts/setup-all.sh
```

## 도움 받기

1. 이 문제 해결 가이드 확인
2. 컴포넌트 로그 검토
3. GitHub 이슈 검색
4. 새 이슈 생성 시 포함할 내용:
   - 시스템 정보 (OS, RAM, CPU)
   - 컴포넌트 버전
   - 에러 메시지
   - 재현 단계
