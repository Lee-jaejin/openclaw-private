# Private AI System Architecture

완전히 프라이빗한 AI 메시징 시스템 설계 문서.

## 목표

- 외부 클라우드 의존 없음
- 지정된 기기만 통신 가능
- 모든 통신 암호화
- 로컬 LLM으로 데이터 유출 차단
- 컨테이너 격리로 호스트 보호

## 시스템 구성도

```
┌─────────────────────────────────────────────────────────────────┐
│                    Private Network (Headscale)                   │
│                         WireGuard VPN                            │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                                                             │ │
│  │   ┌──────────┐      ┌──────────────┐      ┌──────────┐     │ │
│  │   │ telmeet  │      │   openclaw   │      │  Ollama  │     │ │
│  │   │ (메시징)  │ ───→ │   (Podman)   │ ───→ │ (로컬LLM) │     │ │
│  │   └──────────┘      └──────────────┘      └──────────┘     │ │
│  │        ↑                   ↑                               │ │
│  │   ┌────┴────┐         ┌────┴────┐                          │ │
│  │   │ Phone   │         │ Laptop  │                          │ │
│  │   │ Client  │         │ Desktop │                          │ │
│  │   └─────────┘         └─────────┘                          │ │
│  │                                                             │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                              │                                   │
│                    ┌─────────▼─────────┐                        │
│                    │    Headscale      │                        │
│                    │  (코디네이터 서버)  │                        │
│                    │  - 기기 인증       │                        │
│                    │  - 키 관리         │                        │
│                    └───────────────────┘                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                               ❌
                        외부 인터넷 차단
```

## 컴포넌트 상세

### 1. Headscale (네트워크 코디네이터)

| 항목 | 설명 |
|------|------|
| 역할 | Tailscale 호환 셀프호스팅 코디네이터 |
| 기능 | 기기 등록, 키 교환, 접근 제어 |
| 위치 | 홈서버 또는 항상 켜져있는 기기 |
| 포트 | 443 (HTTPS), 3478 (STUN) |

### 2. Tailscale Client (각 기기)

| 항목 | 설명 |
|------|------|
| 역할 | WireGuard VPN 클라이언트 |
| 설치 위치 | MacBook, Phone, 기타 기기 |
| 인증 | Headscale에서 사전 승인된 키 |

### 3. Ollama (로컬 LLM)

| 항목 | 설명 |
|------|------|
| 역할 | 로컬 AI 추론 엔진 |
| 모델 | 예: config/openclaw.json의 primary/fallbacks 참고 (llama3.2, qwen2.5-coder 등) |
| 포트 | 11434 (로컬만) |
| 네트워크 | localhost 또는 VPN 내부만 |

### 4. OpenClaw (AI Gateway)

| 항목 | 설명 |
|------|------|
| 역할 | 메시징-AI 연동 게이트웨이 |
| 실행 | Podman 컨테이너 (격리) |
| 포트 | 18789 |
| 모델 연동 | Ollama (VPN 내부) |

### 5. Telmeet (메시징 앱)

| 항목 | 설명 |
|------|------|
| 역할 | 커스텀 프라이빗 메시징 |
| 연동 | openclaw 플러그인 |
| 데이터 | 로컬 저장만 |

## 네트워크 흐름

```
사용자 입력 (Phone/Laptop)
        │
        ▼ [WireGuard 암호화]
   ┌─────────┐
   │ telmeet │
   └────┬────┘
        │
        ▼ [VPN 내부 통신]
   ┌─────────┐
   │openclaw │
   └────┬────┘
        │
        ▼ [localhost]
   ┌─────────┐
   │ Ollama  │
   └────┬────┘
        │
        ▼
   AI 응답 생성 (완전 로컬)
        │
        ▼ [WireGuard 암호화]
   사용자에게 전달
```

## 보안 계층

### Layer 1: 네트워크 격리

```
┌─────────────────────────────────────┐
│  Headscale Private Network          │
│  - WireGuard (ChaCha20, Curve25519) │
│  - 기기별 공개키 인증                 │
│  - 사전 승인된 기기만 참여            │
└─────────────────────────────────────┘
```

