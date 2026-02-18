# OpenClaw 워크스페이스 설정 (SOUL.md, AGENTS.md 등)

OpenClaw는 **에이전트 워크스페이스**에 있는 파일들(SOUL.md, AGENTS.md, USER.md 등)을 매 세션 시작 시 시스템 프롬프트에 **주입**합니다. 이 파일들이 없거나 비어 있으면, 모델이 "SOUL.md를 읽어야 한다"만 반복하는 현상이 발생할 수 있습니다.

## 1. 파일이 어디에 있어야 하는지

| 설정 항목 | 이 프로젝트 값 | 설명 |
|-----------|----------------|------|
| `agents.defaults.workspace` | `/home/node/.openclaw/workspace` | 컨테이너 **안**의 워크스페이스 경로 |

즉, OpenClaw가 참조하는 위치는 **설정에 적힌 워크스페이스 디렉터리**입니다.  
현재 `config/openclaw.json`에는 다음이 들어 있습니다.

```json
"agents": {
  "defaults": {
    "workspace": "/home/node/.openclaw/workspace",
    ...
  }
}
```

컨테이너 기준으로 보면 (이 레포의 `docker-compose.yml`):

- `openclaw-data` → `/home/node/.openclaw` (세션·기타 데이터)
- `openclaw.json` → 호스트의 `./config/openclaw.json`을 **읽기 전용**으로 마운트
- **워크스페이스** → 호스트의 `./workspace`를 `/home/node/.openclaw/workspace`에 마운트 (호스트에서 편집·백업 가능)

즉, 이 레포에서는 이미 워크스페이스가 호스트 `./workspace`로 연결되어 있습니다. **SOUL.md, AGENTS.md 등을 호스트의 `workspace/` 디렉터리에 두면 됩니다.**

## 2. 어떻게 설정하면 되는지

**이 레포에는 이미** `docker-compose.yml`에 워크스페이스 마운트(`./workspace` → `/home/node/.openclaw/workspace`)가 들어 있습니다. 아래만 하면 됩니다.

**첫 기동 전 한 번에 하기:**

```bash
mkdir -p workspace
cp config/workspace-templates/AGENTS-chat-only.md workspace/AGENTS.md
cp config/workspace-templates/SOUL.md workspace/SOUL.md
cp config/workspace-templates/USER.md workspace/USER.md
podman compose up -d openclaw
```

### 2-1. 이 레포의 현재 구성

`docker-compose.yml`의 `openclaw` 서비스는 이미 다음처럼 되어 있습니다.

```yaml
volumes:
  - openclaw-data:/home/node/.openclaw
  - ./config/openclaw.json:/home/node/.openclaw/openclaw.json:ro
  - ./workspace:/home/node/.openclaw/workspace
  # ... SSH 키, imsg 등
```

호스트의 `./workspace`에 AGENTS.md, SOUL.md, USER.md를 두면 됩니다. 아래 2-2처럼 템플릿을 복사하거나, 직접 작성합니다.

**다른 구성이 필요할 때 (참고): named volume만 사용**

```yaml
volumes:
  - openclaw-workspace:/home/node/.openclaw/workspace
  # ...
volumes:
  openclaw-workspace:
```

이 경우 파일은 컨테이너 **첫 기동 후** 안에서 만들어야 합니다.

```bash
podman compose up -d openclaw
podman exec openclaw openclaw setup --workspace /home/node/.openclaw/workspace
# 또는 수동으로
podman exec -it openclaw sh
mkdir -p /home/node/.openclaw/workspace
# 에디터 없으면 호스트에서 만든 파일을 복사
exit
podman cp workspace/AGENTS.md openclaw:/home/node/.openclaw/workspace/
```

### 2-2. 최소 파일만 넣기 (iMessage 등 채팅 전용)

공식 기본 AGENTS.md에는 "세션 시작 시 SOUL.md, USER.md, memory를 **읽어라**"는 문장이 들어 있습니다.  
로컬 Ollama는 **파일 읽기 도구가 없고**, OpenClaw가 이미 이 파일 내용을 프롬프트에 넣어 주므로, 모델이 "읽어라"를 말로만 반복하지 않도록 **짧고 단순한 지시**만 두는 편이 좋습니다.

