# FN-Level Feature Development — SUB-SSOT Procedure

> **버전**: 1.1 | **갱신**: 2026-04-15 (Phase-E task-E-2-1 — REVIEWER/VALIDATOR 절차 이관)
> **원본**: `_backup/GUIDES/DEV-work-guide/4-fn-dev-field-procedure-v1.md`
> **변경**: GATE/포맷→공통 참조, 예외 4조항 포함, 파일명 정규화. v1.1에서 PHASE 7 §7.3 REVIEWER 본문은 `SUB-SSOT/VERIFIER/`, §7.4 VALIDATOR 본문은 `SUB-SSOT/TESTER/` 참조로 축소.

## 이 문서의 사용법

```
적용 대상: IMPL_GRANULARITY = FN 요청 (단일 함수/메서드/소규모 모듈)
실행 주체: AI 에이전트 (Claude Code) + 인간 승인자
역할 선언: 각 PHASE 시작 시 ROLE_CHECK 필수 (참조: core/7-shared-definitions.md §2.1)
GATE 규칙: 참조: core/7-shared-definitions.md §1 (GATE_FORMAT, ANTI-COMPRESSION)
```

---

## PHASE 0 — 요청 수신 및 분류
```
ROLE   : PLANNER
INPUT  : 개발자의 fn 요청
OUTPUT : request-brief.md
```

### 0.1 요청 구조 분해

```markdown
# Request Brief
## 구조 분해
| 항목            | 내용                          | 명확도        |
|-----------------|-------------------------------|---------------|
| 함수명 (예상)   |                               | CLEAR/AMBIGUOUS |
| 입력값 타입     |                               | CLEAR/AMBIGUOUS |
| 출력값 타입     |                               | CLEAR/AMBIGUOUS |
| 실패 시 동작    |                               | CLEAR/AMBIGUOUS |
| 호출 위치       | BE API / FE component / both  | CLEAR/AMBIGUOUS |
| 기존 유사 함수  | 있음({이름}) / 없음            | CLEAR/AMBIGUOUS |
| 성능 요구사항   | 있음({기준}) / 명시 없음       | CLEAR/AMBIGUOUS |
| 트랜잭션 필요   | YES / NO / AMBIGUOUS          | CLEAR/AMBIGUOUS |

## IMPL_GRANULARITY
선언: FN
근거: {함수 수, 파일 수, 범위}
```

### 0.2 AMBIGUITY 처리

AMBIGUITY 블록 형식 → `참조: core/7-shared-definitions.md §3.1`

### 0.3 GATE 0

```
[PASS/FAIL] 구조 분해 표 모든 항목 충족?
[PASS/FAIL] 미결 AMBIGUITY 블록 0개?
[PASS/FAIL] IMPL_GRANULARITY = FN 선언 존재?
```

---

## PHASE 1 — 요구사항 분석 및 전체 프로세스 점검
```
ROLE   : PLANNER
INPUT  : request-brief.md
OUTPUT : requirements.md
```

### 1.1 요구사항 계층 분석

```markdown
## 기능 요구사항 (FR)
| ID    | 요구사항 | 우선순위      | 검증 가능 기준 |
|-------|----------|---------------|----------------|
| FR-01 |          | MUST/SHOULD   | {측정 가능}    |

## 비기능 요구사항 (NF)
| ID    | 항목     | 목표값        | 측정 방법      |
|-------|----------|---------------|----------------|
| NF-01 | 응답시간 | p99 < {N}ms   | {명령}         |

## 제약 조건
- 기존 API 계약 변경: YES / NO
- 기존 DB 스키마 변경: YES / NO (변경 시 HUMAN 승인 필수)
```

### 1.2 프로세스 점검

호출 체인(upstream) 최상위까지 역추적. 영향 범위(downstream) 목록화.

### 1.3 GATE 1

```
[PASS/FAIL] FR 측정 가능 완료 조건?
[PASS/FAIL] NF 목표값+측정 방법?
[PASS/FAIL] 호출 체인 역추적 완료?
[PASS/FAIL] downstream 모듈 목록화?
[PASS/FAIL] 트랜잭션 필요 여부 결정?
```

