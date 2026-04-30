# ver6-0 — 폴더·파일 구조 설명

> **버전**: 1.2 | **작성일**: 2026-04-16 | **최종 갱신**: 2026-04-16 (AutoCycle v1.1 Phase-I 반영)
> **대상 SSOT**: v8.2-renewal-6th (AutoCycle v1.1, Phase-E/F/G/H/I 반영)
> **목적**: ver6-0 리포지토리 내 모든 폴더·파일의 **위치·역할·연결 관계·로딩 시점**을 한 화면에서 조회
> **근거**: Phase-E(DEV 분할) / Phase-F(GUIDES 이관) / Phase-G(AutoCycle Foundation) / Phase-H(AutoCycle Hardening) 이후 상태

---

## 1. 최상위 구조

```
ver6-0/
├── docs/                   # SSOT 본체 (108 .md 파일)
├── scripts/                # 운영 스크립트 (마이그레이션·알림)
└── implementation_plan.md  # ver6-0 자체 구현 계획 (6세대 도입)
```

| 최상위 | 용도 | 외부 편집 가능 여부 |
|--------|------|---------------------|
| `docs/` | SSOT 정의·규칙·역할·템플릿·Phase 산출물 | SSOT 변경 시 Phase 트랙 필수 |
| `scripts/` | DB 마이그레이션 SQL·백필 Python·Telegram 알림 | 인프라 작업자가 편집 |
| `implementation_plan.md` | 6세대(SUB-SSOT 모듈형 로딩) 도입 계획 히스토리 | 완료 후 수정 없음 |

---

## 2. `docs/` — SSOT 본체

### 2.1 진입점·코어 (루트 수준, 6파일 + GUIDE + VERSION)

| 파일 | 라인 | 역할 | 누가 읽는가 |
|------|------|------|-------------|
| `0-entrypoint.md` | 654 | 모든 세션의 **진입점** · 역할별 스폰 컨텍스트 주입 표 · §7.5 SUB-SSOT 라우팅 | Team Lead (최초 1회 필수), 모든 역할 FRESH-1 |
| `1-project.md` | 624 | 프로젝트 정의 · 팀 구성 · 라이프사이클 · 병렬 처리 정책 | Team Lead, planner, 신규 합류 역할 |
| `2-architecture.md` | 424 | 인프라 · BE/FE 구조 · DB 스키마 · §2 BE, §3 FE | backend-dev, frontend-dev, research-architect |
| `3-workflow.md` | 992 | 상태 머신(20개) · G0~G4 게이트 · Phase Chain · AUTO_FIX · AB_COMPARISON · DESIGN_REVIEW | 모든 역할 (공통 프로토콜) |
| `4-event-protocol.md` | 213 | JSONL 이벤트 로그 · Heartbeat (5th 확장) | backend/frontend-dev, tester |
| `5-automation.md` | 319 | Artifact Persister · AutoReporter · DecisionEngine (5th 확장) | Team Lead, verifier |
| `GUIDE.md` | (개요) | SSOT 전체 네비게이션 허브 · 역할 매핑표 · 6세대 구조 가이드 | 신규 사용자, SSOT 개편 시 |
| `VERSION.md` | (변경이력) | 버전 관리 · 변경 이력 · 토큰 효율성 비교표 | SSOT 갱신 시 필수 갱신 |
| `STRUCTURE.md` | (본 문서) | 구조 설명 (2026-04-16 신설) | 전체 조회용 |

### 2.2 `core/` — 공통 레이어 (3파일)

| 파일 | 라인 | 역할 |
|------|------|------|
| `6-rules-index.md` | ~450 | **규칙 ID 통합 인덱스** (v1.2) — 95개 규칙. HR-1~8, CHAIN-1~13, ITER-PRE/POST, ITERATION-BUDGET, ASSIGN, NOTIFY, FRESH, LIFECYCLE 등 |
| `7-shared-definitions.md` | ~410 | **공통 포맷** (v1.1) — GATE, ROLE_CHECK, 승인 프로토콜(10종), VAL 포맷, VUL 체크리스트, 충돌 분류, 예외 4조항, **§8 ITERATION-BUDGET** |
| `README.md` | — | core/ 폴더 용도 설명 |

### 2.3 `SUB-SSOT/` — 모듈형 로딩 레이어 (18파일 = 인덱스 + 6 SUB-SSOT)

