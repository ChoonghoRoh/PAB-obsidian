# SSOT 버전 관리 (6th iteration)

**통합 릴리스**: `v8.2-renewal-6th`
**릴리스 날짜**: 2026-04-13 (v8.0) / 2026-04-15 (v8.0.1) / 2026-04-16 (v8.1) / **최신 갱신: 2026-04-16 (v8.2 — AutoCycle v1.1 Phase-I)**
**전략**: **5th 기반 확장** — 5th 단독 사용 구조 유지 + SUB-SSOT 모듈형 로딩 아키텍처 + **AutoCycle 15단계 자동 handoff (사용자 주도 Step 0 Pre-draft 포함)**

**최근 변경 (2026-04-16 — Phase-I, v8.2 AutoCycle v1.1)**: 사용자 주도 마스터 플랜 진입 전 **Step 0 Pre-draft 게이트** 신설. PROMPT-QUALITY 규칙(HIGH) 등록 (완전성·명료성·실행 가능성·범위 적정성·트리아지 5항목 판정). `/plan` 스킬(.claude/skills/plan/SKILL.md, Plan Mode 유사, Team Lead 단독, 온디맨드 팀원 호출). master-plan YAML `initiator`·`prompt_quality`·`pre_draft_ref` 3필드 표준. `orchestration-procedure §Step-0 Branch` + 플로우차트 + 체크리스트. `master-final-report §7.3 initiator_hint` 필드. `docs/phases/pre/` 평탄 폴더 신설 (pre-analysis + pre-draft). **AI handoff는 14단계 유지 (Step 0 자동 스킵 + CHAIN-13 자동 로딩)**. 15단계 시뮬레이션 3 시나리오 커버리지 100%.

**이전 변경 (2026-04-16 — Phase-G+H, v8.1 AutoCycle v1.0)**: 14단계 개발 요청 자동 사이클(handoff) 지원. Phase-G(Foundation): TEMPLATES 5종 신설 + ITER-PRE/POST 규칙 2건 + TESTER KPI-driven. Phase-H(Hardening): G-Pre 수렴 게이트 + ITERATION-BUDGET 500K + CHAIN-12(Tech Debt 자동 로딩) + CHAIN-13(직전 3 Phase 기억 전달) + verifier 승인 훅 + 사용자 피드백 필드. 14단계 커버리지 14/14 (100%).

**이전 변경 (2026-04-15 — Phase-E, v8.0.1)**: ver6-0 개선 과제 — DEV SUB-SSOT 3분할 (CODER 전용 축소 + REVIEWER → VERIFIER + VALIDATOR → TESTER 이관) + RESEARCH SUB-SSOT 신설 (Lead/Architect/Analyst 3역할 분리). 역할별 SUB-SSOT 비대칭 해소, Research 역할 독립 주입 가능.

**이전 변경 (2026-04-13 — v8.0)**: 6세대 SUB-SSOT 모듈형 로딩 도입 — 역할별 SUB-SSOT(DEV/PLANNER/VERIFIER/TESTER/TEAM-LEAD) 분리, 공통 레이어(core/7-shared-definitions.md) 신설, FRESH-10~12 규칙 추가, 토큰 약 60% 절감.

---

## 릴리스 정보

| 항목 | 내용 |
|------|------|
| **버전** | 8.2-renewal-6th (6th iteration, AutoCycle v1.1) |
| **이전 버전** | 8.1-renewal-6th (AutoCycle v1.0) / 7.0-renewal-5th (5th) |
| **변경 사유** | AutoCycle 15단계 사용자 주도 Step 0 Pre-draft 게이트 신설 (v8.1→v8.2) + 역할별 모듈형 로딩 (v7→v8) |
| **핵심 원칙** | **5th 호환성 유지** — 5th 콘텐츠 전량 보존 + 6th SUB-SSOT 확장 레이어 + AutoCycle Pre-draft Gate |

---

## 5th → 6th 변경 요약

