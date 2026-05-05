---
title: "PAB SSOT — 시스템 아키텍처 (인프라·BE·FE·DB)"
description: "Personal AI Brain v3의 Docker Compose 인프라(PostgreSQL/Qdrant/Redis/FastAPI/Ollama), 백엔드(FastAPI+SQLAlchemy ORM+Pydantic), 프론트엔드(Vanilla JS+ESM+Bootstrap), 5세대 확장(Event/Automation/Git Checkpoint) 정리"
created: 2026-05-05 05:13
updated: 2026-05-05 05:13
type: "[[RESEARCH_NOTE]]"
index: "[[ENGINEERING]]"
topics: ["[[PAB_SSOT]]", "[[ARCHITECTURE]]", "[[DOCKER_COMPOSE]]", "[[FASTAPI]]"]
tags: [research-note, pab-ssot-nexus, architecture, infrastructure, fastapi, vanilla-js]
keywords: ["Docker Compose", "FastAPI", "SQLAlchemy", "Pydantic", "PostgreSQL", "Qdrant", "Redis", "Ollama", "ESM", "Vanilla JS", "JSONL", "Heartbeat", "Watchdog", "Git Checkpoint"]
sources:
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/2-architecture.md"
aliases: ["SSOT 아키텍처", "PAB v3 인프라"]
---

# PAB SSOT — 시스템 아키텍처

## 인프라 구성 — Docker Compose 5종

```
┌──────────────────────────────────────────────────────────────┐
│                    Docker Compose (pab-network)              │
│  ┌──────────┐  ┌──────────┐  ┌───────┐  ┌────────────────┐  │
│  │PostgreSQL│  │  Qdrant  │  │ Redis │  │    Backend     │  │
│  │  :5433   │  │  :6343   │  │ :6380 │  │ FastAPI :8001  │  │
│  │ 메타데이터│  │ 벡터 검색 │  │ 캐시  │  │ API + Static   │  │
│  └──────────┘  └──────────┘  └───────┘  └────────────────┘  │
│                                               │              │
└───────────────────────────────────────────────┼──────────────┘
                                                ▼
                                  ┌──────────────────────────┐
                                  │   [[Ollama]] (호스트)     │
                                  │   :11434                  │
                                  │   host.docker.internal    │
                                  └──────────────────────────┘
```

**서빙 구조**: FastAPI가 정적 파일(`web/public/`)을 `/static`으로 서빙 + HTML 템플릿(`web/src/pages/`)을 [[Jinja2]]로 SSR. **별도 프론트엔드 빌드 없음** (빌드리스 모놀리식).

**Base URL**: `http://localhost:8001` (ver3 고정)

### 컨테이너 사양

| 컨테이너 | 이미지 | 포트 (호스트:내부) | 볼륨 |
|---|---|---|---|
| `pab-backend-ver3` | Dockerfile.backend (Python 3.12-slim) | 8001:8000 | `./:/app` (소스 마운트) |
| `pab-postgres-ver3` | postgres:15 | 5433:5432 | `postgres-data-ver3` |
| `qdrant-ver3` | qdrant/qdrant:latest | 6343:6333, 6344:6334 | `./qdrant-data-ver3` |
| `pab-redis-ver3` | redis:7-alpine | 6380:6379 | `redis-data-ver3` (AOF) |
| Ollama | ollama/ollama (호스트) | 11434 | — |

**ver3 전용 포트**(ver2와 환경 격리): PG `5432→5433`, Qdrant `6333→6343`, Redis `6379→6380`, Backend `8000→8001`.

## 백엔드 — FastAPI + SQLAlchemy ORM

### 기술 스택

| 항목 | 기준 |
|---|---|
| 언어 | Python 3.12 |
| 프레임워크 | [[FastAPI]] (async) |
| ORM | [[SQLAlchemy]] 2.0+ — **raw SQL 절대 금지** |
| DB | PostgreSQL 15 |
| 벡터 검색 | Qdrant |
| 캐싱 | Redis (AOF 지속성) |
| 스키마 검증 | [[Pydantic]] v2 |
| 타입 체크 | mypy |
| 테스트 | pytest |

### 디렉토리 구조

```
backend/
├── main.py                  # FastAPI 앱 진입점 (정적 파일 마운트, 라우터 등록)
├── config.py                # 환경변수 설정
├── models/                  # ORM 모델 (database.py, models.py, admin_models.py, workflow_common.py)
├── routers/                 # API 라우터 — 도메인별 11 묶음
│   ├── auth/  search/  ai/  knowledge/  reasoning/  cognitive/
│   ├── system/  automation/  ingest/  admin/
├── services/                # 비즈니스 로직 — 도메인별 7 묶음
├── middleware/              # 보안 헤더·Rate Limit·Request ID·전역 에러 핸들러·페이지 접근 로그·JWT/API Key 인증
└── utils/                   # logger, text_processing 등
tests/                       # pytest (conftest, test_*, integration/)
```

### 백엔드 코드 작성 규칙 (G2_be Critical)

