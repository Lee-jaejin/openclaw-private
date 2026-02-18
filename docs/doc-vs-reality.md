# 문서 vs 실제 프로젝트 불일치 점검

프로젝트 상태와 문서를 비교한 결과. 커밋 전 또는 문서 수정 시 참고.

**최종 반영 (2026-02):** 아래 조치 항목은 모두 문서/설정에 반영됨. 추후 구조 변경 시 이 문서를 다시 점검하면 됨.

---

## 1. 컨테이너 이름

| 문서 | 내용 | 실제 |
|------|------|------|
| **docs/monitoring.md** | `openclaw-isolated` (체크·로그 예시) | docker-compose 컨테이너 이름은 **`openclaw`** |
| **docs/offline-mode.md** | `--name openclaw-isolated` (podman run 예시) | 동일 예시는 **`openclaw`** 로 통일하는 편이 일관됨 |

**조치:** monitoring.md의 `openclaw-isolated` → `openclaw` 로 수정. offline-mode.md의 예시 이름도 `openclaw` 로 통일 권장.

---

## 2. OpenClaw 볼륨·세션 구조

| 문서 | 내용 | 실제 |
|------|------|------|
| **docs/openclaw-workspace-setup.md** | "openclaw-sessions → 볼륨으로 세션만 유지", "워크스페이스는 별도 볼륨/마운트가 없음" | 현재 compose에는 **openclaw-sessions 없음**. **openclaw-data** + **./workspace** 마운트 사용 |
| **docs/openclaw-workspace-setup.md** | 방법 A 예시 YAML에 `openclaw-sessions`, `openclaw.json`만 마운트 | 실제는 `openclaw-data:/home/node/.openclaw` + `./config/openclaw.json:ro` + `./workspace:/home/node/.openclaw/workspace` |
| **docs/architecture.md** | "세션 \| ~/.openclaw/sessions/" | 이 레포에서는 세션이 **openclaw-data** 볼륨 안에 있음 (별도 sessions 볼륨 없음) |
| **docs/backup-recovery.md** | "OpenClaw 세션 \| ~/.openclaw/sessions/" | 동일. openclaw-data/workspace 반영 필요 |

**조치:** openclaw-workspace-setup.md에서 현재 구조(openclaw-data + workspace 마운트)로 설명 정리하고, openclaw-sessions 언급 제거 또는 "과거 구성"으로 표기. architecture/backup-recovery에서 openclaw 데이터 저장 위치를 "openclaw-data 볼륨, workspace는 ./workspace 마운트"에 맞게 수정.

---

## 3. 워크스페이스 템플릿 경로

| 문서 | 내용 | 실제 |
|------|------|------|
| **docs/openclaw-setup-order.md** | `config/workspace-templates/AGENTS-chat-only.md`, `SOUL.md`, `USER.md` 복사 | **config/workspace-templates/** 디렉터리 없음. .gitignore에 **workspace-templates/** 가 있어 레포에 템플릿이 없을 수 있음 |
| **docs/openclaw-workspace-setup.md** | `config/workspace-templates/` 복사, `AGENTS-chat-only.md` 등 | 동일 경로. 템플릿이 없으면 사용자가 절차를 따를 수 없음 |

**조치:** (1) 템플릿을 레포에 두려면 `config/workspace-templates/` 를 만들고 필요한 파일만 커밋(.gitignore에서 해당 경로 제외 또는 예외). (2) 템플릿을 레포에 두지 않을 거면 문서에서 "이 레포에 workspace-templates가 있는 경우" 등 조건부로 쓰거나, 공식 OpenClaw 문서/다른 저장소 링크로 대체.

---

## 4. OpenClaw 빌드 명령

| 문서 | 내용 | 실제 |
|------|------|------|
| **docs/update-policy.md** | `podman build -t openclaw:local -f infra/openclaw/Dockerfile .` | docker-compose는 **context: ./infra/openclaw**. 올바른 예: `podman build -t openclaw:local ./infra/openclaw` 또는 `-f infra/openclaw/Dockerfile infra/openclaw` |
| **docs/offline-mode.md** | 동일하게 `-f infra/openclaw/Dockerfile .` | context 불일치. 동일하게 수정 필요 |

**조치:** 두 문서 모두 빌드 예시를 `./infra/openclaw` 컨텍스트에 맞게 수정.

---

## 5. 오프라인 모드 podman run 예시

| 문서 | 내용 | 실제 |
|------|------|------|
| **docs/offline-mode.md** | `-v path/to/.../config:/home/node/.openclaw:rw`, `-v path/to/.../workspace:/workspace:rw` | openclaw.json의 **workspace** 는 `/home/node/.openclaw/workspace`. 컨테이너 내 경로를 **/workspace** 가 아니라 **/home/node/.openclaw/workspace** 로 맞추는 것이 일관됨 |