| 변경 항목 | 내용 |
|----------|------------|
| **+SUB-SSOT 아키텍처** | 역할별 독립 로딩 집합 (DEV/PLANNER/VERIFIER/TESTER/TEAM-LEAD) |
| **+공통 레이어** | `core/7-shared-definitions.md` — GATE, 역할, 승인, VUL 공통 포맷 |
| **+FRESH 규칙 3개** | FRESH-10(모듈형 로딩), FRESH-11(공통 레이어 필수), FRESH-12(독립 검증) |
| **+SUB-SSOT 인덱스** | `SUB-SSOT/0-sub-ssot-index.md` — 라우팅 테이블 |
| **+§7.5 라우팅** | 0-entrypoint.md에 SUB-SSOT 라우팅 섹션 추가 |
| **ssot_version** | `7.0-renewal-5th` → `8.0-renewal-6th` |

---

## Breaking Changes (5th → 6th)

| 변경 항목 | 변경 내용 |
|----------|----------|
| **ssot_version** | `7.0-renewal-5th` → `8.0-renewal-6th` — 기존 Phase status.md에서 버전 불일치 발생 |
| **SUB-SSOT 참조** | 각 역할 체크리스트에 SUB-SSOT 경로 참조 추가 — 기존 SSOT 사용자에게는 무영향 |
| **FRESH-10~12** | 신규 규칙 — SUB-SSOT 로딩 시에만 적용, 기존 전체 SSOT 로딩에는 무영향 |

---

## 6th 신규 파일 목록

| 경로 | 용도 |
|------|------|
| `core/7-shared-definitions.md` | 공통 포맷 정의 (GATE, 역할, 승인, VUL 체크리스트) |
| `SUB-SSOT/0-sub-ssot-index.md` | SUB-SSOT 라우팅 테이블·인덱스 |
| `SUB-SSOT/DEV/0-dev-entrypoint.md` | DEV 진입점 |
| `SUB-SSOT/DEV/1-fn-procedure.md` | fn 개발 절차 |
| `SUB-SSOT/DEV/2-ai-execution-rules.md` | AI 실행 규칙 |
| `SUB-SSOT/DEV/3-failure-modes.md` | 실패 모드 |
| `SUB-SSOT/PLANNER/0-planner-entrypoint.md` | Planner 진입점 |
| `SUB-SSOT/PLANNER/1-planning-procedure.md` | 계획 절차 |
| `SUB-SSOT/VERIFIER/0-verifier-entrypoint.md` | Verifier 진입점 |
| `SUB-SSOT/VERIFIER/1-verification-procedure.md` | 검증 절차 |
| `SUB-SSOT/TESTER/0-tester-entrypoint.md` | Tester 진입점 |
| `SUB-SSOT/TESTER/1-testing-procedure.md` | 테스트 절차 |
| `SUB-SSOT/TEAM-LEAD/0-lead-entrypoint.md` | Team Lead 진입점 |
| `SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md` | 오케스트레이션 절차 |
| `SUB-SSOT/RESEARCH/0-research-entrypoint.md` | Research 3역할 공용 진입점 (2026-04-15 Phase-E 신설) |
| `SUB-SSOT/RESEARCH/1-lead-procedure.md` | research-lead 절차 (2026-04-15 Phase-E 신설) |
| `SUB-SSOT/RESEARCH/2-architect-procedure.md` | research-architect 절차 (2026-04-15 Phase-E 신설) |
| `SUB-SSOT/RESEARCH/3-analyst-procedure.md` | research-analyst 절차 (2026-04-15 Phase-E 신설) |

---

## 5th 유지 파일 목록

