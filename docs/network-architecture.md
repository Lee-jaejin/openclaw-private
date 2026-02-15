# 네트워크 아키텍처

> OpenClaw Private 네트워크 구조, VPN 개념 설명, 수동 개입 포인트, 미해결 이슈 정리

---

## 1. 이 프로젝트가 하는 일

OpenClaw(AI 어시스턴트)을 프라이빗하게 사용하면서, 나가는 트래픽을 전부 감시한다.

```
┌─ 프라이버시 ──────────────────────────────────────────────┐
│                                                           │
│   사용자 ──→ OpenClaw ──→ Ollama (로컬 LLM)              │
│                │          ↑                               │
│                │          추론은 여기서 끝. 외부 전송 없음  │
│                │                                          │
│                │  혹시 외부로 나가는 트래픽이 있다면?       │
│                ▼                                          │
│           egress-proxy ──→ exit-node ──→ 인터넷           │
│           (Squid 로그)     (iptables 로그)                │
│           ↑                ↑                              │
│           감시 포인트 1     감시 포인트 2                   │
│                                                           │
└───────────────────────────────────────────────────────────┘

핵심: LLM 추론은 로컬. 외부 통신은 프록시 강제 + 이중 로깅.
```

---

## 2. 현재 구조 (단일 머신)

Mac 1대 위에서 모든 것이 돌아간다.

```
┌─ macOS 호스트 (M3 Pro, 36GB) ─────────────────────────────────────┐
│                                                                    │
│   Ollama (호스트)              Tailscale 클라이언트                 │
│   127.0.0.1:11434              100.64.0.1                          │
│        ▲                            │                              │
│        │ host-gateway               │ WireGuard 직접 터널          │
│        │                            │ (같은 브릿지라 DERP 불필요)   │
│        │                            │                              │
│   ┌────┼────────────────────────────┼───── Podman (rootless) ──┐   │
│   │    │                            │                          │   │
│   │    │  ┌── openclaw-internal (bridge, internal) ──────┐     │   │
│   │    │  │                                              │     │   │
│   │    │  │  OpenClaw (:18789)                           │     │   │
│   │    │  │    │ HTTP_PROXY 강제                         │     │   │
│   │    │  │    ▼                                         │     │   │
│   │    │  │  egress-proxy (:3128) ───┐                   │     │   │
│   │    │  │  Squid 감사 로그         │                   │     │   │
│   │    │  │                          │                   │     │   │
│   │    │  └──────────────────────────┼───────────────────┘     │   │
│   │    │                             │                         │   │
│   │    │    Headscale (:8080)        │  default network        │   │
│   │    │    VPN 코디네이터       ─────┘  (인터넷 접근 가능)     │   │
│   │    │                                                       │   │
│   └────┼───────────────────────────────────────────────────────┘   │
│        │                                                           │
└────────┼───────────────────────────────────────────────────────────┘
         │                            │
         │              Multipass bridge (192.168.64.0/24)
         │                            │
┌────────┼────────────────────────────┼─────────────────────────────┐
│        │                            │           oc-exit VM        │
│        │  Tailscale exit-node ◄─────┘                             │
│        │  100.64.0.2                                              │
│        │                                                          │
│        │  iptables NAT + OC_EGRESS 로깅 ◄── egress-proxy 트래픽  │
│        │       │                                                  │
│        ▼       ▼                                                  │
│      (차단)  인터넷                                                │
└───────────────────────────────────────────────────────────────────┘

네트워크 격리:
  OpenClaw → 인터넷 직접: 차단 (internal network, 외부 라우트 없음)
  OpenClaw → egress-proxy: 가능 (같은 internal network)
  OpenClaw → Ollama: 가능 (host-gateway)
  egress-proxy → 인터넷: 가능 (default network)
```

**현재 구조의 특징:**
- `openclaw-internal` 네트워크는 `internal: true` → 외부 라우팅 차단
- OpenClaw은 egress-proxy를 통해서만 외부 접근 가능 (네트워크 레벨 강제)
- Mac과 VM이 같은 Multipass 브릿지 위 → WireGuard **직접 연결**
- DERP 릴레이를 경유하지 않음
- `tailscale ping 100.64.0.2` → `via direct` 로 확인 가능

---

## 3. DERP / STUN / NAT 이해하기

### 직접 연결이 되는 경우 (현재)

같은 네트워크에 있으면 WireGuard가 상대 IP를 직접 찾을 수 있다.

```
  Mac (192.168.64.1)  ←──── WireGuard 직접 ────→  VM (192.168.64.x)

  같은 브릿지 = 서로 보임 = 릴레이 불필요
```

### 직접 연결이 안 되는 경우 (NAT 뒤)

디바이스가 다른 네트워크에 있으면 NAT(공유기) 뒤에 숨어서 서로 못 찾는다.