```
SUB-SSOT/
├── 0-sub-ssot-index.md             # 라우팅 테이블 (v1.1 — 6 SUB-SSOT 등록)
├── DEV/            (v1.1)          # CODER 전용 (backend-dev, frontend-dev)
│   ├── 0-dev-entrypoint.md         # 로딩 체크리스트 + §6 Heartbeat
│   ├── 1-fn-procedure.md           # PHASE 0~7 + §8 에러 패턴 + §9 FE 패턴 + §10 AUTO_FIX + §11 실전 예제
│   ├── 2-ai-execution-rules.md     # CODER 페르소나 (REVIEWER·VALIDATOR는 포인터만)
│   └── 3-failure-modes.md          # 24개 PROBLEM-* (CODER 인식용 · Fix는 VERIFIER/TESTER 참조)
├── PLANNER/        (v1.1)          # planner
│   ├── 0-planner-entrypoint.md
│   └── 1-planning-procedure.md     # Task 분해 + 출력 형식 + 병렬 Phase + 5th 확장 연계
├── VERIFIER/       (v1.1)          # verifier = REVIEWER 역할
│   ├── 0-verifier-entrypoint.md    # REVIEWER 페르소나 Scope/Rules/Forbidden
│   └── 1-verification-procedure.md # plan-first review + 컨텍스트 분리 + 8항목 체크리스트 + PARTIAL + Council 상세
├── TESTER/         (v1.1)          # tester = VALIDATOR 역할
│   ├── 0-tester-entrypoint.md      # VALIDATOR 페르소나 + inotifywait
│   └── 1-testing-procedure.md      # 증거 기반 감사 + VAL 포맷 + FAIL_COUNTER + G3 실행 + 시나리오별 명령 A~E + AB_COMPARISON + 결함 분류 (심각도 4+유형 5+필드 7)
├── RESEARCH/       (v1.0, Phase-E) # 3역할 독립 주입
│   ├── 0-research-entrypoint.md    # 공용 (진입 조건·Hub-and-Spoke·G0·산출물·15분 SLA)
│   ├── 1-lead-procedure.md         # 범위 정의·팀 조율·통합 (Explore/opus)
│   ├── 2-architect-procedure.md    # 영향도 분석·PoC 설계 (Explore/opus)
│   └── 3-analyst-procedure.md      # 벤치마크·정량 비교 (Explore/sonnet, WebSearch/WebFetch)
└── TEAM-LEAD/      (v1.2)          # Team Lead (메인 세션, AutoCycle 확장)
    ├── 0-lead-entrypoint.md
    └── 1-orchestration-procedure.md  # +§ITER-PRE/POST +G-Pre +CHAIN-12/13 +G4 verifier
```

**로딩 원칙**:
- 공통: `core/7-shared-definitions.md` (7K) + 해당 SUB-SSOT entrypoint (3K)
- 필수: 역할 procedure (3~10K)
- 선택: 상황별 추가 파일

**토큰 합계 (추정, v1.1 기준)**:

| 역할 | 로딩 | 토큰 |
|------|------|------|
| CODER (fn 기본) | 7-shared + DEV 0·1 | ~18K |
| CODER (fn 풀) | 7-shared + DEV 0~3 | ~27K |
| Planner | 7-shared + PLANNER 0·1 | ~13K |
| Verifier | 7-shared + VERIFIER 0·1 | ~17K |
| Tester | 7-shared + TESTER 0·1 | ~16.5K |
| Research (역할당) | 7-shared + RESEARCH 0 + 해당 절차 | ~14K |
| Team Lead | 코어 0~5 + TEAM-LEAD 0·1 + 인덱스 | ~38K |

### 2.4 `PERSONA/` — 마인드셋 레이어 (교체 가능, 10파일)

| 파일 | 용도 |
|------|------|
| `LEADER.md` / `PLANNER.md` / `BACKEND.md` / `FRONTEND.md` / `QA.md` | 기본 페르소나 (각 역할 Charter 1차 덮어쓰기용) |
| `RESEARCH_LEAD.md` / `RESEARCH_ARCHITECT.md` / `RESEARCH_ANALYST.md` | Research 3역할 페르소나 |
| `README.md` | 교체 원칙 설명 |

원칙: **ROLES/\*.md = 불변 실행 가이드**, **PERSONA/\*.md = 교체 가능 마인드셋**. 스폰 시 PERSONA가 Charter를 덮어씀.

