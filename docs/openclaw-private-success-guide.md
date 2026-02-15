# OpenClaw Private 보안 셋업 성공 루트 가이드

이 문서는 이 저장소 기준으로, **가장 단순한 성공 경로**만 정리한 운영 매뉴얼이다.

## 0) 전제

- OS: macOS (호스트)
- 컨테이너: Podman
- VM: Multipass (`oc-exit`)
- Headscale/Tailscale 조합으로 Exit Node 경유
- OpenClaw outbound는 `egress-proxy`로 강제

## 1) 컨테이너 기동

```bash
pnpm start
```

상태 확인:

```bash
podman ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

## 2) Headscale TLS 준비

인증서를 생성한다 (최초 1회). 자세한 절차는 [setup-guide.md](./setup-guide.md#1-tls-인증서-생성)를 참조.

```bash
cd infra/headscale/certs
bash generate.sh   # 또는 수동으로 openssl 명령 실행
```

macOS 신뢰 저장소 등록:

```bash
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  infra/headscale/certs/ca.crt
brew services restart tailscale
```

Headscale 헬스체크:

```bash
curl -kfsS https://127.0.0.1:8080/health
```

## 3) VM에서 Headscale 접근 프록시 실행

Headscale는 localhost 바인딩이므로 VM 접근용 프록시를 실행한다.

```bash
mkdir -p logs
nohup node scripts/headscale-vm-proxy.mjs > logs/headscale-vm-proxy.log 2>&1 &
```

확인:

```bash
tail -n 5 logs/headscale-vm-proxy.log
```

> `pnpm start`를 사용하면 VM 프록시도 자동으로 기동된다.

## 4) Exit Node VM 준비 (Multipass)

VM 생성:

```bash
multipass launch 24.04 --name oc-exit --cpus 2 --memory 2G --disk 20G
```

Tailscale 설치/기동:

```bash
multipass exec oc-exit -- bash -lc 'curl -fsSL https://tailscale.com/install.sh | sh'
multipass exec oc-exit -- sudo systemctl enable --now tailscaled
```

VM에 CA 설치:

```bash
multipass transfer infra/headscale/certs/ca.crt oc-exit:/tmp/openclaw-headscale-ca.crt
multipass exec oc-exit -- sudo cp /tmp/openclaw-headscale-ca.crt /usr/local/share/ca-certificates/openclaw-headscale-ca.crt
multipass exec oc-exit -- sudo update-ca-certificates
```

Exit Node audit 룰 적용:

```bash
multipass transfer infra/tailscale/enable-exit-node-audit.sh oc-exit:/tmp/enable-exit-node-audit.sh
multipass exec oc-exit -- sudo chmod +x /tmp/enable-exit-node-audit.sh
multipass exec oc-exit -- sudo bash /tmp/enable-exit-node-audit.sh
```

## 5) Headscale 사용자/노드 등록

사용자 확인(없으면 생성):

```bash
podman exec headscale headscale users list
podman exec headscale headscale users create kosmos
```

VM 등록:

```bash
multipass exec oc-exit -- sudo tailscale up \
  --login-server=https://192.168.64.1:8080 \
  --accept-routes \
  --accept-dns=false \
  --advertise-exit-node
```

출력된 등록 키로 등록:

```bash
podman exec headscale headscale nodes register --key <VM_REG_KEY> --user kosmos
```

Mac 등록 + Exit Node 지정:

```bash
tailscale up \
  --login-server=https://127.0.0.1:8080 \
  --accept-routes \
  --accept-dns=false \
  --exit-node=100.64.0.2 \
  --exit-node-allow-lan-access=false \
  --force-reauth
```

출력된 등록 키로 등록:

```bash
podman exec headscale headscale nodes register --key <MAC_REG_KEY> --user kosmos
```

## 6) Exit Node 라우트 승인

노드/라우트 확인:

```bash
podman exec headscale headscale nodes list
podman exec headscale headscale nodes list-routes
```

`oc-exit` 노드 ID를 확인한 뒤 default route 승인:

```bash
podman exec headscale headscale nodes approve-routes --identifier <OC_EXIT_NODE_ID> --routes 0.0.0.0/0,::/0
```

## 7) 검증

상태 확인:

```bash
tailscale status
multipass exec oc-exit -- tailscale status
```

Exit Node 설정 확인:

```bash
tailscale status --json | jq '.ExitNodeStatus'
```

## 8) OpenClaw egress audit 확인

리포트 수동 생성:

```bash
pnpm audit:egress --window 15
cat logs/audit/latest.md
```

주기 실행 등록:

```bash
pnpm audit:cron
```

원시 프록시 로그:

```bash
tail -n 30 logs/egress-proxy/access.log
```