```
  ┌─ 집 공유기 (NAT) ──────┐        ┌─ 회사 공유기 (NAT) ──────┐
  │                         │        │                          │
  │  Mac                    │        │  다른 디바이스            │
  │  192.168.0.10           │        │  10.0.1.50               │
  │  (사설 IP — 외부에서    │        │  (사설 IP — 외부에서     │
  │   접근 불가)            │        │   접근 불가)             │
  │                         │        │                          │
  └────────┬────────────────┘        └────────┬─────────────────┘
           │ NAT                              │ NAT
           ▼                                  ▼
       203.0.113.5                        198.51.100.8
       (공인 IP)                          (공인 IP)

  문제: 양쪽 다 NAT 뒤 → 서로의 실제 주소를 모름 → 직접 연결 불가
```

### STUN의 역할: "내 공인 주소가 뭐지?"

STUN 서버에 물어봐서 NAT이 부여한 공인 IP:포트를 알아낸다.

```
  Mac ──── "내 주소가 뭐야?" ────→ STUN 서버 (UDP 3478)
  Mac ◄─── "203.0.113.5:34567" ──── STUN 서버

  이제 Mac은 자기 공인 주소를 알고, 이걸 상대에게 알려줄 수 있다.
```

### DERP의 역할: "직접 연결 실패 시 릴레이"

STUN으로 주소를 알아내도 NAT 유형에 따라 직접 연결이 안 될 수 있다.
그때 DERP 서버가 중간에서 패킷을 전달해준다.

```
  직접 연결 시도 (STUN으로 알아낸 주소로):

  Mac ──── WireGuard ────✕ 실패 (NAT이 차단)

  DERP 릴레이로 fallback:

  Mac ────→ DERP 서버 ────→ 다른 디바이스
       암호화 유지    릴레이만 할 뿐
       (E2E)         내용은 못 봄
```

### 전체 연결 흐름

```
  1. Headscale가 디바이스 목록 + DERP 서버 위치를 알려줌
                    │
                    ▼
  2. STUN으로 자기 공인 주소 파악
                    │
                    ▼
  3. 상대방과 직접 WireGuard 연결 시도 ──→ 성공하면 직접 통신
                    │
                    ▼ 실패 시
  4. DERP 릴레이를 통해 패킷 전달 (fallback)
```

### 이 프로젝트에서의 위치

```
  ┌──────────────────────────────────────────────────────┐
  │ Headscale (셀프호스팅 컨트롤 서버)                     │
  │                                                      │
  │  역할 1: 디바이스 등록/인증, ACL 관리                  │
  │  역할 2: 내장 DERP 서버 (region 999)                  │
  │  역할 3: 내장 STUN 서버 (UDP 3478)                    │
  │                                                      │
  │  → 외부 Tailscale SaaS 대신 전부 로컬에서 운영        │
  └──────────────────────────────────────────────────────┘

  현재: 같은 브릿지라 STUN/DERP 안 씀 (직접 연결)
  미래: 외부 디바이스 추가 시 STUN → 직접 연결 시도 → 실패 시 DERP 릴레이
```

---

## 4. 미래 구조 (디바이스 추가 시)

외부 네트워크의 디바이스가 참여하면 DERP가 필요해진다.

```
  ┌─ 집 (NAT 뒤) ────────────────────────────┐
  │                                           │
  │  Mac (Tailscale)                          │
  │  + Podman (Headscale, OpenClaw, ...)      │
  │  + oc-exit VM                             │
  │                                           │
  └───────────────┬───────────────────────────┘
                  │
                  │  1) STUN으로 주소 파악
                  │  2) 직접 연결 시도
                  │  3) 실패 시 DERP 릴레이
                  │
  ┌───────────────┴───────────────────────────┐
  │  Headscale 내장 DERP/STUN                  │
  │  (Mac에서 구동 중, 포트포워딩 필요)         │
  └───────────────┬───────────────────────────┘
                  │
                  │  WireGuard 터널
                  │
  ┌───────────────┴───────────────────────────┐
  │                                           │
  │  회사/카페 (다른 NAT 뒤)                   │
  │  모바일/노트북 (Tailscale)                 │
  │                                           │
  └───────────────────────────────────────────┘

  이때 필요한 추가 작업:
  - Headscale 포트를 공인 IP/도메인으로 노출 (포트포워딩 or VPS)
  - STUN(3478/udp) + DERP(8080/tcp) 모두 외부 접근 가능해야 함
  - 노드 등록 + ACL 업데이트
```

---

## 5. 통신 경로 요약

