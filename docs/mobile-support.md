# Mobile Support

Accessing Private AI System from iOS/Android devices.

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

```
1. Open Tailscale app
2. Settings → "Use custom control server"
3. Enter Headscale URL: https://headscale.your-domain.com
4. Login (use pre-auth key)
```

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

### Option 2: Native App (Future)

- Develop with React Native or Flutter
- Integrate Tailscale SDK
- Support local notifications

### Option 3: Telegram/Signal Integration

Access through existing messaging apps:

```bash
# Configure Telegram bot on server
openclaw channels add telegram

# Chat with bot from mobile Telegram
```

## Push Notifications (VPN Internal)

### Local Push Server (Optional)

```bash
# ntfy (self-hosted push)
docker run -d --name ntfy \
  -p 8080:80 \
  binwiederhier/ntfy

# Send notification
curl -d "New message arrived" http://100.64.x.x:8080/ai-alerts
```

### iOS Shortcuts Integration

```
1. Open Shortcuts app
2. Create new shortcut
3. Add "Get Contents of URL"
4. Configure Tailscale IP + endpoint
```

## Security Considerations

### VPN Required

```
✅ All mobile access goes through Tailscale VPN
✅ No public internet exposure
✅ Device authentication required (pre-auth key)
```

### Additional Security

```bash
# Restrict mobile access with Headscale ACL
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

## Checklist

- [ ] Install iOS Tailscale
- [ ] Install Android Tailscale
- [ ] Generate pre-auth keys
- [ ] Register mobile devices
- [ ] Test web UI access
- [ ] Configure push notifications (optional)

---

## 한국어 (Korean)

### iOS 설정
1. App Store에서 Tailscale 설치
2. 설정에서 custom control server 입력
3. Pre-auth key로 인증

### Android 설정
1. Play Store에서 Tailscale 설치
2. iOS와 동일한 절차

### 보안 고려사항
- 모든 접근은 VPN 통과 필수
- 공용 인터넷 노출 없음
- 기기 인증 필수