### Layer 2: 컨테이너 격리

```
┌─────────────────────────────────────┐
│  Podman Container                   │
│  - no-new-privileges                │
│  - cap-drop ALL                     │
│  - 지정 폴더만 마운트                 │
└─────────────────────────────────────┘
```

### Layer 3: 데이터 격리

```
┌─────────────────────────────────────┐
│  Local LLM (Ollama)                 │
│  - 추론 완전 로컬                    │
│  - 외부 API 호출 없음                │
│  - 모델 가중치만 다운로드 (1회)       │
└─────────────────────────────────────┘
```

## 기기 인증 정책

### 허용 기기 등록 절차

1. Headscale 서버에서 pre-auth key 생성
2. 새 기기에서 Tailscale 설치 + 키로 인증
3. Headscale에서 기기 승인
4. ACL로 접근 범위 제한

### ACL (Access Control List) 예시

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
    "group:trusted": ["user1", "user2"]
  },
  "hosts": {
    "openclaw-server": "100.64.0.1",
    "ollama-server": "100.64.0.2"
  }
}
```

## 데이터 저장 위치

| 데이터 | 위치 | 암호화 |
|--------|------|--------|
| 메시지 | 로컬 기기 | 선택적 |
| 설정 | `config/openclaw.json` (호스트), 컨테이너는 읽기 전용 마운트 | 없음 |
| OpenClaw 데이터·세션 | openclaw-data 볼륨 (`/home/node/.openclaw`) | 없음 |
| 워크스페이스 (SOUL/AGENTS 등) | 호스트 `./workspace` → `/home/node/.openclaw/workspace` | 없음 |
| LLM 모델 | `~/.ollama/models/` | 없음 |
| VPN 키 | `/var/lib/tailscale/` | 있음 |

## 구현 단계

### Phase 1: 로컬 LLM 설정
- [ ] Ollama 설치
- [ ] 모델 다운로드 (llama3.2 또는 codellama)
- [ ] localhost 바인딩 확인

### Phase 2: OpenClaw 격리 실행
- [ ] Podman 이미지 빌드
- [ ] 격리 폴더 구성
- [ ] Ollama 연동 테스트

### Phase 3: Headscale 구축
- [ ] Headscale 서버 설치
- [ ] HTTPS 설정 (자체 인증서 또는 Let's Encrypt)
- [ ] 초기 사용자/기기 등록

### Phase 4: 클라이언트 연결
- [ ] MacBook에 Tailscale 설치
- [ ] Headscale에 연결
- [ ] 다른 기기 추가

### Phase 5: Telmeet 통합
- [ ] telmeet 플러그인 완성
- [ ] openclaw 연동
- [ ] VPN 내부 테스트

### Phase 6: 보안 강화
- [ ] ACL 정책 적용
- [ ] 로그 모니터링 설정
- [ ] 정기 키 로테이션 계획

## 하드웨어 요구사항

### 메인 서버 (MacBook M3 Pro)

| 항목 | 스펙 |
|------|------|
| CPU | Apple M3 Pro |
| RAM | 36GB |
| 역할 | Ollama + OpenClaw + Headscale |

### 권장 모델 크기

| RAM | 최대 모델 |
|-----|----------|
| 36GB | 32B-34B (Q4 양자화) |
| 16GB | 13B-14B |
| 8GB | 7B-8B |

## 장애 대응

### Headscale 서버 다운

- 기존 연결은 유지됨 (P2P)
- 새 기기 등록 불가
- 해결: 서버 재시작 또는 백업 서버

### Ollama 응답 없음

- openclaw가 fallback 모델 사용 (설정 시)
- 또는 에러 반환
- 해결: `ollama serve` 재시작

### VPN 연결 끊김

- 메시징 중단
- 로컬 작업은 계속 가능
- 해결: Tailscale 재연결

## 참고 문서

- [Headscale 공식 문서](https://headscale.net/)
- [Tailscale 문서](https://tailscale.com/kb/)
- [WireGuard 프로토콜](https://www.wireguard.com/)
- [Ollama 문서](https://ollama.ai/)
