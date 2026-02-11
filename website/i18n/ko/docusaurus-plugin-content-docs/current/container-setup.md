---
id: container-setup
title: 컨테이너 설정
sidebar_position: 7
---

# OpenClaw 컨테이너 설정

AI 게이트웨이를 위한 격리된 컨테이너 설정입니다.

## Podman Compose

`infra/openclaw/docker-compose.yml`:

```yaml
version: "3.8"

services:
  openclaw:
    image: openclaw:local
    container_name: openclaw
    restart: unless-stopped
    ports:
      - "18789:18789"
    environment:
      - OLLAMA_HOST=http://host.containers.internal:11434
      - NODE_ENV=production
    volumes:
      - openclaw-config:/home/node/.openclaw
      - openclaw-sessions:/home/node/.openclaw/sessions
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    extra_hosts:
      - "host.containers.internal:host-gateway"

volumes:
  openclaw-config:
  openclaw-sessions:
```

## 이미지 빌드

```bash
# 프로젝트 루트에서
podman build -t openclaw:local -f infra/openclaw/Dockerfile .

# 또는 스크립트 사용
./scripts/build-container.sh
```

## 보안 설정

### 권한 제한

```yaml
security_opt:
  - no-new-privileges:true
cap_drop:
  - ALL
```

### 볼륨 마운트

필요한 디렉토리만 마운트:

```yaml
volumes:
  - openclaw-config:/home/node/.openclaw:rw
  - /path/to/workspace:/workspace:ro  # 가능하면 읽기 전용
```

### 네트워크 격리

최대 격리를 위해:

```yaml
networks:
  openclaw-net:
    driver: bridge
    internal: true  # 외부 접근 불가
```

## 설정

### OpenClaw 설정

`config/openclaw.json`:

현재 설정은 `config/openclaw.json` 참고. 주요 항목:

- `agents.defaults.model.primary` — 기본 모델
- `agents.defaults.model.fallbacks` — 대체 모델
- `models.providers.ollama.baseUrl` — Ollama 엔드포인트

## 실행

```bash
# 컨테이너 시작
podman compose up -d

# 로그 확인
podman logs -f openclaw

# 중지
podman compose down
```

## 헬스 체크

```bash
# 컨테이너 상태 확인
podman ps

# API 헬스 확인
curl http://localhost:18789/health

# 컨테이너에서 Ollama 연결 확인
podman exec openclaw curl http://host.containers.internal:11434/api/tags
```

## 문제 해결

### Ollama에 연결 안 됨

```bash
# host.containers.internal 해석 확인
podman exec openclaw ping host.containers.internal

# Ollama가 리스닝 중인지 확인
curl http://localhost:11434/api/tags
```

### 권한 거부됨

```bash
# 볼륨 권한 확인
podman exec openclaw ls -la /home/node/.openclaw

# 필요시 소유권 수정
podman exec -u root openclaw chown -R node:node /home/node/.openclaw
```
