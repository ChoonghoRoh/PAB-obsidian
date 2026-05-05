---
title: "PAB SSOT v8.2-renewal-6th — 진입점·버전·3계층 아키텍처 개요"
description: "Personal AI Brain v3 운영용 SSOT의 진입점·버전 트리·전체 폴더 구조·역할별 모듈형 로딩 가이드. v8.2 AutoCycle v1.1까지 누적, 코어 SSOT 0~5 + 공통 레이어 + 역할별 SUB-SSOT의 3계층"
created: 2026-05-05 05:13
updated: 2026-05-05 05:13
type: "[[RESEARCH_NOTE]]"
index: "[[KNOWLEDGE_MGMT]]"
topics: ["[[PAB_SSOT]]", "[[SSOT_ENTRYPOINT]]", "[[MODULAR_LOADING]]"]
tags: [research-note, pab-ssot-nexus, ssot, entrypoint, v8-2-renewal-6th]
keywords: ["SSOT", "v8.2-renewal-6th", "0-entrypoint", "FRESH", "ENTRY", "LOCK", "SUB-SSOT", "Hub-and-Spoke", "Team Lead", "토큰 절감", "AutoCycle"]
sources:
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/0-entrypoint.md"
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/VERSION.md"
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/STRUCTURE.md"
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/GUIDE.md"
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/1-project.md"
aliases: ["SSOT 진입", "SSOT 6세대 진입", "ver6-0 진입점"]
---

# PAB SSOT v8.2-renewal-6th — 진입점과 6세대 모듈형 로딩

## SSOT란 무엇인가

**SSOT(Single Source of Truth)** — Claude Code Agent Teams 운영을 위한 **단일 진실 공급원**. 메인 세션이 [[Team Lead]]로서 팀을 생성·조율·판정·해산하고, 팀원은 역할별 Charter([[PERSONA]] 페르소나)를 기반으로 병렬·협업 작업을 수행한다. 모든 Phase는 **상태 기반 워크플로우**(20개 상태)로 진행된다.

본 SSOT는 [[Personal AI Brain v3]] 프로젝트(Docker Compose 기반 로컬 AI 브레인 — 문서 벡터화·의미 검색·AI 응답·지식 구조화·Reasoning) 운영을 1차 대상으로 한다. 본 디렉토리(`~/WORKS/PAB-SSOT-Nexus/docs/SSOT/`) 안에서 **단독 사용 가능**(다른 SSOT 폴더 참조 불필요).

**왜 단일?** Phase Chain·역할 분담·게이트 판정·상태 전이 같은 운영 규칙이 여러 곳에 흩어지면 결국 충돌·드리프트가 생긴다. SSOT는 **읽기 전용 정본**으로 두고, 모든 팀원·세션이 진입 시 동일한 버전을 로드하도록 강제한다(FRESH-1, ENTRY-1).

## 버전 트리 — 4세대 → 5세대 → 6세대 → AutoCycle

| 버전 | 시점 | 핵심 변경 |
|---|---|---|
| **v6.0-renewal-4th** | 2026-02-17 | 4세대 — 진입점·1-project·2-architecture·3-workflow + Phase Chain + PERSONA 5종 + claude/ 참조 제거 |
| **v7.0-renewal-5th** | 2026-02-28 | 5세대 — RESEARCH 상태 + G0 게이트 + Research Team 3역할 + 4-event-protocol + 5-automation + 11명 Verification Council + 상태머신 14→20개 |
| **v8.0-renewal-6th** | 2026-04-13 | 6세대 — SUB-SSOT 모듈형 로딩 + `core/7-shared-definitions.md` 공통 레이어 + FRESH-10~12 (토큰 60% 절감) |
| **v8.0.1** | 2026-04-15 (Phase-E) | DEV 3분할 (CODER 전용 축소 + REVIEWER → VERIFIER + VALIDATOR → TESTER 이관) + RESEARCH SUB-SSOT 신설 |
| **v8.1** | 2026-04-16 (Phase-G+H) | **AutoCycle v1.0** — 14단계 자동 handoff. TEMPLATES 5종 + ITER-PRE/POST + ITERATION-BUDGET 500K + CHAIN-12/13 |
| **v8.2** | 2026-04-16 (Phase-I) | **AutoCycle v1.1** — Step 0 Pre-draft 게이트 신설 + PROMPT-QUALITY 규칙(HIGH) + `/plan` 스킬 + `pre/` 평탄 폴더. 사용자 주도 15단계 / AI handoff 14단계 분기 |

