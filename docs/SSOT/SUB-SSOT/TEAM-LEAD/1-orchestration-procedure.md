# Orchestration Procedure — SUB-SSOT

> **버전**: 1.3 | **갱신**: 2026-04-16 (Phase-I I-4 — §Step-0 Branch 신규, initiator 판별 로직)
> **소스**: CLAUDE.md HR 규칙 + 0-entrypoint.md §2.5 + autocycle-initial-requirements.md(원본 저장소 참조 — 번들 미포함)

---

## §Step-0 Branch — 사용자 주도 vs AI handoff 진입 분기 (Phase-I I-4)

> **적용 규칙**: `PROMPT-QUALITY` (6-rules-index.md §1.20)
> **적용 시점**: 마스터 플랜 요청 접수 직후, TeamCreate 이전 (Phase 오케스트레이션 흐름보다 앞선 단계)

### Master Plan YAML 헤더 표준 (initiator 필드)

모든 `phase-{N}-master-plan.md` 파일의 YAML 헤더에 `initiator` 필드를 **필수**로 포함한다.

```yaml
---
phase: "N"
name: "..."
initiator: "user" | "ai-handoff"         # 필수
prompt_quality: "full" | "fast-path" | "n/a"   # initiator == "user" 시 필수
pre_draft_ref: "docs/phases/pre/phase-{N}-pre-draft.md"   # user + full 시 필수
---
```

| 필드 | initiator = user | initiator = ai-handoff |
|------|------------------|------------------------|
| `prompt_quality` | "full" 또는 "fast-path" 필수 | "n/a" |
| `pre_draft_ref` | full 일 때 필수 | 불필요 |
| Step 0 진입 | 필수 | 자동 스킵 |
| CHAIN-13 자동 로딩 | 선택 | 필수 |

### 판별 플로우차트

```
[Master Plan 요청 접수]
        │
        ▼
    사용자가 /plan 명시 호출?
        │
   ┌────┴────┐
  YES         NO
   │          │
   │          ▼
   │    master-plan YAML
   │    initiator == "user"?
   │          │
   │     ┌────┴────┐
   │    YES         NO (ai-handoff)
   │     │          │
   ▼     ▼          ▼
 Step 0 진입    Step 0 스킵
 (Pre-draft)   + CHAIN-13 자동 로딩
   │              │
   ▼              ▼
 /plan 스킬    master-plan 작성 착수
 실행          (Phase-{N} orchestration)
   │
   ▼
 pre-draft-topics.md
 작성 → PROMPT-QUALITY
 5항목 판정
   │
   ┌────┴────┐
  PASS     FAIL/PARTIAL
   │         │
   ▼         ▼
 master-plan  재질문 / 범위 조정 / 보류
 작성 착수
```

### 오버라이드 규칙 (verifier #0 Optional note 반영)

1. **사용자 명시 호출 최우선**: `/plan` 명시 호출은 YAML `initiator`에 상관없이 Step 0 진입 강제
2. **Next Prompt 자동 상속**: 직전 Phase의 `master-final-report §7.3 initiator_hint` 값이 다음 Phase의 기본 `initiator`로 적용 (기본값 "ai-handoff")
3. **사용자 수동 오버라이드 허용**: AI handoff로 이어진 프롬프트라도 사용자가 master-plan YAML을 직접 "user"로 변경하면 Step 0 진입

### 진입 분기 체크리스트 (Team Lead 의무)

마스터 플랜 요청 접수 시 Team Lead는 다음 순서로 판별:

- [ ] 1. `/plan` 명시 호출 여부 확인 → YES면 즉시 Step 0 진입
- [ ] 2. 이전 Phase의 master-final-report §7.3 `initiator_hint` 조회
- [ ] 3. 현재 요청이 Next Prompt Suggestion 자동 이어짐인지 판별
- [ ] 4. `initiator` 값 결정: 직접 사용자 요청 → "user" / Next Prompt 이어짐 → "ai-handoff"
- [ ] 5. master-plan YAML에 `initiator`·`prompt_quality`·`pre_draft_ref` 필드 기입
- [ ] 6. `initiator == "user"` → `/plan` 스킬 실행 → `docs/phases/pre/phase-{N}-pre-draft.md` 작성
- [ ] 7. `initiator == "ai-handoff"` → CHAIN-13 자동 로딩 후 즉시 master-plan 작성 단계

