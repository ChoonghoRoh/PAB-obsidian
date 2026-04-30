# ver6-0 SSOT 전체 가이드

**버전**: v8.0-renewal-6th | **릴리스**: 2026-04-13
**기반**: v7.0-renewal-5th (5th 콘텐츠 100% 보존) + 6th SUB-SSOT 모듈형 로딩 아키텍처

---

## 1. 개요

### 1.1 이 SSOT의 목적

Claude Code Agent Teams 운영을 위한 **단일 진실 공급원(Single Source of Truth)**. Team Lead가 팀을 생성하고, 역할별 에이전트가 병렬로 코드를 작성/검증/테스트하는 전체 워크플로우를 규정한다.

### 1.2 6th 세대의 핵심 변경

5th 세대 위에 **SUB-SSOT 모듈형 로딩**을 추가하여 역할별 토큰 효율 42~67% 개선.

| 항목 | 5th (ver5-1) | 6th (ver6-0) |
|------|-------------|-------------|
| SSOT 버전 | 7.0-renewal-5th | 8.0-renewal-6th |
| 로딩 방식 | 전체 풀로드 | 역할별 선택 로딩 |
| 공통 포맷 위치 | 5개 문서에 분산 | `core/7-shared-definitions.md` 1곳 집중 |
| fn 개발 시 토큰 | ~57K | ~20K (기본) |
| 신규 파일 | 0 | +15 (공통 1 + SUB-SSOT 14) |
| 상태 머신 | 20개 | 20개 (동일) |
| 게이트 | G0~G4 | G0~G4 (동일) |

### 1.3 5th 세대 유지 항목 (변경 없음)

- 20개 상태 머신 (4th 14개 + 5th 6개)
- G0~G4 품질 게이트
- Research Team 3역할 (research-lead/architect/analyst)
- 5th_mode 5축 (research, event, automation, branch, multi_perspective)
- Hub-and-Spoke 통신 모델
- HR-1~HR-8 하드 규칙
- 모든 PERSONA, ROLES, GUIDES, TEMPLATES, QUALITY 파일

---

## 2. 3계층 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: CORE SSOT (0~5)                                    │
│                                                             │
│ 0-entrypoint   1-project   2-architecture   3-workflow      │
│ 4-event-protocol   5-automation                             │
│                                                             │
│ 대상: Team Lead 풀로드 (FRESH-1)                             │
│ 내용: 상태 머신 20개, G0~G4, Phase Chain, 팀 구조, 인프라     │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│ Layer 2: COMMON (core/7-shared-definitions.md)              │
│                                                             │
│ §1 GATE 포맷 + ANTI-COMPRESSION                             │
│ §2 ROLE_CHECK + 역할 매핑 + 전환 금지                        │
│ §3 승인 프로토콜 10종 (AMBIGUITY~DEPENDENCY_CONFLICT)        │
│ §4 산출물 포맷 (DEVIATION, VAL, FAIL_COUNTER)                │
│ §5 충돌 분류 Type A~E                                        │
│ §6 VUL 체크리스트 3종                                        │
│ §7 예외 4조항 (Hotfix/Minor/Pattern/POC)                     │
│                                                             │
│ 대상: 모든 SUB-SSOT가 필수 로딩 (FRESH-11)                   │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│ Layer 3: SUB-SSOT (역할별 선택 로딩)                          │
│                                                             │
│  DEV (4파일)    PLANNER (2파일)    VERIFIER (2파일)          │
│  TESTER (2파일) TEAM-LEAD (2파일)                            │
│                                                             │
│ 대상: 해당 역할 세션에서만 로딩 (FRESH-10)                    │
│ 원칙: 공통 + SUB-SSOT만으로 독립 실행 가능 (FRESH-12)         │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. 전체 파일 맵