---

## PHASE 2 — DB 스키마 분석 및 API 설계
```
ROLE   : PLANNER
INPUT  : requirements.md
OUTPUT : schema-analysis.md, api-contract.md
```

관련 테이블 전수 조사. 쿼리 전략(ORM/Raw SQL) 선언. N+1 위험 검토.
API 포함 시 API_CONTRACT_LOCK 완료. Breaking Change 명시.

스키마 변경 승인 → `참조: core/7-shared-definitions.md §3.9`

### GATE 2
```
[PASS/FAIL] 관련 테이블 전체 목록화?
[PASS/FAIL] 스키마 변경 시 승인 완료?
[PASS/FAIL] 쿼리 전략 선언?
[PASS/FAIL] N+1 위험 검토?
[PASS/FAIL] API 계약 잠금? (내부 fn은 N/A)
[PASS/FAIL] Breaking Change 명시?
```

---

## PHASE 3 — 핵심 기능 선행 테스트 (Spike)
```
ROLE   : CODER → REVIEWER (별도 컨텍스트 — 절차: SUB-SSOT/VERIFIER/)
INPUT  : requirements.md, schema-analysis.md, api-contract.md
OUTPUT : spike/{feature}/spike.{ext}, spike-result.md
```

가장 불확실한 핵심 로직 1~2개만 실제 실행. NF 예비 측정. GO/NO-GO 판정.
Spike 불필요 시 → "Spike 불필요 — 이유: {근거}" 기재.

### GATE 3
```
[PASS/FAIL] Spike 대상 또는 불필요 근거?
[PASS/FAIL] 검증 질문별 실행 출력?
[PASS/FAIL] 성능 예비 측정?
[PASS/FAIL] GO/NO-GO 판정?
```

---

## PHASE 4 — 기존 기능 연결 및 호환 분석
```
ROLE   : PLANNER + REVIEWER (REVIEWER 절차: SUB-SSOT/VERIFIER/)
INPUT  : requirements.md, spike-result.md, 기존 코드베이스
OUTPUT : compatibility-report.md
```

연결 지점(upstream/downstream) 전수 목록. 시그니처 충돌 유형 분류.
충돌 유형 → `참조: core/7-shared-definitions.md §5`

기존 테스트 기준선 실행·기록 (회귀 비교 기준).

### GATE 4
```
[PASS/FAIL] 연결 지점 upstream/downstream 포함?
[PASS/FAIL] 시그니처 충돌 분류?
[PASS/FAIL] Type A+ 충돌 HUMAN 승인? (없으면 N/A)
[PASS/FAIL] 회귀 위험 목록?
[PASS/FAIL] 기존 테스트 기준선?
```

---

## PHASE 5 — 라이브러리 및 공통 모듈 검토
```
ROLE   : PLANNER
INPUT  : requirements.md, compatibility-report.md
OUTPUT : library-review.md
```

기존 공통 모듈 재사용 우선. 라이브러리 선택 매트릭스.
의존성 충돌 → `참조: core/7-shared-definitions.md §3.10`

### GATE 5
```
[PASS/FAIL] 공통 모듈 재사용 검토?
[PASS/FAIL] 재사용 불가 항목 사유?
[PASS/FAIL] Authorization(EXISTING/HUMAN_APPROVED)?
[PASS/FAIL] 의존성 충돌 사전 검사?
```

---

## PHASE 6 — 인프라 성능 점검 및 해결 방안
```
ROLE   : PLANNER + VALIDATOR (VALIDATOR 절차: SUB-SSOT/TESTER/)
INPUT  : requirements.md(NF), spike-result.md, compatibility-report.md
OUTPUT : infra-review.md
```

NF 목표 vs 현재 인프라 갭 분석. 해결 방안 선택. 인프라 설정 변경 목록.

### GATE 6
```
[PASS/FAIL] NF vs 인프라 대조?
[PASS/FAIL] 갭 항목 해결 방안?
[PASS/FAIL] 인프라 설정 변경 목록? (없으면 N/A)
[PASS/FAIL] .env.example 갱신? (없으면 N/A)
```

---

