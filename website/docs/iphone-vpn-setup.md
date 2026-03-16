---
id: iphone-vpn-setup
title: iPhone VPN Setup
sidebar_position: 10
---

# iPhone VPN Setup

Connect your iPhone to the OpenClaw private network via headscale VPN.

## Background

Tailscale iOS 1.60+ requires OIDC-based authentication even for custom coordination servers — a pre-auth key alone is not enough. This guide covers two options:

| | Option A (recommended) | Option B |
|---|---|---|
| **Method** | Dex OIDC self-hosted | LAN only |
| **iPhone access** | Anywhere (via VPN) | Home WiFi only |
| **Setup required** | Dex container + OIDC config | None |
| **Rule 3** | ✅ No external services | ✅ No external services |

---

## Prerequisites

1. headscale is running (`yarn start`)
2. CA certificate is installed on iPhone — see [iOS CA Certificate Install](#ios-ca-cert)
3. Tailscale app installed on iPhone (App Store)

---

## iOS CA Certificate Install {#ios-ca-cert}

The iPhone must trust the headscale CA before connecting.

**1. Serve the CA cert**

On the control tower:
```bash
yarn ca:serve
```

Output:
```
Serving CA cert at http://192.168.x.x:8880/ca.crt
iOS profile:       http://192.168.x.x:8880/headscale-ca.mobileconfig
```

**2. Install on iPhone**

On iPhone Safari: open `http://192.168.x.x:8880/headscale-ca.mobileconfig`

- Tap "Allow" → profile download prompt appears
- Settings → General → VPN & Device Management → install the profile
- Settings → General → About → Certificate Trust Settings → enable the OpenClaw CA

> **Critical**: The toggle in Certificate Trust Settings must be **ON (green)**. Without this, the Tailscale Network Extension will not trust the certificate even if Safari appears to work. If Safari showed "This connection is not private" and you tapped "proceed anyway", the CA is **not** system-trusted — the NE will still reject it.

---

## Option A: Dex OIDC (Recommended) {#option-a}

### 1. Configure `.env`

```bash
HEADSCALE_HOST_IP=192.168.x.x     # this machine's LAN IP
DEX_ENABLED=true
DEX_ADMIN_PASSWORD=<your-password>
DEX_CLIENT_SECRET=<random-string>  # generate: openssl rand -hex 24
```

### 2. Run Setup

```bash
yarn dex:setup
```

This generates:
- `infra/dex/certs/dex.crt` — Dex TLS cert (signed by headscale CA)
- `infra/dex/config.yaml` — Dex config with OIDC client + static password
- Appends `oidc:` section to `infra/headscale/config/config.yaml`

### 3. Start Dex and Restart headscale

```bash
yarn dex:up
podman restart headscale
```

Verify Dex is healthy:
```bash
curl -k https://192.168.x.x:5556/.well-known/openid-configuration
```

Expected: JSON response with `issuer`, `authorization_endpoint`, etc.

### 4. Connect iPhone

1. Open **Tailscale** app on iPhone
2. Settings (gear) → Account → set custom control server: `https://192.168.x.x:8080`
3. Tap **Login**
4. A Dex login page opens — enter `admin@openclaw.private` and `DEX_ADMIN_PASSWORD`
5. iPhone is registered on the headscale VPN

> **If Login button does nothing**: iOS VPN permission has not been granted yet. Try entering an auth key once (see troubleshooting below) to trigger the VPN permission dialog — grant it — then return to the Login flow. Do **not** use auth keys as the actual auth method; they are sent to tailscale.com, not headscale.

### 5. Verify

On control tower:
```bash
podman exec headscale headscale nodes list
```

iPhone should appear with a `100.64.x.x` VPN IP.

**iPhone → ntfy test:**
```bash
# From iPhone, subscribe to ntfy at http://100.64.0.1:8095
# (VPN must be connected)
```

---

## Option B: LAN Only {#option-b}

No Dex setup needed. iPhone can only access ntfy on home WiFi.

In `.env`:
```bash
DEX_ENABLED=false
```

iPhone ntfy access: `http://192.168.x.x:8095` (home WiFi only).

---

## Troubleshooting

### Dex crashes on startup (`cannot specify static passwords without enabling password db`)

Add `enablePasswordDB: true` to `infra/dex/config.yaml`:

```yaml
enablePasswordDB: true

oauth2:
  skipApprovalScreen: true
```

Then restart: `podman compose -f infra/dex/docker-compose.yml restart dex`

### headscale crashes (`strip_email_domain`/`map_legacy_users` removed)

headscale v0.28+ removed these keys. Remove them from `infra/headscale/config/config.yaml`:

```yaml
# Remove these lines if present:
#   strip_email_domain: true
#   map_legacy_users: false
```

Then restart: `podman restart headscale`

### Tailscale Login button does nothing

The iOS VPN permission has not been granted. To trigger the permission dialog:
1. In Tailscale settings, enter any text in the auth key field and attempt to connect — iOS will show the VPN permission dialog
2. Tap **Allow**
3. Return to the Login flow (OIDC)

Do **not** use headscale preauthkeys as the auth method — Tailscale iOS sends auth keys to `tailscale.com`, not to your headscale. Only the OIDC Login button connects to headscale directly.

### Tailscale shows "loading" indefinitely

The Tailscale Network Extension cannot establish TLS with headscale. Most likely cause: CA certificate not trusted at system level.

Verify: open `https://192.168.x.x:8080/health` in iPhone Safari **without** tapping "proceed anyway" on any warning. If a warning appears, the CA is not trusted — re-enable the toggle in **Settings → General → About → Certificate Trust Settings**.

### Dex login page doesn't load

```bash
# Check Dex logs
podman logs dex

# Verify Dex TLS cert covers the host IP
openssl x509 -in infra/dex/certs/dex.crt -text -noout | grep -A5 "Subject Alternative"
```

### headscale OIDC not activating

```bash
podman logs headscale | grep -i oidc
```

If you see connection errors → Dex is not reachable from headscale. Check that Dex is running and `yarn dex:up` succeeded.

### iPhone certificate not trusted

The CA must be toggled ON in **Certificate Trust Settings** (Settings → General → About → Certificate Trust Settings). Installing the mobileconfig profile alone is not sufficient — the trust toggle must be manually enabled.

---

## Regenerating Dex Config

If you change `DEX_ADMIN_PASSWORD` or `DEX_CLIENT_SECRET`, re-run:

```bash
rm infra/dex/certs/dex.crt   # force cert regeneration (optional)
yarn dex:setup
yarn dex:down && yarn dex:up
podman restart headscale
```
