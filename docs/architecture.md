# Private AI System Architecture

Design documentation for a fully private AI messaging system.

## Goals

- No external cloud dependency
- Only designated devices can communicate
- All communication encrypted
- Local LLM prevents data leakage
- Container isolation protects host

## System Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Private Network (Headscale)                   │
│                         WireGuard VPN                            │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                                                             │ │
│  │   ┌──────────┐      ┌──────────────┐      ┌──────────┐     │ │
│  │   │ Messaging│      │   OpenClaw   │      │  Ollama  │     │ │
│  │   │  Client  │ ───→ │  (Container) │ ───→ │(Local LLM│     │ │
│  │   └──────────┘      └──────────────┘      └──────────┘     │ │
│  │        ↑                   ↑                               │ │
│  │   ┌────┴────┐         ┌────┴────┐                          │ │
│  │   │ Phone   │         │ Laptop  │                          │ │
│  │   │ Client  │         │ Desktop │                          │ │
│  │   └─────────┘         └─────────┘                          │ │
│  │                                                             │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                              │                                   │
│                    ┌─────────▼─────────┐                        │
│                    │    Headscale      │                        │
│                    │ (Coordinator)     │                        │
│                    │  - Device auth    │                        │
│                    │  - Key management │                        │
│                    └───────────────────┘                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                               ❌
                        External Internet Blocked
```

## Component Details

### 1. Headscale (Network Coordinator)

| Item | Description |
|------|-------------|
| Role | Tailscale-compatible self-hosted coordinator |
| Features | Device registration, key exchange, access control |
| Location | Home server or always-on device |
| Ports | 443 (HTTPS), 3478 (STUN) |

### 2. Tailscale Client (Each Device)

| Item | Description |
|------|-------------|
| Role | WireGuard VPN client |
| Installed On | MacBook, Phone, other devices |
| Authentication | Pre-approved keys from Headscale |

### 3. Ollama (Local LLM)

| Item | Description |
|------|-------------|
| Role | Local AI inference engine |
| Models | llama3.3, codellama |
| Port | 11434 (local only) |
| Network | localhost or VPN internal only |

### 4. OpenClaw (AI Gateway)

| Item | Description |
|------|-------------|
| Role | Messaging-AI integration gateway |
| Execution | Container (isolated) |
| Port | 18789 |
| Model Integration | Ollama (VPN internal) |

## Network Flow

```
User Input (Phone/Laptop)
        │
        ▼ [WireGuard Encrypted]
   ┌─────────┐
   │ Client  │
   └────┬────┘
        │
        ▼ [VPN Internal]
   ┌─────────┐
   │OpenClaw │
   └────┬────┘
        │
        ▼ [localhost]
   ┌─────────┐
   │ Ollama  │
   └────┬────┘
        │
        ▼
   AI Response (Fully Local)
        │
        ▼ [WireGuard Encrypted]
   Delivered to User
```

## Security Layers

### Layer 1: Network Isolation

```
┌─────────────────────────────────────┐
│  Headscale Private Network          │
│  - WireGuard (ChaCha20, Curve25519) │
│  - Per-device public key auth       │
│  - Pre-approved devices only        │
└─────────────────────────────────────┘
```

### Layer 2: Container Isolation

```
┌─────────────────────────────────────┐
│  Container Runtime                  │
│  - no-new-privileges                │
│  - cap-drop ALL                     │
│  - Designated folders only          │
└─────────────────────────────────────┘
```

### Layer 3: Data Isolation

```
┌─────────────────────────────────────┐
│  Local LLM (Ollama)                 │
│  - Fully local inference            │
│  - No external API calls            │
│  - Model weights downloaded once    │
└─────────────────────────────────────┘
```

## Device Authentication Policy

### Allowed Device Registration

1. Generate pre-auth key on Headscale server
2. Install Tailscale on new device + authenticate with key
3. Approve device on Headscale
4. Restrict access scope with ACL

### ACL (Access Control List) Example

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["group:trusted"],
      "dst": ["*:*"]
    }
  ],
  "groups": {
    "group:trusted": ["user1", "user2"]
  },
  "hosts": {
    "openclaw-server": "100.64.0.1",
    "ollama-server": "100.64.0.2"
  }
}
```

## Data Storage Locations

| Data | Location | Encrypted |
|------|----------|-----------|
| Messages | Local device | Optional |
| Config | `~/.openclaw/` | No |
| Sessions | `~/.openclaw/sessions/` | No |
| LLM Models | `~/.ollama/models/` | No |
| VPN Keys | `/var/lib/tailscale/` | Yes |

## Implementation Phases

### Phase 1: Local LLM Setup
- [ ] Install Ollama
- [ ] Download models (llama3.3 or codellama)
- [ ] Verify localhost binding

### Phase 2: OpenClaw Isolated Execution
- [ ] Build container image
- [ ] Configure isolated folders
- [ ] Test Ollama integration

### Phase 3: Headscale Setup
- [ ] Install Headscale server
- [ ] Configure HTTPS (self-signed or Let's Encrypt)
- [ ] Initial user/device registration

### Phase 4: Client Connection
- [ ] Install Tailscale on MacBook
- [ ] Connect to Headscale
- [ ] Add other devices

### Phase 5: Integration
- [ ] Complete messaging plugin
- [ ] Integrate with OpenClaw
- [ ] Test within VPN

### Phase 6: Security Hardening
- [ ] Apply ACL policies
- [ ] Set up log monitoring
- [ ] Plan periodic key rotation

## Hardware Requirements

### Main Server (MacBook M3 Pro)

| Item | Spec |
|------|------|
| CPU | Apple M3 Pro |
| RAM | 36GB |
| Role | Ollama + OpenClaw + Headscale |

### Recommended Model Sizes

| RAM | Max Model |
|-----|-----------|
| 36GB | 32B-34B (Q4 quantized) |
| 16GB | 13B-14B |
| 8GB | 7B-8B |

## Failure Response

### Headscale Server Down

- Existing connections maintained (P2P)
- Cannot register new devices
- Solution: Restart server or use backup

### Ollama Not Responding

- OpenClaw uses fallback model (if configured)
- Or returns error
- Solution: Restart `ollama serve`

### VPN Disconnected

- Messaging interrupted
- Local work continues
- Solution: Reconnect Tailscale

## References

- [Headscale Documentation](https://headscale.net/)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [WireGuard Protocol](https://www.wireguard.com/)
- [Ollama Documentation](https://ollama.ai/)

---

## 한국어 (Korean)

### 목표
- 외부 클라우드 의존 없음
- 지정된 기기만 통신 가능
- 모든 통신 암호화
- 로컬 LLM으로 데이터 유출 차단

### 보안 계층
1. 네트워크 격리 (WireGuard VPN)
2. 컨테이너 격리
3. 데이터 격리 (로컬 LLM)

### 장애 대응
- Headscale 다운: 기존 연결 유지, 새 등록 불가
- Ollama 응답 없음: fallback 모델 사용
- VPN 끊김: 로컬 작업 계속 가능
