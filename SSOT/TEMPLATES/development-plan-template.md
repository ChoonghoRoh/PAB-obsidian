# 개발 계획서 템플릿 (Development Plan Template)

> **버전**: 1.0 | **생성일**: 2026-04-16 (Phase-G sub-G-3)
> **적용 Step**: AutoCycle Step 3 — 개발 PLAN 수립 / 목표 / KPI 수치화 / 사용자·개발자 관점
> **작성 주체**: planner (PLANNING 단계)
> **참조**: `autocycle-kpi-targets.md`, `SUB-SSOT/PLANNER/1-planning-procedure.md`

---

## §1 원본 프롬프트 (사용자 요청 원문)

> {사용자 개발 요청 프롬프트 전문을 여기에 인용}

**프롬프트 수신 일시**: YYYY-MM-DD HH:MM
**요청 분류**: [신규 기능 / 개선 / 버그 수정 / 리팩토링 / 기타]

---

## §2 개발 목표

### 2.1 사용자 관점 (User Perspective)

| 항목 | 내용 |
|------|------|
| **사용자가 기대하는 결과** | {사용자 시나리오 기술 — "~하면 ~가 된다"} |
| **사용성 개선 포인트** | {UI 변경·워크플로우 단축·오류 감소 등} |
| **비즈니스 가치** | {시간 절감·정확도 향상·신규 기능 등} |

### 2.2 개발자 관점 (Developer Perspective)

| 항목 | 내용 |
|------|------|
| **아키텍처 영향** | {변경 모듈·레이어·API·DB 스키마} |
| **기술 선택** | {라이브러리·프레임워크·패턴 — Research 결과 반영} |
| **리스크** | {호환성·성능·보안 위험} |
| **복잡도 티어** | HIGH / MED / LOW |

---

## §3 KPI 정의 (SMART 기준)

### 3.1 KPI 표

| KPI ID | 지표 | 초기값 (as-is) | 목표값 (to-be) | 측정법 | 달성 기한 |
|--------|------|----------------|----------------|--------|-----------|
| KPI-01 | {예: 응답시간 p99} | {현재값 ms} | {목표값 ms} | {pytest / 벤치마크 / grep / 수동} | Phase X-Y 종료 시 |
| KPI-02 | {예: 테스트 커버리지} | {현재%} | {목표%} | pytest --cov | 동 |
| KPI-03 | {사용자 시나리오 통과율} | — | 100% | E2E / Playwright | 동 |

> **SMART 가이드**: Specific(구체적) · Measurable(측정 가능) · Achievable(달성 가능) · Relevant(관련성) · Time-bound(기한 명시).
> **초기값이 없는 경우**: "측정 없음(N/A)" 기입 후, Phase 시작 시 1회 측정하여 갱신.

### 3.2 KPI → 테스트 매핑 (Step 10 입력)

| KPI ID | 테스트 유형 | 테스트 파일/명령 (예상) | 판정 기준 |
|--------|------------|------------------------|-----------|
| KPI-01 | 단위 테스트 | `pytest tests/test_{module}.py -k "response_time"` | p99 < {목표값}ms |
| KPI-02 | 커버리지 | `pytest --cov=backend/app --cov-report=term-missing` | ≥{목표%}% |
| KPI-03 | E2E / Playwright | `npx playwright test tests/e2e/{scenario}.spec.ts` | PASS 100% |

> TESTER는 본 표를 `§KPI-driven Test Plan` 절차의 입력으로 사용.

---

## §4 Task 분해 (planner 출력)

| Task ID | 도메인 | 담당 팀원 | 요약 | 완료 기준 | 복잡도 | UI 변경 | KPI 연결 |
|---------|--------|----------|------|-----------|--------|---------|----------|
| X-Y-1 | [DB] | backend-dev | {요약} | {done_when} | HIGH | 아니오 | KPI-01 |
| X-Y-2 | [BE] | backend-dev | {요약} | {done_when} | MED | 아니오 | KPI-01·02 |
| X-Y-3 | [FE] | frontend-dev | {요약} | {done_when} | MED | 예 | KPI-03 |

**G1 준비 여부**:
- 완료 기준 명확: 예/아니오
- Task 수: N (3~7 범위)
- DESIGN_REVIEW 필요: 예/아니오

---

## §5 리스크·완화

| 리스크 ID | 설명 | 영향도(1~5) | 발생 가능성(1~5) | 점수 | 완화 방안 |
|-----------|------|------------|------------------|------|-----------|
| R-01 | {예: 기존 API Breaking Change} | 4 | 3 | 12 | {Migration 스크립트 작성} |

---

## §6 사전 반복 이력 (Step 6 — ITER-PRE)

| 이터레이션 | 일시 | 변경 요약 | KPI 일관성 변동 |
|-----------|------|-----------|----------------|
| #1 | — | 초안 | — |
| #2 | — | {변경 사유} | {증가/감소} |
| #3 | — | {변경 사유} | {증가/감소} |

> Step 6 3회 반복 종료 시 **G-Pre 수렴 게이트** 확인 (Phase-H H-1 보완 후 적용).

---

## 사용 안내

1. **작성**: planner가 본 템플릿을 채워 SendMessage로 Team Lead에게 전달
2. **승인**: Team Lead가 G1 판정 + §3 KPI 적절성 검토
3. **참조**: CODER는 §4 Task 분해, TESTER는 §3.2 KPI→테스트 매핑
4. **갱신**: Step 5 diff 분석 후 §3·§4 갱신, Step 6 반복 시 §6 이력 추가
5. **보존**: Phase 종료 후 `docs/phases/phase-X-Y/development-plan.md` 로 저장

---

**문서 관리**: v1.0, 2026-04-16, AutoCycle Step 3 개발 계획서 템플릿. Phase-G sub-G-3.
