---
id: headscale-setup
title: Headscale Setup
sidebar_position: 5
---

# Headscale Setup

Self-hosted Tailscale coordinator configuration.

## Overview

Headscale is a self-hosted implementation of the Tailscale control server. It allows you to run your own private WireGuard VPN network without relying on Tailscale's cloud service.

## Podman Installation

```bash
cd infra/headscale
podman compose up -d
```

### Configuration File

`infra/headscale/config.yaml`:

```yaml
server_url: https://headscale.your-domain.com
listen_addr: 0.0.0.0:8080
metrics_listen_addr: 0.0.0.0:9090
private_key_path: /var/lib/headscale/private.key
noise:
  private_key_path: /var/lib/headscale/noise_private.key
ip_prefixes:
  - 100.64.0.0/10
derp:
  server:
    enabled: false
dns_config:
  nameservers:
    - 1.1.1.1
  base_domain: headscale.local
```

## User Management

```bash
# Create user
podman exec headscale headscale users create myuser

# Generate pre-auth key
podman exec headscale headscale preauthkeys create --user myuser --expiration 24h

# List nodes
podman exec headscale headscale nodes list
```

## Tailscale Client Connection

### macOS

```bash
# Install Tailscale
brew install tailscale

# Connect to Headscale
tailscale up --login-server https://headscale.your-domain.com --authkey YOUR_PREAUTH_KEY
```

### Linux

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Connect
sudo tailscale up --login-server https://headscale.your-domain.com --authkey YOUR_PREAUTH_KEY
```

## Access Control Lists (ACL)

Create `infra/headscale/acl.json`:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["group:trusted"],
      "dst": ["*:*"]
    }
  ],
  "groups": {
    "group:trusted": ["user1"]
  },
  "hosts": {
    "server": "100.64.0.1"
  }
}
```

Apply ACL:

```bash
podman exec headscale headscale policy set --file /etc/headscale/acl.json
```

## Troubleshooting

### Connection Issues

```bash
# Check Headscale logs
podman logs -f headscale

# Verify Tailscale status
tailscale status

# Test connectivity
tailscale ping 100.64.0.1
```

### Certificate Issues

For HTTPS, use Let's Encrypt or self-signed certificates:

```bash
# Generate self-signed cert
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```