### 2.5 `ROLES/` — 역할 정의 정본 (11파일)

| 파일 | 역할 | SUB-SSOT |
|------|------|----------|
| `team-lead.md` | Team Lead (메인 세션) | TEAM-LEAD/ |
| `planner.md` | planner | PLANNER/ |
| `backend-dev.md` / `frontend-dev.md` | CODER 2인 | DEV/ |
| `verifier.md` | REVIEWER (v1.1 통합) | VERIFIER/ |
| `tester.md` | VALIDATOR (v1.1 통합) | TESTER/ |
| `research-lead.md` / `research-architect.md` / `research-analyst.md` | Research 3역할 | RESEARCH/ |
| `README.md` | 역할 매핑표 + 페르소나 교체 원칙 |

### 2.6 `QUALITY/` — Verification Council (1파일)

| 파일 | 용도 |
|------|------|
| `10-persona-qc.md` | **11명 Verification Council** (5th Multi-perspective) — Security/Performance Expert(비토), Architecture, Data, Test, UX, Accessibility, Code Style 등 |

### 2.7 `TEMPLATES/` — 보고서·로그 양식 (11파일 = 기존 6 + AutoCycle 5)

| 파일 | 용도 |
|------|------|
| `task-report-template.md` | Phase X-Y reports/report-{role}.md 표준 (작업 내용/결과/테스트/위험/추천 5섹션) |
| `research-report-template.md` | G0용 리서치 보고서 (범위·대안 비교·영향도·리스크·추천·G0 준비) |
| `ab-comparison-template.md` | AB_COMPARISON 상태 비교 리포트 |
| `decision-log-template.md` | 의사결정 기록 |
| `defect-report-template.md` | 결함 보고 (Defect ID·심각도·유형·재현·기대·실제·환경 7필드) |
| `event-log-template.md` | JSONL 이벤트 로그 스키마 |
| `development-plan-template.md` | **AutoCycle Step 3** — KPI 수치화 · 사용자/개발자 관점 · 사전 반복 이력 (Phase-G) |
| `prompt-alignment-check.md` | **AutoCycle Step 5** — 원본 프롬프트 vs 계획/구현 문장별 매핑 (Phase-G) |
| `phase-achievement-report.md` | **AutoCycle Step 8** — KPI 초기값 vs 달성값 · 수정계획서 (Phase-G) |
| `tech-debt-report.md` | **AutoCycle Step 12** — 수정 불가 항목 · carryover_to · CHAIN-12 자동 로딩 (Phase-G + Phase-H) |
| `master-final-report.md` | **AutoCycle Step 13~14** — 6섹션 최종 보고서 · Next Prompt · verifier 승인 · 피드백 (Phase-G + Phase-H) |

### 2.8 Phase 산출물 (`phases/`)

```
phases/
├── phase-E/                # Phase-E (DEV 3분할 + RESEARCH 신설, 2026-04-15 DONE)
│   ├── phase-E-status.md   # YAML 상태 (current_state, sub_phases, verifier_results)
│   ├── phase-E-plan.md     # 5-step 워크플로우 + 게이트 정의
│   ├── phase-E-todo-list.md
│   ├── checkpoints/        # 전체 1 + task 7 = 8 checkpoints (CP-{영역}.{번호})
│   ├── tasks/              # 7 task spec
│   └── scratchpad/         # 5 샘플 (Step 3a 산출물)
├── phase-F/                # Phase-F (GUIDES → SUB-SSOT 이관, 2026-04-15 DONE)
│   ├── phase-F-status.md
│   └── diff-analysis.md    # 6 GUIDES × SUB-SSOT 섹션별 판정표 (10장)
├── phase-G/                # Phase-G (AutoCycle Foundation, 2026-04-16 DONE)
│   └── phase-G-status.md   # 8 sub-task DONE, verifier #2 PASS
├── phase-H/                # Phase-H (AutoCycle Hardening, 2026-04-16 DONE)
│   ├── phase-H-status.md   # 6 sub-task DONE, verifier #4 PASS, 14/14 FULL COVERAGE
│   ├── phase-H-plan.md
│   ├── phase-H-todo-list.md
│   └── tasks/              # 6 task spec (H-1~H-6)
├── phase-I/                # Phase-I (AutoCycle Pre-draft Gate, 2026-04-16 진행 중)
│   ├── phase-I-status.md
│   ├── phase-I-plan.md
│   ├── phase-I-todo-list.md
│   └── tasks/              # 5 task spec (I-1~I-5)
├── pre/                    # Master Plan 이전 산출물 (2026-04-16 Phase-I I-1 신설)
│   ├── phase-{N}-pre-analysis.md  # ANALYSIS-1 사전 분석 (기존 루트 → pre/로 이전)
│   └── phase-{N}-pre-draft.md     # Step 0 Pre-draft (사용자 주도 한정, /plan 스킬 산출)
├── phase-G-master-plan.md      # Phase-G 마스터 플랜
├── phase-H-master-plan.md      # Phase-H 마스터 플랜
├── phase-I-master-plan.md      # Phase-I 마스터 플랜
├── phase-chain-autocycle.md    # AutoCycle 체인 마스터 (Phase-G → Phase-H)
├── phase-chain-autocycle-final-report.md  # AutoCycle v1.0 체인 종료 보고
├── autocycle-initial-requirements.md  # 사용자 원본 요구사항 보존
├── autocycle-kpi-targets.md    # 개발 완료 KPI 목표치 (SMART)
└── autocycle-completion-checklist.md  # 체인 종료 점검 지침
```

