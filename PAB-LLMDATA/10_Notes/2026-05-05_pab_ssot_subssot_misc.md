---
title: "PAB SSOT — SUB-SSOT 라우팅 + tests + mcp-design + infra (보조 디렉토리)"
description: "역할별 SUB-SSOT 6종 라우팅 인덱스 + tests/(시나리오 A~I + 마커 체계) + mcp-design(3개 MCP 서버 설계) + infra(git subtree 가이드) 정리"
created: 2026-05-05 05:13
updated: 2026-05-05 05:13
type: "[[RESEARCH_NOTE]]"
index: "[[ENGINEERING]]"
topics: ["[[PAB_SSOT]]", "[[SUB_SSOT]]", "[[TEST_SCENARIOS]]", "[[MCP_DESIGN]]"]
tags: [research-note, pab-ssot-nexus, sub-ssot, tests, mcp, infra]
keywords: ["SUB-SSOT 라우팅", "DEV", "PLANNER", "VERIFIER", "TESTER", "TEAM-LEAD", "RESEARCH", "토큰 절감 60%", "시나리오 A~I", "pytest 마커", "smoke/db/redis/llm/integration", "MCP 3 서버", "FastMCP", "git subtree", "ssot-core 분리"]
sources:
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/SUB-SSOT/0-sub-ssot-index.md"
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/tests/index.md"
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/mcp-design/mcp-server-design.md"
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/infra/git-subtree-guide.md"
aliases: ["SUB-SSOT 인덱스", "테스트 시나리오", "MCP 설계", "git subtree"]
---

# PAB SSOT — SUB-SSOT + tests + mcp-design + infra

## §1 SUB-SSOT 라우팅 인덱스 (0-sub-ssot-index.md)

> Team Lead가 팀원 스폰 시 어떤 SUB-SSOT를 로딩할지 판단하는 라우팅 허브. **토큰 절감 60%** (역할별 ~14~38K).

### SUB-SSOT 6종 + 공통 레이어

| SUB-SSOT | 파일 수 | 토큰 (추정) | 대상 역할 |
|---|---:|---:|---|
| **공통 레이어** | 1 | ~7K | 모든 역할 (FRESH-11 필수) |
| **DEV** (v1.1) | 4 | ~22K (필수만 ~18K) | **CODER** (backend-dev / frontend-dev) |
| **PLANNER** | 2 | ~6K | planner |
| **VERIFIER** (v1.1) | 2 | ~10K | **verifier** (REVIEWER 통합) |
| **TESTER** (v1.1) | 2 | ~9.5K | **tester** (VALIDATOR 통합) |
| **TEAM-LEAD** | 2 | ~8K | Team Lead |
| **RESEARCH** (v1.0, Phase-E 신설) | 4 | ~15K (역할당 ~14K) | research-lead / architect / analyst |

### 작업 유형 → 로딩 집합

```
[작업 유형]                    [로딩 파일]
fn 기본 개발                  core/7-shared + DEV/0-dev + DEV/1-fn         (~18K)
fn 풀 (복잡/위험)             core/7-shared + DEV/0~3 전부                  (~27K)
단순 Task (코드 수정)         core/7-shared + DEV/0-dev                     (~10K)
계획 수립                     core/7-shared + PLANNER/0~1                   (~13K)
코드 검증 (REVIEWER)          core/7-shared + VERIFIER/0~1                  (~17K)
코드 테스트 (VALIDATOR)       core/7-shared + TESTER/0~1                    (~16.5K)
기술 조사 (Research Lead)     core/7-shared + RESEARCH/0 + 1-lead           (~14K)
기술 조사 (Research Architect) core/7-shared + RESEARCH/0 + 2-architect      (~14K)
기술 조사 (Research Analyst)  core/7-shared + RESEARCH/0 + 3-analyst        (~14K)
오케스트레이션                SSOT 코어(0~5) + core/7-shared + TEAM-LEAD/0~1 + 인덱스 (~38K)
```

### 판단 기준

| 질문 | YES → | NO → |
|---|---|---|
| 코드 작성 필요? | DEV SUB-SSOT | 비 DEV |
| fn 단위 요청? | DEV fn 기본 이상 | DEV 단순 Task |
| 호환 분석·인프라 변경 수반? | DEV fn 풀 (0~3) | DEV fn 기본 |
| 계획만 필요? | PLANNER | — |
| 코드 리뷰만? | VERIFIER | — |
| 테스트 실행만? | TESTER | — |

### SUB-SSOT 디렉토리 구조

```
docs/
├── core/7-shared-definitions.md          ← 공통 레이어 (FRESH-11)
└── SUB-SSOT/
    ├── 0-sub-ssot-index.md               ← 본 인덱스
    ├── DEV/      (4파일: 0-dev-entrypoint, 1-fn-procedure, 2-ai-execution-rules, 3-failure-modes)
    ├── PLANNER/  (2파일: 0-planner-entrypoint, 1-planning-procedure)
    ├── VERIFIER/ (2파일: 0-verifier-entrypoint, 1-verification-procedure)
    ├── TESTER/   (2파일: 0-tester-entrypoint, 1-testing-procedure)
    ├── RESEARCH/ (4파일: 0-research-entrypoint, 1-lead, 2-architect, 3-analyst)
    └── TEAM-LEAD/(2파일: 0-lead-entrypoint, 1-orchestration-procedure)
```

