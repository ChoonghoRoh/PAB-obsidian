# SSOT — Master Plan

## 1. Master Plan 작성 시 필수 체크리스트 (CRITICAL)

새 Master Plan을 작성할 때 **아래 항목을 모두 수행해야 한다**. 누락 시 CRITICAL 규칙 위반이다.

### 1.1 사전 점검 (Master Plan 작성 전)

| # | 점검 항목 | 근거 규칙 | 조치 |
|---|----------|----------|------|
| 1 | 리팩토링 레지스트리 로드 | **REFACTOR-2** | `docs/SSOT/WORKFLOW/refactoring/refactoring-registry.md` Read → 700줄 초과 파일 확인 |
| 2 | 이전 Phase 이관 항목 확인 | **CHAIN-11** | 이전 final-summary-report.md의 이관 항목 반영 여부 확인 |
| 3 | 기존 파일 패턴 Glob | **CHAIN-10 / HR-4** | `docs/phases/phase-*-master-plan.md` Glob → 동일 경로에 생성 |

### 1.2 Master Plan 본문 필수 포함 항목

| # | 포함 항목 | 근거 규칙 |
|---|----------|----------|
| 1 | HR-5 리팩토링 점검 결과 섹션 | **REFACTOR-2** — 700줄 초과 시 Lv1 분리 편성, 없으면 "해당 없음" 명시 |
| 2 | 모든 Sub-Phase에 게이트 명시 (G1~G4) | **CHAIN-7** |
| 3 | Task 도메인 태그 + 담당 역할 | **ASSIGN-1** — `entrypoint.md` §3.8 도메인 태그 표 |
| 4 | 완료 보고서 작성 계획 | **CHAIN-11** — `phase-{N}-final-summary-report.md` |

### 1.3 사후 검증

- Master Plan 초안 작성 후 **§1.1 사전 점검 · §1.2 본문 필수 항목과 대조**
- planner가 초안을 검토해 의견을 결과 파일로 낸다(`handoff/planning.md` §1). 반영 여부는 Team Lead가 정한다
- 누락 항목 발견 시 Master Plan에 보완 후 진행
