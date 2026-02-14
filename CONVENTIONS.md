# Conventions

## Code Style

### 우선순위

```
Readability > Simplicity > Performance
```

### Shell Scripts

- `set -euo pipefail` 필수
- 변수는 `"${VAR}"` 형태로 항상 따옴표 사용
- 함수명: `snake_case` (예: `check_health`, `setup_vpn`)
- 긴 파이프라인은 줄바꿈으로 가독성 확보

### TypeScript (plugins/)

- strict mode 필수
- 함수명: `camelCase`, 타입명: `PascalCase`, 상수: `SCREAMING_SNAKE_CASE`
- `any` 사용 금지, 명시적 타입 선언

### 피해야 할 패턴

| 패턴 | 이유 |
|------|------|
| Over-engineering | 현재 필요한 것만 구현, 미래 요구사항 예측 금지 |
| 하드코딩된 IP/포트 | 환경변수 또는 설정 파일로 관리 |
| 외부 네트워크 호출 | 오프라인 환경에서 동작 불가 |
| root 권한 실행 | rootless 원칙 위반 |

## Testing

### 범위

| 대상 | 테스트 방법 | 위치 |
|------|------------|------|
| Model Router | `node --test` 단위 테스트 | `plugins/model-router/src/**/*.test.ts` |
| 인프라 상태 | `pnpm health` 헬스 체크 | `scripts/health-check.sh` |
| 타입 안전성 | `pnpm exec tsc --noEmit` | - |

### 네이밍

```typescript
// 패턴: test_[행위]_[조건]_[결과]
test('routes coding task to deepseek-coder when keyword matches', () => { ... });
test('falls back to default model when no keyword matches', () => { ... });
```

## Tool Choices

| 용도 | 사용 | 사용하지 않음 | 이유 |
|------|------|-------------|------|
| 컨테이너 | Podman | Docker | 데몬리스, rootless |
| 패키지 매니저 | pnpm | npm, yarn | 하드링크, 워크스페이스 |
| VPN 코디네이터 | Headscale | Tailscale SaaS | 셀프호스팅, 외부 의존 제거 |
| LLM 런타임 | Ollama (호스트) | 컨테이너 Ollama | GPU 직접 접근, 메모리 효율 |
| 문서 | Docusaurus | GitBook, Notion | 오프라인 빌드, 정적 사이트 |

## Security Patterns

### 컨테이너 보안

```yaml
# 모든 Podman 서비스에 적용
security_opt:
  - no-new-privileges:true
cap_drop:
  - ALL
```

### 네트워크 보안

- 서비스 간 통신은 VPN 내부 IP만 사용
- 외부 포트 노출 최소화 (`127.0.0.1:port` 바인딩)
- Headscale ACL로 디바이스 간 접근 제어

### Secrets 관리

- `.env` 파일은 `.gitignore`에 포함, 절대 커밋하지 않음
- `.env.example`에 템플릿만 유지
- 로그에 민감정보(키, 토큰, 패스워드) 출력 금지

