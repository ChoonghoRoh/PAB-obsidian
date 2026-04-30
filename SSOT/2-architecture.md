# SSOT — 아키텍처

**버전**: 7.0-renewal-5th
**최종 수정**: 2026-02-28
**특징**: 단독 사용 (다른 SSOT 폴더 참조 불필요) + 5세대 확장 (Event Infrastructure, Automation Infrastructure, Git Checkpoint)

---

## 1. 인프라 구성

### 1.1 시스템 아키텍처

```
┌──────────────────────────────────────────────────────────────┐
│                       Docker Compose                          │
│                      (pab-network)                            │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌───────┐  ┌────────────────┐  │
│  │PostgreSQL│  │  Qdrant  │  │ Redis │  │    Backend      │  │
│  │  :5433   │  │  :6343   │  │ :6380 │  │ (FastAPI) :8001 │  │
│  │          │  │          │  │       │  │                  │  │
│  │ 메타데이터│  │ 벡터 검색 │  │ 캐시  │  │ API+Static Files│  │
│  └──────────┘  └──────────┘  └───────┘  └────────────────┘  │
│                                               │               │
└───────────────────────────────────────────────┼───────────────┘
                                                │
                                    ┌───────────▼──────────┐
                                    │   Ollama (호스트)     │
                                    │   :11434              │
                                    │   host.docker.internal│
                                    └──────────────────────┘
```

**서빙 구조**: FastAPI가 정적 파일(`web/public/`)을 `/static` 경로로 서빙하고, HTML 템플릿(`web/src/pages/`)을 Jinja2로 렌더링하는 모놀리식 구조이다. 별도의 프론트엔드 빌드 프로세스는 없다.

**Base URL**: `http://localhost:8001` (ver3 고정)

---

### 1.2 컨테이너 사양

| 컨테이너 | 이미지 | 포트 (호스트:내부) | 볼륨 |
|----------|--------|-------------------|------|
| `pab-backend-ver3` | Dockerfile.backend (Python 3.12-slim) | 8001:8000 | `./:/app` (소스 마운트) |
| `pab-postgres-ver3` | postgres:15 | 5433:5432 | `postgres-data-ver3` |
| `qdrant-ver3` | qdrant/qdrant:latest | 6343:6333, 6344:6334 | `./qdrant-data-ver3` |
| `pab-redis-ver3` | redis:7-alpine | 6380:6379 | `redis-data-ver3` (AOF) |
| Ollama | ollama/ollama (호스트) | 11434 | — |

**ver3 전용 포트**:
- PostgreSQL: `5433` (ver2는 5432)
- Qdrant: `6343` (ver2는 6333)
- Redis: `6380` (ver2는 6379)
- Backend: `8001` (ver2는 8000)

**환경 격리**: ver2와 ver3가 동일 머신에서 독립 실행 가능하도록 포트와 볼륨명을 분리했다.

---

## 2. 백엔드 구조

### 2.1 기술 스택

| 항목 | 기준 |
|------|------|
| **언어** | Python 3.12 |
| **프레임워크** | FastAPI (async) |
| **ORM** | SQLAlchemy 2.0+ (ORM 필수, raw SQL 금지) |
| **DB** | PostgreSQL 15 |
| **벡터 검색** | Qdrant |
| **캐싱** | Redis (AOF 지속성) |
| **스키마 검증** | Pydantic v2 |
| **타입 체크** | mypy |
| **테스트** | pytest |

---

### 2.2 디렉토리 구조

