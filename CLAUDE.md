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

## Architecture Principles

**Rule 1: 네트워크 격리** — 모든 디바이스 간 통신은 WireGuard VPN 터널 내에서만 허용한다.

**Rule 2: 컨테이너 최소 권한** — `--cap-drop ALL`, `--security-opt no-new-privileges`, rootless 모드를 기본으로 한다.

**Rule 3: 외부 의존성 제로** — CDN, 클라우드 API, SaaS를 사용하지 않는다. 모든 구성요소는 오프라인에서 동작해야 한다.

**Rule 4: 데이터 로컬 유지** — LLM 추론 데이터, 사용자 데이터 모두 로컬에서만 처리하고 외부로 전송하지 않는다.

## Behavior

- 모호한 요청 시 가정을 명시하고, 구현 전 확인
- 요청한 기능만 구현. 조기 추상화, 미래 대비 코드 금지
- 변경한 모든 줄이 요청과 직접 연결. 주변 코드 리팩토링 금지
- 작업 시작 전 성공 기준 정의. 각 단계 독립 검증
- 행동 원칙 상세: @principles/README.md

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
- 구성요소 상태, 기술 스택, TODO가 변경되면 @STATUS.md 도 함께 업데이트할 것
- 코드 작성, 테스트, 도구 선택, 보안 패턴은 @CONVENTIONS.md 참조

## Do NOT

- `.env` 파일을 커밋하거나 내용을 출력하지 말 것
- `infra/headscale/config/` 내 네트워크 설정을 임의 변경하지 말 것
- 외부 CDN, 클라우드 API, SaaS 의존성을 추가하지 말 것

## Verification

- 코드 변경 후: `node --test` (해당 모듈)
- 인프라 변경 후: `pnpm health`
- 타입 체크: `pnpm exec tsc --noEmit`

## Commits

커밋 작성 시 @COMMITS.md 참조. 영문, Conventional Commits 형식.

## Quick Reference

```
컨테이너:  Podman (rootless)
네트워크:  WireGuard VPN (Headscale + Tailscale)
LLM:      Ollama (호스트)
스크립트:  Bash + set -euo pipefail
패키지:    pnpm 9+
런타임:    Node.js 22+
```

## Compaction

When compacting, always preserve:
- Architecture Principles (Rule 1~4) — 이 프로젝트의 핵심 제약 조건
- 변경된 파일 전체 목록과 각 파일의 변경 이유
- 실행한 테스트/검증 명령어와 결과
- 현재 작업의 목표와 진행 상황
