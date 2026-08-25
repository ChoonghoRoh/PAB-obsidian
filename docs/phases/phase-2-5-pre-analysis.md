---
phase: "2-5"
title: "운영 안정화 + 백업 무결성 — 사전 분석"
ssot_version: v8.2-renewal-6th   # ver6-2 라인 이행 (2026-08-25). v8.3 policy/model-assignment.md는 이식 보존
created: 2026-08-24
updated: 2026-08-24
status: APPROVED
master_plan_ref: docs/phases/phase-2-master-plan.md
exceptions_ref: docs/phases/phase-2-exceptions.md
trigger: "2026-08-24 CouchDB LiveSync 3일 장애 미인지 사건"
---

# Phase 2-5 사전 분석 (ANALYSIS-1)

## §0 요약

2026-08-21 서버 재부팅으로 `pab-couchdb`가 기동 실패한 뒤 **3일간(08-21 09:50 ~ 08-24 07:42) 라이브싱크가 전면 중단**되었으나, 감지 수단이 없어 우연히 확인할 때까지 인지하지 못했다. 복구는 완료했으나 이 사건은 **운영 관측·백업 계층의 부재**를 드러냈다. 본 문서는 장애 조사 결과와 인프라 갭을 정리하고 Phase 2-5 편성 근거를 제시한다.

## §1 장애 조사 결과 (사실)

### 1.1 타임라인

| 시각 (KST) | 사건 |
|---|---|
| 2026-08-21 09:49:49 | 서버 재부팅 → CouchDB SIGTERM 정상 종료 |
| 2026-08-21 09:49:5x | `restart: unless-stopped` 재기동 시도 → **바인딩 실패** |
| 2026-08-21 ~ 08-24 | `pab-couchdb` Exited(128), `pab-livesync-bridge` 크래시 루프 (3일) |
| 2026-08-24 07:42 | 사용자 상태 확인 요청으로 최초 인지 |
| 2026-08-24 07:5x | 복구 완료 (sysctl + `--force-recreate`) |

### 1.2 근본 원인

```
failed to bind host port 100.109.251.86:5984/tcp: cannot assign requested address
```

- Docker가 `tailscaled`보다 먼저 기동 → `tailscale0`에 `100.109.251.86` 미할당 상태
- `docker-compose.yml:25`가 해당 Tailnet IP에 직접 바인딩 (DP-4 보안 정책)
- `systemctl show docker.service -p After`에 `tailscaled.service` 없음 → **기동 순서 미보장 (구조적 결함)**

### 1.3 2차 결함 (복구 과정에서 발견)

네트워킹 셋업 실패 시 컨테이너가 **네트워크 엔드포인트 없는 상태**(`Networks: {}`, 포트 매핑 공란)로 남는다. 이 상태에서 `docker compose up -d`는 재생성 없이 `start`만 수행하므로 **healthy로 뜨면서도 통신 불가**한 위양성 상태가 된다. `--force-recreate` 필수.

### 1.4 적용한 복구 조치

| 조치 | 내용 | 상태 |
|---|---|---|
| 재발 방지 | `/etc/sysctl.d/99-pab-nonlocal-bind.conf` → `net.ipv4.ip_nonlocal_bind=1` | 적용 (0→1 확인) |
| 컨테이너 복구 | `docker compose up -d --force-recreate` | 완료 |

### 1.5 데이터 영향

**유실 없음.** 로컬 vault 150개 = 서버 미러 150개 일치, CouchDB `pab-llmdata` 문서 3,005개(청크 포함) 정상. 미러 최신 파일과 로컬 마지막 변경이 모두 08-17이라 장애 구간의 갭이 없다.

## §2 인프라 갭 분석

### G-1 (🔴) 헬스 모니터링·알림 전면 부재

- 서버 crontab·systemd timer에 CouchDB/vault 관련 감시 항목 **0건** (조사 확인)
- 3일 장애를 인지하지 못한 직접 원인
- **가용 자산**: `scripts/pmAuto/report_to_telegram.sh` (HR-8 NOTIFY 인프라) 재사용 가능

### G-2 (🔴) GitHub 오프사이트 백업 34일 정체

