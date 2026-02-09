# Backup/Recovery Strategy

Data protection and recovery plan for Private AI System.

## Backup Targets

| Component | Data Location | Importance |
|-----------|---------------|------------|
| Headscale | `/var/lib/headscale/db.sqlite` | High |
| Headscale Config | `/etc/headscale/config.yaml` | High |
| OpenClaw Config | `~/.openclaw/openclaw.json` | Medium |
| OpenClaw Sessions | `~/.openclaw/sessions/` | Low |
| Ollama Models | `~/.ollama/models/` | Low (re-downloadable) |
| Tailscale Keys | `/var/lib/tailscale/` | High |

## Backup Scripts

### Full Backup

```bash
#!/bin/bash
# backup-private-ai.sh

BACKUP_DIR="$HOME/backups/private-ai/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Headscale (run on server)
cp /var/lib/headscale/db.sqlite "$BACKUP_DIR/headscale.db"
cp /etc/headscale/config.yaml "$BACKUP_DIR/headscale-config.yaml"

# OpenClaw config
cp -r ~/config "$BACKUP_DIR/openclaw-config"

# Compress
tar -czf "$BACKUP_DIR.tar.gz" -C "$(dirname $BACKUP_DIR)" "$(basename $BACKUP_DIR)"
rm -rf "$BACKUP_DIR"

echo "Backup complete: $BACKUP_DIR.tar.gz"
```

### Automated Backup (cron)

```bash
# Daily backup at 3 AM
0 3 * * * /path/to/backup-private-ai.sh >> /var/log/backup.log 2>&1
```

## Recovery Procedures

### Headscale Recovery

```bash
# 1. Stop service
sudo systemctl stop headscale

# 2. Restore DB
sudo cp backup/headscale.db /var/lib/headscale/db.sqlite
sudo cp backup/headscale-config.yaml /etc/headscale/config.yaml

# 3. Set permissions
sudo chown headscale:headscale /var/lib/headscale/db.sqlite

# 4. Start service
sudo systemctl start headscale
```

### OpenClaw Recovery

```bash
# Restore config
cp -r backup/openclaw-config/* ~/config/
```

### Ollama Models (Re-download)

```bash
ollama pull codellama:34b
ollama pull llama3.3:latest
```

## Backup Retention Policy

| Frequency | Retention | Location |
|-----------|-----------|----------|
| Daily | 7 days | Local |
| Weekly | 4 weeks | Local + External |
| Monthly | 6 months | External drive |

## Backup Verification

```bash
#!/bin/bash
# verify-backup.sh

BACKUP_FILE=$1

# Test decompression
tar -tzf "$BACKUP_FILE" > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "✅ Archive OK"
else
  echo "❌ Archive corrupted"
  exit 1
fi

# Headscale DB integrity
sqlite3 "$BACKUP_FILE/headscale.db" "PRAGMA integrity_check;"
```

## Disaster Recovery Scenarios

### Scenario 1: Complete Server Loss

1. Prepare new server
2. Install Headscale
3. Restore DB + config from backup
4. Clients auto-reconnect (keys preserved)

### Scenario 2: Config File Corruption

1. Restore config from latest backup
2. Restart services

### Scenario 3: Ollama Model Loss

1. Re-download with `ollama pull`
2. Configuration remains intact

## Checklist

- [ ] Create backup scripts
- [ ] Configure cron
- [ ] Connect external drive
- [ ] Run recovery test
- [ ] Set up backup alerts

---

## 한국어 (Korean)

### 백업 대상
- Headscale DB 및 설정 (높음)
- OpenClaw 설정 (중간)
- Ollama 모델 (낮음 - 재다운로드 가능)

### 백업 보관 정책
- 일간: 7일 (로컬)
- 주간: 4주 (로컬 + 외장)
- 월간: 6개월 (외장 드라이브)
