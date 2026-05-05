---
title: "PAB SSOT — 워크플로우·상태 머신·게이트·Phase Chain"
description: "20개 상태 머신(4th 14 + 5th 6) · ENTRY/NOTIFY/ASSIGN/AGENT-LIFECYCLE/REPORT 규칙 · G0~G4 게이트 · 병렬 BUILDING + Worktree WT-1~5 · Phase Chain CHAIN-1~11 · 컨텍스트 복구 · REFACTOR-1~3 · ANALYSIS-1~3"
created: 2026-05-05 05:13
updated: 2026-05-05 05:13
type: "[[RESEARCH_NOTE]]"
index: "[[KNOWLEDGE_MGMT]]"
topics: ["[[PAB_SSOT]]", "[[STATE_MACHINE]]", "[[QUALITY_GATE]]", "[[PHASE_CHAIN]]"]
tags: [research-note, pab-ssot-nexus, workflow, state-machine, gate, chain, autocycle]
keywords: ["20개 상태", "G0~G4", "ENTRY", "NOTIFY", "ASSIGN", "LIFECYCLE", "REPORT", "AUTO_FIX", "AB_COMPARISON", "DESIGN_REVIEW", "BRANCH_CREATION", "WORKTREE_SETUP", "WT-1~5", "CHAIN-1~11", "REFACTOR-1~3", "ANALYSIS-1~3", "Phase Chain"]
sources:
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/3-workflow.md"
aliases: ["SSOT 워크플로우", "20개 상태 머신", "G0~G4"]
---

# PAB SSOT — 워크플로우 (3-workflow)

> 본 노트는 SSOT 본체에서 가장 두꺼운 `3-workflow.md` (992줄)의 핵심을 압축. 상세 규칙·플로우는 원본 참조.

## ENTRYPOINT — 단일 진입점 5규칙

Phase 실행의 단일 진입점은 `phase-X-Y-status.md`. 다음 5규칙 강제:

| ID | 규칙 |
|---|---|
| **ENTRY-1** | 모든 Phase 작업은 `docs/phases/phase-X-Y/phase-X-Y-status.md`를 먼저 읽는 것으로 시작 |
| **ENTRY-2** | `current_state` 값에 따라 다음 행동 결정 |
| **ENTRY-3** | 진입 시 `ssot_version` 일치 확인 |
| **ENTRY-4** | `blockers` 배열이 비어있지 않으면 다른 작업보다 Blocker 해결 우선 |
| **ENTRY-5** | status 파일 안 읽고 Task 구현 직행 금지 |

**플로우**: SSOT 0→1→2→3 로드(FRESH-1) → status.md 읽기 → ssot_version 확인 → blockers 확인 → current_state 분기 → 팀 상태 확인 → 워크플로우 실행.

## 상태 머신 — 20개 (4th 14 + 5th 6)

### 4th 기존 14개

`IDLE` · `TEAM_SETUP` · `PLANNING` · `PLAN_REVIEW`(G1) · `TASK_SPEC` · `BUILDING` · `VERIFYING`(G2) · `TESTING`(G3) · `INTEGRATION` · `E2E` · `E2E_REPORT` · `TEAM_SHUTDOWN` · `BLOCKED` · `REWINDING` · `DONE`

### 5th 신규 6개 (조건부)

| 상태 | 진입 조건 | 역할 |
|---|---|---|
| `RESEARCH` | `5th_mode.research = true` | Research Team 기술 조사·아키텍처 탐색 |
| `RESEARCH_REVIEW` | RESEARCH 완료 | Team Lead의 G0 게이트 판정 |
| `BRANCH_CREATION` | `5th_mode.branch = true` | Phase 전용 Git 브랜치 생성·확인 |
| `AUTO_FIX` | `5th_mode.automation = true` + VERIFYING FAIL(High만) | 자동 수정 시도 (최대 3회) |
| `AB_COMPARISON` | TESTING 통과 + 복수 구현 존재 | A/B 비교 후 최적안 선택 |
| `DESIGN_REVIEW` | PLAN_REVIEW 통과 + 복잡도 높음 | 아키텍처 추가 검토 |

> 5th 신규 상태는 모두 **선택적**. `5th_mode` 미설정 또는 `false`면 4th 기존 전이 경로 사용.

### 전이 다이어그램

