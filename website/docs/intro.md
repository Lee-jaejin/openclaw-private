---
id: intro
title: Introduction
sidebar_position: 1
slug: /
---

# OpenClaw Private

Private AI System for closed-circuit networks. Personal use only.

## Overview

This project provides a complete private AI infrastructure that:

- **No external cloud dependency** - All processing happens locally
- **Only designated devices can communicate** - Secured by WireGuard VPN
- **All communication encrypted** - End-to-end encryption via Headscale/Tailscale
- **Local LLM prevents data leakage** - Using Ollama for local inference
- **Container isolation protects host** - OpenClaw runs in isolated containers

## Components

| Component | Purpose |
|-----------|---------|
| **Headscale** | Self-hosted Tailscale coordinator |
| **Tailscale** | WireGuard VPN client |
| **Ollama** | Local LLM inference engine |
| **OpenClaw** | AI gateway in container |
| **Model Router** | Task-based model selection |

## Model Strategy

Uses Llama family models exclusively:

| Task Type | Model | Use Case |
|-----------|-------|----------|
| **Coding** | CodeLlama 34B | Code generation, debugging |
| **Reasoning** | Llama 3.3 70B | Analysis, complex logic |
| **General** | Llama 3.3 | General conversation |

## Quick Start

```bash
# Clone repository
git clone https://github.com/jaejin/openclaw-private.git
cd openclaw-private

# Run setup
./scripts/setup-all.sh
```

See [Getting Started](/getting-started) for detailed instructions.
