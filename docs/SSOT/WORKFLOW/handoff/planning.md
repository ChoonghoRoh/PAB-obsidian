# 단계 단위 — PLANNING (planner)

## 1. 결과 전달

planner는 쓰기 권한이 없다(EDIT-4, REPORT-1 결과 파일만 예외). 계획 분석 결과는 결과 파일에 기록하고 SendMessage로 요지 · 경로를 Team Lead에게 보내며, Team Lead가 plan · todo-list · tasks 파일을 만든다.

Team Lead는 planner 업무 지시에 현재 `SSOT 버전`(entrypoint 머리)을 적는다. planner는 이를 status.md `ssot_version`과 대조한다.

**planner 상주 · 역할 분담**: planner는 PLANNING에 스폰되어 G4 입력(계획서 이행 점검)을 낼 때까지 Phase 동안 상주한다. 상주 중 대기는 할당 상태로 본다(LIFECYCLE-1 · 2 예외 — `WORKFLOW/workflow.md` §AGENT-LIFECYCLE).

| 담당 | 하는 일 |
|------|---------|
| planner | 계획 초안 · pre-draft와 master plan 검토 · 기능 · 트렌드 벤치마크 · DESIGN_REVIEW 검토 의견 · Team Lead 자문 · 계획서 이행 점검(`CORE/shared-definitions.md` §6.3 VUL3-01~05 — 충족 · 미충족 · 이탈 표, 판정 문구 없음) |
| Team Lead | 사용자 대화 · 결정 수렴 · 파일 확정 · 게이트 판정(G1 · G4 포함) |

## 2. G1 판정 기준

| 게이트 | 판정 기준 | 결과 |
|--------|----------|------|
| **G1** | ① 완료 기준 명확(명령 · 수치 · 산출물로 검증 가능) ② Task 3~7개 · 도메인별 균형 · 담당 팀원 지정(ASSIGN-1) ③ 도메인 분류 완료(`[BE]` `[DB]` `[DS]` `[FE]` `[FS]` `[TEST]` `[INFRA]` `[DOC]`) ④ 리스크 식별 · 대응 또는 수용 명시 ⑤ 백엔드: API Spec 확정, DB 스키마 정의 ⑥ 프론트엔드: 페이지 구조 · 동선 정의, 기존 컴포넌트 활용 방향 ⑦ 정본 컴포넌트 목록: `[FE]` `[DS]` `[FS]` Task마다 정본 목록 또는 신규 선택(`LEAD_SELECTED`) 항목(REUSE-3) ⑧ DESIGN_REVIEW 필요 여부(Team Lead가 복잡도로 판단) ⑨ planner가 적은 KPI · 대조표 명령은 Team Lead가 BASE로 한 번 실행해 기대값과 대조한다(`ROLES/SUB-SSOT/PLANNER/planning-procedure.md` — planner는 명령을 적기만 한다) | PASS → TASK_SPEC(DESIGN_REVIEW가 필요하면 DESIGN_REVIEW) / FAIL → REWINDING → PLANNING |

- 이 표가 G1 판정 기준의 정본이다. planner는 이 기준으로 자가 점검한 결과를 내고, 판정은 Team Lead가 한다. `ROLES/planner.md` · `ROLES/SUB-SSOT/PLANNER/planning-procedure.md`는 이 표를 인용한다(LOCK-6).

## 3. Task 분해 — CL 크기 기준

#### CL 크기 권장 기준

Google CL Review 베스트 프랙티스 기반, Task 단위 변경 크기를 제한한다:

| 크기 | 줄 수 | 판정 | 조치 |
|------|------:|:----:|------|
| Small | ~100줄 | 권장 | 빠른 리뷰 가능 |
| Medium | 100~300줄 | 허용 | 일반적 Task 크기 |
| Large | 300~500줄 | 주의 | 분할 가능 여부 검토 |
| Too Large | 500줄+ | 경고 | Task 분할 필수 (HR-5) |

## 4. [DS] Task 순서

UI가 있는 기능은 `[DS]` Task를 관련 `[FE]` Task보다 앞에 두고, `[FE]` Task의 `depends_on`에 그 `[DS]` Task를 적는다.