### 로딩 플로우

```
Team Lead 진입
  ├── SSOT 코어 로딩 (0~5)
  ├── SUB-SSOT/0-sub-ssot-index.md 참조 (본 문서)
  └── 팀원 스폰 시:
      ├── 작업 유형 확인 (라우팅 테이블)
      ├── 해당 SUB-SSOT 경로 결정
      └── SendMessage에 로딩 경로 포함
          ↓ (팀원 세션 시작)
          ├── core/7-shared-definitions.md 로딩 (필수, FRESH-11)
          ├── {역할}/0-{role}-entrypoint.md
          └── {역할}/1-{procedure}.md
              └── 필요 시 추가 (DEV/2, DEV/3 등)
```

### 토큰 효율 비교

| 시나리오 | ver5-1 풀로드 | SUB-SSOT v1.1 | 절감 |
|---|---:|---:|:--:|
| fn 기본 (CODER) | ~61K | **~18K** | **70%** |
| fn 풀 (CODER) | ~61K | ~27K | 56% |
| Planner | ~37K | ~13K | 65% |
| Verifier (REVIEWER) | ~44K | ~17K | 61% |
| Tester (VALIDATOR) | ~38K | ~16.5K | 57% |
| Team Lead | ~35K | ~38K (+3K 인덱스) | 허브 |
| Research × 3 | ~30K (각) | ~14K (각) | 53% |

상세 SUB-SSOT 내부 절차: 각 SUB-SSOT 파일 직접 참조. (DEV 8 PHASE 절차, VERIFIER REVIEWER 8항목 체크리스트, TESTER 결함 분류 ISTQB CTFL 4.0 기반 등)

## §2 tests/ — 테스트 선택 실행 가이드 (4파일)

> **원칙**: 전체 테스트 실행(`pytest tests/`)은 **불필요**. 변경 코드에 영향받는 테스트만 선택 실행.

### 변경 시나리오 A~I

총 280 테스트 (29 파일). Phase 25-2 마커 체계 적용 후.

| 시나리오 | 영역 | 환경 | 핵심 테스트 |
|---|---|---|---|
| **A** | AI/LLM (`/api/ask`, Ollama, 키워드 추천) | Ollama (192.168.0.22:11434) | test_ai_api, test_keyword_recommenders |
| **B** | Reasoning (`/api/reason`, 추론, 추천) | Ollama | test_reasoning_api, test_reason_document, test_reasoning_recommendations |
| **C** | Knowledge (`/api/knowledge`, 청크, 라벨, 관계, 승인) | PostgreSQL (5433) | test_knowledge_api, test_approval_bulk_api, test_phase20_5, test_structure_matching |
| **D** | 검색/캐시 (`/api/search`, Redis, Hybrid) | Redis (6380) | test_api_routers, test_search_service, test_hybrid_search |
| **E** | 인증/권한 (JWT, 역할, Admin) | 없음 | test_auth_permissions, test_admin_api |
| **F** | 자동화/워크플로우 (`/api/automation`, Task Plan) | 없음 (Mock) | test_ai_automation_api, test_ai_workflow_service, test_task_plan_generator |
| **G** | 폴더 관리/파일 스캔 | SQLite + tmp_path | test_folder_management |
| **H** | 인프라/보안 (HSTS, CORS, RateLimit) | Redis (옵션) | test_phase_12_qc |
| **I** | LLM 정책 (3-Tier, 네트워크 복원력, 타임아웃) | Mock | test_llm_3tier, test_llm_network, test_llm_timeout_tier |

### 회귀 테스트

| 회귀 | 명령 | 시간 | 용도 |
|---|---|---|---|
| **빠른 회귀** (LLM·통합 제외, ~170 테스트) | `pytest tests/ -m "not llm and not integration" --tb=short -q` | ~2분 | Phase 완료 시 G3 최소 요건 |
| **LLM 회귀** (~210 테스트) | `OLLAMA_BASE_URL=... pytest tests/ -m "not integration" --tb=short -q --timeout=60` | ~6분 | Phase X 전체 완료 시 |
| **통합 회귀** (~46 테스트) | `OLLAMA_BASE_URL=... pytest tests/ -m "integration" --tb=short -q` | — | 릴리스 전 또는 G3 Full |

### pytest 마커 체계

| 마커 | 테스트 수 | 환경 |
|---|:--:|---|
| smoke | 27 | 없음 |
| db | 34 | PostgreSQL |
| redis | 8 | Redis |
| llm | ~39 | Ollama |
| integration | 46 | 전체 환경 |
| 마커 없음 | ~106 | 대부분 없음 |

### 소스 → 테스트 빠른 참조 (예시)