**Phase 디렉토리 규칙 (CHAIN-10, HR-4)**:
- `master-plan.md`, `phase-chain-*.md`, `final-summary-report.md` → `docs/phases/` 루트
- `status.md`, `plan.md`, `todo-list.md`, `tasks/`, `checkpoints/`, `scratchpad/` → `phase-{N}-{M}/` 하위
- `pre-analysis.md`, `pre-draft.md` → **`docs/phases/pre/` 평탄 폴더** · 파일명 `phase-{N}-pre-xxx.md` 강제 (2026-04-16 Phase-I I-1 신설)
- **pre-draft**는 사용자 주도 마스터 플랜(`initiator: user`) 진입 시에만 생성 — AI handoff 시 자동 생략

### 2.9 `_backup/` — 레거시 보존 (Phase 이동 이력)

```
_backup/
├── README.md
├── GUIDES/                         # Phase-F 이관으로 6파일 이동 (2026-04-15)
│   ├── backend-work-guide.md       # → SUB-SSOT/DEV/
│   ├── frontend-work-guide.md      # → SUB-SSOT/DEV/
│   ├── planner-work-guide.md       # → SUB-SSOT/PLANNER/
│   ├── verifier-work-guide.md      # → SUB-SSOT/VERIFIER/
│   ├── tester-work-guide.md        # → SUB-SSOT/TESTER/
│   ├── research-work-guide.md      # → SUB-SSOT/RESEARCH/
│   └── DEV-work-guide/             # Phase-E 이관 (5파일) — 6세대 DEV SUB-SSOT 소스 원본
│       ├── 0-workflow-system-overview.md
│       ├── 1-Feature-Development-Standard-Operating-Procedure.md
│       ├── 2-ai-harness-dev-procedure.md
│       ├── 3-dev-problem-analysis.md
│       └── 4-fn-dev-field-procedure-v1.md
├── ab-test/ (5)                    # 초기 AB 테스트 자료 (2026-04-14 이동)
├── vision-appendix/ (3)            # KPI·리스크 매트릭스·비교표 (SSOT 자체 버전업용)
├── reports/                        # 레거시 리포트 (현재 비어있음)
└── ssot-template/                  # copier 파이프라인 (미운영, 참조용)
    ├── README.md
    └── template/
        ├── core/
        └── project/
```

**원칙**: 삭제하지 않고 이동. 롤백·히스토리 참조 가능. SSOT 본체 참조는 `_backup/` 경로를 사용해 "레거시"임을 명시.

### 2.10 기타 보조 디렉토리

| 폴더 | 파일 | 용도 |
|------|------|------|
| `infra/` | `git-subtree-guide.md` | Git subtree 사용 가이드 |
| `mcp-design/` | `mcp-server-design.md` | MCP 서버 설계 초안 |
| `refactoring/` | `refactoring-registry.md` / `refactoring-rules.md` | REFACTOR-1~3 규칙 · 500줄 초과 파일 레지스트리 (HR-5) |
| `tests/` | `index.md` / `test-phase-mapping.md` / `test-suite-report.md` / `test-tuning-guide.md` | 시나리오 A~I별 pytest 매핑 · Phase별 테스트 목록 |

---

## 3. `scripts/` — 운영 스크립트

