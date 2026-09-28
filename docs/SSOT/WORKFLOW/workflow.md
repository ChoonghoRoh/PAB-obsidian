# SSOT — 워크플로우

---

## 1. 워크플로우 상태 머신

### 1.1 상태 정의

#### 기본 상태

| 상태 코드 | 상태명 | 설명 | 진입 조건 |
|----------|--------|------|----------|
| `IDLE` | 대기 | Phase 미시작 | 초기 상태 |
| `TEAM_SETUP` | 팀 구성 | 첫 팀원 스폰(자동 팀 생성) + 상태 파일 생성 | Phase 시작 명령 |
| `PLANNING` | 계획 | planner 팀원이 요구사항 분석, Task 분해 | 팀 구성 완료 |
| `PLAN_REVIEW` | 계획 검토 (G1) | Team Lead가 planner 결과 검증 | PLANNING 완료 |
| `TASK_SPEC` | Task 내역서 작성 | Task별 실행 계획 문서 생성 | PLAN_REVIEW 통과 (또는 DESIGN_REVIEW 통과) |
| `BUILDING` | 구현 | backend-dev/frontend-dev가 코드 작성 | TASK_SPEC 완료 (또는 WORKTREE_SETUP 완료) |
| `VERIFYING` | 검증 (G2) | verifier가 코드 리뷰 → Team Lead 보고 | BUILDING 완료 |
| `TESTING` | 테스트 (G3) | tester가 테스트 실행 → Team Lead 보고 | VERIFYING 통과 |
| `INTEGRATION` | 통합 테스트 | Phase 전체 통합 검증 (API↔UI 연동) | 모든 Task TESTING 통과 (또는 AB_COMPARISON 완료 · 병렬 BUILDING 재검증 PASS — §3.3) |
| `E2E` | E2E 테스트 | 사용자 시나리오 기반 전체 테스트 | INTEGRATION 통과 |
| `E2E_REPORT` | E2E 리포트 | Verification Report + E2E 리포트 작성 | E2E 통과 |
| `TEAM_SHUTDOWN` | 팀 해산 | 팀원 전원 shutdown_request → 팀 config에 team-lead만 남았는지 확인 → 센티넬 해제 확인 | E2E_REPORT 완료 |
| `BLOCKED` | 차단 | Blocker 이슈 발생 | 어떤 상태에서든 진입 가능 |
| `REWINDING` | 리와인드 | 이전 상태로 롤백 중 | FAIL 판정 시 |
| `DONE` | 완료 | Phase 종료 | TEAM_SHUTDOWN 완료 |

#### 조건부 상태

| 상태 코드 | 상태명 | 설명 | 진입 조건 | 필수/선택 |
|----------|--------|------|----------|:---------:|
| `BRANCH_CREATION` | 브랜치 생성 | 병렬 트랙용 Phase 브랜치 생성 | TASK_SPEC 완료 + 병렬 트랙 N ≥ 2 (WT-1) | N ≥ 2 시 필수 |
| `WORKTREE_SETUP` | worktree 구성 | 트랙별 worktree 생성·의존성 설치·status 기록 | BRANCH_CREATION 완료 | N ≥ 2 시 필수 |
| `AB_COMPARISON` | A/B 비교 | 복수 구현 방안 비교 검증 | TESTING 통과 + 복수 구현 존재 시 | 선택 |
| `DESIGN_REVIEW` | 설계 검토 | 아키텍처/설계 레벨 추가 검토 | PLAN_REVIEW 통과 + 복잡도 높은 Phase | 선택 |

**조건부 실행 규칙**: 조건부 상태는 진입 조건을 충족할 때만 실행한다. 충족하지 않으면 건너뛰고 기본 전이 경로를 따른다.

---

### 1.2 상태 전이 다이어그램

```
── 기본 경로 ──
IDLE → TEAM_SETUP → PLANNING → PLAN_REVIEW → TASK_SPEC
                         ↑          │ FAIL
                         └──────────┘ REWINDING

TASK_SPEC → BUILDING → VERIFYING → TESTING → (다음 Task 또는 INTEGRATION)
                ↑          │ FAIL      │ FAIL
                └──────────┴───────────┘ REWINDING

모든 Task 완료 → INTEGRATION → E2E → E2E_REPORT → TEAM_SHUTDOWN → DONE
                      │ FAIL     │ FAIL
                      └──────────┘ REWINDING → BUILDING

── 조건부 분기 ──
PLAN_REVIEW ─(복잡도 높음)→ DESIGN_REVIEW → TASK_SPEC

TASK_SPEC ─(병렬 N ≥ 2)→ BRANCH_CREATION → WORKTREE_SETUP → BUILDING

TESTING ─(복수 구현)→ AB_COMPARISON → INTEGRATION

VERIFYING ─(병렬 BUILDING 재검증 PASS)→ INTEGRATION

※ 어떤 상태에서든 BLOCKED로 전이 가능 (Blocker 이슈 발생 시)
```

