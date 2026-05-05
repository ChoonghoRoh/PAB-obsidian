---
title: "PAB SSOT — 96개 규칙 통합 인덱스 + 공통 포맷 (6-rules-index + 7-shared-definitions)"
description: "100개 상위 규칙(하위 134개)의 카테고리별 인덱스 — HR/LOCK/FRESH/ENTRY/CHAIN/EDIT/GATE/E/REFACTOR/5TH/EVENT/AUTO/MODE/ASSIGN/LIFECYCLE/REPORT/NOTIFY/ANALYSIS/REFERENCE/PROMPT/WT 21 카테고리. 공통 포맷(GATE/ROLE_CHECK/승인 10종/VAL/VUL/예외 4조항/ITERATION-BUDGET 500K)"
created: 2026-05-05 05:13
updated: 2026-05-05 05:13
type: "[[RESEARCH_NOTE]]"
index: "[[KNOWLEDGE_MGMT]]"
topics: ["[[PAB_SSOT]]", "[[RULES_INDEX]]", "[[CHAIN_RULES]]", "[[HARD_RULES]]"]
tags: [research-note, pab-ssot-nexus, rules, chain, hr, gate, shared-definitions]
keywords: ["HR-1~5", "LOCK-1~5", "FRESH-1~12", "ENTRY-1~5", "CHAIN-1~13", "EDIT-1~5", "G0~G4", "E0~E4", "REFACTOR-1~3", "5TH_*", "EVENT-1~6", "AUTO-1~6", "ASSIGN-1~5", "LIFECYCLE-1~4", "REPORT-1~5", "NOTIFY-1~3", "ANALYSIS-1~3", "WT-1~5", "PROMPT-QUALITY", "ITER-PRE", "ITER-POST", "ITERATION-BUDGET 500K", "GATE_FORMAT", "ANTI-COMPRESSION", "ROLE_CHECK", "VAL", "VUL", "FAIL_COUNTER", "충돌 Type A~E", "Hotfix/Minor/Pattern/POC 예외"]
sources:
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/core/6-rules-index.md"
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/core/7-shared-definitions.md"
aliases: ["96개 규칙", "SSOT 규칙 인덱스", "공통 포맷"]
---

# PAB SSOT — 96개 규칙 인덱스 + 공통 포맷

> 100개 상위 규칙(하위 134개), 21 카테고리, 7 원본 파일. 심각도 분포: CRITICAL 42 / HIGH 37 / MEDIUM 18 / LOW 1.

## §1 카테고리별 색인

### HR — Hard Rules (절대 위반 금지) — 5개

| ID | 제목 | 요약 |
|---|---|---|
| **HR-1** | Team Lead 코드 수정 금지 | Team Lead는 코드 Edit/Write 금지, 팀원 위임 전용 |
| **HR-2** | Phase 산출물 생략 금지 | status/plan/todo-list/tasks 4종 필수 (CHAIN-6) |
| **HR-3** | 컨텍스트 복구 시 SSOT 리로드 | 세션 복구 시 0-entrypoint → status → 팀 확인 필수 |
| **HR-4** | Phase 문서 경로 규칙 | master-plan → docs/phases/ 루트, phase 문서 → 하위 폴더 (CHAIN-10) |
| **HR-5** | 리팩토링 규정 | 500줄 등록 / 700줄 Level 분류 / 1000줄 즉시 편성 (REFACTOR-1~3) |

> CLAUDE.md(본 PAB-obsidian 프로젝트)는 SSOT 본체 HR-1~5에 추가로 **HR-6(ASSIGN)** + **HR-7(LIFECYCLE)** + **HR-8(NOTIFY)** 3개를 더 정의.

### LOCK — SSOT 잠금 — 5개