```
── 4th 기본 경로 ──
IDLE → TEAM_SETUP → PLANNING → PLAN_REVIEW(G1) → TASK_SPEC
                         ↑          │ FAIL
                         └──────────┘ REWINDING

TASK_SPEC → BUILDING → VERIFYING(G2) → TESTING(G3) → (다음 Task 또는 INTEGRATION)
                ↑          │ FAIL          │ FAIL
                └──────────┴───────────────┘ REWINDING

모든 Task 완료 → INTEGRATION → E2E → E2E_REPORT → TEAM_SHUTDOWN → DONE

── 5th 확장 분기 ──
TEAM_SETUP ─(research)→ RESEARCH → RESEARCH_REVIEW(G0)
                                        │ PASS → PLANNING
                                        │ FAIL → REWINDING → RESEARCH

PLAN_REVIEW ─(복잡도)→ DESIGN_REVIEW → TASK_SPEC

TASK_SPEC ─(branch)→ BRANCH_CREATION → (N≥2: WORKTREE_SETUP) → BUILDING

VERIFYING ─(FAIL High만 + automation)→ AUTO_FIX ─(성공)→ VERIFYING
                                          │ (3회 초과)→ REWINDING → BUILDING

TESTING ─(복수 구현)→ AB_COMPARISON → INTEGRATION

※ 어떤 상태에서든 BLOCKED 진입 가능
```

### status.md 핵심 필드

```yaml
phase: "X-Y"
ssot_version: "8.2-renewal-6th"
ssot_loaded_at: "2026-04-16T..."
current_state: "BUILDING"
current_task: "X-Y-2"
current_task_domain: "[FE]"
team_name: "phase-X-Y"
team_members: []
blockers: []
rewind_target: null
retry_count: 0
gate_results: { G0_research_review: null, G1_plan_review: null, G2_code_review_be: null, ... }
task_progress: {}
last_updated: "..."
# ── 5th 확장 ──
5th_mode:
  research: false
  event: false
  automation: false
  branch: false
  multi_perspective: false
auto_fix_count: 0
research_status: null  # null | in_progress | completed
worktree_paths: []     # WT-5
cleanup_wt: pending    # WT-5: pending | done
```

## NOTIFY — Telegram 알림 필수 (NOTIFY-1~3)

**절대 생략 금지**. Phase/Sub-Phase가 DONE 도달 시 Team Lead가 **반드시** 알림 발송. 알림 없이 DONE 전이 무효.

| 규칙 | 내용 |
|---|---|
| **NOTIFY-1** | Phase/Sub-Phase DONE 시 Telegram 알림 발송 |
| **NOTIFY-2** | 메시지 형식: `[PAB-SSOT-Nexus] ✅ Phase {N}-{M} 완료: {1줄 요약}\n📊 결과: {핵심 수치}\n📁 보고서: {경로}` — 프로젝트명 prefix 표기 |
| **NOTIFY-3** | Master Plan 전체 완료 시 종합 알림 (Sub-Phase별 요약) |

```bash
scripts/pmAuto/report_to_telegram.sh "PAB-SSOT-Nexus" "✅ Phase X-Y 완료: {요약}
📊 결과: {핵심 수치}
📁 보고서: docs/phases/phase-X-Y/reports/"
```

## ASSIGN — 도메인-역할 할당 검증 (ASSIGN-1~5)

> **⚠️ 절대 원칙**: 테스트·코드 검증·A/B 평가 등 **검증 성격 작업**은 backend-dev/frontend-dev가 **절대 수행 금지**. 반드시 tester·verifier·QC에 위임. Team Lead가 강력 통제.

| ID | 규칙 | 심각도 |
|---|---|:--:|
| **ASSIGN-1** | `[BE]`→backend-dev, `[FE]`→frontend-dev, `[TEST]`→tester, `[DOC]`→해당 전문가/Team Lead | CRITICAL |
| **ASSIGN-2** | `[TEST]` Task를 backend-dev/frontend-dev에 할당 **절대 금지** (구현자 셀프 체크 방지) | CRITICAL |
| **ASSIGN-3** | Task assignee 지정 시 도메인 태그 ↔ 역할 일치를 Team Lead가 반드시 검증 | CRITICAL |
| **ASSIGN-4** | 스크립트 실행+분석 Task는 tester(Bash) 또는 verifier(Explore)에 할당. backend-dev는 **코드 작성만** | CRITICAL |
| **ASSIGN-5** | Team Lead 통제 의무 — 스폰·할당·진행 중 **3단계 검증** 필수 | CRITICAL |