```
backend/
├── main.py                      # FastAPI 앱 진입점 (정적 파일 마운트, 라우터 등록)
├── config.py                    # 환경변수 설정
│
├── models/                      # ORM 모델
│   ├── database.py              # SQLAlchemy 엔진, 세션
│   ├── models.py                # 핵심 ORM 모델
│   ├── admin_models.py          # Admin 설정 모델 (Phase 11) + PageAccessLog (Phase 13-4)
│   └── workflow_common.py       # 워크플로우 공통 모델
│
├── routers/                     # API 라우터 (도메인별)
│   ├── auth/auth.py
│   ├── search/{search,documents}.py
│   ├── ai/{ai,conversations}.py
│   ├── knowledge/{knowledge,labels,relations,approval,suggestions}.py
│   ├── reasoning/{reason,reason_stream,reason_store,reasoning_chain,reasoning_results,recommendations}.py
│   ├── cognitive/{memory,context,learning,personality,metacognition}.py
│   ├── system/{system,backup,integrity,logs,error_logs,statistics}.py
│   ├── automation/{automation,workflow}.py
│   ├── ingest/file_parser.py
│   └── admin/{schema_crud,template_crud,preset_crud,rag_profile_crud,policy_set_crud,audit_log_crud,page_access_log_crud}.py
│
├── services/                    # 비즈니스 로직 (도메인별)
│   ├── search/{search_service,hybrid_search,reranker,multi_hop_rag,document_sync_service}.py
│   ├── ai/{ollama_client,context_manager}.py
│   ├── knowledge/{auto_labeler,structure_matcher,knowledge_integration_service,transaction_manager,chunk_sync_service}.py
│   ├── reasoning/{dynamic_reasoning_service,reasoning_chain_service,recommendation_service}.py
│   ├── cognitive/{memory_service,context_service,learning_service,personality_service,metacognition_service,memory_scheduler}.py
│   ├── system/{system_service,integrity_service,logging_service,statistics_service}.py
│   └── ingest/{file_parser_service,hwp_parser}.py
│
├── middleware/                  # 미들웨어
│   ├── security.py              # 보안 헤더
│   ├── rate_limit.py            # Rate Limiting (slowapi, X-Forwarded-For)
│   ├── request_id.py            # Request ID 미들웨어 (UUID)
│   ├── error_handler.py         # 전역 에러 핸들러 (표준 JSON)
│   ├── page_access_log.py       # 페이지 접근 로그 (Phase 13-4)
│   └── auth.py                  # JWT/API Key 인증
│
└── utils/                       # 유틸리티
    ├── logger.py                # 로깅 설정
    ├── text_processing.py       # 텍스트 처리
    └── ...

tests/                           # 테스트 (pytest)
├── conftest.py                  # pytest 설정
├── test_*.py                    # 테스트 파일
└── integration/                 # 통합 테스트
```

---

### 2.3 백엔드 코드 작성 규칙

| 규칙 | 기준 | 예시 |
|------|------|------|
| **ORM 필수** | raw SQL 절대 금지 | `session.query(Document).filter(...)` (O), `session.execute("SELECT ...")` (X) |
| **타입 힌트 필수** | 모든 함수 시그니처 | `def get_doc(doc_id: int) -> Document:` |
| **Pydantic 검증** | 모든 API 입력 | `@app.post("/api/doc", response_model=DocResponse) def create(req: DocCreate):` |
| **에러 핸들링** | HTTPException | `raise HTTPException(status_code=404, detail="Not found")` |
| **네이밍** | snake_case | `document_service.py`, `def get_document_by_id():` |
| **비동기** | async/await 활용 | `async def get_doc(): await db.execute(...)` |
| **의존성 주입** | Depends 활용 | `def route(db: Session = Depends(get_db)):` |

**금지 사항**:
- raw SQL 쿼리
- 타입 힌트 생략
- 입력 검증 없이 사용자 입력 처리
- 에러 처리 없이 예외 방치

➜ [ROLES/backend-dev.md](ROLES/backend-dev.md)

---

## 3. 프론트엔드 구조

### 3.1 기술 스택

| 항목 | 기준 |
|------|------|
| **언어** | Vanilla JavaScript (ES2020+) |
| **모듈 시스템** | ESM (`<script type="module">`, `import`/`export`) |
| **UI 프레임워크** | Bootstrap 5 (로컬 배치) |
| **아이콘** | Bootstrap Icons (로컬 배치) |
| **템플릿** | Jinja2 (서버 사이드 렌더링) |
| **빌드 도구** | 없음 (빌드리스 구조) |
| **테스트** | Playwright (E2E) |

---

### 3.2 디렉토리 구조

(3rd와 동일한 web/ 구조 — 생략)

---

### 3.3 프론트엔드 코드 작성 규칙