### 관련 산출물

- 규칙: `core/6-rules-index.md §1.20 PROMPT-QUALITY`
- 템플릿: `TEMPLATES/pre-draft-topics.md` (§1~§8 구조)
- 스킬: `.claude/skills/plan/SKILL.md` (Plan Mode 유사, Team Lead 단독)
- 저장 경로: `docs/phases/pre/phase-{N}-pre-draft.md`
- 연관 규칙: CHAIN-13 (Phase-H H-6, AI handoff 시 기억 전달)

---

## §G-A — worktree 휴리스틱 판정 의무 (Phase 7-2 신규)

> **적용 규칙**: WT-6 (3-workflow.md §6.6.1) — Phase 7-1에서 정본화
> **Cross-reference**: [3-workflow.md §6.6.1 WT-6](../../3-workflow.md) / [정본 §1 D1~D4](../../../../poc/worktree-gate-design/01-design-decisions.md) / [3-workflow.md §6.6.2 WT-7](../../3-workflow.md)
> **위임 한계 (C2)**: 본 절차는 Team Lead의 **절차·책임**만 규정. 휴리스틱 알고리즘 실행은 `/plan` 스킬(Phase 7-3 영역)에 위임 — Team Lead 본인은 "절차 따라 결과 기록"만 수행.

### 적용 시점

다음 두 시점에 Team Lead는 **반드시** worktree 휴리스틱 판정을 수행한다:

1. **마스터 플랜 작성 시** — `/plan` 호출 직후, 또는 master-plan YAML 작성 시점
2. **Sub-Phase 진입 시** — `/phase-init` 호출 직전 (status.md 신규 생성 단계)

### 입력 신호 셋 (S1 + S5 + S6)

| 신호 ID | 출처 | 추출 방법 |
|---------|------|---------|
| **S1. 트랙 수 N** | master-plan / Sub-Phase Task 명세 | 도메인 태그 `[BE]/[FE]/[TEST]` 카운트 |
| **S5. 상태머신 분기** | 직전 Phase status.md `current_state` | `current_state ∈ {AB_COMPARISON, REWINDING}` 여부 |
| **S6. 사용자 명시** | master-plan / Sub-Phase 본문 | `worktree: yes/no` 직접 선언 여부 |

### 판정 결과 3분 (WT-6 D2)

- **필요** — WT-1 CRITICAL 등 강제 발동 (G-C 차단, G-D FAIL 안전망 연계)
- **권장** — 회색지대, 안내만, 사용자 결정
- **불필요** — 출력 없음

우선순위: **S6 > S5 > S1** (사용자 명시 → 상태머신 → 트랙 수)

### 판정 결과 출력 형식 (G-B 연계)

판정 결과는 다음 두 위치에 동시 기록한다:

1. **master-plan 본문**: "필요" 판정 시 한 줄 안내 (예: "worktree 필수 — 트랙 N=2 이상")
2. **phase-X-Y-status.md YAML 헤더**:
   - `worktree_required: true|false`
   - `worktree_recommended: true|false`
   - `expected_tracks: [be, fe, ...]`

### 자동 발동 금지 (사용자 통제권 보장)

- AI(Team Lead)는 판정·기록만 수행. 실제 worktree 생성은 **G-C 강제 차단** 또는 **사용자 트리거 어휘**(§G-E 참조) 발동 시에만 진행
- "필요"만 강제, "권장"은 인지만. 자동 발동 절대 금지

### 체크리스트 (Team Lead 의무)

마스터 플랜 작성 시 / Sub-Phase 진입 시 Team Lead는 다음 순서로 수행:

- [ ] 1. S1 (트랙 수 N) 추출 — Task 도메인 태그 카운트
- [ ] 2. S5 (상태머신 분기) 점검 — 직전 Phase status.md `current_state` 확인
- [ ] 3. S6 (사용자 명시) 확인 — master-plan/Sub-Phase 본문 `worktree: yes/no` 검색
- [ ] 4. WT-6 D3 우선순위(S6 > S5 > S1) 적용하여 3분 판정
- [ ] 5. master-plan / status.md YAML에 `worktree_required` / `worktree_recommended` / `expected_tracks` 기록
- [ ] 6. "필요" 판정 시 master-plan 본문에 한 줄 안내 작성
- [ ] 7. 휴리스틱 알고리즘 실행은 `/plan` 스킬에 위임 (Phase 7-3 영역) — Team Lead는 결과 기록만

