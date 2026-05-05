---
title: "PAB SSOT — 통합 진입점 MOC"
description: "PAB-SSOT-Nexus 본체(13,715줄 71 파일) + 11 skill을 12개 wiki 노트로 정리한 진입점. 3계층 아키텍처·96개 규칙·11 skill·이식 가이드 통합 인덱스"
created: 2026-05-05 05:13
updated: 2026-05-05 05:13
type: "[[REFERENCE]]"
index: "[[KNOWLEDGE_MGMT]]"
topics: ["[[PAB_SSOT]]"]
tags: [reference, moc, pab-ssot-nexus, ssot]
keywords: ["PAB SSOT", "MOC", "v8.2-renewal-6th", "AutoCycle v1.1", "11 skill", "12 노트", "이식 가이드", "3계층 아키텍처"]
sources: ["~/WORKS/PAB-SSOT-Nexus/docs/SSOT/", "~/WORKS/PAB-SSOT-Nexus/skills/"]
aliases: ["PAB SSOT MOC", "SSOT 통합 인덱스", "SSOT 진입점"]
---

# PAB SSOT — 통합 진입점 MOC

> **버전**: v8.2-renewal-6th (AutoCycle v1.1) · 2026-04-16
> **원본**: `~/WORKS/PAB-SSOT-Nexus/docs/SSOT/` (71파일 13,715줄) + `~/WORKS/PAB-SSOT-Nexus/skills/` (11 skill 1,930줄)
> **wiki 정리**: 12 노트로 분할 (본 MOC 포함)

## 3계층 아키텍처 한눈에

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: CORE SSOT (0~5)                                    │
│ 0-entrypoint  1-project  2-architecture  3-workflow         │
│ 4-event-protocol  5-automation                              │
│ → Team Lead 풀로드 (FRESH-1)                                │
└───────────────────────────┬─────────────────────────────────┘
                            ↓
┌───────────────────────────▼─────────────────────────────────┐
│ Layer 2: COMMON (core/7-shared-definitions.md)              │
│ GATE 포맷 + ROLE_CHECK + 승인 10종 + VAL/VUL                 │
│ + 충돌 Type A~E + 예외 4조항 + ITERATION-BUDGET 500K        │
│ → 모든 SUB-SSOT 필수 동반 (FRESH-11)                        │
└───────────────────────────┬─────────────────────────────────┘
                            ↓
┌───────────────────────────▼─────────────────────────────────┐
│ Layer 3: SUB-SSOT (역할별 선택 로딩, 토큰 절감 60%)          │
│ DEV(4) PLANNER(2) VERIFIER(2) TESTER(2)                     │
│ TEAM-LEAD(2) RESEARCH(4) — 6 SUB-SSOT                       │
│ → 해당 역할 세션에서만 (FRESH-10)                           │
└─────────────────────────────────────────────────────────────┘

[+ 자동화 11 skill] menu / context-handoff / ssot-reload /
                   phase-init / plan / notify-telegram / worktree /
                   refactor-scan / worklog / report / wiki
