# 원격 Linux 머신에서 Ollama 돌리고 OpenClaw에서 연결하기

Jetson AGX Orin 등 GPU가 있는 원격 Linux 머신에서 Ollama를 실행하고,
OpenClaw에서 Headscale/Tailscale VPN(tailnet)으로 해당 Ollama에 연결하는 방법.

---

## 플레이어 정의

| 표기 | 설명 |
|------|------|
| **[맥]** | OpenClaw 호스트. Headscale이 실행 중인 macOS 머신 |
| **[Jetson]** | 원격 Linux 머신. Ollama를 실행할 GPU 서버 |

---

## 전제

- **[맥]** Headscale 컨테이너가 실행 중 (`podman ps | grep headscale`)
- **[Jetson]** Ollama 설치됨 (네이티브 또는 jetson-containers 등)
- 두 머신이 **같은 LAN**에 연결되어 있음 (같은 공유기)

---

## 1. Headscale을 LAN에서 접근 가능하도록 설정

기본값으로 Headscale은 `127.0.0.1`에만 바인딩되어 외부 머신에서 접근 불가하다.

### 1.1 맥의 LAN IP 확인

**[맥]**
```bash
ipconfig getifaddr en0
# 예: 192.168.45.20
```

이 IP를 이하 `<HEADSCALE_LAN_IP>` 로 표기한다.

### 1.2 Jetson에서 맥으로 통신 가능한지 확인

**[Jetson]**
```bash
ping -c 3 <HEADSCALE_LAN_IP>
```

응답이 오면 계속 진행한다.

### 1.3 인증서 SAN에 LAN IP 추가

**[맥]** `infra/headscale/certs/server-openssl.cnf` 의 `[alt_names]` 섹션에 추가:

```ini
[alt_names]
DNS.1 = localhost
DNS.2 = headscale.local
IP.1 = 127.0.0.1
IP.2 = 192.168.64.1
IP.3 = <HEADSCALE_LAN_IP>   # ← 추가
```

### 1.4 인증서 재발급

**[맥]** `infra/headscale/certs/` 디렉토리에서:

```bash
cd infra/headscale/certs

# CSR 재생성
openssl req -new -key headscale.key -out headscale.csr -config server-openssl.cnf

# CA로 서명
openssl x509 -req \
  -in headscale.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out headscale.crt \
  -days 825 -sha256 \
  -extfile server-openssl.cnf -extensions v3_req
```

확인:
```bash
openssl x509 -in headscale.crt -noout -text | grep -A2 "Subject Alternative"
# → IP Address:<HEADSCALE_LAN_IP> 가 목록에 보여야 함
```

### 1.5 docker-compose 포트 바인딩 변경

**[맥]** `infra/headscale/docker-compose.yml` 수정:

```yaml
ports:
  - "0.0.0.0:8080:8080"         # 127.0.0.1 → 0.0.0.0
  - "127.0.0.1:9090:9090"       # Metrics는 로컬 유지
  - "0.0.0.0:3478:3478/udp"     # 127.0.0.1 → 0.0.0.0
```

### 1.6 Headscale config 업데이트

**[맥]** `infra/headscale/config/config.yaml` 두 곳 수정:

```yaml
server_url: https://<HEADSCALE_LAN_IP>:8080   # 기존 IP 교체

derp:
  server:
    ipv4: <HEADSCALE_LAN_IP>                   # 기존 IP 교체
```

### 1.7 Headscale 재시작

**[맥]**
```bash
podman rm -f headscale
cd infra/headscale && podman-compose up -d
```

### 1.8 접근 확인

**[맥]**
```bash
curl -sk https://<HEADSCALE_LAN_IP>:8080/health
# → {"status":"pass"}
```

**[Jetson]**
```bash
curl -sk https://<HEADSCALE_LAN_IP>:8080/health
# → {"status":"pass"}
```

---

## 2. 맥 Tailscale 재연결

Headscale `server_url`이 바뀌었으므로 맥의 Tailscale도 재인증이 필요하다.

### 2.1 Headscale user 확인/생성

