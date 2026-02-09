---
id: troubleshooting
title: Troubleshooting
sidebar_position: 12
---

# Troubleshooting

Common issues and solutions for the Private AI System.

## Network Issues

### Tailscale Won't Connect

```bash
# Check Headscale server status
headscale nodes list

# Restart Tailscale
sudo tailscale down
sudo tailscale up --login-server https://your-headscale-server

# Check logs
journalctl -u tailscaled -f
```

### Devices Can't See Each Other

```bash
# Verify both devices are connected
tailscale status

# Check ACL configuration
cat /etc/headscale/acl.json

# Test connectivity
tailscale ping <other-device-ip>
```

## Ollama Issues

### Model Won't Load

```bash
# Check available memory
free -h

# Check model status
curl http://localhost:11434/api/ps

# Try smaller quantization
ollama pull codellama:34b-q4_0

# Check disk space
df -h ~/.ollama
```

### Slow Inference

- Check memory pressure in Activity Monitor
- Ensure no other heavy processes running
- Consider using smaller models
- Verify GPU acceleration (if applicable)

### Connection Refused

```bash
# Check if Ollama is running
ps aux | grep ollama

# Start Ollama
ollama serve

# Check binding address
lsof -i :11434
```

## OpenClaw Container Issues

### Container Won't Start

```bash
# Check container logs
docker logs openclaw

# Verify image exists
docker images | grep openclaw

# Rebuild if needed
docker build -t openclaw:local .
```

### Can't Connect to Ollama from Container

```bash
# Test from inside container
docker exec openclaw curl http://host.docker.internal:11434/api/tags

# Check Docker network
docker network ls

# Verify extra_hosts in docker-compose.yml
```

### Permission Denied

```bash
# Check volume permissions
docker exec openclaw ls -la /home/node/.openclaw

# Fix ownership
docker exec -u root openclaw chown -R node:node /home/node/.openclaw

# Restart container
docker-compose restart openclaw
```

## Mobile Issues

### VPN Slow on Mobile

```bash
# Check if using DERP relay
tailscale netcheck

# Same network should be direct
# Different network uses DERP
```

### Battery Drain

- iOS: Enable Background App Refresh for Tailscale
- Android: Exclude Tailscale from battery optimization
- Consider disconnecting when not in use

## General Debugging

### Check System Status

```bash
# All-in-one status check
./scripts/check-status.sh

# Or manually:
tailscale status
curl http://localhost:11434/api/tags
docker ps
curl http://localhost:18789/health
```

### Collect Logs

```bash
# Headscale logs
docker logs headscale > ~/logs/headscale.log

# Ollama logs
journalctl -u ollama > ~/logs/ollama.log

# OpenClaw logs
docker logs openclaw > ~/logs/openclaw.log

# Tailscale logs
sudo tailscale bugreport > ~/logs/tailscale-bugreport.txt
```

### Reset Everything

```bash
# Stop all services
docker-compose down
sudo tailscale down
pkill ollama

# Clear data (careful!)
rm -rf ~/.ollama/models/*
docker volume rm openclaw-config openclaw-sessions

# Restart fresh
./scripts/setup-all.sh
```

## Getting Help

1. Check this troubleshooting guide
2. Review component logs
3. Search GitHub issues
4. Create a new issue with:
   - System info (OS, RAM, CPU)
   - Component versions
   - Error messages
   - Steps to reproduce