**역할 책임 경계**:

| 역할 | 수행 가능 | 수행 절대 금지 |
|---|---|---|
| backend-dev | 코드 작성, 리팩토링, 문서 | 테스트 실행, 코드 검증, A/B 평가, QC |
| frontend-dev | UI 코드, 스타일링 | 테스트 실행, 코드 검증, A/B 평가, QC |
| tester | 테스트 실행, A/B 평가, 스크립트 실행 | 프로덕션 코드 수정 |
| verifier | 코드 검증, 품질 분석, 탐색 | 프로덕션 코드 수정 |
| QC | 최종 품질 확인, 회귀 검증 | 프로덕션 코드 수정 |

## AGENT-LIFECYCLE — 에이전트 운영 (LIFECYCLE-1~4)

| ID | 규칙 | 심각도 |
|---|---|:--:|
| **LIFECYCLE-1** | 5분 무보고 idle → 즉시 점검 + 필요 시 종료 | CRITICAL |
| **LIFECYCLE-2** | 미사용 에이전트 즉시 shutdown_request | CRITICAL |
| **LIFECYCLE-3** | 종료 전 in_progress Task 확인 → 미완료는 재할당/보류 후 종료 | HIGH |
| **LIFECYCLE-4** | 팀 작업 완료 시 전원 shutdown + TeamDelete (잔류 0) | HIGH |

## REPORT — 문서 기반 보고 (REPORT-1~5)

| ID | 규칙 |
|---|---|
| **REPORT-1** | Task 완료 시 보고서 마크다운 파일 작성 (Phase 디렉토리 `reports/`) |
| **REPORT-2** | SendMessage에는 보고서 파일 경로(링크)만 — 텍스트 본문 보고 금지 |
| **REPORT-3** | `TEMPLATES/task-report-template.md` 형식 준수 |
| **REPORT-4** | 필수 섹션 5개: 작업 내용, 작업 결과, 테스트 결과, 위험 요소, 다음 추천 |
| **REPORT-5** | 경로: `docs/phases/phase-X-Y/reports/report-{역할명}.md` |

```
docs/phases/phase-X-Y/reports/
├── report-backend-dev.md
├── report-frontend-dev.md
├── report-verifier.md
└── report-tester.md
```

## 품질 게이트 G0~G4

```
[G0: Research Review] ← 5th 신규 (research=true 시)
  ↓
[G1: Plan Review]     planner → Team Lead
  ↓
[G2: Code Review]     verifier → Team Lead (BE+FE)
  ↓
[G3: Test Gate]       tester → Team Lead (pytest + 커버리지 + 회귀 + 결함 밀도)
  ↓
[G4: Final Gate]      Team Lead 종합 (G2 PASS + G3 PASS + Blocker 0)
```

| 게이트 | PASS 기준 | FAIL 시 |
|---|---|---|
| **G0** (5th) | 기술 조사 완료, 대안 2개+, 리스크 분석 (선택: PoC) | RESEARCH 재실행 |
| **G1** | 완료 기준 명확, Task 3~7개, 도메인 분류, 리스크 식별 | PLANNING 재실행 |
| **G2** | Critical 0건 (ORM, Pydantic, 타입 힌트, ESM, esc(), CDN 미사용) | PARTIAL → AUTO_FIX (6조건 AND) / FAIL → BUILDING |
| **G3** | pytest PASS + 커버리지 ≥80% + E2E PASS + 회귀 통과 + **결함 밀도 ≤5건/KLOC** (ISTQB CTFL 4.0) | BUILDING |
| **G4** | G2 + G3 PASS + Blocker 0 | DONE / PARTIAL → Tech Debt / FAIL → REWINDING |

### G2 Entry 체크리스트 (G2 진입 전 사전 준비)

- [ ] Task 구현 완료 (todo-list 체크박스)
- [ ] 자체 테스트 PASS 확인
- [ ] 줄수 확인 (HR-5 REFACTOR-3 — 500줄 이하)
- [ ] 타입 힌트 완비
- [ ] import 정리 (미사용·순환 ❌)
- [ ] 디버그 코드 제거 (console.log/print/debugger/TODO temp)

### CL 크기 권장 (Google CL Review 기반)

