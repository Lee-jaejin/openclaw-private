---
id: headscale-setup
title: Headscale 설정
sidebar_position: 5
---

# Headscale 설정

자체 호스팅 Tailscale 코디네이터 설정입니다.

## 개요

Headscale은 Tailscale 제어 서버의 자체 호스팅 구현입니다. Tailscale의 클라우드 서비스에 의존하지 않고 자체 프라이빗 WireGuard VPN 네트워크를 운영할 수 있습니다.

## Docker 설치

```bash
cd infra/headscale
docker-compose up -d
```

### 설정 파일

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

## 사용자 관리

```bash
# 사용자 생성
docker exec headscale headscale users create myuser

# 사전 인증 키 생성
docker exec headscale headscale preauthkeys create --user myuser --expiration 24h

# 노드 목록
docker exec headscale headscale nodes list
```

## Tailscale 클라이언트 연결

### macOS

```bash
# Tailscale 설치
brew install tailscale

# Headscale에 연결
tailscale up --login-server https://headscale.your-domain.com --authkey YOUR_PREAUTH_KEY
```

### Linux

```bash
# Tailscale 설치
curl -fsSL https://tailscale.com/install.sh | sh

# 연결
sudo tailscale up --login-server https://headscale.your-domain.com --authkey YOUR_PREAUTH_KEY
```

## 접근 제어 목록 (ACL)

`infra/headscale/acl.json` 생성:

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

ACL 적용:

```bash
docker exec headscale headscale policy set --file /etc/headscale/acl.json
```

## 문제 해결

### 연결 문제

```bash
# Headscale 로그 확인
docker logs -f headscale

# Tailscale 상태 확인
tailscale status

# 연결 테스트
tailscale ping 100.64.0.1
```

### 인증서 문제

HTTPS의 경우 Let's Encrypt 또는 자체 서명 인증서 사용:

```bash
# 자체 서명 인증서 생성
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```
