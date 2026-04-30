# 테스트-Phase 연관성 분석 문서

> 작성일: 2026-03-01 | 기준: 280개 테스트 (29개 파일) | Phase 25-2 마커 체계 적용 후

---

## 1. Phase → 테스트 파일 매핑

Phase별로 **생성된 테스트 파일**과, 해당 Phase 기능 변경 시 **실행해야 할 테스트**를 구분한다.

### Phase 9 (초기 API 구축)

| 생성 Phase | 파일 | 테스트 수 | 마커 | 대상 |
|:---------:|------|:--------:|:----:|------|
| 9-2-1 | `test_ai_api.py` | 6 | llm | `/api/ask`, `/api/system/status` |
| 9-2-2 | `test_knowledge_api.py` | 6 | smoke | `/api/knowledge/chunks`, `/api/labels`, `/api/relations` |
| 9-2-3 | `test_reasoning_api.py` | 8 | llm | `/api/reason`, `/api/reason/recommendations/*` |
| 9-2-4 | `test_document_to_answer.py` | 2 | integration | `/api/search` → `/api/ask` 흐름 |
| 9-2-4 | `test_import_matching.py` | 1 | integration | `/api/knowledge/chunks/*/suggestions` |
| 9-2-4 | `test_knowledge_workflow.py` | 2 | integration | chunks → labels → relations 연속 |
| 9-3-1 | `test_reasoning_recommendations.py` | 6 | db | 추천 서비스/프롬프트 로직 |
| 9-3-2 | `test_structure_matching.py` | 5 | db | 구조 매칭/카테고리 추론 |
| 9-3-3 | `test_hybrid_search.py` | 4 | — | RRF 점수/정렬 로직 |
| 초기 | `test_models.py` | 3 | — | Project/Document/Memory 모델 CRUD |

### Phase 11~16 (기능 확장)

| 생성 Phase | 파일 | 테스트 수 | 마커 | 대상 |
|:---------:|------|:--------:|:----:|------|
| 11-2 | `test_admin_api.py` | 6 | smoke | `/api/admin/*` (설정 API) |
| 12 | `test_phase_12_qc.py` | 10 | — | HSTS/RateLimit/CORS/에러포맷 QC |
| 14-1 | `test_auth_permissions.py` | 11 | smoke | JWT/역할 계층/Admin 접근 제어 |
| 15-1 | `test_folder_management.py` | 19 | — | 폴더 경로/파일 스캔/동기화 |
| 15-2 | `test_ai_automation_api.py` | 16 | — | `/api/automation/*` 상태머신/취소 |
| 15-2 | `test_ai_workflow_service.py` | 12 | — | 문서→청크→키워드→라벨→승인→임베딩 |
| 15-3 | `test_reason_document.py` | 7 | llm, timeout | `/api/reason` document_ids 필터/스트리밍 |
| 15-4 | `test_search_service.py` | 7 | redis | SearchService 캐시/Redis 백엔드 |
| 16-7 | `test_api_routers.py` | 4 | smoke, redis | `/api/search*`, cache stats, `/health` |
| 16-7 | `test_task_plan_generator.py` | 12 | — | Task Plan 생성/CLI 가용성/API 응답 |

### Phase 17~25 (고도화)

| 생성 Phase | 파일 | 테스트 수 | 마커 | 대상 |
|:---------:|------|:--------:|:----:|------|
| 17-2 | `test_keyword_recommenders.py` | 23 | llm | 키워드 추출/매칭/폴백/recommender |
| 20-2 | `test_approval_bulk_api.py` | 23 | db | `/api/approval/*` 승인 설정/배치 |
| 20-5 | `test_phase20_5.py` | 18 | — | 이력/일관성/순환방지/AI연계 |
| 22-3 | `test_llm_3tier.py` | 33 | llm, integration | 3-Tier 모델 선택/캐시/토큰 한도 |
| 22-3 | `test_llm_network.py` | 21 | llm, integration | 네트워크 재시도/폴백/오류 분류 |
| 25-1 | `test_llm_timeout_tier.py` | 12 | llm, integration | TIER_TIMEOUT/모델 티어 매핑 |
| 25-2 | `test_reason_document.py` (**변경**) | 7 | llm, timeout | mock 기반 스트리밍 테스트 전환 + `@timeout(60)` 추가 |
| 25-2 | `stream_executor.py` (**버그 수정**) | — | — | `_async_stream_tokens` StopIteration/Future 버그 → sentinel 패턴 |
| 25-2 | `conftest.py` (**변경**) | — | — | `collect_metrics` 조건부 실행 (`PYTEST_COLLECT_METRICS`) |
| 25-2 | 14개 테스트 파일 (**마커 추가**) | — | llm, smoke, db, redis | 7개 마커 체계 전면 적용 (Phase 25-2 마커 체계) |
| 26 (A/B) | `test_graph_stats.py` | 3 | — | `/api/knowledge/graph/stats` |
| 26 (A/B) | `test_label_suggestions.py` | 2 | — | `/api/knowledge/labels/suggest*` |

