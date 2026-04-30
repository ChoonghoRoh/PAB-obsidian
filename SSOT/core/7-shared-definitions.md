# 7-shared-definitions.md — SUB-SSOT 공통 포맷 정의 레이어

> **버전**: 1.0 | **생성일**: 2026-04-13
> **SSOT**: v8.0-renewal-6th | **용도**: 모든 SUB-SSOT에서 공통으로 참조하는 포맷·규칙 정의

## 개요

SUB-SSOT 간 중복을 제거하고 일관성을 보장하기 위해, 여러 역할에서 공통으로 사용하는 포맷·규칙을 이 파일에 집중 정의한다. 각 SUB-SSOT에서는 `참조: core/7-shared-definitions.md §N`으로 이 파일을 참조한다.

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

> **원본**: DEV-work-guide 파일2 PROBLEM-CTX-04, 파일4 §0

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
| PLANNER | planner | 문서만 생성, 코드 금지 |
| CODER | backend-dev, frontend-dev | 도메인별 코드 수정 |
| REVIEWER | verifier | 별도 컨텍스트 필수 |
| VALIDATOR | tester | 명령어 실행 증거 필수 |
| HUMAN | 인간 승인자 | 8개 트리거 시 대기 |

### 2.3 역할 전환 금지

- CODER와 REVIEWER는 **동일 컨텍스트에서 전환 금지**.
- 옵션: A) 별도 세션 (권장), C) 인간 리뷰.

> **원본**: DEV-work-guide 파일2 §1, PROBLEM-CTX-06

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

> **원본**: DEV-work-guide 파일2 §6 (Section 6), 파일4 §0.2, §2.2, §9

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

> **원본**: DEV-work-guide 파일2 §2.7, 파일4 §7.4

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

> **원본**: DEV-work-guide 파일2 VUL2 (§VULNERABILITY 2)

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

> **원본**: DEV-work-guide 파일2 §3 (Section 3: Three Critical Vulnerability Mitigations)

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
- spike/ 또는 poc/ 디렉토리 격리

→ PHASE 0~3만 수행. PHASE 4~7 불필요 (폐기 전제).

> **원본**: DEV-work-guide 파일2 §4, 파일4 §8

---

---

## §8 ITERATION-BUDGET — 사이클 자원 상한 (Phase-H H-2)

**규칙 ID**: ITERATION-BUDGET
**적용 시점**: AutoCycle 14단계 전체 (1 사이클 = Step 1~14)
**목적**: 단일 개발 사이클의 토큰·시간 폭증을 방지하여 비용 예측 가능성 확보.

### 8.1 토큰 상한

| 항목 | 기본값 | 비고 |
|------|--------|------|
| **사이클 총 토큰** | **500,000 tokens** | Step 1~14 합산 (입력+출력) |
| **단일 Phase 토큰** | 200,000 tokens | Phase X-Y 1회 실행 상한 |
| **사전 반복 (Step 1~5)** | 150,000 tokens | 3회 반복 합산 |
| **재계획 (Step 8~9)** | 100,000 tokens | 2회 재계획 합산 |

### 8.2 초과 에스컬레이션 절차

```
사이클 진행 중 토큰 소비량 추적 (Team Lead)

if 현재 소비량 ≥ 80% of 상한:
    → WARNING: Team Lead 토큰 절약 모드 진입
    → 불필요한 Research/Spike 스킵 가능

if 현재 소비량 ≥ 100% of 상한:
    → HALT: 자동 진행 중단
    → HUMAN_ESCALATION_REQUEST 발동 (§3.6)
    → 옵션:
      A) 상한 확장 승인 (최대 2배, 1,000K)
      B) 범위 축소 후 현재 예산 내 완료
      C) 사이클 종료 → 미완 항목 Tech Debt 전이
```

### 8.3 측정 책임

- **Team Lead**: 각 Phase/Step 전환 시 토큰 소비량 기록 (phase-achievement-report.md §3)
- **verifier**: G2 검증 시 토큰 예산 초과 여부 확인
- **예외**: 사용자가 사전에 "예산 무제한"을 선언한 경우 본 규칙 적용 제외 (선언 기록 필수)

---

**문서 관리**: v1.1, 2026-04-16, SUB-SSOT 공통 레이어 (Phase-H §ITERATION-BUDGET 추가)
