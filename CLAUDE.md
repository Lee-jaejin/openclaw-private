# OpenClaw Private

폐쇄망 전용 프라이빗 AI 어시스턴트 인프라. 외부 클라우드 없이 로컬 LLM을 운영하며 WireGuard VPN으로 디바이스 간 통신을 보호한다.

## Status

작업 전 @STATUS.md 확인. 구성요소별 상태, TODO, 기술 스택 정리되어 있다.

## Structure

```
config/openclaw.json      → 모델 프로필 설정
infra/headscale/          → VPN 코디네이터 (Podman)
infra/ollama/             → 로컬 LLM 서버 (Podman 또는 호스트)
infra/openclaw/           → OpenClaw 앱 컨테이너 (pnpm 패키지 의존성)
infra/tailscale/          → VPN 클라이언트 설치 스크립트
plugins/model-router/src/ → 태스크→모델 라우팅 (TypeScript)
scripts/                  → 운영 스크립트
website/                  → Docusaurus 문서 사이트 (한/영 i18n)
```

## Design Decisions

- **Podman > Docker**: 데몬리스, rootless → 폐쇄망에서 보안 우위
- **Ollama 직접 운영**: 외부 API 의존 제거, 추론 데이터 로컬 유지
- **Headscale**: Tailscale 컨트롤 서버의 셀프호스팅 대안, 외부 SaaS 불필요
- **호스트 Ollama 전환**: 컨테이너 대비 GPU 직접 접근, 메모리 효율 우위

## Commands

- `pnpm setup` — 전체 인프라 설치
- `pnpm health` — 헬스 체크
- `pnpm monitor` — 실시간 모니터링
- `pnpm backup` — 백업 (7개 보관)
- `pnpm docs:dev` — 문서 사이트 로컬 개발
- `node --test plugins/model-router/src/**/*.test.ts` — Model Router 테스트

## Rules

- **IMPORTANT**: 모든 코드와 설정은 오프라인 환경에서 동작해야 한다. 외부 API 호출 금지.
- 보안: 컨테이너 격리, 최소 권한(`--cap-drop ALL`), VPN 필수 통신
- Shell 스크립트는 `set -euo pipefail` 사용
- TypeScript는 strict mode
- 문서는 한/영 i18n 구조를 따른다

## Workflow

- 구성요소 상태, 기술 스택, TODO가 변경되면 @STATUS.md 도 함께 업데이트할 것

## Do NOT

- `.env` 파일을 커밋하거나 내용을 출력하지 말 것
- `infra/headscale/config/` 내 네트워크 설정을 임의 변경하지 말 것
- 외부 CDN, 클라우드 API, SaaS 의존성을 추가하지 말 것

## Verification

- 코드 변경 후: `node --test` (해당 모듈)
- 인프라 변경 후: `pnpm health`
- 타입 체크: `pnpm exec tsc --noEmit`

## Commits

영문 작성. 타입 접두사: `feat:`, `fix:`, `infra:`, `docs:`, `refactor:`, `test:`
