# SUB-SSOT 인덱스 — 라우팅 테이블

> **버전**: 1.1 | **갱신**: 2026-04-15 (Phase-E task-E-2-4 — DEV 축소·VERIFIER/TESTER 확장 반영)
> **용도**: Team Lead가 팀원 스폰 시 어떤 SUB-SSOT를 로딩할지 판단하는 라우팅 허브

---

## §1 SUB-SSOT 목록

| SUB-SSOT | 파일 수 | 토큰 (추정) | 대상 역할 |
|----------|---------|-------------|-----------|
| **공통 레이어** | 1 | ~7K | 모든 역할 |
| **DEV** (v1.1) | 4 | ~22K (필수만 ~18K) | **CODER** (backend-dev / frontend-dev) |
| **PLANNER** | 2 | ~6K | planner |
| **VERIFIER** (v1.1) | 2 | ~10K | **verifier** (REVIEWER 역할 수행) |
| **TESTER** (v1.1) | 2 | ~9.5K | **tester** (VALIDATOR 역할 수행) |
| **TEAM-LEAD** | 2 | ~8K | Team Lead |
| **RESEARCH** (v1.0, 신규) | 4 | ~15K (역할당 ~14K) | **research-lead / research-architect / research-analyst** — 2026-04-15 Phase-E task-E-1 신설 |

---

## §2 라우팅 테이블

### 작업 유형 → 로딩 집합

```
[작업 유형]                    [팀원에게 로딩 지시할 파일]
────────────────────          ──────────────────────────
fn 기본 개발                  core/7-shared + DEV/0-dev + DEV/1-fn   (CODER 전용, v1.1)
fn 풀 (복잡/위험)             core/7-shared + DEV/0~3 전부              (CODER 전용, v1.1)
단순 Task (코드 수정)         core/7-shared + DEV/0-dev
계획 수립                     core/7-shared + PLANNER/0~1
코드 검증 (REVIEWER)          core/7-shared + VERIFIER/0~1              (REVIEWER 통합, v1.1)
코드 테스트 (VALIDATOR)       core/7-shared + TESTER/0~1                (VALIDATOR 통합, v1.1)
기술 조사 (Research Lead)     core/7-shared + RESEARCH/0-research + RESEARCH/1-lead
기술 조사 (Research Architect) core/7-shared + RESEARCH/0-research + RESEARCH/2-architect
기술 조사 (Research Analyst)  core/7-shared + RESEARCH/0-research + RESEARCH/3-analyst
오케스트레이션                SSOT 코어(0~5) + core/7-shared + TEAM-LEAD/0~1 + 본 인덱스
```

### 판단 기준

| 질문 | YES → | NO → |
|------|-------|------|
| 코드 작성이 필요한가? | DEV SUB-SSOT | 비 DEV |
| fn 단위 요청인가? | DEV fn 기본 이상 | DEV 단순 Task |
| 호환 분석·인프라 변경 수반? | DEV fn 풀 (0~3) | DEV fn 기본 |
| 계획만 필요? | PLANNER | — |
| 코드 리뷰만 필요? | VERIFIER | — |
| 테스트 실행만 필요? | TESTER | — |

---

## §3 로딩 플로우 다이어그램

```
Team Lead 진입
  │
  ├── SSOT 코어 로딩 (0~5)
  │
  ├── SUB-SSOT/0-sub-ssot-index.md (본 문서) 참조
  │
  └── 팀원 스폰 시:
      │
      ├── 작업 유형 확인 (§2 라우팅 테이블)
      │
      ├── 해당 SUB-SSOT 경로 결정
      │
      └── SendMessage에 로딩 경로 포함
          │
          팀원 세션 시작
          │
          ├── core/7-shared-definitions.md 로딩 ← (필수)
          │
          ├── {역할}/0-{role}-entrypoint.md 로딩
          │
          └── {역할}/1-{procedure}.md 로딩
              │
              └── 필요 시 추가 파일 로딩 (2,3번)
```

---

## §4 토큰 효율성 비교

| 시나리오 | 현행 (ver5-1) | SUB-SSOT (v1.1) | 절감율 |
|----------|---------------|-----------------|--------|
| fn 기본 (CODER) | ~61K | ~18K | **70%** |
| fn 풀 (CODER) | ~61K | ~27K | **56%** |
| Planner | ~37K | ~13K | **65%** |
| Verifier (REVIEWER 포함) | ~44K | ~17K | **61%** |
| Tester (VALIDATOR 포함) | ~38K | ~16.5K | **57%** |
| Team Lead | ~35K | ~35K + 3K(인덱스) | — |
| Research Lead | ~30K (GUIDES 공유) | ~14K | **53%** |
| Research Architect | ~30K (GUIDES 공유) | ~14K | **53%** |
| Research Analyst | ~30K (GUIDES 공유) | ~14K | **53%** |

---

## §5 파일 경로 목록

```
docs/
├── core/
│   └── 7-shared-definitions.md          ← 공통 레이어
│
└── SUB-SSOT/
    ├── 0-sub-ssot-index.md              ← 본 문서
    │
    ├── DEV/
    │   ├── 0-dev-entrypoint.md
    │   ├── 1-fn-procedure.md
    │   ├── 2-ai-execution-rules.md
    │   └── 3-failure-modes.md
    │
    ├── PLANNER/
    │   ├── 0-planner-entrypoint.md
    │   └── 1-planning-procedure.md
    │
    ├── VERIFIER/
    │   ├── 0-verifier-entrypoint.md
    │   └── 1-verification-procedure.md
    │
    ├── TESTER/
    │   ├── 0-tester-entrypoint.md
    │   └── 1-testing-procedure.md
    │
    ├── RESEARCH/                           ← 2026-04-15 Phase-E task-E-1 신설
    │   ├── 0-research-entrypoint.md
    │   ├── 1-lead-procedure.md
    │   ├── 2-architect-procedure.md
    │   └── 3-analyst-procedure.md
    │
    └── TEAM-LEAD/
        ├── 0-lead-entrypoint.md
        └── 1-orchestration-procedure.md
```

---

**문서 관리**: v1.0, SUB-SSOT 라우팅 인덱스
