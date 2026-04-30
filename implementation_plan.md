# SUB-SSOT 모듈형 로딩 아키텍처 — ver6-0 구현 계획

## 목표

`260413-sub-ssot-architecture-plan.md`에 정의된 SUB-SSOT 모듈형 로딩 아키텍처를 **ver6-0** 폴더에 구현한다. ver5-1의 파일은 수정/삭제하지 않는다.

---

## Phase A: 선행 분석 문서 작성

ver5-1의 `docs/`와 `scripts/` 폴더별 역할과 연결 지점을 설명하는 분석 문서를 작성한다.

### [NEW] docs/analysis/260413-ver5-1-structure-analysis.md

ver5-1의 전체 구조를 docs와 scripts 두 축으로 분석:

| 섹션 | 내용 |
|------|------|
| §1 docs 폴더 | 코어 SSOT(0~5), core/, GUIDES/, ROLES/, PERSONA/, QUALITY/, TEMPLATES/ 역할 |
| §2 scripts 폴더 | migrations/, pmAuto/ 역할 |
| §3 연결 지점 맵 | 문서 간 참조 관계, 역할별 로딩 경로, FRESH 규칙 연결 |
| §4 SUB-SSOT 도입 영향 | 어떤 파일이 SUB-SSOT 소스가 되는지, 어떤 참조가 추가되는지 |

---

## Phase B: ver5-1 → ver6-0 전체 복사

ver5-1 전체를 ver6-0으로 복사한다 (원본 보존).

```
xcopy /E /I "ver5-1" "ver6-0"
```

---

## Phase C: SUB-SSOT 아키텍처 구현 (ver6-0 내에서)

`260413-sub-ssot-architecture-plan.md`에 따라 14개 신규 파일 생성 + 1개 파일 수정.

### Phase C-1: 공통 레이어 생성

#### [NEW] ver6-0/docs/core/7-shared-definitions.md (~7K 토큰)

공통 포맷 정의를 한 곳에 집중:

| 섹션 | 내용 | 원본 출처 |
|------|------|-----------|
| §1 GATE 공통 규칙 | GATE_FORMAT, ANTI_COMPRESSION | DEV 파일2 §CTX-04, 파일4 §0 |
| §2 역할 시스템 | ROLE_CHECK, 역할 매핑 테이블, 전환 금지 | DEV 파일2 §1, §CTX-06 |
| §3 승인 프로토콜 | AMBIGUITY, GOAL_CHANGE, BLOCKER 등 10개 블록 포맷 | DEV 파일2 §6, 파일4 §9 |
| §4 산출물 포맷 | DEVIATION, VAL_RESULT, FAIL_COUNTER | DEV 파일2 §2.7, 파일4 §7.4 |
| §5 충돌 분류 | Type A~E 정의, 충돌 파일 포맷 | DEV 파일2 VUL2 |
| §6 VUL 체크리스트 | VUL1(경계), VUL2(충돌), VUL3(범위) | DEV 파일2 §3 |

---

### Phase C-2: DEV SUB-SSOT 생성

#### [NEW] ver6-0/docs/SUB-SSOT/DEV/0-dev-entrypoint.md (~3K 토큰)
- DEV SUB-SSOT 로딩 체크리스트
- 역할 매핑 (CODER→backend-dev/frontend-dev, REVIEWER→verifier 등)
- 요청 유형별 로딩 집합 (단순 Task / fn 기본 / fn 풀)
- 산출물 디렉토리 구조

#### [NEW] ver6-0/docs/SUB-SSOT/DEV/1-fn-procedure.md (~10K 토큰)
- 원본: `GUIDES/DEV-work-guide/4-fn-dev-field-procedure-v1.md`
- PHASE 0~7 전체 유지, GATE 포맷→공통 참조로 대체, 예외 처리 4조항 추가

#### [NEW] ver6-0/docs/SUB-SSOT/DEV/2-ai-execution-rules.md (~8K 토큰)
- 원본: `GUIDES/DEV-work-guide/2-ai-harness-dev-procedure.md`
- 5개 역할 페르소나 유지, VUL 포맷→공통 참조로 대체

#### [NEW] ver6-0/docs/SUB-SSOT/DEV/3-failure-modes.md (~5K 토큰)
- 원본: `GUIDES/DEV-work-guide/3-dev-problem-analysis.md`
- 24개 PROBLEM 목록 유지, Recommended fix 1줄 요약으로 압축

---

### Phase C-3: 다른 역할 SUB-SSOT 생성

#### PLANNER (2파일, ~6K)
- [NEW] ver6-0/docs/SUB-SSOT/PLANNER/0-planner-entrypoint.md
- [NEW] ver6-0/docs/SUB-SSOT/PLANNER/1-planning-procedure.md

