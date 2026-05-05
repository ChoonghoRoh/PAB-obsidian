---
title: "PAB SSOT — 템플릿 11종 (TEMPLATES/)"
description: "Phase 산출물 표준 양식 11종 — task-report·defect-report·decision-log·event-log·ab-comparison·research-report + AutoCycle 5종(development-plan·prompt-alignment·phase-achievement·tech-debt·master-final) + Pre-draft Topics(v8.2)"
created: 2026-05-05 05:13
updated: 2026-05-05 05:13
type: "[[RESEARCH_NOTE]]"
index: "[[KNOWLEDGE_MGMT]]"
topics: ["[[PAB_SSOT]]", "[[TEMPLATES]]", "[[AUTOCYCLE]]"]
tags: [research-note, pab-ssot-nexus, templates, autocycle, reports]
keywords: ["task-report-template", "defect-report-template", "decision-log-template", "event-log-template", "ab-comparison-template", "research-report-template", "development-plan-template", "prompt-alignment-check", "phase-achievement-report", "tech-debt-report", "master-final-report", "pre-draft-topics", "AutoCycle Step 0/3/5/8/12/13/14"]
sources:
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/TEMPLATES/"
aliases: ["SSOT 템플릿", "11 templates", "AutoCycle 템플릿"]
---

# PAB SSOT — 템플릿 11종

> 보고서·로그·계획서 표준 양식 11종. 5세대 기본 6종 + AutoCycle v1.0/v1.1 신규 5종.

## 전체 일람

| # | 파일 | 라인 | 적용 시점 | AutoCycle Step | 작성 주체 |
|---|---|---:|---|---|---|
| 1 | `task-report-template.md` | 40 | Task 완료 | — | 모든 팀원 (역할별) |
| 2 | `defect-report-template.md` | 85 | 결함 발견 | — | tester / verifier |
| 3 | `decision-log-template.md` | 29 | 의사결정 시 | — | Team Lead |
| 4 | `event-log-template.md` | 99 | 이벤트 발생 (자동) | — | 자동 (4-event-protocol §1) |
| 5 | `ab-comparison-template.md` | 79 | AB_COMPARISON 상태 | — | tester + Team Lead |
| 6 | `research-report-template.md` | — | RESEARCH 완료 | — | research-lead |
| 7 | **`development-plan-template.md`** | 110 | PLANNING (Step 3) | **Step 3** | planner |
| 8 | **`prompt-alignment-check.md`** | 89 | PLAN_REVIEW (Step 5) | **Step 5** | planner + verifier 협업 |
| 9 | **`phase-achievement-report.md`** | 75 | G4 판정 시점 (Step 8) | **Step 8** | Team Lead |
| 10 | **`tech-debt-report.md`** | 83 | Phase 종료 시점 (Step 12) | **Step 12** | Team Lead |
| 11 | **`master-final-report.md`** | 203 | 체인/Phase 종료 시 (Step 13~14) | **Step 13~14** | Team Lead |
| 12 | **`pre-draft-topics.md`** | 169 | 사용자 주도 Master Plan 진입 전 (Step 0) | **Step 0 (v8.2)** | Team Lead 단독 (`/plan` skill) |

> 굵은 글씨 5종은 AutoCycle v1.0(Phase-G·H) + 1종(Phase-I)에서 신설. PROMPT-QUALITY 규칙(HIGH) 적용 필수.

## 5세대 기본 6종

### 1. task-report-template.md
Task 완료 시 마크다운 보고서. **REPORT-1~5 강제 양식**.

```markdown
# Phase X-Y 작업 보고서 — {역할}
**작성자**: {팀원 이름}
**Phase**: X-Y
**작성일**: YYYY-MM-DD
```

필수 섹션 5개 (REPORT-4):
1. 작업 내용
2. 작업 결과
3. 테스트 결과
4. 위험 요소
5. 다음 개발 추천

저장 경로 (REPORT-5): `docs/phases/phase-X-Y/reports/report-{역할명}.md`

### 2. defect-report-template.md (Defect Report)
결함 발견 시 7필드 양식 (Defect ID·심각도·유형·재현·기대·실제·환경). **ISTQB CTFL 4.0 기반**.

```yaml
defect_id: "DEF-phase-X-Y-NNN"
```