- 마지막 커밋 `ce4533f` (2026-07-21) → 조사 시점 기준 **34일 공백**
- 미커밋 잔여: 노트 8종, `_INDEX.md` 수정, `무제.canvas` 삭제
- master-plan §3 KPI "GitHub 백업 자동 커밋·푸시 도달"(Phase 2-1) **미달 상태**
- **핵심 리스크**: LiveSync는 복제이지 백업이 아니다. 삭제·손상이 전 기기로 전파되며, 되돌릴 스냅샷이 34일간 없다

### G-3 (🟡) CouchDB 볼륨 백업 부재

- `pab_couchdb_data`(3.6MB) 덤프·스냅샷 자동화 없음
- G-2와 성격 구분: G-2는 vault 내용, G-3은 동기화 메타데이터(청크·리비전)
- 볼륨 손실 시 각 기기에서 재구축은 가능하나 동기화 이력 소실
- Phase 2-1 잔여 인계사항 "백업 자동화(DP-1)"에 해당

### G-4 (🟡) 자격증명 미회전

- `pabadmin`(관리자) — Phase 2-1 PoC 시 세션 노출, 잔여 인계사항에 기록됨
- `pabbridge`(bridge 읽기전용) — 2026-08-24 조사 중 마스킹 패턴 미적용으로 재노출
- 둘 다 Tailnet 내부 한정이나 정식 운영 전 회전 필요

### G-5 (🟡) `workspace.json` git 추적 잔존

- `PAB-LLMDATA/.obsidian/workspace.json`이 여전히 git 추적 중
- master-plan §7 R-2(per-machine churn) 미해소, §3 KPI "per-machine 제외" 미달
- Phase 2-1 T-5가 LiveSync 제외는 처리했으나 git 추적 해제는 누락

### G-6 (🟢) iPhone LiveSync 미검증

- Tailnet에 `chroh-iphone` 등록됨 (현재 idle)
- Phase 2-1 T-4 미완 항목 (당시 폰 offline)

### G-7 (🟢) Phase 2-2 범위 재정의 필요 — **중복 착수 위험**

조사 결과 **PAB-v4가 이미 vault 미러를 인덱싱 중**임을 확인했다.

| 항목 | 실측값 |
|---|---|
| 마운트 | `/home/oceanui/pab-vault-mirror → /vault-mirror` |
| 환경변수 | `OBSIDIAN_VAULT_PATH=/vault-mirror`, `VAULT_MIRROR_WATCH_ENABLED=true`, `VAULT_MIRROR_SCAN_INTERVAL_SECONDS=60` |
| Qdrant | `brain_documents_v4` (1,661 points), `hugrag_bge_m3` |

master-plan §4 Phase 2-2는 "Qdrant + bge-m3 + `pab-kb-mcp` 신규 구축"으로 정의되어 있으나, 이를 그대로 착수하면 **동일 vault를 두 벌 인덱싱**하게 된다. Phase 2-2는 "신규 RAG 구축"이 아니라 **"기존 PAB-v4 RAG를 MCP로 노출"** 로 범위를 재정의해야 한다. 본 Phase 범위 밖이며, Phase 2-2 진입 전 별도 판단 필요.

## §3 Phase 편성 근거

### 3.1 신규 Sub-Phase 필요성

G-1~G-6은 성격이 일관된다 — **가동 중인 인프라의 관측·백업·위생**. master-plan §4의 기존 2-2(RAG/MCP)·2-3(자동화)·2-4(통합검증) 어디에도 속하지 않으며, Phase 2-1의 잔여 인계사항(G-3·G-4·G-6)과 신규 발견(G-1·G-2·G-5)이 섞여 있다. 따라서 **Phase 2-5 신설**이 적절하다.

### 3.2 실행 순서 — 2-2보다 선행

번호는 2-5이나 **의존 순서상 2-1 직후, 2-2 이전**에 실행한다. 근거:

1. 2-2/2-3은 vault 데이터를 소비·가공하는 단계다. 백업·관측 없는 기반 위에 자동화를 쌓으면 장애 시 손실 범위가 커진다
2. G-7(2-2 범위 재정의)이 미해결이므로 2-2 즉시 착수는 불가하다
3. G-1·G-2는 현재 진행형 리스크다 (백업 공백이 매일 늘어남)

