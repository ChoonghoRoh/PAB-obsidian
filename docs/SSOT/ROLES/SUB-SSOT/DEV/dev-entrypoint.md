# DEV SUB-SSOT 진입점

> **SUB-SSOT**: DEV | **대상**: CODER (backend-dev / frontend-dev)

## 개요

DEV SUB-SSOT는 개발 요청(fn / unit / integration)을 처리하는 **CODER(구현 역할)** 를 위한 작업 가이드이다. 공통 레이어(`CORE/shared-definitions.md`)와 함께 로딩하면 SSOT 코어 전체 없이도 완전한 CODER 작업이 가능하다. REVIEWER·VALIDATOR 절차는 각자 SUB-SSOT에서 독립 로딩한다.

---

## §1 로딩 체크리스트

스폰 때는 base 세트(`entrypoint.md` 스폰 주입표의 dev 행)만 읽는다(FRESH-6). 아래 DEV SUB-SSOT는 Team Lead가 지시한 만큼 추가로 읽는다. 지시 밖의 SSOT가 필요하면 읽기 전에 `[SSOT 요청] {문서·절} — {사유}`로 요청한다(HANDOFF-3).

### 1.1 필수 로딩 (DEV SUB-SSOT를 읽을 때)

```
[ ] CORE/shared-definitions.md         — 공통 포맷·규칙
[ ] ROLES/SUB-SSOT/DEV/dev-entrypoint.md     — 본 문서
```

> **제품 코드 주석**: 제품 코드 구역(`PROJECT.md` §3)의 코드·마크업 주석은 누가 쓰든(위치 기준 — COMMENT-1) `docs/comment-policy/comment-policy.md`(형식·금지·포인터·읽을 때) + 하네스 `scripts/comment/comment-lint.py`를 따르고, 위반은 NOTE-1~6이다 — 등급은 VP §G2 판정 기준 「등급 산출」 표. 건드리는 블록만 규격으로 바꾸고 판정은 `lint --changed`(COMMENT-2)와 `points <대상>` 죽은 참조 0(파일 단위 — NOTE-6)으로 한다. 그 구역 밖 하네스 코드 · 문서는 COMMENT-1.

### 1.2 선택적 로딩 (상황별)

```
[ ] ROLES/SUB-SSOT/DEV/fn-procedure.md       — fn 절차
    → fn 기본 개발(아래 §1.3)
[ ] ROLES/SUB-SSOT/DEV/ai-execution-rules.md — AI 실행 규칙
    → 첫 세션, 역할 혼동 우려 시, 복잡 작업 시
[ ] ROLES/SUB-SSOT/DEV/failure-modes.md      — 실패 모드
    → 위험도 높은 작업, 통합 작업, 레거시 코드 수정 시
```

### 1.3 요청 유형별 로딩 집합

| 요청 유형 | 로딩 집합 |
|-----------|-----------|
| **단순 Task** | shared-definitions + dev-entrypoint |
| **fn 기본** | shared-definitions + dev-entrypoint + fn-procedure |
| **fn 풀** | shared-definitions + DEV 전부 |

---

## §2 역할 매핑

### 2.1 DEV 역할 → SSOT 팀원 매핑 (본 SUB-SSOT 범위)

| 절차 역할 | SSOT 팀원 | 컨텍스트 |
|-----------|-----------|----------|
| PLANNER | 담당 dev(backend-dev · frontend-dev) — fn 절차의 계획 단계를 맡는다(`CORE/shared-definitions.md` §2.2) | 계획 산출물(`docs/plans/`) 작성, 계획 단계에서는 제품 코드 작성 금지 |
| CODER | backend-dev (pab-backend-dev / opus) | BE 구현, 담당 구역(`PROJECT.md` §3) 편집 |
| CODER | frontend-dev (pab-frontend-dev / opus) | FE 구현, 담당 구역(`PROJECT.md` §3) 편집 |

> **REVIEWER 역할 (verifier, pab-verifier / opus)** — 별도 컨텍스트, 읽기 전용
> **VALIDATOR 역할 (tester, pab-tester / opus)** — 명령 실행, 증거 기반

### 2.2 역할 분리 규칙 (CODER 경계)

- CODER와 REVIEWER는 **동일 컨텍스트 금지**
- 각 STEP/PHASE 시작 시 **ROLE_CHECK** 필수

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

- Spike는 `spike/` 대신 자율 worktree(WT-8, `WORKFLOW/handoff/common.md` §3)에서 해도 된다 — 채택된 설계는 BUILDING에서 담당 구역에 다시 구현한다.

---

## §4 IMPL_GRANULARITY 판정

요청 수신 시 구현 단위를 먼저 선언한다.

| 단위 | 범위 | TODO 크기 | VAL 범위 |
|------|------|-----------|----------|
| **FN** | 단일 함수/메서드 (파일 1~3, 함수 3~10) | 함수 1개/항목 | 단위 테스트 |
| **UNIT** | 단일 모듈/클래스 + 테스트 | 모듈 1개/항목 | 모듈 테스트 |
| **INTEGRATION** | 복수 모듈 E2E 연동 | 서비스 1개/항목 | E2E 테스트 |
| **SYSTEM** | BE + FE + DB + Infra 교차 | 서비스 1개/항목 | 전체 통합 |