| 규칙 | 기준 | 예시 |
|---|---|---|
| **ORM 필수** | raw SQL 절대 금지 | `session.query(Document).filter(...)` ✅ / `session.execute("SELECT ...")` ❌ |
| **타입 힌트 필수** | 모든 함수 시그니처 | `def get_doc(doc_id: int) -> Document:` |
| **Pydantic 검증** | 모든 API 입력 | `@app.post("/api/doc", response_model=DocResponse) def create(req: DocCreate):` |
| **에러 핸들링** | HTTPException 패턴 | `raise HTTPException(status_code=404, detail="Not found")` |
| **네이밍** | snake_case | `document_service.py`, `def get_document_by_id():` |
| **비동기** | async/await | `async def get_doc(): await db.execute(...)` |
| **의존성 주입** | Depends 활용 | `def route(db: Session = Depends(get_db)):` |

**금지**: raw SQL, 타입 힌트 생략, 입력 검증 없이 사용자 입력 처리, 에러 처리 없이 예외 방치.

## 프론트엔드 — Vanilla JS + ESM (빌드리스)

### 기술 스택

| 항목 | 기준 |
|---|---|
| 언어 | Vanilla JavaScript (ES2020+) |
| 모듈 | [[ESM]] (`<script type="module">`, `import`/`export`) |
| UI | [[Bootstrap]] 5 (**로컬 배치**) |
| 아이콘 | Bootstrap Icons (로컬) |
| 템플릿 | [[Jinja2]] SSR |
| 빌드 | **없음** (빌드리스 구조) |
| 테스트 | [[Playwright]] E2E |

### 프론트엔드 코드 작성 규칙 (G2_fe Critical)

| 규칙 | 기준 | 예시 |
|---|---|---|
| **ESM import/export** | `type="module"` 필수 | `<script type="module" src="/static/js/page.js">` |
| **외부 CDN 금지** | 모든 라이브러리 로컬 | `web/public/libs/`에 Bootstrap·axios 배치 |
| **XSS 방지** | innerHTML 시 esc() 필수 | `elem.innerHTML = esc(userInput)` ✅ |
| **window 전역 금지** | 새 함수 할당 금지 | `export function fn()` ✅ / `window.fn = function()` ❌ |
| **컴포넌트 재사용** | layout-component 등 활용 | `import { initLayout } from '/static/js/components/layout-component.js'` |
| **네이밍** | camelCase(변수) / kebab-case(파일) | `myVariable`, `my-page.js` |

**금지**: cdn.jsdelivr.net 등 외부 CDN 참조, innerHTML에 검증 없는 사용자 입력, window 전역 새 함수 할당(레거시 제외).

### 신규 페이지 추가 시 3개 파일 동시 생성

```
1. HTML 템플릿: web/src/pages/{페이지명}.html  (layout-component 포함)
2. JavaScript:  web/public/js/{페이지명}/{페이지명}.js
3. CSS:         web/public/css/{페이지명}.css
```

## 데이터베이스 3종

| DB | 용도 | 주의 |
|---|---|---|
| **PostgreSQL** | 문서 메타데이터·사용자·설정·로그 | **ORM 필수**, raw SQL 금지 |
| **Qdrant** | 문서 청크 벡터 임베딩·의미 검색 | 컬렉션 `document_chunks` |
| **Redis** | Rate Limit·검색 캐시·AI 작업 진행 | AOF 지속성 |

## Event Infrastructure (5세대, `5th_mode.event`)

### JSONL 이벤트 로그
모든 에이전트 활동을 [[JSONL]](JSON Lines)로 기록.

| 항목 | 내용 |
|---|---|
| 경로 | `/tmp/agent-events/{phase}.jsonl` |
| 형식 | 한 줄에 하나의 JSON 이벤트 |
| 이벤트 유형 | `state_change`, `task_start`, `task_end`, `gate_result`, `error`, `heartbeat` |
| 필수 필드 | `timestamp`, `phase`, `event_type`, `agent`, `payload` |

```json
{"timestamp":"2026-02-28T10:00:00Z","phase":"21-4","event_type":"state_change","agent":"team-lead","payload":{"from":"PLANNING","to":"PLAN_REVIEW"}}
{"timestamp":"2026-02-28T10:05:00Z","phase":"21-4","event_type":"gate_result","agent":"team-lead","payload":{"gate":"G1","result":"PASS"}}
```

### 파일 이벤트 감지

| OS | 도구 |
|---|---|
| Linux | `inotifywait -m -e close_write /tmp/agent-events/` |
| macOS | `fswatch -0 /tmp/agent-events/` |

폴링 대신 이벤트 기반 처리. 감시 대상은 `/tmp/agent-events/`(이벤트 로그)와 `/tmp/agent-messages/`(에이전트 메시지).

### Heartbeat 프로토콜
장기 실행 에이전트의 생존 모니터링:
- **주기**: 5~10분 (`{event_type: "heartbeat", state: "working", agent: "<role>"}`)
- **타임아웃**: 역할별 SLA 초과 시 비응답 판정
- **대응**: Team Lead가 SendMessage 재전송 또는 재스폰

### Watchdog SLA 표