### 1.3 조건부 상태 실행 규칙

| 상태 | 조건 | 미충족 시 경로 |
|------|------|---------------|
| `DESIGN_REVIEW` | Phase 복잡도 높음 (Team Lead 판단) | PLAN_REVIEW → TASK_SPEC |
| `BRANCH_CREATION` → `WORKTREE_SETUP` | 병렬 트랙 N ≥ 2 (WT-1) | TASK_SPEC → BUILDING |
| `AB_COMPARISON` | 복수 구현 방안 존재 (Team Lead 판단) | TESTING → INTEGRATION |

### 1.4 상태 전이 훅

`.claude/hooks/state-transition-guard.sh`는 Edit · Write 도구로 status.md를 고친 뒤(PostToolUse) `current_state`를 **마지막으로 커밋된 status.md**와 비교한다. Bash로 status.md를 쓰면 이 훅이 실행되지 않아 전이 검사를 건너뛴다 — `current_state`는 Edit · Write 도구로만 바꾼다.

- 위 전이표에 없는 전이는 **경고만 하고 막지 않는다**. 경고는 `additionalContext`로 모델에, `systemMessage`로 사용자에게 함께 전달된다.
- 커밋하지 않은 채 연달아 고치면 비교 기준이 옛 상태에 머문다 — 전이마다 status.md를 커밋한다.
- `retry_count`가 상한을 넘으면 거부를 알린다(§4 재시도).

---

## 2. 상태 파일 (Status File)

### 2.1 파일 경로

```
docs/phases/phase-X-Y/phase-X-Y-status.md
```

### 2.2 상태 파일 스키마 (핵심 필드)

`/phase-init`이 아래 앞부분 필드로 status.md를 만든다(`current_state`는 `PLANNING`으로 시작). 뒷부분 필드는 Team Lead가 필요할 때 추가한다.

```yaml
---
phase_id: "X-Y"
title: "..."
current_state: "PLANNING"
created_at: "2026-02-28"
updated_at: "2026-02-28"
ssot_version: "{SSOT 버전}"
retry_count: 0
gate_results: { G1: null, G2: null, G3: null, G4: null }
agents:
  - name: backend-dev
    spawned_at:     "2026-08-08T13:00:00+09:00"   # Team Lead 직접 기록 (팀원에게는 SubagentStart가 발화하지 않는다)
    last_report_at: "2026-08-08T13:04:12+09:00"
    next_check_at:  "2026-08-08T13:07:12+09:00"   # spawn+30초 1차 / 이후 3분 주기
    respawn_count: 0                               # LIFECYCLE-5 상한 5회
token_budget:
  policy: ""
  limit: 0
  estimate: 0
  declared: ""
  unit: "noncache"
  consumed: 0
  measure_from: null
# Team Lead가 추가하는 필드
ssot_loaded_at: "2026-02-28T10:00:00Z"
current_task: "X-Y-2"
current_task_domain: "[FE]"
team_name: "session-<세션 ID 앞 8자>"  # 세션마다 팀 하나(암묵적) — Team Lead가 기록만 한다, Agent 도구 team_name 인자는 CLI가 무시
team_members: []              # /abort가 활성 팀 확인에 읽는다
last_action: "..."
last_action_result: "PASS"   # PASS | FAIL | PARTIAL | N/A
next_action: "..."
blockers: []
rewind_target: null
task_progress: {}
error_log: []
plan_rev: "v1.0"             # CR을 승인하면 올린다
worktree_required: false
worktree_recommended: false
expected_tracks: []
worktree_paths: []
cleanup_wt: null
next_phase_recommendations: []
decision_at: null
---
```