```
ver6-0/
├── implementation_plan.md                    # 구현 계획서 (내부용)
│
├── docs/
│   ├── GUIDE.md                              # [본 문서] 전체 가이드
│   ├── VERSION.md                            # 버전 이력 (v6.0→v8.0-renewal-6th)
│   │
│   │── ── CORE SSOT ── ──
│   ├── 0-entrypoint.md        (28KB)         # 진입점, 역할별 체크리스트, FRESH 규칙
│   ├── 1-project.md           (36KB)         # 팀 구성, 역할 정의, 통신 모델
│   ├── 2-architecture.md      (18KB)         # 인프라, BE/FE 기술 스택, 코드 규칙
│   ├── 3-workflow.md          (51KB)         # 상태 머신 20개, G0~G4, Phase Chain
│   ├── 4-event-protocol.md     (7KB)         # JSONL 이벤트, Heartbeat, Watchdog (5th)
│   ├── 5-automation.md        (12KB)         # Artifact Persister, AutoReporter (5th)
│   │
│   │── ── COMMON LAYER ── ──
│   ├── core/
│   │   ├── 6-rules-index.md   (24KB)         # 92개 규칙 인덱스 (19 카테고리)
│   │   ├── 7-shared-definitions.md (12KB)    # [6th 신규] 공통 포맷 정의
│   │   └── README.md                         # core 설명
│   │
│   │── ── SUB-SSOT ── ──
│   ├── SUB-SSOT/
│   │   ├── 0-sub-ssot-index.md  (3.9KB)     # [6th 신규] 라우팅 테이블
│   │   ├── DEV/                              # [6th 신규] 개발 파트
│   │   │   ├── 0-dev-entrypoint.md  (4.1KB)  #   진입점, 역할 매핑, 로딩 집합
│   │   │   ├── 1-fn-procedure.md    (7.8KB)  #   fn 8 PHASE 절차 (PHASE 0~7)
│   │   │   ├── 2-ai-execution-rules.md (4.9KB) # 5역할 페르소나, AI 실행 규칙
│   │   │   └── 3-failure-modes.md   (5.5KB)  #   24개 실패 모드 + 우선순위
│   │   ├── PLANNER/                          # [6th 신규] 계획 파트
│   │   │   ├── 0-planner-entrypoint.md (1.7KB)
│   │   │   └── 1-planning-procedure.md (2.8KB)
│   │   ├── VERIFIER/                         # [6th 신규] 검증 파트
│   │   │   ├── 0-verifier-entrypoint.md (2.0KB)
│   │   │   └── 1-verification-procedure.md (3.3KB)
│   │   ├── TESTER/                           # [6th 신규] 테스트 파트
│   │   │   ├── 0-tester-entrypoint.md (2.0KB)
│   │   │   └── 1-testing-procedure.md (2.8KB)
│   │   └── TEAM-LEAD/                        # [6th 신규] 오케스트레이션
│   │       ├── 0-lead-entrypoint.md   (2.2KB)
│   │       └── 1-orchestration-procedure.md (2.7KB)
│   │
│   │── ── ROLES & PERSONA ── ──
│   ├── PERSONA/          (9파일)             # 역할 페르소나 (LEADER, BACKEND, FRONTEND, PLANNER, QA, RESEARCH x3)
│   ├── ROLES/            (9파일 + README)    # 역할 통합 정의 (backend-dev, frontend-dev, planner, verifier, tester, research x3, team-lead — PERSONA+ROLES 통합)
│   │
│   │── ── GUIDES (레거시 backup, 2026-04-15 Phase-F로 SUB-SSOT 이관 완료) ── ──
│   ├── _backup/GUIDES/             # 6개 역할 가이드는 SUB-SSOT/{ROLE}/ 정본으로 이관·보존
│   │   ├── backend-work-guide.md   (10KB)    # → SUB-SSOT/DEV/ (CODER 전용)
│   │   ├── frontend-work-guide.md   (9KB)    # → SUB-SSOT/DEV/ (CODER 전용)
│   │   ├── planner-work-guide.md    (5KB)    # → SUB-SSOT/PLANNER/
│   │   ├── verifier-work-guide.md   (9KB)    # → SUB-SSOT/VERIFIER/ (REVIEWER 통합)
│   │   ├── tester-work-guide.md    (18KB)    # → SUB-SSOT/TESTER/ (VALIDATOR 통합)
│   │   ├── research-work-guide.md   (7KB)    # → SUB-SSOT/RESEARCH/ (3역할 분리)
│   │   └── DEV-work-guide/         (133KB)   # 개발 절차 원본 (SUB-SSOT/DEV 소스, Phase-E에서 이관)
│   │       ├── 0-workflow-system-overview.md  # 문서 시스템 개요
│   │       ├── 1-Feature-Development-SOP.md   # 7단계 인간 기준 SOP
│   │       ├── 2-ai-harness-dev-procedure.md  # AI 실행 규칙 원본
│   │       ├── 3-dev-problem-analysis.md      # 24개 실패 모드 원본
│   │       └── 4-fn-dev-field-procedure-v1.md # fn 8 PHASE 원본
│   │
│   │── ── QUALITY & TEMPLATES ── ──
│   ├── QUALITY/10-persona-qc.md  (9KB)       # 11명 Verification Council (5th)
│   ├── TEMPLATES/            (6파일)          # 보고서 템플릿 (ab-comparison, decision-log 등)
│   │
│   │── ── 기타 ── ──
│   ├── ab-test/              (5파일)          # A/B 테스트 문서
│   ├── vision-appendix/      (3파일)          # 비전 부록 (KPI, 리스크)
│   ├── ssot-template/                         # Copier 기반 SSOT 템플릿
│   ├── infra/                                 # git-subtree 가이드
│   ├── mcp-design/                            # MCP 서버 설계
│   └── harness-comparison-report.md           # 하네스 비교 보고서
│
└── scripts/
    ├── migrations/                            # DB 마이그레이션 (수동 실행)
    │   ├── README.md                          # 실행 방법 + 목록
    │   ├── 001_add_gin_indexes.sql            # GIN 인덱스 4개 (Phase 12-2-3)
    │   ├── 002_create_page_access_log.sql     # 페이지 접근 로그 (Phase 13-4)
    │   ├── 003_create_system_settings.sql     # 시스템 설정 K-V (Phase 15-1-1)
    │   ├── 004_create_users_table.sql         # 사용자 인증 (Phase 15-5-1)
    │   ├── backfill_titles_display_ids.py     # title/display_id 역추출 (Phase 32-3)
    │   └── update_qdrant_payload.py           # Qdrant payload 갱신 (Phase 32-3)
    └── pmAuto/
        └── report_to_telegram.sh              # Telegram 알림 (HR-8 NOTIFY)
```