---

## §G-E — VERIFYING 종료 후 차기 Phase 권고 작성 의무 (Phase 7-2 신규)

> **적용 규칙**: WT-7 G-E (3-workflow.md §6.6.2) — Phase 7-1에서 정본화
> **Cross-reference**: [3-workflow.md §6.6.2 WT-7](../../3-workflow.md) / [정본 §2](../../../../poc/worktree-gate-design/01-design-decisions.md) / [verifier.md §2.2 §G-E 트리거 신호](../../ROLES/verifier.md)
> **위임 한계 (C2)**: 본 절차는 Team Lead의 **절차·책임**만 규정. 임계값 자동 계산·권고 옵션 자동 생성 등 알고리즘 실행은 `/plan` 스킬(Phase 7-3 영역)에 위임.

### 적용 시점

VERIFYING 종료 직후 — verifier로부터 G2/G3 보고서를 SendMessage로 수신한 시점.

### 임계값 점검 의무 (D1 채택 — 본문 직접 명시)

verifier 보고서 수신 즉시 다음 두 임계값을 점검한다 (OR 조건 — 하나라도 충족 시 권고 작성 의무 발동):

- **테스트 FAIL 비율 ≥ 30%** → "compare 권고" 작성 의무 발동
- **룰 위반 High 이상 ≥ 5건** → "compare 권고" 작성 의무 발동

두 조건 모두 미달 시 권고 작성 생략 (불필요 — 일반 흐름).

### 권고 출력 위치 (양쪽 기록 의무)

권고는 다음 두 위치에 **동시** 기록한다:

1. **status.md YAML**: `phase-X-Y-status.md` 헤더의 `next_phase_recommendations` 필드 — 사유·옵션·트리거 어휘 5종 명시
2. **final-summary**: `phase-X-final-summary-report.md`의 `§다음 Phase 권고` 섹션 — 본문 권고 코멘트

### 5종 트리거 어휘 (M12 사전, Phase 7-4 확정 예약)

차기 Phase `/plan` 시작 시 사용자에게 다음 5종 어휘 중 하나의 응답을 요청한다:

- `권고안 진행` → suggested_options 그대로 compare 발동
- `쉽게 진행` → 권고 무시, 일반 흐름
- `옵션 X로` → 권고 옵션 중 1개만 채택 (단일 worktree)
- `compare 진행` → 명시적 compare 호출
- 무응답 → 묵시적 거절 (일반 흐름)

> 자연어 변형 매핑 표는 Phase 7-4 (`skills/worktree/REFERENCE.md §1.4`)에서 확정.

### 자동 발동 금지

- AI(Team Lead)는 권고 작성·기록만 수행. 실제 worktree compare 발동은 **사용자 트리거 어휘** 입력 시에만 진행
- 무응답 = 거절로 간주 (묵시적 거절)

### 체크리스트 (Team Lead 의무)

verifier G2/G3 보고서 수신 시 Team Lead는 다음 순서로 수행:

- [ ] 1. 보고서 수신 즉시 임계값 점검 (테스트 FAIL ≥ 30% / High ≥ 5건)
- [ ] 2. 임계값 충족 시 status.md YAML `next_phase_recommendations` 작성 — 반드시 사유·옵션 후보(suggested_options)·5종 트리거 어휘 모두 명시
- [ ] 3. final-summary-report.md `§다음 Phase 권고` 섹션 동시 작성
- [ ] 4. 차기 Phase `/plan` 시작 시 자동 픽업 → 사용자에게 5종 트리거 어휘 안내
- [ ] 5. 사용자 응답에 따라 status.md `decision_at` / `decision_by` / `reason` 기록
- [ ] 6. 권고 본문 작성·옵션 결정 책임은 **Team Lead 단독**. verifier는 트리거 신호만 발신 (책임 분리 — verifier.md §2.2 참조)
- [ ] 7. 임계값 미달 시 권고 작성 생략 + 일반 흐름 진행 (현 Phase DONE 전이는 깨지지 않음)

---

## Phase 오케스트레이션 흐름