| ID | 요약 |
|---|---|
| LOCK-1 | Phase 실행 중 SSOT 변경 금지 |
| LOCK-2 | 변경 불가피 시 BLOCKED 전이 후 변경 |
| LOCK-3 | 변경 후 모든 팀원에게 SendMessage로 리로드 지시 |
| LOCK-4 | 팀원 SSOT 수정 금지 (읽기 전용) |
| LOCK-5 | 변경 이력 필수 기록 |

### FRESH — SSOT 신선도 — 12개

| ID | 시점 | 행동 |
|---|---|---|
| FRESH-1 | 세션 시작 | SSOT 0→1→2→3 로드 |
| FRESH-2 | 새 Phase 시작 | ssot_version 일치 확인 |
| FRESH-3 | 버전 불일치 감지 | Phase 전 리로드 |
| FRESH-4 | 리로드 완료 | ssot_loaded_at 타임스탬프 기록 |
| FRESH-5 | 장기 세션 (Task 3+) | SSOT 버전 재확인 권장 |
| FRESH-6 | 팀원 스폰 | `ROLES/*.md` 1개 로딩 |
| FRESH-7 | 컨텍스트 복구 | SSOT 리로드 + status + 팀 확인 (=HR-3) |
| FRESH-8 | Phase 완료 | 500줄 초과 등록, Master Plan 시 700줄 편성 |
| FRESH-9 | 작업 1회 시작 | 권장 로딩 집합 (선택) |
| FRESH-10 | SUB-SSOT 모듈 | 역할별 진입점 + 공통 레이어만 로딩 |
| FRESH-11 | SUB-SSOT 동반 | `core/7-shared-definitions.md` 항상 함께 로딩 |
| FRESH-12 | SUB-SSOT 검증 | 공통 + SUB-SSOT만으로 단독 실행 가능해야 |

### ENTRY — 진입점 프로토콜 — 5개

| ID | 요약 |
|---|---|
| ENTRY-1 | status.md 먼저 읽고 시작 |
| ENTRY-2 | current_state 값으로 행동 결정 |
| ENTRY-3 | 진입 시 ssot_version 일치 확인 |
| ENTRY-4 | blockers 비어있지 않으면 우선 해결 |
| ENTRY-5 | status 미확인 후 Task 시작 금지 |

### CHAIN — Phase Chain — 13개 (CHAIN-1~11 + CHAIN-12/13 AutoCycle)

| ID | 요약 |
|---|---|
| CHAIN-1 | Phase 독립성 — 각 Phase 단독 실행 가능 |
| CHAIN-2 | Phase 간 전환 시 `/clear` 필수 |
| CHAIN-3 | Chain 파일 디스크 영속 |
| CHAIN-4 | phases 배열 순서대로만 (건너뛰기 금지) |
| CHAIN-5 | DONE 시 1줄 요약을 Chain 파일에 기록 |
| CHAIN-6 | 산출물 의무 (=HR-2) |
| CHAIN-7 | G0~G4 생략 불가 (G0은 research=true 시) |
| CHAIN-8 | status.md YAML frontmatter 형식 |
| CHAIN-9 | task-X-Y-N.md 메타 4종 + §1~§4 섹션 |
| CHAIN-10 | 파일 경로 규칙 (=HR-4) |
| CHAIN-11 | Master Plan 완료 시 final-summary-report.md 작성 |
| **CHAIN-12** | 차기 Phase 시작 시 직전 tech-debt-report.md 자동 로딩 (carryover 확인) |
| **CHAIN-13** | 차기 Phase 시작 시 직전 최대 3개 master-final-report 요약 자동 로딩 (기억 전달) |

### ITER — AutoCycle 반복 + 예산 (ver8.1)