**필드 설명**:
- `worktree_required` · `worktree_recommended` · `expected_tracks`: G-A 판정 결과(`worktree.md` §7). `expected_tracks`에 트랙이 2개 이상이면 G-A가 발동한다.
- `worktree_paths` · `cleanup_wt`: WT-5. BRANCH_CREATION에서 worktree 경로를 기록하고 `cleanup_wt`를 `pending`으로 바꾼다. 정리가 끝나면 `done`. worktree를 만들지 않는 Phase는 `null`로 둔다.
- `next_phase_recommendations` · `decision_at`: G-E 사후 권고와 사용자 결정 시각(`worktree.md` §7).
- `agents`: Team Lead가 기록하는 팀원 추적 필드. LIFECYCLE-6 워처는 이 필드를 읽지 않고 팀 설정(`~/.claude/teams/{team}/config.json`)과 inbox를 본다 — pane 없는 팀원(in-process 모드 등)은 세션 transcript의 마지막 기록을 본다(TD-109).
- `token_budget`: 착수 때 승인받은 예산과 계측값(OPS-3 · OPS-4). 7키의 뜻은 `CORE/shared-definitions.md` §8이 정본이다.
- 🔴 **인라인 주석 금지**: `retry_count`·`current_state` 행에는 `#` 인라인 주석을 달지 않는다 — 주석이 붙으면 LOCK-1 훅이 `current_state` 값을 잘못 읽어, `DONE`을 실행 중으로 보고 SSOT 수정을 막는다.

---

## 3. 워크플로우 실행

### 3.1 상태별 Action Table

#### 기본 상태 Action