```
Phase 시작
  │
  ▼
[1] TeamCreate(team_name: "phase-X-Y")
  │
  ▼
[1.5] (5th 선택) Research Team 스폰
  │   → RESEARCH → RESEARCH_REVIEW(G0)
  │
  ▼
[2] Task tool × N — 팀원 스폰
  │   planner(Plan/opus), backend-dev, frontend-dev(sonnet),
  │   verifier(Explore/sonnet), tester(Bash/sonnet)
  │
  ▼
[3] SendMessage — 작업 할당 (SUB-SSOT 로딩 지시 포함)
  │
  ▼
[4] 팀원 작업 + 보고 (SendMessage)
  │
  ▼
[5] 모든 작업 완료 → shutdown_request × N
  │
  ▼
[6] TeamDelete — 팀 해산
  │
  ▼
Phase 완료 (DONE)
```

---

## 팀원 스폰 시 SUB-SSOT 로딩 지시

Team Lead는 팀원 스폰 시 SendMessage에 **SUB-SSOT 로딩 경로**를 포함한다:

```
SendMessage → planner:
  "다음 문서를 로딩하세요:
   1. core/7-shared-definitions.md
   2. SUB-SSOT/PLANNER/0-planner-entrypoint.md
   3. SUB-SSOT/PLANNER/1-planning-procedure.md
   그리고 Phase X-Y 계획 분석을 시작하세요."
```

---

## Gate 판정 (G0~G4)

| Gate | 판정자 | 기준 |
|------|--------|------|
| **G0** | Team Lead | Research 완료, 대안 2+, 리스크 분석 |
| **G1** | Team Lead | Task 3~7, 도메인 분류, 리스크 식별 |
| **G2** | Team Lead (verifier 보고 기반) | Critical 0건 |
| **G3** | Team Lead (tester 보고 기반) | pytest PASS, 커버리지 ≥80% |
| **G4** | Team Lead | G2+G3 PASS + Blocker 0 + **verifier 승인** (master-final-report §8 PASS 필수, AutoCycle Step 13 시) |

---

## 에이전트 라이프사이클 관리

| 규칙 | 행동 |
|------|------|
| LIFECYCLE-1 | 5분 무보고 → 역할·Task 점검 → 필요 시 종료 |
| LIFECYCLE-2 | 할당 Task 없는 에이전트 → 즉시 shutdown |
| LIFECYCLE-3 | 종료 전 미완료 Task 재할당/보류 판단 |
| LIFECYCLE-4 | 팀 해산 시 전원 shutdown → TeamDelete |
| LIFECYCLE-5 | 좀비 감지 + Respawn (30초/3분 check, 상한 5회) — 상세 `2-lifecycle-procedure.md §LIFECYCLE-5 RESPAWN` |
| LIFECYCLE-6 | 체크 스케줄러 arm/해제 + BUILDING 진입 차단 (상세 `2-lifecycle-procedure.md §LIFECYCLE-6 SCHEDULER`) |

> **§LIFECYCLE-5 RESPAWN · §LIFECYCLE-6 SCHEDULER 는 `2-lifecycle-procedure.md` 로 분리**
> (Phase 9-2, REFACTOR-2 Lv1 — 671/700 여유 부족). 본 문서는 LIFECYCLE-1~6 요약표까지만 보유한다.

---

## 지연 스폰 (비용 절감)

verifier, tester는 **VERIFYING/TESTING 단계 진입 시** 스폰 가능.
초기 BUILDING 동안 불필요한 에이전트 유지 비용 절감.

---

## Phase Chain 운영

- DONE 후 `/clear` → 다음 Phase status.md 읽기 → [1] TeamCreate부터 반복
- Chain 파일: `docs/phases/phase-chain-{name}.md` (phases 배열)
- 순차 보장 (CHAIN-4), /clear 필수 (CHAIN-2)

### CHAIN-12: Tech Debt 자동 로딩

차기 Phase 시작 시 Team Lead는 **status.md 읽기 직후, TeamCreate 전**에:

1. 직전 Phase의 `tech-debt-report.md` 존재 여부 확인 (Glob)
2. 존재 시 `§2 기술 부채 목록` + `§5 차기 Phase 연계` 읽기
3. `carryover_to`가 현재 Phase를 가리키는 항목을 master-plan 사전 반영
4. 해당 항목을 현재 Phase의 plan.md에 "선행 해결 항목"으로 등록

```
Phase-{N} 시작:
  → status.md 읽기 (ENTRY-1)
  → Glob("docs/phases/phase-{N-1}*/tech-debt-report.md")
  → if 파일 존재:
       Read(tech-debt-report §2, §5)
       carryover 항목 추출 → plan.md §선행 해결 등록
  → TeamCreate (정상 흐름)
```

