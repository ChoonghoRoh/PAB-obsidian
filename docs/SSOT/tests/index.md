# 테스트 선택 실행 가이드

> 기준: 280개 테스트 (29개 파일) | Phase 25-2 마커 체계 적용 후
>
> **원칙: 전체 테스트 실행은 불필요하다.** 변경한 코드에 영향받는 테스트만 선택 실행한다.

---

## 1. 변경 시나리오별 실행 가이드

### 어떤 코드를 변경했는지 확인 → 해당 시나리오의 명령어 실행

---

### A. AI/LLM (`/api/ask`, Ollama, 키워드 추천)

**환경**: Ollama 서버 필요 (192.168.0.22:11434)

```bash
OLLAMA_BASE_URL=http://192.168.0.22:11434 \
python3 -m pytest tests/test_ai_api.py tests/test_keyword_recommenders.py --tb=short -v
```

| 변경 대상 | 실행할 테스트 | 테스트 수 | 소요 |
|----------|-------------|:--------:|:----:|
| `/api/ask` 엔드포인트 | test_ai_api.py | 6 | ~15초 |
| 키워드 추천 로직 | test_keyword_recommenders.py | 23 | ~5초 |
| ollama_client.py | test_ai_api.py | 6 | ~15초 |

---

### B. Reasoning (`/api/reason`, 추론, 추천)

**환경**: Ollama 서버 필요

```bash
OLLAMA_BASE_URL=http://192.168.0.22:11434 \
python3 -m pytest tests/test_reasoning_api.py tests/test_reason_document.py tests/test_reasoning_recommendations.py --tb=short -v
```

| 변경 대상 | 실행할 테스트 | 테스트 수 | 소요 |
|----------|-------------|:--------:|:----:|
| `/api/reason` 라우터 | test_reasoning_api.py | 8 | ~35초 |
| document_ids 필터/스트리밍 | test_reason_document.py | 7 | ~70초 |
| 추천 서비스/프롬프트 | test_reasoning_recommendations.py | 6 | ~5초 |

---

### C. Knowledge (`/api/knowledge`, 청크, 라벨, 관계, 승인)

**환경**: PostgreSQL (Docker, localhost:5433)

```bash
python3 -m pytest tests/test_knowledge_api.py tests/test_approval_bulk_api.py tests/test_phase20_5.py tests/test_structure_matching.py --tb=short -v
```

| 변경 대상 | 실행할 테스트 | 테스트 수 | 소요 |
|----------|-------------|:--------:|:----:|
| 청크/라벨/관계 CRUD | test_knowledge_api.py | 6 | ~5초 |
| 승인 설정/배치 API | test_approval_bulk_api.py | 23 | ~5초 |
| 이력/일관성/순환방지 | test_phase20_5.py | 18 | ~10초 |
| 구조 매칭/라벨 추천 | test_structure_matching.py | 5 | ~5초 |
| 모델 필드/제약 | test_models.py | 3 | ~2초 |
| 그래프 통계 | test_graph_stats.py | 3 | ~2초 |
| 라벨 추천 제안 | test_label_suggestions.py | 2 | ~2초 |

---

### D. 검색/캐시 (`/api/search`, Redis, Hybrid)

**환경**: Redis (Docker, localhost:6379)

```bash
python3 -m pytest tests/test_api_routers.py tests/test_search_service.py tests/test_hybrid_search.py --tb=short -v
```

| 변경 대상 | 실행할 테스트 | 테스트 수 | 소요 |
|----------|-------------|:--------:|:----:|
| `/api/search*` 라우터 | test_api_routers.py | 4 | ~10초 |
| SearchService/캐시 | test_search_service.py | 7 | ~45초 |
| Hybrid 검색 점수/정렬 | test_hybrid_search.py | 4 | ~2초 |

---

### E. 인증/권한 (JWT, 역할, Admin)

**환경**: 없음 (로컬 실행 가능)

