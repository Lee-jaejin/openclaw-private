# Private AI System - TODO

Architecture documentation and implementation task list.

## Tasks

### 1. Backup/Recovery Strategy
- [x] Headscale DB backup plan
- [x] Config file backup location and schedule
- [x] Recovery procedure documentation
- [x] Automated backup scripts
- [ ] Deploy scripts and configure cron

### 2. Monitoring
- [x] System health check scripts
- [x] Log collection strategy
- [x] Alert setup (macOS notification)
- [x] Resource monitoring
- [ ] Deploy scripts and configure cron

### 3. Update Policy
- [x] Ollama model version management
- [x] Headscale update procedure
- [x] OpenClaw container image refresh
- [x] Rollback plan
- [ ] Deploy version tracking scripts

### 4. Multi-LLM Strategy
- [x] Task-based model auto-selection logic
  - Coding → CodeLlama 34B
  - Reasoning → Llama 3.3 70B
  - General → Llama 3.3
- [x] Model switching API/CLI
- [x] Fallback model configuration
- [ ] Implement routing logic in model-router plugin
- [ ] Run performance benchmarks

### 5. Offline Mode
- [x] P2P communication without Headscale server
- [x] Local-only mode configuration
- [x] Preparation procedures
- [ ] Execute offline tests

### 6. Mobile Support
- [x] iOS Tailscale setup
- [x] Android Tailscale setup
- [x] Web/native options
- [x] Push notifications (ntfy)
- [ ] Test on actual devices

---

## Priority

| Rank | Item | Reason |
|------|------|--------|
| 1 | Multi-LLM Strategy | Core feature, directly affects usability |
| 2 | Backup/Recovery | Data safety |
| 3 | Monitoring | Operational stability |
| 4 | Update Policy | Long-term maintenance |
| 5 | Offline Mode | Additional feature |
| 6 | Mobile Support | Extension feature |

---

## Progress

| Item | Status | Completed |
|------|--------|-----------|
| Backup/Recovery | **Done** | 2026-02-07 |
| Monitoring | **Done** | 2026-02-07 |
| Update Policy | **Done** | 2026-02-09 |
| Multi-LLM Strategy | **In Progress** | - |
| Offline Mode | **Done** | 2026-02-09 |
| Mobile Support | **Done** | 2026-02-09 |

---

## 한국어 (Korean)

### 우선순위
1. 멀티 LLM 전략 - 핵심 기능, 사용성 직결
2. 백업/복구 - 데이터 안전
3. 모니터링 - 운영 안정성
4. 업데이트 정책 - 장기 유지보수
5. 오프라인 모드 - 추가 기능
6. 모바일 지원 - 확장 기능