**조치:** 예시를 `-v .../workspace:/home/node/.openclaw/workspace` 형태로 수정.

---

## 6. 모델/설정 예시 (참고용)

| 문서 | 내용 | 실제 config |
|------|------|-------------|
| **docs/architecture.md** | "모델 \| llama3.2, codellama, qwen2.5-coder" | openclaw.json: **gpt-oss:20b**, llama3.2:latest 등 (프로젝트별 선택) |
| **docs/multi-llm-strategy.md** | qwen2.5-coder:32b, deepseek-r1:32b, llama3.3 예시 | 전략 문서이므로 예시로 두고, "실제 설정은 config/openclaw.json 참고" 한 줄 추가해도 됨 |

**조치:** architecture.md는 "예: llama3.2, qwen2.5-coder 등 (config 참고)"처럼 일반화하거나, 현재 config와 맞춤. multi-llm은 선택적으로 "이 레포 기본값과 다를 수 있음" 안내.

---

## 7. 백업 스크립트 vs 문서

| 문서 | 내용 | 실제 |
|------|------|------|
| **docs/backup-recovery.md** | OpenClaw 설정·세션 백업 대상 기술 | **scripts/backup.sh** 는 **config/** 와 Headscale, ollama list 만 백업. **workspace/** 및 openclaw-data 볼륨은 미포함 |

**조치:** backup-recovery.md에 "workspace/ 디렉터리(SOUL.md, AGENTS.md 등)도 백업하려면 스크립트에 workspace 복사 단계 추가" 등 명시. 필요 시 backup.sh에 workspace 백업 옵션 추가.

---

## 8. 기타

- **docs/update-policy.md** 버전 기록 파일 경로: `~/Study/ai/private-ai-versions.md` — 사용자별 경로이므로 "예: 프로젝트 docs 또는 홈 디렉터리" 등으로 일반화 권장.
- **docs/update-policy.md** "notify-updates.sh"에서 GitHub API 호출 — CLAUDE.md 원칙상 **외부 API 호출 금지**. 오프라인 환경에서는 사용 불가이므로 "선택적·온라인 전제" 또는 제거/대체 안내 필요.

---

## 요약 체크리스트 (반영 완료)

- [x] monitoring.md: openclaw-isolated → openclaw
- [x] openclaw-workspace-setup.md: openclaw-sessions 제거, 현재 openclaw-data + workspace 반영
- [x] architecture.md, backup-recovery.md: OpenClaw 데이터 위치(openclaw-data, workspace) 반영
- [x] config/workspace-templates/ 추가 (AGENTS-chat-only.md, SOUL.md, USER.md), .gitignore는 루트만 /workspace-templates/
- [x] update-policy.md, offline-mode.md: podman build context → `./infra/openclaw`
- [x] offline-mode.md: podman run 컨테이너 이름·워크스페이스 마운트 경로 수정
- [x] backup-recovery.md: workspace 백업 안내 및 pnpm backup 한계 명시
- [x] update-policy.md: 버전 기록 경로 일반화, GitHub API 스크립트는 "온라인 전제" 안내