| 규칙 | 기준 | 예시 |
|------|------|------|
| **ESM import/export** | `type="module"` 필수 | `<script type="module" src="/static/js/page.js">` |
| **외부 CDN 금지** | 모든 라이브러리 로컬 배치 | `web/public/libs/` 에 Bootstrap, axios 등 배치 |
| **XSS 방지** | innerHTML 시 esc() 필수 | `elem.innerHTML = esc(userInput)` (O), `elem.innerHTML = userInput` (X) |
| **window 전역 금지** | 새 함수 할당 금지 | `export function fn()` (O), `window.fn = function()` (X) |
| **컴포넌트 재사용** | `layout-component.js` 등 활용 | `import { initLayout } from '/static/js/components/layout-component.js'` |
| **네이밍** | camelCase (변수), kebab-case (파일명) | `myVariable`, `my-page.js` |
| **에러 핸들링** | try-catch + 사용자 메시지 | `try { await api() } catch(e) { alert('오류 발생') }` |

**금지 사항**:
- 외부 CDN 참조 (cdn.jsdelivr.net 등)
- innerHTML에 검증 없는 사용자 입력
- window 전역 객체에 함수 할당 (기존 레거시 제외)

➜ [ROLES/frontend-dev.md](ROLES/frontend-dev.md)

---

### 3.4 프론트엔드 파일 구조 규칙

**신규 페이지 추가 시** 반드시 아래 3개 파일을 함께 생성한다:

```
1. HTML 템플릿: web/src/pages/{페이지명}.html
2. JavaScript:   web/public/js/{페이지명}/{페이지명}.js
3. CSS:          web/public/css/{페이지명}.css
```

**HTML 템플릿 필수**: layout-component 포함, 페이지별 CSS/JS `type="module"` 링크.

---

## 4. 데이터베이스

### 4.1 PostgreSQL (메타데이터)

**용도**: 문서 메타데이터, 사용자 데이터, 설정, 로그 등. **ORM 필수**, raw SQL 금지.

### 4.2 Qdrant (벡터 검색)

**용도**: 문서 청크 벡터 임베딩 저장 및 의미 검색. 컬렉션: `document_chunks`.

### 4.3 Redis (캐싱)

**용도**: Rate Limiting, 검색 캐시, AI 작업 진행 등. AOF 지속성.

---

## 5. Event Infrastructure (5th 확장)

> **활성화 조건**: `5th_mode.event = true` 시 적용. 상세 프로토콜은 [4-event-protocol.md](4-event-protocol.md) 참조.

### 5.1 JSONL 이벤트 로그

모든 에이전트 활동은 JSONL(JSON Lines) 형식으로 이벤트 로그에 기록된다.

| 항목 | 내용 |
|------|------|
| **로그 경로** | `/tmp/agent-events/{phase}.jsonl` |
| **형식** | JSON Lines — 한 줄에 하나의 JSON 이벤트 |
| **이벤트 유형** | `state_change`, `task_start`, `task_end`, `gate_result`, `error`, `heartbeat` |
| **필수 필드** | `timestamp`, `phase`, `event_type`, `agent`, `payload` |

**이벤트 레코드 예시**:
```json
{"timestamp":"2026-02-28T10:00:00Z","phase":"21-4","event_type":"state_change","agent":"team-lead","payload":{"from":"PLANNING","to":"PLAN_REVIEW"}}
{"timestamp":"2026-02-28T10:05:00Z","phase":"21-4","event_type":"gate_result","agent":"team-lead","payload":{"gate":"G1","result":"PASS"}}
```

### 5.2 파일 이벤트 감지 (inotifywait / fswatch)

| 항목 | 내용 |
|------|------|
| **Linux** | `inotifywait -m -e close_write /tmp/agent-events/` |
| **macOS** | `fswatch -0 /tmp/agent-events/` |
| **감시 대상** | `/tmp/agent-events/` (이벤트 로그), `/tmp/agent-messages/` (에이전트 메시지) |
| **용도** | 이벤트 발생 시 실시간 반응 — 폴링 대신 이벤트 기반 처리 |

### 5.3 Heartbeat 프로토콜

장기 실행 에이전트의 생존 상태를 모니터링한다.