| 경로 | 용도 |
|------|------|
| `0-entrypoint.md` | 진입점 (**수정**: §7.5 SUB-SSOT 라우팅, FRESH-10~12 추가) |
| `1-project.md` | 프로젝트·팀 구성·역할 |
| `2-architecture.md` | 인프라·BE/FE 구조·DB |
| `3-workflow.md` | 상태 머신(20개), 품질 게이트(G0~G4) |
| `4-event-protocol.md` | 이벤트 인프라 프로토콜 |
| `5-automation.md` | 자동화 파이프라인 |
| `PERSONA/` | 역할 페르소나 (9개 파일) |
| `ROLES/` | 역할 상세 규칙 (8개 파일) |
| `_backup/GUIDES/` | 작업지시 가이드 (2026-04-15 Phase-F에서 SUB-SSOT로 완전 이관, 6파일 backup 보존) |
| `QUALITY/` | 11명 Verification Council |
| `TEMPLATES/` | 문서 템플릿 |
| `core/6-rules-index.md` | 규칙 통합 인덱스 |
| `VERSION.md` | 본 문서 |

---

## 토큰 효율성 비교

| 시나리오 | 5th (현행) | 6th v8.0 (SUB-SSOT) | 6th v8.0.1 (Phase-E) | 절감율 (v8.0.1 기준) |
|----------|-----------|----------------------|----------------------|---------------------|
| fn 기본 개발 (CODER 전용) | ~61K | ~20K | **~18K** | **70%** |
| fn 풀 (CODER 전용) | ~61K | ~33K | **~27K** | **56%** |
| Planner | ~37K | ~13K | ~13K | 65% |
| Verifier (REVIEWER 통합) | ~44K | ~14K | **~17K** | 61% |
| Tester (VALIDATOR 통합) | ~38K | ~14K | **~16.5K** | 57% |
| Research Lead (신규 분리) | ~30K | — (GUIDES 공유) | **~14K** | **53%** |
| Research Architect (신규 분리) | ~30K | — (GUIDES 공유) | **~14K** | **53%** |
| Research Analyst (신규 분리) | ~30K | — (GUIDES 공유) | **~14K** | **53%** |
| Team Lead | ~35K | ~38K | ~38K | (허브) |

---

## 권장 사용

- **기본 진입점**: `0-entrypoint.md`
- **SUB-SSOT 사용**: [SUB-SSOT/0-sub-ssot-index.md](SUB-SSOT/0-sub-ssot-index.md) 라우팅 테이블 참조
- **SSOT 갱신 시**: 기존 0~5·ROLES·GUIDES·QUALITY 정답 유지 + SUB-SSOT 동기화

---

## 변경 이력

### v8.2 (AutoCycle Phase-I, 2026-04-16) — AutoCycle v1.1 (15단계 사용자 주도 확장)