```
scripts/
├── pmAuto/
│   └── report_to_telegram.sh       # HR-8 NOTIFY-1 — Phase DONE 시 Telegram 알림
└── migrations/
    ├── README.md                   # 마이그레이션 개요 (003·004·_applied 포함)
    ├── __init__.py
    ├── 001_add_gin_indexes.sql     # PostgreSQL GIN 인덱스 (전문검색)
    ├── 002_create_page_access_log.sql
    ├── 003_create_system_settings.sql
    ├── 004_create_users_table.sql
    └── _applied/                   # 1회성 백필 (Phase 32-3)
        ├── backfill_titles_display_ids.py
        └── update_qdrant_payload.py
```

---

## 4. 파일 찾기 빠른 조회

| 찾을 정보 | 경로 |
|-----------|------|
| **Team Lead가 처음 읽어야 할 문서** | `docs/0-entrypoint.md` §7·§7.5 |
| **규칙 ID (HR-1, CHAIN-5, ITER-PRE 등) 조회** | `docs/core/6-rules-index.md` (v1.2, 95개 규칙) |
| **GATE/VAL/승인 포맷 + ITERATION-BUDGET** | `docs/core/7-shared-definitions.md` (v1.1, §8 토큰 상한) |
| **역할별 스폰 시 로딩할 파일 세트** | `docs/0-entrypoint.md §역할별 스폰 컨텍스트 주입` |
| **SUB-SSOT 라우팅 테이블** | `docs/SUB-SSOT/0-sub-ssot-index.md` |
| **Phase 상태 머신 (20개)** | `docs/3-workflow.md §3` |
| **G0~G4 게이트 정의** | `docs/3-workflow.md §4` |
| **Research 3역할 절차** | `docs/SUB-SSOT/RESEARCH/` |
| **REVIEWER 8항목 체크리스트** | `docs/SUB-SSOT/VERIFIER/1-verification-procedure.md` |
| **pytest 시나리오별 명령 (A~E)** | `docs/SUB-SSOT/TESTER/1-testing-procedure.md §시나리오별 명령` |
| **결함 분류 (심각도·유형·필드)** | `docs/SUB-SSOT/TESTER/1-testing-procedure.md §결함 분류 (ISTQB CTFL 4.0 기반)` |
| **Heartbeat 프로토콜** | `docs/SUB-SSOT/DEV/0-dev-entrypoint.md §6` |
| **AUTO_FIX 6가지 AND 조건** | `docs/SUB-SSOT/DEV/1-fn-procedure.md §10`, `SUB-SSOT/VERIFIER/1-verification-procedure.md §PARTIAL` |
| **11명 Verification Council** | `docs/QUALITY/10-persona-qc.md`, `SUB-SSOT/VERIFIER/1-verification-procedure.md §Council 코디네이션` |
| **Telegram 알림 스크립트** | `scripts/pmAuto/report_to_telegram.sh` |
| **리팩토링 레지스트리** | `docs/refactoring/refactoring-registry.md` |
| **레거시 GUIDES 원본** | `docs/_backup/GUIDES/{role}-work-guide.md` |

---

## 5. 역할별 스폰 시 로딩 파일 세트 (v1.1 기준)

| 역할 | 코어 | SUB-SSOT | ROLES | PERSONA | 기타 |
|------|------|----------|-------|---------|------|
| **Team Lead** | 0~5 | TEAM-LEAD/0·1 + 인덱스 | team-lead.md | LEADER.md | QUALITY/10-persona-qc.md |
| **planner** | 0·1·3 | PLANNER/0·1 | planner.md | PLANNER.md | TEMPLATES/ |
| **backend-dev (CODER)** | 2(BE)·3 + 7-shared | DEV/0·1 (+2·3 선택) | backend-dev.md | BACKEND.md | — |
| **frontend-dev (CODER)** | 2(FE)·3 + 7-shared | DEV/0·1 (+2·3 선택) | frontend-dev.md | FRONTEND.md | — |
| **verifier (REVIEWER)** | 3 + 7-shared | VERIFIER/0·1 | verifier.md | QA.md | QUALITY/ |
| **tester (VALIDATOR)** | 3 + 7-shared | TESTER/0·1 | tester.md | QA.md | tests/index.md |
| **research-lead** | 2·3 + 7-shared | RESEARCH/0 + 1-lead | research-lead.md | RESEARCH_LEAD.md | TEMPLATES/research-report-template.md |
| **research-architect** | 2·3 + 7-shared | RESEARCH/0 + 2-architect | research-architect.md | RESEARCH_ARCHITECT.md | — |
| **research-analyst** | 2·3 + 7-shared | RESEARCH/0 + 3-analyst | research-analyst.md | RESEARCH_ANALYST.md | — |

