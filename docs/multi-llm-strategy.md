# 멀티 LLM 전략

작업 유형별 최적 모델 선택 및 fallback 설정.

## 개요

```
┌─────────────────────────────────────────────────────────┐
│                    요청 입력                             │
└─────────────────────┬───────────────────────────────────┘
                      ▼
              ┌───────────────┐
              │  작업 분류기   │
              └───────┬───────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   ┌─────────┐   ┌─────────┐   ┌─────────┐
   │  코딩   │   │  추론   │   │  일반   │
   │  Qwen   │   │DeepSeek │   │  Llama  │
   └────┬────┘   └────┬────┘   └────┬────┘
        │             │             │
        └─────────────┼─────────────┘
                      ▼
              ┌───────────────┐
              │   응답 출력    │
              └───────────────┘
```

## 모델 역할 분담

| 모델 | 용도 | 강점 |
|------|------|------|
| **Qwen 2.5 Coder 32B** | 코딩, 코드 리뷰, 디버깅 | 코드 수정 정확도 최상 |
| **DeepSeek R1 32B** | 논리 추론, 수학, 분석 | 단계별 사고 |
| **Llama 3.3** | 일반 대화, 요약, 번역 | 범용성 |

## OpenClaw 설정

### 기본 구성 (Primary + Fallbacks)

이 레포에서는 `config/openclaw.json`이 컨테이너에 마운트됩니다. 아래는 예시이며, 실제 primary/fallbacks는 해당 파일을 참고하세요.

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/qwen2.5-coder:32b",
        "fallbacks": [
          "ollama/deepseek-r1:32b",
          "ollama/llama3.3:latest"
        ]
      }
    }
  },
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://host.containers.internal:11434/v1"
      }
    }
  }
}
```

### 작업별 에이전트 설정

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/llama3.3:latest"
      }
    },
    "profiles": {
      "coder": {
        "model": {
          "primary": "ollama/qwen2.5-coder:32b",
          "fallbacks": ["ollama/deepseek-r1:32b"]
        }
      },
      "reasoner": {
        "model": {
          "primary": "ollama/deepseek-r1:32b",
          "fallbacks": ["ollama/qwen2.5-coder:32b"]
        }
      }
    }
  }
}
```

## CLI로 모델 전환

```bash
# 현재 모델 확인
node /app/dist/index.js models list

# 코딩 모델로 전환
node /app/dist/index.js models set ollama/qwen2.5-coder:32b

# 추론 모델로 전환
node /app/dist/index.js models set ollama/deepseek-r1:32b

# 범용 모델로 전환
node /app/dist/index.js models set ollama/llama3.3:latest
```

## 자동 라우팅 전략 (향후 구현)

### 키워드 기반 라우팅

| 키워드 | 라우팅 모델 |
|--------|------------|
| `코드`, `함수`, `버그`, `리팩토링` | Qwen Coder |
| `왜`, `분석`, `비교`, `논리` | DeepSeek R1 |
| 그 외 | Llama 3.3 |

### 구현 예시 (telmeet 플러그인)

```typescript
function selectModel(message: string): string {
  const codingKeywords = ['코드', 'code', 'function', 'bug', 'debug', 'refactor'];
  const reasoningKeywords = ['왜', 'why', 'analyze', 'compare', 'logic', '분석'];

  const lowerMessage = message.toLowerCase();

  if (codingKeywords.some(kw => lowerMessage.includes(kw))) {
    return 'ollama/qwen2.5-coder:32b';
  }

  if (reasoningKeywords.some(kw => lowerMessage.includes(kw))) {
    return 'ollama/deepseek-r1:32b';
  }

  return 'ollama/llama3.3:latest';
}
```

## Fallback 동작

```
요청 → Primary 모델 시도
           │
           ├── 성공 → 응답 반환
           │
           └── 실패 (타임아웃/에러)
                  │
                  ▼
           Fallback[0] 시도
                  │
                  ├── 성공 → 응답 반환
                  │
                  └── 실패 → Fallback[1] 시도...
```

### Fallback 트리거 조건

- 모델 응답 타임아웃 (기본 120초)
- Ollama 서버 연결 실패
- 메모리 부족 (OOM)
- 모델 로드 실패

## 리소스 관리

### M3 Pro 36GB 동시 실행 제한

| 시나리오 | 가능 여부 |
|----------|----------|
| 32B 모델 1개 | ✅ 여유 |
| 32B + 8B 동시 | ⚠️ 빠듯 |
| 32B 2개 동시 | ❌ 불가 |

### 모델 언로드 전략

```bash
# 현재 로드된 모델 확인
curl http://localhost:11434/api/ps

# 특정 모델 언로드 (메모리 해제)
curl http://localhost:11434/api/delete -d '{"name":"qwen2.5-coder:32b"}'
```

### Ollama 설정 (keep_alive)

```bash
# 모델 자동 언로드 시간 (기본 5분)
OLLAMA_KEEP_ALIVE=5m ollama serve

# 즉시 언로드 (메모리 절약)
OLLAMA_KEEP_ALIVE=0 ollama serve
```

## 성능 모니터링

### 응답 시간 벤치마크 (예상)

| 모델 | 첫 토큰 | 생성 속도 |
|------|---------|----------|
| Qwen 2.5 Coder 32B | 2-3초 | 10-15 tok/s |
| DeepSeek R1 32B | 2-3초 | 10-15 tok/s |
| Llama 3.3 8B | 0.5초 | 25-30 tok/s |

### 모니터링 스크립트

```bash
#!/bin/bash
# monitor-models.sh

while true; do
  echo "=== $(date) ==="

  # Ollama 상태
  curl -s http://localhost:11434/api/ps | jq '.models[] | {name, size, expires_at}'

  # 메모리 사용량
  vm_stat | grep "Pages active"

  sleep 30
done
```

## 체크리스트

- [x] 모델 역할 정의
- [x] OpenClaw fallback 설정 방법
- [x] CLI 전환 명령어
- [x] 자동 라우팅 전략 설계
- [ ] telmeet 플러그인에 라우팅 로직 구현
- [ ] 모니터링 대시보드 구축
- [ ] 성능 벤치마크 실측
