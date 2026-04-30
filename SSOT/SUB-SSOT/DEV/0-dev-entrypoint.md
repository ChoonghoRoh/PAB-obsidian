# DEV SUB-SSOT 진입점

> **버전**: 1.1 | **갱신**: 2026-04-15 (Phase-E task-E-2-1 — CODER 전용 축소)
> **SUB-SSOT**: DEV | **대상**: CODER (backend-dev / frontend-dev)
> **REVIEWER·VALIDATOR 역할**: 별도 SUB-SSOT 참조 — `SUB-SSOT/VERIFIER/` (REVIEWER), `SUB-SSOT/TESTER/` (VALIDATOR)

## 개요

DEV SUB-SSOT는 개발 요청(fn / unit / integration)을 처리하는 **CODER(구현 역할)** 를 위한 작업 가이드이다. 공통 레이어(`core/7-shared-definitions.md`)와 함께 로딩하면 SSOT 코어 전체 없이도 완전한 CODER 작업이 가능하다. REVIEWER·VALIDATOR 절차는 각자 SUB-SSOT에서 독립 로딩한다.

---

## §1 로딩 체크리스트

### 1.1 필수 로딩 (모든 DEV 세션)

```
[ ] core/7-shared-definitions.md         — 공통 포맷·규칙 (~7K 토큰)
[ ] SUB-SSOT/DEV/0-dev-entrypoint.md     — 본 문서 (~3K 토큰)
[ ] SUB-SSOT/DEV/1-fn-procedure.md       — fn 절차 (~10K 토큰)
```

### 1.2 선택적 로딩 (상황별)

```
[ ] SUB-SSOT/DEV/2-ai-execution-rules.md — AI 실행 규칙 (~8K 토큰)
    → 첫 세션, 역할 혼동 우려 시, 복잡 작업 시
[ ] SUB-SSOT/DEV/3-failure-modes.md      — 실패 모드 (~5K 토큰)
    → 위험도 높은 작업, 통합 작업, 레거시 코드 수정 시
```

### 1.3 요청 유형별 로딩 집합

| 요청 유형 | 로딩 집합 | 토큰 추정 (v1.1 축소 후) |
|-----------|-----------|---------------------------|
| **단순 Task** | 7-shared + 0-dev-entrypoint | ~9K |
| **fn 기본** | 7-shared + 0-dev + 1-fn-procedure | ~18K |
| **fn 풀** | 7-shared + 0~3 전부 | ~27K |

> v1.0 대비: REVIEWER/VALIDATOR 절차 이관으로 fn 풀 -6K (-18%). REVIEWER/VALIDATOR 로딩은 `SUB-SSOT/VERIFIER/`, `SUB-SSOT/TESTER/` 각 entrypoint 참조.

---

## §2 역할 매핑

### 2.1 DEV 역할 → SSOT 팀원 매핑 (본 SUB-SSOT 범위)

| 절차 역할 | SSOT 팀원 | 컨텍스트 |
|-----------|-----------|----------|
| PLANNER | planner (Plan/opus) | 계획 단계, 코드 작성 금지 |
| CODER | backend-dev (general-purpose/sonnet) | BE 구현, backend/ 편집 |
| CODER | frontend-dev (general-purpose/sonnet) | FE 구현, web/ 편집 |

> **REVIEWER 역할 (verifier, Explore/sonnet)** — 별도 컨텍스트, 읽기 전용: `SUB-SSOT/VERIFIER/` 참조
> **VALIDATOR 역할 (tester, Bash/sonnet)** — 명령 실행, 증거 기반: `SUB-SSOT/TESTER/` 참조

### 2.2 역할 분리 규칙 (CODER 경계)

- CODER와 REVIEWER는 **동일 컨텍스트 금지** (→ `참조: core/7-shared-definitions.md §2.3`)
- 각 STEP/PHASE 시작 시 **ROLE_CHECK** 필수 (→ `참조: core/7-shared-definitions.md §2.1`)

