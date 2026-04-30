# Orchestration Procedure — SUB-SSOT

> **버전**: 1.3 | **갱신**: 2026-04-16 (Phase-I I-4 — §Step-0 Branch 신규, initiator 판별 로직)
> **소스**: CLAUDE.md HR 규칙 + 0-entrypoint.md §2.5 + autocycle-initial-requirements.md

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

```
PRE_BUILD_ITERATION_COUNTER = 0  # 초기값

while PRE_BUILD_ITERATION_COUNTER < 3:
    Step 1  — 현행 파일 조사 (research-analyst, research-architect)
    Step 2  — 외부 벤치마킹 (research-analyst WebSearch)
    Step 3  — 개발 PLAN 수립 / KPI 수치화 (planner → development-plan-template.md)
    Step 4  — Spike 테스트 (CODER → PHASE 3)
    Step 5  — 프롬프트 정합성 점검 (prompt-alignment-check.md)
    PRE_BUILD_ITERATION_COUNTER += 1

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

```
REPLAN_COUNTER = 0  # 초기값

Phase X-Y DONE (Step 7)
  → Step 8: phase-achievement-report.md 작성 + KPI 달성 대조
  → if 미달 KPI 존재 AND REPLAN_COUNTER < 2:
       REPLAN_COUNTER += 1
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
