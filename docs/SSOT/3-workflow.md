# SSOT — 워크플로우

**버전**: 8.2-renewal-6th
**최종 수정**: 2026-04-16 (Phase-I I-1 — pre/ 폴더 + 파일명 규칙, §8.7/§11/§12 갱신)
**특징**: 단독 사용 (다른 SSOT 폴더 참조 불필요) + 5세대 확장 (20개 상태, G0 게이트, AUTO_FIX, AB_COMPARISON, DESIGN_REVIEW) + AutoCycle v1.1 (Step 0 Pre-draft, 사용자 주도 한정)

---

## 0. ENTRYPOINT 정의

Phase 실행의 **단일 진입점**은 `phase-X-Y-status.md` 파일이다.

### ENTRYPOINT 규칙

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **ENTRY-1** | 단일 진입점 | 모든 Phase 작업은 `docs/phases/phase-X-Y/phase-X-Y-status.md`를 먼저 읽는 것으로 시작 |
| **ENTRY-2** | 상태 기반 분기 | `current_state` 값에 따라 다음 행동을 결정 ([§3.1](#31-상태별-action-table) 참조) |
| **ENTRY-3** | SSOT 버전 확인 | 진입 시 `ssot_version` 필드와 현재 SSOT 버전의 일치 여부를 확인 |
| **ENTRY-4** | Blocker 우선 확인 | `blockers` 배열이 비어있지 않으면 다른 작업보다 Blocker 해결을 우선 |
| **ENTRY-5** | 진입점 외 직접 시작 금지 | status 파일을 읽지 않고 Task 구현을 바로 시작하는 것을 금지 |

**ENTRYPOINT 플로우**:
```
세션 시작 / Phase 재개
  │
  ▼
[1] SSOT 로딩 (0→1→2→3) ← FRESH-1
  │
  ▼
[2] phase-X-Y-status.md 읽기 ← ENTRY-1
  │
  ▼
[3] ssot_version 확인 ← ENTRY-3
  │
  ├── 불일치 → SSOT 리로드 ← FRESH-3
  │
  ▼
[4] blockers 확인 ← ENTRY-4
  │
  ├── 비어있지 않음 → Blocker 해결 우선
  │
  ▼
[5] current_state 기반 다음 행동 결정 ← ENTRY-2
  │
  ▼
[6] 팀 상태 확인 (TeamCreate 필요 여부, 팀원 idle 상태) ← [0-entrypoint §3.9](0-entrypoint.md#39-팀-라이프사이클)
  │
  ▼
[7] 워크플로우 실행
```

---

## 1. 워크플로우 상태 머신

### 1.1 상태 정의 (20개 — 4th 14개 + 5th 6개)

#### 4th 기존 상태 (14개)

| 상태 코드 | 상태명 | 설명 | 진입 조건 |
|----------|--------|------|----------|
| `IDLE` | 대기 | Phase 미시작 | 초기 상태 |
| `TEAM_SETUP` | 팀 구성 | TeamCreate + 팀원 스폰 | Phase 시작 명령 |
| `PLANNING` | 계획 | planner 팀원이 요구사항 분석, Task 분해 | 팀 구성 완료 (또는 RESEARCH_REVIEW 통과) |
| `PLAN_REVIEW` | 계획 검토 (G1) | Team Lead가 planner 결과 검증 | PLANNING 완료 |
| `TASK_SPEC` | Task 내역서 작성 | Task별 실행 계획 문서 생성 | PLAN_REVIEW 통과 (또는 DESIGN_REVIEW 통과) |
| `BUILDING` | 구현 | backend-dev/frontend-dev가 코드 작성 | TASK_SPEC 완료 (또는 BRANCH_CREATION 완료) |
| `VERIFYING` | 검증 (G2) | verifier가 코드 리뷰 → Team Lead 보고 | BUILDING 완료 (또는 AUTO_FIX 완료) |
| `TESTING` | 테스트 (G3) | tester가 테스트 실행 → Team Lead 보고 | VERIFYING 통과 |
| `INTEGRATION` | 통합 테스트 | Phase 전체 통합 검증 (API↔UI 연동) | 모든 Task TESTING 통과 (또는 AB_COMPARISON 완료) |
| `E2E` | E2E 테스트 | 사용자 시나리오 기반 전체 테스트 | INTEGRATION 통과 |
| `E2E_REPORT` | E2E 리포트 | Verification Report + E2E 리포트 작성 | E2E 통과 |
| `TEAM_SHUTDOWN` | 팀 해산 | 팀원 셧다운 + TeamDelete | E2E_REPORT 완료 |
| `BLOCKED` | 차단 | Blocker 이슈 발생 | 어떤 상태에서든 진입 가능 |
| `REWINDING` | 리와인드 | 이전 상태로 롤백 중 | FAIL 판정 시 |
| `DONE` | 완료 | Phase 종료 | TEAM_SHUTDOWN 완료 |

#### 5th 신규 상태 (6개)

| 상태 코드 | 상태명 | 설명 | 진입 조건 | 필수/선택 |
|----------|--------|------|----------|:---------:|
| `RESEARCH` | 조사 | Research Team이 기술 조사·아키텍처 탐색 수행 | TEAM_SETUP 완료 + `5th_mode.research = true` | 선택 |
| `RESEARCH_REVIEW` | 조사 검토 (G0) | Team Lead가 Research Team 결과 검증 | RESEARCH 완료 | 선택 (RESEARCH 시 필수) |
| `BRANCH_CREATION` | 브랜치 생성 | Phase 전용 Git 브랜치 생성·확인 | TASK_SPEC 완료 + `5th_mode.branch = true` | 선택 |
| `AUTO_FIX` | 자동 수정 | VERIFYING FAIL 시 자동 수정 시도 (최대 3회) | VERIFYING FAIL + `5th_mode.automation = true` | 선택 |
| `AB_COMPARISON` | A/B 비교 | 복수 구현 방안 비교 검증 | TESTING 통과 + 복수 구현 존재 시 | 선택 |
| `DESIGN_REVIEW` | 설계 검토 | 아키텍처/설계 레벨 추가 검토 | PLAN_REVIEW 통과 + 복잡도 높은 Phase | 선택 |

**조건부 실행 규칙**: 5th 신규 상태는 모두 **선택적**이다. `5th_mode` 설정 또는 Phase 특성에 따라 건너뛸 수 있으며, 건너뛴 경우 4th 기존 전이 경로를 따른다.

---

### 1.2 상태 전이 다이어그램 (20개 상태)

```
── 4th 기존 경로 ──
IDLE → TEAM_SETUP → PLANNING → PLAN_REVIEW → TASK_SPEC
                         ↑          │ FAIL
                         └──────────┘ REWINDING

TASK_SPEC → BUILDING → VERIFYING → TESTING → (다음 Task 또는 INTEGRATION)
                ↑          │ FAIL      │ FAIL
                └──────────┴───────────┘ REWINDING

모든 Task 완료 → INTEGRATION → E2E → E2E_REPORT → TEAM_SHUTDOWN → DONE
                      │ FAIL     │ FAIL
                      └──────────┘ REWINDING → BUILDING

── 5th 확장 분기 ──
TEAM_SETUP ─(5th_mode.research)→ RESEARCH → RESEARCH_REVIEW(G0)
                                                  │ PASS → PLANNING
                                                  │ FAIL → REWINDING → RESEARCH

PLAN_REVIEW ─(복잡도 높음)→ DESIGN_REVIEW → TASK_SPEC

TASK_SPEC ─(5th_mode.branch)→ BRANCH_CREATION → BUILDING

VERIFYING ─(FAIL + 5th_mode.automation)→ AUTO_FIX ─(성공)→ VERIFYING
                                             │ (3회 초과)→ REWINDING → BUILDING

TESTING ─(복수 구현)→ AB_COMPARISON → INTEGRATION

※ 어떤 상태에서든 BLOCKED로 전이 가능 (Blocker 이슈 발생 시)
```

### 1.3 조건부 상태 실행 규칙 (5th)

| 상태 | 조건 | 미충족 시 경로 |
|------|------|---------------|
| `RESEARCH` | `5th_mode.research = true` | TEAM_SETUP → PLANNING (4th 호환) |
| `RESEARCH_REVIEW` | RESEARCH 실행 시 자동 포함 | — |
| `DESIGN_REVIEW` | Phase 복잡도 높음 (Team Lead 판단) | PLAN_REVIEW → TASK_SPEC (4th 호환) |
| `BRANCH_CREATION` | `5th_mode.branch = true` | TASK_SPEC → BUILDING (4th 호환) |
| `AUTO_FIX` | `5th_mode.automation = true` + VERIFYING FAIL | VERIFYING FAIL → REWINDING → BUILDING (4th 호환) |
| `AB_COMPARISON` | 복수 구현 방안 존재 (Team Lead 판단) | TESTING → INTEGRATION (4th 호환) |

---

## 2. 상태 파일 (Status File)

### 2.1 파일 경로

```
docs/phases/phase-X-Y/phase-X-Y-status.md
```

### 2.2 상태 파일 스키마 (핵심 필드)

```yaml
---
phase: "X-Y"
ssot_version: "7.0-renewal-5th"
ssot_loaded_at: "2026-02-28T10:00:00Z"
current_state: "BUILDING"
current_task: "X-Y-2"
current_task_domain: "[FE]"
team_name: "phase-X-Y"
team_members: []
last_action: "..."
last_action_result: "PASS"   # PASS | FAIL | PARTIAL | N/A
next_action: "..."
blockers: []
rewind_target: null
retry_count: 0
gate_results: { G0_research_review: null, G1_plan_review: null, G2_code_review_be: null, ... }
task_progress: {}
error_log: []
last_updated: "2026-02-28T10:30:00Z"
# ── 5th 확장 필드 ──
5th_mode:                          # 5th 혁신 축 활성화 설정 (미설정 시 4th 호환 모드)
  research: false                  # Research-first (RESEARCH + G0)
  event: false                     # Event-first (JSONL 이벤트 로그)
  automation: false                # Automation-first (AUTO_FIX, Artifact Persister)
  branch: false                    # Branch-first (BRANCH_CREATION, Git Checkpoint)
  multi_perspective: false         # Multi-perspective (11명 Verification Council)
auto_fix_count: 0                  # AUTO_FIX 누적 횟수 (최대 3)
research_status: null              # RESEARCH 상태 추적 (null | in_progress | completed)
# ── 6th AutoCycle 반복 카운터 (영속 필수 — 세션/컨텍스트 리셋에도 유지) ──
pre_build_iteration_counter: 0     # ITER-PRE 사전반복 누적 (최대 3 — 4회차 절대 금지)
replan_counter: 0                  # ITER-POST 재계획 누적 (최대 2 — 초과분 Tech Debt 전이)
token_budget: { limit: 500000, consumed: 0, last_recorded_at: null }   # ITERATION-BUDGET 계기 — 수동 기록. 미기록 시 G2 FAIL
# ── 6th LIFECYCLE-6 에이전트 추적 (스케줄러 연계) ──
agents:
  - name: backend-dev
    spawned_at:     "2026-08-08T13:00:00+09:00"   # Team Lead 직접 기록 (SubagentStart 훅은 식별자 미전달)
    last_report_at: "2026-08-08T13:04:12+09:00"
    next_check_at:  "2026-08-08T13:07:12+09:00"   # spawn+30초 1차 / 이후 3분 주기
    respawn_count: 0                               # LIFECYCLE-5 상한 5회
---
```

**5th_mode 필드 설명**:
- `5th_mode` 전체가 없거나 모든 값이 `false`이면 **4th 호환 모드**로 동작 (14개 상태만 사용).
- 개별 축을 `true`로 설정하면 해당 5th 확장 기능이 활성화된다.

**권장 프리셋** (신규 이식 시 선택 가이드 — AUTO_FIX·이벤트 로그 등 자동 안전장치 다수가 이 스위치에 묶여 있음):

| 프리셋 | 설정 | 활성화되는 것 | 권장 대상 |
|--------|------|--------------|-----------|
| **최소** (기본값) | 전부 `false` | 없음 — 4th 호환, 수동 운영 | 첫 이식 직후 검증 단계 |
| **표준** | `automation: true` + `event: true` | AUTO_FIX 루프(상한 3회) · JSONL 이벤트 로그 · DecisionEngine | 사이클 1회 이상 완주 후 |
| **전체** | 5축 전부 `true` | 표준 + RESEARCH/G0 · Branch-first(Git Checkpoint) · 11명 Verification Council | 팀 운영 숙련 후 |

- 프리셋은 Phase 시작 시 status.md에 기입한다 (Chain 운영 시 phase-chain 파일의 `5th_mode` 기본값이 상속됨).
- `auto_fix_count`: AUTO_FIX 루프에서 재시도 횟수 추적. 3회 초과 시 에스컬레이션.
- `research_status`: Research Team 진행 상태 추적.
- `pre_build_iteration_counter` / `replan_counter`: **AutoCycle ITER-PRE(3회)·ITER-POST(2회) 반복 카운터의 유일한 정본**. 메모리(대화 컨텍스트) 변수로만 유지하는 것을 금지한다 — Phase 전환 `/clear`·세션 끊김 시 리셋되어 반복 상한이 무력화되기 때문. 반복 진입 전 반드시 status.md에서 읽고, 반복 종료 시 즉시 기록한다 (`state-transition-guard` 훅이 상한 초과를 차단).
- `agents`: LIFECYCLE-6 체크 스케줄러(`zombie_watch.sh`) 연계 필드 목록 — 필드별 상세는 `SUB-SSOT/TEAM-LEAD/2-lifecycle-procedure.md §LIFECYCLE-6 SCHEDULER` 참조 (Phase 8-5).
- 🔴 **인라인 주석 금지**: `retry_count`·`auto_fix_count`·`pre_build_iteration_counter`·`replan_counter`·`current_state` 행에는 `#` 인라인 주석을 달지 않는다 — `state-transition-guard` 훅이 값을 오파싱해 조용히 오차단·오우회할 수 있다.

---

## 3. 워크플로우 실행

### 3.0 AutoCycle 15단계 정본 표 (SSOT 유일 정본)

> 사용자 주도 = 15단계(Step 0 포함), AI handoff = 14단계(Step 0 자동 스킵 + CHAIN-13).
> 본 표가 **전 단계의 유일한 정본**이다 — 가이드 HTML 등 다른 문서의 단계 표는 본 표를 따른다.
> 상세 절차: `SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md` (§Step-0 Branch, §ITER-PRE, §ITER-POST)

| Step | 내용 | 실행 주체 | 스킬 · 템플릿 | 산출물 | 전이 조건 · 게이트 |
|------|------|-----------|---------------|--------|-------------------|
| **0** | Pre-draft (사용자 주도만) | Team Lead 단독 | `/plan` · pre-draft-topics.md | `docs/phases/pre/phase-{N}-pre-draft.md` | PROMPT-QUALITY 5항목 PASS + 사용자 승인 → master-plan 착수. ai-handoff는 자동 스킵 |
| **1** | 현행 코드 조사 | research-analyst · research-architect | (Agent 스폰) | `pre/phase-{N}-pre-analysis.md` (ANALYSIS-1) | ITER-PRE 루프 구성 요소 |
| **2** | 외부 벤치마킹 | research-analyst | WebSearch | pre-analysis 보강 | ITER-PRE 루프 구성 요소 |
| **3** | 개발 PLAN + KPI 수치화 + 관점 2분법 | planner | development-plan-template.md | development-plan | G1 (KPI 표는 Step 8·10 입력) |
| **4** | Spike 테스트 | dev (CODER) | — | Spike 결과 기록 | ITER-PRE 루프 구성 요소 |
| **5** | 프롬프트 DRIFT 체크 | planner + verifier | prompt-alignment-check.md | 정합성 판정 | DRIFT 발견 시 PLAN 보정 |
| **6** | 사전반복 종결 | Team Lead | §ITER-PRE | `iteration-{1,2,3}/` + `g-pre-gate-result.md` | Step 1~5 최대 3회(`pre_build_iteration_counter`) → **G-Pre 3기준 PASS** → BUILDING 착수. 4회차 절대 금지 |
| **7** | 본 개발 사이클 | 전원 | `/phase-init` · TeamCreate | CHAIN-6 산출물 4종 (status/plan/todo/tasks) | 상태 머신 §3.1 → G2 → Phase DONE |
| **8** | 달성 검증 (KPI 대조) | Team Lead | phase-achievement-report.md | 달성 보고서 (**§3.5**에 토큰 소비 기록 + `status.md` `token_budget` 갱신 — 미기록 시 G2 FAIL) | KPI 전부 달성 → Step 10 / 미달 → Step 9 |
| **9** | 재계획 | Team Lead | §ITER-POST | 수정계획서 (achievement-report §4) | 최대 2회(`replan_counter`) → 초과분 Tech Debt 전이 |
| **10** | KPI-driven Test Plan | tester | TESTER/1-testing-procedure.md | 테스트 계획 (5-tier) | development-plan §3.2 KPI→테스트 매핑 |
| **11** | 테스트 수행 | tester | — | 테스트 결과 | G3 (커버리지 ≥ coverage_target) |
| **12** | Tech Debt 기록 | Team Lead | tech-debt-report.md | tech-debt-report (`carryover_to`) | 차기 Phase에서 CHAIN-12 자동 로딩 |
| **13** | Final Report 6섹션 + verifier 독립 검증 | Team Lead + verifier | master-final-report.md | 최종 보고서 (§8 V-1~V-4) | verifier FAIL 시 G4 DONE 전이 차단 |
| **14** | Next Prompt Suggestion 3안 | Team Lead | master-final-report.md §7 | 3안 + §7.3 `initiator_hint` | 채택 시 차기 사이클 initiator로 상속 (AI handoff 연결) |

- 토큰 상한: ITERATION-BUDGET (7-shared-definitions.md §8) — 사이클 500K, 80% WARNING / 100% HALT.
- 중단: `/abort` (§8.5) — 반복 카운터는 리셋하지 않는다.

### 3.1 상태별 Action Table (20개 상태)

#### 4th 기존 상태 Action

| 현재 상태 | 다음 행동 | 담당 |
|----------|----------|------|
| **IDLE** | TeamCreate + 팀원 스폰 | Team Lead |
| **TEAM_SETUP** | `5th_mode.research`? → RESEARCH 진입, 아니면 SendMessage → planner: "Phase X-Y 계획 분석 요청" | Team Lead |
| **PLANNING** | planner **SendMessage** 수신 대기 (파일 폴링 금지). 수신 후 Team Lead가 phase-X-Y/ 산출물(plan, todo-list, tasks/) 생성 → PLAN_REVIEW 전이 | Team Lead |
| **PLAN_REVIEW** | planner 결과 검토 → PASS: DESIGN_REVIEW(선택) 또는 TASK_SPEC, FAIL: REWINDING→PLANNING | Team Lead |
| **TASK_SPEC** | Task 내역서 일괄 생성 (task-X-Y-N.md × N) + TaskCreate + **도메인-역할 검증(ASSIGN-1~4)** → `5th_mode.branch`? → BRANCH_CREATION, 아니면 BUILDING | Team Lead |
| **BUILDING** | **[LIFECYCLE-6]** 팀원 ≥1 인데 워처 미arm 이면 **진입 차단** → arm 후 진입. **[LIFECYCLE-6.1 SPAWN_GATE]** 스폰 → 임무 전달 → 준비 신호 60~90s 대기 → 판정 후 진입. 무응답은 `SPAWN_UNCONFIRMED`(자동 respawn 금지, 시그널 #1·#2 객관 판정 전환). SendMessage → 팀원: "Task 구현 시작" (backend-dev/frontend-dev) | 팀원 |
| **VERIFYING** | SendMessage → verifier: "검증 요청" → PASS: TESTING, FAIL: `5th_mode.automation`? → AUTO_FIX, 아니면 REWINDING | Team Lead + verifier |
| **TESTING** | SendMessage → tester: "테스트 실행" → PASS: AB_COMPARISON(선택) 또는 다음 Task 또는 INTEGRATION | Team Lead + tester |
| **INTEGRATION** | tester가 통합 테스트 실행 → PASS: E2E, FAIL: REWINDING | tester |
| **E2E** | tester가 E2E 실행 → PASS: E2E_REPORT, FAIL: REWINDING | tester |
| **E2E_REPORT** | Verification Report + E2E 리포트 작성 → TEAM_SHUTDOWN | Team Lead |
| **TEAM_SHUTDOWN** | SendMessage(shutdown_request) × N → TeamDelete → DONE | Team Lead |
| **BLOCKED** | Blocker 해결 → 이전 상태 복귀 | 해당 팀원 |
| **REWINDING** | rewind_target 상태로 전이 → 재시도 | Team Lead |
| **DONE** | Phase 완료 → **Telegram 알림 발송(NOTIFY-1)** → 다음 Phase 준비 또는 [§8 Phase Chain](#8-phase-chain-자동-순차-실행) 진행 | Team Lead |

#### Telegram 완료 알림 규칙 (NOTIFY-1~3)

**절대 생략 금지**: Phase 또는 Sub-Phase가 DONE 상태에 도달할 때마다, Team Lead는 **반드시** Telegram 알림을 발송한다. 이 규칙은 어떤 상황에서도 예외 없이 적용된다.

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **NOTIFY-1** | Phase/Sub-Phase DONE 시 Telegram 알림 필수 | DONE 전이 즉시 `scripts/pmAuto/report_to_telegram.sh`를 실행하여 완료 내역을 사용자에게 알린다. **생략 시 DONE 전이 무효** |
| **NOTIFY-2** | 알림 메시지 형식 | `"[PAB-SSOT-Nexus] ✅ Phase {N}-{M} 완료: {1줄 요약}\n📊 결과: {핵심 수치}\n📁 보고서: {보고서 경로}"` — 프로젝트명 `[PAB-SSOT-Nexus]`을 맨 앞에 표기 |
| **NOTIFY-3** | Master Plan 완료 시 종합 알림 | 전체 Chain/Master Plan 완료 시 Sub-Phase별 요약을 포함한 종합 알림 발송 |

**실행 방법**:
```bash
# 사용법: scripts/pmAuto/report_to_telegram.sh "{프로젝트명}" "{메시지}"
# → 자동으로 "[프로젝트명] 메시지" 형식으로 전송

# Phase DONE 시 (Team Lead가 실행)
scripts/pmAuto/report_to_telegram.sh "PAB-SSOT-Nexus" "✅ Phase X-Y 완료: {요약}
📊 결과: {핵심 수치}
📁 보고서: docs/phases/phase-X-Y/reports/"

# Master Plan 전체 완료 시
scripts/pmAuto/report_to_telegram.sh "PAB-SSOT-Nexus" "🎉 Phase {N} 전체 완료: {마스터 플랜 제목}
📋 Sub-Phases: {N}-1 ~ {N}-{M} 모두 DONE
📁 최종 보고서: docs/phases/phase-{N}-final-summary-report.md"
```

#### 5th 신규 상태 Action

| 현재 상태 | 다음 행동 | 담당 | 조건 |
|----------|----------|------|------|
| **RESEARCH** | Research Team 스폰 → 기술 조사·아키텍처 탐색 → research-lead가 통합 보고서 SendMessage | Research Team | `5th_mode.research = true` |
| **RESEARCH_REVIEW** | G0 게이트 판정 → PASS: PLANNING, FAIL: REWINDING→RESEARCH | Team Lead | RESEARCH 완료 시 |
| **DESIGN_REVIEW** | 아키텍처/설계 레벨 추가 검토 → PASS: TASK_SPEC, FAIL: REWINDING→PLANNING | Team Lead | Phase 복잡도 판단 |
| **BRANCH_CREATION** | Phase 전용 Git 브랜치 생성·태그 → BUILDING | Team Lead | `5th_mode.branch = true` |
| **AUTO_FIX** | 자동 수정 시도 (auto_fix_count += 1) → 성공: VERIFYING 재진입, 실패(3회 초과): REWINDING→BUILDING | 팀원 (backend-dev/frontend-dev) | `5th_mode.automation = true` + VERIFYING FAIL |
| **AB_COMPARISON** | 복수 구현 방안 비교 → 최적안 선택 → INTEGRATION | Team Lead | 복수 구현 존재 시 |

### 3.2 상태별 상세 플로우

#### IDLE → TEAM_SETUP
```
1. Team Lead: SSOT 리로드 (0→1→2→3) ← FRESH-1
2. Team Lead: TeamCreate(team_name: "phase-X-Y")
3. Task tool로 팀원 스폰: planner, backend-dev, frontend-dev (ROLES/*.md 로딩 ← FRESH-6)
4. 상태 파일 생성 (phase-X-Y-status.md)
5. current_state = "TEAM_SETUP" → "PLANNING"
6. SendMessage → planner: "Phase X-Y 계획 분석 요청"
```

#### PLANNING → PLAN_REVIEW (planner 결과 수신 및 산출물 생성)

**씽크 불일치 방지**: planner는 **쓰기 권한이 없어** 파일을 생성하지 않는다. 결과는 **SendMessage로만** Team Lead에게 전달한다. 따라서 "planner 결과 대기"는 **디렉터리 파일 폴링(sleep + ls)**이 아니라 **planner로부터 SendMessage 수신 대기**이다.

```
1. Team Lead: planner로부터 SendMessage 수신 (계획 분석 결과)
2. Team Lead: 수신한 페이로드를 phase-X-Y/ 에 산출물로 저장
   - phase-X-Y-plan.md (계획서)
   - phase-X-Y-todo-list.md (체크리스트)
   - tasks/task-X-Y-N.md (Task 명세, N = 1..)
3. current_state = "PLAN_REVIEW"
4. Team Lead: G1 검토 후 PASS → TASK_SPEC, FAIL → REWINDING → PLANNING
```

**금지**: phase-X-Y/ 디렉터리를 `sleep` + `ls`로 폴링하여 "산출물 생성 여부"를 확인하지 않는다. planner는 해당 경로에 파일을 쓰지 않는다.

➜ [ROLES/planner.md](ROLES/planner.md) (쓰기 권한 없음), [SUB-SSOT/PLANNER/1-planning-procedure.md](SUB-SSOT/PLANNER/1-planning-procedure.md)

#### BUILDING → VERIFYING → TESTING
```
[BUILDING] SendMessage → backend-dev/frontend-dev: Task 구현 → 보고서 작성 → 파일 링크로 완료 보고
[VERIFYING] SendMessage → verifier: 검증 요청 → 보고서 작성 → 파일 링크로 G2 결과 보고
[TESTING]  SendMessage → tester: 테스트 실행 → 보고서 작성 → 파일 링크로 G3 결과 보고
FAIL 시 REWINDING → BUILDING, PASS 시 다음 Task 또는 INTEGRATION
```

**병렬 BUILDING 진입 시 CWD 주입 규칙 (WT-3 연계)**:

- Team Lead 는 팀원 스폰 SendMessage 본문 상단에 `[CWD] ../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-{track}` 행을 **필수** 로 포함한다.
- 팀원(backend-dev/frontend-dev)은 FRESH-1.5 체크리스트에서 `pwd` 결과가 주입된 CWD 와 일치하는지 검증하고, 불일치 시 `[BLOCKER] WT-3 위반 — CWD 주입 불일치` 를 즉시 보고하여 작업을 중단한다.
- 메인 저장소 경로에서의 편집·빌드는 **WT-3 위반** 으로 기록되며, 위반 시 Team Lead 가 즉시 재할당한다. 상세는 `/worktree` skill 참조.

**문서 기반 보고 규칙 (REPORT-1~5)**:

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **REPORT-1** | 보고서 파일 필수 작성 | 모든 팀원은 Task 완료 시 보고서 마크다운 파일을 **Phase 디렉토리 내** `reports/` 하위에 작성 |
| **REPORT-2** | SendMessage는 링크만 | SendMessage에는 보고서 파일 경로(링크)만 포함. 텍스트 본문 보고 금지 |
| **REPORT-3** | 보고서 템플릿 준수 | [TEMPLATES/task-report-template.md](TEMPLATES/task-report-template.md) 형식 준수 |
| **REPORT-4** | 필수 섹션 5개 | 작업 내용, 작업 결과, 테스트 결과, 위험 요소, 다음 개발 추천 |
| **REPORT-5** | 보고서 경로 규칙 | `docs/phases/phase-X-Y/reports/report-{역할명}.md` (예: `report-backend-dev.md`) |

**보고서 저장 경로**:
```
docs/phases/phase-X-Y/
├── reports/
│   ├── report-backend-dev.md    ← backend-dev 작업 보고서
│   ├── report-frontend-dev.md   ← frontend-dev 작업 보고서
│   ├── report-verifier.md       ← verifier 검증 보고서
│   └── report-tester.md         ← tester 테스트 보고서
```

**SendMessage 보고 예시**:
```
"Phase 38-1 Task 1,2 완료. 보고서: docs/phases/phase-38-1/reports/report-backend-dev.md"
```

**테스트 범위 (선택적 실행 원칙)**: 전체 테스트 실행(`pytest tests/`)은 불필요하다. **변경한 코드에 영향받는 테스트만 선택 실행**한다. Team Lead는 테스트 요청 시 **변경 도메인/파일 정보**를 tester에게 전달하고, tester는 [docs/tests/index.md](../../../tests/index.md)에서 해당 시나리오(A~I)를 확인하여 필요한 테스트만 실행한다. [ROLES/tester.md §3.5](ROLES/tester.md#35-테스트-범위-선택적-실행-원칙).

**G3 결과 수신**: tester는 보고서를 `docs/phases/phase-X-Y/reports/report-tester.md`에 작성하고, SendMessage로 파일 경로를 보고한다. Team Lead는 해당 보고서를 읽어 판정한다. ~~`/tmp/agent-messages/` 경로 사용은 폐기.~~

**테스트 요청·결과 문서화(1주기)**: 요청서(목록)+결과서는 **docs/pytest-report/** 에 `YYMMDD-HHMM-phase-X-Y-테스트명.md` 로 저장하여 기록 조회. ➜ [SUB-SSOT/TESTER/1-testing-procedure.md](SUB-SSOT/TESTER/1-testing-procedure.md)

#### TEAM_SETUP → RESEARCH → RESEARCH_REVIEW (5th 확장)

> `5th_mode.research = true` 시에만 실행. 미설정 시 TEAM_SETUP → PLANNING 직행 (4th 호환).

```
1. Team Lead: TEAM_SETUP 완료 후 5th_mode.research 확인
2. research = true → Research Team 스폰 (research-lead, research-architect, research-analyst)
3. current_state = "RESEARCH"
4. research-lead: 조사 범위 정의 → Team Lead 승인
5. research-architect + research-analyst: 병렬 탐색 (기술 스택, 코드베이스, 아키텍처)
6. research-lead: 결과 통합 → SendMessage(Team Lead): 조사 보고서
7. current_state = "RESEARCH_REVIEW" (G0 게이트)
8. Team Lead: G0 판정
   - PASS → research_status = "completed", PLANNING 진입
   - FAIL → REWINDING → RESEARCH (조사 보완 요청)
```

**G0 게이트 판정 기준**:

| 기준 | PASS 조건 |
|------|----------|
| 기술 조사 완료 | 요구 기술에 대한 조사가 충분히 수행됨 |
| 아키텍처 대안 | 최소 2개 이상의 구현 대안이 비교됨 |
| 리스크 분석 | 기술적 리스크와 완화 방안이 포함됨 |
| 영향 범위 식별 | 변경 대상 파일·모듈이 식별됨 |
| PoC 결과 (선택) | 핵심 기술 검증용 PoC 수행 (필수 아님) |

#### PLAN_REVIEW → DESIGN_REVIEW (5th 확장, 선택적)

> Phase 복잡도가 높다고 Team Lead가 판단한 경우에만 진입.

```
1. PLAN_REVIEW G1 PASS 후 Team Lead가 복잡도 평가
2. 복잡도 높음 → current_state = "DESIGN_REVIEW"
3. Team Lead + planner (또는 research-architect): 아키텍처/설계 레벨 검토
4. PASS → TASK_SPEC, FAIL → REWINDING → PLANNING
```

#### TASK_SPEC — 도메인-역할 할당 규칙 (ASSIGN)

> **배경**: Team Lead가 편의상 `[TEST]` Task를 backend-dev에 할당하는 위반이 반복 발생 (V-25-3, V-25-4-001). 구현자가 자기 코드를 검증하는 **셀프 체크**는 G3 독립성을 훼손한다.

> **⚠️ 절대 원칙**: 테스트·코드 검증·A/B 평가 등 **검증 성격의 모든 작업**은 backend-dev/frontend-dev가 **절대 수행하지 않는다**. 이러한 작업은 **반드시 tester·verifier·QC에게만** 위임하며, Team Lead가 이를 **강력하게 통제·제어**한다.

| ID | 규칙 | 설명 | 심각도 |
|----|------|------|--------|
| **ASSIGN-1** | 도메인-역할 매핑 필수 | `[BE]`→backend-dev, `[FE]`→frontend-dev, `[TEST]`→tester, `[DOC]`→해당 전문가 또는 Team Lead | CRITICAL |
| **ASSIGN-2** | [TEST] Task는 tester 전용 | `[TEST]` 도메인 Task를 backend-dev/frontend-dev에 할당 **절대 금지**. 구현자 셀프 체크 방지 | CRITICAL |
| **ASSIGN-3** | 할당 전 검증 | Task assignee 지정 시 **도메인 태그 ↔ 역할 일치**를 Team Lead가 반드시 검증. 불일치 시 할당 불가 | CRITICAL |
| **ASSIGN-4** | 스크립트 실행·분석 Task | 코드 작성이 아닌 **스크립트 실행+분석** Task는 tester(Bash) 또는 verifier(Explore)에 할당. backend-dev는 **코드 작성만** 담당 | CRITICAL |
| **ASSIGN-5** | Team Lead 통제 의무 | Team Lead는 **모든 검증·테스트·QC 작업이 구현자(BE/FE)에게 할당되지 않았는지** 능동적으로 감시. 팀원 스폰 시점·Task 할당 시점·작업 진행 중 3단계 검증 필수 | CRITICAL |

**역할 책임 경계** (위반 시 즉시 시정):

| 역할 | 수행 가능 | 수행 절대 금지 |
|------|----------|--------------|
| backend-dev | 코드 작성, 리팩토링, 문서 작성 | 테스트 실행, 코드 검증, A/B 평가, QC |
| frontend-dev | UI 코드 작성, 스타일링 | 테스트 실행, 코드 검증, A/B 평가, QC |
| tester | 테스트 실행, A/B 평가, 스크립트 실행 | 프로덕션 코드 수정 |
| verifier | 코드 검증, 품질 분석, 탐색 | 프로덕션 코드 수정 |
| QC | 최종 품질 확인, 회귀 검증 | 프로덕션 코드 수정 |

**검증 절차** (TASK_SPEC 상태에서 Team Lead 필수 수행):
```
1. 각 Task의 도메인 태그 확인: [BE], [FE], [TEST], [DOC], [FS], [DB], [INFRA]
2. ASSIGN-1 매핑표 대조 → assignee 결정
3. [TEST] 태그 Task → 반드시 tester 할당 (ASSIGN-2)
4. 스크립트 실행/A/B 평가 등 → tester 또는 verifier 할당 (ASSIGN-4)
5. 검증·테스트·QC 성격 Task가 BE/FE에 할당되었는지 최종 점검 (ASSIGN-5)
6. 불일치 발견 시 → 할당 수정 후 진행
```

**Team Lead 3단계 통제** (ASSIGN-5):
```
① 스폰 시점: 팀원 역할(tester/verifier)과 할당 Task 성격 일치 확인
② 할당 시점: TaskUpdate(owner) 실행 전 도메인-역할 교차 검증
③ 진행 중:   팀원 보고 시 "구현자가 검증 수행" 징후 감지 → 즉시 중단·재할당
```

**위반 시 조치**: 즉시 작업 중단 + 올바른 역할에 재할당 + violations 섹션 기록 + MEMORY.md 재발 방지 등록.

#### 에이전트 라이프사이클 관리 규칙 (AGENT-LIFECYCLE)

> Team Lead는 에이전트(팀원)의 생성·운영·종료를 **엄격하게** 관리한다. 유휴 에이전트를 방치하지 않는다.

| ID | 규칙 | 설명 | 심각도 |
|----|------|------|--------|
| **LIFECYCLE-1** | 5분 무보고 점검 | 에이전트가 **5분 이상 보고 없이 idle** 상태이면, Team Lead는 해당 에이전트의 역할·할당 Task를 점검하고 **필요 시 즉시 종료** | CRITICAL |
| **LIFECYCLE-2** | 미사용 에이전트 즉시 종료 | 할당된 Task가 없거나, 모든 Task가 완료된 에이전트는 **즉시 shutdown_request**로 종료. 유휴 방치 금지 | CRITICAL |
| **LIFECYCLE-3** | 종료 전 Task 상태 확인 | 에이전트 종료 전 TaskList로 해당 에이전트의 in_progress Task를 확인. 미완료 Task가 있으면 재할당 또는 보류 판단 후 종료 | HIGH |
| **LIFECYCLE-4** | 팀 해산 시 전원 종료 | 팀 작업 완료 시 **모든 팀원에게 shutdown_request** 후 TeamDelete. 잔류 에이전트 없이 깨끗하게 정리 | HIGH |
| **LIFECYCLE-5** | 좀비 감지 + Respawn | spawn 후 30초 1차 check + 3분 정기 check. 좀비 확인 시 shutdown_request + suffix(`_r1`~`_r5`)로 동일 spec respawn. **상한 5회**. 누적 도달 시 task BLOCKED + 사용자 보고 (상세: SUB-SSOT TEAM-LEAD `2-lifecycle-procedure.md` §LIFECYCLE-5 RESPAWN) | CRITICAL |
| **LIFECYCLE-6** | 체크 스케줄러 | LIFECYCLE-1·5 의 실행체. 팀원 ≥1 인 Phase 는 **TEAM_SETUP 완료 직후 워처 arm**(BUILDING 진입 시 미arm이면 진입 차단 — 2차 방어선). 3분 주기 폴링 + spawn+30초 1차 체크, 상태 변화 시에만 알림 (상세: SUB-SSOT TEAM-LEAD `2-lifecycle-procedure.md` §LIFECYCLE-6 SCHEDULER) | CRITICAL |

**Team Lead 에이전트 관리 절차**:
```
1. 에이전트 스폰 → 즉시 Task 할당 (idle 스폰 금지)
2. 5분 타이머: 보고 없으면 → TaskList 확인 → 역할·Task 점검
3. 점검 결과:
   a. Task 진행 중 + 정상 → 메시지로 상태 확인 요청
   b. Task 없음 / 완료됨 → 즉시 종료 (shutdown_request)
   c. 역할 불일치 발견 → 즉시 중단 + 재할당 또는 종료
   d. 좀비 의심(프로세스 부재/무응답) → LIFECYCLE-5 진입 (SUB-SSOT TEAM-LEAD `2-lifecycle-procedure.md` §LIFECYCLE-5 RESPAWN 참조)
4. 팀 작업 완료 → 전원 종료 → TeamDelete
```
> 위 3.a/3.d 판정은 LIFECYCLE-6 워처(arm 상태에서 3분 폴링)가 emit 하는 상태 변화 알림을 근거로 삼는다 (상세: SUB-SSOT TEAM-LEAD `2-lifecycle-procedure.md` §LIFECYCLE-6 SCHEDULER).

---

#### TASK_SPEC → BRANCH_CREATION (5th 확장, 선택적)

> `5th_mode.branch = true` 시에만 실행.

```
1. TASK_SPEC 완료 후 5th_mode.branch 확인
2. branch = true → current_state = "BRANCH_CREATION"
3. Team Lead: git checkout -b phase-{X}-{Y}        ← 메인 저장소에서 브랜치 생성
3a. Team Lead: 병렬 트랙 수 N 판정 (1-project.md §7.3)
3b. N ≥ 2 → WORKTREE_SETUP 진입 (필수, WT-1).
    N = 1 → worktree 선택적 (권장: 건너뜀, 메인 clone에서 BUILDING 진행)
4. Git 태그: phase-{X}-{Y}-BRANCH_CREATION
5. current_state = "WORKTREE_SETUP" (N ≥ 2) 또는 "BUILDING" (N = 1)
```

> 상세: `/worktree` skill (수명 주기 자동화) 참조.

#### BRANCH_CREATION → WORKTREE_SETUP (병렬 N ≥ 2 필수, WT-1)

> `BRANCH_CREATION` 블록 3b 에서 N ≥ 2 로 판정된 경우의 서브 상태. 상세 커맨드 시트는
> `/worktree` skill 참조.

```
1. 각 트랙 {track} ∈ {be, fe, ver, ...} 에 대해:
   git worktree add ../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-{track} phase-{X}-{Y}-{track}  # → /worktree로 자동화 가능
2. 각 worktree 에서 의존성 설치 (npm ci / pip install -r requirements.txt 등) — 의존성 독립 격리 보장 (/worktree 자동 수행)
3. Git 태그: phase-{X}-{Y}-WORKTREE_SETUP
4. phase-{X}-{Y}-status.md 에 worktree_paths (YAML 배열) + cleanup_wt: pending 필드 기록 (WT-5)
5. current_state = "BUILDING" (각 worktree 경로는 팀원 스폰 시 CWD 로 주입)
```

##### G-C 차단 게이트 (WT-7 연계, Phase 7-1 신규)

> **차단 조건**: `phase-{X}-{Y}-status.md` YAML 에 `worktree_required: true` 인데 `worktree_paths: []` 빈 상태 → `BRANCH_CREATION → BUILDING` 직접 전이 **금지**.

```
1. Team Lead 는 `current_state = BUILDING` 전이 금지 (강제 차단)
2. 즉시 `WORKTREE_SETUP` 절차 (위 5단계) 실행
3. `worktree_paths` 가 채워진 후에만 `BUILDING` 전이 허용
```

| 항목 | 내용 |
|------|------|
| **차단 트리거** | status.md `worktree_required: true` + `worktree_paths: []` |
| **차단 동작** | Team Lead `BUILDING` 전이 거부 → `WORKTREE_SETUP` 강제 실행 |
| **누락 시 안전망** | G-D (verifier G2) 가 트랙 ≥ 2 + worktree 미생성 시 **G2 FAIL** 로 적발 (WT-7) |
| **인지 게이트 위치** | 5단 게이트 체인 G-A (Plan 안내) → G-B (phase-init YAML) → **G-C (본 차단)** → G-D (G2 FAIL) → G-E (사후 권고) |
| **상세** | §6.6.2 WT-7 게이트 체인 / `/worktree` skill / [01-design-decisions.md §2 G-C](../../poc/worktree-gate-design/01-design-decisions.md) (rev.2 APPROVED) |

#### VERIFYING → AUTO_FIX (5th 확장, 선택적)

> `5th_mode.automation = true` + VERIFYING FAIL (PARTIAL) 시에만 진입.

```
1. VERIFYING G2 FAIL (Critical 0건, High만 = PARTIAL)
2. 5th_mode.automation = true → current_state = "AUTO_FIX"
3. Team Lead → SendMessage(backend-dev/frontend-dev): "G2 FAIL 항목 자동 수정"
4. 팀원 수정 → 완료 보고
5. auto_fix_count += 1
6. auto_fix_count <= 3 → VERIFYING 재진입
7. auto_fix_count > 3 → REWINDING → BUILDING (접근 방식 재고)
```

**AUTO_FIX 루프 규칙**:

| 규칙 | 내용 |
|------|------|
| **최대 재시도** | 3회 (`auto_fix_count <= 3`) |
| **진입 조건** | VERIFYING FAIL + `5th_mode.automation = true` + Critical 0건 |
| **성공 시** | VERIFYING 재진입 (재검증) |
| **3회 초과** | `auto_fix_count` 리셋, REWINDING → BUILDING |
| **Critical FAIL** | AUTO_FIX 진입 불가 — 즉시 REWINDING → BUILDING |

#### TESTING → AB_COMPARISON (5th 확장, 선택적)

> 복수 구현 방안이 존재하고 비교 필요 시에만 진입.

```
1. TESTING PASS 후 복수 구현 존재 여부 확인
2. 복수 존재 → current_state = "AB_COMPARISON"
3. Team Lead: 구현 A vs B 비교 (성능, 가독성, 유지보수성)
4. 최적안 선택 → INTEGRATION (또는 다음 Task)
```

#### 3.3 병렬 BUILDING 및 재검증

**참조**: [1-project.md §7.3](1-project.md#73-병렬-처리-정책-backend--frontend--verifier).

| 규칙 | 설명 |
|------|------|
| **병렬 허용 조건** | **완전히 분리된 작업**일 때만 병렬. 수정 파일 집합 교집합 ∅, EDIT-5 준수. 신규 기능 제작 Phase는 **단일 인스턴스·순차 진행**. |
| **병렬 BUILDING 후** | 병렬 BUILDING을 사용한 Phase는 **전체 Task 완료 후** 반드시 **재검증** 수행. |
| **재검증 절차** | ① 병렬 BUILDING 완료 → ② Team Lead가 **Phase 전체 변경 파일**을 verifier에게 전달 → ③ verifier가 **통합 G2 검증**(BE+FE 또는 verifier-be + verifier-fe 결과 취합) → ④ PASS 시 TESTING/INTEGRATION 진행. FAIL 시 REWINDING → BUILDING. |

```
[병렬 BUILDING 완료]
  │
  ▼
[재검증] Team Lead → SendMessage(verifier): "Phase X-Y 전체 변경 대상 통합 검증 요청"
  │
  ▼
[VERIFYING] verifier → G2 통합 판정 → Team Lead 보고
  │
  ├── PASS → TESTING / INTEGRATION
  └── FAIL → REWINDING → BUILDING
```

---

## 4. 품질 게이트 (Quality Gates — G0~G4, 5th 확장)

### 4.1 게이트 구조

```
[G0: Research Review] ← 5th 신규. Research Team 조사 결과 검증 (5th_mode.research = true 시)
  ↓
[G1: Plan Review]     planner 분석 → Team Lead 검토
  ↓
[G2: Code Review]     verifier가 BE+FE 코드 검증 → Team Lead 보고
  ↓
[G3: Test Gate]       tester가 테스트 실행 + 커버리지 확인
  ↓
[G4: Final Gate]      Team Lead가 G2+G3 종합 판정
```

### 4.2 게이트별 판정 기준

| 게이트 | 판정 기준 | 결과 |
|--------|----------|------|
| **G0** *(5th 신규)* | 기술 조사 완료, 아키텍처 대안 2개+, 리스크 분석 포함, PoC 결과(선택) | PASS → PLANNING / FAIL → RESEARCH |
| **G1** | 완료 기준 명확, Task 3~7개, 도메인 분류 완료, 리스크 식별 | PASS → TASK_SPEC / FAIL → PLANNING |
| **G2** | Critical 0건 (ORM, Pydantic, type hints, ESM, esc(), CDN) | PASS → TESTING / PARTIAL → AUTO_FIX ([5-automation.md §3.2](5-automation.md#32-자동-판정-규칙) 6조건 AND 충족 시) / FAIL → BUILDING |
| **G3** | pytest PASS, 커버리지 >=80%, E2E PASS, 회귀 테스트 통과, **결함 밀도 ≤ 5건/KLOC** (ISTQB CTFL 4.0 기반) | PASS → INTEGRATION / FAIL → BUILDING |
| **G4** | G2 PASS + G3 PASS + Blocker 0건 | PASS → DONE / PARTIAL → Tech Debt / FAIL → REWINDING |

> **G3 결함 밀도 계산법** (ISTQB CTFL 4.0):
> `결함 밀도 = 발견 결함 수 / (코드 줄 수 ÷ 1000)`
> - 단위: 건/KLOC (Kilo Lines of Code)
> - 기준: ≤ 5건/KLOC 이면 PASS, 초과 시 FAIL
> - 결함 보고서 양식: [TEMPLATES/defect-report-template.md](TEMPLATES/defect-report-template.md)
> - 결함 분류 체계: [SUB-SSOT/TESTER/1-testing-procedure.md](SUB-SSOT/TESTER/1-testing-procedure.md) (ISTQB CTFL 4.0 기반)

### 4.3 G0 Research Review 상세 (5th 신규)

**수행자**: Team Lead (+ verifier 선택적 참여)
**입력**: Research Team의 `research-report.md`
**판정 체크리스트**:
- [ ] 기술 선택의 근거가 충분한가
- [ ] 영향 범위가 식별되었는가 (파일, 모듈, API 단위)
- [ ] 리스크에 대한 완화 방안이 있는가
- [ ] 대안이 2개 이상 검토되었는가
- [ ] (선택) PoC 결과가 첨부되었는가

**결과**: PASS → PLANNING 진입 | FAIL → RESEARCH 재실행 (보완 지시)

### 4.4 G2 Code Review Entry 체크리스트 및 CL 크기 기준

#### G2 Entry 체크리스트 (G2 진입 전 사전 준비 확인)

G2 코드 리뷰에 진입하기 전, 다음 항목이 충족되어야 한다:

| # | 항목 | 설명 | 확인 |
|:-:|------|------|:----:|
| 1 | Task 구현 완료 | todo-list의 해당 Task 체크박스 모두 체크 | [ ] |
| 2 | 자체 테스트 실행 | 구현자가 로컬에서 pytest/vitest 실행 후 PASS 확인 | [ ] |
| 3 | 줄수 확인 | 신규/수정 파일 500줄 이하 (HR-5 REFACTOR-3) | [ ] |
| 4 | 타입 힌트 완비 | 모든 함수의 파라미터 + 반환 타입 힌트 존재 | [ ] |
| 5 | import 정리 | 미사용 import 제거, 순환 참조 없음 | [ ] |
| 6 | 디버그 코드 제거 | console.log, print, debugger, TODO(temp) 등 제거 | [ ] |

#### CL 크기 권장 기준

Google CL Review 베스트 프랙티스 기반, Task 단위 변경 크기를 제한한다:

| 크기 | 줄 수 | 판정 | 조치 |
|------|------:|:----:|------|
| Small | ~100줄 | 권장 | 빠른 리뷰 가능 |
| Medium | 100~300줄 | 허용 | 일반적 Task 크기 |
| Large | 300~500줄 | 주의 | 분할 가능 여부 검토 |
| Too Large | 500줄+ | 경고 | Task 분할 필수 (HR-5) |

---

## 5. 에러 처리

| 등급 | 명칭 | 처리 |
|------|------|------|
| **E0** Critical | 즉시 중단, 사용자 보고 |
| **E1** Blocker | BLOCKED 전이, Fix Task 생성 |
| **E2** High | REWINDING, 수정 요청 |
| **E3** Medium | Technical Debt 등록 |
| **E4** Low | 기록만 |

**재시도**: `retry_count`는 **Phase 누적 카운터**다 (status.md 정본 — 상태 불문 REWINDING 전이마다 +1, §6.1). 누적 ≥ 3이면 접근 방식 폐기, 에러 로그 보고, 사용자 판단 대기. **상태별로 별도 계수하지 않는다** — 서로 다른 게이트에서 나눠 실패해도 합산 3회에서 중단된다. 각 REWINDING의 발생 상태·사유는 `error_log[]`에 병기하여 사유별 추적을 보장한다. (상한 초과 기록은 `state-transition-guard` 훅이 차단)

---

## 6. 리와인드 (Rewind) · Git Checkpoint · Worktree 규칙

### 6.1 리와인드 기본 절차

실패 시 rewind_target 결정 → current_state = "REWINDING" → 해당 팀원에게 수정 요청 → rewind_target으로 전이 → retry_count += 1.
(PLAN_REVIEW 실패 → PLANNING, VERIFYING/TESTING/INTEGRATION/E2E 실패 → BUILDING)

### 6.2 A/B 분기 (AB_COMPARISON 연계)

`AB_COMPARISON` 진입 시 복수 구현안을 각각 독립 브랜치에서 구현한다. 상세 상태 전이는 §3.2 "TESTING → AB_COMPARISON" 블록 참조. 브랜치 네이밍·Git Checkpoint 규칙은 본 §6.4 에서 worktree 격리와 함께 기술한다.

### 6.3 REWINDING 과 worktree (WT-1 연계)

REWINDING 시 실패한 worktree 는 **보존** 하고, `retry-N` worktree 를 **추가 생성** 하여 재시도 격리를 보장한다.

```
1. phase-{X}-{Y} 실패 시점에 태깅: git tag phase-{X}-{Y}-retry-{N-1}-fail
2. retry 브랜치 생성: git checkout -b phase-{X}-{Y}-retry-{N}
3. retry worktree 추가: git worktree add ../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-retry-{N} phase-{X}-{Y}-retry-{N}  # → /worktree로 자동화 가능
4. 실패 worktree 는 §6.5 아카이브 규칙에 따라 Chain 종료까지 보존 (포렌식·롤백 용)
5. 성공 시 retry worktree 를 정본으로 채택, 실패 worktree 는 아카이브 후 제거 (WT-4)
```

> 상세: `/worktree` skill (REWINDING 지원) 참조.

### 6.4 A/B 분기 + worktree (WT-1, WT-4 연계)

`AB_COMPARISON` 에서 A/B 두 구현안을 병렬 수행할 때, 두 브랜치를 **각각 독립 worktree 에 격리** 한다 (WT-1 필수). 빌드 산출물·환경 변수·측정값이 교차 오염되지 않도록 의존성 독립 격리를 강제한다.

```
A/B 분기 시작
  → git tag phase-{X}-{Y}-ab-start
  → git checkout -b phase-{X}-{Y}-branch-A
  → git checkout main ; git checkout -b phase-{X}-{Y}-branch-B
  → git worktree add ../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-ab-A phase-{X}-{Y}-branch-A        # WT-1 필수 (→ /worktree로 자동화 가능)
  → git worktree add ../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-ab-B phase-{X}-{Y}-branch-B        # WT-1 필수 (→ /worktree로 자동화 가능)
  → 각 worktree 에서 병렬 구현 (CWD 격리 보장, 의존성 독립)
  → 비교 평가 (ab-comparison-template.md)
  → 선택된 브랜치 main 에 merge
  → 비선택 브랜치 worktree 제거 + 브랜치 아카이브 태깅 (WT-4)
    · git tag archive/phase-{X}-{Y}-branch-{비선택} phase-{X}-{Y}-branch-{비선택}
    · git worktree remove ../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-ab-{비선택}  # → /worktree로 자동화 가능
  → git worktree prune  # → /worktree로 자동화 가능
```

> 상세: `/worktree` skill (A/B 분기 지원) 참조.

### 6.5 실패·비선택 브랜치 아카이브 규칙

- REWINDING 에서 실패한 브랜치와 A/B 비선택 브랜치는 **즉시 삭제하지 않는다**.
- Chain 종료 시점까지 `archive/phase-{X}-{Y}-*` 태그로 보존하며, worktree 는 WT-4 에 따라 Chain 완료 시 일괄 제거한다.
- 롤백이 필요한 경우 아카이브 태그에서 재체크아웃 후 새 worktree 를 생성한다.

### 6.6 Worktree 규칙 (WT-1 ~ WT-5)

병렬 BUILDING·A/B 분기·REWINDING 에서 공통 적용되는 worktree 운영 규칙. 본 절은 규칙 정의만 담고, 운영 커맨드·디렉토리 규약·체크리스트는 `/worktree` skill로 자동화된다.

| ID | 규칙 | 심각도 |
|----|------|--------|
| **WT-1** | **worktree 필수 조건** — 병렬 BUILDING 트랙 수 ≥ 2 일 때 worktree 없이 BUILDING 진입 금지. A/B 분기(§6.4)·REWINDING(§6.3) 에서도 적용 | CRITICAL |
| **WT-2** | **경로 규약** — `../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-{track}` 패턴만 허용. 저장소 내부 `.worktrees/` 배치 금지 (gitignore 누락 시 재귀 노출 위험) | HIGH |
| **WT-3** | **CWD 일관성** — 팀원은 스폰 시 주입된 worktree 경로 밖에서 편집·빌드 금지. 위반 시 즉시 작업 중단·재할당. BUILDING 단락 CWD 주입 규칙과 연계 | CRITICAL |
| **WT-4** | **수명 주기** — Phase Chain 완료 시 `git worktree remove` + `git worktree prune` 일괄 수행. 실패 브랜치(REWINDING)·A/B 비선택 브랜치는 §6.5 아카이브 규칙 준수 후 제거 | HIGH |
| **WT-5** | **상태 기록** — `phase-{X}-{Y}-status.md` YAML 에 `worktree_paths: []` 와 `cleanup_wt: pending\|done` 필드 필수 기록 | MEDIUM |

**근거·인용**:

- WT 규칙 상세 및 충돌·누수 방지: `/worktree` skill 참조
- 병렬 처리 정책 연계 (EDIT-5 보강): [1-project.md §7.3](1-project.md#73-병렬-처리-정책-backend--frontend--verifier)
- 규칙 인덱스 등록: [core/6-rules-index.md](core/6-rules-index.md) WT 카테고리
- 운영 자동화: `/worktree` skill (Phase-K 대체 완료)

**심각도 분포 요약** (WT-1~5): CRITICAL 2 (WT-1, WT-3) / HIGH 2 (WT-2, WT-4) / MEDIUM 1 (WT-5).
**WT-6/WT-7 포함 시**: CRITICAL 2 / HIGH 4 / MEDIUM 1 (총 7개) — Phase 7-1 추가.

### 6.6.1 WT-6 — worktree 발동 휴리스틱 룰 (Phase 7-1 신규)

> **원본 정본**: [docs/poc/worktree-gate-design/01-design-decisions.md §1](../../poc/worktree-gate-design/01-design-decisions.md) (rev.2 APPROVED)
> **Cross-reference**: `/worktree` skill / WT-7 (§6.6.2) / 6-rules-index.md §1.21

| 항목 | 내용 |
|------|------|
| **ID** | WT-6 |
| **심각도** | HIGH |
| **요약** | 신호 셋 S1+S5+S6 기반 worktree 발동 3분 판정 (필요/권장/불필요). 우선순위 S6 > S5 > S1. **자동 발동 금지** — 사용자 통제권 보장 (필요만 강제, 권장은 안내). |

#### D1. 입력 신호 셋 (시작 셋)

| 신호 ID | 출처 | 추출 방법 | 신뢰도 |
|---------|------|----------|-------|
| **S1. 트랙 수 N** | Task 도메인 태그 `[BE]/[FE]/[TEST]` 카운트 | Task 명세 파일 grep | 높음 |
| **S5. 상태머신 분기** | status.md `current_state` | 직접 매핑: `AB_COMPARISON` / `REWINDING` → 자동 필요 | 확정 |
| **S6. 사용자 명시** | Plan/Phase 본문 `worktree: yes/no` | 사용자 직접 선언 | 확정 |

> 확장 후보 (V2): S2(분기 키워드), S3(retry 키워드), S4(파일 충돌 예측). 운영 후 점진 추가.

#### D2. 판정 결과 카테고리 — 3분

| 카테고리 | 의미 |
|---------|------|
| **필요** | WT-1 CRITICAL 등 강제 발동 (G-C 차단, G-D FAIL) |
| **권장** | 회색지대 — 안내만, 사용자 결정 |
| **불필요** | 아무 출력 없음 |

#### D3. 룰 (조건식, 우선순위 ↓)

```
[1] 사용자 명시 (S6) 우선
    worktree: yes 명시 → 강제로 "필요"
    worktree: no 명시  → 강제로 "불필요" (단 S5 만족 시 경고)

[2] 상태머신 자동 발동 (S5)
    current_state ∈ {AB_COMPARISON, REWINDING} → "필요"

[3] 트랙 수 (S1)
    N ≥ 2           → "필요"     (WT-1 CRITICAL)
    N = 1 + Task ≥ 10 → "권장"   (대형 단일 트랙도 격리 효과)
    N = 1 + Task < 10 → "불필요"

[4] 알 수 없음 (Task 명세 미작성 등)
    → "권장" + 안내 메시지로 사용자에게 판정 요청
```

#### D4. 권유 vs 강제 정책

| 결과 | G-A (Plan) | G-B (phase-init) | G-C (BUILDING) | G-D (G2) |
|------|----------|----------------|--------------|---------|
| **필요** | 한 줄 안내 | YAML `worktree_required: true` | `worktree_paths: []` 시 **차단** | 미생성 시 **FAIL** |
| **권장** | 안내+사용자 확인 요청 | YAML `worktree_recommended: true` | 차단 없음, 경고만 | 경고 (FAIL 아님) |
| **불필요** | 출력 없음 | 필드 생략 | 통과 | 통과 |

> **핵심**: "필요"만 강제, "권장"은 인지만. **자동 발동 금지** = 사용자 통제권 유지.

### 6.6.2 WT-7 — worktree 발동 5단 게이트 체인 (Phase 7-1 신규)

> **원본 정본**: [docs/poc/worktree-gate-design/01-design-decisions.md §2](../../poc/worktree-gate-design/01-design-decisions.md) (rev.2 APPROVED)
> **Cross-reference**: `/worktree` skill / WT-6 (§6.6.1) / §3 BUILDING G-C 차단 블록 / 6-rules-index.md §1.21

| 항목 | 내용 |
|------|------|
| **ID** | WT-7 |
| **심각도** | HIGH |
| **요약** | G-A → G-B → G-C → G-D → G-E **5단 안전망**. 앞 게이트 누락 시 다음 게이트가 적발. 단일 게이트 누락 안전망 보장. |

#### 게이트 체인 다이어그램

각 게이트는 **앞 게이트가 누락됐을 때 잡는 안전망** 역할. 단일 게이트는 깨지기 쉬워 최소 2개는 박아야 인지 보장.

```
G-A (예측)  → "필요할 것 같다" 한 줄 안내      [발견]
   ↓ 누락 시
G-B (선언) → status.md에 명시적 필드 박기     [기록]
   ↓ 누락 시
G-C (강제) → BUILDING 진입 차단                [강제]
   ↓ 누락 시
G-D (적발) → G2 FAIL (verifier 독립 검증)     [감사]

G-E (사후) → VERIFYING 후 차기 Phase 권고      [인계]
```

#### 게이트별 상세

| 게이트 | 시점 | 주체 | 입력 | 출력 | 강제력 |
|-------|------|------|------|------|--------|
| **G-A** | `/plan` 작성 시 | Team Lead | S1+S5+S6 | "worktree 필요/권장" 한 줄 안내 | 안내 |
| **G-B** | `/phase-init` 산출물 생성 시 | phase-init skill | G-A 출력 + Task 명세 | status.md YAML `worktree_required/recommended` 자동 삽입 | 안내 |
| **G-C** | `BRANCH_CREATION → WORKTREE_SETUP` 전이 | Team Lead | status.md `worktree_required: true` | true 인데 `worktree_paths: []` 이면 BUILDING **차단** | **차단** |
| **G-D** | verifier G2 시 | verifier | `git worktree list` + status.md | 트랙 ≥ 2 + worktree 없음 → **G2 FAIL** | **FAIL** |
| **G-E** | VERIFYING 종료 직후 | verifier + Team Lead | G2/G3 결과 + 임계값 (FAIL 30%/High 5건) | `next_phase_recommendations` YAML + final-summary §섹션 | 안내 (차기 Phase 인계) |

#### G-E 사후 권고 절차 (D/E 케이스 전용)

D/E 케이스(기능 개발 실패, 1차 품질 낮음)는 사전 휴리스틱으로 잡히지 않으며, **사람의 주관 평가**가 필요한 영역. AI는 권고만 작성하고 차기 Phase로 인계한다.

```
1. verifier G2/G3 보고서 완료
2. Team Lead 자동 신호 출력 (임계값 기반):
   - 테스트 FAIL 비율 ≥ 30% → "compare 권장"
   - 룰 위반 High 이상 ≥ 5건 → "compare 권장"
3. 권고 코멘트 생성 → status.md YAML + final-summary-report.md 양쪽 기록
4. 현 Phase DONE 전이 (현 Phase는 깨지지 않음)
   ───────────────────────────────────────────────
5. 차기 Phase /plan 시작 시 자동 픽업 → 사용자 표시
6. 사용자 결정 (5종 트리거 어휘):
   - "권고안 진행"   → suggested_options 그대로 compare 발동
   - "쉽게 진행"     → 권고 무시, 일반 흐름
   - "옵션 X로"      → 권고 옵션 중 1개만 채택 (단일 worktree)
   - "compare 진행"  → 명시적 compare 호출
   - 무응답          → 묵시적 거절 (일반 흐름)
7. status.md에 결정 기록 (decision_at, decision_by, reason)
```

> **5종 트리거 어휘 사전 (M12)**: 자연어 변형 매핑은 Phase 7-4 (`skills/worktree/REFERENCE.md §1.4`) 에서 확정.

---

## 7. 참조 문서 (5th 세트)

| 주제 | 링크 |
|------|------|
| **진입점·팀 라이프사이클** | [0-entrypoint.md](0-entrypoint.md) §3.9 |
| **프로젝트·역할** | [1-project.md](1-project.md), [ROLES/](ROLES/) |
| **아키텍처** | [2-architecture.md](2-architecture.md) |
| **역할별 가이드** | [SUB-SSOT/](SUB-SSOT/) (정본, v1.1+) — 레거시 GUIDES 원본은 번들 미포함 |
| **이벤트 프로토콜** | [4-event-protocol.md](4-event-protocol.md) ← **5th 신규** |
| **자동화 파이프라인** | [5-automation.md](5-automation.md) ← **5th 신규** |
| **11명 Verification Council** | [QUALITY/10-persona-qc.md](QUALITY/10-persona-qc.md) ← **5th 신규** |

---

## 8. Phase Chain (자동 순차 실행)

### 8.1 개요

Phase Chain은 복수의 Phase를 사전 정의된 순서로 자동 순차 실행하는 프로토콜이다.  
각 Phase DONE 후 `/clear`로 컨텍스트를 초기화하고, 다음 Phase를 자동 시작한다.

### 8.2 Phase Chain 정의 파일

```yaml
# docs/phases/phase-chain-{name}.md
---
chain_name: "phase-15-fullstack"
phases: ["15-4", "15-5", "15-6", "15-7", "15-8"]
current_index: 0          # 현재 실행 중인 Phase 인덱스
status: "running"         # pending | running | completed | aborted
ssot_version: "7.0-renewal-5th"
created_at: "2026-02-28T..."
# ── 5th 확장 필드 (선택) ──
5th_mode:                  # Chain 전체에 적용할 5th_mode 기본값
  research: false
  event: false
  automation: false
  branch: false
  multi_perspective: false
---
```

### 8.3 Phase Chain 실행 프로토콜

```
[1] Chain 파일 생성 (phase-chain-{name}.md)
[2] Phase[current_index] Cold Start: SSOT 리로드 → TeamCreate + 팀원 스폰 → PLANNING → … → DONE
[3] Phase DONE → TEAM_SHUTDOWN + TeamDelete → Chain 파일 current_index += 1 → 완료 리포트 출력
[4] 리팩토링 레지스트리 갱신 ← REFACTOR-1 (500줄 초과 파일 스캔 → 등록만, 계획 삽입 아님)
[5] /clear 실행 (토큰 최적화, Chain 파일은 디스크에 유지)
[6] current_index < len(phases)? → 다음 Phase Cold Start(Step 2), else Chain 완료
```

### 8.4 `/clear` 후 컨텍스트 복구

1. Chain 파일 읽기
2. current_index 확인
3. current_index < len(phases)? → 해당 Phase의 status.md 확인 → DONE 아니면 Warm Start, DONE이면 current_index += 1 후 다음 Phase
4. SSOT 리로드(FRESH-1) 후 Phase Cold Start

### 8.5 Chain 중단·재개

| 상황 | 처리 |
|------|------|
| Phase 실패 (retry ≥ 3) | Chain 일시정지, 사용자 판단 대기 |
| 사용자 중단 요청 | **`/abort` 스킬이 표준 진입점** — 팀 shutdown + status.md BLOCKED 기록 + chain status = "aborted" + 재개 정보 보존을 일괄 수행 |
| 세션 끊김 | Chain 파일로 재개 (8.4 절차) |

### 8.6 Phase Chain 규칙

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **CHAIN-1** | Phase 독립성 | 각 Phase는 Chain 없이도 단독 실행 가능해야 함 |
| **CHAIN-2** | `/clear` 필수 | Phase 간 전환 시 `/clear`로 토큰 초기화 |
| **CHAIN-3** | Chain 파일 유지 | `/clear` 후에도 Chain 파일은 디스크에 영속 |
| **CHAIN-4** | 순차 보장 | phases 배열 순서대로만 실행 (건너뛰기 금지) |
| **CHAIN-5** | 완료 리포트 | 각 Phase DONE 시 1줄 요약을 Chain 파일에 기록 |
| **CHAIN-6** | 산출물 의무 | plan.md, todo-list.md, tasks/task-X-Y-N.md, status.md(YAML) 최소 필수 |
| **CHAIN-7** | Gate 의무 | G0~G4 생략 불가 (G0은 `5th_mode.research = true` 시 필수. 단독 실행 시 G2·G3는 자체 검증으로 대체 가능, status에 기록) |
| **CHAIN-8** | Status 형식 | status.md는 YAML frontmatter 형식(§2.2 스키마) 준수 |
| **CHAIN-9** | Task 문서 형식 | task-X-Y-N.md: 메타 필드 4종(우선순위/의존성/담당 팀원/상태) + §1~§4 섹션 번호 |
| **CHAIN-10** | 파일 경로 규칙 | 아래 §8.7 디렉토리 구조 준수 필수. 기존 파일 패턴을 반드시 확인 후 생성 |
| **CHAIN-11** | Master Plan 완료 보고서 | Master Plan 전체 Sub-Phase 완료 시 `phase-{N}-final-summary-report.md`를 `docs/phases/` 루트에 작성 필수 |

### 8.7 Phase 문서 디렉토리 구조

```
docs/phases/
├── phase-chain-{name}.md                ← Chain 정의 (phases 루트)
├── phase-{N}-master-plan.md             ← 마스터 플랜 (phases 루트, 하위 폴더 아님)
├── phase-{N}-final-summary-report.md    ← 완료 보고서 (phases 루트, CHAIN-11)
├── pre/                                 ← Master Plan 이전 산출물 (평탄 구조)
│    ├── phase-{N}-pre-analysis.md       ← ANALYSIS-1 사전 분석
│    └── phase-{N}-pre-draft.md          ← Step 0 Pre-draft (사용자 주도 한정)
├── phase-{N}-{M}/                       ← 개별 Phase 산출물 폴더
│    ├── phase-{N}-{M}-status.md         ← YAML 상태 파일 (ENTRY-1 진입점)
│    ├── phase-{N}-{M}-plan.md           ← Phase 계획서
│    ├── phase-{N}-{M}-todo-list.md      ← Todo 체크리스트
│    └── tasks/                          ← Task 명세 폴더
│         └── task-{N}-{M}-{T}.md        ← 개별 Task 명세
```

**핵심 규칙**:
- `master-plan.md`·`phase-chain-*.md`·`final-summary-report.md`는 **`docs/phases/` 루트**에 위치 (하위 폴더 생성 금지)
- `status.md`·`plan.md`·`todo-list.md`·`tasks/`는 **`phase-{N}-{M}/` 폴더** 안에 위치
- `pre-analysis.md`·`pre-draft.md`는 **`docs/phases/pre/` 평탄 폴더**에 `phase-{N}-pre-xxx.md` 형식으로 위치 (2026-04-16 Phase-I I-1 신설)
- **pre-draft**는 사용자 주도 마스터 플랜(`initiator: user`) 진입 시에만 생성. AI handoff 시 자동 생략
- 새 파일 생성 전 **기존 파일 패턴을 `Glob`으로 확인** 후 동일 경로 레벨에 생성

### 8.8 Phase Chain + 5th_mode 연동 (5th 확장)

Phase Chain 실행 시 `5th_mode` 설정을 Chain 레벨 또는 Phase 레벨에서 제어할 수 있다.

| 설정 레벨 | 적용 범위 | 설명 |
|----------|----------|------|
| **Chain 레벨** | Chain 파일의 `5th_mode` | Chain 내 모든 Phase에 기본 적용 |
| **Phase 레벨** | 개별 Phase의 `status.md` `5th_mode` | 해당 Phase에만 적용 (Chain 기본값 오버라이드) |

**Phase Chain Cold Start 시 5th 확장 절차**:
```
[2] Phase[current_index] Cold Start:
  │
  ▼
[2a] SSOT 리로드 (0→1→2→3)
  │
  ▼
[2b] Chain 파일 5th_mode 읽기 → Phase status.md에 5th_mode 기본값 설정
  │
  ▼
[2c] TeamCreate + 팀원 스폰
  │
  ▼
[2d] 5th_mode.research = true? → Research Team 스폰 → RESEARCH → G0
  │   아니면 → PLANNING 직행
  │
  ▼
[2e] 5th_mode.branch = true? → TASK_SPEC 후 BRANCH_CREATION
  │   아니면 → TASK_SPEC → BUILDING 직행
  │
  ▼
[2f] ... → DONE → Chain 다음 Phase
```

**이벤트 로그 연동**: `5th_mode.event = true` 시 Phase Chain 진행 이벤트(`chain_phase_start`, `chain_phase_done`)를 `/tmp/agent-events/chain-{name}.jsonl`에 기록.

---

## 9. 컨텍스트 복구 프로토콜

### 9.1 개요

컨텍스트 압축, 세션 중단, 토큰 초과 등으로 작업이 중단된 후 복구하는 경우의 **필수 절차**를 정의한다.
이 프로토콜을 건너뛰고 "이전 요약을 바탕으로 바로 작업 재개"하는 것은 **금지**한다.

### 9.2 복구 절차

```
컨텍스트 복구 시점 (압축 발생 / 세션 재개 / /clear 후)
  │
  ▼
[1] SSOT 리로드 ← FRESH-1 (0-entrypoint.md 읽기)
  │
  ▼
[2] Phase Chain 파일 확인 (phase-chain-{name}.md)
  │   → current_index, status 확인
  │
  ▼
[3] 현재 Phase status.md 읽기 ← ENTRY-1
  │   → current_state, task_progress, team_name, 5th_mode 확인
  │
  ▼
[3.5] (5th) 5th_mode 확인 → 활성화된 축에 따라 복구 분기 결정
  │   ├── 5th_mode.research = true + current_state = RESEARCH → Research Team 재스폰
  │   ├── 5th_mode.branch = true → Git branch/tag 상태 확인
  │   └── 5th_mode.event = true → 이벤트 로그에서 마지막 상태 교차 검증
  │
  ▼
[4] 팀 상태 확인
  │   ├── team_name 존재 → 팀 config 읽기, idle 팀원 확인
  │   └── team_name null → 새 팀 생성 필수 (HR-1: 팀 없이 코드 수정 금지)
  │
  ▼
[5] 미완료 Task 식별
  │   → task_progress에서 status != "DONE" 항목 확인
  │   → 해당 Task의 task-X-Y-N.md 읽기
  │
  ▼
[6] 업무 재분배
  │   ├── 기존 팀원 idle 상태 → SendMessage로 작업 재개 지시
  │   ├── 기존 팀원 없음 → 새 팀원 스폰 + Task 할당
  │   └── Task 미할당 → TaskUpdate(owner) 설정
  │
  ▼
[7] 작업 재개 (current_state 기반)
```

### 9.3 복구 시 금지 사항

| 금지 항목 | 이유 |
|----------|------|
| SSOT 리로드 없이 작업 재개 | 규칙 변경·버전 불일치 감지 불가 |
| 팀 없이 Team Lead가 직접 코드 수정 | HR-1 위반. "빠르게 마무리"는 정당한 사유가 아님 |
| 산출물(tasks/, todo-list) 생략 | HR-2 위반. 중단 복구 시에도 산출물 의무 동일 |
| 이전 세션 요약만 보고 상태 추정 | status.md가 단일 진입점 (ENTRY-1). 요약은 참고일 뿐 |

### 9.4 복구 판정 기준

| 상황 | 처리 |
|------|------|
| current_state = DONE | 다음 Phase 진행 (Chain이면 current_index 확인) |
| current_state = BUILDING, task 일부 DONE | 미완료 Task만 재할당 |
| current_state = PLANNING/PLAN_REVIEW | planner 재스폰 후 계획 재수립 |
| team_name 존재하나 팀원 응답 없음 | TeamDelete → 새 팀 생성 |
| tasks/ 문서 미생성 상태 | 산출물 먼저 생성 후 BUILDING 진입 |
| current_state = RESEARCH *(5th)* | Research Team 재스폰, 진행 중이던 조사 재개 (research_status 확인) |
| current_state = AUTO_FIX *(5th)* | auto_fix_count 확인 → 3회 미만이면 AUTO_FIX 재진입, 3회 이상이면 에스컬레이션 |
| current_state = BRANCH_CREATION *(5th)* | Git branch 존재 여부 확인 → 있으면 BUILDING 진입, 없으면 BRANCH_CREATION 재실행 |

### 9.5 실행 단위 컨텍스트 (권장 로딩 집합)

**목적**: 역할별로 "작업 1회"(계획 1회, Task 1건, 검증 1회 등) 실행 시 **권장 로딩 집합**을 정의하여 토큰 예측·품질 일관성·재현성을 높인다.  
**성격**: 권장(필수 아님). 도구가 강제 로딩하지 않더라도 팀원 스폰 시 프롬프트 또는 Task 지시에 포함할 수 있다.

| 역할 | 실행 단위 | 권장 로딩 집합 (순서) | 비고 |
|------|-----------|------------------------|------|
| **planner** | 계획 분석 1회 | ① phase-X-Y-status.md (ssot_version, current_state, blockers) ② master-plan·navigation(Team Lead 전달분) ③ [ROLES/planner.md](ROLES/planner.md) §2 SSOT·리스크 ④ [SUB-SSOT/PLANNER/1-planning-procedure.md](SUB-SSOT/PLANNER/1-planning-procedure.md) | 입력 고정적 → 실행 단위 로딩 효과 큼 |
| **backend-dev** | Task 1건 구현 | ① task-X-Y-N.md (해당 Task) ② [2-architecture.md](2-architecture.md) § 백엔드 ③ (선택) phase-X-Y-status.md | Task별 범위 상이 → 최소 집합만 고정 |
| **frontend-dev** | Task 1건 구현 | ① task-X-Y-N.md (해당 Task) ② [2-architecture.md](2-architecture.md) § 프론트엔드 ③ (선택) phase-X-Y-status.md | 동일 |
| **verifier** | 검증 1회 | ① 변경된 파일 목록(Team Lead 전달) 및 해당 파일 내용 ② 해당 task-X-Y-N.md (완료 기준) ③ [ROLES/verifier.md](ROLES/verifier.md) §3 검증 기준 | 판정 일관성·감사 추적에 유리 |
| **tester** | 테스트 1회 | ① (선택) 해당 task-X-Y-N.md·phase-X-Y-status.md ② [ROLES/tester.md](ROLES/tester.md) 테스트 명령 | CLI 위주라 문서 로딩은 보조 |

**적용**: Team Lead가 SendMessage로 Task/검증 요청 시 위 권장 로딩 집합을 안내하거나, 팀원이 작업 시작 전 스스로 해당 문서를 읽어 컨텍스트에 포함할 수 있다.

---

## 10. 코드 유지관리 (리팩토링)

**상세 규정**: [docs/SSOT/refactoring/refactoring-rules.md](refactoring/refactoring-rules.md)
**레지스트리**: [docs/SSOT/refactoring/refactoring-registry.md](refactoring/refactoring-registry.md)

### 10.1 개요

단일 파일의 코드 줄 수가 과도하게 증가하면 가독성·유지보수성이 저하된다.
아래 규칙을 **초기 개발·Phase 진행·유지보수** 모든 단계에서 적용한다.

### 10.2 임계값

| 기준 | 줄 수 | 의미 |
|------|------:|------|
| 관심선 | **500줄** | 레지스트리 등록, 모니터링 |
| 경고선 | **700줄** | Level 분류 + 리팩토링 검토 |
| 위험선 | **1000줄** | 즉시 리팩토링 (다음 Master Plan 최우선) |

### 10.3 Level 분류

| Level | 조건 | 판별 기준 | 편성 |
|:-----:|------|----------|------|
| **Lv1** | 700줄 초과, 독립 분리 가능 | 연관 파일 중 500줄 초과 0개 또는 단방향만 | 다음 Master Plan 내 선행 sub-phase |
| **Lv2** | 700줄 초과, 연관 파일과 양방향 밀접 | 연관 파일 중 500줄 초과 1개+ 양방향 참조 | `phase-X-refactoring` 별도 Phase |

### 10.4 실행 규칙 (REFACTOR-1~3)

| 규칙 | 시점 | 조치 |
|------|------|------|
| **REFACTOR-1** | Phase X-Y 완료(DONE) | 코드 스캔 → 500줄 초과 파일 레지스트리 **등록만** (§8.3 Step [4]) |
| **REFACTOR-2** | Master Plan 작성 | 레지스트리 읽기 → 700줄 초과 시 Level별 리팩토링 편성 |
| **REFACTOR-3** | PLANNING/BUILDING/G2 | 신규 코드 500줄 초과 **사전 방지** |

### 10.5 phase-X-refactoring 운영 (Lv2)

| 항목 | 규칙 |
|------|------|
| 명칭 | `phase-X-refactoring` (예: phase-19-refactoring) |
| git branch | main에서 분기, sub-phase 단위로 main merge |
| 팀 구성 | 기능 개발 팀과 **별도 팀** |
| 동시 수정 금지 | 리팩토링 대상 파일을 기능 branch에서 수정 금지 |
| 우선순위 | 대상 파일을 기능 Phase에서 수정 필요 → **리팩토링 먼저**. 무관 → 기능 먼저 가능 |
| 선행 절차 | 영향도 조사 → 아키텍처 검토 → Plan → 사용자 승인 → 실행 |

### 10.6 [예외] 확정 — 3요건 필수

| # | 요건 |
|---|------|
| 1 | 영향도 조사 **실시** |
| 2 | 분리 시도 또는 검토에서 **순환 의존/응집도 파괴 입증** |
| 3 | 사용자 **승인** |

### 10.7 점검 프로토콜 — 2단계

**단계 1**: Phase X-Y 완료 → 코드 스캔 → 레지스트리 등록·갱신만 (계획 삽입 안 함)
**단계 2**: Master Plan 작성 → 레지스트리 읽기 → Lv1은 선행 sub-phase, Lv2는 별도 phase-X-refactoring 편성

---

## 11. Master Plan 작성 시 필수 체크리스트 (CRITICAL)

새 Master Plan을 작성할 때 **아래 항목을 모두 수행해야 한다**. 누락 시 CRITICAL 규칙 위반이다.

### 11.1 사전 점검 (Master Plan 작성 전)

| # | 점검 항목 | 근거 규칙 | 조치 |
|---|----------|----------|------|
| 1 | 리팩토링 레지스트리 로드 | **REFACTOR-2** | `docs/SSOT/refactoring/refactoring-registry.md` Read → 700줄 초과 파일 Level 분류 |
| 2 | 이전 Phase 이관 항목 확인 | **CHAIN-5** | 이전 final-summary-report.md의 이관 항목 반영 여부 확인 |
| 3 | 기존 파일 패턴 Glob | **CHAIN-10 / HR-4** | `docs/phases/phase-*-master-plan.md` Glob → 동일 경로에 생성 |
| 4 | 사전 분석 결과 파일 저장 | **ANALYSIS-1** | 보류 항목·비교 검토·요구사항 분석 등을 `docs/phases/pre/phase-{N}-pre-analysis.md`에 저장. 텍스트 출력만으로 완료 처리 금지 |

### 11.2 Master Plan 본문 필수 포함 항목

| # | 포함 항목 | 근거 규칙 |
|---|----------|----------|
| 1 | HR-5 리팩토링 점검 결과 섹션 | **REFACTOR-2** — 700줄 초과 시 Lv1/Lv2 편성, 없으면 "해당 없음" 명시 |
| 2 | 모든 Sub-Phase에 게이트 명시 (G0~G4) | **CHAIN-7** — G0은 5th_mode.research=true 시 |
| 3 | Task 도메인 태그 + 담당 역할 | **ASSIGN-1** — `[BE]`→backend-dev, `[FE]`→frontend-dev, `[TEST]`→tester |
| 4 | 완료 보고서 작성 계획 | **CHAIN-11** — `phase-{N}-final-summary-report.md` |

### 11.3 사후 검증

- Master Plan 초안 작성 후 **CLAUDE.md의 "Master Plan 작성 시 필수 점검" 체크리스트와 대조**
- 누락 항목 발견 시 Master Plan에 보완 후 진행

---

## 12. 사전 분석 규칙 (Pre-Analysis)

### 12.1 개요

Master Plan 작성 **이전** 단계에서 수행하는 분석(보류 항목 정리, 기술 비교 검토, 요구사항 수집, 현황 진단 등)의 결과는 **반드시 파일로 저장**해야 한다. 텍스트 출력(thinking pad, 대화 응답 등)만으로 분석 완료를 선언하는 것은 금지한다.

### 12.2 규칙

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **ANALYSIS-1** | 사전 분석 결과 파일 저장 필수 | 보류 항목·비교 검토·요구사항 분석 등 Master Plan 이전 분석 결과를 `docs/phases/pre/phase-{N}-pre-analysis.md`에 저장한다. 텍스트 출력만으로 완료 처리 금지 |
| **ANALYSIS-2** | 분석 파일 경로 규칙 | `docs/phases/pre/` 폴더에 `phase-{N}-pre-analysis.md` 형식으로 생성 (HR-4 / CHAIN-10 준수, 2026-04-16 Phase-I I-1로 루트 → pre/ 이동) |
| **ANALYSIS-3** | 분석 파일 필수 섹션 | 아래 §12.3 템플릿의 필수 섹션을 포함해야 한다 |

### 12.3 pre-analysis.md 필수 섹션

```markdown
# Phase {N} 사전 분석

## 1. 분석 배경
- 이전 Phase 이관 항목
- 사용자 요구사항

## 2. 현황 진단
- 현재 코드/기능 상태
- 기술 부채·보류 항목 목록

## 3. 비교 검토 (해당 시)
- Plan A vs B 비교표
- 각 안의 장단점·리스크

## 4. 결론 및 추천안
- 선택한 방향과 근거
- Master Plan 반영 사항
```

### 12.4 상태 머신 연동

사전 분석은 **IDLE → TEAM_SETUP** 전이 이전, 즉 Phase 시작 명령 수신 후 Master Plan 작성 전에 수행한다.

```
Phase 시작 요청 (사용자 명령)
  │
  ▼
[PRE-ANALYSIS]  ← ANALYSIS-1: 분석 결과를 docs/phases/pre/phase-{N}-pre-analysis.md에 저장
  │
  ▼
[Master Plan 작성]  ← §11 체크리스트 (pre-analysis.md 참조하여 작성)
  │
  ▼
IDLE → TEAM_SETUP → ...  (기존 상태 머신 진입)
```

**주의**: PRE-ANALYSIS는 상태 머신의 정식 상태가 아닌 **사전 절차**이다. status.md에 기록하지 않으며, Master Plan 작성의 선행 조건으로만 기능한다.

### 12.5 품질 게이트 연동

| 게이트 | ANALYSIS 관련 점검 |
|--------|-------------------|
| **G1 (Plan Review)** | Master Plan이 pre-analysis.md의 결론/추천안을 반영했는지 확인 |
| **G4 (Final Gate)** | pre-analysis.md에 명시된 보류 항목이 해결되었거나 다음 Phase로 이관 기록되었는지 확인 |

### 12.6 역할별 책임

| 역할 | 책임 |
|------|------|
| **Team Lead** | pre-analysis.md 작성 (또는 planner에 위임). 파일 존재 여부를 Master Plan 작성 전 확인 |
| **planner** | Team Lead 위임 시 분석 수행 → SendMessage로 결과 보고. Team Lead가 파일 생성 |
| **Research Team** | `5th_mode.research = true` 시, RESEARCH 상태에서 기술 조사 수행. 결과가 pre-analysis.md에 통합될 수 있음 |

### 12.7 발생 배경

Phase 42 시작 시 thinking pad 분석(Plan A vs B 비교, 보류 항목 정리 등)이 텍스트 출력만 되고 파일로 저장되지 않은 SSOT 갭을 사용자가 발견. 분석 결과의 영속성·추적성을 보장하기 위해 ANALYSIS-1 규칙을 신설함.

---

**문서 관리**:
- 버전: 8.2-renewal-6th (6th iteration)
- 최종 수정: 2026-03-14
- 단독 사용: 본 docs/SSOT 세트만으로 SSOT 완결
- 4th 콘텐츠 전량 보존
- 5th 확장: 20개 상태 머신(+6), G0 Research Review 게이트, AUTO_FIX 루프, AB_COMPARISON, DESIGN_REVIEW, BRANCH_CREATION, 5th_mode 연동, Phase Chain 5th_mode 연동, 컨텍스트 복구 5th 확장
- §12 사전 분석 규칙 추가 (ANALYSIS-1~3)
