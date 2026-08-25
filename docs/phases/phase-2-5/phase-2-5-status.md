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
  G2_infra: PARTIAL  # T-1 한정 PASS (Team Lead 독립 검증 2026-08-25). T-2~T-6 미착수
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
domain_tags_in_use: [INFRA]
roles:
  team_lead: main
  backend_dev: spawning      # 2026-08-26 T-2 착수 위해 재스폰 (직전 인스턴스는 T-1 후 HR-7 종료)
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
3. **backend-dev 재스폰 → T-2(자동 커밋 cron) 최우선 착수** ← 현재. 편입이 T-4에 물리고 T-4는 PR-1로 T-2가 선행
4. T-3(CouchDB 볼륨 백업) → T-4(자격증명 회전 + `pabprove` 발급 + 편입 실행)
5. T-5 · T-6 · T-7
6. tester 스폰 → G3_smoke 장애 주입 E2E (HR-6: 구현자 셀프체크 금지, **사용자 승인 필요** — 가동 서비스 중단 수반)
7. G4 PASS 후 NOTIFY 발송 (`[PAB-LLMDATA]`, NOTIFY-1)

## 외부 협업 상태 (2026-08-26)

| 채널 | 최근 | 우리 대기 | 상대 대기 |
|---|---|---|---|
| PAB-Observer | OB2-A 수신(회답 완료) | OB2-A §8 ①~⑤ 회신 · OB3(승격 실행 통지) | — |
| PAB-Prove | **PO2 발신**(2026-08-26) | PO3(편입 일시 통지) | PO2 §8 R-1~R-6 (**R-5가 편입 게이트 P-1**) |