```bash
python3 -m pytest tests/test_auth_permissions.py tests/test_admin_api.py --tb=short -v
```

| 변경 대상 | 실행할 테스트 | 테스트 수 | 소요 |
|----------|-------------|:--------:|:----:|
| JWT/역할/미들웨어 | test_auth_permissions.py | 11 | ~5초 |
| Admin 설정 API | test_admin_api.py | 6 | ~5초 |

---

### F. 자동화/워크플로우 (`/api/automation`, Task Plan)

**환경**: 없음 (로컬 실행 가능, Mock 기반)

```bash
python3 -m pytest tests/test_ai_automation_api.py tests/test_ai_workflow_service.py tests/test_task_plan_generator.py --tb=short -v
```

| 변경 대상 | 실행할 테스트 | 테스트 수 | 소요 |
|----------|-------------|:--------:|:----:|
| `/api/automation/*` 상태머신 | test_ai_automation_api.py | 16 | ~5초 |
| 워크플로우 서비스 | test_ai_workflow_service.py | 12 | ~5초 |
| Task Plan 생성 | test_task_plan_generator.py | 12 | ~5초 |

---

### G. 폴더 관리/파일 스캔

**환경**: 없음 (SQLite + tmp_path)

```bash
python3 -m pytest tests/test_folder_management.py --tb=short -v
```

| 변경 대상 | 실행할 테스트 | 테스트 수 | 소요 |
|----------|-------------|:--------:|:----:|
| 폴더 경로/파일 스캔/동기화 | test_folder_management.py | 19 | ~5초 |

---

### H. 인프라/보안 (HSTS, CORS, RateLimit)

**환경**: Redis (옵션)

```bash
python3 -m pytest tests/integration/test_phase_12_qc.py --tb=short -v
```

| 변경 대상 | 실행할 테스트 | 테스트 수 | 소요 |
|----------|-------------|:--------:|:----:|
| HSTS/CORS/RateLimit/에러포맷 | test_phase_12_qc.py | 10 | ~5초 |

---

### I. LLM 정책 (3-Tier, 네트워크 복원력, 타임아웃)

**환경**: 없음 (Mock 기반, Ollama 불필요)

```bash
python3 -m pytest tests/integration/test_llm_3tier.py tests/integration/test_llm_network.py tests/integration/test_llm_timeout_tier.py --tb=short -v
```

| 변경 대상 | 실행할 테스트 | 테스트 수 | 소요 |
|----------|-------------|:--------:|:----:|
| 모델 선택/캐시/토큰 한도 | test_llm_3tier.py | 33 | ~10초 |
| 재시도/폴백/오류 분류 | test_llm_network.py | 21 | ~10초 |
| 타임아웃/모델 티어 매핑 | test_llm_timeout_tier.py | 12 | ~5초 |

---

## 2. 회귀 테스트 (구현 완료 후 최종 확인)

개별 시나리오 테스트 PASS 후, 다른 기능에 영향이 없는지 빠른 회귀를 실행한다.

### 빠른 회귀 (~2분, LLM/통합 제외)

```bash
python3 -m pytest tests/ -m "not llm and not integration" --tb=short -q
```

- 약 170개 테스트 실행 (외부 서비스 의존 최소)
- **Phase 완료 시 G3 게이트 최소 요건**

### LLM 포함 회귀 (~6분)

```bash
OLLAMA_BASE_URL=http://192.168.0.22:11434 \
python3 -m pytest tests/ -m "not integration" --tb=short -q --timeout=60
```

- 약 210개 테스트 실행 (Ollama 필요)
- `--timeout=60`으로 스트리밍 HANG 방지

### 통합 테스트 (별도 환경 필요)

```bash
OLLAMA_BASE_URL=http://192.168.0.22:11434 \
python3 -m pytest tests/ -m "integration" --tb=short -q
```