---

## 4. 역할별 로딩 경로

### 4.1 로딩 요약표

| 역할 | 로딩 파일 | 토큰 (추정) | 절감률 |
|------|-----------|-------------|--------|
| **DEV (fn 기본)** | 7-shared + DEV/0 + DEV/1 | ~20K | 65% |
| **DEV (fn 풀)** | 7-shared + DEV/0~3 | ~33K | 42% |
| **DEV (단순 Task)** | 7-shared + DEV/0 | ~10K | — |
| **PLANNER** | 7-shared + PLANNER/0~1 | ~13K | 54% |
| **VERIFIER** | 7-shared + VERIFIER/0~1 | ~14K | 48% |
| **TESTER** | 7-shared + TESTER/0~1 | ~14K | 48% |
| **TEAM-LEAD** | SSOT 코어(0~5) + 7-shared + LEAD/0~1 + index | ~65K | — |
| **단순 Task** | ROLES/*.md + task.md | ~5K | — |

### 4.2 로딩 순서

**Team Lead (메인 세션)**:
```
[1] SSOT 코어 0→1→2→3 (FRESH-1)
[2] 4-event-protocol + 5-automation (5th_mode 활성 시)
[3] core/7-shared-definitions.md (FRESH-11)
[4] SUB-SSOT/0-sub-ssot-index.md (라우팅 참조)
[5] SUB-SSOT/TEAM-LEAD/0~1 (오케스트레이션)
```

**팀원 (역할별 세션)**:
```
[1] core/7-shared-definitions.md (FRESH-11, 필수)
[2] SUB-SSOT/{역할}/0-{role}-entrypoint.md
[3] SUB-SSOT/{역할}/1-{procedure}.md
[4] (선택) 추가 파일 (DEV/2, DEV/3 등)
```

---

## 5. SUB-SSOT 라우팅 판정

Team Lead가 팀원 스폰 또는 작업 지시 시 적용하는 판정 플로우:

```
요청 수신
│
├── 코드 작성 필요?
│   ├── YES → fn 단위 요청?
│   │   ├── YES → 호환분석/인프라 변경 수반?
│   │   │   ├── YES → DEV fn 풀 (7-shared + DEV/0~3)     ~33K
│   │   │   └── NO  → DEV fn 기본 (7-shared + DEV/0~1)   ~20K
│   │   └── NO → DEV 단순 Task (7-shared + DEV/0)         ~10K
│   │
│   └── NO ↓
│
├── 계획만 필요?   → PLANNER (7-shared + PLANNER/0~1)     ~13K
├── 코드 리뷰?     → VERIFIER (7-shared + VERIFIER/0~1)   ~14K
├── 테스트 실행?   → TESTER (7-shared + TESTER/0~1)       ~14K
└── Phase 운영?     → 코어 SSOT + TEAM-LEAD               ~65K
```

**SendMessage에 로딩 경로 포함 예시**:
```
"fn 개발 요청입니다. 다음 문서를 순서대로 읽고 작업하세요:
1. docs/core/7-shared-definitions.md
2. docs/SUB-SSOT/DEV/0-dev-entrypoint.md
3. docs/SUB-SSOT/DEV/1-fn-procedure.md"
```

---

## 6. 공통 레이어 (core/7-shared-definitions.md) 인덱스

모든 SUB-SSOT가 `참조: core/7-shared-definitions.md §N.N` 형태로 참조하는 공통 정의:

| 섹션 | 내용 | 주요 사용처 |
|------|------|-------------|
| **§1.1** | GATE 포맷: `[PASS/FAIL/N/A] {항목} — 근거: {한 줄}` | 전 역할 |
| **§1.2** | ANTI-COMPRESSION: "전체 통과" 일괄 선언 = GATE 실패 | 전 역할 |
| **§2.1** | ROLE_CHECK 프로토콜: 각 작업 시작 시 역할 선언 | DEV, VERIFIER |
| **§2.2** | 역할 매핑: CODER→backend-dev/frontend-dev 등 | DEV |
| **§2.3** | 역할 전환 금지: 동일 컨텍스트 CODER→REVIEWER 금지 | DEV, VERIFIER |
| **§3.1** | AMBIGUITY 블록 포맷 | DEV, PLANNER |
| **§3.2** | GOAL_CHANGE_REQUEST 포맷 | DEV |
| **§3.3** | BLOCKER_REVIEW_REQUEST 포맷 | VERIFIER |
| **§3.4** | DELETION_APPROVAL_REQUEST 포맷 | DEV |
| **§3.5** | CHANGE_REQUEST 포맷 | DEV |
| **§3.6** | HUMAN_ESCALATION_REQUEST 포맷 | DEV, TESTER |
| **§3.7** | SCOPE_REDUCTION_PROPOSAL 포맷 | DEV |
| **§3.8** | CONFLICT_APPROVAL_REQUEST 포맷 | DEV |
| **§3.9** | SCHEMA_CHANGE_APPROVAL 포맷 | DEV |
| **§3.10** | DEPENDENCY_CONFLICT 포맷 | DEV |
| **§4.1** | DEVIATION 기록 포맷 | DEV |
| **§4.2** | VAL 결과 포맷 (명령 + stdout 3줄 + 결과) | DEV, TESTER |
| **§4.3** | FAIL_COUNTER (동일 항목 3회→에스컬레이션, 30%→복귀) | DEV, TESTER |
| **§5.1** | 충돌 분류 Type A~E + 각 대응 (HALT/LOG) | DEV |
| **§5.2** | 충돌 파일 포맷 (conflict-{datetime}.md) | DEV |
| **§6.1** | VUL1: 샘플 코드 경계 (5개 검사) | DEV |
| **§6.2** | VUL2: 호환성 충돌 (5개 검사) | DEV |
| **§6.3** | VUL3: 범위 무결성 (5개 검사) | DEV |
| **§7.1** | Hotfix 예외 (1파일, 신규 fn 없음, 기존 테스트 통과) | 전 역할 |
| **§7.2** | Minor Change 예외 (5줄 이하, 신규 fn/class/API 없음) | 전 역할 |
| **§7.3** | Pattern Reuse 예외 (3회+ 적용, 인간 승인) | DEV |
| **§7.4** | POC/Spike 예외 (폐기 전제, 격리 디렉토리) | DEV |

---

## 7. 코어 SSOT (0~5) 요약

| 문서 | 핵심 내용 |
|------|-----------|
| **0-entrypoint** | SSOT 진입점. 역할별 필독 체크리스트(9역할), 코어 개념(팀 구조, 20개 상태, Hub-and-Spoke), LOCK 규칙 5개, FRESH 규칙 12개(1~9 기존 + 10~12 6th 신규), ENTRYPOINT 규칙 5개, G0~G4 게이트, 도메인 태그, 팀 라이프사이클, 5th 혁신 5축 |
| **1-project** | Personal AI Brain v3 프로젝트 정의. 팀 구성(Team Lead + 5 core + Research Team 3). 역할별 subagent_type/model 매핑. 코드 편집 도메인(`[BE]`/`[FE]`/`[DB]`/`[FS]`). Hub-and-Spoke 통신. Research Team 라이프사이클(5th) |
| **2-architecture** | Docker Compose 인프라(PostgreSQL 5433, Qdrant 6343, Redis 6380, Backend 8001). FastAPI + SQLAlchemy ORM(raw SQL 금지) + Pydantic v2. Vanilla JS + ESM + Bootstrap 5 로컬 + Jinja2 SSR. 코드 규칙(타입 힌트, innerHTML+esc(), CDN 금지) |
| **3-workflow** | ENTRYPOINT 규칙(status.md 단일 진입). 20개 상태 머신(4th 14개 + 5th 6개). 상태별 Action Table. G0~G4 판정 기준. Error Handling(E0~E4). Phase Chain 15개 CHAIN 규칙. 컨텍스트 복구 프로토콜 7단계. 리팩토링 레지스트리(500/700/1000줄) |
| **4-event-protocol** | JSONL 이벤트 로그(8 event types). Heartbeat 프로토콜(5~10분). Watchdog SLA(역할별 타임아웃). 상태 전이 로깅. Git 체크포인트. 로그 관리(10MB 경고). (5th 확장) |
| **5-automation** | Artifact Persister(CHAIN-6 자동 검증). AutoReporter(Task/상태/게이트 보고). DecisionEngine(AUTO_FIX 6조건 AND, 최대 3회). ContextRecoveryManager(FRESH-7 7단계). Git Checkpoint(태그/REWINDING/A-B 브랜치). (5th 확장) |

---

## 8. DEV SUB-SSOT 상세

### 8.1 구성

| 파일 | 역할 | 필수/선택 |
|------|------|-----------|
| `0-dev-entrypoint.md` | 진입점, 역할 매핑, 로딩 집합, IMPL_GRANULARITY 판정 | 필수 |
| `1-fn-procedure.md` | fn 8 PHASE 절차 (PHASE 0~7), GATE 0~7 | 필수 |
| `2-ai-execution-rules.md` | 5역할 페르소나(PLANNER/CODER/REVIEWER/VALIDATOR/HUMAN), STEP별 실행 규칙 | 선택 |
| `3-failure-modes.md` | 24개 실패 모드(BE 4/FE 3/DB 3/Infra 3/Process 8/Context 7), 우선순위 P1~P4 | 선택 |

### 8.2 PHASE 0~7 요약

| PHASE | 이름 | ROLE | 핵심 활동 | 산출물 |
|-------|------|------|-----------|--------|
| 0 | 요청 수신 및 분류 | PLANNER | 구조 분해, AMBIGUITY 처리, IMPL_GRANULARITY 선언 | `request-brief.md` |
| 1 | 요구사항 분석 | PLANNER | FR/NF/제약 분석, 호출 체인 역추적, 단위 흐름 정의 | `requirements.md` |
| 2 | DB 스키마 & API 설계 | PLANNER | 테이블 전수 조사, 쿼리 전략, API_CONTRACT_LOCK | `schema-analysis.md`, `api-contract.md` |
| 3 | Spike 테스트 | CODER→REVIEWER | 핵심 1~2개 실행, NF 예비 측정, GO/NO-GO | `spike-result.md` |
| 4 | 호환 분석 | PLANNER+REVIEWER | 연결 지점, 시그니처 충돌(Type A~E), 회귀 기준선 | `compatibility-report.md` |
| 5 | 라이브러리 검토 | PLANNER | 공통 모듈 재사용, 선택 매트릭스, 의존성 충돌 검사 | `library-review.md` |
| 6 | 인프라 점검 | PLANNER+VALIDATOR | NF vs 인프라 갭, 해결 방안, 설정 변경 목록 | `infra-review.md` |
| 7 | 구현 및 검증 | CODER→REVIEWER→VALIDATOR | 구현, 코드 리뷰, VAL 검증, 회귀 테스트, NF 실측 | `result.md`, 프로덕션 코드 |

### 8.3 산출물 디렉토리

```
docs/plans/{feature-name}/
├── request-brief.md        # PHASE 0
├── requirements.md         # PHASE 1
├── schema-analysis.md      # PHASE 2
├── api-contract.md         # PHASE 2 (잠금)
├── spike-result.md         # PHASE 3
├── compatibility-report.md # PHASE 4
├── library-review.md       # PHASE 5
├── infra-review.md         # PHASE 6
└── result.md               # PHASE 7
```

### 8.4 원본 참조

SUB-SSOT/DEV의 각 파일은 `_backup/GUIDES/DEV-work-guide/` 원본의 축약본:

| SUB-SSOT | 원본 | 축약률 |
|----------|------|--------|
| DEV/0-dev-entrypoint (4.1KB) | DEV-work-guide/0-workflow-system-overview (24KB) | 83% |
| DEV/1-fn-procedure (7.8KB) | DEV-work-guide/4-fn-dev-field-procedure-v1 (32KB) | 76% |
| DEV/2-ai-execution-rules (4.9KB) | DEV-work-guide/2-ai-harness-dev-procedure (30KB) | 84% |
| DEV/3-failure-modes (5.5KB) | DEV-work-guide/3-dev-problem-analysis (33KB) | 83% |

---

## 9. 다른 역할 SUB-SSOT 요약

### 9.1 PLANNER

| 파일 | 핵심 내용 |
|------|-----------|
| `0-planner-entrypoint` | 로딩 체크리스트, G1 판정 기준, 핵심 원칙(3~7 Task, 도메인 태그, 측정 가능 DoD) |
| `1-planning-procedure` | 5단계 플로우(수신→분석→분해→G1 점검→보고), TODO 형식(done_when/verify_by/complexity/risk), 복잡도 티어(HIGH/MED/LOW) |

### 9.2 VERIFIER

| 파일 | 핵심 내용 |
|------|-----------|
| `0-verifier-entrypoint` | 로딩 체크리스트, REVIEWER 페르소나(별도 컨텍스트 필수), G2 기준(Critical 0 = PASS) |
| `1-verification-procedure` | 7단계 검증 플로우, REVIEWER 8항목 체크리스트(AUTH/SCHEMA/N+1/CONTRACT/COMMON/PROTOTYPE/DEVIATION/INFRA), PARTIAL→AUTO_FIX(6조건 AND, 최대 3회), 11명 Council(5th) |

### 9.3 TESTER

| 파일 | 핵심 내용 |
|------|-----------|
| `0-tester-entrypoint` | 로딩 체크리스트, VALIDATOR 페르소나, G3 기준(pytest PASS + 커버리지 80%) |
| `1-testing-procedure` | 4단계 테스트 플로우(수집→등록→실행→기록), pytest 동기 실행(xdist 금지), 1주기=요청서+결과서, 결함 분류(Critical/Major/Minor/Trivial), 밀도 5/KLOC 이하 |

### 9.4 TEAM-LEAD

| 파일 | 핵심 내용 |
|------|-----------|
| `0-lead-entrypoint` | 로딩 체크리스트, HR-1~HR-7 요약, SUB-SSOT 라우팅 판단 테이블 |
| `1-orchestration-procedure` | 6단계 Phase 오케스트레이션, Gate 판정(G0~G4 소유·기준), 에이전트 라이프사이클(LIFECYCLE-1~4), 지연 스폰, Phase Chain 운영, 외부 질의 대응(HR-1/EDIT-2) |

---

## 10. FRESH 규칙 전체 (1~12)

| 규칙 | 내용 | 시점 |
|------|------|------|
| **FRESH-1** | 세션 시작 시 SSOT 0→1→2→3 로드 | Team Lead 세션 시작 |
| **FRESH-2** | 새 Phase 시작 시 ssot_version 확인 | Phase 시작 전 |
| **FRESH-3** | 버전 불일치 시 SSOT 리로드 우선 | 버전 감지 시 |
| **FRESH-4** | 리로드 시각 기록 (`ssot_loaded_at`) | SSOT 로딩 완료 시 |
| **FRESH-5** | 장기 세션 중 주기적 확인 (Task 3개+) | 진행 중 |
| **FRESH-6** | 팀원 스폰 시 ROLES/*.md 1개 로딩 | 팀원 스폰 시 |
| **FRESH-7** | 컨텍스트 복구 시 SSOT 리로드 필수 | 압축/중단 후 |
| **FRESH-8** | 리팩토링 레지스트리 관리 (500줄→등록) | Phase 완료 시 |
| **FRESH-9** | 실행 단위 컨텍스트 권장 로딩 집합 | 작업 1회 시작 시 |
| **FRESH-10** | SUB-SSOT 선택적 로딩 허용 | 역할별 세션 시작 시 |
| **FRESH-11** | SUB-SSOT 시 core/7-shared 필수 선행 로딩 | SUB-SSOT 로딩 전 |
| **FRESH-12** | SUB-SSOT 단독 실행 가능 (코어 없이) | 팀원 세션 |

---

## 11. GATE 체계 (G0~G4)

```
[G0: Research Review]   5th 신규. Research Team 조사 완료 + 대안 2개+ + 리스크 분석
  ↓
[G1: Plan Review]       planner 분석 → Team Lead 검토. Task 3~7개, 도메인 분류, 리스크
  ↓
[G2: Code Review]       verifier → Team Lead. Critical 0건 = PASS, High만 = PARTIAL
  ↓
[G3: Test Gate]         tester → Team Lead. pytest PASS + 커버리지 80% + E2E PASS
  ↓
[G4: Final Gate]        Team Lead. G2 PASS + G3 PASS + Blocker 0건
```

| 게이트 | 소유자 | PASS 조건 | FAIL 시 |
|--------|--------|-----------|---------|
| G0 | Team Lead | 조사 완료 + 대안 2+ + 리스크 | RESEARCH 재실행 |
| G1 | Team Lead | 완료 기준 명확 + Task 3~7 + 도메인 분류 | PLANNING 재실행 |
| G2 | Team Lead (verifier 보고) | Critical 0건 | PARTIAL→AUTO_FIX(최대 3회) 또는 REWINDING |
| G3 | Team Lead (tester 보고) | pytest PASS + 80%+ + E2E PASS | TESTING 재실행 |
| G4 | Team Lead | G2+G3 PASS + Blocker 0 | Phase 미완료 |

---

## 12. 토큰 효율 비교 (실측 기반)

> 바이트 실측(`wc -c`), 토큰 변환 ×0.38 (한영 혼합 Markdown)

### 12.1 파일 크기 실측

| 구분 | 바이트 | 토큰 (추정) |
|------|--------|-------------|
| SSOT 코어 0~5 합계 | 151,823 | ~58K |
| core/7-shared-definitions | 11,518 | ~4K |
| SUB-SSOT/DEV 4파일 합계 | 22,432 | ~9K |
| SUB-SSOT/PLANNER 2파일 | 4,476 | ~2K |
| SUB-SSOT/VERIFIER 2파일 | 5,359 | ~2K |
| SUB-SSOT/TESTER 2파일 | 4,774 | ~2K |
| SUB-SSOT/TEAM-LEAD 2파일 | 4,919 | ~2K |
| SUB-SSOT/index | 3,894 | ~1K |

### 12.2 시나리오별 비교

| 시나리오 | ver5-1 (토큰) | ver6-0 SUB-SSOT (토큰) | 절감 |
|----------|---------------|------------------------|------|
| fn 개발 (기본) | ~57K | **~13K** (shared 4K + DEV/0 2K + DEV/1 3K + ROLES 2K + arch-partial 2K) | **77%** |
| fn 개발 (풀) | ~57K | **~19K** (shared 4K + DEV/0~3 9K + ROLES 2K + arch 4K) | **67%** |
| Planner | ~28K | **~8K** (shared 4K + PLANNER 2K + ROLES 2K) | **71%** |
| Verifier | ~27K | **~8K** (shared 4K + VERIFIER 2K + ROLES 2K) | **70%** |
| Tester | ~27K | **~8K** (shared 4K + TESTER 2K + ROLES 2K) | **70%** |
| Team Lead | ~58K | **~67K** (코어 58K + shared 4K + LEAD 2K + index 1K + ROLES 2K) | +16% |

---

## 13. 마이그레이션 가이드 (ver5-1 → ver6-0)

### 13.1 필수 작업

| 단계 | 작업 | 명령/방법 |
|------|------|-----------|
| 1 | ver6-0 폴더를 프로젝트에 배치 | `cp -r ver6-0/ {target}` |
| 2 | 기존 phase-status.md의 ssot_version 갱신 | `sed -i 's/7.0-renewal-5th/8.0-renewal-6th/' docs/phases/*/phase-*-status.md` |
| 3 | CLAUDE.md에 SSOT 진입점 경로 변경 | `docs/SSOT-NEW/0-entrypoint.md` → ver6-0 경로 |

### 13.2 선택 작업 (점진적 도입)

| 단계 | 작업 | 효과 |
|------|------|------|
| 4 | 팀원 스폰 시 SUB-SSOT 경로 지시 추가 | 즉시 토큰 절감 |
| 5 | _backup/GUIDES/DEV-work-guide/ (백업) — 필요 시 FROZEN 선언 유지 | 이중 경로 동기화 관리 |
| 6 | ssot-reload 스킬에 SUB-SSOT 로딩 옵션 추가 | 자동화 |

### 13.3 하위 호환성

- FRESH-1~9 기존 로딩 경로는 **그대로 동작**
- SUB-SSOT 로딩은 **opt-in** (기존 방식을 대체하지 않고 추가)
- 20개 상태 머신, G0~G4, 5th_mode 플래그 모두 동일

---

## 14. 참조 문서 인덱스

### 14.1 코어

| 문서 | 경로 |
|------|------|
| 진입점 | [0-entrypoint.md](0-entrypoint.md) |
| 프로젝트 | [1-project.md](1-project.md) |
| 아키텍처 | [2-architecture.md](2-architecture.md) |
| 워크플로우 | [3-workflow.md](3-workflow.md) |
| 이벤트 프로토콜 | [4-event-protocol.md](4-event-protocol.md) |
| 자동화 | [5-automation.md](5-automation.md) |
| 규칙 인덱스 | [core/6-rules-index.md](core/6-rules-index.md) |
| 공통 정의 | [core/7-shared-definitions.md](core/7-shared-definitions.md) |

### 14.2 SUB-SSOT

| SUB-SSOT | 진입점 | 절차서 |
|----------|--------|--------|
| 라우팅 | [0-sub-ssot-index.md](SUB-SSOT/0-sub-ssot-index.md) | — |
| DEV | [DEV/0-dev-entrypoint.md](SUB-SSOT/DEV/0-dev-entrypoint.md) | [1-fn-procedure.md](SUB-SSOT/DEV/1-fn-procedure.md) |
| PLANNER | [PLANNER/0-planner-entrypoint.md](SUB-SSOT/PLANNER/0-planner-entrypoint.md) | [1-planning-procedure.md](SUB-SSOT/PLANNER/1-planning-procedure.md) |
| VERIFIER | [VERIFIER/0-verifier-entrypoint.md](SUB-SSOT/VERIFIER/0-verifier-entrypoint.md) | [1-verification-procedure.md](SUB-SSOT/VERIFIER/1-verification-procedure.md) |
| TESTER | [TESTER/0-tester-entrypoint.md](SUB-SSOT/TESTER/0-tester-entrypoint.md) | [1-testing-procedure.md](SUB-SSOT/TESTER/1-testing-procedure.md) |
| TEAM-LEAD | [TEAM-LEAD/0-lead-entrypoint.md](SUB-SSOT/TEAM-LEAD/0-lead-entrypoint.md) | [1-orchestration-procedure.md](SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md) |

### 14.3 역할 & 가이드

| 역할 | PERSONA | ROLES | GUIDE | SUB-SSOT |
|------|---------|-------|-------|----------|
| Team Lead | [LEADER.md](PERSONA/LEADER.md) | [team-lead.md](ROLES/team-lead.md) | — | TEAM-LEAD/ |
| Planner | [PLANNER.md](PERSONA/PLANNER.md) | [planner.md](ROLES/planner.md) | [planner-work-guide.md](_backup/GUIDES/planner-work-guide.md) | PLANNER/ |
| Backend Dev | [BACKEND.md](PERSONA/BACKEND.md) | [backend-dev.md](ROLES/backend-dev.md) | [backend-work-guide.md](_backup/GUIDES/backend-work-guide.md) | DEV/ |
| Frontend Dev | [FRONTEND.md](PERSONA/FRONTEND.md) | [frontend-dev.md](ROLES/frontend-dev.md) | [frontend-work-guide.md](_backup/GUIDES/frontend-work-guide.md) | DEV/ |
| Verifier | [QA.md](PERSONA/QA.md) | [verifier.md](ROLES/verifier.md) | [verifier-work-guide.md](_backup/GUIDES/verifier-work-guide.md) | VERIFIER/ |
| Tester | [QA.md](PERSONA/QA.md) | [tester.md](ROLES/tester.md) | [tester-work-guide.md](_backup/GUIDES/tester-work-guide.md) | TESTER/ |
| Research Lead | [RESEARCH_LEAD.md](PERSONA/RESEARCH_LEAD.md) | [research-lead.md](ROLES/research-lead.md) | [research-work-guide.md](_backup/GUIDES/research-work-guide.md) | — |
| Research Architect | [RESEARCH_ARCHITECT.md](PERSONA/RESEARCH_ARCHITECT.md) | [research-architect.md](ROLES/research-architect.md) | — | — |
| Research Analyst | [RESEARCH_ANALYST.md](PERSONA/RESEARCH_ANALYST.md) | [research-analyst.md](ROLES/research-analyst.md) | — | — |

### 14.4 기타

| 문서 | 경로 |
|------|------|
| 버전 이력 | [VERSION.md](VERSION.md) |
| 11명 Council | [QUALITY/10-persona-qc.md](QUALITY/10-persona-qc.md) |
| DEV-work-guide 원본 (백업) | [_backup/GUIDES/DEV-work-guide/](_backup/GUIDES/DEV-work-guide/) |
| 구현 계획 | [../implementation_plan.md](../implementation_plan.md) |

---

## 15. Scripts 가이드

### 15.1 디렉토리 구조

```
scripts/
├── migrations/                          # DB 마이그레이션 (수동 실행)
│   ├── README.md                        # 실행 방법 + 목록
│   ├── __init__.py                      # Python 패키지
│   ├── 001_add_gin_indexes.sql          # GIN 인덱스 4개
│   ├── 002_create_page_access_log.sql   # 페이지 접근 로그 테이블
│   ├── 003_create_system_settings.sql   # 시스템 설정 K-V 테이블
│   ├── 004_create_users_table.sql       # 사용자 인증 테이블
│   ├── backfill_titles_display_ids.py   # Document/Chunk title 역추출
│   └── update_qdrant_payload.py         # Qdrant 벡터 payload 갱신
│
└── pmAuto/
    └── report_to_telegram.sh            # Telegram 알림 발송 (HR-8)
