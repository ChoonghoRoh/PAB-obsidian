---
phase: "2-5"
title: "운영 안정화 + 백업 무결성"
team_name: "phase-2-5"
ssot_version: v8.2-renewal-6th   # ver6-2 라인 이행 (2026-08-25). v8.3 policy/model-assignment.md는 이식 보존
created: 2026-08-25
updated: 2026-08-26
current_state: IN_PROGRESS
exceptions: [E-1, E-2, E-3, E-4]
exceptions_ref: docs/phases/phase-2-exceptions.md
master_plan_ref: docs/phases/phase-2-master-plan.md
pre_analysis_ref: docs/phases/phase-2-5-pre-analysis.md
integration_ref: docs/interop/pab-observer/260825-OB2-vault이원화-회신-및-승격사전통지.md   # Observer/UK 관측 연계 (2026-08-25 신설)
interop_refs:
  - docs/interop/pab-observer/260825-OB2A-OB2회답-승격준비확정+B1~B5회신.md   # Observer 회답 (수신, B-1~B-5 전건)
  - docs/interop/pab-prove/260825-PO1-3800X-LiveSync디바이스편입요청.md      # Prove 발신 (수신본)
  - docs/interop/pab-prove/260826-PO2-PO1회답-디바이스편입-조건부승인.md      # 우리 회답 (2026-08-26)
notify_prefix: "[PAB-LLMDATA]"
execution_order: "2-1 직후 · 2-2 이전 (번호와 실행순서 불일치, master-plan §4 명시)"
gate_results:
  G0: SKIP       # research = false — 사전 분석(phase-2-5-pre-analysis.md, APPROVED)이 조사 대체
  G1: PASS       # plan.md Team Lead 검토 승인 (2026-08-25) — 결정사항·리스크·게이트 반영 확인
  G2_infra: PARTIAL  # 2026-08-26 갱신
  #   T-1 PASS (2026-08-25) + volbackup 감시 연계 PASS (2026-08-26, eb1875b — 6분기 전수 시험)
  #   T-2 조건부 PASS — 커밋·푸시 실체 충족(2efb00e). cron 활성화만 BL-3로 잔여
  #   T-3 조건부 PASS — 복원 리허설 PASS(doc_count 3064=3064 / VDU 본문 194자 / _local 13=13).
  #                     서버 cron 등록만 Observer OB2-C 판정 대기
  #   T-7 §작업3 PASS — link-check status 정합(PASS/exit 0, --strict-broken 하위호환)
  #   T-4·T-5·T-6 미착수 (T-5 진행 중)
  #   [T-1 검증 결과]
  #   ✓ Tailnet IP(100.109.251.86) 경유 — localhost 회피 확인
  #   ✓ printf %q 상태파일 규약 준수 (46일 침묵 사고 재발 방지)
  #   ✓ UK_PAB_VAULT_PUSH_URL 미설정 시 Push 생략 후 정상 종료
  #   ✓ 정상 상태 Telegram 발송 0건 — 무소음 확인
  #   ✓ cron 등록: 서버 */5, 맥북 watchdog 주1회 + git-stamp 매시간
  #   ✓ 폴백 구조: UK URL 등록 시 Telegram 자동 중단(PAB_TELEGRAM_FALLBACK=auto)
  #   ✓ HR-5: 최대 463줄 (500줄 미만)
  #   △ 잔여: 스크립트 주석의 문서 경로가 구 경로(phase-2-5-observer-integration-prompt.md)
  #           → OB2 경로로 갱신 필요 (Team Lead 문서 이동에 기인, backend-dev 재스폰 시 처리)
  #   ⏸ G3_smoke 장애 주입은 tester 미스폰 — HR-6 독립성 유지 위해 별도 수행 필요
  G3_smoke: PENDING  # E-3 — 장애 주입 E2E (pytest 대체)
  G4: PENDING
blockers:
  - id: BL-1
    task: "2-5-1"
    desc: "UK_PAB_VAULT_PUSH_URL 미발급 — Observer 측 회신 대기. 미설정 시 Push 생략 동작으로 선배포는 가능(진행 차단 아님)"
    owner: "Observer 측 (사용자 전달)"
  - id: BL-2
    task: "2-5-1"
    desc: "기존 UK CouchDB 모니터 알림 미도달 원인 미규명 — UK는 15초 주기로 /_up 감시 중이었으나 3일 장애가 사람에게 도달하지 않음. 규명 없이는 신규 모니터도 동일 침묵 위험"
    owner: "Observer 측 (사용자 전달)"
  - id: BL-3
    task: "2-5-2"
    status: RESOLVED   # 2026-09-02 사용자 본인 터미널 실행으로 해소
    desc: "[해소] 맥북 crontab **쓰기** 차단(macOS TCC 추정). 2026-09-02 사용자가 deploy_monitoring.sh --local-only 1회 실행하여 해소. 실측(2026-09-02 22:06 KST): crontab 3줄 — 기존 2종 무변경 + `17 */2 * * * ... # PAB-GIT-AUTOCOMMIT` 신규 등재. ⚠️ 등재는 확인됐으나 **발화는 2026-09-03 09:23 기준 0회** — 예정 6회(22:17·00:17·02:17·04:17·06:17·08:17)가 전부 맥북 슬립 창(09-02 22:00 직후 ~ 09-03 09:23:11, kern.waketime 실측)에 포함. macOS cron은 놓친 실행을 보충하지 않음. 다음 기회 09-03 10:17"
    owner: "-"
