# 정밀 변경 (Surgical Changes)

> 요청에 해당하는 코드만 수정하라. 주변 코드를 건드리지 마라.

## 적용 상황

- 스크립트 버그를 수정할 때
- Compose 파일 설정을 변경할 때
- 기존 설정에 항목을 추가할 때
- PR 리뷰 피드백을 반영할 때

## 핵심 규칙

1. **변경한 모든 줄이 요청에 연결되어야 한다**: 설명할 수 없는 변경은 하지 마라
2. **기존 스타일을 따르라**: 변수명, 따옴표, 들여쓰기를 기존 코드에 맞춰라
3. **Drive-by 리팩토링 금지**: 버그 수정하면서 주변 코드 정리하지 마라
4. **요청하지 않은 개선 금지**: 주석, 로깅, 에러 핸들링을 추가하지 마라
5. **자기가 만든 것만 정리하라**: 기존 코드의 "문제"를 고치려 하지 마라


## 예시 1: Drive-by 리팩토링

**요청**: "백업 스크립트에서 경로 오류 수정해줘"

### ❌ 잘못된 접근

```diff
 #!/bin/bash
 set -euo pipefail
-backup_dir="/data/backu"
+BACKUP_DIR="/data/backup"
+
+log() { echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"; }
+
+log "Starting backup to ${BACKUP_DIR}"
+
+if [[ ! -d "${BACKUP_DIR}" ]]; then
+    mkdir -p "${BACKUP_DIR}"
+    log "Created backup directory"
+fi
```

문제: 경로 오류만 수정하면 되는데 — 변수명 SCREAMING_CASE 변경, 로깅 함수 추가, 디렉토리 존재 확인까지.

### ✅ 올바른 접근

```diff
-backup_dir="/data/backu"
+backup_dir="/data/backup"
```

1줄. 경로만 수정. 기존 변수명 스타일 유지.


## 예시 2: 스타일 드리프트

**요청**: "Compose 파일에 healthcheck 추가해줘"

### ❌ 잘못된 접근

```diff
 services:
   headscale:
-    image: headscale/headscale:0.22
+    image: headscale/headscale:0.22  # VPN coordinator
     container_name: headscale
+    restart: unless-stopped
     ports:
-      - "127.0.0.1:8080:8080"
+      - "${HEADSCALE_HOST:-127.0.0.1}:${HEADSCALE_PORT:-8080}:8080"
+    healthcheck:
+      test: ["CMD", "headscale", "health"]
+      interval: 30s
+      timeout: 5s
+      retries: 3
     security_opt:
       - no-new-privileges:true
```

문제: healthcheck만 요청했는데 — 주석 추가, restart 정책, 포트를 환경변수로 변경.

### ✅ 올바른 접근

```diff
 services:
   headscale:
     image: headscale/headscale:0.22
     container_name: headscale
     ports:
       - "127.0.0.1:8080:8080"
+    healthcheck:
+      test: ["CMD", "headscale", "health"]
+      interval: 30s
+      timeout: 5s
+      retries: 3
     security_opt:
       - no-new-privileges:true
```

healthcheck만 추가. 기존 설정은 건드리지 않음.


## 자기 점검

변경을 마친 후 diff를 보고 스스로 질문하라:

- 이 변경이 요청과 직접 연결되는가?
- 기존 코드의 스타일(변수명, 들여쓰기, 따옴표)을 유지했는가?
- 요청하지 않은 "개선"을 추가하지 않았는가?


## CLAUDE.md 삽입 블록

```markdown
### 정밀 변경
- 변경한 모든 줄이 요청과 직접 연결되어야 함
- 기존 코드 스타일(따옴표, 네이밍, 들여쓰기) 유지
- 버그 수정 시 주변 코드 리팩토링 금지 (drive-by refactoring)
- 요청하지 않은 docstring, 타입 힌트, 주석 추가 금지
```