→ 상세: `0-entrypoint.md §역할별 스폰 컨텍스트 주입 (6th 모듈형 로딩)`

---

## 6. 상태 전환 시 핵심 문서

| 상태 (3-workflow.md §3) | 주도 역할 | 주 SSOT 참조 |
|--------------------------|-----------|---------------|
| `IDLE` → `TEAM_SETUP` | Team Lead | TEAM-LEAD/ |
| `RESEARCH` (5th) | research-lead | RESEARCH/ + GUIDES 레거시 |
| `RESEARCH_REVIEW` (G0) | Team Lead | 3-workflow.md §4.3 |
| `PLANNING` → `PLAN_REVIEW` (G1) | planner → Team Lead | PLANNER/ + TEMPLATES/ |
| `TASK_SPEC` | planner | PLANNER/1-planning-procedure.md |
| `BUILDING` | backend/frontend-dev | DEV/ |
| `VERIFYING` (G2) | verifier | VERIFIER/ + QUALITY/ |
| `AUTO_FIX` (5th) | verifier + dev | 5-automation.md §3.2 + VERIFIER/PARTIAL |
| `TESTING` (G3) | tester | TESTER/ + tests/index.md |
| `INTEGRATION` → `E2E` | Team Lead + tester | TESTER/ |
| `AB_COMPARISON` (5th) | tester | TESTER/ + TEMPLATES/ab-comparison |
| `DESIGN_REVIEW` (5th) | Team Lead | PLANNER/ §5th |
| `E2E_REPORT` → `TEAM_SHUTDOWN` → `DONE` | Team Lead | TEAM-LEAD/ + NOTIFY |

---

## 7. 버전 이력 (파일 기준)

- **v8.0** (2026-04-13): SUB-SSOT 모듈형 로딩 신설 (DEV/PLANNER/VERIFIER/TESTER/TEAM-LEAD)
- **v8.0.1** (2026-04-15 Phase-E): DEV 3분할, RESEARCH 신설 (4파일)
- **v8.0.1** (2026-04-15 Phase-F): GUIDES 6파일 → `_backup/GUIDES/`, SUB-SSOT 5역할 보강
- **v8.1** (2026-04-16 Phase-G+H): AutoCycle v1.0 — TEMPLATES 5종, 규칙 5건(ITER-PRE/POST, ITERATION-BUDGET, CHAIN-12/13), TESTER KPI-driven, 14단계 커버리지 100%
- **v8.2** (2026-04-16 Phase-I): AutoCycle v1.1 — Step 0 Pre-draft 게이트 신설, PROMPT-QUALITY 규칙(HIGH, 총 96건), `/plan` 스킬, `pre-draft-topics.md` 템플릿, `pre/` 평탄 폴더, Step-0 Branch 분기 로직, 15단계 커버리지 100%
- **v1.0 → STRUCTURE.md** (2026-04-16): 본 구조 설명 문서 신설
- **v1.1 → STRUCTURE.md** (2026-04-16): AutoCycle Phase-G+H 반영
- **v1.2 → STRUCTURE.md** (2026-04-16): AutoCycle Phase-I(v1.1) 반영 — §2.8 `pre/` 블록 확장, SSOT v8.2 표기

---

| **AutoCycle TEMPLATES (5종)** | `docs/TEMPLATES/development-plan-template.md` 외 4종 |
| **AutoCycle 체인 관리** | `docs/phases/phase-chain-autocycle.md` |
| **ITERATION-BUDGET (토큰 상한)** | `docs/core/7-shared-definitions.md §8` |
| **CHAIN-12 (Tech Debt 자동 로딩)** | `docs/TEMPLATES/tech-debt-report.md §5` + `1-orchestration §Phase Chain` |
| **CHAIN-13 (직전 3 Phase 기억)** | `docs/SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md §Phase Chain` |

---

**문서 관리**: v1.2, 2026-04-16. ver6-0 v8.2 기준 (AutoCycle v1.1 · Phase-I 반영). 이후 구조 변경 시 본 문서 갱신 필수.
