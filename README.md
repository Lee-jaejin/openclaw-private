# openclaw-private

My private OpenClaw setup for closed-circuit networks. Personal use only.

## Overview

Self-hosted AI assistant infrastructure using:

- **Headscale**: Self-hosted Tailscale coordination server
- **Tailscale**: Mesh VPN for secure connectivity
- **Ollama**: Local LLM server
- **OpenClaw**: AI assistant CLI

```
┌─────────────────────────────────────────────────────────────┐
│                     Private Network                          │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │  macOS   │────│ Headscale│────│  Linux   │              │
│  │ (Client) │    │ (Server) │    │ (Server) │              │
│  └────┬─────┘    └──────────┘    └────┬─────┘              │
│       │                               │                     │
│       └───────────┬───────────────────┘                     │
│                   │                                         │
│            ┌──────▼──────┐                                  │
│            │   Ollama    │                                  │
│            │ (Local LLM) │                                  │
│            └──────┬──────┘                                  │
│                   │                                         │
│            ┌──────▼──────┐                                  │
│            │  OpenClaw   │                                  │
│            └─────────────┘                                  │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# Clone and setup
git clone https://github.com/<username>/openclaw-private.git
cd openclaw-private

# This repo expects the OpenClaw source at ./openclaw
# (e.g., git submodule or a checked-out sibling directory).
# Example:
#   git submodule add https://github.com/openclaw/openclaw.git openclaw

# Create your local env (do not commit .env)
cp .env.example .env

# Run complete setup
npm run setup
# or
bash scripts/setup-all.sh
```

## Project Structure

```
openclaw-private/
├── config/                 # OpenClaw configuration
│   └── openclaw.json
├── infra/                  # Infrastructure setup
│   ├── headscale/          # Coordination server
│   ├── tailscale/          # Mesh network client
│   └── ollama/             # Local LLM server
├── scripts/                # Operational scripts
│   ├── setup-all.sh        # Complete setup
│   ├── backup.sh           # Backup routine
│   ├── monitor.sh          # System monitoring
│   └── health-check.sh     # Health checks
├── plugins/                # Custom plugins
│   └── model-router/       # Multi-LLM routing
└── docs/                   # Architecture documentation
```

## Ollama

Ollama를 호스트에 직접 설치하거나 컨테이너로 띄울 수 있다.

```bash
# 호스트 Ollama 사용 (기본)
# .env에 OLLAMA_HOST=http://host.containers.internal:11434
podman compose up

# 컨테이너 Ollama 사용
# .env에 OLLAMA_HOST=http://ollama:11434
podman compose --profile with-ollama up
```

사용할 모델은 `infra/ollama/models.sh`에서, 라우팅 설정은 `config/openclaw.json`에서 관리한다.

## Scripts

```bash
# Health check
npm run health

# Monitor services
npm run monitor

# Backup configuration
npm run backup
```

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Multi-LLM Strategy](docs/multi-llm-strategy.md)
- [Backup & Recovery](docs/backup-recovery.md)
- [Monitoring](docs/monitoring.md)
- [Offline Mode](docs/offline-mode.md)
- [Mobile Support](docs/mobile-support.md)
- [TODO](docs/TODO.md)

## Requirements

- Node.js 22+
- Podman (for containers)
- macOS / Linux

## License

GPL-3.0