- 약 46개 테스트 (PostgreSQL + Redis + Qdrant + Ollama 전부 필요)
- 일반 개발 시 불필요, 릴리스 전 또는 G3 Full 시에만 실행

---

## 3. 소스 파일 → 테스트 빠른 참조

코드를 수정한 파일 기준으로 어떤 테스트를 실행할지 바로 찾는다.

| 수정한 소스 파일 | 실행할 테스트 | 시나리오 |
|----------------|-------------|:--------:|
| `routers/ai/*.py` | test_ai_api | A |
| `routers/reasoning/*.py` | test_reasoning_api, test_reason_document | B |
| `routers/knowledge/*.py` | test_knowledge_api, test_approval_bulk_api, test_phase20_5 | C |
| `routers/search.py` | test_api_routers, test_search_service | D |
| `routers/admin.py` | test_admin_api, test_auth_permissions | E |
| `routers/auth.py` | test_auth_permissions | E |
| `routers/automation/*.py` | test_ai_automation_api, test_task_plan_generator | F |
| `services/ai/ollama_client.py` | test_ai_api, test_llm_3tier, test_llm_network, test_llm_timeout_tier | A + I |
| `services/search/*.py` | test_search_service, test_hybrid_search | D |
| `services/reasoning/*.py` | test_reasoning_recommendations, test_keyword_recommenders | B |
| `services/knowledge/*.py` | test_structure_matching, test_folder_management, test_phase20_5 | C + G |
| `services/automation/*.py` | test_ai_automation_api, test_ai_workflow_service | F |
| `models/models.py` | test_models, test_folder_management | C + G |
| `config.py` | test_llm_timeout_tier, test_phase_12_qc | H + I |
| `middleware/*.py` | test_phase_12_qc, test_auth_permissions | E + H |

---

## 4. 마커별 실행 (환경 기반)

사용 가능한 외부 서비스에 따라 마커로 필터링한다.

| 마커 | 테스트 수 | 필요 환경 | 명령어 |
|------|:--------:|----------|--------|
| smoke | 27 | 없음 | `pytest tests/ -m "smoke" --tb=short -q` |
| db | 34 | PostgreSQL | `pytest tests/ -m "db" --tb=short -q` |
| redis | 8 | Redis | `pytest tests/ -m "redis" --tb=short -q` |
| llm | ~39 | Ollama | `OLLAMA_BASE_URL=... pytest tests/ -m "llm and not integration" --tb=short -q` |
| integration | 46 | 전체 환경 | `OLLAMA_BASE_URL=... pytest tests/ -m "integration" --tb=short -q` |
| 마커 없음 | ~106 | 대부분 없음 | `pytest tests/ -m "not llm and not integration and not smoke and not db and not redis" --tb=short -q` |

---

## 5. 테스트 파일 전체 목록

### `tests/` (단위 + API)

| 파일 | 테스트 수 | 마커 | 의존성 | 용도 |
|------|:--------:|:----:|--------|------|
| test_ai_api.py | 6 | llm | Ollama | `/api/ask` 기본 동작, 시스템 상태 |
| test_reasoning_api.py | 8 | llm | Ollama | `/api/reason` 모드별 요청, 추천 |
| test_reason_document.py | 7 | llm, timeout | Ollama(mock) | document_ids 필터, 스트리밍 SSE |
| test_knowledge_api.py | 6 | smoke | DB | 청크/라벨/관계 CRUD |
| test_api_routers.py | 4 | smoke, redis | Redis | search 라우터, 캐시, /health |
| test_admin_api.py | 6 | smoke | — | Admin 설정 API |
| test_approval_bulk_api.py | 23 | db | DB | 승인 설정/배치 API |
| test_auth_permissions.py | 11 | smoke | — | JWT/역할/Admin 접근 제어 |
| test_search_service.py | 7 | redis | Redis | SearchService 캐시 |
| test_hybrid_search.py | 4 | — | — | RRF 점수/정렬 (순수 로직) |
| test_structure_matching.py | 5 | db | DB | 구조 매칭/카테고리 추론 |
| test_reasoning_recommendations.py | 6 | db | DB | 추천 서비스/프롬프트 |
| test_keyword_recommenders.py | 23 | llm | Mock | 키워드 추출/매칭/폴백 |
| test_ai_automation_api.py | 16 | — | — | 자동화 상태머신/취소 |
| test_ai_workflow_service.py | 12 | — | Mock | 워크플로우 흐름 (Qdrant mock) |
| test_task_plan_generator.py | 12 | — | — | Task Plan 생성/CLI |
| test_models.py | 3 | — | SQLite | 모델 CRUD |
| test_folder_management.py | 19 | — | SQLite + FS | 폴더 경로/스캔/동기화 |
| test_phase20_5.py | 18 | — | SQLite + API | 이력/일관성/순환방지 |
| test_graph_stats.py | 3 | — | — | 그래프 통계 API |
| test_label_suggestions.py | 2 | — | — | 라벨 추천 제안 API |