| 단계 | SLA 타임아웃 | 에스컬레이션 |
|---|:--:|---|
| PLANNING | 10분 | 리마인드 1회 → Team Lead |
| RESEARCH | 15분 | 리마인드 1회 → Team Lead |
| VERIFYING | 12분 | 리마인드 1회 → Team Lead |
| TESTING | 15분 | 리마인드 1회 → Team Lead |
| BUILDING | Phase 가변 | Heartbeat 미수신 2회 → 재스폰 |

```
Watchdog 흐름:
[1] 에이전트 스폰 → Heartbeat 타이머 시작
[2] Heartbeat 수신 → 타이머 리셋
[3] 타임아웃 1회 → SendMessage(리마인드)
[4] 타임아웃 2회 연속 → Team Lead 에스컬레이션
[5] 판단: 재스폰 / BLOCKED 전이 / 사용자 보고
```

상세는 [[2026-05-05_pab_ssot_event_automation|이벤트·자동화 노트]] 참조.

## Automation Infrastructure (5세대, `5th_mode.automation`)

### Artifact Persister
Phase 산출물 자동 수집·보존:
- **대상**: `phase-X-Y-status.md`, `phase-X-Y-plan.md`, `todo-list.md`, `tasks/*.md`, 이벤트 로그
- **트리거**: 상태 전이 이벤트 발생 시
- **보존**: `docs/phases/phase-X-Y/artifacts/`에 타임스탬프 스냅샷

### AutoReporter
Phase 완료(DONE) 시 자동 리포트:
- 입력: 이벤트 로그 + gate_results + task_progress + error_log
- 출력: `phase-X-Y-report.md` (요약·게이트 결과·타임라인·이슈)

### DecisionEngine — 자율 판정
G2 PARTIAL(Critical 0, High 1~2건) 시 verifier가 dev에 직접 수정안 전달(Team Lead 확인 불요).

```
DecisionEngine 흐름:
VERIFYING(G2)
  ├── PASS → TESTING
  ├── PARTIAL (High만) → AUTO_FIX (자율 수정, max 3회)
  │   └── 수정 후 → VERIFYING 재검증
  │   └── 3회 초과 → Team Lead 에스컬레이션
  └── FAIL (Critical) → REWINDING → BUILDING
```

판정 이력은 `decision-log.md`에 자동 기록.

## Git Checkpoint (5세대, `5th_mode.branch`)

### 태그 네이밍

| 항목 | 내용 |
|---|---|
| 태그 형식 | `phase-{X}-{Y}-{state}` |
| 예시 | `phase-21-4-PLANNING`, `phase-21-4-BUILDING`, `phase-21-4-DONE` |
| 생성 시점 | `current_state` 전이 시 Team Lead 자동 |
| 용도 | 상태별 코드 스냅샷, REWINDING 시 정확한 복원 지점 |

### Branch 전략

| 항목 | 내용 |
|---|---|
| Phase Branch | `phase-{X}-{Y}` — Phase 시작 시 main에서 분기 |
| Merge | Phase DONE 후 main에 merge |
| **BRANCH_CREATION 상태** | TASK_SPEC 완료 후 → BRANCH_CREATION → 브랜치 생성·확인 → BUILDING |
| Lv2 리팩토링 | `phase-X-refactoring` 별도 브랜치 |

### 자동 태그 목록 (Phase 라이프사이클)

```
phase-{X}-{Y}-TEAM_SETUP
phase-{X}-{Y}-RESEARCH         (research=true)
phase-{X}-{Y}-RESEARCH_REVIEW  (research=true)
phase-{X}-{Y}-PLANNING
phase-{X}-{Y}-PLAN_REVIEW
phase-{X}-{Y}-TASK_SPEC
phase-{X}-{Y}-BRANCH_CREATION  (branch=true)
phase-{X}-{Y}-BUILDING
phase-{X}-{Y}-VERIFYING
phase-{X}-{Y}-TESTING
phase-{X}-{Y}-INTEGRATION
phase-{X}-{Y}-E2E
phase-{X}-{Y}-E2E_REPORT
phase-{X}-{Y}-DONE
```

REWINDING 시 `git checkout phase-{X}-{Y}-{target_state}`로 복원.

## 다음 노트

- [[2026-05-05_pab_ssot_intro|진입점·6세대 모듈형 로딩]] — 본 노트의 상위
- [[2026-05-05_pab_ssot_workflow|워크플로우]] — 20개 상태 + G0~G4 판정 + Phase Chain
- [[2026-05-05_pab_ssot_event_automation|이벤트·자동화]] — 4-event-protocol + 5-automation 상세
- [[PAB_SSOT_overview|MOC]]

## 참고

- `/PAB-SSOT-Nexus/docs/SSOT/docs/2-architecture.md` — 본 노트의 1차 출처
- `/PAB-SSOT-Nexus/docs/SSOT/docs/4-event-protocol.md` — 이벤트 인프라 상세 (5th)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/5-automation.md` — 자동화 파이프라인 상세 (5th)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/ROLES/backend-dev.md` — 백엔드 코드 규칙 정본
- `/PAB-SSOT-Nexus/docs/SSOT/docs/ROLES/frontend-dev.md` — 프론트엔드 코드 규칙 정본
