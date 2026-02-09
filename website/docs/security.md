---
id: security
title: Security Layers
sidebar_position: 3
---

# Security Architecture

Multi-layered security approach for the private AI system.

## Layer 1: Network Isolation

```
┌─────────────────────────────────────┐
│  Headscale Private Network          │
│  - WireGuard (ChaCha20, Curve25519) │
│  - Per-device public key auth       │
│  - Pre-approved devices only        │
└─────────────────────────────────────┘
```

## Layer 2: Container Isolation

```
┌─────────────────────────────────────┐
│  Container Runtime                  │
│  - no-new-privileges                │
│  - cap-drop ALL                     │
│  - Designated folders only          │
└─────────────────────────────────────┘
```

## Layer 3: Data Isolation

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
