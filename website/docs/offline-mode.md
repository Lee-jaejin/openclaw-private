---
id: offline-mode
title: Offline Mode
sidebar_position: 10
---

# Offline Mode

Operating the Private AI System without internet access.

## Offline Capability

| Component | Offline | Requirements |
|-----------|---------|--------------|
| Ollama | ✅ Yes | Models pre-downloaded |
| OpenClaw | ✅ Yes | Image pre-built |
| Headscale | ⚠️ Partial | After initial setup |
| Tailscale | ⚠️ Partial | P2P direct connection |

## Preparation (While Online)

### 1. Download Ollama Models

```bash
# Download all required models
ollama pull codellama:34b
ollama pull llama3.3:latest

# Verify downloads
ollama list
```

### 2. Build OpenClaw Image

```bash
cd ~/Study/ai/openclaw
podman build -t openclaw:local .

# Save image (for backup)
podman save openclaw:local -o ~/backups/openclaw-local.tar
```

### 3. Cache Dependencies

```bash
# npm package cache (if needed)
cd ~/Study/ai/openclaw
pnpm install --offline
```

## Offline Execution

### Full Local Mode (Single Device)

```bash
# 1. Start Ollama
ollama serve

# 2. Run OpenClaw (network isolated)
podman run -it --rm --name openclaw-isolated \
  --network none \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  -v ~/config:/home/node/.openclaw:rw \
  -v ~/workspace:/workspace:rw \
  -e HOME=/home/node \
  openclaw:local \
  bash
```

### Local Network Mode (Multiple Devices)

Direct connection without Headscale:

```bash
# Device A (Server)
ollama serve --host 0.0.0.0

# Device B (Client)
export OLLAMA_HOST=http://192.168.1.100:11434
```

### P2P VPN (Tailscale Direct)

Already-connected devices can communicate without Headscale:

```bash
# Check existing connections
tailscale status

# Direct connection doesn't need coordinator
# (But can't add new devices)
```

## Configuration (Offline)

`config/openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/codellama:34b",
        "fallbacks": [
          "ollama/llama3.3:latest"
        ]
      }
    }
  },
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://localhost:11434/v1"
      }
    }
  },
  "offline": true
}
```

## Limitations

### What Doesn't Work Offline

| Feature | Reason | Alternative |
|---------|--------|-------------|
| Model download | Needs internet | Pre-download |
| Cloud APIs | Cloud service | Local LLM |
| New device registration | Needs Headscale | Pre-register |
| Web search | Needs internet | Local docs |

### Performance Considerations

- Local LLM is slower than cloud
- Ensure sufficient RAM
- First inference has model load time

## Emergency Response

### When Internet Goes Down

```bash
# 1. Check current state
ollama list
podman images

# 2. Switch to local mode
# Disable fallback in openclaw.json

# 3. Continue offline work
```

### After Recovery

```bash
# 1. Verify connection
ping 8.8.8.8

# 2. Update models (optional)
ollama pull codellama:34b

# 3. Return to normal mode
```
