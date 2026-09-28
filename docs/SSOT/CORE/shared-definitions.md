# shared-definitions.md — SUB-SSOT 공통 포맷 정의 레이어

> **용도**: 모든 SUB-SSOT에서 공통으로 참조하는 포맷·규칙 정의

## 개요

SUB-SSOT 간 중복을 제거하고 일관성을 보장하기 위해, 여러 역할에서 공통으로 사용하는 포맷·규칙을 이 파일에 집중 정의한다. 각 SUB-SSOT에서는 `참조: CORE/shared-definitions.md §N`으로 이 파일을 참조한다.

---

## §1 GATE 공통 규칙

### 1.1 GATE 포맷 (GATE_FORMAT)

모든 GATE 체크리스트 항목은 개별 라인으로 판정한다.

```
[PASS/FAIL/N/A] {체크리스트 항목 텍스트}
                — 근거: {1줄 증거}
```

**금지사항**: "전체 통과", "모든 항목 확인" 같은 일괄 선언은 **GATE 실패**로 자동 처리된다.

### 1.2 ANTI-COMPRESSION 규칙

```
ANTI-COMPRESSION RULE:
  각 체크리스트 항목은 반드시 자체 줄에 개별 응답.
  일괄 응답("all items confirmed")은 무효이며 GATE 재평가 필수.

  형식:
    [PASS] {항목} — evidence: {1줄 증거}
    [FAIL] {항목} — reason: {실패 사유}
    [N/A]  {항목} — reason: {미해당 사유}
```

---

## §2 역할 시스템

### 2.1 ROLE_CHECK 프로토콜

모든 STEP/PHASE 시작 시 역할을 선언한다.

```
ROLE_CHECK
현재 역할    : {PLANNER / CODER / REVIEWER / VALIDATOR}
현재 STEP    : {N}
금지 행동    :
  PLANNER  : 실행 코드 작성
  CODER    : 자기 코드 리뷰, 범위 축소
  REVIEWER : 수정 코드 작성, 증거 없는 승인
  VALIDATOR: 구두 확인 수락, Fail 카운터 리셋
확인         : "나는 {역할}로서 금지 행동을 수행하지 않는다."
```

### 2.2 역할 매핑 테이블

| 절차 역할 | SSOT 팀원 | 비고 |
|-----------|-----------|------|
| PLANNER | planner (Phase 계획) · 담당 dev (`ROLES/SUB-SSOT/DEV/fn-procedure.md`의 PLANNER 단계) | planner는 파일 쓰기 없음(REPORT-1 결과 파일만 — EDIT-4) · 코드 금지. fn 절차의 PLANNER 단계 산출 파일은 담당 dev가 쓴다 |
| CODER | backend-dev, frontend-dev | 도메인별 코드 수정 |
| REVIEWER | verifier | 별도 컨텍스트 필수 |
| VALIDATOR | tester | 명령어 실행 증거 필수 |
| HUMAN | 인간 승인자 | 트리거 시 대기 |

### 2.3 역할 전환 금지

- CODER와 REVIEWER는 **동일 컨텍스트에서 전환 금지**.
- 옵션: A) 별도 세션 (권장), C) 인간 리뷰.

---

## §3 승인 프로토콜

### 3.1 AMBIGUITY 블록

```
---AMBIGUITY---
항목      : {대상 항목}
문제      : {무엇이 불명확}
선택지    : A) {해석A}  B) {해석B}
AI 가정   : {선택 + 이유}
인간 결정 : [여기에 입력]
---END_AMBIGUITY---
```

### 3.2 GOAL_CHANGE_REQUEST

```
---GOAL_CHANGE_REQUEST---
요청자       : {어느 STEP에서}
변경 내용    : {무엇을 변경}
사유         : {현재 목표가 왜 문제인가}
영향         : {하류 STEP 영향}
인간 결정    : [APPROVE / REJECT + 사유]
---END_GOAL_CHANGE_REQUEST---
```

### 3.3 BLOCKER_REVIEW_REQUEST

```
---BLOCKER_REVIEW_REQUEST---
발견 사항    : {REVIEW-N 요약}
AI 독립 해결 불가.
인간 결정    : [APPROVE 해결 / REDESIGN / DESCOPE + 사유]
---END_BLOCKER_REVIEW_REQUEST---
```

사용 조건: BLOCKER는 G2 Critical과 같다 — FAIL → REWINDING이 기본이다. 이 요청은 되돌리기 어려운 결함(V 어려움 — 데이터 삭제·push·알림·설치본 덮어쓰기 등. TOOL-6 조작 분류와는 별개 — 이 V는 결함 결과 기준)이거나 `retry_count` 재판정 상한 초과 때만 쓴다(`ROLES/SUB-SSOT/VERIFIER/verification-procedure.md` §G2 판정 기준).