- **신규**: `TEMPLATES/pre-draft-topics.md` — §1~§8 (원본·토픽·수집 자료·Pre-test·5항목 판정·마스터 플랜 진입 준비·Next Step·사용 지침)
- **신규**: `.claude/skills/plan/SKILL.md` — `/plan` 스킬 (Plan Mode 유사, Team Lead 단독, 온디맨드 팀원 호출)
- **신규**: `phase-chain-autocycle-v1.1.md` — v1.1 체인 마스터 (v1.0 `phase-chain-autocycle.md` 스냅샷 보존)
- **신규**: `docs/phases/pre/` 평탄 폴더 — `phase-{N}-pre-analysis.md` / `phase-{N}-pre-draft.md` 파일명 강제
- **변경**: `core/6-rules-index.md` v1.2 → v1.3 — §1.20 PROMPT-QUALITY (HIGH) 신설 (5항목: 완전성·명료성·실행 가능성·범위 적정성·트리아지), §1.18 ANALYSIS-1/2 경로 업데이트 (총 95 → 96건)
- **변경**: `SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md` v1.2 → v1.3 — §Step-0 Branch 신설 (사용자/AI 분기 플로우차트 + 체크리스트)
- **변경**: `TEMPLATES/master-final-report.md` — §7.3 `initiator_hint` 필드 (다음 마스터 플랜 진입 경로 추천)
- **변경**: `STRUCTURE.md` v1.1 → v1.2 — §2.8 `pre/` 블록 확장, SSOT 버전 표기 갱신
- **변경**: `3-workflow.md` §8.7 / §11 / §12 — pre-analysis·pre-draft 경로 개정
- **신규 규칙**: PROMPT-QUALITY (HIGH)
- **15단계 시뮬레이션**: 사용자 주도 / AI handoff / Fast-path 3 시나리오 전부 커버리지 100% (verifier #1 PASS)
- **진입 분기**: 사용자 주도(`initiator: user`) = 15단계 / AI handoff(`initiator: ai-handoff`) = 14단계 (Step 0 자동 스킵 + CHAIN-13 대체)
- **ssot_version**: `8.1` → `8.2` (minor upgrade, AutoCycle v1.0 → v1.1)
- **Phase 산출물**: `ver6-0/docs/phases/phase-I/` (status · plan · todo-list · 5 task specs) + `phase-I-master-plan.md` + `phase-I-final-summary-report.md` + `phases/pre/phase-I-pre-analysis.md`

### v8.1 (AutoCycle Phase-G+H, 2026-04-16) — 14단계 자동 handoff v1.0

- **신규**: `TEMPLATES/development-plan-template.md` — KPI 수치화·사용자/개발자 관점 2분법 (Step 3)
- **신규**: `TEMPLATES/prompt-alignment-check.md` — 원본 프롬프트 vs 계획/구현 diff 분석 (Step 5)
- **신규**: `TEMPLATES/phase-achievement-report.md` — KPI 달성 대조·수정계획 (Step 8)
- **신규**: `TEMPLATES/tech-debt-report.md` — 수정 불가 항목 문서화·carryover_to (Step 12)
- **신규**: `TEMPLATES/master-final-report.md` — 6섹션 최종 보고서 + Next Prompt + verifier 승인 (Step 13~14)
- **변경**: `SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md` v1.0 → v1.2 — §ITER-PRE(3회 반복 + G-Pre 수렴 게이트), §ITER-POST(2회 재계획), CHAIN-12(Tech Debt 자동 로딩), CHAIN-13(직전 3 Phase 기억 전달), G4 verifier 승인 훅
- **변경**: `SUB-SSOT/TESTER/1-testing-procedure.md` — §KPI-driven Test Plan 추가 (Step 10)
- **변경**: `core/7-shared-definitions.md` v1.0 → v1.1 — §8 ITERATION-BUDGET (사이클 토큰 상한 500K)
- **변경**: `core/6-rules-index.md` v1.1 → v1.2 — ITER-PRE, ITER-POST, ITERATION-BUDGET, CHAIN-12, CHAIN-13 (신규 5건, 총 95개 규칙)
- **신규 규칙**: ITER-PRE(CRITICAL), ITER-POST(CRITICAL), ITERATION-BUDGET(CRITICAL), CHAIN-12(HIGH), CHAIN-13(HIGH)
- **14단계 커버리지**: 14/14 (100%) — 가상 시뮬레이션 dry-run PASS
- **ssot_version**: `8.0.1` → `8.1` (minor upgrade, AutoCycle runtime 동작 영향)

### v8.0.1 (Phase-E, 2026-04-15) — ver6-0 개선 과제

- **신규**: `SUB-SSOT/RESEARCH/` 디렉토리 4파일 (`0-research-entrypoint.md`, `1-lead-procedure.md`, `2-architect-procedure.md`, `3-analyst-procedure.md`) — 3역할(research-lead/architect/analyst) 독립 주입 가능
- **변경**: `SUB-SSOT/DEV/` v1.0 → v1.1 — CODER 전용으로 축소. REVIEWER 페르소나·plan-first review·컨텍스트 분리는 VERIFIER로, VALIDATOR 페르소나·VAL 포맷·FAIL_COUNTER는 TESTER로 이관
- **변경**: `SUB-SSOT/VERIFIER/` v1.0 → v1.1 — REVIEWER 페르소나 Scope/Rules/Forbidden 확장, plan-first review·컨텍스트 분리 신규 섹션, REVIEWER 실패 모드 대응(PROBLEM-BE-04, DB-03, PROC-06) 통합
- **변경**: `SUB-SSOT/TESTER/` v1.0 → v1.1 — VALIDATOR 페르소나 확장, 증거 기반 감사·VAL 포맷·FAIL_COUNTER 신규 섹션, VALIDATOR 실패 모드 대응(PROBLEM-PROC-05, CTX-07) 통합
- **변경**: `SUB-SSOT/DEV/3-failure-modes.md` — REVIEWER/VALIDATOR 소관 Fix 4건을 참조 축약 (MULTI 원칙: DEV는 CODER 인식용 유지 + VERIFIER/TESTER에 완화 관점 신규)
- **변경**: `0-entrypoint.md §역할별 스폰 주입 표` + `§7.5 라우팅` — DEV CODER 전용·VERIFIER REVIEWER 통합·TESTER VALIDATOR 통합·Research 3역할 분리 반영
- **변경**: `SUB-SSOT/0-sub-ssot-index.md` v1.0 → v1.1 — DEV/VERIFIER/TESTER 대상 갱신, RESEARCH 신규 행, 토큰 효율 표 갱신
- **변경**: `ROLES/README.md` — verifier/tester에 REVIEWER/VALIDATOR 책임 명시, research-* 역할에 SUB-SSOT 경로 추가
- **출처**: `docs/analysis/260414-ver6-0-audit-followup.md §6.5 #17, #19` 사용자 결정
- **Phase 산출물**: `ver6-0/docs/phases/phase-E/` — status, plan, todo-list, 8 checkpoints, 7 task specs, scratchpad
- **ssot_version**: `8.0-renewal-6th` 유지 (sub-version 8.0.1)

### v8.0-renewal-6th (2026-04-13)
- **신규**: SUB-SSOT 모듈형 로딩 아키텍처 (5개 역할 SUB-SSOT)
- **신규**: `core/7-shared-definitions.md` (공통 포맷 레이어)
- **신규**: `SUB-SSOT/0-sub-ssot-index.md` (라우팅 인덱스)
- **신규**: FRESH-10, FRESH-11, FRESH-12 규칙
- **변경**: `0-entrypoint.md` (§7.5 SUB-SSOT 라우팅, 역할별 SUB-SSOT 참조)
- **변경**: ssot_version `7.0-renewal-5th` → `8.0-renewal-6th`
- **유지**: 5th 전체 콘텐츠 보존 (하위 호환)

### v7.0-renewal-5th (2026-02-28)
- **신규**: 상태 머신 6개 상태 추가 (RESEARCH, RESEARCH_REVIEW, BRANCH_CREATION, AUTO_FIX, AB_COMPARISON, DESIGN_REVIEW)
- **신규**: G0 Research Review 게이트
- **신규**: Research Team 3역할
- **신규**: `4-event-protocol.md`, `5-automation.md`
- **신규**: `QUALITY/10-persona-qc.md` (11명 Verification Council)
- **신규**: `TEMPLATES/`
- **변경**: status.md 스키마에 `5th_mode` 필드 추가
- **변경**: ssot_version `6.0-renewal-4th` → `7.0-renewal-5th`
- **유지**: 4th 전체 콘텐츠 보존

### v6.0-renewal-4th (2026-02-17)
- **신규**: iterations/4th 폴더, 0-entrypoint·1-project·2-architecture·3-workflow
- **신규**: ROLES/planner.md, _backup/GUIDES/planner-work-guide.md
- **신규**: 3-workflow.md §8 Phase Chain
- **신규**: PERSONA/ 5종
- **변경**: 팀 라이프사이클 §3.9 루프 명시
- **변경**: Charter 링크 PERSONA/*.md 변경
- **제거**: 모든 claude/ 참조

---

**문서 관리**: 버전 8.2-renewal-6th (AutoCycle v1.1), 단독 사용(6th 세트만으로 SSOT 완결, 5th 전량 보존+SUB-SSOT 확장+AutoCycle Pre-draft Gate)