```

### 15.2 DB 마이그레이션

> Alembic 미사용. SQL 스크립트 수동 실행 방식.

**실행 환경**: PostgreSQL 15, DB명: `knowledge`, 사용자: `brain`, 포트: `5433`

#### SQL 마이그레이션 목록

| 번호 | 파일 | 대상 테이블 | Phase | 설명 |
|------|------|------------|-------|------|
| 001 | `001_add_gin_indexes.sql` | knowledge_chunks, conversations, memories | 12-2-3 | GIN 인덱스 4개 (to_tsvector 'simple' 파서, CONCURRENTLY) |
| 002 | `002_create_page_access_log.sql` | page_access_logs | 13-4 | 페이지 접근 로그 테이블 + path/date 인덱스 |
| 003 | `003_create_system_settings.sql` | system_settings | 15-1-1 | K-V 시스템 설정 테이블 (key UNIQUE) |
| 004 | `004_create_users_table.sql` | users | 15-5-1 | 사용자 인증 테이블 (username/role/is_active) |

#### 실행 방법

```bash
# Docker 환경 (권장)
docker exec -i pab-postgres-ver3 psql -U brain -d knowledge \
  < scripts/migrations/001_add_gin_indexes.sql

# 로컬 환경
psql -h localhost -p 5433 -U brain -d knowledge \
  -f scripts/migrations/001_add_gin_indexes.sql