이 레포에는 **채팅 전용 최소 템플릿**이 있습니다.

- `config/workspace-templates/AGENTS-chat-only.md` — "답변만 직접 해라" 위주
- `config/workspace-templates/SOUL.md` — 톤/성격만 간단히
- `config/workspace-templates/USER.md` — 사용자 선호만 간단히

사용 절차:

```bash
mkdir -p workspace
cp config/workspace-templates/AGENTS-chat-only.md workspace/AGENTS.md
cp config/workspace-templates/SOUL.md workspace/SOUL.md
cp config/workspace-templates/USER.md workspace/USER.md
```

이 레포에서는 이미 `./workspace`가 마운트되어 있으므로, 위 파일만 넣은 뒤 OpenClaw를 재시작하면 됩니다.

### 2-3. 공식 부트스트랩으로 한 번 채우기

OpenClaw 소스/이미지에 `openclaw setup`이 들어 있다면, 워크스페이스만 마운트한 상태에서 한 번 실행해 기본 AGENTS.md, SOUL.md, USER.md 등을 생성할 수 있습니다.

```bash
podman exec openclaw openclaw setup --workspace /home/node/.openclaw/workspace
```

생성된 AGENTS.md에 "Read SOUL.md before responding" 같은 문장이 있으면, iMessage 전용으로 쓸 때는 2-2의 `AGENTS-chat-only.md`로 **교체**하는 것을 권장합니다.

### 2-4. 설정만 바꾸고 싶을 때 (경로·부트스트랩)

- **워크스페이스 경로 변경**  
  `config/openclaw.json`에서 `agents.defaults.workspace`를 바꿉니다.  
  컨테이너 안 경로이므로, 마운트한 위치와 맞춰야 합니다 (예: `/home/node/.openclaw/workspace`).

- **부트스트랩 자동 생성 끄기**
  워크스페이스 파일을 직접 관리할 때는 `agents.defaults.skipBootstrap`을 `true`로 설정합니다.

  ```json
  "agents": {
    "defaults": {
      "skipBootstrap": true,
      "workspace": "/home/node/.openclaw/workspace"
    }
  }
  ```

  공식 문서: [Agent workspace](https://docs.openclaw.ai/concepts/agent-workspace), [Bootstrapping](https://docs.openclaw.ai/start/bootstrapping)

## 3. 참고 링크

- [Agent Workspace (공식)](https://docs.openclaw.ai/concepts/agent-workspace) — 워크스페이스 경로, 파일 역할, 부트스트랩
- [Agent Bootstrapping](https://docs.openclaw.ai/start/bootstrapping) — 첫 실행 시 시드 파일 생성
- [Default AGENTS.md](https://docs.openclaw.ai/reference/AGENTS.default) — 기본 AGENTS.md 내용 및 "Session start (required)" 안내
- [OpenClaw memory files (openclaw-setup.me)](https://openclaw-setup.me/blog/openclaw-memory-files/) — AGENTS.md, SOUL.md, USER.md 등 요약
- [Configuration](https://docs.openclaw.ai/gateway/configuration) — `agents.defaults.workspace`, `skipBootstrap` 등

## 4. 요약

| 하고 싶은 것 | 할 일 |
|--------------|--------|
| SOUL.md, AGENTS.md **위치** | `agents.defaults.workspace`가 가리키는 디렉터리 (현재 컨테이너 안 `/home/node/.openclaw/workspace`) |
| **설정** | `config/openclaw.json`에서 `agents.defaults.workspace` 유지 또는 변경 |
| **파일 채우기** | (1) 이 레포의 `config/workspace-templates/` 복사 **또** (2) `openclaw setup` 한 번 실행 |
| iMessage에서 "SOUL 읽어라" 반복 줄이기 | 워크스페이스에 **실제 SOUL.md·AGENTS.md 내용**이 들어가 있게 하고, AGENTS.md는 `AGENTS-chat-only.md`처럼 "바로 답변하라" 위주로 단순화 |
