---
id: architecture
title: System Architecture
sidebar_position: 2
---

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
| Models | See `infra/ollama/models.sh` |
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