**[맥]**
```bash
podman exec headscale headscale users list
# 목록이 비어있으면 생성
podman exec headscale headscale users create kosmos
```

### 2.2 Tailscale 재인증

**[맥]**
```bash
sudo tailscale up \
  --login-server=https://<HEADSCALE_LAN_IP>:8080 \
  --accept-dns=false \
  --accept-routes \
  --force-reauth
```

> `can't change --login-server without --force-reauth` 에러가 나면 `--force-reauth` 추가.
> 에러 없이 실행됐는데 플래그 관련 에러가 나면 에러 메시지에 나온 명령을 그대로 쓰면 된다.

터미널에 등록 URL이 출력된다:
```
https://<HEADSCALE_LAN_IP>:8080/register/nodekey:XXXXXXXXXXXX
```

### 2.3 맥 노드 등록

URL의 `nodekey:` 이후 전체 값을 복사해 **3분 안에** 등록한다.

**[맥] (다른 터미널)**
```bash
podman exec headscale headscale nodes register --user kosmos --key <nodekey값>
```

> `tailscale up` 을 종료하면 nodekey 캐시가 만료된다. 반드시 대기 중인 상태에서 등록한다.

### 2.4 연결 확인

**[맥]**
```bash
tailscale status
# → macbook-pro  kosmos  macOS  -
```

---

## 3. Jetson을 Tailnet에 연결

### 3.1 CA 인증서 Jetson으로 전송

Headscale의 자체 서명 인증서를 Jetson이 신뢰하도록 CA를 설치해야 한다.

SSH가 안 될 경우 Python HTTP 서버로 전송한다.

**[맥]** 임시 HTTP 서버 실행:
```bash
cd infra/headscale/certs
python3 -m http.server 9999
```

**[Jetson]** CA 다운로드:
```bash
curl -o /tmp/headscale-ca.crt http://<HEADSCALE_LAN_IP>:9999/ca.crt
```

**[맥]** 전송 완료 후 서버 종료:
```bash
Ctrl+C
```

### 3.2 CA 인증서 설치

**[Jetson]**
```bash
sudo cp /tmp/headscale-ca.crt /usr/local/share/ca-certificates/headscale-ca.crt
sudo update-ca-certificates
```

설치 확인:
```bash
ls /etc/ssl/certs/ | grep headscale
# → headscale-ca.pem 이 보여야 함

# Headscale 서버에 CA로 접속 확인
curl -v --cacert /tmp/headscale-ca.crt https://<HEADSCALE_LAN_IP>:8080/health
# → {"status":"pass"}
```

### 3.3 Tailscale 설치

**[Jetson]**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable --now tailscaled
```

### 3.4 Headscale에 연결

**[Jetson]** 터미널 1 — 실행 후 URL이 출력되면 그 상태로 대기:
```bash
sudo systemctl restart tailscaled
sudo tailscale up --login-server=https://<HEADSCALE_LAN_IP>:8080 --force-reauth
# → https://<HEADSCALE_LAN_IP>:8080/register/nodekey:XXXXXXXXXXXX 출력됨
```

> 이전에 다른 서버 주소로 시도한 적 있으면 `--force-reauth` 필요.

**[맥]** 터미널 2 — nodekey 복사 후 즉시 등록 (3분 안에):
```bash
podman exec headscale headscale nodes register --user kosmos --key <nodekey값>
```

### 3.5 연결 확인

**[Jetson]**
```bash
tailscale status
tailscale ip -4
# → 100.64.x.x (tailnet IP)
```

**[맥]**
```bash
tailscale status
# → Jetson이 peer 목록에 보여야 함

