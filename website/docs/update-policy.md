---
id: update-policy
title: Update Policy
sidebar_position: 11
---

# Update Policy

Version management and update procedures for Private AI System components.

## Update Schedule

| Component | Recommended | Automation | Importance |
|-----------|-------------|------------|------------|
| Headscale | Monthly | Manual | High |
| Tailscale Client | Auto | Auto | Medium |
| Ollama | Monthly | Manual | Medium |
| Ollama Models | As needed | Manual | Low |
| OpenClaw Image | As needed | Manual | Medium |
| macOS/System | Quarterly | Manual | High |

## Update Procedures

### Headscale

```bash
# 1. Check current version
headscale version

# 2. Backup first
sudo cp /var/lib/headscale/db.sqlite ~/backups/headscale-$(date +%Y%m%d).db

# 3. Update (depends on package manager)
# Debian/Ubuntu
sudo apt update && sudo apt upgrade headscale

# Or direct binary
wget https://github.com/juanfont/headscale/releases/latest/download/headscale_linux_amd64
sudo mv headscale_linux_amd64 /usr/local/bin/headscale
sudo chmod +x /usr/local/bin/headscale

# 4. Restart service
sudo systemctl restart headscale

# 5. Verify
headscale version
sudo systemctl status headscale
```

### Tailscale Client

```bash
# macOS (auto-update enabled)
# Manual update:
brew upgrade tailscale

# App Store version updates automatically
```

### Ollama

```bash
# 1. Current version
ollama --version

# 2. Check running models
curl -s http://localhost:11434/api/ps

# 3. Update
brew upgrade ollama

# 4. Restart service
brew services restart ollama

# 5. Verify
ollama --version
```

### Ollama Models

```bash
# Check for new versions manually
# https://ollama.com/library

# Update all models
bash infra/ollama/models.sh

# Clean old versions
ollama list
ollama rm <old-model>
```

### OpenClaw Container Image

```bash
# 1. Update source
cd ~/Study/ai/openclaw
git pull origin main

# 2. Rebuild image
podman build -t openclaw:local .

# 3. Clean old images
podman image prune
```

## Rollback Procedures

### Headscale Rollback

```bash
# 1. Stop service
sudo systemctl stop headscale

# 2. Restore previous binary (if backed up)
sudo cp ~/backups/headscale-prev /usr/local/bin/headscale

# 3. Restore DB (if needed)
sudo cp ~/backups/headscale-YYYYMMDD.db /var/lib/headscale/db.sqlite

# 4. Start service
sudo systemctl start headscale
```

### OpenClaw Rollback

```bash
# Restore to previous commit
cd ~/Study/ai/openclaw
git checkout <previous-commit>
podman build -t openclaw:local .
```

## Version Tracking

### Version Check Script

```bash
#!/bin/bash
# check-versions.sh

echo "=== Private AI System Versions ==="
echo "Date: $(date)"
echo ""

echo "Headscale: $(headscale version 2>/dev/null || echo 'N/A')"
echo "Tailscale: $(tailscale version 2>/dev/null | head -1 || echo 'N/A')"
echo "Ollama: $(ollama --version 2>/dev/null || echo 'N/A')"
echo "Podman: $(podman --version 2>/dev/null || echo 'N/A')"
echo ""

echo "Ollama Models:"
ollama list 2>/dev/null || echo "N/A"
```

## Pre-Update Checklist

- [ ] Verify backup complete
- [ ] Record current versions
- [ ] Check changelog (breaking changes)
- [ ] Test in staging (if possible)
- [ ] Prepare rollback plan
