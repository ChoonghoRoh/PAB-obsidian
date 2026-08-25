# Verification Procedure — SUB-SSOT

> **버전**: 1.2 | **갱신**: 2026-04-15 (Phase-F — verifier-work-guide.md 고유 검증 시나리오·PARTIAL·Council 상세 통합)
> **소스**: `_backup/GUIDES/verifier-work-guide.md` + DEV-work-guide 파일2 §1.3/§2.3 + 파일4 §7.3 (Phase-E·F 완전 이관)

## 검증 프로세스

```
[1] Team Lead: SendMessage → verifier에게 검증 요청 (변경 파일·완료 기준)
[2] verifier: 변경 파일 읽기 (Read, Grep)
[3] verifier: 검증 기준 적용 (Critical/High)
[4] verifier: 이슈 목록 작성
[5] verifier: 판정 (PASS / FAIL / PARTIAL)
[6] verifier: 보고서 → docs/phases/phase-X-Y/reports/report-verifier.md
[7] verifier: SendMessage → Team Lead에게 보고서 파일 경로만 전달
```

---

## REVIEWER 실행 원칙

### plan-first review

- REVIEWER는 **코드 리뷰 전 계획 문서(requirements.md, api-contract.md, schema-analysis.md) 먼저 검토**한다.
- 계획과 코드가 어긋날 때 BLOCKER 판정. CODER 해명만으로 승인 금지.
- PHASE 3 (Spike): Spike 결과가 불확실성을 실제로 해소했는지 판정.
- PHASE 4 (호환 분석): upstream/downstream 영향이 계획 범위 내인지 검증.
- PHASE 7 (본 구현): 아래 8항목 체크리스트 적용.

### 컨텍스트 분리

- CODER와 REVIEWER는 **동일 세션 금지** (→ `core/7-shared-definitions.md §2.3`).
- verifier 스폰 시 CODER 컨텍스트 미공유가 기본.
- 위반 시 PROBLEM-PROC-06 (동일 컨텍스트 리뷰 bias) 발동.

---

## REVIEWER 체크리스트 (8항목)

**Scope**: PHASE 7 본 구현 검증 (PHASE 3 Spike 리뷰는 §plan-first review 참조).
**전제**: CODER와 **별도 컨텍스트 필수**. 읽는 순서: requirements.md → api-contract.md → 코드.

```
[ ] AUTH   : 데이터 변경/조회에 인증·권한 체크?
             grep: "permission|require_auth|@login" {file}
[ ] SCHEMA : 쿼리가 schema-analysis.md 전략 준수?
[ ] N+1    : 루프 안 DB 쿼리?
             grep: "for .* in|\.all()|\.filter(" {file}
[ ] CONTRACT: API 응답이 api-contract.md 스키마 일치?
[ ] COMMON : 공통 모듈 미사용 직접 구현?
[ ] PROTOTYPE: Spike 코드 직접 복사?
[ ] DEVIATION: CODER DEVIATION 기록 전부 근거?
[ ] INFRA  : 하드코딩 설정값/비밀키/IP?
             grep: "password|secret|127.0.0.1|hardcode" {files}

각 항목: [PASS/FAIL/N/A] + 근거 한 줄
BLOCKER → BLOCKER_REVIEW_REQUEST (참조: core/7-shared-definitions.md §3.3)
```

---

## PARTIAL 행동 플로우

### AUTO_FIX 진입 조건 (6개 AND)

```
[1] Critical 0건
[2] High 1~2건
[3] 아키텍처 변경 없음
[4] 새 의존성 없음
[5] Security Expert 비토 없음
[6] Performance Expert 비토 없음
→ 전부 충족: AUTO_FIX 루프 (최대 3회)
→ 미충족: 수동 에스컬레이션
```

### AUTO_FIX 루프

```
[1] 이슈 목록 + 구체적 수정 지시 작성 (파일, 라인, 위반, 기대 방향)
[2] 담당 dev에게 수정 지시 전달
[3] dev: 지시 범위 내 수정
[4] verifier: 재검증
    - PASS → 루프 종료
    - PARTIAL → 잔여 갱신, [1]로 (최대 3회)
    - FAIL → 즉시 종료, Team Lead에게 FAIL
```

---

## Council 코디네이션 (5th 확장, Phase-F 상세화)

### 호출 조건

11명 Verification Council은 `5th_mode.multi_perspective: true` 설정일 때 활성화:

- **활성화 시**: 모든 G2 검증에서 Council 기반 다관점 검증 수행
- **비활성화 시** (`5th_mode.multi_perspective: false` 또는 미설정, 4th 호환): 기존 단일 verifier 체크리스트 방식
- **전환 불가**: Phase 도중 `multi_perspective` 설정 변경 금지. **Phase 시작 전에 확정**

### 동적 멤버 선택

도메인 태그에 따라 Council 멤버 5~6명 동적 선택:

| 도메인 태그 | 필수 참여 (비토권) | 추가 참여 |
|-------------|---------------------|-----------|
| [BE] | Security Expert, Performance Expert | Architecture Expert, Data Expert, Test Engineer |
| [FE] | Security Expert, Performance Expert | UX Expert, Accessibility Expert, Code Style Expert |
| [FS] | **전원 참여 (11명)** | — |