---

## 2. 기능 도메인 → 실행 대상 테스트

Phase 개발 시 **변경하는 기능 도메인**에 따라 실행할 테스트를 선택한다.

### AI/LLM 도메인 (Ollama 필요)

```bash
# 실행 명령
OLLAMA_BASE_URL=http://192.168.0.22:11434 \
python3 -m pytest tests/ -m "llm and not integration" --tb=short -v
```

| 변경 대상 | 필수 테스트 | 추가 권장 |
|----------|-----------|----------|
| `/api/ask` 엔드포인트 | test_ai_api.py | test_document_to_answer.py |
| `/api/reason` 엔드포인트 | test_reasoning_api.py, test_reason_document.py | — |
| ollama_client.py (타임아웃/모델) | test_llm_timeout_tier.py | test_llm_3tier.py, test_llm_network.py |
| 키워드 추천 로직 | test_keyword_recommenders.py | test_reasoning_recommendations.py |
| LLM 네트워크/폴백 | test_llm_network.py | test_llm_3tier.py |

### Knowledge 도메인 (DB 필요)

```bash
python3 -m pytest tests/ -m "db or smoke" --tb=short -v
```

| 변경 대상 | 필수 테스트 | 추가 권장 |
|----------|-----------|----------|
| `/api/knowledge/*` CRUD | test_knowledge_api.py | test_knowledge_workflow.py |
| `/api/approval/*` 승인 | test_approval_bulk_api.py | — |
| 이력/일관성/순환방지 | test_phase20_5.py | — |
| 모델 필드/제약 변경 | test_models.py | test_folder_management.py |
| 구조 매칭/라벨 추천 | test_structure_matching.py | test_label_suggestions.py, test_import_matching.py |
| 그래프 통계 | test_graph_stats.py | — |

### 검색/캐시 도메인 (Redis 필요)

```bash
python3 -m pytest tests/ -m "redis" --tb=short -v
```

| 변경 대상 | 필수 테스트 | 추가 권장 |
|----------|-----------|----------|
| `/api/search*` 라우터 | test_api_routers.py | test_document_to_answer.py |
| SearchService/캐시 | test_search_service.py | — |
| Hybrid 검색 점수/정렬 | test_hybrid_search.py | — |

### 인증/권한 도메인

```bash
python3 -m pytest tests/test_auth_permissions.py --tb=short -v
```

| 변경 대상 | 필수 테스트 |
|----------|-----------|
| JWT/역할/미들웨어 | test_auth_permissions.py |
| Admin API 접근 제어 | test_admin_api.py |

### 자동화/워크플로우 도메인

```bash
python3 -m pytest tests/test_ai_automation_api.py tests/test_ai_workflow_service.py tests/test_task_plan_generator.py --tb=short -v
```

| 변경 대상 | 필수 테스트 |
|----------|-----------|
| `/api/automation/*` | test_ai_automation_api.py |
| 워크플로우 서비스 | test_ai_workflow_service.py |
| Task Plan 생성 | test_task_plan_generator.py |

### 인프라/보안 도메인

```bash
python3 -m pytest tests/integration/test_phase_12_qc.py --tb=short -v
```

| 변경 대상 | 필수 테스트 |
|----------|-----------|
| HSTS/CORS/RateLimit | test_phase_12_qc.py |
| 폴더 관리/파일 스캔 | test_folder_management.py |

---

## 3. 소스 파일 → 테스트 영향 매트릭스

백엔드 소스 파일 변경 시 실행해야 할 테스트를 매핑한다.

| 소스 파일 | 영향받는 테스트 | 마커 |
|----------|---------------|:----:|
| `backend/routers/ai.py` | test_ai_api | llm |
| `backend/routers/reasoning.py` | test_reasoning_api, test_reason_document | llm |
| `backend/routers/knowledge/*.py` | test_knowledge_api, test_approval_bulk_api, test_phase20_5 | smoke, db |
| `backend/routers/search.py` | test_api_routers, test_search_service | smoke, redis |
| `backend/routers/admin.py` | test_admin_api, test_auth_permissions | smoke |
| `backend/routers/auth.py` | test_auth_permissions | smoke |
| `backend/routers/automation.py` | test_ai_automation_api, test_task_plan_generator | — |
| `backend/services/ai/ollama_client.py` | test_llm_timeout_tier, test_llm_3tier, test_llm_network | llm |
| `backend/services/search/*.py` | test_search_service, test_hybrid_search | redis |
| `backend/services/reasoning/*.py` | test_reasoning_recommendations, test_keyword_recommenders | db, llm |
| `backend/services/knowledge/*.py` | test_structure_matching, test_folder_management, test_phase20_5 | db |
| `backend/services/automation/*.py` | test_ai_automation_api, test_ai_workflow_service | — |
| `backend/models/models.py` | test_models, test_folder_management | — |
| `backend/config.py` | test_llm_timeout_tier, test_phase_12_qc | llm |
| `backend/middleware/*.py` | test_phase_12_qc, test_auth_permissions | — |