심각도: Critical / Major / Minor / Trivial. 유형: Functional / Performance / Security / UX / Compatibility.

### 3. decision-log-template.md
의사결정 기록 (Team Lead 판정·승인). 29줄 간결 양식.

```markdown
# Decision Log: {Phase 제목}
> Phase: {X-Y}
> 생성일: {날짜}
```

DecisionEngine이 자율 판정 시 자동 기록 (5-automation §3.6).

### 4. event-log-template.md
JSONL 이벤트 로그 표준. 4-event-protocol.md §1 이벤트 스키마 참조 (8 event_type).

### 5. ab-comparison-template.md
AB_COMPARISON 상태 비교 리포트. Branch-A vs Branch-B.

```markdown
# A/B Comparison Report: [제목]
> Phase: [X-Y] | Task: [N]
> 비교 대상: Branch-A vs Branch-B
> 작성일: [YYYY-MM-DD]
```

비교 항목: 코드 품질·아키텍처 적합성·유지보수성·확장성·테스트 용이성·성능·안정성.

### 6. research-report-template.md
G0용 리서치 보고서. 범위·대안 비교·영향도·리스크·추천·G0 준비.

작성 주체: research-lead (research-architect + research-analyst 결과 통합).

## AutoCycle v1.0/v1.1 신규 5종 + Pre-draft

### 7. development-plan-template.md (Step 3 — PLANNING)
**KPI 수치화 + 사용자/개발자 관점 분리**. PLANNING 단계의 핵심 산출물.

| 섹션 | 내용 |
|---|---|
| 목표 | 정량적 KPI (예: API 응답 시간 < 200ms) |
| 사용자 관점 KPI | UX·기능·접근성 측정값 |
| 개발자 관점 KPI | 커버리지·복잡도·리팩토링 등 |
| 사전 반복 이력 | ITER-PRE 3회 한도 내 변경 이력 |

작성 주체: planner. PLANNING → PLAN_REVIEW(G1) 진입 전 필수.

### 8. prompt-alignment-check.md (Step 5 — PLAN_REVIEW)
**원본 프롬프트 vs 계획/구현 문장별 매핑**. 사용자 의도와 계획·구현 정합성 검증.

작성 주체: planner + verifier 협업. PLAN_REVIEW(G1) 단계.

### 9. phase-achievement-report.md (Step 8 — G4 판정)
**KPI 초기값 vs 달성값 + 수정계획서**. 1 사이클 완료 후 계획 부합 검증.

| 섹션 | 내용 |
|---|---|
| KPI 초기값 | development-plan-template.md의 목표 |
| KPI 달성값 | 실측 결과 |
| Gap 분석 | 부합·미달 항목 |
| 수정계획 | 미달 시 다음 사이클 보완 (ITER-POST 트리거) |

작성 주체: Team Lead (G4 판정 시점).

### 10. tech-debt-report.md (Step 12 — Phase 종료)
**수정 불가 항목 + carryover_to**. 본 Phase에서 해결 못한 항목을 다음 Phase로 이관.

```yaml
defects:
  - id: TD-phase-X-Y-001
    severity: HIGH
    description: "..."
    carryover_to: "phase-X-(Y+1)"   # CHAIN-12로 자동 로딩
```

**CHAIN-12 자동 로딩**: 차기 Phase 시작 시 Team Lead가 직전 tech-debt-report.md를 읽어 carryover 확인 필수.

작성 주체: Team Lead (Phase 종료 시점).

### 11. master-final-report.md (Step 13~14 — 체인/Phase 종료)
**6섹션 최종 보고서 + Next Prompt + verifier 승인 + 사용자 피드백**.

6섹션 (203줄 양식):
1. 요약 (Executive Summary)
2. 사이클 결과 (KPI 달성)
3. 의사결정 이력
4. Next Prompt — 다음 Master Plan 진입 추천 (Phase-I `initiator_hint` 필드)
5. verifier 승인 훅 (G4 verifier 서명)
6. 사용자 피드백 (자유 기입)

작성 주체: Team Lead. 체인 또는 Master Plan 종료 시 필수 (CHAIN-11).

**CHAIN-13 자동 로딩**: 차기 Phase/사이클 시작 시 직전 최대 3개 master-final-report 요약 자동 로딩 (기억 전달).

