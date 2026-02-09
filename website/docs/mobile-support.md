---
id: mobile-support
title: Mobile Support
sidebar_position: 9
---

# Mobile Support

Accessing the Private AI System from iOS/Android devices.

## Architecture

```
┌─────────────────────────────────────────────────┐
│            Headscale VPN                        │
│                                                 │
│  ┌──────────┐         ┌──────────────────────┐  │
│  │  iPhone  │         │     Server (Mac)     │  │
│  │ Tailscale│ ──VPN─→ │  - Ollama           │  │
│  │          │         │  - OpenClaw         │  │
│  └──────────┘         └──────────────────────┘  │
│                                                 │
│  ┌──────────┐                                   │
│  │ Android  │                                   │
│  │ Tailscale│                                   │
│  └──────────┘                                   │
└─────────────────────────────────────────────────┘
```

## iOS Setup

### 1. Install Tailscale

```
App Store → Search "Tailscale" → Install
```

### 2. Connect to Headscale

1. Open Tailscale app
2. Settings → "Use custom control server"
3. Enter Headscale URL: `https://headscale.your-domain.com`
4. Login (use pre-auth key)

### 3. Generate Pre-auth Key (on server)

```bash
# On Headscale server
headscale preauthkeys create --user your-user --expiration 1h

# Enter generated key on iOS
```

### 4. Verify Connection

```bash
# On server
headscale nodes list

# iOS device should appear in list
```

## Android Setup

### 1. Install Tailscale

```
Play Store → Search "Tailscale" → Install
```

### 2. Connect

Same procedure as iOS:
1. Enter custom control server in app settings
2. Authenticate with pre-auth key
3. Verify connection

## Mobile Clients

### Option 1: Web Interface

```bash
# Enable web UI on server
openclaw gateway run --web-ui

# Access from mobile browser
# http://100.64.x.x:18789 (Tailscale IP)
```

### Option 2: Telegram/Signal Integration

Access through existing messaging apps:

```bash
# Configure Telegram bot on server
openclaw channels add telegram

# Chat with bot from mobile Telegram
```

## Security Considerations

### VPN Required

- ✅ All mobile access goes through Tailscale VPN
- ✅ No public internet exposure
- ✅ Device authentication required (pre-auth key)

### Additional Security (ACL)

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["group:mobile"],
      "dst": ["server:18789"]
    }
  ],
  "groups": {
    "group:mobile": ["iphone-user", "android-user"]
  }
}
```

## Battery Optimization

### iOS

```
Settings → Tailscale → Enable Background App Refresh
```

### Android

```
Settings → Apps → Tailscale → Exclude from battery optimization
```

## Troubleshooting

### VPN Won't Connect

```bash
# Check server status
headscale nodes list

# Re-register device
headscale nodes delete <node-id>
# Reconnect from mobile
```

### Slow Connection

```bash
# Check direct connection
tailscale ping <server-ip>

# If using DERP relay, expect slower speeds
# Same network = direct connection
```