domain_tags_in_use: [INFRA]
roles:
  team_lead: main
  backend_dev: active        # 2026-09-03 재스폰 — T-3 서버 cron 2줄 등록 준비(등록 실행은 Team Lead 별도 지시 게이트)
  verifier: not_spawned
  tester: not_spawned        # G3_smoke 장애 주입 (HR-6 독립성)
  frontend_dev: not_spawned  # 미사용
sub_phase_artifacts:
  status: docs/phases/phase-2-5/phase-2-5-status.md
  plan: docs/phases/phase-2-5/phase-2-5-plan.md
  todo_list: docs/phases/phase-2-5/phase-2-5-todo-list.md
  tasks_dir: docs/phases/phase-2-5/tasks/
  tasks:
    - tasks/task-2-5-1.md  # [G-1] 헬스 모니터링 + Telegram 알림
    - tasks/task-2-5-2.md  # [G-2] GitHub 오프사이트 백업 정상화 + 자동 커밋·푸시
    - tasks/task-2-5-3.md  # [G-3] CouchDB 볼륨 덤프 백업 + 세대 보존
    - tasks/task-2-5-4.md  # [G-4] 자격증명 회전 (pabadmin·pabbridge)
    - tasks/task-2-5-5.md  # [G-5] workspace.json git 추적 해제
    - tasks/task-2-5-6.md  # [G-6] iPhone LiveSync 연동 검증
    - tasks/task-2-5-7.md  # [G-7] /wiki 스킬 MOC 자동화 + link-check 게이트 (2026-08-26 신설, PO1 §4.4 대응)
5th_mode:
  research: false          # 사전 분석 완료 (APPROVED)
  event: true              # 2026-08-21 CouchDB 3일 장애 사건 대응
  automation: true         # cron 기반 모니터링·백업 자동화
  branch: false            # 신규 스크립트 위주, 충돌 위험 낮음 → main 진행
  multi_perspective: false
decision_points:
  DP-2-5-1: "모니터링 실행 위치 = (A) 3800X crontab + 맥북발 주 1회 역방향 확인 보조"
  DP-2-5-2: "git 자동 커밋 주체 = (A) 맥북 로컬 cron (DP-1 git-authority 무변경)"
  DP-2-5-3: "CouchDB 백업 보존 = 일 1회 × 7세대"
  DP-2-5-4: "bridge 역방향 허용 = N-1(config allowWriteBack 플래그) + ⒜(별도 컨테이너) 병행 — 미러 체인 가용성을 Prove와 분리 (2026-08-26)"
  DP-2-5-5: "N-2 쓰기 실증 = T-4 자격증명 회전과 동시. pabbridge는 VDU 생존으로 사용 불가 → pabprove 신규 발급 (2026-08-26)"
  DP-2-5-6: "정본 정비 2건 = PAB-obsidian 직접 적용 (2026-08-26 완료, orphan 8→0)"
  DP-2-5-7: "/wiki 개선 = 최소 수정(T-7)만 본 Phase 편입. 저장 계층 통합은 범위 밖 (2026-08-26)"
  DP-2-5-8: "T-3 = 물리 볼륨 덤프(논리 백업은 Observer #32가 이미 수행). 고유 가치 = 리비전 트리·뷰 인덱스·볼륨 일관 복구 신뢰성 (2026-08-26)"
  DP-2-5-9: "T-3 정합성 = ⒜ 컨테이너 무정지 + append-only + 아카이브 무결성 검증. ⒝정지는 모니터 3종 동시 알림, ⒞FS 스냅샷은 루트 LV 전체라 과함 (2026-08-26)"
ssot_loaded_at: 2026-08-25T00:00:00
deferred:
  G-8: "Phase 2-2 범위 재정의 (PAB-v4 기존 RAG 중복 인덱싱 회피) — 본 Phase 범위 밖, 2-2 진입 전 별도 판단 (구 G-7, T-7 신설로 재채번)"
  PROVE-1: "저장 계층 통합 (/wiki ↔ Prove safe_write_* 경유) — 의존 방향 유보. 가드 계층 upstream 편입을 대안 제시, Prove 확정 통지 후 판단 (PO2 §5.4)"
  O-4: "서버 증분 60건 선별 기준 미확정 — 편입 경계(편입 실행 완료 시각) 이전 산출물이 대상. OB3에 승격 범위와 함께 정리"
---

# Phase 2-5 Status — 운영 안정화 + 백업 무결성

상태: **IN_PROGRESS** (G1 PASS 2026-08-25, T-1 착수)

## 진입 요약