```

## 12 노트 진입 가이드

### 시작 (필독)
| 노트 | 분량 | 내용 |
|---|---|---|
| [[2026-05-05_pab_ssot_intro\|① 진입점·6세대 모듈형 로딩]] | 250줄 | 버전 트리(4th→5th→6th→AutoCycle) · 3계층 아키텍처 · FRESH/ENTRY/LOCK 진입 절차 |

### 시스템·워크플로우
| 노트 | 분량 | 내용 |
|---|---|---|
| [[2026-05-05_pab_ssot_architecture\|② 아키텍처]] | 200줄 | Docker 5종 인프라 · FastAPI+SQLAlchemy · Vanilla JS+ESM · Event/Automation 5세대 |
| [[2026-05-05_pab_ssot_workflow\|③ 워크플로우]] | 350줄 | **20개 상태 머신** · G0~G4 · NOTIFY/ASSIGN/LIFECYCLE/REPORT · 병렬+WT-1~5 · CHAIN-1~11 · REFACTOR · ANALYSIS |
| [[2026-05-05_pab_ssot_event_automation\|④ 이벤트·자동화]] | 290줄 | JSONL · Heartbeat · Watchdog · Artifact Persister · AutoReporter · **DecisionEngine 6조건 AND** · Git Checkpoint |

### 규칙 인덱스
| 노트 | 분량 | 내용 |
|---|---|---|
| [[2026-05-05_pab_ssot_rules_chain\|⑤ 96개 규칙 + 공통 포맷]] | 380줄 | **HR-1~5/CHAIN-1~13/FRESH-1~12/ENTRY/EDIT/GATE/ASSIGN/LIFECYCLE/REPORT/NOTIFY/ANALYSIS/PROMPT/WT** + 7-shared-definitions(GATE/승인 10종/VAL/VUL/예외 4/ITERATION-BUDGET) |

### 역할·페르소나·템플릿
| 노트 | 분량 | 내용 |
|---|---|---|
| [[2026-05-05_pab_ssot_roles\|⑥ 역할 9종]] | 270줄 | Team Lead·Planner·Backend·Frontend·Verifier·Tester·Research(L/A/A) — Hub-and-Spoke + G0~G4 분담 + 대리 저장 패턴 |
| [[2026-05-05_pab_ssot_persona_qc\|⑦ 페르소나·QC]] | 230줄 | 9 PERSONA Charter + **11명 Verification Council** (동적 선택·비토·점수·체크리스트) |
| [[2026-05-05_pab_ssot_templates\|⑧ 템플릿 11종]] | 230줄 | task-report·defect·ab-comparison + AutoCycle 5종(development-plan·prompt-alignment·phase-achievement·tech-debt·master-final) + Pre-draft |

### SUB-SSOT·tests·기타
| 노트 | 분량 | 내용 |
|---|---|---|
| [[2026-05-05_pab_ssot_subssot_misc\|⑨ SUB-SSOT·tests·기타]] | 240줄 | SUB-SSOT 6 라우팅(토큰 60% 절감) · 테스트 시나리오 A~I · MCP 3 서버 설계 · git subtree 가이드 |

### Skills (자동화)
| 노트 | 분량 | 내용 |
|---|---|---|
| [[2026-05-05_pab_ssot_skills_catalog\|⑩ skill 카탈로그]] | 220줄 | 11 skill 일람 — 분류·트리거·자동화 규칙 매핑 |
| [[2026-05-05_pab_ssot_skills_detail\|⑪ skill 상세]] | 380줄 | 각 skill 입출력·내부 절차·예시·연계 |

### 이식
| 노트 | 분량 | 내용 |
|---|---|---|
| [[2026-05-05_pab_ssot_portability\|⑫ 이식 가이드]] | 280줄 | A/B/C 3 단위 이식 + 복사 대상 + plugin.json + deploy.sh + ver5/6 호환 + git subtree + vault 운영 모드 |

## 학습 경로 추천

### "Team Lead로 SSOT 처음 운영" (60분)
1. [[2026-05-05_pab_ssot_intro|① 진입점]] (15분) — 무엇·왜·어떻게
2. [[2026-05-05_pab_ssot_workflow|③ 워크플로우]] (20분) — 20개 상태·G0~G4·CHAIN
3. [[2026-05-05_pab_ssot_rules_chain|⑤ 규칙 인덱스]] (15분) — HR-1~5 필수
4. [[2026-05-05_pab_ssot_roles|⑥ 역할 9종]] (10분) — 어떤 팀원을 언제 스폰

### "skill로 운영 자동화" (30분)
1. [[2026-05-05_pab_ssot_skills_catalog|⑩ skill 카탈로그]] (10분)
2. [[2026-05-05_pab_ssot_skills_detail|⑪ skill 상세]] (20분)

### "다른 프로젝트에 이식" (45분)
1. [[2026-05-05_pab_ssot_intro|① 진입점]] (15분) — 3계층 이해
2. [[2026-05-05_pab_ssot_portability|⑫ 이식 가이드]] (20분) — A/B/C 결정
3. [[2026-05-05_pab_ssot_subssot_misc|⑨ SUB-SSOT·기타]] (10분) — git subtree 옵션

### "특정 게이트 G0~G4 깊이 이해" (40분)
1. [[2026-05-05_pab_ssot_workflow|③ 워크플로우]] §품질 게이트 (10분)
2. [[2026-05-05_pab_ssot_event_automation|④ 자동화]] §AUTO_FIX 6조건 (10분)
3. [[2026-05-05_pab_ssot_persona_qc|⑦ Council]] §11명 동적 선택 (10분)
4. [[2026-05-05_pab_ssot_templates|⑧ 템플릿]] §AutoCycle 5종 (10분)

## 주요 규칙 ID 빠른 참조

| 카테고리 | 핵심 규칙 | 노트 |
|---|---|---|
| **Hard Rules** | HR-1(코드 직접 수정 금지) · HR-2(산출물 의무) · HR-3(복구 시 리로드) · HR-4(경로 규칙) · HR-5(리팩토링 500/700) | ⑤ |
| **CHAIN** | CHAIN-2(/clear) · CHAIN-6(산출물) · CHAIN-7(G0~G4) · CHAIN-10(경로) · CHAIN-11(final-summary) · CHAIN-12/13(AutoCycle 자동 로딩) | ⑤ + ③ |
| **품질 게이트** | G0(Research) · G1(Plan) · G2(Code) · G3(Test) · G4(Final) | ③ + ⑥ |
| **AUTO_FIX** | DecisionEngine 6조건 AND (PARTIAL + Critical 0 + High 1~2 + 아키텍처/의존성/비토 변경 없음) | ④ |
| **Worktree** | WT-1(병렬 ≥2 격리 필수) · WT-3(CWD 일관성) | ③ + ⑨ |
| **NOTIFY** | NOTIFY-1(DONE 알림 의무, 생략 시 DONE 무효) | ③ + ⑤ |
| **AutoCycle** | ITER-PRE(3회) · ITER-POST(2회) · ITERATION-BUDGET 500K · PROMPT-QUALITY 5항목 | ⑤ + ⑧ |
| **ASSIGN** | [BE]→backend-dev / [FE]→frontend-dev / [TEST]→tester (절대 BE/FE에 [TEST] 할당 금지) | ⑥ + ⑤ |

## 외부 의존 도식

```
[PAB-SSOT-Nexus]               ← SSOT 본체 (본 노트 시리즈의 1차 출처)
    │
    ├─ docs/SSOT/             → ① ~ ⑨ 노트
    ├─ skills/ (11 skill)     → ⑩ ⑪ 노트
    ├─ scripts/pmAuto/        → notify-telegram 의존 (③ ⑤ ⑩)
    ├─ ver{5-0,5-1,6-0}/      → 버전 히스토리 (⑫)
    ├─ dist/                  → AutoCycle 포터블 (⑫)
    ├─ pab-ssot/              → Next.js 웹앱 (deploy.sh로 3800x 배포)
    └─ .claude-plugin/        → PAB plugin 매니페스트 (⑫)