| ID | 요약 |
|---|---|
| **ITER-PRE** | Pre-Build Iteration Loop — Step 1~5 사전 반복 최대 3회. 3회 후 G-Pre 수렴 게이트. 미충족 시 범위 축소/사용자 승인 (CRITICAL) |
| **ITER-POST** | Post-Build Re-plan Loop — Step 8 재계획 최대 2회. 초과 시 Tech Debt 전이 (CRITICAL) |
| **ITERATION-BUDGET** | 1 사이클 토큰 상한 **500K**. 80% 도달 시 WARNING, 100% 시 HALT + 에스컬레이션. 사용자 "예산 무제한" 선언 시 예외 (CRITICAL) |

### EDIT — 코드 편집 권한 — 5개

| ID | 요약 |
|---|---|
| EDIT-1 | backend-dev: backend/tests/scripts, frontend-dev: web/e2e |
| EDIT-2 | Team Lead 코드 수정 금지 (=HR-1) |
| EDIT-3 | status.md/SSOT는 Team Lead만 수정 |
| EDIT-4 | verifier(Explore)·planner(Plan) 쓰기 권한 없음 |
| EDIT-5 | 동일 파일 두 팀원 동시 편집 금지, [FS]는 BE→FE 순차 |

### GATE — 품질 게이트 — 5개

상세 PASS 기준은 [[2026-05-05_pab_ssot_workflow|워크플로우 노트 §품질 게이트]].

| ID | 요약 |
|---|---|
| **G0** | Research 완료 + 대안 2+ + 리스크 분석 (5th 신규) |
| **G1** | 완료 기준 명확, Task 3~7개, 도메인 분류, 리스크 식별 |
| **G2** | Critical 0건 (ORM/Pydantic/타입/ESM/esc/CDN) |
| **G3** | pytest PASS + 커버리지 ≥80% + E2E + 회귀 + 결함 밀도 ≤5/KLOC |
| **G4** | G2 + G3 PASS + Blocker 0 |

### ERROR — 에러 처리 등급 — 5개

| ID | 등급 | 처리 |
|---|---|---|
| E0 | Critical | 즉시 중단, 사용자 보고 |
| E1 | Blocker | BLOCKED 전이, Fix Task 생성 |
| E2 | High | REWINDING, 수정 요청 |
| E3 | Medium | Tech Debt 등록 |
| E4 | Low | 기록만 |

### REFACTOR — 코드 유지관리 — 3개

| ID | 시점 | 조치 |
|---|---|---|
| REFACTOR-1 | Phase X-Y DONE | 코드 스캔 → 500+ 레지스트리 등록 |
| REFACTOR-2 | Master Plan 작성 | 700+ Lv1/Lv2 분류 후 리팩토링 편성 |
| REFACTOR-3 | PLANNING/BUILDING/G2 | 신규 코드 500+ 사전 방지 |

### 5TH — 5세대 조건부 플래그 — 5개

| ID | 효과 |
|---|---|
| 5TH_RESEARCH | research=true → RESEARCH + G0 |
| 5TH_EVENT | event=true → JSONL + Heartbeat |
| 5TH_AUTOMATION | automation=true → AUTO_FIX + Persister + AutoReporter |
| 5TH_BRANCH | branch=true → Phase Git 격리 + 체크포인트 |
| 5TH_MULTI | multi_perspective=true → 11명 Verification Council |

### EVENT — 이벤트 프로토콜 — 6개 (하위 15)

상세는 [[2026-05-05_pab_ssot_event_automation|이벤트·자동화 노트]].

| ID | 요약 |
|---|---|
| EVENT-1 | JSONL 스키마 — 1line-1JSON, UTF-8, 필수 6필드, 8 event_type |
| EVENT-2 | Heartbeat — 5~10분, 미수신 시 에스컬레이션 |
| EVENT-3 | Watchdog SLA — 역할별 10~15분, 3단계 에스컬레이션 |
| EVENT-4 | 모든 상태 전이 자동 로깅, Git 태그 생성 |
| EVENT-5 | G0~G4 결과 로깅 (verdict/score/council) |
| EVENT-6 | /tmp 활성, docs/ 아카이브, 10MB 경고 |