### 3.4 DELETION_APPROVAL_REQUEST

```
---DELETION_APPROVAL_REQUEST---
삭제 항목    : {VAL-ID 목록}
사유         : {각 항목이 더 이상 유효하지 않은 이유}
인간 결정    : [APPROVE / REJECT]
---END_DELETION_APPROVAL_REQUEST---
```

### 3.5 CHANGE_REQUEST

```
---CHANGE_REQUEST---
타임스탬프   : {datetime}
트리거       : {변경 필요 원인}
변경 내용    : {detail-plan.md 수정 내용}
영향 범위    : {파일, 테스트, VAL 항목}
AI 추천      : APPROVE / REJECT
인간 결정    : [APPROVE / REJECT + 사유]
---END_CHANGE_REQUEST---
```

### 3.6 HUMAN_ESCALATION_REQUEST

```
---HUMAN_ESCALATION_REQUEST---
타임스탬프   : {datetime}
트리거       : {초과된 임계값}
실패 요약    : {실패 VAL 항목 + 사유}
반복 횟수    : {N}
현재 목표    : {STEP 01 목표 그대로 복사}
AI 평가      : {기술적 차단 요인}
옵션         :
  A) 계속 — 추가 가이던스: [여기에 입력]
  B) 범위 축소 — 아래 제안 승인 필요
  C) 전면 재설계 — STEP 01로 복귀
인간 결정    : [A / B / C + 상세]
---END_HUMAN_ESCALATION_REQUEST---
```

### 3.7 SCOPE_REDUCTION_PROPOSAL

```
---SCOPE_REDUCTION_PROPOSAL---
원래 목표     : {STEP 01 목표 그대로}
축소 제안     : {제거되는 부분}
손실되는 것   : {사라지는 기능/보장}
유지되는 것   : {여전히 제공되는 것}
영향 VAL 항목 : {제거될 VAL-ID}
인간 결정     : [APPROVE / REJECT]
---END_SCOPE_REDUCTION_PROPOSAL---
```

### 3.8 CONFLICT_APPROVAL_REQUEST

```
---CONFLICT_APPROVAL_REQUEST---
유형          : {A/B/C — 인간 승인 필수}
인간 결정     : [APPROVE 해결 / ALTERNATIVE: {설명}]
---END_CONFLICT_APPROVAL_REQUEST---
```

### 3.9 SCHEMA_CHANGE_APPROVAL

```
---SCHEMA_CHANGE_APPROVAL---
변경 내용     : {요약}
영향 행 수    : {추정값 또는 "확인 필요"}
롤백 방법     : {DOWN 마이그레이션 또는 수동 절차}
인간 결정     : [APPROVE / REJECT]
---END_SCHEMA_CHANGE_APPROVAL---
```

### 3.10 DEPENDENCY_CONFLICT

```
---DEPENDENCY_CONFLICT---
충돌 패키지   : {package A} vs {package B}
요구 버전     : A requires {ver}, B requires {ver}
해결 방법     : 버전 고정 / 대체 라이브러리 / HUMAN 결정 필요
인간 결정     : [APPROVE 해결 방법 / ALTERNATIVE]
---END_DEPENDENCY_CONFLICT---
```

---

## §4 산출물 포맷

### 4.1 DEVIATION 기록

```
DEVIATION-{N}
계획     : {어느 문서의 어느 항목}
실제     : {무엇을 다르게 구현}
이유     : {왜 이탈이 불가피}
영향     : {어느 VAL 항목에 영향}
```

### 4.2 VAL 결과 기록

```
VAL-{N} [{echo: 검증 항목 한 줄 요약}]
명령어   : {실제 실행 명령}
출력     : {실제 stdout — 최소 3줄, 생략 시 자동 FAIL}
결과     : PASS / FAIL
실행시각 : {datetime}
```

**규칙**: Output 필드가 없거나 설명만 있으면(실제 출력 아님) 자동 **FAIL**.

### 4.3 FAIL_COUNTER

```
FAIL_COUNTER
총 VAL 항목  : {N}
현재 실패    : {X}
실패율       : {X/N*100}%
반복 횟수    : {N}회차
```

**임계값**:
- 동일 항목 1회 실패 → 수정 후 재검증 (자율)
- 동일 항목 2회 연속 실패 → 계획 재검토
- 동일 항목 3회 연속 실패 → HUMAN_ESCALATION_REQUEST (§3.6)
- 실패율 30% 초과 → 이전 단계 복귀
- 반복 3회 초과 → HUMAN_ESCALATION_REQUEST

