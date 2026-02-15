# Commit Conventions

영문 작성. Conventional Commits 형식을 따른다.

```
<type>(<scope>): <description>
```

| Type | 용도 |
|------|------|
| `feat` | 새로운 기능 |
| `fix` | 버그 수정 |
| `infra` | 인프라/컨테이너/VPN 변경 |
| `docs` | 문서 변경 |
| `refactor` | 리팩토링 |
| `test` | 테스트 추가/수정 |
| `chore` | 빌드, 설정, 스크립트 변경 |

허용 scope:

| Scope | 대상 |
|-------|------|
| `headscale` | VPN 코디네이터 |
| `ollama` | LLM 서버 |
| `openclaw` | OpenClaw 앱 컨테이너 |
| `tailscale` | VPN 클라이언트 |
| `router` | Model Router 플러그인 |
| `scripts` | 운영 스크립트 |
| `website` | 문서 사이트 |
| `config` | 설정 파일 |
| `network` | 네트워크/VPN 설정 |

예시:
```
infra(headscale): add DERP relay configuration
feat(router): add keyword-based task classification
fix(scripts): correct health-check exit code handling
docs(website): add VPN setup guide in Korean
```