#### VERIFIER (2파일, ~7K)
- [NEW] ver6-0/docs/SUB-SSOT/VERIFIER/0-verifier-entrypoint.md
- [NEW] ver6-0/docs/SUB-SSOT/VERIFIER/1-verification-procedure.md

#### TESTER (2파일, ~7K)
- [NEW] ver6-0/docs/SUB-SSOT/TESTER/0-tester-entrypoint.md
- [NEW] ver6-0/docs/SUB-SSOT/TESTER/1-testing-procedure.md

#### TEAM-LEAD (2파일, ~8K)
- [NEW] ver6-0/docs/SUB-SSOT/TEAM-LEAD/0-lead-entrypoint.md
- [NEW] ver6-0/docs/SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md

---

### Phase C-4: 연결 구조 최종화

#### [NEW] ver6-0/docs/SUB-SSOT/0-sub-ssot-index.md
- 전체 SUB-SSOT 목록
- 라우팅 테이블 (작업 유형 → 로딩 집합)
- 로딩 플로우 다이어그램

#### [MODIFY] ver6-0/docs/0-entrypoint.md
- §4 SUB-SSOT 라우팅 섹션 추가
- §2 역할별 체크리스트에 SUB-SSOT 참조 1줄씩 추가
- §3.5 FRESH 규칙에 FRESH-10/11/12 추가

---

## Phase D: 검증

### 자동 검증
1. **파일 존재 확인**: ver6-0에 14개 신규 파일 + 수정된 entrypoint 존재 확인
2. **ver5-1 무변경 확인**: ver5-1 디렉토리 해시 비교
3. **참조 무결성**: 각 SUB-SSOT 내 `참조: core/7-shared-definitions.md §N` 링크 검증
4. **토큰 추정**: `wc -c` 기반 각 SUB-SSOT 경로의 실제 토큰 추정

### 수동 검증
- 각 SUB-SSOT를 공통 레이어와 함께 단독 로딩하여 역할 작업 가능 여부 확인

---

## 파일 변경 총 목록

| # | 파일 | 작업 |
|---|------|------|
| 1 | `docs/analysis/260413-ver5-1-structure-analysis.md` | 신규 (선행 분석) |
| 2 | `ver6-0/` (전체) | ver5-1 복사 |
| 3 | `ver6-0/docs/core/7-shared-definitions.md` | 신규 |
| 4 | `ver6-0/docs/SUB-SSOT/0-sub-ssot-index.md` | 신규 |
| 5 | `ver6-0/docs/SUB-SSOT/DEV/0-dev-entrypoint.md` | 신규 |
| 6 | `ver6-0/docs/SUB-SSOT/DEV/1-fn-procedure.md` | 신규 |
| 7 | `ver6-0/docs/SUB-SSOT/DEV/2-ai-execution-rules.md` | 신규 |
| 8 | `ver6-0/docs/SUB-SSOT/DEV/3-failure-modes.md` | 신규 |
| 9 | `ver6-0/docs/SUB-SSOT/PLANNER/0-planner-entrypoint.md` | 신규 |
| 10 | `ver6-0/docs/SUB-SSOT/PLANNER/1-planning-procedure.md` | 신규 |
| 11 | `ver6-0/docs/SUB-SSOT/VERIFIER/0-verifier-entrypoint.md` | 신규 |
| 12 | `ver6-0/docs/SUB-SSOT/VERIFIER/1-verification-procedure.md` | 신규 |
| 13 | `ver6-0/docs/SUB-SSOT/TESTER/0-tester-entrypoint.md` | 신규 |
| 14 | `ver6-0/docs/SUB-SSOT/TESTER/1-testing-procedure.md` | 신규 |
| 15 | `ver6-0/docs/SUB-SSOT/TEAM-LEAD/0-lead-entrypoint.md` | 신규 |
| 16 | `ver6-0/docs/SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md` | 신규 |
| 17 | `ver6-0/docs/0-entrypoint.md` | 수정 |

> [!IMPORTANT]
> ver5-1의 파일은 **일절 수정/삭제하지 않습니다**. 모든 변경은 ver6-0 내에서만 이루어집니다.

---

## Open Questions

1. **ver5-1의 분석 관련 .md 파일들** (`5th-generation-vision.md`, `5th-ssot-analysis-report.md`, `harness-comparison-report.md` 등)도 ver6-0에 그대로 복사할지, 아니면 제외할지?
2. **GUIDES/DEV-work-guide/** 원본 파일들은 ver6-0에서도 레거시 참조용으로 유지하는 것이 맞는지?