### AUTO — 자동화 파이프라인 — 6개 (하위 31)

| ID | 요약 |
|---|---|
| AUTO-1 | Artifact Persister — 산출물 무결성 + CHAIN-6 자동 검증 |
| AUTO-2 | AutoReporter — Task/상태/Gate 자동 진행 리포트 |
| AUTO-3 | DecisionEngine — AUTO_FIX **6조건 AND**, 최대 3회 |
| AUTO-4 | 활성화 제어 — `5th_mode.automation` |
| AUTO-5 | ContextRecovery — FRESH-7 절차, HR-1/2/3 준수 검증 |
| AUTO-6 | Git Checkpoint — 상태 전이 태그, REWINDING 복구, A/B 패턴 |

### MODE — 교차 문서 — 2개

| ID | 요약 |
|---|---|
| MODE-1 | 5세대 이중축 — Event-first + Automation-first |
| MODE-2 | 5th_mode 미설정 시 4th 호환 모드 |

### ASSIGN — Task 할당 — 5개

| ID | 요약 |
|---|---|
| ASSIGN-1 | `[BE]`→backend-dev, `[FE]`→frontend-dev, `[TEST]`→tester, `[DOC]`→전문가/TL |
| ASSIGN-2 | `[TEST]`를 backend-dev/frontend-dev에 할당 절대 금지 |
| ASSIGN-3 | assignee 지정 시 도메인↔역할 일치 검증 |
| ASSIGN-4 | 평가/분석 Task → tester(Bash) 또는 verifier(Explore) |
| ASSIGN-5 | Team Lead 3단계(스폰·할당·진행 중) 능동 감시 |

### LIFECYCLE — 에이전트 라이프사이클 — 4개

| ID | 요약 |
|---|---|
| LIFECYCLE-1 | 5분 무보고 → 점검 후 필요 시 종료 |
| LIFECYCLE-2 | 미사용 에이전트 즉시 shutdown |
| LIFECYCLE-3 | 종료 전 in_progress Task 확인 → 재할당/보류 |
| LIFECYCLE-4 | 팀 작업 완료 시 전원 shutdown + TeamDelete |

### REPORT — 팀원 보고 방식 — 5개

| ID | 요약 |
|---|---|
| REPORT-1 | Task 완료 시 `reports/report-{역할}.md` 작성 |
| REPORT-2 | SendMessage는 보고서 파일 경로(링크)만 |
| REPORT-3 | `TEMPLATES/task-report-template.md` 형식 준수 |
| REPORT-4 | 필수 섹션 5개: 작업 내용/결과/테스트/위험/추천 |
| REPORT-5 | 경로: `docs/phases/phase-X-Y/reports/report-{역할}.md` |

### NOTIFY — Telegram 알림 — 3개

| ID | 요약 |
|---|---|
| NOTIFY-1 | DONE 전이 즉시 `scripts/pmAuto/report_to_telegram.sh` 실행. 생략 시 DONE 전이 무효 |
| NOTIFY-2 | 형식: `[프로젝트명] ✅ Phase {N}-{M} 완료: {요약}\n📊 결과/📁 보고서` |
| NOTIFY-3 | Master Plan 완료 시 종합 알림 (Sub-Phase별 요약) |

### ANALYSIS — 사전 분석 — 3개

| ID | 요약 |
|---|---|
| ANALYSIS-1 | `docs/phases/pre/phase-{N}-pre-analysis.md` 저장 필수. 텍스트 출력만으로 완료 금지 |
| ANALYSIS-2 | 경로: `docs/phases/pre/` 평탄 폴더 |
| ANALYSIS-3 | 필수 섹션 4개: 분석 배경 / 현황 진단 / 비교 검토 / 결론 및 추천안 |

### REFERENCE — 문서 우선순위 — 1개

| ID | 요약 |
|---|---|
| REFERENCE-1 | 컨텍스트 복구는 3-workflow §9, Phase 문서 구조는 §8.7이 정본 |

