---
id: mobile-support
title: 모바일 지원
sidebar_position: 9
---

# 모바일 지원

iOS/Android 기기에서 Private AI 시스템에 접근하는 방법입니다.

## 아키텍처

```
┌─────────────────────────────────────────────────┐
│            Headscale VPN                        │
│                                                 │
│  ┌──────────┐         ┌──────────────────────┐  │
│  │  iPhone  │         │     서버 (Mac)       │  │
│  │ Tailscale│ ──VPN─→ │  - Ollama           │  │
│  │          │         │  - OpenClaw         │  │
│  └──────────┘         └──────────────────────┘  │
│                                                 │
│  ┌──────────┐                                   │
│  │ Android  │                                   │
│  │ Tailscale│                                   │
│  └──────────┘                                   │
└─────────────────────────────────────────────────┘
```

## iOS 설정

### 1. Tailscale 설치

```
App Store → "Tailscale" 검색 → 설치
```

### 2. Headscale 연결

1. Tailscale 앱 열기
2. 설정 → "Use custom control server"
3. Headscale URL 입력: `https://headscale.your-domain.com`
4. 로그인 (사전 인증 키 사용)

### 3. 사전 인증 키 생성 (서버에서)

```bash
# Headscale 서버에서
headscale preauthkeys create --user your-user --expiration 1h

# iOS에서 생성된 키 입력
```

### 4. 연결 확인

```bash
# 서버에서
headscale nodes list

# iOS 기기가 목록에 나타나야 함
```

## Android 설정

### 1. Tailscale 설치

```
Play Store → "Tailscale" 검색 → 설치
```

### 2. 연결

iOS와 동일한 절차:
1. 앱 설정에서 custom control server 입력
2. 사전 인증 키로 인증
3. 연결 확인

## 모바일 클라이언트

### 옵션 1: 웹 인터페이스

```bash
# 서버에서 웹 UI 활성화
openclaw gateway run --web-ui

# 모바일 브라우저에서 접근
# http://100.64.x.x:18789 (Tailscale IP)
```

### 옵션 2: Telegram/Signal 연동

기존 메시징 앱을 통해 접근:

```bash
# 서버에서 Telegram 봇 설정
openclaw channels add telegram

# 모바일 Telegram에서 봇과 채팅
```

## 보안 고려사항

### VPN 필수

- ✅ 모든 모바일 접근은 Tailscale VPN 통과
- ✅ 공용 인터넷 노출 없음
- ✅ 기기 인증 필수 (사전 인증 키)

### 추가 보안 (ACL)

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["group:mobile"],
      "dst": ["server:18789"]
    }
  ],
  "groups": {
    "group:mobile": ["iphone-user", "android-user"]
  }
}
```

## 배터리 최적화

### iOS

```
설정 → Tailscale → 백그라운드 앱 새로 고침 활성화
```

### Android

```
설정 → 앱 → Tailscale → 배터리 최적화에서 제외
```

## 문제 해결

### VPN 연결 안 됨

```bash
# 서버 상태 확인
headscale nodes list

# 기기 재등록
headscale nodes delete <node-id>
# 모바일에서 다시 연결
```

### 느린 연결

```bash
# 직접 연결 확인
tailscale ping <server-ip>

# DERP 릴레이 사용 시 더 느림
# 같은 네트워크 = 직접 연결
```