---

## §5 충돌 분류

### 5.1 Type A~E 정의

| 유형 | 충돌 | 대응 |
|------|------|------|
| **Type A** | Signature Conflict — 같은 이름, 다른 인터페이스 | **HALT + HUMAN** |
| **Type B** | Dependency Conflict — 패키지 버전 비호환 | **HALT + HUMAN** |
| **Type C** | Schema Conflict — 마이그레이션이 기존 데이터 영향 | **HALT + HUMAN** |
| **Type D** | Naming Collision — 변수/환경변수 이름 중복 | LOG + AUTO-RESOLVE |
| **Type E** | Convention Mismatch — 스타일/폴더 구조 차이 | LOG + FOLLOW-EXISTING |

### 5.2 충돌 파일 포맷

```markdown
# Conflict Report

## Metadata
- Detected_at : {datetime}
- Detected_by : CODER / automated check
- Type        : A / B / C / D / E
- Location    : {file:line or package name}

## Description
- Existing    : {현재 코드베이스 상태}
- Incoming    : {새 구현이 요구하는 것}
- Difference  : {구체적 비호환 내용}

## Resolution
- Method      : {wrapper / version pin / migration / prefix / follow-existing}
- Status      : PENDING_HUMAN / AUTO_RESOLVED
- AI_recommend: {추천 행동}

## Approval (Type A/B/C만)
---CONFLICT_APPROVAL_REQUEST---
Type          : {A/B/C}
Human_decision: [APPROVE resolution / ALTERNATIVE: {설명}]
---END_CONFLICT_APPROVAL_REQUEST---
```

---

## §6 VUL 체크리스트

### 6.1 VUL1 — 샘플 코드 경계 검증

| ID | 검사 항목 | 방법 | 기대 결과 |
|----|-----------|------|-----------|
| VUL1-01 | Import 검사 | `python -c "from prototype.{module} import {func}"` | ImportError 없음 |
| VUL1-02 | 범위 상한 검사 | `grep -c "logger\.\|console\.log\|print(" prototype/{file}` | 0 matches |
| VUL1-03 | 핵심 로직 커버리지 | TODO 항목 vs prototype 함수 수 (수동) | ≥60% 대응 |
| VUL1-04 | 격리 검사 | `git branch --show-current` 또는 `ls prototype/` | prototype/ 또는 feat/prototype-* |
| VUL1-05 | 헤더 검사 | `head -8 prototype/{file}` | "[PROTOTYPE ONLY" 존재 |
| VUL1-06 | 인증 적용 검사 | 보호 대상 라우트 · 핸들러 목록(`grep -n` 라우트 선언)과 인증 데코레이터 · 미들웨어 적용 목록 대조 | 미적용 0 |

### 6.2 VUL2 — 호환성 충돌 감사

| ID | 검사 항목 | 방법 | 기대 결과 |
|----|-----------|------|-----------|
| VUL2-01 | 충돌 로그 존재 | `ls docs/plans/{feature}/conflict-*.md` | 충돌 감지 시 파일 존재 |
| VUL2-02 | Type A 해결 | 기존 vs 신규 함수명 grep 비교 | wrapper 패턴 존재 |
| VUL2-03 | Type B 해결 | `pip check` 또는 `npm ls` | 0 conflict warnings |
| VUL2-04 | Type C 해결 | 마이그레이션 파일 ALTER/DROP 검토 | HUMAN 승인 기록 존재 |
| VUL2-05 | Type D/E 감사 | conflict-*.md 내 resolution 필드 확인 | 모든 항목에 resolution 존재 |

### 6.3 VUL3 — 범위 무결성 감사

| ID | 검사 항목 | 방법 | 기대 결과 |
|----|-----------|------|-----------|
| VUL3-01 | 산출물 파일 수 | STEP 01 vs STEP 07 파일 수 비교 | STEP 07 ≥ STEP 01 |
| VUL3-02 | VAL 항목 수 추이 | STEP 02 → STEP 05 → STEP 07 count 비교 | 미승인 감소 없음 |
| VUL3-03 | TODO 완료 감사 | plan.md [x] vs result.md completed 대조 | 모든 TODO 추적됨 |
| VUL3-04 | DEVIATION 영향 | DEVIATION-N 중 범위 축소 여부 검토 | 범위 축소 없음 (없으면 SCOPE_REDUCTION_PROPOSAL) |
| VUL3-05 | 목표 일치 비교 | Definition of Done vs result.md 대조 | 모든 DoD 항목 충족 |

---

## §7 예외 처리 조항