### PROMPT — 프롬프트 품질 (v8.2 신규) — 1개

| ID | 요약 |
|---|---|
| **PROMPT-QUALITY** | 사용자 주도 마스터 플랜(`initiator: user`) 진입 전 Step 0 Pre-draft 5항목 판정 필수 — 완전성·명료성·실행 가능성·범위 적정성·트리아지. AI handoff 시 적용 제외. Fast-path 허용 (`prompt_quality: fast-path`) |

### WT — Worktree (병렬 격리) — 5개

| ID | 요약 | 심각도 |
|---|---|:--:|
| WT-1 | 병렬 BUILDING 트랙 ≥ 2 시 worktree 격리 필수. A/B 분기·REWINDING도 동일 | CRITICAL |
| WT-2 | 경로 `../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-{track}` 패턴만 (저장소 내부 `.worktrees/` 금지) | HIGH |
| WT-3 | 팀원은 주입된 worktree CWD 밖 편집·빌드 금지. 위반 시 즉시 중단·재할당 | CRITICAL |
| WT-4 | Chain 완료 시 `git worktree remove` + `prune`. 실패·A/B 비선택 브랜치는 §6.5 아카이브 | HIGH |
| WT-5 | status.md에 `worktree_paths: []` + `cleanup_wt: pending\|done` 필수 기록 | MEDIUM |

## §2 HR ↔ 다른 규칙 교차 매핑

| HR | 대응 규칙 | 관계 |
|---|---|---|
| HR-1 | EDIT-2, AUTO-5.4 | 동일 제약 (코드 수정 금지), 자동화 복구 시에도 적용 |
| HR-2 | CHAIN-6, AUTO-1.5 | 산출물 의무, Persister가 자동 검증 |
| HR-3 | FRESH-7, AUTO-5.3 | 복구 프로토콜 |
| HR-4 | CHAIN-10 | 파일 경로 규칙 동일 |
| HR-5 | REFACTOR-1~3, FRESH-8 | 리팩토링 전체 흐름 |
| HR-6 | ASSIGN-1~5 | Task 도메인-역할 분리 |
| HR-7 | LIFECYCLE-1~4 | 에이전트 라이프사이클 관리 |
| HR-8 | NOTIFY-1~3 | Telegram 알림 (CLAUDE.md 정의) |

---

# core/7-shared-definitions — 공통 포맷 레이어

> SUB-SSOT 간 중복 제거 + 일관성 보장. 모든 SUB-SSOT가 `참조: core/7-shared-definitions.md §N` 형식으로 인용.

## §1 GATE 공통 — GATE_FORMAT + ANTI-COMPRESSION

```
[PASS/FAIL/N/A] {체크리스트 항목}
                — 근거: {1줄 증거}
```

> **금지**: "전체 통과", "모든 항목 확인" 같은 일괄 선언 = **GATE 실패** 자동 처리.

```
ANTI-COMPRESSION RULE:
  각 체크리스트 항목은 자체 줄에 개별 응답.
  일괄 응답("all items confirmed")은 무효 → GATE 재평가 필수.
  형식:
    [PASS] {항목} — evidence: {1줄}
    [FAIL] {항목} — reason: {실패 사유}
    [N/A]  {항목} — reason: {미해당 사유}
```

## §2 역할 시스템 — ROLE_CHECK + 매핑

### ROLE_CHECK 프로토콜
모든 STEP/PHASE 시작 시 역할 선언:

```
ROLE_CHECK
현재 역할    : {PLANNER / CODER / REVIEWER / VALIDATOR}
현재 STEP    : {N}
금지 행동    :
  PLANNER  : 실행 코드 작성
  CODER    : 자기 코드 리뷰, 범위 축소
  REVIEWER : 수정 코드 작성, 증거 없는 승인
  VALIDATOR: 구두 확인 수락, Fail 카운터 리셋
확인         : "나는 {역할}로서 금지 행동을 수행하지 않는다."
```

