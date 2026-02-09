# Multi-LLM Strategy

Optimal model selection and fallback configuration by task type.

## Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Request Input                         │
└─────────────────────┬───────────────────────────────────┘
                      ▼
              ┌───────────────┐
              │ Task Classifier│
              └───────┬───────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   ┌─────────┐   ┌─────────┐   ┌─────────┐
   │ Coding  │   │Reasoning│   │ General │
   │CodeLlama│   │ Llama   │   │ Llama   │
   └────┬────┘   └────┬────┘   └────┬────┘
        │             │             │
        └─────────────┼─────────────┘
                      ▼
              ┌───────────────┐
              │ Response Output│
              └───────────────┘
```

## Model Role Assignment

| Model | Purpose | Strength |
|-------|---------|----------|
| **CodeLlama 34B** | Coding, code review, debugging | Code-specialized training |
| **Llama 3.3 70B** | Logical reasoning, math, analysis | High-performance general |
| **Llama 3.3** | General chat, summarization, translation | Versatility |

> **Note:** All models are from the Llama family, ensuring consistent response style and license management.

## OpenClaw Configuration

### Basic Setup (Primary + Fallbacks)

`config/openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/llama3.3:latest",
        "fallbacks": [
          "ollama/codellama:34b",
          "ollama/llama3.2:latest"
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

### Task-specific Agent Profiles

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
          "primary": "ollama/codellama:34b",
          "fallbacks": ["ollama/llama3.3:latest"]
        }
      },
      "reasoner": {
        "model": {
          "primary": "ollama/llama3.3:70b",
          "fallbacks": ["ollama/llama3.3:latest"]
        }
      }
    }
  }
}
```

## CLI Model Switching

```bash
# Check current model
openclaw models list

# Switch to coding model
openclaw models set ollama/codellama:34b

# Switch to high-performance model
openclaw models set ollama/llama3.3:70b

# Switch to general model
openclaw models set ollama/llama3.3:latest
```

## Auto-Routing Strategy

### Keyword-based Routing

| Keywords | Routed Model |
|----------|--------------|
| `code`, `function`, `bug`, `refactor` | CodeLlama 34B |
| `why`, `analyze`, `compare`, `logic` | Llama 3.3 70B |
| Others | Llama 3.3 |

### Implementation Example (model-router plugin)

```typescript
function selectModel(message: string): string {
  const codingKeywords = ['code', 'function', 'bug', 'debug', 'refactor'];
  const reasoningKeywords = ['why', 'analyze', 'compare', 'logic'];

  const lowerMessage = message.toLowerCase();

  if (codingKeywords.some(kw => lowerMessage.includes(kw))) {
    return 'ollama/codellama:34b';
  }

  if (reasoningKeywords.some(kw => lowerMessage.includes(kw))) {
    return 'ollama/llama3.3:70b';
  }

  return 'ollama/llama3.3:latest';
}
```

## Fallback Behavior

```
Request → Try Primary Model
              │
              ├── Success → Return Response
              │
              └── Failure (timeout/error)
                     │
                     ▼
              Try Fallback[0]
                     │
                     ├── Success → Return Response
                     │
                     └── Failure → Try Fallback[1]...
```

### Fallback Trigger Conditions

- Model response timeout (default 120s)
- Ollama server connection failure
- Out of memory (OOM)
- Model load failure

## Resource Management

### M3 Pro 36GB Concurrent Execution Limits

| Scenario | Feasibility |
|----------|-------------|
| Llama 3.3 (8B) x1 | ✅ Comfortable |
| CodeLlama 34B x1 | ✅ OK |
| 70B model x1 | ⚠️ Tight (Q4 quantization needed) |
| 34B + 8B concurrent | ⚠️ Tight |

### Model Unload Strategy

```bash
# Check currently loaded models
curl http://localhost:11434/api/ps

# Unload specific model (free memory)
curl http://localhost:11434/api/delete -d '{"name":"codellama:34b"}'
```

### Ollama Settings (keep_alive)

```bash
# Auto-unload time (default 5min)
OLLAMA_KEEP_ALIVE=5m ollama serve

# Immediate unload (save memory)
OLLAMA_KEEP_ALIVE=0 ollama serve
```

## Performance Monitoring

### Response Time Benchmark (Expected)

| Model | Time to First Token | Generation Speed |
|-------|---------------------|------------------|
| CodeLlama 34B | 2-3s | 10-15 tok/s |
| Llama 3.3 70B (Q4) | 3-5s | 5-10 tok/s |
| Llama 3.3 8B | 0.5s | 25-30 tok/s |

### Monitoring Script

```bash
#!/bin/bash
# monitor-models.sh

while true; do
  echo "=== $(date) ==="

  # Ollama status
  curl -s http://localhost:11434/api/ps | jq '.models[] | {name, size, expires_at}'

  # Memory usage
  vm_stat | grep "Pages active"

  sleep 30
done
```

## Checklist

- [x] Define model roles
- [x] OpenClaw fallback configuration
- [x] CLI switching commands
- [x] Auto-routing strategy design
- [ ] Implement routing logic in model-router plugin
- [ ] Build monitoring dashboard
- [ ] Run performance benchmarks

---

## 한국어 (Korean)

### 모델 역할 분담
- **CodeLlama 34B**: 코딩, 코드 리뷰, 디버깅 (코드 특화)
- **Llama 3.3 70B**: 논리 추론, 수학, 분석 (고성능)
- **Llama 3.3**: 일반 대화, 요약, 번역 (범용)

### Fallback 트리거 조건
- 모델 응답 타임아웃 (기본 120초)
- Ollama 서버 연결 실패
- 메모리 부족 (OOM)
- 모델 로드 실패
