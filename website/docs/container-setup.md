---
id: container-setup
title: Container Setup
sidebar_position: 7
---

# OpenClaw Container Setup

Isolated container configuration for the AI gateway.

## Podman Compose

`infra/openclaw/docker-compose.yml`:

```yaml
version: "3.8"

services:
  openclaw:
    image: openclaw:local
    container_name: openclaw
    restart: unless-stopped
    ports:
      - "18789:18789"
    environment:
      - OLLAMA_HOST=http://host.containers.internal:11434
      - NODE_ENV=production
    volumes:
      - openclaw-config:/home/node/.openclaw
      - openclaw-sessions:/home/node/.openclaw/sessions
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    extra_hosts:
      - "host.containers.internal:host-gateway"

volumes:
  openclaw-config:
  openclaw-sessions:
```

## Building the Image

```bash
# From project root
podman build -t openclaw:local -f infra/openclaw/Dockerfile .

# Or use script
./scripts/build-container.sh
```

## Security Configuration

### Capability Restrictions

```yaml
security_opt:
  - no-new-privileges:true
cap_drop:
  - ALL
```

### Volume Mounts

Only mount necessary directories:

```yaml
volumes:
  - openclaw-config:/home/node/.openclaw:rw
  - /path/to/workspace:/workspace:ro  # Read-only if possible
```

### Network Isolation

For maximum isolation:

```yaml
networks:
  openclaw-net:
    driver: bridge
    internal: true  # No external access
```

## Configuration

### OpenClaw Config

`config/openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/llama3.3:latest",
        "fallbacks": ["ollama/codellama:34b"]
      }
    }
  },
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://host.containers.internal:11434/v1"
      }
    }
  },
  "gateway": {
    "port": 18789,
    "bind": "0.0.0.0"
  }
}
```

## Running

```bash
# Start container
podman compose up -d

# View logs
podman logs -f openclaw

# Stop
podman compose down
```

## Health Check

```bash
# Check container status
podman ps

# Check API health
curl http://localhost:18789/health

# Check Ollama connectivity from container
podman exec openclaw curl http://host.containers.internal:11434/api/tags
```

## Troubleshooting

### Cannot Connect to Ollama

```bash
# Verify host.containers.internal resolves
podman exec openclaw ping host.containers.internal

# Check Ollama is listening
curl http://localhost:11434/api/tags
```

### Permission Denied

```bash
# Check volume permissions
podman exec openclaw ls -la /home/node/.openclaw

# Fix ownership if needed
podman exec -u root openclaw chown -R node:node /home/node/.openclaw
```