| 수정 소스 | 실행 테스트 | 시나리오 |
|---|---|:--:|
| `routers/ai/*.py` | test_ai_api | A |
| `routers/reasoning/*.py` | test_reasoning_api, test_reason_document | B |
| `routers/knowledge/*.py` | test_knowledge_api, test_approval_bulk_api, test_phase20_5 | C |
| `routers/search.py` | test_api_routers, test_search_service | D |
| `services/ai/ollama_client.py` | test_ai_api, test_llm_3tier, test_llm_network, test_llm_timeout_tier | A + I |
| `models/models.py` | test_models, test_folder_management | C + G |
| `middleware/*.py` | test_phase_12_qc, test_auth_permissions | E + H |

### tests/ 4 파일

| 파일 | 용도 |
|---|---|
| **`index.md`** | 본 노트의 1차 출처 — 시나리오 A~I + 마커 + 회귀 |
| `test-phase-mapping.md` | Phase별 테스트 생성 이력 + 소스→테스트 영향 매트릭스 |
| `test-suite-report.md` | 기능 영역별 추천 테스트 + 부하 전략 |
| `test-tuning-guide.md` | 마커/환경/부하 튜닝 가이드 |

추가: `docs/pytest-report/YYMMDD-HHMM-phase-X-Y-테스트명.md` — 1주기 요청서/결과서 저장소.

## §3 mcp-design/ — 3개 MCP 서버 설계 (Phase 24-6)

> SSOT 운영 자동화를 위한 3개 MCP(Model Context Protocol) 서버. **Python FastMCP** + 로컬 stdio 모드.

### 기술 스택

| 항목 | 선택 |
|---|---|
| 프레임워크 | Python FastMCP (`from mcp.server.fastmcp import FastMCP`) |
| 런타임 | Python 3.11+ |
| YAML 파싱 | PyYAML (`yaml.safe_load`) |
| 배포 모드 | 로컬 stdio (Claude Code `settings.json` `mcpServers` 등록) |
| 데이터 형식 | YAML frontmatter (status.md), JSONL (이벤트 로그) |

### 서버 3종

| 서버명 | 역할 | Tool 수 |
|---|---|:--:|
| **`ssot-state-manager`** | Phase status.md CRUD + 상태 전이 유효성 검증 | 4 |
| **`ssot-event-logger`** | JSONL 이벤트 기록/조회/아카이브 | 4 |
| **`ssot-artifact-validator`** | CHAIN-6 산출물 존재 확인 + 내용 검증 | 4 |

> 본 문서는 **설계서** 단계 (Phase 24-6 Task 24-6-2). 실제 구현 여부는 후속 Phase 확인 필요.

## §4 infra/git-subtree-guide.md — Core/Custom 분리

> **목적**: SSOT의 `core/` 디렉토리를 별도 리포지토리(`ssot-core`)로 분리하여 다른 프로젝트에서 git subtree로 가져와 사용. **이식성 확보** 목적.

### 분리 전 (현재)

```
personal-ai-brain-v3/
└── docs/SSOT/renewal/iterations/5th/
    ├── core/           ← 이식 대상 (6-rules-index, README)
    └── project/        ← 프로젝트 고유 (1-project, 2-architecture, ROLES, _backup/GUIDES)
```

### 분리 후

```
ssot-core/  (별도 리포지토리)
├── 6-rules-index.md
├── README.md
├── 3-workflow.md  (향후 이동)
├── 4-event-protocol.md  (향후 이동)
├── 5-automation.md  (향후 이동)
├── QUALITY/
└── TEMPLATES/

personal-ai-brain-v3/
└── docs/SSOT/renewal/iterations/5th/
    ├── core/        ← git subtree로 ssot-core 연결 (읽기 전용)
    └── project/     ← 프로젝트 고유 유지
```

### 분리 절차 (요약)

1. `ssot-core` 신규 리포지토리 생성
2. `git subtree split --prefix=docs/SSOT/.../core` 로 core 분리
3. `ssot-core` 리포지토리에 push
4. 원본에서 `git subtree add` 또는 `git submodule`로 다시 연결
5. 다른 프로젝트에서는 `git subtree pull --prefix=core ssot-core main`로 가져옴

상세 명령은 원본 git-subtree-guide.md 참조.

## 다음 노트

- [[2026-05-05_pab_ssot_skills_catalog|skill 카탈로그]] — 11 skill (worktree·notify-telegram 등 자동화)
- [[2026-05-05_pab_ssot_portability|이식 가이드]] — git subtree + dist + ver 호환
- [[2026-05-05_pab_ssot_roles|역할 9종]] — VERIFIER/TESTER SUB-SSOT 매핑
- [[2026-05-05_pab_ssot_intro|진입점·6세대]] — 3계층 아키텍처
- [[PAB_SSOT_overview|MOC]]

## 참고

- `/PAB-SSOT-Nexus/docs/SSOT/docs/SUB-SSOT/0-sub-ssot-index.md` (v1.1, 142줄)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/tests/index.md` (323줄, 시나리오 A~I + 회귀 + 마커)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/mcp-design/mcp-server-design.md` — 3 MCP 서버 설계 (Phase 24-6)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/infra/git-subtree-guide.md` — Core 이식성 분리 가이드
