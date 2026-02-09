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

### Docker

```bash
cd infra/ollama
docker-compose up -d
```

## 모델 다운로드

```bash
# 코딩 작업용 CodeLlama
ollama pull codellama:34b

# 일반 및 추론용 Llama 3.3
ollama pull llama3.3:latest

# 선택: RAM 제한 시 더 가벼운 모델
ollama pull codellama:13b
ollama pull llama3.2:latest
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

| 모델 | 필요 RAM | 양자화 |
|-----|----------|--------|
| CodeLlama 34B | 20GB+ | Q4_K_M |
| Llama 3.3 70B | 40GB+ | Q4_K_M |
| Llama 3.3 8B | 6GB+ | Q4_K_M |
| CodeLlama 13B | 10GB+ | Q4_K_M |

## API 사용

### 사용 가능한 모델 확인

```bash
curl http://localhost:11434/api/tags
```

### 응답 생성

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.3",
  "prompt": "안녕하세요, 잘 지내시나요?"
}'
```

### 채팅 API

```bash
curl http://localhost:11434/api/chat -d '{
  "model": "codellama:34b",
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
ollama rm codellama:34b
ollama pull codellama:34b
```

### 메모리 부족

```bash
# 더 작은 양자화 사용
ollama pull codellama:34b-q4_0

# 또는 더 작은 모델 사용
ollama pull codellama:13b
```

### 추론 느림

- GPU 가속 활성화 확인
- Activity Monitor에서 메모리 압력 확인
- 양자화된 모델 사용 고려
