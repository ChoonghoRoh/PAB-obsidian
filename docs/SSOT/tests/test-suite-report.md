# 테스트 스위트 리포트 (프로젝트 기반, 상세)

목표:
- `tests/`의 각 테스트가 **어떤 상황에서 필요한지**를 “현재 프로젝트 기능” 기준으로 정리
- **일괄 실행 시 부하**(LLM/임베딩/Qdrant/Redis)로 인한 흔들림을 줄이기 위한 실행 전략을 제공

---

## 1) 테스트 실행이 “전부 실행”이 아닌 이유

`pytest tests/`는 기본적으로 `tests/` 아래에서 pytest가 인식하는 테스트를 수집해 실행하지만, 이 프로젝트는 테스트가 다음 성격으로 섞여 있다.

- **폴백 허용형 API Smoke**: DB/LLM이 없으면 500을 허용하거나 skip하는 테스트가 있음  
  → “기능이 망가졌는지”가 아니라 “라우터가 살아있는지/스키마가 유지되는지” 확인에 가깝다.
- **외부 의존/부하 민감**: Ollama(LLM), 임베딩 모델 로딩, Qdrant upsert 등은 동시에 돌리면 느려지거나 타임아웃이 발생하기 쉬움  
  → `heavy`를 단독 실행하는 이유.
- **테스트 DB가 2종**: `db_session`(SQLite in-memory)와 `SessionLocal`(실제 DB) 접근이 섞여 있음  
  → “로컬 빠른 단위” vs “통합 환경”을 구분해야 한다.

---

## 2) 기능 영역별 추천 테스트 (언제 무엇을 돌릴지)

### A. AI Q&A(`/api/ask`)·LLM 관련

- **필수(변경 시)**:
  - `tests/test_ai_api.py`: ask 기본 요청/입력 검증/폴백 + `/api/system/status` 구조
- **복원력/정책 변경 시**:
  - `tests/integration/test_llm_network.py`: 네트워크 오류 분류·재시도·폴백(urllib patch 기반)
  - `tests/integration/test_llm_3tier.py`: 모델 tier 선택·캐시·토큰 한도

권장 실행 방식:
- AI/Ollama 관련은 **단독 1회** 먼저 실행(부하/경합 방지)

---

### B. Knowledge(청크·라벨·관계)·승인(Bulk Approval)

- **필수(라우터/스키마/검증 변경 시)**:
  - `tests/test_knowledge_api.py`: chunks/labels/relations 기본 검증
  - `tests/test_approval_bulk_api.py`: 승인 설정 + batch API 입력/응답 스키마
- **이력/일관성/사이클 관련 변경 시**:
  - `tests/test_phase20_5.py`: history_service/changelog API, 라벨 일관성 검사, 순환 관계 방지
- **통합 환경에서 플로우 확인 시**:
  - `tests/integration/test_knowledge_workflow.py`: chunks→labels→relations 최소 연속 호출
  - `tests/integration/test_import_matching.py`: `/suggestions` 연동

주의:
- DB 준비 여부에 따라 skip/500 허용 케이스가 있으니, “완전한 통합”을 보려면 DB/Qdrant 준비된 환경에서 실행해야 한다.

---

### C. 검색(Search)·캐시(Redis/메모리)·하이브리드 검색

- **필수(검색 관련 변경 시)**:
  - `tests/test_api_routers.py`: `/api/search*`, cache stats
  - `tests/test_search_service.py`: SearchService 캐시/Redis 캐시 동작(구현에 따라)
  - `tests/test_hybrid_search.py`: 결과 결합 로직(RRF)
- **통합 플로우 확인 시**:
  - `tests/integration/test_document_to_answer.py`: search→ask 흐름

---

### D. Reasoning(일반/문서 필터/추천)

- **라우터/파라미터 변경 시**:
  - `tests/test_reasoning_api.py`
  - `tests/test_reason_document.py` (document_ids, stream)
- **추천 로직/LLM 추천 변경 시**:
  - `tests/test_reasoning_recommendations.py`
  - `tests/test_keyword_recommenders.py`

---

### E. 인증/권한

- **정책/권한 레벨 변경 시**:
  - `tests/test_auth_permissions.py` (role hierarchy + admin API 접근 제어)

---

### F. Admin 설정 API / 작업 플랜 생성(자동화)

- `tests/test_admin_api.py`: admin 라우터가 OpenAPI에 포함되는지 + 목록 응답 구조
- `tests/test_task_plan_generator.py`: CLI 가용성 체크/plan 생성 구조/API 응답 구조

---

## 3) “일괄 실행 부하”를 줄이는 표준 실행 전략

권장:
- **수동 실행**: `pytest` 또는 `npx playwright test` 를 **한 번에 하나씩** 실행한다.
- **heavy 단독**: LLM/임베딩/Qdrant 관련 항목은 먼저 단독 실행 후 충분한 대기 시간 확보.

자동 디스커버리·순차 실행 파이프라인(generate/run_tester_commands)은 **미구현** — 도입은 별도 Phase에서 결정.

---

## 4) 1주기 산출물(요청서+결과서)로 리팩토링 자료 만들기

테스트 요청 시마다 아래 파일로 남기면, 추후 병목/불안정/회귀가 **자료로 축적**된다.

- 저장: `docs/pytest-report/YYMMDD-HHMM-phase-X-Y-테스트명.md`
- 생성: `python3 scripts/tests/run_tester_with_report.py --phase X-Y --name 회귀 --scope partial`

FAIL인 경우:
- 어떤 구분(backend/frontend/db/api/llm/qdrant/redis)에서 실패했는지
- 재현 조건(환경·데이터·옵션)
- 수정 보완점(테스트 튜닝/코드 리팩토링 후보)을 **같은 문서에 남긴다**

---

## 5) 현재 코드 기준 “주의/개선 포인트” (문서화)

이 섹션은 **테스트 튜닝 문서**로 이어질 수 있는 개선 포인트를 기록한다.

- `tests/integration/test_phase_12_qc.py`
  - 일부 케이스는 “실제 존재하는 엔드포인트/미들웨어 동작”과 맞는지 점검이 필요함(예: `/api/memories/`가 실제 라우팅되는지).
  - CORS 테스트는 TestClient에서 미들웨어 처리 차이로 405/200이 갈릴 수 있어, 명확한 기준을 추가하는 편이 좋다.
- `tests/test_reasoning_recommendations.py`, `tests/test_structure_matching.py` 등
  - `SessionLocal`(실 DB) 접근이 섞여 있어, 로컬 단위 테스트로 돌릴 때 환경 의존성이 생김.

개선안은 별도 문서 `docs/tests/test-tuning-guide.md`에 정리한다.