- Security Expert·Performance Expert는 도메인 무관 **항상 참여** + **비토 권한**
- verifier(코디네이터)는 변경 파일 경로 기준 도메인 판별:
  - `backend/` → [BE]
  - `web/` → [FE]
  - 양쪽 포함 → [FS]

### 투표 집계 방법

```
[1] 각 Council 멤버 독립 검증 (Read-only)
[2] 개별 판정 수집: PASS / PARTIAL / FAIL + 점수(0~100) + 이슈 목록
[3] 비토 우선 처리:
    - Security Expert FAIL → 즉시 종합 FAIL
    - Performance Expert FAIL → 즉시 종합 FAIL
[4] 다수결 판정:
    - 3인 이상 FAIL → 종합 FAIL
[5] 점수 합산 (비토·다수결 미해당 시):
    - 각 멤버 점수 가중 평균
    - ≥85 PASS / 70~84 PARTIAL / <70 FAIL
[6] 이슈 목록 병합:
    - 중복 제거 (동일 파일+동일 라인+동일 카테고리)
    - Critical/High/Medium 우선순위 정렬
[7] 종합 판정 + 병합 이슈 목록을 Team Lead에 보고
```

- **점수 가중치**: Security·Performance 1.5배, 나머지 1.0배
- **동점 시**: 낮은 판정(FAIL > PARTIAL > PASS) 우선 채택

---

## REVIEWER 실패 모드 대응

DEV/3-failure-modes.md의 REVIEWER 완화 소관 항목. CODER 인식은 DEV 원본 유지, 본 섹션은 REVIEWER 실행 관점.

| ID | 완화 절차 (REVIEWER가 수행) |
|----|-----------------------------|
| PROBLEM-BE-04 | PHASE 7 재작성 시 Spike ↔ 본구현 **구조 비교 의무** — 함수 시그니처·에러 경로·반환 타입 일치 검증 |
| PROBLEM-DB-03 | PHASE 7에서 `schema-analysis.md` 쿼리 전략 선언 ↔ 실구현 쿼리 스타일(ORM/Raw) **대조** 검사 |
| PROBLEM-PROC-06 | 동일 컨텍스트 리뷰 bias 차단 — verifier 스폰은 **반드시 별도 세션**, CODER 컨텍스트 미공유 확인 |

→ 원본 목록: `SUB-SSOT/DEV/3-failure-modes.md`

---

## 검증 시나리오 예시

### ORM 규칙 위반 검출

```
위반: session.execute(text("SELECT * FROM users ..."))
정상: session.query(User).filter(User.id == user_id).first()
판정: 비즈니스 로직(backend/app/) → Critical, 테스트(tests/) → High
```

### ESM import 검출

```
위반: type="module" 누락, require(), CDN URL
판정: type="module" 누락/CommonJS/CDN → Critical, .js 확장자 누락 → High
```

### 타입 힌트 누락 검출 (Phase-F 이관)

모든 함수의 파라미터와 반환 타입에 타입 힌트가 있는지 검증.

**검출 방법**:
- 함수 정의(`def`, `async def`)에서 파라미터 타입 어노테이션 누락 확인
- 반환 타입(`-> Type`) 누락 확인
- `self`, `cls` 파라미터는 타입 힌트 검사 제외

**판정 기준**:
- API 엔드포인트 함수 타입 힌트 누락 → **High**
- 내부 유틸리티 함수 타입 힌트 누락 → **High**
- `__init__` 반환 타입(`-> None`) 누락 → 권고 사항 (이슈 미계상)

---

## PARTIAL 행동 플로우 (Phase-F 상세화)

G2 검증 결과가 PARTIAL(Critical 0건, High 1~2건)로 판정된 경우의 행동 절차.

### AUTO_FIX 진입 판단 — 6가지 AND

| # | 조건 |
|---|------|
| 1 | Critical 0건 |
| 2 | High 1~2건 |
| 3 | 아키텍처 변경 없음 |
| 4 | 새 의존성 없음 |
| 5 | Security Expert 비토 없음 |
| 6 | Performance Expert 비토 없음 |

전부 충족 → AUTO_FIX 루프 / 하나라도 미충족 → 수동 에스컬레이션

### AUTO_FIX 루프 실행

```
[1] verifier: 이슈 목록 + 수정 지시 작성 (파일 경로·라인 범위·위반 내용·기대 방향)
[2] Team Lead 경유 또는 직접: 담당 dev에게 수정 지시 전달
[3] dev: 지시 범위 내 수정
[4] dev: 수정 완료 보고
[5] verifier: 재검증 실행
    - PASS → 루프 종료, Team Lead에 PASS 보고
    - PARTIAL → 잔여 이슈 목록 갱신, [1]로 복귀 (최대 3회)
    - FAIL → 즉시 종료, Team Lead에 FAIL 보고
```

### 수동 에스컬레이션

AUTO_FIX 조건 미충족 또는 3회 반복 초과 시:
- verifier는 **전체 이슈 목록 + 실패 사유 + 권고 사항**을 Team Lead에 보고
- Team Lead가 방향 전환·아키텍처 검토·BLOCKED 전이 판단
- verifier는 Team Lead 지시까지 추가 검증 수행 없음

---

**문서 관리**: v1.0, VERIFIER 검증 절차
