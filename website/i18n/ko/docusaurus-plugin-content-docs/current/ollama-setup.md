---
id: ollama-setup
title: Ollama 설정
sidebar_position: 6
---

# Ollama 설정

로컬 LLM 추론 엔진 설정입니다.

## 설치

### macOS

```bash
brew install ollama
```

### Linux

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### Podman

```bash
cd infra/ollama
podman compose up -d
```

## 모델 다운로드

제공된 스크립트로 설정된 모델을 일괄 다운로드:

```bash
bash infra/ollama/models.sh
```

또는 개별 모델 설치:

```bash
ollama pull <모델명>

# 설치된 모델 확인
ollama list
```

## 설정

### localhost만 바인딩 (권장)

```bash
# 기본값 - localhost만
ollama serve
```

### 네트워크 접근 허용 (VPN 내부)

```bash
# VPN 내부 접근용
OLLAMA_HOST=0.0.0.0 ollama serve
```

### 환경 변수

```bash
# ~/.zshrc 또는 ~/.bashrc
export OLLAMA_HOST=127.0.0.1
export OLLAMA_MODELS=~/.ollama/models
export OLLAMA_KEEP_ALIVE=5m
```

## 메모리 요구사항

현재 모델 목록과 RAM 요구사항은 `infra/ollama/models.sh` 참고. 일반 가이드:

| 모델 크기 | 필요 RAM | 양자화 |
|----------|----------|--------|
| ~7B | 4-6GB | Q4_K_M |
| ~14B | 8-10GB | Q4_K_M |
| ~20B | 12-14GB | Q4_K_M |
| ~34B | 20GB+ | Q4_K_M |
| ~70B | 40GB+ | Q4_K_M |

## API 사용

### 사용 가능한 모델 확인

```bash
curl http://localhost:11434/api/tags
```

### 응답 생성

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "<모델명>",
  "prompt": "안녕하세요, 잘 지내시나요?"
}'
```

### 채팅 API

```bash
curl http://localhost:11434/api/chat -d '{
  "model": "<모델명>",
  "messages": [
    {"role": "user", "content": "리스트를 정렬하는 Python 함수를 작성해줘"}
  ]
}'
```

## 문제 해결

### 모델 로드 안 됨

```bash
# 실행 중인 모델 확인
curl http://localhost:11434/api/ps

# 디스크 공간 확인
df -h ~/.ollama

# 제거 후 재다운로드
ollama rm <모델명>
ollama pull <모델명>
```

### 메모리 부족

```bash
# 더 작은 양자화 사용
ollama pull <모델명>-q4_0

# 또는 config/openclaw.json에서 더 작은 모델로 변경
```

### 추론 느림

- GPU 가속 활성화 확인
- Activity Monitor에서 메모리 압력 확인
- 양자화된 모델 사용 고려
