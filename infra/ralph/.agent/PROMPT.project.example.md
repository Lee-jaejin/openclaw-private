# Project Context — [Project Name]
#
# This file is Layer 2: project-specific context injected between the framework
# prompt (Layer 1) and the behavior principles (Layer 3).
#
# Copy this file to YOUR_PROJECT/.agent/PROMPT.md and fill it in.
# Focus on: what this project is, tech stack, conventions, constraints.
# Do NOT add task loop rules or signal definitions — those live in Layer 1.

## Overview

[이 프로젝트가 무엇을 하는지 1-3문장으로 설명]

예시:
> Next.js 14 기반의 SaaS 구독 관리 앱. Stripe 결제 연동, Prisma + PostgreSQL, Tailwind CSS 사용.

## Tech Stack

- Language: TypeScript (strict mode)
- Framework: [e.g. Next.js 14 App Router / Express / FastAPI]
- Database: [e.g. PostgreSQL via Prisma / SQLite / MongoDB]
- Test: [e.g. Vitest + Playwright / Jest / pytest]
- Package manager: [e.g. pnpm / npm / uv]

## Conventions

- [컴포넌트 작성 규칙 등]
- [네이밍 규칙]
- [커밋 메시지 형식]

예시:
> - Server Component 우선, 상태가 필요한 경우에만 'use client' 추가
> - DB 접근은 Prisma ORM만 사용, raw SQL 금지
> - 커밋: Conventional Commits (feat/fix/chore)

## Constraints

- [절대 하지 말아야 할 것]
- [외부 의존성 제한]
- [보안 규칙]

예시:
> - .env의 키를 코드에 하드코딩하지 말 것
> - 외부 CDN 사용 금지 (오프라인 환경)
> - pnpm test 통과 후에만 커밋

## Completion Criteria

태스크 완료 조건:
- [ ] 관련 테스트 통과
- [ ] 타입 에러 없음 (`tsc --noEmit`)
- [ ] lint 통과
- [ ] 변경 커밋 완료
