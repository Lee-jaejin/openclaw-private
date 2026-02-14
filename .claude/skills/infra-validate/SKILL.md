---
name: infra-validate
description: 인프라 변경 후 다단계 검증 워크플로우 실행
disable-model-invocation: true
---

인프라 변경 사항을 단계별로 검증한다. 모든 단계를 순서대로 실행하고 결과를 요약하라.

## Step 1: Compose 파일 문법 검증

`infra/` 하위의 모든 `docker-compose*.yml` 파일에 대해 `podman-compose config`로 문법을 검증한다.

```bash
for f in infra/*/docker-compose*.yml; do
  echo "=== Validating: $f ==="
  podman-compose -f "$f" config --quiet && echo "OK" || echo "FAIL"
done
```

## Step 2: 보안 설정 확인

각 Compose 파일에서 다음 보안 설정의 존재 여부를 확인한다:
- `cap_drop` 에 `ALL` 포함
- `security_opt` 에 `no-new-privileges` 포함

누락된 서비스가 있으면 경고를 출력한다.

## Step 3: 헬스 체크 실행

```bash
pnpm health
```

## Step 4: 결과 요약

각 단계의 통과/실패 여부를 표로 요약한다:

| 단계 | 결과 |
|------|------|
| Compose 문법 | PASS/FAIL |
| 보안 설정 | PASS/FAIL (누락 항목 나열) |
| 헬스 체크 | PASS/FAIL |
