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
ollama pull <model-name>-q4_0

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
podman logs openclaw

# Verify image exists
podman images | grep openclaw

# Rebuild if needed
podman build -t openclaw:local .
```

### Can't Connect to Ollama from Container

```bash
# Test from inside container
podman exec openclaw curl http://host.containers.internal:11434/api/tags

# Check Podman network
podman network ls

# Verify extra_hosts in docker-compose.yml
```

### Permission Denied

```bash
# Check volume permissions
podman exec openclaw ls -la /home/node/.openclaw

# Fix ownership
podman exec -u root openclaw chown -R node:node /home/node/.openclaw

# Restart container
podman compose restart openclaw
```

### Assistant repeats "read SOUL.md / AGENTS.md" instead of answering

**Symptom:** You ask a question via iMessage; the model spends a long time "thinking" and then keeps saying it should read SOUL.md, AGENTS.md, USER.md, or MEMORY.md, instead of giving a direct answer.

**Cause:** The request sent to the LLM includes project-context instructions meant for an **agent with tools** (e.g. "read SOUL.md every session"). The local Ollama model has **no file-reading tools**, so it cannot act on those instructions and instead **verbalizes** them in a loop. If the entries plugin attaches only a **list of files** (AGENTS.md, SOUL.md) without their contents, the model may fixate on "I need to read these" without ever answering the user.

**What you can do:**

1. **Try disabling the entries plugin** for iMessage so that file lists are not attached to messages. In `config/openclaw.json` set:
   ```json
   "plugins": {
     "entries": {
       "imessage": { "enabled": false }
     }
   }
   ```
   Then restart: `podman restart openclaw`.

2. **Adjust project context / system prompt in OpenClaw.** If you build OpenClaw from source (e.g. the `openclaw` repo), check how system prompts or project guidelines are built for chat sessions. Instructions like "always read SOUL.md, AGENTS.md first" are meant for IDE agents with file access; for iMessage chat, use a simpler instruction such as "answer the user's question directly" and avoid injecting file-reading steps when the model has no tools to read files.

3. **Use a smaller or different model** if the current one tends to over-reason; sometimes a different Ollama model gives more direct answers with the same config.

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
podman ps
curl http://localhost:18789/health
```

### Collect Logs

```bash
# Headscale logs
podman logs headscale > ~/logs/headscale.log

# Ollama logs
journalctl -u ollama > ~/logs/ollama.log

# OpenClaw logs
podman logs openclaw > ~/logs/openclaw.log

# Tailscale logs
sudo tailscale bugreport > ~/logs/tailscale-bugreport.txt
```

### Reset Everything

```bash
# Stop all services
podman compose down
sudo tailscale down
pkill ollama

# Clear data (careful!)
rm -rf ~/.ollama/models/*
podman volume rm openclaw-config openclaw-sessions

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