2026-08-21 서버 재부팅으로 `pab-couchdb` 기동 실패 → **3일간 LiveSync 전면 중단이 미인지**된 사건 대응.
복구는 완료(`ip_nonlocal_bind=1` + `--force-recreate`)했으나 **관측·백업 계층 부재**가 드러나 Phase 2-5를 사후 신설했다.

## 다음 액션 (2026-08-26 갱신)

1. ~~`phase-2-5-plan.md` 확정 → G1 PASS~~ ✅ (2026-08-25)
2. ~~T-1 모니터링~~ ✅ G2_infra 조건부 PASS (2026-08-25)
3. ~~T-2 자동 커밋·푸시~~ ◐ **구현·검증 완료** (커밋 `2efb00e`, 미커밋 0 / 미푸시 0). **cron 활성화만 BL-3로 잔여 — 사용자 터미널 1회 실행 필요**
4. **T-3(CouchDB 물리 볼륨 백업)** ← 진행 중. 스크립트 작성·1회 실행 완료. **복원 리허설 + Observer OB2-C 판정 후 cron 등록**
5. T-4(자격증명 회전 + `pabprove` 발급 + 편입 실행) — 게이트 P-1(Prove R-5)·P-2(Observer 24h) 대기
6. T-5 · T-6 · T-7(§작업 3 완료, SKILL.md 분 완료)
7. tester 스폰 → G3_smoke 장애 주입 E2E (HR-6: 구현자 셀프체크 금지, **사용자 승인 필요** — 가동 서비스 중단 수반)
8. G4 PASS 후 NOTIFY 발송 (`[PAB-LLMDATA]`, NOTIFY-1)

## 외부 협업 상태 (2026-08-26)

| 채널 | 최근 | 우리 대기 | 상대 대기 |
|---|---|---|---|
| PAB-Observer | OB2-A 수신(회답 완료) | OB2-A §8 ①~⑤ 회신 · OB3(승격 실행 통지) | — |
| PAB-Prove | **PO2 발신**(2026-08-26) | PO3(편입 일시 통지) | PO2 §8 R-1~R-6 (**R-5가 편입 게이트 P-1**) |

### 팀 운영 합의 (2026-08-26) — 다음 세션 인계

- **게이트는 작업 지시와 같은 메시지 안에** 넣는다. 후속 메시지로 조건을 추가하면 상대는 이미 움직인 뒤일 수 있다. 바꿔야 하면 *"직전 지시 X를 Y로 대체한다"*고 명시한다 (Team Lead 측 규율 — 이번 세션에 실제로 어겼고 T-5에서 혼선이 났다)
- **공유 자원 비가역 단계 앞에서는 지시가 요구하지 않아도 먼저 확인**한다 — 서버 배포·원격 쓰기·cron·커밋 (backend-dev 측 규율. 이번 세션 T-3 서버 배포가 그 기준이면 멈췄어야 했다)
- **HR-5 분할 방향** (`pab_sync_healthcheck.sh` 499줄, 임계 직전): `check_*` 함수만 별도 파일로. **디스패처·상태관리·알림 규율은 본체 유지** — PR-2(연속실패)/PR-4(md_safe) 상속 구조가 깨지면 알림 규율이 두 벌이 된다

### 세션 종료 시점 잔여 (2026-08-26)

| 항목 | 대기 사유 | owner |
|---|---|---|
| **T-2 cron 활성화** | **BL-3** — 맥북 crontab 쓰기 차단 | **사용자** (`deploy_monitoring.sh --local-only` 1회) |
| T-3 서버 cron 2줄 + `deploy_monitoring.sh` 통합 | Observer **OB2-C** 정식 판정 | Observer(다음 세션) |
| `UK_COUCHDB_VERIFY_PUSH_URL` + `#33` 실번호 | 〃 (코드 변경 불요, 값만 들어오면 동작) | 〃 |
| T-4 자격증명 회전 + `pabprove` 발급 | **PR-1**(T-2 cron 선행) + Prove **R-5** | 사용자·Prove |
| T-6 iPhone LiveSync | `depends_on: 2-5-4` — 회전 전 설정하면 재설정 2회 | 사용자(T-4 이후) |
| T-7 G2_infra E2E | `/wiki` 실사용 시 자연 검증 (더미 노트로 정본 오염 금지) | — |
| G3_smoke 장애 주입 | tester 미스폰 + **가동 서비스 중단 수반 → 사용자 승인 필요** | 사용자 |

**진행 중 조율** (2026-08-26)
- **T-3 사전 통지 완료** — Observer 전건 수용 가능 회신, 정식 판정은 OB2-C. **cron 등록은 판정 후**
- **합의**: `_local` 백업은 Observer `#32`에 추가(이중화, 비용≈0) / T-3 정합성 ⒜ 무정지 확정 / 복원 리허설 절차는 양측 공용으로 공유
- **상호 정정 3건** — 이 협업의 실적: Observer가 §7.1 "미재연결 확정" 철회 · 우리가 OB2-B §2.3 "02:45 연결됨" 철회(r2) · Observer가 "논리 백업은 VDU 미포함" 철회 · 우리가 "`_local`은 논리로 못 받음" 철회. **모두 "관측은 맞았고 결론이 근거보다 넓었던" 같은 형태**