```

## 본 vault의 다른 관련 노트

- [[2026-05-04_pab_ssot_nexus_overview|PAB-SSOT-Nexus 프로젝트 overview]] — 본 SSOT의 호스트 프로젝트 정체·구조·연동
- [[PAB_project_overview|PAB 생태계 MOC]] — PAB-Conductor·Khala·Observer·Reader·SSOT-Nexus 5 프로젝트
- [[2026-05-04_pab_conductor_overview|PAB-Conductor]] — SSOT 워크플로우 적용 사례 (full-stack)
- [[2026-05-04_pab_khala_overview|PAB-Khala]] — SSOT Phase 0~5 적용 사례

## 본 시리즈 운영 메모

- 본 12 노트는 **2026-05-05 일괄 작성**. SSOT 본체 v8.2-renewal-6th 기준.
- SSOT 갱신 시(예: AutoCycle v1.2) 영향 노트 일괄 갱신 권장.
- 노트 분할 단위는 SSOT 본체의 파일/카테고리 묶음 기준 (1:1이 아니라 영역별 합본).
- 12 노트 모두 frontmatter 11필드 표준 준수 (project 필드 없음 — 외부 자료 정리이므로).
- 각 노트의 wikilink는 vault-wide 매칭으로 노트 위치(폴더) 무관.

## 향후 보강 예정

- SUB-SSOT 6종 각각의 내부 절차 deep-dive 노트 (현재는 ⑨에 요약)
- AutoCycle Step 1~14 시나리오별 실전 적용 노트
- 11 skill 각각의 실전 사용 예시 + 트러블슈팅 노트
- Phase 23·24·25·26 등 실제 진행된 Phase의 회고 노트