ping -c 3 <JETSON_TAILNET_IP>
```

**[Jetson]**
```bash
ping -c 3 100.64.0.1   # 맥의 tailnet IP
```

---

## 4. Ollama 바인딩 설정

기본값으로 Ollama는 `127.0.0.1`에만 수신한다. tailnet에서 접근 가능하도록 변경한다.

**[Jetson]** systemd override 파일 생성:
```bash
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf << 'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama
```

바인딩 확인:
```bash
sudo ss -tlnp | grep 11434
# → *:11434  *:*  이 보여야 함 (0.0.0.0 또는 *)
```

**[맥]** tailnet을 통해 Ollama 접근 확인:
```bash
curl -s http://<JETSON_TAILNET_IP>:11434/api/tags | jq .
# → 모델 목록이 출력되어야 함
```

---

## 5. OpenClaw .env 설정

**[맥]** `.env` 수정:
```bash
OLLAMA_HOST=http://<JETSON_TAILNET_IP>:11434
OLLAMA_BASE_URL=http://<JETSON_TAILNET_IP>:11434/v1
OPENCLAW_NO_PROXY=localhost,127.0.0.1,host.containers.internal,ollama,headscale,egress-proxy,<JETSON_TAILNET_IP>
```

**[맥]** OpenClaw 재시작:
```bash
podman compose down && podman compose up -d
```

---

## 6. 최종 확인

**[맥]**
```bash
pnpm health
```

```
[OK] Headscale
[OK] Tailscale
[OK] Ollama API
[OK] Ollama Models
...
```

`Ollama API`, `Ollama Models` 가 OK면 완료.

---

## config/openclaw.json

`config/openclaw.json`의 `models.providers.ollama.baseUrl`은 `${OLLAMA_BASE_URL}`을 참조하므로
`.env`만 바꿔도 Jetson의 Ollama를 바라본다. Jetson에 실제로 pull된 모델 id만
`models` 배열에 넣어 두면 된다 (예: `llama3.1:8b`, `llama3.2:3b`, `phi4:14b`).

---

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| `could not resolve host` | mDNS 미지원 또는 다른 네트워크 | LAN IP 직접 사용 |
| `certificate signed by unknown authority` | CA 미설치 또는 tailscaled 캐시 | `sudo update-ca-certificates && sudo systemctl restart tailscaled` |
| `node not found in registration cache` | nodekey 만료 (3분) | `tailscale up` 실행 중 상태에서 즉시 등록 |
| `can't change --login-server without --force-reauth` | 이전 서버 캐시 존재 | `--force-reauth` 추가 |
| Headscale 재시작 후 user 목록 비어있음 | 볼륨 재생성 (강제 rm 후 up 시) | `headscale users create <name>` 으로 재생성 |
| `Ollama API: not responding at http://localhost:11434` | `pnpm health`가 `.env` 미로드 | `package.json` health 스크립트에 `set -a && . .env && set +a` 추가 |
| Ollama `127.0.0.1:11434` 에 바인딩됨 | systemd override 미적용 | override.conf 생성 후 `daemon-reload && restart ollama` |
| scp hang | SSH 데몬 미실행 또는 host key 확인 대기 | Python HTTP 서버로 파일 전송 |

---

## 요약

| 단계 | 머신 | 작업 |
|------|------|------|
| 1.1~1.2 | 맥 | LAN IP 확인, Jetson에서 맥 ping 확인 |
| 1.3~1.4 | 맥 | 인증서 SAN에 LAN IP 추가 및 재발급 |
| 1.5~1.6 | 맥 | docker-compose 포트 및 config.yaml LAN IP로 변경 |
| 1.7~1.8 | 맥 | Headscale 재시작 및 헬스 확인 |
| 2.1~2.4 | 맥 | Headscale user 생성, Tailscale 재인증 및 노드 등록 |
| 3.1~3.2 | 맥 → Jetson | CA 인증서 전송(HTTP 서버) 및 설치 |
| 3.3~3.4 | Jetson + 맥 | Tailscale 설치, Headscale 연결, 노드 등록 |
| 3.5 | 양쪽 | ping으로 tailnet 연결 확인 |
| 4 | Jetson + 맥 | Ollama `0.0.0.0:11434` 바인딩, curl로 접근 확인 |
| 5 | 맥 | `.env` Jetson tailnet IP로 변경, OpenClaw 재시작 |
| 6 | 맥 | `pnpm health` 로 전체 확인 |