### CHAIN-13: 직전 3 Phase Final Report 자동 로딩 (CHAIN-N+1)

차기 Phase 또는 사이클 시작 시 Team Lead는 **직전 최대 3개 Phase의 master-final-report 요약**을 로딩하여 기억 전달:

1. 직전 3 Phase의 `master-final-report.md` (또는 `phase-achievement-report.md`) 존재 확인
2. 각 보고서의 `§3 달성 수치` + `§5 보완점` + `§7 Next Prompt Suggestion` 요약 추출
3. 현재 Phase plan.md에 "선행 컨텍스트" 섹션으로 1~3줄씩 요약 등록
4. 반복 실수 방지: 이전 Tech Debt·KPI 미달 항목이 현재 Phase에서 재발하지 않도록 경계

```
Phase-{N} 시작 (CHAIN-12 직후):
  → Glob("docs/phases/phase-{N-1}*/master-final-report.md",
         "docs/phases/phase-{N-2}*/master-final-report.md",
         "docs/phases/phase-{N-3}*/master-final-report.md")
  → 존재하는 보고서마다:
       Read(§3 달성 수치 요약, §5 보완점, §7 Next Prompt)
       → plan.md §선행 컨텍스트에 요약 1~3줄 기록
  → 로딩 완료 후 TeamCreate 진행
```

---

## §ITER-PRE — Pre-Build Iteration Loop (Phase-G, AutoCycle Step 6)

**규칙 ID**: ITER-PRE
**적용 시점**: PLANNING 완료(G1 PASS) 후 → BUILDING 착수 전
**목적**: Step 1~5 (파일 조사·벤치마킹·PLAN 수립·Spike·차이분석)를 **최대 3회 반복**하여 개발 PLAN 보완.

### 사전 반복 카운터

> **카운터 영속 규칙 (필수)**: `PRE_BUILD_ITERATION_COUNTER`의 정본은 **status.md YAML `pre_build_iteration_counter`** 필드다 (3-workflow.md §2.2).
> 대화 컨텍스트(메모리) 변수로만 유지 금지 — Phase 전환 `/clear`·세션 끊김 시 리셋되어 3회 상한이 무력화된다.
> 매 반복 **진입 전 status.md에서 읽고**, 반복 종료 시 **즉시 +1 기록**한다. 상한 초과 기록은 `state-transition-guard` 훅이 차단한다.

```
PRE_BUILD_ITERATION_COUNTER = status.md 읽기(pre_build_iteration_counter)  # 정본에서 로드

while PRE_BUILD_ITERATION_COUNTER < 3:
    Step 1  — 현행 파일 조사 (research-analyst, research-architect)
    Step 2  — 외부 벤치마킹 (research-analyst WebSearch)
    Step 3  — 개발 PLAN 수립 / KPI 수치화 (planner → development-plan-template.md)
    Step 4  — Spike 테스트 (CODER → PHASE 3)
    Step 5  — 프롬프트 정합성 점검 (prompt-alignment-check.md)
    PRE_BUILD_ITERATION_COUNTER += 1
    status.md 기록(pre_build_iteration_counter = PRE_BUILD_ITERATION_COUNTER)  # 즉시 영속화

    development-plan-template.md §6 사전 반복 이력에 이터레이션 기록

    if PRE_BUILD_ITERATION_COUNTER == 3:
        → G-Pre 수렴 게이트 확인 (Phase-H H-1 확장)
        → BUILDING 착수
```

### G-Pre 수렴 게이트 (Phase-H H-1 정의)

3회 반복 종료 시 Team Lead가 **아래 3기준 모두 PASS**해야 BUILDING 착수:

| 기준 | ID | 측정법 | PASS 조건 |
|------|-----|--------|-----------|
| **KPI 일관성** | G-Pre-1 | iteration-1~3의 development-plan KPI 표 비교 | KPI 값 변동 ≤20% (= 일관성 ≥80%) |
| **대안 수렴** | G-Pre-2 | iteration-3의 선택 안 수 확인 | **정확히 1안 확정** (2안 이상 병존 시 FAIL) |
| **리스크 안정** | G-Pre-3 | iteration-2 vs iteration-3 리스크 목록 diff | 신규 리스크 0건 또는 모든 신규 리스크에 완화안 존재 |