### 3.3 Task 편성 (사용자 지정 우선순위 순차)

| Task | 갭 | 내용 | 우선 |
|---|---|---|---|
| T-1 | G-1 | 헬스 모니터링 + Telegram 알림 (cron, 실패 시에만 발송) | 🔴 |
| T-2 | G-2 | GitHub 백업 정상화(미커밋 해소) + 자동 커밋·푸시 | 🔴 |
| T-3 | G-3 | CouchDB 볼륨 덤프 백업 자동화 + 보존 정책 | 🟡 |
| T-4 | G-4 | `pabadmin`·`pabbridge` 자격증명 회전 | 🟡 |
| T-5 | G-5 | `workspace.json` git 추적 해제 (R-2 해소) | 🟡 |
| T-6 | G-6 | iPhone LiveSync 연동 검증 | 🟢 |

## §4 SSOT 예외 적용

Phase 2 예외 E-1~E-4를 **그대로 상속**한다 (신규 예외 없음).

| 예외 | 본 Phase 적용 |
|---|---|
| E-1 G2_infra | 적용 — 코드가 아닌 운영 인프라 산출물 |
| E-2 리팩토링 비대상 | 설정파일 비대상. 단 신규 bash 스크립트는 HR-5 정상 적용 |
| E-3 G3_smoke | 적용 — 장애 주입(컨테이너 강제 정지) 후 알림 수신 검증 |
| E-4 외부 API 금지 | 해당 없음 (추론 없음) |

## §5 리스크

| # | 리스크 | 완화 |
|---|---|---|
| PR-1 | 자격증명 회전(T-4) 시 전 기기 LiveSync 재설정 필요 → 동기화 일시 중단 | T-1·T-2 완료 후 착수. 회전 절차·롤백 문서화 선행 |
| PR-2 | 알림 과다 발송(플래핑) → 알림 피로 | 연속 N회 실패 시에만 발송 + 복구 시 1회 발송 |
| PR-3 | 자동 커밋(T-2)이 충돌·불완전 상태를 커밋 | 데스크톱 git-authority 유지(DP-1). 자동화는 커밋·푸시만, 병합 금지 |
| PR-4 | Telegram `_` 토큰 parse_mode 충돌 | 기존 회피책 적용 (하이픈 치환·escape) |

## §6 결정 포인트 (사용자 확정 2026-08-24)

| # | 항목 | **확정** | 근거·후속 조건 |
|---|---|---|---|
| DP-2-5-1 | 모니터링 실행 위치 | **(A) 3800X crontab** | 의존성 최소·구현 단순. **잔여 위험**: 서버 자체 다운 시 알림 불가 → T-1에 맥북발 주 1회 역방향 확인 보조 장치 포함 |
| DP-2-5-2 | git 자동 커밋 주체 | **(A) 맥북 로컬 cron** | DP-1(데스크톱 git-authority) 정책 무변경. **잔여 위험**: 맥북 장시간 off 시 공백 → T-1이 "마지막 커밋 경과 > 24h" 알림으로 커버 |
| DP-2-5-3 | CouchDB 백업 보존 | **일 1회 × 7세대** | DB 3.6MB로 용량 부담 없음. 일주일 내 발견 가능한 손상에 대응 |

**결정 간 연동**: DP-2-5-1의 잔여 위험(서버 다운 시 침묵)과 DP-2-5-2의 잔여 위험(맥북 off 시 공백)은 서로를 감시하는 구조로 상쇄한다 — 서버 cron이 git 공백을 감시하고, 맥북 주 1회 점검이 서버 침묵을 감시한다. 두 위험이 동시에 실현되는 경우(서버·맥북 동시 장기 정지)는 본 Phase 범위 밖으로 수용한다.

---

**작성**: Team Lead (메인 세션) | **근거**: 2026-08-24 장애 조사 세션 | **다음**: master-plan §4에 Phase 2-5 추가 → 사용자 승인 → entry artifacts 생성