**원칙**: 5세대 호환성 유지 — 5th 콘텐츠 전량 보존 + 6th SUB-SSOT 확장 레이어 + AutoCycle Pre-draft Gate.

## 3계층 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: CORE SSOT (0~5)                                    │
│ 0-entrypoint  1-project  2-architecture  3-workflow         │
│ 4-event-protocol  5-automation                              │
│ 대상: Team Lead 풀로드 (FRESH-1)                            │
│ 내용: 상태 머신 20개, G0~G4, Phase Chain, 팀 구조, 인프라    │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│ Layer 2: COMMON (core/7-shared-definitions.md)              │
│ §1 GATE 포맷 + ANTI-COMPRESSION                             │
│ §2 ROLE_CHECK + 역할 매핑 + 전환 금지                        │
│ §3 승인 프로토콜 10종                                        │
│ §4 산출물 포맷 (DEVIATION, VAL, FAIL_COUNTER)                │
│ §5 충돌 분류 Type A~E                                        │
│ §6 VUL 체크리스트 3종                                        │
│ §7 예외 4조항 (Hotfix/Minor/Pattern/POC)                     │
│ §8 ITERATION-BUDGET (500K 토큰 상한, AutoCycle)              │
│ 대상: 모든 SUB-SSOT 필수 동반 로딩 (FRESH-11)                │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│ Layer 3: SUB-SSOT (역할별 선택 로딩)                         │
│ DEV(4) · PLANNER(2) · VERIFIER(2) · TESTER(2)               │
│ TEAM-LEAD(2) · RESEARCH(4)                                  │
│ 대상: 해당 역할 세션에서만 로딩 (FRESH-10)                   │
│ 원칙: 공통 + SUB-SSOT만으로 독립 실행 가능 (FRESH-12)        │
└─────────────────────────────────────────────────────────────┘
```

상세는 [[2026-05-05_pab_ssot_architecture|아키텍처 노트]] 참조.

## 진입 절차 — FRESH·ENTRY·LOCK

세션을 시작할 때마다 강제되는 3종 규칙군:

### FRESH (12개) — 신선도 유지
- **FRESH-1**: 세션 시작 시 SSOT 0→1→2→3 로드 (Team Lead 풀로드)
- **FRESH-2~5**: Phase 시작 전 ssot_version 확인 + 불일치 시 리로드 + 리로드 시각 기록 + 장기 세션 주기 점검
- **FRESH-6**: 팀원 스폰 시 `ROLES/*.md` 1개 로딩
- **FRESH-7**: 컨텍스트 압축·세션 중단 후 복구 시 SSOT 리로드 필수 (팀 없이 코드 수정 절대 금지)
- **FRESH-8**: 리팩토링 레지스트리 관리 (500줄 초과 → 등록, 700줄 초과 → 리팩토링 sub-phase 편성)
- **FRESH-9**: 실행 단위 컨텍스트 권장 로딩 집합 (planner·verifier 우선)
- **FRESH-10~12** (6th 신규): SUB-SSOT 선택적 로딩 + 공통 레이어 필수 동반 + SUB-SSOT 독립 실행 가능성 검증

### ENTRY (5개) — 단일 진입점
모든 Phase는 `phase-X-Y-status.md`를 먼저 읽는 것으로 시작. status 파일 안 읽고 Task 구현 직행 금지(ENTRY-5). `ssot_version` 확인(ENTRY-3) → blockers 우선(ENTRY-4) → `current_state` 기반 다음 행동(ENTRY-2).

### LOCK (5개) — Phase 실행 중 SSOT 변경 차단
- LOCK-1: Phase 실행 중 SSOT 변경 금지 (`current_state`가 IDLE/DONE이 아닌 동안 수정 불가)
- LOCK-2: 변경 필요 시 BLOCKED로 일시정지 후 변경
- LOCK-3: 변경 후 모든 팀원에게 SendMessage로 리로드 지시
- LOCK-4: 팀원 SSOT 수정 금지 (읽기 전용)
- LOCK-5: 변경 이력 필수 기록 (VERSION.md 갱신)

상세 절차·플로우차트는 [[2026-05-05_pab_ssot_workflow|워크플로우 노트]] §ENTRYPOINT 절 참조.

## 폴더 구조 한눈에

```
SSOT/
├── implementation_plan.md           # 6세대 도입 구현 계획
└── docs/
    ├── 0-entrypoint.md              # 657줄 — 진입점, 역할별 체크리스트, §7.5 SUB-SSOT 라우팅
    ├── 1-project.md                 # 629줄 — Personal AI Brain v3, 팀 구성, 역할별 상세
    ├── 2-architecture.md            # 인프라, BE/FE, DB
    ├── 3-workflow.md                # 992줄 — 20개 상태, G0~G4, Phase Chain, AUTO_FIX, AB_COMPARISON
    ├── 4-event-protocol.md          # JSONL 이벤트 (5th)
    ├── 5-automation.md              # Artifact Persister, AutoReporter (5th)
    ├── GUIDE.md / VERSION.md / STRUCTURE.md   # 메타·가이드
    │
    ├── core/
    │   ├── 6-rules-index.md         # 96개 규칙 통합 인덱스 (HR-1~8, CHAIN-1~13, ITER-PRE/POST 등)
    │   └── 7-shared-definitions.md  # 공통 포맷 (GATE, ROLE_CHECK, 승인 10종, VAL, VUL, ITERATION-BUDGET)
    │
    ├── SUB-SSOT/
    │   ├── 0-sub-ssot-index.md      # 라우팅 테이블
    │   ├── DEV/        (4파일)      # CODER 전용 (backend-dev, frontend-dev)
    │   ├── PLANNER/    (2파일)
    │   ├── VERIFIER/   (2파일)      # REVIEWER 통합
    │   ├── TESTER/     (2파일)      # VALIDATOR 통합
    │   ├── TEAM-LEAD/  (2파일)
    │   └── RESEARCH/   (4파일)      # Lead/Architect/Analyst 3역할 (Phase-E)
    │
    ├── PERSONA/    (10파일)         # 마인드셋 레이어 (교체 가능)
    ├── ROLES/      (11파일)         # 역할 정의 정본 (불변 실행 가이드)
    ├── QUALITY/10-persona-qc.md     # 11명 Verification Council (5th)
    ├── TEMPLATES/  (11파일)         # 보고서 양식 (Step 3·5·8·12·13~14 AutoCycle 5종 포함)
    ├── tests/      (4파일)          # 시나리오 A~I 매핑, Phase별 테스트 목록
    ├── refactoring/(2파일)          # REFACTOR-1~3 + 500줄 초과 레지스트리
    ├── SUB-SSOT/RESEARCH/  /  QUALITY/  /  mcp-design/  /  infra/
    └── phases/                      # Phase 산출물 (E·F·G·H·I + pre/)
```

총 71 파일 13,715 라인. 본 wiki에서는 영역별로 11 노트로 분할 정리.

## 역할별 모듈형 로딩 — 토큰 절감 60%

| 역할 | 5th 풀로드 | 6th SUB-SSOT | 절감 |
|---|---|---|---|
| CODER (fn 기본) | ~61K | **~18K** (`7-shared` + `DEV/0` + `DEV/1`) | 70% |
| CODER (fn 풀) | ~61K | ~27K (`DEV/0~3`) | 56% |
| Planner | ~37K | ~13K | 65% |
| Verifier (REVIEWER 통합) | ~44K | ~17K | 61% |
| Tester (VALIDATOR 통합) | ~38K | ~16.5K | 57% |
| Research Lead/Architect/Analyst | ~30K | **~14K** (각각 독립) | 53% |
| **Team Lead** | ~35K | ~38K (허브 — 코어 0~5 + LEAD/0·1 + 인덱스) | (허브) |

**로딩 순서 — Team Lead**: `[0] 0-entrypoint → [1] 1-project → [2] 2-architecture → [3] 3-workflow` (FRESH-1 강제)

**로딩 순서 — 팀원**: `[1] core/7-shared (FRESH-11 필수) → [2] SUB-SSOT/{역할}/0-entrypoint → [3] SUB-SSOT/{역할}/1-procedure → [4] (선택) 추가 파일`

상세 라우팅은 [[2026-05-05_pab_ssot_skills_catalog|skill 카탈로그 노트]] §SUB-SSOT 라우팅 + 0-entrypoint.md §7.5 참조.

## 5세대 혁신 5축 (5th_mode)

| # | 축 | 핵심 | 주요 변경 |
|---|---|---|---|
| 1 | **Research-first** | 구현 전 조사 의무화 | RESEARCH 상태 + G0 + Research Team 3역할 |
| 2 | **Event-first** | 파일 폴링 → 이벤트 기반 | JSONL 이벤트 로그, Heartbeat → [[2026-05-05_pab_ssot_event_automation|이벤트·자동화 노트]] |
| 3 | **Automation-first** | 반복 산출물 자동 생성 | Artifact Persister, AutoReporter |
| 4 | **Branch-first** | Phase별 Git 격리 | BRANCH_CREATION 상태, `phase-{X}-{Y}-{state}` 태그 |
| 5 | **Multi-perspective** | 단일 Verifier → 11명 위원회 | Verification Council |

**opt-out 원칙**: 모든 축 기본 `true`. 명시적 `false`만 비활성화. status.md `5th_mode:` 필드.

## SSOT-NEW 구조 (core/ + project/) — 이식성 확장

Phase 24-1-3에서 도입된 비파괴 전환. 이식 가능성을 위해 **core(프레임워크)** 와 **project(프로젝트별)** 분리:

- `core/` — 이식 가능 (6-rules-index, 3·4·5-workflow/event/automation, QUALITY, TEMPLATES)
- `project/` — 프로젝트별 (1-project, 2-architecture, ROLES, _backup/GUIDES)

상세 이식 절차는 [[2026-05-05_pab_ssot_portability|이식 가이드 노트]] 참조.

## 다음 노트 — 본 SSOT 시리즈 진입

- [[PAB_SSOT_overview|MOC — SSOT 전체 진입점]] (모든 노트 wikilink 모음)
- [[2026-05-05_pab_ssot_architecture|아키텍처]] — 2-architecture (인프라·BE·FE·DB)
- [[2026-05-05_pab_ssot_workflow|워크플로우]] — 3-workflow (20개 상태·G0~G4·Phase Chain·AUTO_FIX·AB_COMPARISON)
- [[2026-05-05_pab_ssot_event_automation|이벤트·자동화]] — 4-event-protocol + 5-automation
- [[2026-05-05_pab_ssot_rules_chain|규칙·CHAIN]] — 6-rules-index (HR-1~8 + CHAIN-1~13) + 7-shared-definitions
- [[2026-05-05_pab_ssot_roles|역할 9종]] — ROLES/
- [[2026-05-05_pab_ssot_persona_qc|페르소나·QC]] — PERSONA + 11명 Council
- [[2026-05-05_pab_ssot_templates|템플릿 11종]] — TEMPLATES/
- [[2026-05-05_pab_ssot_subssot_misc|SUB-SSOT·tests·기타]] — SUB-SSOT/, tests/, mcp-design, infra
- [[2026-05-05_pab_ssot_skills_catalog|skill 카탈로그]] — 11 skill 일람·트리거
- [[2026-05-05_pab_ssot_skills_detail|skill 상세]] — 입출력·내부 절차·예시
- [[2026-05-05_pab_ssot_portability|이식 가이드]] — 다른 프로젝트 적용 절차

## 관련 본 vault 노트

- [[2026-05-04_pab_ssot_nexus_overview|PAB-SSOT-Nexus 프로젝트 overview]] — 본 SSOT의 호스트 프로젝트(저장소 구조 + ver5/6 버전 관리)
- [[PAB_project_overview|PAB 생태계 MOC]] — Conductor·Khala·Observer·Reader·SSOT-Nexus 5개 프로젝트 진입점

## 참고

- `/PAB-SSOT-Nexus/docs/SSOT/docs/0-entrypoint.md` — SSOT 진입점 (657줄)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/VERSION.md` — 버전 이력 (200줄)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/STRUCTURE.md` — 폴더 구조 설명 (331줄)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/GUIDE.md` — 전체 가이드 (631줄)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/1-project.md` — 프로젝트·팀 구성 (629줄)