| 크기 | 줄 수 | 판정 |
|---|---:|:--:|
| Small | ~100 | 권장 |
| Medium | 100~300 | 허용 |
| Large | 300~500 | 주의 (분할 검토) |
| Too Large | 500+ | **경고** (Task 분할 필수, HR-5) |

## 병렬 BUILDING + Worktree (WT-1~5)

병렬 BUILDING 트랙 ≥ 2일 때 worktree 격리 필수. 빌드 산출물·환경변수·`git checkout`·`git stash` 경합 방지.

| ID | 규칙 | 심각도 |
|---|---|:--:|
| **WT-1** | 병렬 BUILDING 트랙 ≥ 2일 때 worktree 없이 BUILDING 진입 금지. A/B 분기·REWINDING도 동일 | CRITICAL |
| **WT-2** | 경로 규약 `../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-{track}` — 저장소 내부 `.worktrees/` 금지 | HIGH |
| **WT-3** | CWD 일관성 — 팀원은 주입된 worktree 경로 밖 편집·빌드 금지 | CRITICAL |
| **WT-4** | Phase Chain 완료 시 `git worktree remove` + `prune` 일괄. 실패·A/B 비선택 브랜치는 §6.5 아카이브 | HIGH |
| **WT-5** | status.md에 `worktree_paths: []` + `cleanup_wt: pending\|done` 필수 기록 | MEDIUM |

WORKTREE_SETUP 절차:
1. 각 트랙별 `git worktree add ../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-{track} phase-{X}-{Y}-{track}`
2. 각 worktree에서 의존성 설치 (npm ci / pip install 등)
3. Git 태그 `phase-{X}-{Y}-WORKTREE_SETUP`
4. status.md에 worktree_paths + cleanup_wt 기록
5. current_state = BUILDING (각 worktree 경로를 팀원 스폰 시 CWD 주입)

자동화: `/pab:worktree` skill ([[2026-05-05_pab_ssot_skills_detail|skill 상세 노트]] 참조).

## 리와인드·A/B·아카이브

- **6.1 리와인드**: rewind_target 결정 → REWINDING → 수정 요청 → rewind_target 전이 → retry_count += 1
- **6.3 REWINDING + worktree**: 실패 worktree 보존 + `retry-N` worktree 추가 생성. 실패 worktree는 §6.5 아카이브 후 제거 (WT-4)
- **6.4 A/B 분기**: A/B 두 구현안을 각각 독립 worktree에 격리 (WT-1 필수). 비선택 브랜치는 `archive/phase-{X}-{Y}-branch-{비선택}` 태그 보존 후 worktree 제거
- **6.5 아카이브**: Chain 종료까지 `archive/phase-{X}-{Y}-*` 태그 보존. 롤백 시 재체크아웃

## Phase Chain — 자동 순차 실행 (CHAIN-1~11)

```yaml
# docs/phases/phase-chain-{name}.md
chain_name: "phase-15-fullstack"
phases: ["15-4", "15-5", "15-6", "15-7", "15-8"]
current_index: 0
status: "running"   # pending | running | completed | aborted
ssot_version: "8.2-renewal-6th"
5th_mode: { research: false, event: false, automation: false, branch: false, multi_perspective: false }
```

### 실행 프로토콜
1. Chain 파일 생성 (`phase-chain-{name}.md`)
2. Phase[current_index] **Cold Start**: SSOT 리로드 → TeamCreate → 팀원 스폰 → PLANNING → … → DONE
3. Phase DONE → TEAM_SHUTDOWN + TeamDelete → current_index += 1 → 완료 리포트
4. **REFACTOR-1**: 500줄 초과 파일 스캔 → 레지스트리 등록 (계획 삽입 X)
5. `/clear` (토큰 최적화, Chain 파일은 디스크 유지)
6. current_index < len(phases)? → 다음 Phase Cold Start, else Chain 완료

### CHAIN 규칙