---

## §3 산출물 디렉토리 구조

```
docs/plans/{feature-name}/
├── request-brief.md        # PHASE 0 — 요청 구조 분해
├── requirements.md         # PHASE 1 — FR/NF/제약조건
├── schema-analysis.md      # PHASE 2 — DB 스키마 분석
├── api-contract.md         # PHASE 2 — API 계약 (잠금)
├── spike-result.md         # PHASE 3 — Spike 결과
├── compatibility-report.md # PHASE 4 — 기존 기능 호환 분석
├── library-review.md       # PHASE 5 — 라이브러리/공통모듈 검토
├── infra-review.md         # PHASE 6 — 인프라 점검
└── result.md               # PHASE 7 — 구현 결과 + VAL 기록

spike/{feature-name}/
└── spike.{ext}             # PHASE 3 — Spike 코드 (PHASE 7 후 폐기)
```

---

## §4 IMPL_GRANULARITY 판정

요청 수신 시 구현 단위를 먼저 선언한다.

| 단위 | 범위 | TODO 크기 | VAL 범위 |
|------|------|-----------|----------|
| **FN** | 단일 함수/메서드 (파일 1~3, 함수 3~10) | 함수 1개/항목 | 단위 테스트 |
| **UNIT** | 단일 모듈/클래스 + 테스트 | 모듈 1개/항목 | 모듈 테스트 |
| **INTEGRATION** | 복수 모듈 E2E 연동 | 서비스 1개/항목 | E2E 테스트 |
| **SYSTEM** | BE + FE + DB + Infra 교차 | 서비스 1개/항목 | 전체 통합 |

---

## §5 레거시 원본 참조

DEV SUB-SSOT의 원본 문서는 `_backup/GUIDES/DEV-work-guide/`에 레거시 참조용으로 보존된다 (2026-04-14 backup 이동):

| SUB-SSOT 파일 | 원본 파일 |
|---------------|-----------|
| `1-fn-procedure.md` | `_backup/GUIDES/DEV-work-guide/4-fn-dev-field-procedure-v1.md` |
| `2-ai-execution-rules.md` | `_backup/GUIDES/DEV-work-guide/2-ai-harness-dev-procedure.md` |
| `3-failure-modes.md` | `_backup/GUIDES/DEV-work-guide/3-dev-problem-analysis.md` |
| (본 문서) | `_backup/GUIDES/DEV-work-guide/0-workflow-system-overview.md` |

상세 참조가 필요한 경우에만 원본 파일을 추가 로딩한다.

---

## §6 Heartbeat 프로토콜 (5th 확장, Phase-F 이관)

`5th_mode.event: true` 환경에서는 **BUILDING 상태 동안 5분 주기 Heartbeat 이벤트** 발신 (→ `4-event-protocol.md §2`).

| 항목 | 내용 |
|------|------|
| 주기 | 5분 (BUILDING 상태) |
| 페이로드 | 현재 Task·진행률(%)·현재 작업 내용 |
| 미발신 시 | Watchdog 리마인드 → 에스컬레이션 → BLOCKED 전이 |
| 발신 방법 | JSONL 이벤트 로그 `event_type: "heartbeat"` |

```json
{"timestamp":"...","agent":"backend-dev","event_type":"heartbeat","state":"working","detail":{"task":"X-Y-N","progress":60,"current_action":"API 엔드포인트 구현 중"},"phase_id":"X-Y"}
```

FE 예시 (`agent`만 `frontend-dev`):
```json
{"timestamp":"...","agent":"frontend-dev","event_type":"heartbeat","state":"working","detail":{"task":"X-Y-N","progress":40,"current_action":"페이지 컴포넌트 구현 중"},"phase_id":"X-Y"}
```

---

**문서 관리**: v1.1, 2026-04-13 생성 / 2026-04-15 Phase-E·F 갱신, DEV SUB-SSOT 진입점 (CODER 전용)