| 항목 | 내용 |
|------|------|
| **주기** | 5~10분 주기로 heartbeat 이벤트 기록 |
| **기록 위치** | `/tmp/agent-events/{phase}.jsonl` |
| **이벤트 유형** | `heartbeat` |
| **페이로드** | `{event_type: "heartbeat", state: "working", agent: "<role>"}` |
| **타임아웃** | 역할별 SLA 초과 시 에이전트 비응답 판정 |
| **대응** | Team Lead가 비응답 에이전트에 SendMessage 재전송 또는 재스폰 |

### 5.4 Watchdog SLA 아키텍처

Heartbeat 기반으로 에이전트 상태를 감시하고, SLA 초과 시 자동 에스컬레이션한다.

| 역할/단계 | SLA 타임아웃 | 에스컬레이션 경로 |
|-----------|:-----------:|-----------------|
| **PLANNING** | 10분 | 리마인드 (1회) → Team Lead 보고 |
| **RESEARCH** | 15분 | 리마인드 (1회) → Team Lead 보고 |
| **VERIFYING** | 12분 | 리마인드 (1회) → Team Lead 보고 |
| **TESTING** | 15분 | 리마인드 (1회) → Team Lead 보고 |
| **BUILDING** | Phase 특성에 따라 가변 | Heartbeat 미수신 2회 연속 → 재스폰 |

```
Watchdog 흐름:
  [1] 에이전트 스폰 → Heartbeat 타이머 시작
  [2] Heartbeat 수신 → 타이머 리셋
  [3] 타임아웃 1회 → SendMessage(리마인드)
  [4] 타임아웃 2회 연속 → Team Lead에 에스컬레이션 (비응답 에이전트 보고)
  [5] Team Lead 판단: 재스폰 / BLOCKED 전이 / 사용자 보고
```

---

## 6. Automation Infrastructure (5th 확장)

> **활성화 조건**: `5th_mode.automation = true` 시 적용. 상세 파이프라인은 [5-automation.md](5-automation.md) 참조.

### 6.1 Artifact Persister

Phase 산출물을 자동으로 수집·보존하는 메커니즘.

| 항목 | 내용 |
|------|------|
| **대상** | `phase-X-Y-status.md`, `phase-X-Y-plan.md`, `phase-X-Y-todo-list.md`, `tasks/*.md`, 이벤트 로그 |
| **트리거** | 상태 전이 이벤트 발생 시 자동 실행 |
| **보존 경로** | `docs/phases/phase-X-Y/artifacts/` |
| **동작** | 상태 전이마다 현재 산출물 스냅샷을 artifacts/ 에 타임스탬프 기록 |

### 6.2 AutoReporter

Phase 완료 시 자동 리포트 생성.

| 항목 | 내용 |
|------|------|
| **트리거** | `DONE` 상태 전이 시 |
| **입력** | 이벤트 로그, gate_results, task_progress, error_log |
| **출력** | Phase 완료 리포트 (요약, 게이트 결과, 타임라인, 이슈 목록) |
| **형식** | Markdown 문서 (`phase-X-Y-report.md`) |

### 6.3 DecisionEngine (자율 판정)

반복적 수정 판정을 자동화하여 Team Lead 개입을 최소화한다.

| 항목 | 내용 |
|------|------|
| **적용 조건** | G2 판정 결과 PARTIAL (Critical 0, High 1~2건) |
| **동작** | verifier가 dev에 직접 수정안 전달 (Team Lead 확인 불요) |
| **AUTO_FIX 루프** | 자동 수정 최대 3회 재시도 → VERIFYING 재검증 |
| **에스컬레이션** | 3회 초과 시 Team Lead에게 에스컬레이션 |
| **기록** | 판정 이력을 `decision-log.md`에 자동 기록 |

```
DecisionEngine 흐름:
  VERIFYING(G2)
    ├── PASS → TESTING
    ├── PARTIAL (High만) → AUTO_FIX (자율 수정, max 3회)
    │   └── 수정 후 → VERIFYING (재검증)
    │   └── 3회 초과 → Team Lead 에스컬레이션
    └── FAIL (Critical) → REWINDING → BUILDING
```