#### G-Pre 판정 절차

```
G-Pre 판정 (Team Lead, PRE_BUILD_ITERATION_COUNTER == 3 시점):

  [G-Pre-1] iteration-1, 2, 3의 KPI 표에서 각 KPI 값 추출
             → max-min / mean ≤ 0.20 인지 확인
             → PASS / FAIL

  [G-Pre-2] iteration-3 development-plan §2.4 "최종 선택안" 확인
             → 1안 확정 → PASS
             → 2안+ 병존 → FAIL (추가 논의 필요)

  [G-Pre-3] iteration-2 risk-list vs iteration-3 risk-list diff
             → 신규 항목 0 → PASS
             → 신규 항목 존재 + 전부 완화안 보유 → PASS
             → 신규 항목 존재 + 완화안 없음 → FAIL

  if 3기준 모두 PASS:
      → BUILDING 착수 허가
  else:
      → FAIL 항목 기록
      → 옵션 A) 범위 축소 (SCOPE_REDUCTION_PROPOSAL, §3.7)
      → 옵션 B) 사용자 에스컬레이션 (HUMAN_ESCALATION_REQUEST, §3.6)
      → 4회차 반복 절대 금지
```

#### G-Pre 산출물

- `iteration-3/g-pre-gate-result.md`: 3기준 PASS/FAIL + 근거 1줄씩
- FAIL 시: `SCOPE_REDUCTION_PROPOSAL` 또는 `HUMAN_ESCALATION_REQUEST` 1건

### ITER-PRE 산출물 보관

각 이터레이션의 중간 산출물은 `docs/phases/phase-X-Y/iteration-{1,2,3}/` 하위에 보관.

---

## §ITER-POST — Post-Build Re-plan Loop (Phase-G, AutoCycle Step 9)

**규칙 ID**: ITER-POST
**적용 시점**: Phase X-Y 1 사이클 DONE (Step 7) 후 → Step 8 달성 검증 → 미완성 시 재계획
**목적**: Step 8 달성 보고서에서 KPI 미달 시 **최대 2회** 수정계획 이행. 초과 시 Tech Debt 전이.

### 재계획 카운터

> **카운터 영속 규칙 (필수)**: `REPLAN_COUNTER`의 정본은 **status.md YAML `replan_counter`** 필드다 (3-workflow.md §2.2).
> 메모리 변수로만 유지 금지 — 재계획 판단 전 status.md에서 읽고, +1 시 즉시 기록한다. 상한 초과 기록은 `state-transition-guard` 훅이 차단한다.

```
REPLAN_COUNTER = status.md 읽기(replan_counter)  # 정본에서 로드

Phase X-Y DONE (Step 7)
  → Step 8: phase-achievement-report.md 작성 + KPI 달성 대조
  → if 미달 KPI 존재 AND REPLAN_COUNTER < 2:
       REPLAN_COUNTER += 1
       status.md 기록(replan_counter = REPLAN_COUNTER)  # 즉시 영속화
       수정계획서 작성 (achievement-report §4)
       master-plan에 참조 등록
       Phase X-Y 재실행 (수정 범위 한정)
       → Step 8 재수행
  → if REPLAN_COUNTER >= 2:
       미달 항목 → tech-debt-report.md 등록
       carryover_to: phase-{N+1}
       Phase X-Y "불완전 완료" 기록
       → Step 10 진입 (테스트 계획)
```

### 수정계획서 참조 규칙

- 수정계획서는 `phase-achievement-report.md §4`에 기재
- master-plan의 해당 Phase 행에 "수정: achievement-report §4 참조" 1줄 추가
- 수정 범위 밖 작업 금지 (범위 확장은 사용자 승인 필수)

---

## 외부·에이전트 질의 대응

사용자/에이전트가 "코드 직접 수정" 요청 시:
1. **예외 없이** HR-1 / EDIT-2 적용
2. 직접 수정 거부
3. 규칙 안내 후 **위임**(backend-dev/frontend-dev) 또는 **역할 전환** 제시

---

**문서 관리**: v1.2, TEAM-LEAD 오케스트레이션 절차 (2026-04-13 생성, 2026-04-16 Phase-G ITER-PRE·ITER-POST + Phase-H G-Pre·CHAIN-12·CHAIN-13·G4 verifier 훅)