```

#### 주의사항

- `CREATE INDEX CONCURRENTLY`는 트랜잭션 블록 안에서 실행 불가 — autocommit 모드 필수 (`-f` 플래그)
- 대용량 테이블의 인덱스 생성은 수 분 소요 가능
- `IF NOT EXISTS` / `IF NOT EXISTS` 패턴으로 재실행 안전

#### 검증 쿼리

```sql
-- 인덱스 확인
SELECT indexname, tablename FROM pg_indexes
WHERE indexname LIKE 'idx_%' ORDER BY tablename;

-- 테이블 확인
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' ORDER BY table_name;
```

#### Python 마이그레이션

| 파일 | Phase | 설명 | 실행 방법 |
|------|-------|------|-----------|
| `backfill_titles_display_ids.py` | 32-3 | Document/KnowledgeChunk의 title + display_id 역추출 | `python3 -m scripts.migrations.backfill_titles_display_ids` |
| `update_qdrant_payload.py` | 32-3 | Qdrant 벡터 포인트에 title + display_id payload 추가 | `python3 scripts/migrations/update_qdrant_payload.py` |

**실행 순서**: `backfill_titles_display_ids.py` (PostgreSQL) → `update_qdrant_payload.py` (Qdrant)

**의존성**: `backend.models.database.SessionLocal`, `backend.models.models.Document/KnowledgeChunk`, `qdrant_client`

### 15.3 Telegram 알림 (pmAuto)

> HR-8 (NOTIFY-1~3): Phase 완료 시 Telegram 알림 필수

**파일**: `scripts/pmAuto/report_to_telegram.sh`

**사용법**:
```bash
bash scripts/pmAuto/report_to_telegram.sh "PAB-v3" "Phase 21-4 완료: 사용자 인증 구현"
```

**인자**:
| 순번 | 인자 | 예시 |
|------|------|------|
| $1 | 프로젝트명 | `PAB-v3` |
| $2 | 메시지 본문 (Markdown) | `Phase X-Y 완료: {요약}` |

**메시지 형식** (HR-8 규정):
```
[PAB-v3] Phase {N}-{M} 완료: {1줄 요약}
결과: {핵심 수치}
보고서: {경로}
```

**호출 시점**:
- Phase 또는 Sub-Phase가 DONE 상태 도달 시 (알림 없이 DONE 전이 무효)
- Master Plan 전체 완료 시 종합 알림

**설정**: BOT_TOKEN과 CHAT_ID가 스크립트에 하드코딩됨

---

**문서 관리**: v1.0 | 2026-04-13 | ver6-0 (v8.0-renewal-6th) 전체 가이드