➜ [상세: 5-automation.md](5-automation.md)

---

## 7. Git Checkpoint (5th 확장)

> **활성화 조건**: `5th_mode.branch = true` 시 적용.

### 7.1 태그 네이밍 규칙

상태 전이마다 Git 태그를 생성하여 체크포인트를 남긴다.

| 항목 | 내용 |
|------|------|
| **태그 형식** | `phase-{X}-{Y}-{state}` |
| **예시** | `phase-21-4-PLANNING`, `phase-21-4-BUILDING`, `phase-21-4-DONE` |
| **생성 시점** | `current_state` 전이 시 Team Lead가 자동 생성 |
| **용도** | 상태별 코드 스냅샷 보존, REWINDING 시 정확한 복원 지점 |

### 7.2 Branch 전략

| 항목 | 내용 |
|------|------|
| **Phase Branch** | `phase-{X}-{Y}` — Phase 시작 시 main에서 분기 |
| **Merge** | Phase DONE 후 main에 merge |
| **BRANCH_CREATION 상태** | TASK_SPEC 완료 후 → BRANCH_CREATION → 브랜치 생성·확인 → BUILDING |
| **Lv2 리팩토링** | `phase-X-refactoring` 별도 브랜치 (기존 §10.5 규칙 유지) |

### 7.3 상태 전이 시 자동 태그

```
상태 전이 발생 (예: PLANNING → PLAN_REVIEW)
  │
  ▼
[1] Team Lead: git tag phase-{X}-{Y}-{state} 생성
  │   예: git tag phase-21-4-PLAN_REVIEW
  │
  ▼
[2] 이벤트 로그에 tag_created 이벤트 기록 (5th_mode.event = true 시)
  │
  ▼
[3] REWINDING 시: git checkout phase-{X}-{Y}-{target_state} 로 복원
```

**자동 태그 목록** (Phase 라이프사이클 전체):
```
phase-{X}-{Y}-TEAM_SETUP
phase-{X}-{Y}-RESEARCH         (5th_mode.research = true 시)
phase-{X}-{Y}-RESEARCH_REVIEW  (5th_mode.research = true 시)
phase-{X}-{Y}-PLANNING
phase-{X}-{Y}-PLAN_REVIEW
phase-{X}-{Y}-TASK_SPEC
phase-{X}-{Y}-BRANCH_CREATION  (5th_mode.branch = true 시)
phase-{X}-{Y}-BUILDING
phase-{X}-{Y}-VERIFYING
phase-{X}-{Y}-TESTING
phase-{X}-{Y}-INTEGRATION
phase-{X}-{Y}-E2E
phase-{X}-{Y}-E2E_REPORT
phase-{X}-{Y}-DONE
```

---

## 8. 참조 문서

| 문서 | 용도 | 경로 |
|------|------|------|
| Backend Charter | Backend Developer 역할 | [PERSONA/BACKEND.md](PERSONA/BACKEND.md) |
| Frontend Charter | Frontend Developer 역할 | [PERSONA/FRONTEND.md](PERSONA/FRONTEND.md) |
| Backend 가이드 | Backend 전용 가이드 | [ROLES/backend-dev.md](ROLES/backend-dev.md) |
| Frontend 가이드 | Frontend 전용 가이드 | [ROLES/frontend-dev.md](ROLES/frontend-dev.md) |
| Event Protocol | 이벤트 인프라 프로토콜 | [4-event-protocol.md](4-event-protocol.md) ← **5th 신규** |
| Automation | 자동화 파이프라인 | [5-automation.md](5-automation.md) ← **5th 신규** |

---

**문서 관리**:
- 버전: 7.0-renewal-5th (5th iteration)
- 최종 수정: 2026-02-28
- 단독 사용: 본 iterations/5th 세트만으로 SSOT 완결
- 4th 콘텐츠 전량 보존
- 5th 확장: Event Infrastructure (§5, JSONL 이벤트 로그 + Heartbeat + Watchdog SLA), Automation Infrastructure (§6, Artifact Persister + AutoReporter + DecisionEngine), Git Checkpoint (§7, Branch-first + 상태 전이 자동 태그)
