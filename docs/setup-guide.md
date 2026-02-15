# Setup Guide

배포 환경별로 직접 생성해야 하는 민감 파일과 설정 절차를 안내한다.

---

## 1. TLS 인증서 생성

Headscale HTTPS + DERP에 사용할 자체 서명 CA와 서버 인증서를 생성한다.
`infra/headscale/certs/` 디렉토리 전체가 `.gitignore`에 포함되어 있으므로, 각 사용자가 직접 생성해야 한다.

### 사전 조건

- `openssl` CLI (macOS/Linux 기본 포함)

### 1-1. OpenSSL 설정 파일 생성

```bash
mkdir -p infra/headscale/certs
cd infra/headscale/certs
```

**ca-openssl.cnf** (CA 설정):

```ini
[req]
default_bits = 4096
prompt = no
default_md = sha256
x509_extensions = v3_ca
distinguished_name = dn

[dn]
CN = OpenClaw Headscale Root CA

[v3_ca]
basicConstraints = critical, CA:TRUE, pathlen:0
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
```

**server-openssl.cnf** (서버 인증서 설정):

```ini
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
CN = headscale.local

[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = headscale.local
IP.1 = 127.0.0.1
IP.2 = 192.168.64.1    # ← Multipass 브릿지 IP (환경에 맞게 변경)
```

### 1-2. 인증서 생성

```bash
# 1) CA 키 + 인증서
openssl req -x509 -new -nodes \
  -config ca-openssl.cnf \
  -keyout ca.key \
  -out ca.crt \
  -days 3650

# 2) 서버 키 + CSR
openssl req -new -nodes \
  -config server-openssl.cnf \
  -keyout headscale.key \
  -out headscale.csr

# 3) CA로 서버 인증서 서명
openssl x509 -req \
  -in headscale.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -extfile server-openssl.cnf -extensions v3_req \
  -out headscale.crt \
  -days 825
```

### 1-3. macOS 신뢰 등록

```bash
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  infra/headscale/certs/ca.crt
```

### 생성되는 파일 (모두 .gitignore)

| 파일 | 용도 |
|------|------|
| `ca.key` | CA 비밀키 |
| `ca.crt` | CA 공개 인증서 |
| `headscale.key` | 서버 비밀키 |
| `headscale.crt` | 서버 인증서 |
| `headscale.csr` | 서명 요청 (임시) |
| `ca.srl` | 시리얼 번호 (임시) |

---

## 2. 환경 변수 (.env)

```bash
cp .env.example .env
```

`.env`를 열어 실제 값을 채운다:

| 변수 | 설명 |
|------|------|
| `OPENCLAW_GATEWAY_TOKEN` | OpenClaw 게이트웨이 인증 토큰 |
| `TAILSCALE_EXIT_NODE` | exit-node IP 또는 호스트명 (예: `100.64.0.2`) |

`.env`는 `.gitignore`에 포함되어 커밋되지 않는다.

---

## 3. iMessage 채널 설정 (선택)

OpenClaw 컨테이너에서 호스트 macOS의 iMessage CLI를 SSH로 호출하는 구조.

### 3-1. SSH 키 생성

```bash
mkdir -p ~/.openclaw/keys
ssh-keygen -t ed25519 -f ~/.openclaw/keys/openclaw_imsg -N "" -C "openclaw-imsg"
```

### 3-2. 호스트에 공개키 등록

```bash
cat ~/.openclaw/keys/openclaw_imsg.pub >> ~/.ssh/authorized_keys
```

### 3-3. docker-compose 볼륨 마운트 활성화

`infra/openclaw/docker-compose.yml`에서 iMessage 관련 주석을 해제:

```yaml
volumes:
  - ../../config/openclaw.json:/home/node/.openclaw/openclaw.json:ro
  - openclaw-sessions:/home/node/.openclaw/sessions
  - ~/.openclaw/keys/openclaw_imsg:/home/node/.ssh/openclaw_imsg:ro   # 주석 해제
  - ../../scripts/imsg-host:/usr/local/bin/imsg-host:ro               # 주석 해제
```

### 3-4. openclaw.json에 채널 추가

`config/openclaw.json`의 `channels` 섹션:

```json
"channels": {
  "imessage": {
    "enabled": true,
    "cliPath": "/usr/local/bin/imsg-host",
    "dbPath": "/Users/<your-username>/Library/Messages/chat.db"
  }
}
```

### 3-5. imsg-host 환경변수 (선택)

`scripts/imsg-host`는 기본적으로 컨테이너 내 사용자명을 SSH 접속에 사용한다. 호스트 사용자명이 다르면:

```bash
# .env 또는 docker-compose environment에 추가
IMSG_SSH_USER=your-macos-username
```
