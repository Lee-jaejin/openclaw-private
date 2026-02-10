# CLAUDE.md — OpenClaw Private

## 프로젝트 요약

폐쇄망 전용 프라이빗 AI 어시스턴트 인프라. 외부 클라우드 없이 로컬에서 LLM을 운영하며, WireGuard VPN으로 디바이스 간 통신을 보호한다.

## 진행 상황

`STATUS.md` 파일에 구성요소별 상태, TODO 목록, 기술 스택이 정리되어 있다. 작업 전 반드시 확인할 것.

## 핵심 구조

```
config/openclaw.json        → 모델 프로필 설정
infra/headscale/            → VPN 코디네이터 (Podman)
infra/ollama/               → 로컬 LLM 서버 (Podman)
infra/tailscale/            → VPN 클라이언트 설치 스크립트
plugins/model-router/src/   → 태스크→모델 라우팅 (TypeScript)
scripts/                    → 운영 스크립트 (setup, health, monitor, backup)
website/                    → Docusaurus 문서 사이트 (한/영)
```

## 기술 스택

- **인프라**: Podman (데몬리스 컨테이너), WireGuard VPN (Headscale + Tailscale)
- **AI**: Ollama + Llama 모델 전용 (외부 API 없음)
- **플러그인**: TypeScript 5.0+ (strict mode), Node.js 22+
- **문서**: Docusaurus 3.9.2, i18n (EN/KO)

## 작업 규칙

- 모든 코드와 설정은 **오프라인 환경**에서 동작해야 한다. 외부 API 호출 금지.
- 보안 원칙: 컨테이너 격리, 최소 권한, VPN 필수 통신.
- 한국어와 영어 모두 지원. 문서는 한/영 i18n 구조를 따른다.
- Shell 스크립트는 `set -euo pipefail` 사용.
- TypeScript는 strict mode.

## 주요 미완료 항목

- OpenClaw 앱 본체: 컨테이너 인프라 완료 (`infra/openclaw/`), npm 패키지 배포 대기
- 테스트: Model Router 완료 (node:test 사용), 추가 컴포넌트 테스트 필요
- GPU 가속: `docker-compose.gpu.yml` override로 토글 가능 (`podman compose -f`). 70B 모델: RAM 확보 후 검증 필요
- 클라우드 백업, 자동 업데이트 미구현

## 커밋 컨벤션

커밋 메시지는 영문으로 작성. 타입 접두사 사용:
- `docs:` 문서
- `feat:` 새 기능
- `fix:` 버그 수정
- `infra:` 인프라 설정
- `refactor:` 리팩토링
- `test:` 테스트