### 12. pre-draft-topics.md (Step 0 — 사용자 주도 진입 전, v8.2 Phase-I 신규)

**PROMPT-QUALITY 규칙 5항목 판정**: 사용자 주도 마스터 플랜(`initiator: user`) 진입 전 프롬프트 품질 토픽 논의·자료 수집.

판정 5항목:
1. **완전성** — 사용자 관점 + 개발자 관점 양쪽 도출 가능
2. **명료성** — 모호 용어 0건 (또는 "TBD" 명시)
3. **실행 가능성** — 기술적 Show-stopper 없음
4. **범위 적정성** — 단일 Phase 적정 / 분할 필요 판정
5. **트리아지** — 즉시 진행 / 재질문 / 분할 / 취소

8 섹션 양식:
1. 원본 프롬프트
2. 토픽 분류
3. 수집 자료
4. Pre-test (실행 가능성 사전 검증)
5. **5항목 판정**
6. 마스터 플랜 진입 준비
7. Next Step
8. 사용 지침

작성 주체: Team Lead 단독 (`/plan` 스킬 사용).
저장 경로: `docs/phases/pre/phase-{N}-pre-draft.md` (HR-4 / CHAIN-10 — `pre/` 평탄 폴더).

**Fast-path 허용**: 5항목 자명 PASS 시 템플릿 작성 생략 (`master-plan.md` frontmatter에 `prompt_quality: fast-path` 표기).

**AI handoff 시 자동 제외**: `initiator: ai-handoff`이면 Step 0 자동 스킵 + CHAIN-13(직전 3 Phase 기억) 대체.

## 진입 분기 — 사용자 주도 vs AI handoff

| 분기 | initiator | Step 0 | 단계 수 | 적용 |
|---|---|:--:|:--:|---|
| **사용자 주도** | `initiator: user` | ✅ Pre-draft 5항목 판정 | **15** | 새 마스터 플랜 시작 |
| **AI handoff** | `initiator: ai-handoff` | ❌ 자동 스킵 | **14** | 이전 Phase의 master-final-report `next_prompt`로 자동 진입 |

## AutoCycle 전체 흐름 (참고)

```
Step 0  [사용자 주도만] Pre-draft Topics + 5항목 판정 (PROMPT-QUALITY)
Step 1  ANALYSIS-1 사전 분석 (pre-analysis.md)
Step 2  Master Plan 작성 (REFACTOR-2 + CHAIN-7 + CHAIN-11 점검)
Step 3  Development Plan (KPI 수치화) — planner
Step 4  Task 분해 + 도메인 태그 + 담당 역할 (ASSIGN-1)
Step 5  Prompt Alignment Check — planner + verifier
Step 6  TASK_SPEC + ASSIGN 검증 (Team Lead 3단계 통제)
Step 7  BUILDING + VERIFYING + TESTING (G2/G3) — 4th 호환 흐름
Step 8  Phase Achievement Report (G4 판정 KPI 부합 검증)
Step 9  ITER-POST 재계획 (최대 2회) — KPI 미달 시
Step 10 INTEGRATION + E2E
Step 11 NOTIFY-1 Telegram 알림 (DONE)
Step 12 Tech Debt Report — carryover 항목
Step 13 Master Final Report — 6섹션
Step 14 verifier 승인 + 사용자 피드백 (Step 13 보고서 §5·§6)
```

(Step 1~5는 ITER-PRE 최대 3회 반복 — G-Pre 수렴 게이트)

## 다음 노트

- [[2026-05-05_pab_ssot_workflow|워크플로우]] — ITER-PRE/POST + ITERATION-BUDGET 500K
- [[2026-05-05_pab_ssot_rules_chain|규칙·CHAIN]] — CHAIN-11/12/13 + ANALYSIS-1~3 + PROMPT-QUALITY
- [[2026-05-05_pab_ssot_skills_detail|skill 상세]] — `/plan` skill (Step 0 Pre-draft 자동화)
- [[PAB_SSOT_overview|MOC]]

## 참고

- `/PAB-SSOT-Nexus/docs/SSOT/docs/TEMPLATES/` (11파일)
- 그 외 핵심 5종은 AutoCycle Phase-G/H/I (2026-04-16) 신설
- PROMPT-QUALITY 규칙: core/6-rules-index.md §1.20
