# 단순함 우선 (Simplicity First)

> 요청한 것만 구현하라. 최소한의 코드로 오늘의 문제를 풀어라.

## 적용 상황

- 새 스크립트를 작성할 때
- Compose 서비스를 추가할 때
- 설정 파일을 변경할 때
- 플러그인 기능을 구현할 때

## 핵심 규칙

1. **요청하지 않은 기능을 추가하지 마라**: "나중에 필요할 것 같은" 설정 금지
2. **조기 추상화 금지**: 패턴이 3회 반복되기 전에 추상화하지 마라
3. **미래를 위한 유연성 금지**: 설정 가능하게, 확장 가능하게 만들지 마라
4. **한 번만 쓰이는 헬퍼 금지**: 인라인으로 충분하면 함수를 만들지 마라


## 예시 1: 과설계된 스크립트

**요청**: "헬스 체크 스크립트 만들어줘"

### ❌ 잘못된 접근

```bash
#!/bin/bash
set -euo pipefail

# 플러그인 시스템
declare -A HEALTH_PLUGINS
register_plugin() { HEALTH_PLUGINS[$1]=$2; }
run_plugins() { for p in "${!HEALTH_PLUGINS[@]}"; do ${HEALTH_PLUGINS[$p]}; done; }

# 알림
notify_slack() { curl -X POST "${SLACK_WEBHOOK}" -d "{\"text\":\"$1\"}"; }

# 대시보드
update_dashboard() { curl -X POST "${DASHBOARD_URL}/api/health" -d "$1"; }

# 재시도 로직
retry() {
  local max_attempts=$1; shift
  local attempt=1
  until "$@" || [[ $attempt -ge $max_attempts ]]; do
    sleep $((attempt * 2))
    ((attempt++))
  done
}
```

문제: 플러그인 시스템, Slack 알림(외부 호출!), 대시보드, 재시도 로직 — 전부 요청하지 않은 것. 외부 호출은 Rule 3 위반.

### ✅ 올바른 접근

```bash
#!/bin/bash
set -euo pipefail
curl -sf http://localhost:8080/health || exit 1
```


## 예시 2: 투기적 Compose 설정

**요청**: "Ollama 서비스 Compose 파일에 추가해줘"

### ❌ 잘못된 접근

```yaml
services:
  ollama:
    image: ollama/ollama
    volumes:
      - ollama_data:/root/.ollama
    ports:
      - "127.0.0.1:11434:11434"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    deploy:
      resources:
        limits:
          memory: 32G
        reservations:
          memory: 16G
      restart_policy:
        condition: on-failure
        max_attempts: 5
```

문제: 로깅 설정, 메모리 리밋, 재시작 정책 — 요청하지 않은 설정들.

### ✅ 올바른 접근

```yaml
services:
  ollama:
    image: ollama/ollama
    volumes:
      - ollama_data:/root/.ollama
    ports:
      - "127.0.0.1:11434:11434"
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
```

보안 설정은 Architecture Principles(Rule 2)이므로 포함. 나머지는 요청 시 추가.


## CLAUDE.md 삽입 블록

```markdown
### 단순함 우선
- 요청한 기능만 구현. 미래 요구사항 예측 금지
- 조기 추상화 금지 — 패턴이 3회 반복되기 전에 추상화하지 않음
- 한 번만 쓰이는 헬퍼/유틸리티 생성 금지
```