---

## 4. 마커별 실행 명령 정리

### 환경별 권장 실행 순서

```bash
# Step 1: Smoke (외부 서비스 불필요, ~10초)
python3 -m pytest tests/ -m "smoke" --tb=short -q

# Step 2: DB 의존 (PostgreSQL 필요, ~10초)
python3 -m pytest tests/ -m "db" --tb=short -q

# Step 3: Redis 의존 (Redis 필요, ~45초)
python3 -m pytest tests/ -m "redis" --tb=short -q

# Step 4: 마커 없는 순수 로직 (외부 서비스 불필요)
python3 -m pytest tests/ -m "not llm and not integration and not smoke and not db and not redis" --tb=short -q

# Step 5: LLM 의존 (Ollama 필요, 단독 실행 권장)
OLLAMA_BASE_URL=http://192.168.0.22:11434 \
python3 -m pytest tests/ -m "llm and not integration" --tb=short -q

# Step 6: 통합 (모든 서비스 필요)
OLLAMA_BASE_URL=http://192.168.0.22:11434 \
python3 -m pytest tests/ -m "integration" --tb=short -q
```

### 빠른 회귀 (2분 내)

```bash
python3 -m pytest tests/ -m "not llm and not integration" --tb=short -q
```

### 전체 실행 (LLM 포함)

```bash
OLLAMA_BASE_URL=http://192.168.0.22:11434 \
python3 -m pytest tests/ --tb=short -q --timeout=60
```

---

## 5. 테스트 분포 현황

### 마커별

| 마커 | 테스트 수 | 비율 | 실행 조건 |
|------|:--------:|:----:|----------|
| llm | 105 | 37.5% | Ollama (192.168.0.22:11434) |
| smoke | 27 | 9.6% | 없음 (로컬 실행 가능) |
| db | 34 | 12.1% | PostgreSQL (localhost:5433) |
| redis | 8 | 2.9% | Redis (localhost:6379) |
| integration | 46 | 16.4% | 전체 환경 |
| 마커 없음 | ~106 | 37.9% | 대부분 로컬 실행 가능 |
| **전체** | **280** | 100% | |

> 마커 중복 있음 (llm+integration 등). 비율 합계 > 100%

### 생성 Phase별 테스트 수

| Phase 범위 | 테스트 수 | 주요 기능 |
|:---------:|:--------:|----------|
| 9 (초기) | 42 | 기본 API + 통합 + 검색 로직 |
| 11~12 | 16 | Admin + QC/보안 |
| 14~16 | 75 | 인증 + 폴더 + 자동화 + Reasoning + 캐시 |
| 17 | 23 | 키워드 추천 |
| 20 | 41 | 승인/이력/일관성 |
| 22~23 | 54 | LLM 3-Tier + 네트워크 복원력 |
| 25 | 12 | 타임아웃/모델 티어 |
| 26 (A/B) | 5 | 그래프 통계 + 라벨 추천 |

---

## 6. Phase 개발 시 테스트 실행 가이드

### 새 Phase 시작 시 체크리스트

1. **변경 도메인 확인** → §2에서 해당 도메인의 필수 테스트 파악
2. **소스 파일 확인** → §3에서 영향받는 테스트 파악
3. **환경 확인** → Docker 서비스 상태, Ollama 접근 여부
4. **구현 완료 후** → §4의 빠른 회귀 먼저 실행
5. **G3 게이트** → §4의 환경별 순서대로 실행

### 예시: Phase X에서 `/api/reason` 로직 변경 시

```bash
# 1. 직접 관련 테스트 (llm 마커, Ollama 필요)
OLLAMA_BASE_URL=http://192.168.0.22:11434 \
python3 -m pytest tests/test_reasoning_api.py tests/test_reason_document.py --tb=short -v

# 2. 추천 로직 영향 확인
python3 -m pytest tests/test_reasoning_recommendations.py --tb=short -v

# 3. 빠른 회귀 (전체 non-LLM)
python3 -m pytest tests/ -m "not llm and not integration" --tb=short -q
```

---

## 관련 문서

| 문서 | 용도 |
|------|------|
| [index.md](index.md) | 테스트 파일 인덱스 (상황별 로드 가이드) |
| [test-suite-report.md](test-suite-report.md) | 기능 영역별 추천 테스트 + 실행 전략 |
| [test-tuning-guide.md](test-tuning-guide.md) | 마커/환경/부하 튜닝 가이드 |
| `docs/pytest-report/` | 1주기 요청서/결과서 저장소 |