| ID | 규칙 |
|---|---|
| **CHAIN-1** | Phase 독립성 — 각 Phase는 Chain 없이도 단독 실행 가능 |
| **CHAIN-2** | Phase 간 전환 시 `/clear` 필수 |
| **CHAIN-3** | `/clear` 후에도 Chain 파일 디스크 영속 |
| **CHAIN-4** | phases 배열 순서대로만 실행 (건너뛰기 금지) |
| **CHAIN-5** | 각 Phase DONE 시 1줄 요약을 Chain 파일에 기록 |
| **CHAIN-6** | 산출물 의무 — plan/todo-list/tasks/status 최소 필수 |
| **CHAIN-7** | Gate 의무 — G0~G4 생략 불가 (G0은 research=true 시) |
| **CHAIN-8** | status.md는 YAML frontmatter (§2.2 스키마) 준수 |
| **CHAIN-9** | task-X-Y-N.md: 메타 필드 4종 + §1~§4 섹션 |
| **CHAIN-10** | 파일 경로 규칙 — §8.7 디렉토리 구조 준수, 기존 패턴 Glob 후 생성 |
| **CHAIN-11** | Master Plan 완료 시 `phase-{N}-final-summary-report.md` 작성 필수 |

> v8.1·v8.2 추가: **CHAIN-12** (Tech Debt 자동 로딩) + **CHAIN-13** (직전 3 Phase 기억 전달). 상세는 [[2026-05-05_pab_ssot_rules_chain|규칙·CHAIN 노트]].

### Phase 디렉토리 구조 (CHAIN-10 / HR-4)

```
docs/phases/
├── phase-chain-{name}.md             ← Chain 정의 (루트)
├── phase-{N}-master-plan.md          ← Master Plan (루트)
├── phase-{N}-final-summary-report.md ← 완료 보고서 (루트, CHAIN-11)
├── pre/                              ← 평탄 구조
│   ├── phase-{N}-pre-analysis.md     ← ANALYSIS-1
│   └── phase-{N}-pre-draft.md        ← Step 0 Pre-draft (사용자 주도 한정)
└── phase-{N}-{M}/
    ├── phase-{N}-{M}-status.md       ← YAML 진입점 (ENTRY-1)
    ├── phase-{N}-{M}-plan.md
    ├── phase-{N}-{M}-todo-list.md
    └── tasks/
        └── task-{N}-{M}-{T}.md
```

핵심: master-plan/chain/final-summary는 **`docs/phases/` 루트**, status/plan/todo-list/tasks는 **`phase-{N}-{M}/` 하위**. pre는 **`pre/` 평탄 폴더**.

## 컨텍스트 복구 프로토콜 (FRESH-7)

압축·세션 중단·`/clear` 후 작업 재개 절차. **이전 요약만 보고 바로 작업 재개 금지.**

```
[1] SSOT 리로드 (FRESH-1)
[2] phase-chain-{name}.md 확인 (current_index, status)
[3] 현재 Phase status.md 읽기 (ENTRY-1)
[3.5] (5th) 5th_mode 확인 → 활성 축 별 분기
   ├─ research=true + state=RESEARCH → Research Team 재스폰
   ├─ branch=true → Git branch/tag 상태 확인
   └─ event=true → 이벤트 로그에서 마지막 상태 교차 검증
[4] 팀 상태 확인 — team_name 존재 → 팀 config 읽기, 없으면 새 팀 생성 (HR-1: 팀 없이 코드 수정 금지)
[5] 미완료 Task 식별 (task_progress, status != DONE)
[6] 업무 재분배
[7] 작업 재개 (current_state 기반)
```

### 복구 시 금지

| 금지 | 이유 |
|---|---|
| SSOT 리로드 없이 작업 재개 | 규칙 변경·버전 불일치 감지 불가 |
| 팀 없이 Team Lead 직접 코드 수정 | HR-1 위반 |
| 산출물(tasks/, todo-list) 생략 | HR-2 위반 |
| 이전 세션 요약만으로 상태 추정 | status.md가 단일 진입점 (ENTRY-1) |

## 코드 유지관리 — 리팩토링 (REFACTOR-1~3 / HR-5)

### 임계값

| 기준 | 줄 수 | 의미 |
|---|---:|---|
| 관심선 | **500** | 레지스트리 등록·모니터링 |
| 경고선 | **700** | Level 분류 + 리팩토링 검토 |
| 위험선 | **1000** | 즉시 리팩토링 (다음 Master Plan 최우선) |

### Level 분류

| Level | 조건 | 편성 |
|:--:|---|---|
| **Lv1** | 700+ 독립 분리 가능 (연관 파일 500+ 0개 또는 단방향) | 다음 Master Plan 내 선행 sub-phase |
| **Lv2** | 700+ 양방향 밀접 (연관 파일 500+ 1개+ 양방향) | `phase-X-refactoring` 별도 Phase + git branch 분리 + 별도 팀 |

### 규칙