## PHASE 7 — 구현 및 검증
```
ROLE   : CODER → REVIEWER (별도 컨텍스트 — SUB-SSOT/VERIFIER/) → VALIDATOR (SUB-SSOT/TESTER/)
INPUT  : 모든 이전 PHASE 산출물
OUTPUT : 프로덕션 코드, result.md
```

### 7.1 CODER 시작

ROLE_CHECK + CHECKPOINT_READ (→ `참조: core/7-shared-definitions.md §2.1`)

### 7.2 구현 규칙

1. 쿼리 전략 = schema-analysis.md 선언 따름
2. 공통 모듈 = library-review.md 방법대로
3. 에러 = common/exceptions.py 계층
4. API 응답 = api-contract.md 스키마 일치
5. 이탈 시 DEVIATION 기록 (→ `참조: core/7-shared-definitions.md §4.1`)

### 7.3 REVIEWER 체크리스트

**→ 절차 본문 이관: `SUB-SSOT/VERIFIER/` 참조** (AUTH, SCHEMA, N+1, CONTRACT, COMMON, PROTOTYPE, DEVIATION, INFRA 8항목 체크리스트). CODER는 REVIEWER 결과만 §7.5 GATE 7에서 확인.

### 7.4 VALIDATOR 검증

**→ 절차 본문 이관: `SUB-SSOT/TESTER/` 참조** (VAL 결과 포맷, FAIL_COUNTER 관리). CODER는 VALIDATOR 결과만 §7.5 GATE 7에서 확인.

### 7.5 GATE 7

```
─── 기능 ───
[PASS/FAIL] FR 전체 구현?
[PASS/FAIL] VAL 전체 PASS + 출력 기록?
[PASS/FAIL] Fail 카운터 0?

─── 품질 ───
[PASS/FAIL] REVIEWER 리뷰 완료, BLOCKER 0?
[PASS/FAIL] DEVIATION 전부 근거 + 수락?
[PASS/FAIL] 회귀 신규 실패 0?

─── 성능 ───
[PASS/FAIL] NF 목표 전체 달성?

─── 호환성 ───
[PASS/FAIL] 모든 위험 지점 처리?
[PASS/FAIL] API Contract 유지? (변경 시 승인 확인)

─── 인프라 ───
[PASS/FAIL] 인프라 설정 변경 완료? (N/A)
[PASS/FAIL] .env.example 갱신? (N/A)
[PASS/FAIL] 하드코딩 값 없음?

─── 문서 ───
[PASS/FAIL] result.md 작성 + Git 커밋?
[PASS/FAIL] spike 파일 아카이브/삭제?
[PASS/FAIL] PR 생성?
```

---

## 예외 처리

Hotfix, Minor Change, Pattern Reuse, POC/Spike-only 예외 조건 → `참조: core/7-shared-definitions.md §7`

---

## §8 에러 처리 패턴 (BE, Phase-F 이관)

### 8.1 DB 연결 실패 — Retry 패턴

일시적 DB 오류는 **지수 백오프 재시도**:

- **최대 재시도**: 3회
- **대기 간격**: 1초 / 2초 / 4초 (지수 증가)
- **재시도 대상**: `OperationalError`, `ConnectionRefusedError` 등 일시 오류
- **비재시도**: `ProgrammingError`, `IntegrityError` 등 논리 오류는 즉시 실패
- **커넥션 풀**: `pool_pre_ping=True`로 stale connection 자동 검출

### 8.2 외부 API 타임아웃 — 서킷 브레이커

- **연결 타임아웃**: 5초 / **읽기 타임아웃**: 10초
- **재시도**: 최대 2회, **멱등 요청**에 한정
- **서킷 브레이커**: 연속 5회 실패 → 30초 Open → Half-Open 1건 시험
- **Fallback**: 캐시된 응답 또는 기본값, 불가 시 503 응답

### 8.3 동시 수정 충돌 — Optimistic Lock

- **구현**: `version` 컬럼(Integer), `UPDATE WHERE version = :current_version`
- **충돌 검출**: UPDATE rowcount = 0
- **응답**: HTTP 409 Conflict + 최신 데이터 반환
- **재시도 정책**: 서버 자동 재시도 없음 — 클라이언트가 확인 후 명시적 재요청