### `tests/integration/` (통합)

| 파일 | 테스트 수 | 마커 | 의존성 | 용도 |
|------|:--------:|:----:|--------|------|
| test_knowledge_workflow.py | 2 | integration | DB | 청크→라벨→관계 연속 호출 |
| test_document_to_answer.py | 2 | integration | DB+Qdrant+Ollama | 검색→질의 통합 흐름 |
| test_import_matching.py | 1 | integration | DB | 라벨 추천 `/suggestions` |
| test_llm_3tier.py | 33 | llm, integration | Mock | 3-Tier 모델 선택/캐시 |
| test_llm_network.py | 21 | llm, integration | Mock | 네트워크 재시도/폴백 |
| test_llm_timeout_tier.py | 12 | llm, integration | Mock | 타임아웃/모델 티어 |
| test_phase_12_qc.py | 10 | — | 설정/미들웨어 | HSTS/CORS/RateLimit QC |

---

## 6. 실행 예시

### 예시 1: `/api/reason` 로직 변경 후

```bash
# 1. 직접 관련 테스트 (30초)
OLLAMA_BASE_URL=http://192.168.0.22:11434 \
python3 -m pytest tests/test_reasoning_api.py tests/test_reason_document.py --tb=short -v

# 2. 추천 영향 확인 (5초)
python3 -m pytest tests/test_reasoning_recommendations.py --tb=short -v

# 3. 빠른 회귀 (2분)
python3 -m pytest tests/ -m "not llm and not integration" --tb=short -q
```

### 예시 2: Knowledge CRUD 변경 후

```bash
# 1. 직접 관련 테스트 (20초)
python3 -m pytest tests/test_knowledge_api.py tests/test_approval_bulk_api.py tests/test_phase20_5.py --tb=short -v

# 2. 빠른 회귀 (2분)
python3 -m pytest tests/ -m "not llm and not integration" --tb=short -q
```

### 예시 3: ollama_client.py 변경 후

```bash
# 1. LLM 정책 테스트 (Mock, 25초)
python3 -m pytest tests/integration/test_llm_3tier.py tests/integration/test_llm_network.py tests/integration/test_llm_timeout_tier.py --tb=short -v

# 2. 실제 LLM 호출 테스트 (15초)
OLLAMA_BASE_URL=http://192.168.0.22:11434 \
python3 -m pytest tests/test_ai_api.py --tb=short -v
```

---

## 관련 문서

| 문서 | 용도 |
|------|------|
| [test-phase-mapping.md](test-phase-mapping.md) | Phase별 테스트 생성 이력 + 소스→테스트 영향 매트릭스 |
| [test-suite-report.md](test-suite-report.md) | 기능 영역별 추천 테스트 + 부하 전략 |
| [test-tuning-guide.md](test-tuning-guide.md) | 마커/환경/부하 튜닝 가이드 |
| `docs/pytest-report/` | 1주기 요청서/결과서 저장소 |
