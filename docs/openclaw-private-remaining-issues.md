# OpenClaw Private 남은 이슈

아래는 성공 루트 문서와 별개로, 현재 운영 시 남아있는 체크 포인트만 분리 정리한 목록이다.

## 1) macOS에서 local DERP 연결 불안정 가능성

- 증상:
  - `tailscale status`에 local relay 연결 실패 health check가 간헐적으로 표시됨
  - `tailscale ping`이 타임아웃될 수 있음
- 빠른 점검:
  - `tailscale netcheck`
  - `tailscale debug derp 999`
  - `tail -n 120 /opt/homebrew/var/log/tailscaled.log`
- 운영 권장:
  - `brew services restart tailscale`
  - macOS Screen Time의 웹 콘텐츠 제한 비활성화 확인

## 2) VM 접근용 headscale 프록시 프로세스 의존성

- 현재 구조는 `scripts/headscale-vm-proxy.mjs` 프로세스가 살아 있어야 VM에서 `192.168.64.1:8080` 접근 가능
- 개선됨: `pnpm start`가 VM 프록시를 자동 기동 (이미 떠있으면 스킵)
- 남은 이슈: Mac 재부팅 시 자동 시작 미구현 (launchd plist 등록 필요)

## 3) Exit Node 커널 플로우 로그 파일 생성 시점

- `infra/tailscale/enable-exit-node-audit.sh` 적용 후에도 실제 포워딩 트래픽이 없으면 `/var/log/openclaw/egress-flow.log`가 비어 있거나 파일이 없을 수 있음
- 운영 권장:
  - 테스트 트래픽 발생 후 `journalctl -k | rg OC_EGRESS` 또는 파일 로그 재확인

## 4) 네트워크 격리 검증 (해결됨)

- `openclaw-internal` 네트워크 (`internal: true`)로 OpenClaw의 직접 인터넷 접근 차단
- 검증 완료:
  - 직접 인터넷 접근: **차단됨**
  - 프록시 경유 접근: **성공 (200)**
- 참고: 컨테이너에 `curl`이 없으므로 `node`로 검증

```bash
# 직접 접근 차단 확인
podman exec openclaw node -e "
  const https = require('https');
  const r = https.get('https://example.com', {timeout: 5000}, () => {
    console.log('FAIL: 직접 접근됨'); process.exit(1);
  });
  r.on('error', () => { console.log('OK: 차단됨'); });
  r.on('timeout', () => { r.destroy(); console.log('OK: 차단됨 (timeout)'); });
"

# 프록시 경유 확인
podman exec openclaw node -e "
  const http = require('http');
  const r = http.request({host:'egress-proxy',port:3128,method:'CONNECT',path:'example.com:443',timeout:5000});
  r.on('connect', (res) => { console.log('OK: 프록시 경유 성공 (' + res.statusCode + ')'); process.exit(0); });
  r.on('error', (e) => { console.log('FAIL: ' + e.message); process.exit(1); });
  r.end();
"
```