### 역할 매핑

| 절차 역할 | SSOT 팀원 | 비고 |
|---|---|---|
| PLANNER | planner | 문서만, 코드 금지 |
| CODER | backend-dev, frontend-dev | 도메인별 코드 수정 |
| REVIEWER | verifier | 별도 컨텍스트 필수 |
| VALIDATOR | tester | 명령어 실행 증거 필수 |
| HUMAN | 인간 승인자 | 8개 트리거 시 대기 |

### 역할 전환 금지
CODER ↔ REVIEWER **동일 컨텍스트 전환 금지**. 옵션: A) 별도 세션(권장), C) 인간 리뷰.

## §3 승인 프로토콜 10종

| 블록 | 트리거 |
|---|---|
| **AMBIGUITY** | 항목 불명확 → 인간 결정 대기 |
| **GOAL_CHANGE_REQUEST** | 목표 변경 필요 |
| **BLOCKER_REVIEW_REQUEST** | AI 독립 해결 불가 |
| **DELETION_APPROVAL_REQUEST** | VAL 항목 삭제 승인 |
| **CHANGE_REQUEST** | detail-plan.md 수정 |
| **HUMAN_ESCALATION_REQUEST** | 임계값 초과 (FAIL 3회 등) |
| **SCOPE_REDUCTION_PROPOSAL** | 범위 축소 제안 |
| **CONFLICT_APPROVAL_REQUEST** | Type A/B/C 충돌 — 인간 승인 필수 |
| **SCHEMA_CHANGE_APPROVAL** | DB 스키마 변경 + 영향 행 수 + 롤백 방법 |
| **DEPENDENCY_CONFLICT** | 패키지 버전 충돌 |

각 블록은 `---{타입}---` ~ `---END_{타입}---`로 감쌈. 인간 결정 필드 필수.

## §4 산출물 포맷

### DEVIATION 기록
```
DEVIATION-{N}
계획     : {어느 문서의 어느 항목}
실제     : {무엇을 다르게 구현}
이유     : {이탈 불가피 사유}
영향     : {영향받는 VAL 항목}
```

### VAL 결과 기록
```
VAL-{N} [{검증 항목 한 줄 요약}]
명령어   : {실제 실행 명령}
출력     : {실제 stdout — 최소 3줄, 생략 시 자동 FAIL}
결과     : PASS / FAIL
실행시각 : {datetime}
```
> Output 필드가 없거나 설명만 있으면(실제 출력 아님) **자동 FAIL**.

### FAIL_COUNTER 임계값
- 동일 항목 1회 실패 → 수정 후 재검증 (자율)
- 동일 항목 2회 연속 → 계획 재검토
- 동일 항목 3회 연속 → **HUMAN_ESCALATION_REQUEST**
- 실패율 30% 초과 → 이전 단계 복귀
- 반복 3회 초과 → HUMAN_ESCALATION_REQUEST

## §5 충돌 분류 Type A~E

| 유형 | 충돌 | 대응 |
|---|---|---|
| **Type A** | Signature Conflict — 같은 이름, 다른 인터페이스 | **HALT + HUMAN** |
| **Type B** | Dependency Conflict — 패키지 버전 비호환 | **HALT + HUMAN** |
| **Type C** | Schema Conflict — 마이그레이션이 기존 데이터 영향 | **HALT + HUMAN** |
| **Type D** | Naming Collision — 변수/환경변수 이름 중복 | LOG + AUTO-RESOLVE |
| **Type E** | Convention Mismatch — 스타일/폴더 구조 차이 | LOG + FOLLOW-EXISTING |

충돌 발견 시 `docs/plans/{feature}/conflict-{datetime}.md` 작성 (Metadata + Description + Resolution + Approval 4섹션).

## §6 VUL 체크리스트 3종

