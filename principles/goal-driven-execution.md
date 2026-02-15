# 목표 중심 실행 (Goal-Driven Execution)

> 무엇을 할지 말하지 말고, 성공 기준을 정의하라. LLM은 목표를 향해 루프하는 데 탁월하다.

## 적용 상황

- 다단계 인프라 작업을 수행할 때
- 모호한 완료 조건이 있을 때
- 네트워크/서비스 문제를 디버깅할 때
- 설정 변경 후 검증할 때

## 핵심 규칙

1. **명령이 아닌 성공 기준을 정의하라**: "X를 해라"보다 "Y 상태가 되면 성공"
2. **각 단계를 독립적으로 검증하라**: 다음 단계 전에 현재 단계를 확인
3. **재현부터 시작하라**: 문제 수정 전 현재 상태를 확인하고 기록
4. **완료를 증명하라**: "수정 완료"가 아니라, 검증 결과를 보여라


## 예시 1: 모호한 계획 vs 검증 가능한 계획

**요청**: "VPN 연결 안 되는 문제 해결해줘"

### ❌ 잘못된 접근

```
계획:
1. Headscale 설정을 확인한다
2. 문제를 찾는다
3. 수정한다
4. 테스트한다
```

문제: 성공 기준 없음. "문제를 찾는다"는 완료를 증명할 수 없다.

### ✅ 올바른 접근

```
성공 기준:
1. headscale 컨테이너가 healthy 상태
2. tailscale status에서 peer 목록이 보임
3. VPN IP로 ping 응답 확인

실행 계획:
1. pnpm health 실행 → 현재 실패 상태 확인
2. podman logs headscale → 에러 메시지 확인
3. 원인 수정
4. pnpm health 재실행 → 위 3개 기준 모두 통과
```


## 예시 2: 단계별 검증

**요청**: "새 디바이스를 VPN에 추가해줘"

### ❌ 잘못된 접근

```bash
# 한 번에 전부 실행
headscale users create new-device
headscale preauthkeys create --user new-device
tailscale up --login-server https://headscale:8080 --authkey "$KEY"
# ACL 수정, DNS 설정, 방화벽 규칙 전부 한 커밋
```

문제: 중간 검증 없이 모든 단계를 한 번에 실행. 어디서 실패했는지 알 수 없음.

### ✅ 올바른 접근

```
단계별 구현 (각 단계 독립 검증):

Step 1: 사용자 생성
  실행: headscale users create new-device
  검증: headscale users list → new-device 표시

Step 2: 인증키 생성
  실행: headscale preauthkeys create --user new-device
  검증: headscale preauthkeys list --user new-device → 키 존재

Step 3: 클라이언트 연결
  실행: tailscale up --login-server ... --authkey ...
  검증: tailscale status → connected, headscale nodes list → online
```


## Karpathy의 핵심 인사이트

> "LLMs are exceptionally good at looping until they meet specific goals...
> Don't tell it what to do, give it success criteria and watch it go."

성공 기준을 제시하면 LLM은 스스로 경로를 찾아 반복하며 목표에 도달한다.
명령을 나열하면 순서대로 실행할 뿐, 결과를 검증하지 않는다.


## CLAUDE.md 삽입 블록

```markdown
### 목표 중심 실행
- 작업 시작 전 성공 기준 정의. "무엇을 하라"보다 "어떤 상태가 되면 성공"
- 다단계 작업은 각 단계를 독립적으로 검증한 후 다음 단계 진행
- 버그 수정 시 재현 테스트 먼저 작성 → 수정 → 테스트 통과 확인
```