```
OpenClaw → Ollama (LLM 추론):
  컨테이너 → host.containers.internal:11434 (host-gateway)
  프록시 우회 (NO_PROXY), 로컬 처리

OpenClaw → 외부 (아웃바운드):
  컨테이너 → egress-proxy(:3128) → exit-node VM → 인터넷
  감시: Squid access.log + iptables OC_EGRESS 로그
  강제: internal network → 프록시 외 직접 외부 접근 차단

OpenClaw → 인터넷 직접:
  차단됨 (openclaw-internal network, internal: true)

VM → Headscale (컨트롤 플레인):
  oc-exit VM → 192.168.64.1:8080 → headscale-vm-proxy → 127.0.0.1:8080

Mac Tailscale → Headscale:
  login: 127.0.0.1:8080 (직접)
  DERP:  192.168.64.1:8080 (프록시 경유, 현재는 미사용)
```

---

## 6. 수동 개입 포인트

자동화가 안 되어 직접 머신에서 실행해야 하는 작업들.

### Mac 호스트 (sudo 필요)

| 작업 | 명령 | 빈도 |
|------|------|------|
| CA 인증서 신뢰 등록 | `sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain infra/headscale/certs/ca.crt` | 최초 1회 |
| Tailscale 데몬 재시작 | `brew services restart tailscale` | DERP 불안정 시 |

### Mac 호스트 (sudo 불필요, 수동 실행)

| 작업 | 명령 | 빈도 |
|------|------|------|
| VM 프록시 기동 | `nohup node scripts/headscale-vm-proxy.mjs > logs/headscale-vm-proxy.log 2>&1 &` | 부팅마다 (자동화 미구현) |
| Headscale 노드 등록 | `podman exec headscale headscale nodes register --key <KEY> --user kosmos` | 노드 추가 시 |
| Exit Node 라우트 승인 | `podman exec headscale headscale nodes approve-routes --identifier <ID> --routes 0.0.0.0/0,::/0` | 노드 추가 시 |
| Mac Tailscale 등록 | `tailscale up --login-server=https://127.0.0.1:8080 --exit-node=100.64.0.2 ...` | 최초 1회 |

### Exit Node VM (sudo 필요)

| 작업 | 명령 | 빈도 |
|------|------|------|
| Tailscale 설치 | `curl -fsSL https://tailscale.com/install.sh \| sh` | 최초 1회 |
| CA 인증서 설치 | `sudo cp .../ca.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates` | 최초 1회 |
| 감사 룰 적용 | `sudo bash enable-exit-node-audit.sh` | 최초 1회 (iptables, sysctl, rsyslog) |
| Tailscale 등록 | `sudo tailscale up --login-server=https://192.168.64.1:8080 --advertise-exit-node` | 최초 1회 |

---

## 7. 미해결 이슈

### 1. ~~STUN 포트 미노출~~ (해결됨)

`docker-compose.yml`에 `127.0.0.1:3478:3478/udp` 포트 매핑 추가하여 해결.

### 2. VM 프록시 자동 재시작 없음 (심각도: 중간)

`headscale-vm-proxy.mjs`가 죽으면 VM에서 Headscale 접근 불가. 현재 `nohup &`로만 실행. Mac 재부팅이나 프로세스 크래시 시 수동 재실행 필요.

- 해결 방안: macOS launchd plist로 자동 시작/재시작 등록

### 3. macOS DERP 간헐 불안정 (심각도: 낮음)

macOS Screen Time 웹 콘텐츠 필터가 Tailscale DERP WebSocket 연결을 간섭할 수 있음.

- 점검: `tailscale netcheck`, `tailscale debug derp 999`
- 워크어라운드: Screen Time 웹 콘텐츠 제한 비활성화, `brew services restart tailscale`

### 4. Exit Node flow 로그 빈 파일 (심각도: 낮음)

실제 포워딩 트래픽이 없으면 `/var/log/openclaw/egress-flow.log` 비어있음. 정상 동작이며 트래픽 발생 시 기록됨.

---

## 8. 보안 계층 요약

| 계층 | 구성요소 | 역할 |
|------|---------|------|
| 네트워크 | WireGuard (Headscale + Tailscale) | E2E 암호화, 디바이스 인증, ACL |
| 컨테이너 | Podman rootless, cap-drop ALL | 호스트 격리, 최소 권한 |
| 감사 | egress-proxy (Squid) + iptables 로깅 | 아웃바운드 트래픽 기록 |
| 격리 | openclaw-internal (internal: true) | 프록시 우회 차단, 네트워크 레벨 강제 |
| 데이터 | Ollama 로컬 추론, 외부 전송 없음 | 추론 데이터 유출 방지 |

---

## 9. 운영 커맨드

| 커맨드 | 설명 |
|--------|------|
| `pnpm start` | 전체 서비스 기동 (컨테이너 + VM 프록시) |
| `pnpm stop` | 전체 서비스 중지 |
| `pnpm health` | 헬스 체크 |
| `pnpm monitor` | 실시간 모니터링 |
| `pnpm exit-node:on` | Exit node 경유 활성화 (감시 포인트 2) |
| `pnpm exit-node:off` | Exit node 경유 비활성화 |
| `pnpm audit:egress` | Egress 로그 감사 |