| VUL | 검사 |
|---|---|
| **VUL1** | 샘플 코드 경계 — Import / 범위 상한 / 핵심 로직 커버리지 ≥60% / 격리(prototype/) / 헤더 |
| **VUL2** | 호환성 충돌 — 충돌 로그 존재 / Type A 해결(wrapper) / Type B(`pip check`) / Type C(HUMAN 승인) / Type D·E(resolution 필드) |
| **VUL3** | 범위 무결성 — 산출물 파일 수 / VAL 항목 수 추이 / TODO 완료 / DEVIATION 영향 / DoD 일치 |

각 VUL은 5개 ID(예: VUL1-01 ~ VUL1-05)로 세분화.

## §7 예외 4조항

| 예외 | 조건 (전부 충족) | 적용 |
|---|---|---|
| **1. Hotfix** | 프로덕션 버그 + 1파일 이하 + 신규 fn 없음 + 기존 테스트 통과 | PHASE 0→7 직행. 24시간 내 사후 문서화 |
| **2. Minor Change** | ≤5줄 + 신규 fn/class/API 없음 + 외부 의존성 변경 없음 | PHASE 1~5 단일 문서 통합. VAL 생략 불가 |
| **3. Pattern Reuse** | 기존 3회+ 동일 패턴 + 패턴 문서 등록 + 인간 승인 | PHASE 1~3 축약 (패턴 문서 참조), PHASE 4~7 정상 |
| **4. POC/Spike-only** | 폐기 전제 + 프로덕션 배포 불가 선언 + spike/poc/ 격리 | PHASE 0~3만 수행 |

## §8 ITERATION-BUDGET — 사이클 자원 상한 (v8.1 Phase-H H-2)

| 항목 | 기본값 |
|---|---:|
| **사이클 총 토큰** | **500,000** |
| 단일 Phase 토큰 | 200,000 |
| 사전 반복 (Step 1~5, 3회) | 150,000 |
| 재계획 (Step 8~9, 2회) | 100,000 |

### 초과 에스컬레이션

```
if 현재 소비량 ≥ 80% 상한:
    → WARNING: 토큰 절약 모드, 불필요 Research/Spike 스킵
if 현재 소비량 ≥ 100% 상한:
    → HALT: 자동 진행 중단
    → HUMAN_ESCALATION_REQUEST 발동
    → 옵션:
      A) 상한 확장 승인 (최대 2배, 1,000K)
      B) 범위 축소 후 현재 예산 내 완료
      C) 사이클 종료 → 미완 항목 Tech Debt 전이
```

**측정 책임**: Team Lead가 각 Phase/Step 전환 시 토큰 소비량 기록 (phase-achievement-report.md §3). verifier가 G2 검증 시 예산 초과 여부 확인. **예외**: 사용자가 사전에 "예산 무제한" 선언 시 적용 제외 (선언 기록 필수).

## 다음 노트

- [[2026-05-05_pab_ssot_workflow|워크플로우]] — CHAIN/G0~G4/REFACTOR/ANALYSIS 상세
- [[2026-05-05_pab_ssot_event_automation|이벤트·자동화]] — EVENT/AUTO 상세
- [[2026-05-05_pab_ssot_roles|역할 9종]] — ROLE_CHECK 매핑별 상세
- [[2026-05-05_pab_ssot_subssot_misc|SUB-SSOT·기타]] — 모듈형 로딩 인덱스
- [[PAB_SSOT_overview|MOC]]

## 참고

- `/PAB-SSOT-Nexus/docs/SSOT/docs/core/6-rules-index.md` (v1.4, 100개 규칙)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/core/7-shared-definitions.md` (v1.1, 공통 포맷 + ITERATION-BUDGET)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/refactoring/refactoring-rules.md` — REFACTOR 상세
- `/PAB-SSOT-Nexus/docs/SSOT/docs/3-workflow.md` §6.6 — WT-1~5 정본