| 현재 상태 | 다음 행동 | 담당 |
|----------|----------|------|
| **IDLE** | 첫 팀원 스폰(자동 팀 생성) + 상태 파일 생성 | Team Lead |
| **TEAM_SETUP** | 전달 게이트(HANDOFF) 통과 → planner 스폰 + "Phase X-Y 계획 분석 요청" | Team Lead |
| **PLANNING** | planner **SendMessage** 수신 대기 (파일 폴링 금지). 수신 후 Team Lead가 phase-X-Y/ 산출물(plan, todo-list, tasks/) 생성 → PLAN_REVIEW 전이 | Team Lead |
| **PLAN_REVIEW** | planner 결과 검토 → PASS: DESIGN_REVIEW(선택) 또는 TASK_SPEC, FAIL: REWINDING→PLANNING | Team Lead |
| **TASK_SPEC** | Task 내역서 일괄 생성 (task-X-Y-N.md × N) + **도메인-역할 검증(ASSIGN-1~5)** → 병렬 트랙 N ≥ 2? → BRANCH_CREATION, 아니면 BUILDING | Team Lead |
| **BUILDING** | **[LIFECYCLE-6]** 팀원 ≥1 인데 워처 미arm 이면 **진입 차단** → arm 후 진입. **[LIFECYCLE-6.1 SPAWN_GATE]** 스폰 → 임무 전달 → 준비 신호 60~90s 대기 → 판정 후 진입(게이트는 팀원을 스폰하는 모든 상태 진입에 두고, 상태 진입 밖 스폰(respawn · Task별 추가 · 겹침 판정자)에도 둔다 — 적용 범위는 모든 스폰, `ROLES/SUB-SSOT/TEAM-LEAD/lifecycle-procedure.md` §SPAWN_GATE). 무응답은 `SPAWN_UNCONFIRMED`(자동 respawn 금지, 시그널 #1·#2 객관 판정 전환). SendMessage → 팀원: "Task 구현 시작" (backend-dev/frontend-dev) | 팀원 |
| **VERIFYING** | SendMessage → verifier: "검증 요청" → PASS: TESTING, PARTIAL·FAIL: REWINDING → BUILDING (지적 범위 수정 후 재검증) | Team Lead + verifier |
| **TESTING** | SendMessage → tester: "테스트 실행" → PASS: AB_COMPARISON(선택) 또는 다음 Task 또는 INTEGRATION | Team Lead + tester |
| **INTEGRATION** | tester가 통합 테스트 실행 → PASS: E2E, FAIL: REWINDING | tester |
| **E2E** | tester가 E2E 실행 → PASS: E2E_REPORT, FAIL: REWINDING | tester |
| **E2E_REPORT** | Verification Report + E2E 리포트 작성 → TEAM_SHUTDOWN | Team Lead |
| **TEAM_SHUTDOWN** | SendMessage(shutdown_request) × N → 팀 config에 team-lead만 남았는지 확인 → 센티넬 해제 확인 → DONE | Team Lead |
| **BLOCKED** | Blocker 해결 → 이전 상태 복귀 | 해당 팀원 |
| **REWINDING** | rewind_target 상태로 전이 → 재시도 | Team Lead |
| **DONE** | Phase 완료 → **Telegram 알림 발송(NOTIFY-1)** → 다음 Phase 준비 또는 Phase Chain 진행 | Team Lead |

#### Telegram 완료 알림 규칙 (NOTIFY-1~3)

**절대 생략 금지**: Phase 또는 Sub-Phase가 DONE 상태에 도달할 때마다, Team Lead는 **반드시** Telegram 알림을 발송한다. 이 규칙은 어떤 상황에서도 예외 없이 적용된다.

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **NOTIFY-1** | Phase/Sub-Phase DONE 시 Telegram 알림 필수 | DONE 전이 즉시 `scripts/pmAuto/report_to_telegram.sh`를 실행하여 완료 내역을 사용자에게 알린다. **생략 시 DONE 전이 무효**. 단 `PROJECT.md` `notify_channel`이 `none`이면 알림을 보내지 않으며 이때 DONE 전이는 유효하다(`/notify-telegram` 스킬이 이 값을 확인한다) |
| **NOTIFY-2** | 알림 메시지 형식 | 메시지 `"✅ Phase {N}-{M} 완료: {1줄 요약}\n📊 결과: {핵심 수치}\n📁 보고서: {보고서 경로}"`. 스크립트가 첫 줄에 `[{project}]`(`PROJECT.md` `notify_project_label`)를 붙이고 다음 줄부터 메시지를 보낸다 |
| **NOTIFY-3** | Master Plan 완료 시 종합 알림 | 전체 Chain/Master Plan 완료 시 Sub-Phase별 요약을 포함한 종합 알림 발송 |

**실행 방법**:
```bash
# 사용법: scripts/pmAuto/report_to_telegram.sh "{프로젝트명}" "{메시지}"
# → 첫 줄 "[프로젝트명]", 다음 줄부터 메시지로 전송

# Phase DONE 시 (Team Lead가 실행)
scripts/pmAuto/report_to_telegram.sh "{project}" "✅ Phase X-Y 완료: {요약}
📊 결과: {핵심 수치}
📁 보고서: docs/phases/phase-X-Y/reports/"

# Master Plan 전체 완료 시
scripts/pmAuto/report_to_telegram.sh "{project}" "🎉 Phase {N} 전체 완료: {마스터 플랜 제목}
📋 Sub-Phases: {N}-1 ~ {N}-{M} 모두 DONE
📁 최종 보고서: docs/phases/phase-{N}-final-summary-report.md"
```

#### 조건부 상태 Action

| 현재 상태 | 다음 행동 | 담당 | 조건 |
|----------|----------|------|------|
| **DESIGN_REVIEW** | 아키텍처/설계 레벨 추가 검토 → PASS: TASK_SPEC, FAIL: REWINDING→PLANNING | Team Lead | Phase 복잡도 판단 |
| **BRANCH_CREATION** | Phase 브랜치 생성 → WORKTREE_SETUP(트랙별 worktree) → BUILDING | Team Lead | 병렬 트랙 N ≥ 2 |
| **AB_COMPARISON** | 복수 구현 방안 비교 → 최적안 선택 → INTEGRATION | Team Lead | 복수 구현 존재 시 |

### 3.2 상태별 상세 플로우

#### IDLE → TEAM_SETUP
```
1. Team Lead: SSOT 리로드 (entrypoint → workflow) ← FRESH-1
2. Team Lead: 팀 준비 확인 — 팀은 도구로 만들지 않고, 첫 팀원을 스폰할 때(4단계) 한 번 자동 생성되며 `/clear`·새 세션 뒤에도 이어진다
3. /phase-init X-Y — 상태 파일·산출물 생성 (current_state = "PLANNING"으로 만든다)
4. 전달 게이트 통과 → `Agent` 도구로 planner 스폰 (base 세트 로딩 ← FRESH-6) + "Phase X-Y 계획 분석 요청" ← HANDOFF-1
```

#### PLANNING → PLAN_REVIEW (planner 결과 수신 및 산출물 생성)

**씽크 불일치 방지**: planner는 **쓰기 권한이 없어** 산출물 파일을 생성하지 않는다. 결과는 REPORT-1 결과 파일에 기록하고 **SendMessage로 요지 · 경로**를 Team Lead에게 전달한다. 따라서 "planner 결과 대기"는 **디렉터리 파일 폴링(sleep + ls)**이 아니라 **planner로부터 SendMessage 수신 대기**이다.

```
1. Team Lead: planner SendMessage(요지 · 결과 파일 경로) 수신 → 결과 파일을 읽는다
2. Team Lead: 읽은 결과로 phase-X-Y/ 에 산출물 생성
   - phase-X-Y-plan.md (계획서)
   - phase-X-Y-todo-list.md (체크리스트)
   - tasks/task-X-Y-N.md (Task 명세, N = 1..)
3. current_state = "PLAN_REVIEW"
4. Team Lead: G1 검토 후 PASS → TASK_SPEC, FAIL → REWINDING → PLANNING
```

**금지**: phase-X-Y/ 디렉터리를 `sleep` + `ls`로 폴링하여 "산출물 생성 여부"를 확인하지 않는다. planner는 해당 경로에 파일을 쓰지 않는다.

#### BUILDING → VERIFYING → TESTING
```
[BUILDING] SendMessage → designer([DS]) · backend-dev · frontend-dev: Task 수행 → 보고
[VERIFYING] SendMessage → verifier: 검증 요청 → G2 결과 보고
[TESTING]  SendMessage → tester: 테스트 실행 → G3 결과 보고
FAIL 시 REWINDING → BUILDING, PASS 시 다음 Task 또는 INTEGRATION
```

**Task 완료 검사 훅** (`.claude/hooks/on-task-completed.sh`, TaskCompleted): 커밋되지 않은 변경 파일을 검사해, html·js에 외부 CDN 참조가 있거나 html·js·css가 `line_crit`(`PROJECT.md`)을 넘으면 Task 완료를 막는다. `line_warn`을 넘으면 경고만 한다.

**병렬 BUILDING 진입 시 CWD 주입 규칙 (WT-3 연계)**:

- Team Lead 는 팀원 스폰 SendMessage 본문 상단에 `[CWD] ../{project}-wt-phase-{X}-{Y}-{track}` 행을 **필수** 로 포함한다.
- 메인 저장소 경로에서의 편집·빌드는 **WT-3 위반** 으로 기록되며, 위반 시 Team Lead 가 즉시 재할당한다.

각 단계 진입은 전달 게이트(HANDOFF)를 통과한 뒤 지시한다. 보고 규칙은 REPORT-1~6이다.

#### PLAN_REVIEW → DESIGN_REVIEW (선택적)

> Phase 복잡도가 높다고 Team Lead가 판단한 경우에만 진입.

```
1. PLAN_REVIEW G1 PASS 후 Team Lead가 복잡도 평가
2. 복잡도 높음 → current_state = "DESIGN_REVIEW"
3. planner: 아키텍처 · 설계 레벨 검토 의견을 결과 파일로 낸다 → Team Lead: 설계 검토 · 판정
4. PASS → TASK_SPEC, FAIL → REWINDING → PLANNING
```

#### TASK_SPEC — 도메인-역할 할당 규칙 (ASSIGN)

> **이유**: 구현자가 자기 코드를 검증하는 **셀프 체크**는 G3 독립성을 훼손한다.

> **⚠️ 절대 원칙(판정 목적 한정)**: 판정(G2 · G3) 근거로 쓰는 테스트·코드 검증·A/B 평가 등 **검증 성격의 모든 작업**은 backend-dev/frontend-dev가 **절대 수행하지 않는다**. 완료 판단용으로 스스로 실행하는 테스트는 예외이며 게이트 증거로 쓰지 않는다. 판정 목적 작업은 **반드시 tester·verifier·QC에게만** 위임하며, Team Lead가 이를 **강력하게 통제·제어**한다.

| ID | 규칙 | 설명 | 심각도 |
|----|------|------|--------|
| **ASSIGN-1** | 도메인-역할 매핑 필수 | Task의 구현 팀원은 `entrypoint.md` §3.8 도메인 태그 표가 정한다. 표와 다르게 할당하지 않는다 | CRITICAL |
| **ASSIGN-2** | [TEST] Task는 tester 전용 | `[TEST]` 도메인 Task를 backend-dev/frontend-dev에 할당 **절대 금지**. 구현자 셀프 체크 방지 | CRITICAL |
| **ASSIGN-3** | 할당 전 검증 | Task assignee 지정 시 **도메인 태그 ↔ 역할 일치**를 Team Lead가 반드시 검증. 불일치 시 할당 불가 | CRITICAL |
| **ASSIGN-4** | 스크립트 실행·분석 Task | 코드 작성이 아닌 **스크립트 실행+분석** Task는 tester 또는 verifier에 할당. backend-dev는 **코드 작성만** 담당 | CRITICAL |
| **ASSIGN-5** | Team Lead 통제 의무 | Team Lead는 **모든 검증·테스트·QC 작업이 구현자(BE/FE)에게 할당되지 않았는지** 능동적으로 감시. 팀원 스폰 시점·Task 할당 시점·작업 진행 중 3단계 검증 필수 | CRITICAL |
| **ASSIGN-6** | 편집자 · 판정자 · 이관 결정자 겸직 견제 | ① 편집자 · 실행자인 Task에서 G2 · G3의 High 이상을 낮추거나 tech-debt로 넘길 때는 결정자 · 근거 · 사용자 확인을 status 로그에 적는다 ② 판정자는 판정 입력(tester · verifier 보고서)을 고치지 않는다 — 작성자에게 정정을 요청하고, 불가피하면 원문을 두고 정정 목록을 따로 남긴다 ③ Team Lead는 [TEST] 실행 결과를 스스로 만들어 판정 근거로 쓰지 않는다 — 불가피하면(도구 · 권한 제약) 사유를 status에 적고 판정은 tester가 한다 ④ Team Lead가 `LEAD_SELECTED`로 고른 컴포넌트의 G2_DS 판정은 verifier가 한다(entrypoint §3.8) | HIGH |

**역할 책임 경계** (위반 시 즉시 시정):

| 역할 | 수행 가능 | 수행 절대 금지 |
|------|----------|--------------|
| backend-dev | 코드 작성, 리팩토링, 문서 작성, 성능 측정(구현 전 대안 비교만 — WT-8) | 판정용 테스트 실행, 코드 검증, A/B 평가, QC, 판정용 성능 수치 · 기준선 측정 |
| frontend-dev | UI 코드 작성, 스타일링 | 판정용 테스트 실행, 코드 검증, A/B 평가, QC |
| designer | 화면 시안(HTML+CSS), UI 설계 명세, 디자인 트렌드 조사, 현행 디자인 검수 | 제품 코드 작성·수정, 테스트 실행 |
| tester | 테스트 코드 작성 · 실행, 회귀 검증, A/B 평가, 스크립트 실행, 성능 수치 · 기준선 측정 | 프로덕션 코드 수정 |
| verifier | 코드 검증, 품질 분석, 탐색 | 프로덕션 코드 수정 |

**검증 절차** (TASK_SPEC 상태에서 Team Lead 필수 수행):
```
1. 각 Task의 도메인 태그 확인: [BE], [FE], [DS], [TEST], [DOC], [FS], [DB], [INFRA]
2. ASSIGN-1 — `entrypoint.md` §3.8 도메인 태그 표 대조 → assignee 결정
3. [TEST] 태그 Task → 반드시 tester 할당 (ASSIGN-2)
4. 스크립트 실행/A/B 평가 등 → tester 또는 verifier 할당 (ASSIGN-4)
5. 검증·테스트·QC 성격 Task가 BE/FE에 할당되었는지 최종 점검 (ASSIGN-5)
6. 불일치 발견 시 → 할당 수정 후 진행
```

**Team Lead 3단계 통제** (ASSIGN-5):
```
① 스폰 시점: 팀원 역할(tester/verifier)과 할당 Task 성격 일치 확인
② 할당 시점: task 파일에 owner를 적기 전 도메인-역할 교차 검증
③ 진행 중:   팀원 보고 시 "구현자가 검증 수행" 징후 감지 → 즉시 중단·재할당
```

**위반 시 조치**: 즉시 작업 중단 + 올바른 역할에 재할당 + violations 섹션 기록 + MEMORY.md 재발 방지 등록.

**CR 반영**: TASK_SPEC 이후 CHANGE_REQUEST를 승인하면 해당 task 파일 · plan 절 제목 · status `plan_rev`를 같은 커밋에서 고친다.

#### 에이전트 라이프사이클 관리 규칙 (AGENT-LIFECYCLE)

> Team Lead는 에이전트(팀원)의 생성·운영·종료를 **엄격하게** 관리한다. 유휴 에이전트를 방치하지 않는다.

| ID | 규칙 | 설명 | 심각도 |
|----|------|------|--------|
| **LIFECYCLE-1** | 5분 무보고 점검 | 에이전트가 **5분 이상 보고 없이 idle** 상태이면, Team Lead는 해당 에이전트의 역할·할당 Task를 점검하고 **필요 시 즉시 종료** | CRITICAL |
| **LIFECYCLE-2** | 미사용 에이전트 즉시 종료 | 할당된 Task가 없거나, 모든 Task가 완료된 에이전트는 **즉시 shutdown_request**로 종료. 유휴 방치 금지 | CRITICAL |
| **LIFECYCLE-3** | 종료 전 Task 상태 확인 | 에이전트 종료 전 task 파일·최근 보고로 해당 에이전트의 진행 중 Task를 확인. 미완료 Task가 있으면 재할당 또는 보류 판단 후 종료 | HIGH |
| **LIFECYCLE-4** | 팀 해산 시 전원 종료 | 팀 작업 완료 시 **모든 팀원에게 shutdown_request** 후 팀 config에 team-lead만 남았는지 확인하고 센티넬 해제를 확인한다. 잔류 에이전트 없이 깨끗하게 정리. 비정상 종료 멤버가 config에 남으면 LIFECYCLE-5(생존 확인)로 처리하고 status에 기록한다 | HIGH |
| **LIFECYCLE-5** | 좀비 감지 + Respawn | spawn 후 30초 1차 check + 3분 정기 check. 좀비 확인 시 shutdown_request + suffix(`_r1`~`_r5`)로 동일 spec respawn. **상한 5회**. 누적 도달 시 task BLOCKED + 사용자 보고 | CRITICAL |
| **LIFECYCLE-6** | 체크 스케줄러 | LIFECYCLE-1·5 의 실행체. 팀원 ≥1 인 Phase 는 **팀원 0→1 스폰 직후 워처 arm**(BUILDING 진입 시 미arm이면 진입 차단 — 2차 방어선). 3분 주기 폴링 + spawn+30초 1차 체크. 알림은 기동 시 한 번, ZOMBIE는 매 주기, 그 밖에는 상태가 바뀔 때 | CRITICAL |

**정본 위치**: LIFECYCLE-5 · 6(하위 6.1 SPAWN_GATE)의 정본은 `ROLES/SUB-SSOT/TEAM-LEAD/lifecycle-procedure.md`다. 위 표의 두 행은 요약이다(LOCK-6).

**상주 예외 (LIFECYCLE-1 · 2)**: 상주 역할(planner 또는 respawn 이름 `planner_r1`~`planner_r5` — `handoff/planning.md` §1)은 PLANNING부터 G4 입력 제출까지 Task 사이 대기를 할당 상태로 본다. LIFECYCLE-1 무보고 점검 · LIFECYCLE-2 즉시 종료 대상이 아니며, 생존은 LIFECYCLE-5 시그널 #1 · #2와 지시 ack(COMM-1)로 판정한다. G4 입력을 낸 뒤에는 LIFECYCLE-2를 따른다.

**Team Lead 에이전트 관리 절차**:
```
1. 에이전트 스폰 → 즉시 Task 할당 (idle 스폰 금지)
2. 5분 타이머: 보고 없으면 → task 파일·최근 보고 확인 → 역할·Task 점검
3. 점검 결과:
   a. Task 진행 중 + 정상 → 메시지로 상태 확인 요청
   b. Task 없음 / 완료됨 → 즉시 종료 (shutdown_request) — 상주 역할은 위 상주 예외
   c. 역할 불일치 발견 → 즉시 중단 + 재할당 또는 종료
   d. 좀비 의심(프로세스 부재/무응답) → LIFECYCLE-5 진입
4. 팀 작업 완료 → 전원 종료 → 팀 config에 team-lead만 남았는지 확인 · 센티넬 해제 확인
```
> 위 3.a/3.d 판정은 LIFECYCLE-6 워처(arm 상태에서 3분 폴링)가 emit 하는 상태 변화 알림을 근거로 삼는다.

---

#### TESTING → AB_COMPARISON (선택적)

> 복수 구현 방안이 존재하고 비교 필요 시에만 진입.

```
1. TESTING PASS 후 복수 구현 존재 여부 확인
2. 복수 존재 → current_state = "AB_COMPARISON"
3. Team Lead: 구현 A vs B 비교 (성능, 가독성, 유지보수성)
4. 최적안 선택 → INTEGRATION (또는 다음 Task)
```

#### 3.3 병렬 BUILDING 및 재검증

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

## 4. 에러 처리

| 등급 | 명칭 | 처리 |
|------|------|------|
| **E0** | Critical | 즉시 중단, 사용자 보고 |
| **E1** | Blocker | BLOCKED 전이, Fix Task 생성 |
| **E2** | High | REWINDING, 수정 요청 |
| **E3** | Medium | Technical Debt 등록 |
| **E4** | Low | 기록만 |

**재시도**: `retry_count`는 **Phase 누적 카운터**다 (status.md 정본 — 상태 불문 REWINDING 전이마다 +1, §5.1). 누적 ≥ 3이면 접근 방식 폐기, 에러 로그 보고, 사용자 판단 대기. **상태별로 별도 계수하지 않는다** — 서로 다른 게이트에서 나눠 실패해도 합산 3회에서 중단된다. 각 REWINDING의 발생 상태·사유는 `error_log[]`에 병기하여 사유별 추적을 보장한다. (상한을 넘는 값은 기록된 뒤 상태 전이 훅이 거부를 알린다 — 즉시 원복하고 사용자 판단을 받는다)

---

## 5. 리와인드 (Rewind)

### 5.1 리와인드 기본 절차

실패 시 rewind_target 결정 → current_state = "REWINDING" → 해당 팀원에게 수정 요청 → rewind_target으로 전이 → retry_count += 1.
(PLAN_REVIEW 실패 → PLANNING, VERIFYING/TESTING/INTEGRATION/E2E 실패 → BUILDING)

### 5.2 A/B 분기 (AB_COMPARISON 연계)

`AB_COMPARISON` 진입 시 복수 구현안을 각각 독립 브랜치에서 구현한다.

---

## 6. 운영 원칙(OPS)

| ID | 규칙 | 설명 | 심각도 |
|----|------|------|--------|
| **OPS-1** | 요구사항 우선 | 요청자 요구사항이 최우선이다. 요구사항 간 순위는 Team Lead가 정하지 않고 사용자에게 질의해 정한다. 정해진 순위를 임의로 바꾸지 않는다 | HIGH |
| **OPS-2** | 발견 문제 | ① 과업 중 발견한 계획 밖 문제는 `reports/issue-*.md`(Phase 밖이면 `docs/reports/`)로 검토 · 결정받은 뒤 반영한다. 팀원은 발견 사실만 보고하고(COMM-4) 리포트는 Team Lead가 쓴다 ② 판정자 결과의 「관찰(결함 아님)」도 Team Lead가 받은 회차에 처리 경로(정정 · tech-debt · 사용자 확인 · 수용 한 줄)를 status 로그에 적는다. 사용자 결정과 닿는 관찰은 수용으로 닫지 않는다 | HIGH |
| **OPS-3** | 예산 | 착수 때 예상 · 상한 · 중간 보고 지점을 사용자에게 보이고 승인받아 status `token_budget`에 적는다. 예상 토큰 안에서 최대 완성을 지향한다. Task 수령마다 소비를 계측한다(`CORE/shared-definitions.md` §8). 완성도가 계획보다 낮거나 상한을 넘을 전망이면 멈추고 분석 설계 리포트(목표 대비 차이 · 보완점 · 선택지)를 쓰며, 다음 단계의 추가 토큰은 사용자 승인 뒤 쓴다 | HIGH |
| **OPS-4** | 1.5배 | 예상의 1.5배 이상이 필요하면 멈추고 계획을 전면 재검토한다(설계 · 계획 페르소나 사건 — OPS-5) | HIGH |
| **OPS-5** | 페르소나 평점제 | 페르소나 6종(설계 · 계획 = planner · designer / 개발 = backend-dev · frontend-dev / 보안 = 보안 판정 담당 / 점검 = verifier / 검수 = tester / 리딩 = Team Lead). 사건별 1회 — 토큰 1.5배 초과(설계 · 계획) · 게이트 FAIL · PARTIAL(개발) · 보안 High 이상 누락(보안) · 판정 누락이 뒤에 드러남(점검) · 시험 기대값 오류 · 재작업(검수) · 중간 보고 · 지시 누락(리딩). 프로젝트 누적, 조치를 마치면 해당 회수만큼 차감. 3회 룰/페르소나 점검 · 5회 workflow 점검 · 10회 하네스(도구) 재설계. 원장은 `docs/persona-overrides/scoreboard.md`(형식 `TEMPLATES/scoreboard-template.md`)이고, 없으면 Team Lead가 첫 팀원 스폰 전에 템플릿으로 만든다. 팀원 스폰 때 해당 페르소나의 누적 회수 · 최근 사건을 함께 전달한다 | MEDIUM |