### 7.1 Exception 1 — Hotfix

조건 (전부 충족 필수):
- 프로덕션 버그, 활성 사용자 영향
- 수정 범위 1파일 이하
- 신규 함수/클래스 생성 없음
- 기존 테스트 통과

→ PHASE 0 → PHASE 7 직행 (1~6 스킵). 24시간 내 사후 문서화 필수.

### 7.2 Exception 2 — Minor Change

조건 (전부 충족 필수):
- 변경 행 ≤5줄
- 신규 함수/클래스/API 없음
- 기존 테스트 통과
- 외부 의존성 변경 없음

→ PHASE 1~5 단일 문서 통합. VAL 체크리스트는 생략 불가.

### 7.3 Exception 3 — Pattern Reuse

조건 (전부 충족 필수):
- 기존에 3회 이상 동일 패턴 적용 이력
- 패턴 문서(patterns/*.md) 등록 완료
- 인간이 해당 패턴 적용을 승인

→ PHASE 1~3 축약 (패턴 문서 참조로 대체). PHASE 4~7 정상 수행.

### 7.4 Exception 4 — POC/Spike-only

조건 (전부 충족 필수):
- POC 목적으로 폐기 전제
- 프로덕션 배포 불가 선언
- spike/·poc/ 디렉토리 또는 worktree(WT-8) 격리

→ PHASE 0~3만 수행. PHASE 4~7 불필요 (폐기 전제).

---

## §8 토큰 예산 · 계측

`WORKFLOW/workflow.md` §6 OPS-3 · OPS-4가 판정할 잣대다.

### 8.1 단위

- **비캐시** = `input_tokens` + `cache_creation_input_tokens` + `output_tokens`.
- **cache_read**(`cache_read_input_tokens`)는 비캐시와 따로 적는다.

### 8.2 합산 범위 · 중복 제거 · 기준 시각

- 합산 범위는 리더 + 팀원 + 서브에이전트 전체다.
- 메시지 `id`가 같으면 첫 출현만 센다(중복 제거).
- 기준 시각은 status `token_budget.measure_from` 이후다.
- 출처는 세션 transcript다.

### 8.3 수단

`scripts/tokenusage/token_usage.py`로 집계한다. 스크립트가 없거나 실패하면 위 8.1 · 8.2와 같은 규칙으로 수동 집계한다.

호출 예: `python3 scripts/tokenusage/token_usage.py --since 2026-02-28T00:00:00Z`

- **기본 범위**는 현재 CWD의 transcript 디렉터리 하나(`~/.claude/projects/<CWD 경로를 바꾼 이름>`)에서 구간 안에 있는 모든 세션이다. 그 Phase의 범위(8.2)와 다를 수 있다.
- `--session <세션 id 앞부분>`(여러 번)을 주면 그 세션과 그 서브에이전트만 센다. 같은 디렉터리의 관계없는 세션을 빼려면 리더 · 팀원 세션 id를 모두 준다.
- `--project-dir <디렉터리>`(여러 번)를 주면 기본 디렉터리를 **대신한다**. worktree · 하위 폴더처럼 다른 CWD에서 돈 세션을 더하려면 기본 디렉터리도 함께 `--project-dir`로 준다.
- 시각(`--since` · `--until` · `measure_from`)에는 오프셋을 반드시 붙인다(`Z` 권장). 오프셋이 없으면 UTC로 읽는다.
- 출력의 「읽지 못한 줄」 · 「열지 못한 파일」이 0이 아니면 그 수만큼 집계에서 빠진 것이다.

### 8.4 산정 항목

Step 0 · 초기화 · 새 스폰 · 편집 · 판정 · 리더 소비를 합산한다. 리더 재캐시는 결정 지점 수 × 리더 컨텍스트 일부로 어림하고, 상주 팀원의 재캐시도 포함한다.

### 8.5 status `token_budget` 7키

| 키 | 뜻 |
|---|---|
| `policy` | 예산 초과 처리 방식(예: `soft_cap` — 상한을 넘을 전망이면 멈추고 분석 설계 리포트를 쓰고, 사용자 승인 뒤 계속한다. OPS-3) |
| `limit` | 상한(비캐시 토큰) |
| `estimate` | 착수 때 예상(비캐시 토큰) |
| `declared` | 승인 기록(누가 · 언제 · 무엇을 승인했는지 — 예상 · 상한 · 중간 보고 지점) |
| `unit` | 계측 단위(§8.1 — 비캐시) |
| `consumed` | 계측된 소비량(비캐시 토큰) |
| `measure_from` | 계측 시작 시각(ISO8601 · 오프셋 필수 — `Z` 권장) |

