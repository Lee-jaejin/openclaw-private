---
id: iphone-vpn-setup
title: iPhone VPN 설정
sidebar_position: 10
---

# iPhone VPN 설정

iPhone을 headscale VPN으로 OpenClaw 프라이빗 네트워크에 연결합니다.

## 배경

Tailscale iOS 1.60 이상은 커스텀 coordination server를 설정해도 OIDC 기반 인증이 필수입니다. preauthkey만으로는 연결이 되지 않습니다. 두 가지 옵션 중 선택합니다.

| | 옵션 A (권장) | 옵션 B |
|---|---|---|
| **방식** | Dex OIDC 자체 호스팅 | LAN 한정 |
| **iPhone 접근** | 어디서든 (VPN 경유) | 집 WiFi 한정 |
| **추가 설정** | Dex 컨테이너 + OIDC 설정 | 없음 |
| **Rule 3 준수** | ✅ 외부 서비스 없음 | ✅ 외부 서비스 없음 |

---

## 사전 조건

1. headscale 실행 중 (`yarn start`)
2. iPhone에 CA 인증서 설치 완료 — [iOS CA 인증서 설치](#ios-ca-cert) 참조
3. iPhone에 Tailscale 앱 설치 (App Store)

---

## iOS CA 인증서 설치 {#ios-ca-cert}

headscale에 연결하려면 iPhone이 CA를 신뢰해야 합니다.

**1. CA 인증서 서빙**

컨트롤 타워에서:
```bash
yarn ca:serve
```

출력:
```
Serving CA cert at http://192.168.x.x:8880/ca.crt
iOS profile:       http://192.168.x.x:8880/headscale-ca.mobileconfig
```

**2. iPhone에 설치**

iPhone Safari에서 `http://192.168.x.x:8880/headscale-ca.mobileconfig` 열기

- "허용" 탭 → 프로파일 다운로드 확인창
- 설정 → 일반 → VPN 및 기기 관리 → 프로파일 설치
- 설정 → 일반 → 정보 → 인증서 신뢰 설정 → OpenClaw CA 신뢰 활성화

> **중요**: 인증서 신뢰 설정의 토글이 **켜져 있어야(초록색)** 합니다. 토글이 꺼진 상태에서는 Tailscale Network Extension이 인증서를 신뢰하지 않습니다. Safari에서 "이 연결은 비공개가 아닙니다" 경고에서 "계속"을 눌렀다면 시스템 신뢰가 아닌 Safari 예외만 적용된 것이므로 NE는 여전히 인증서를 거부합니다.

---

## 옵션 A: Dex OIDC (권장) {#option-a}

### 1. `.env` 설정

```bash
HEADSCALE_HOST_IP=192.168.x.x     # 이 장비의 LAN IP
DEX_ENABLED=true
DEX_ADMIN_PASSWORD=<비밀번호>
DEX_CLIENT_SECRET=<랜덤 문자열>    # 생성: openssl rand -hex 24
```

### 2. 셋업 실행

```bash
yarn dex:setup
```

생성되는 파일:
- `infra/dex/certs/dex.crt` — Dex TLS 인증서 (headscale CA로 서명)
- `infra/dex/config.yaml` — OIDC 클라이언트 + 정적 패스워드 설정
- `infra/headscale/config/config.yaml` 에 `oidc:` 섹션 추가

### 3. Dex 시작 및 headscale 재시작

```bash
yarn dex:up
podman restart headscale
```

Dex 정상 동작 확인:
```bash
curl -k https://192.168.x.x:5556/.well-known/openid-configuration
```

JSON 응답 (`issuer`, `authorization_endpoint` 등)이 오면 정상.

### 4. iPhone 연결

1. iPhone에서 **Tailscale** 앱 실행
2. 설정(기어) → Account → 커스텀 서버 URL 입력: `https://192.168.x.x:8080`
3. **Login** 버튼 탭
4. Dex 로그인 페이지 열림 → `admin@openclaw.private` / `DEX_ADMIN_PASSWORD` 입력
5. iPhone이 headscale VPN에 등록됨

> **Login 버튼이 아무 반응 없을 때**: iOS VPN 권한이 아직 부여되지 않은 상태입니다. 트러블슈팅 섹션을 참조하세요. Auth key 입력은 실제 인증 방법으로 사용하지 마세요 — Tailscale iOS는 auth key를 headscale이 아닌 tailscale.com으로 전송합니다.

### 5. 확인

컨트롤 타워에서:
```bash
podman exec headscale headscale nodes list
```

iPhone이 `100.64.x.x` VPN IP로 표시되면 성공.

**iPhone → ntfy 연결 테스트:**
```bash
# iPhone에서 ntfy 앱 → 서버: http://100.64.0.1:8095
# (Tailscale VPN 연결 상태에서)
```

---

## 옵션 B: LAN 한정 {#option-b}

Dex 설정 없이 사용합니다. iPhone은 집 WiFi에서만 ntfy에 접근 가능합니다.

`.env`:
```bash
DEX_ENABLED=false
```

iPhone ntfy 접근: `http://192.168.x.x:8095` (집 WiFi에서만 동작).

---

## 트러블슈팅

### Dex 시작 시 크래시 (`cannot specify static passwords without enabling password db`)

`infra/dex/config.yaml`에 `enablePasswordDB: true`를 추가합니다:

```yaml
enablePasswordDB: true

oauth2:
  skipApprovalScreen: true
```

재시작: `podman compose -f infra/dex/docker-compose.yml restart dex`

### headscale 시작 시 크래시 (`strip_email_domain`/`map_legacy_users` removed)

headscale v0.28 이상에서 이 두 키가 제거됐습니다. `infra/headscale/config/config.yaml`에서 삭제합니다:

```yaml
# 아래 줄이 있다면 삭제:
#   strip_email_domain: true
#   map_legacy_users: false
```

재시작: `podman restart headscale`

### Tailscale Login 버튼이 아무 반응 없음

iOS VPN 권한이 아직 부여되지 않은 상태입니다. 권한 팝업을 트리거하는 방법:
1. Tailscale 설정에서 auth key 필드에 임의 텍스트 입력 후 연결 시도 → iOS가 VPN 권한 팝업을 표시
2. **허용** 탭
3. 다시 Login (OIDC) 플로우로 돌아가기

headscale preauthkey를 auth key로 입력해서 실제 인증하려 하면 안 됩니다 — Tailscale iOS는 auth key를 headscale이 아닌 `tailscale.com`으로 전송합니다. OIDC Login 버튼만이 headscale에 직접 연결합니다.

### Tailscale이 로딩 상태에서 멈춤

Tailscale Network Extension이 headscale과 TLS를 맺지 못하는 상태입니다. 가장 흔한 원인: CA 인증서가 시스템 수준에서 신뢰되지 않음.

확인 방법: iPhone Safari에서 `https://192.168.x.x:8080/health` 열기 — 경고 없이 바로 `{"status":"pass"}` 가 나와야 합니다. 경고창이 뜨면 CA가 신뢰되지 않은 상태이므로 **설정 → 일반 → 정보 → 인증서 신뢰 설정** 에서 토글을 다시 확인하세요.

### Dex 로그인 페이지가 열리지 않음

```bash
# Dex 로그 확인
podman logs dex

# Dex TLS 인증서 SAN 확인
openssl x509 -in infra/dex/certs/dex.crt -text -noout | grep -A5 "Subject Alternative"
```

### headscale OIDC가 활성화되지 않음

```bash
podman logs headscale | grep -i oidc
```

연결 오류가 보이면 → Dex가 headscale 컨테이너에서 접근 불가 상태. `yarn dex:up` 결과 확인.

### iPhone에서 인증서 신뢰 오류

mobileconfig 프로파일 설치만으로는 부족합니다. **인증서 신뢰 설정** (설정 → 일반 → 정보 → 인증서 신뢰 설정) 에서 토글을 직접 켜야 합니다.

---

## Dex 설정 재생성

`DEX_ADMIN_PASSWORD` 또는 `DEX_CLIENT_SECRET`을 변경한 경우:

```bash
rm infra/dex/certs/dex.crt   # 인증서 재생성 필요 시
yarn dex:setup
yarn dex:down && yarn dex:up
podman restart headscale
```