| ID | 시점 | 조치 |
|---|---|---|
| **REFACTOR-1** | Phase X-Y 완료(DONE) | 코드 스캔 → 500+ 파일 레지스트리 **등록만** (CHAIN §8.3 Step [4]) |
| **REFACTOR-2** | Master Plan 작성 | 레지스트리 읽기 → 700+ Level별 리팩토링 편성 |
| **REFACTOR-3** | PLANNING/BUILDING/G2 | 신규 코드 500+ **사전 방지** |

### 예외 3요건

1. 영향도 조사 실시
2. 분리 시 순환 의존/응집도 파괴 입증
3. 사용자 승인

## Master Plan 작성 시 필수 체크리스트

### 사전 점검

| # | 항목 | 근거 |
|---|---|---|
| 1 | 리팩토링 레지스트리 로드 | REFACTOR-2 — 700+ Level 분류 |
| 2 | 이전 Phase 이관 항목 확인 | CHAIN-5 |
| 3 | 기존 파일 패턴 Glob | CHAIN-10 / HR-4 — 동일 경로에 생성 |
| 4 | 사전 분석 결과 파일 저장 | ANALYSIS-1 — `docs/phases/pre/phase-{N}-pre-analysis.md` |

### 본문 필수 포함

| # | 항목 | 근거 |
|---|---|---|
| 1 | HR-5 리팩토링 점검 결과 섹션 | REFACTOR-2 |
| 2 | 모든 Sub-Phase에 G0~G4 명시 | CHAIN-7 |
| 3 | Task 도메인 태그 + 담당 역할 | ASSIGN-1 |
| 4 | 완료 보고서 작성 계획 | CHAIN-11 |

## 사전 분석 규칙 (ANALYSIS-1~3)

> Master Plan 작성 **이전** 분석은 **반드시 파일로 저장**. 텍스트 출력만으로 완료 선언 금지.

| ID | 규칙 |
|---|---|
| **ANALYSIS-1** | 분석 결과를 `docs/phases/pre/phase-{N}-pre-analysis.md`에 저장 |
| **ANALYSIS-2** | 경로 규칙 — `docs/phases/pre/` 평탄 폴더 (HR-4 / CHAIN-10) |
| **ANALYSIS-3** | 필수 섹션: 분석 배경 / 현황 진단 / 비교 검토 / 결론 및 추천안 |

### 게이트 연동

| 게이트 | ANALYSIS 점검 |
|---|---|
| **G1** | Master Plan이 pre-analysis.md의 결론·추천안을 반영했는지 |
| **G4** | pre-analysis.md의 보류 항목이 해결/이관 기록되었는지 |

## 에러 처리 등급

| 등급 | 처리 |
|---|---|
| E0 Critical | 즉시 중단, 사용자 보고 |
| E1 Blocker | BLOCKED 전이, Fix Task 생성 |
| E2 High | REWINDING, 수정 요청 |
| E3 Medium | Tech Debt 등록 |
| E4 Low | 기록만 |

**재시도**: 동일 상태에서 retry_count ≥ 3이면 접근 방식 폐기 + 에러 로그 + 사용자 판단 대기.

## 다음 노트

- [[2026-05-05_pab_ssot_intro|진입점·6세대]] — 본 노트의 상위
- [[2026-05-05_pab_ssot_event_automation|이벤트·자동화]] — JSONL/Heartbeat/AUTO_FIX 인프라
- [[2026-05-05_pab_ssot_rules_chain|규칙·CHAIN 인덱스]] — HR-1~8, CHAIN-1~13, ITER-PRE/POST 등 96개 규칙
- [[2026-05-05_pab_ssot_roles|역할 9종]] — 각 역할의 검증 분담
- [[PAB_SSOT_overview|MOC]]

## 참고

- `/PAB-SSOT-Nexus/docs/SSOT/docs/3-workflow.md` — 본 노트의 1차 출처 (992줄)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/core/6-rules-index.md` — 96개 규칙 인덱스
- `/PAB-SSOT-Nexus/scripts/pmAuto/report_to_telegram.sh` — NOTIFY-1 실행 스크립트
- `/PAB-SSOT-Nexus/docs/SSOT/docs/refactoring/refactoring-rules.md` — REFACTOR 상세
- `/PAB-SSOT-Nexus/docs/SSOT/docs/refactoring/refactoring-registry.md` — 500줄 초과 파일 레지스트리
