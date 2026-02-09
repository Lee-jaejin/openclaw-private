---
id: container-setup
title: Container Setup
sidebar_position: 7
---

# OpenClaw Container Setup

Isolated container configuration for the AI gateway.

## Docker Compose

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
      - OLLAMA_HOST=http://host.docker.internal:11434
      - NODE_ENV=production
    volumes:
      - openclaw-config:/home/node/.openclaw
      - openclaw-sessions:/home/node/.openclaw/sessions
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    extra_hosts:
      - "host.docker.internal:host-gateway"

volumes:
  openclaw-config:
  openclaw-sessions:
```

## Building the Image

```bash
# From project root
docker build -t openclaw:local -f infra/openclaw/Dockerfile .

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
        "baseUrl": "http://host.docker.internal:11434/v1"
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
docker-compose up -d

# View logs
docker logs -f openclaw

# Stop
docker-compose down
```

## Health Check

```bash
# Check container status
docker ps

# Check API health
curl http://localhost:18789/health

# Check Ollama connectivity from container
docker exec openclaw curl http://host.docker.internal:11434/api/tags
```

## Troubleshooting

### Cannot Connect to Ollama

```bash
# Verify host.docker.internal resolves
docker exec openclaw ping host.docker.internal

# Check Ollama is listening
curl http://localhost:11434/api/tags
```

### Permission Denied

```bash
# Check volume permissions
docker exec openclaw ls -la /home/node/.openclaw

# Fix ownership if needed
docker exec -u root openclaw chown -R node:node /home/node/.openclaw
```