---

## §9 FE 전용 패턴 (Phase-F 이관)

### 9.1 접근성 체크리스트 (WCAG 2.1 AA 기준)

| # | 항목 | 규칙 |
|---|------|------|
| 1 | **aria-label** | 모든 비텍스트 인터랙티브 요소에 `aria-label` 또는 `aria-labelledby` 부여. 장식용 이미지 `alt=""`, 정보 전달 이미지 `alt="설명"` 구분. 폼 입력 `<label for="...">` 또는 `aria-label` 필수 |
| 2 | **tabindex** | 기본 포커스 순서 존중. `tabindex="0"`=포커스 가능, `tabindex="-1"`=프로그래밍 전용. **양수 값 금지** (DOM 순서 변경 → 예측 불가 탐색). 커스텀 위젯(모달·드롭다운) 포커스 트랩 구현 |
| 3 | **색상 대비** | 텍스트 4.5:1 (큰 텍스트 18px+ 는 3:1). UI 컴포넌트 3:1. 색상만으로 정보 전달 금지 — 아이콘·레이블·패턴 병행 |
| 4 | **키보드 네비** | 모든 인터랙티브 요소 키보드 접근 가능. Enter/Space=버튼 활성화, Escape=모달/드롭다운 닫기. 포커스 표시(outline) 제거 금지 |
| 5 | **스크린리더** | 시맨틱 HTML(`<nav>`, `<main>`, `<section>`, `<article>`) 사용. 동적 콘텐츠에 `aria-live="polite"` 또는 `"assertive"`. `<title>` + `<h1>~<h6>` 논리 계층 |

### 9.2 반응형 브레이크포인트 3단계

| 단계 | 범위 | 레이아웃 |
|------|------|----------|
| 모바일 | 0 ~ 767px | 단일 컬럼, 햄버거 메뉴, 터치 최적화 |
| 태블릿 | 768px ~ 1023px | 2컬럼, 사이드바 접기 가능 |
| 데스크톱 | 1024px+ | 다중 컬럼, 전체 네비 표시 |

```css
/* 모바일 퍼스트 */
.container { padding: 1rem; }
@media (min-width: 768px)  { .container { padding: 1.5rem; max-width: 720px; } }
@media (min-width: 1024px) { .container { padding: 2rem;   max-width: 960px; } }
```

**테스트 대상**: 360px / 768px / 1024px / 1440px. 확인 항목 — 텍스트 잘림 없음·가로 스크롤 없음·터치 타겟 ≥44px·이미지 비율.

### 9.3 재사용 패턴

**컴포넌트 추출 기준** (2회 이상 반복 시):
- 동일 HTML 구조 + 동일 스타일 2곳 이상
- 데이터만 다르고 렌더링 로직 동일
- 독립 테스트 가능 단위

**추출 절차**:
1. 반복 HTML 블록을 `web/public/js/components/` 하위 모듈로 분리
2. 데이터 파라미터 받는 렌더 함수/클래스
3. 기존 사용처를 import+호출로 교체
4. 컴포넌트 CSS를 별도 파일 분리

```javascript
// web/public/js/components/status-badge.js
export function createStatusBadge(status, label) {
  const el = document.createElement("span");
  el.className = `badge badge--${status}`;
  el.textContent = label;
  return el;
}
```

**CSS 변수 활용** (디자인 토큰):
```css
/* web/public/css/variables.css */
:root {
  --color-primary: #2563eb; --color-error: #dc2626;
  --color-text: #1f2937;    --color-bg: #ffffff;
  --spacing-sm: 0.5rem;     --spacing-md: 1rem;      --spacing-lg: 2rem;
  --font-size-sm: 0.875rem; --font-size-base: 1rem;  --font-size-lg: 1.25rem;
  --radius-sm: 4px;         --radius-md: 8px;
}
```

컴포넌트 CSS는 하드코딩 대신 `var(--color-primary)` 참조. 다크 모드 대응 — `@media (prefers-color-scheme: dark)` 내에서 변수 재정의.

---

