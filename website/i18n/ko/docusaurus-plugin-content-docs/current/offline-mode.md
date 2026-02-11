---
id: offline-mode
title: 오프라인 모드
sidebar_position: 10
---

# 오프라인 모드

인터넷 접근 없이 Private AI 시스템을 운영하는 방법입니다.

## 오프라인 지원 범위

| 컴포넌트 | 오프라인 | 요구사항 |
|---------|---------|----------|
| Ollama | ✅ 가능 | 모델 사전 다운로드 |
| OpenClaw | ✅ 가능 | 이미지 사전 빌드 |
| Headscale | ⚠️ 부분 | 초기 설정 후 |
| Tailscale | ⚠️ 부분 | P2P 직접 연결 |

## 준비 (온라인 상태에서)

### 1. Ollama 모델 다운로드

```bash
# 필요한 모든 모델 다운로드
bash infra/ollama/models.sh

# 다운로드 확인
ollama list
```

### 2. OpenClaw 이미지 빌드

```bash
cd ~/Study/ai/openclaw
podman build -t openclaw:local .

# 이미지 저장 (백업용)
podman save openclaw:local -o ~/backups/openclaw-local.tar
```

### 3. 의존성 캐시

```bash
# npm 패키지 캐시 (필요시)
cd ~/Study/ai/openclaw
pnpm install --offline
```

## 오프라인 실행

### 완전 로컬 모드 (단일 기기)

```bash
# 1. Ollama 시작
ollama serve

# 2. OpenClaw 실행 (네트워크 격리)
podman run -it --rm --name openclaw-isolated \
  --network none \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  -v ~/config:/home/node/.openclaw:rw \
  -v ~/workspace:/workspace:rw \
  -e HOME=/home/node \
  openclaw:local \
  bash
```

### 로컬 네트워크 모드 (여러 기기)

Headscale 없이 직접 연결:

```bash
# 기기 A (서버)
ollama serve --host 0.0.0.0

# 기기 B (클라이언트)
export OLLAMA_HOST=http://192.168.1.100:11434
```

### P2P VPN (Tailscale 직접)

이미 연결된 기기는 Headscale 없이 통신 가능:

```bash
# 기존 연결 확인
tailscale status

# 직접 연결은 코디네이터 불필요
# (하지만 새 기기 추가 불가)
```

## 설정 (오프라인)

`config/openclaw.json`:

현재 모델 설정은 `config/openclaw.json` 참고. 오프라인에서는 `baseUrl`이 로컬 Ollama를 가리키는지 확인:

```json
{
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://localhost:11434/v1"
      }
    }
  }
}
```

## 제한사항

### 오프라인에서 안 되는 것

| 기능 | 이유 | 대안 |
|-----|------|------|
| 모델 다운로드 | 인터넷 필요 | 사전 다운로드 |
| 클라우드 API | 클라우드 서비스 | 로컬 LLM |
| 새 기기 등록 | Headscale 필요 | 사전 등록 |
| 웹 검색 | 인터넷 필요 | 로컬 문서 |

### 성능 고려사항

- 로컬 LLM은 클라우드보다 느림
- 충분한 RAM 확보 필요
- 첫 추론은 모델 로드 시간 있음

## 비상 대응

### 인터넷이 끊겼을 때

```bash
# 1. 현재 상태 확인
ollama list
podman images

# 2. 로컬 모드로 전환
# openclaw.json에서 fallback 비활성화

# 3. 오프라인 작업 계속
```

### 복구 후

```bash
# 1. 연결 확인
ping 8.8.8.8

# 2. 모델 업데이트 (선택)
bash infra/ollama/models.sh

# 3. 정상 모드로 복귀
```
