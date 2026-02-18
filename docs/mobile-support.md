# 모바일 지원

iOS/Android에서 Private AI System 접근 방법.

## 아키텍처

```
┌─────────────────────────────────────────────────┐
│            Headscale VPN                        │
│                                                 │
│  ┌──────────┐         ┌──────────────────────┐  │
│  │  iPhone  │         │     서버 (Mac)       │  │
│  │ Tailscale│ ──VPN─→ │  - Ollama           │  │
│  │ telmeet  │         │  - OpenClaw         │  │
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

```
1. Tailscale 앱 열기
2. 설정 → "Use custom control server"
3. Headscale URL 입력: https://headscale.your-domain.com
4. 로그인 (pre-auth key 사용)
```

### 3. Pre-auth key 생성 (서버에서)

```bash
# Headscale 서버에서
headscale preauthkeys create --user your-user --expiration 1h

# 생성된 키를 iOS에서 입력
```

### 4. 연결 확인

```bash
# 서버에서 확인
headscale nodes list

# iOS 기기가 목록에 표시되어야 함
```

## Android 설정

### 1. Tailscale 설치

```
Play Store → "Tailscale" 검색 → 설치
```

### 2. 연결

iOS와 동일한 절차:
1. 앱 설정에서 custom control server 입력
2. Pre-auth key로 인증
3. 연결 확인

## telmeet 모바일 클라이언트

### 옵션 1: 웹 인터페이스

```bash
# 서버에서 웹 UI 활성화
node /app/dist/index.js gateway run --web-ui

# 모바일 브라우저에서 접속
# http://100.64.x.x:18789 (Tailscale IP)
```

### 옵션 2: 네이티브 앱 (향후)

- React Native 또는 Flutter로 개발
- Tailscale SDK 통합
- 로컬 알림 지원

### 옵션 3: Telegram/Signal 연동

기존 메시징 앱을 통한 접근:

```bash
# 서버에서 Telegram 봇 설정
node /app/dist/index.js channels add telegram

# 모바일 Telegram에서 봇과 대화
```

## 푸시 알림 (VPN 내부)

### 로컬 푸시 서버 (선택)

```bash
# ntfy (셀프호스팅 푸시)
docker run -d --name ntfy \
  -p 8080:80 \
  binwiederhier/ntfy

# 알림 전송
curl -d "새 메시지 도착" http://100.64.x.x:8080/ai-alerts
```

### iOS Shortcuts 연동

```
1. Shortcuts 앱 열기
2. 새 단축어 만들기
3. "URL 내용 가져오기" 추가
4. Tailscale IP + 엔드포인트 설정
```

## 보안 고려사항

### VPN 필수

```
✅ 모든 모바일 접근은 Tailscale VPN 통과
✅ 공용 인터넷에 노출 없음
✅ 기기 인증 필수 (pre-auth key)
```

### 추가 보안

```bash
# Headscale ACL로 모바일 접근 제한
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
설정 → 앱 → Tailscale → 배터리 최적화 제외
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

# DERP 릴레이 사용 중이면 느림
# 같은 네트워크면 직접 연결 시도
```

## 체크리스트

- [ ] iOS Tailscale 설치
- [ ] Android Tailscale 설치
- [ ] Pre-auth key 생성
- [ ] 모바일 기기 등록
- [ ] 웹 UI 접근 테스트
- [ ] 푸시 알림 설정 (선택)