## §10 AUTO_FIX 대응 (CODER 관점, Phase-F 이관)

G2 검증에서 **PARTIAL 판정**(Critical 0, High 1~2) 시 DecisionEngine(→ `5-automation.md §3.2`)에 의해 AUTO_FIX 루프 작동 가능.

### 10.1 진입 조건 — 6가지 AND

| # | 조건 |
|---|------|
| 1 | Critical 이슈 0건 |
| 2 | High 이슈 1~2건 이내 |
| 3 | 아키텍처 구조 변경 없음 (신규 모듈/패키지 추가 불가) |
| 4 | 새로운 외부 의존성 추가 없음 |
| 5 | Security Expert 비토 없음 |
| 6 | Performance Expert 비토 없음 |

하나라도 미충족 시 AUTO_FIX 진입 불가 — Team Lead 명시 지시 대기.

### 10.2 수정 범위 엄수

- verifier/Council가 전달한 **이슈 목록에 명시된 항목만** 수정.
- 이슈 무관한 리팩토링·스타일 변경 금지.
- 수정 대상이 이슈 목록 외 파일로 확장되면 Team Lead 승인 필수.

### 10.3 재검증 플로우

```
[1] verifier → PARTIAL 이슈 목록 수신
[2] 이슈별 원인 분석 + 수정 (범위 엄수)
[3] 로컬 pytest 실행하여 기존 테스트 통과 확인
[4] TaskUpdate + SendMessage로 수정 완료 보고
[5] verifier 재검증 실행
[6] PASS → 종료
    PARTIAL → [2] 반복 (최대 3회)
    FAIL → AUTO_FIX 중단, Team Lead 에스컬레이션
```

- **3회 초과**: AUTO_FIX 종료, Team Lead에게 BLOCKED 에스컬레이션
- **Critical 신규**: 즉시 AUTO_FIX 중단, Team Lead 보고

---

## §11 실전 예제 (BE, 축약)

### 11.1 FastAPI + SQLAlchemy 에러 핸들링 (Retry + Pydantic 통합)

```python
from fastapi import APIRouter, HTTPException
from sqlalchemy.exc import OperationalError, IntegrityError
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
from app.database import get_async_session
from app.models import Item
from app.schemas import ItemCreate, ItemResponse

router = APIRouter()

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=4),
    retry=retry_if_exception_type(OperationalError),
    reraise=True,
)
async def _create_item_with_retry(session, data: ItemCreate) -> Item:
    item = Item(**data.model_dump())
    session.add(item); await session.commit(); await session.refresh(item)
    return item

@router.post("/items", response_model=ItemResponse, status_code=201)
async def create_item(data: ItemCreate) -> ItemResponse:
    async with get_async_session() as session:
        try:
            item = await _create_item_with_retry(session, data)
            return ItemResponse.model_validate(item)
        except OperationalError:
            raise HTTPException(503, "데이터베이스 연결 실패. 잠시 후 재시도해 주세요.")
        except IntegrityError:
            await session.rollback()
            raise HTTPException(409, "중복 데이터가 존재합니다.")
```

### 11.2 Pydantic 유효성 검증 (field·model_validator)

```python
from datetime import date
from pydantic import BaseModel, Field, field_validator, model_validator

class ProjectCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    start_date: date
    end_date: date
    budget: int = Field(..., ge=0)

    @field_validator("name")
    @classmethod
    def name_must_not_be_blank(cls, v: str) -> str:
        s = v.strip()
        if not s: raise ValueError("프로젝트 이름은 공백만으로 구성할 수 없습니다.")
        return s

    @model_validator(mode="after")
    def end_date_must_be_after_start(self):
        if self.end_date < self.start_date:
            raise ValueError(f"종료일({self.end_date})은 시작일({self.start_date}) 이후여야 합니다.")
        return self
```

→ 상세 참조: `_backup/GUIDES/backend-work-guide.md §코드 예제` (Phase-F 이관 시 레거시 보존).

---

**문서 관리**: v1.1 (2026-04-13 생성, 2026-04-15 Phase-E·F 확장), 원본 4-fn-dev-field-procedure-v1.md 재구성
