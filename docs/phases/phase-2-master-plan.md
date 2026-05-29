---
phase: "2"
title: "PAB-LLMDATA 셀프호스팅 클라우드 활용 (동기화 + RAG/MCP + LLM 자동화)"
type: master-plan
created: 2026-05-29
ssot_version: 8.0-renewal-6th
initiator: user
prompt_quality: pass
pre_draft_ref: docs/phases/phase-2-pre-analysis.md
exceptions_ref: docs/phases/phase-2-exceptions.md
exceptions: [E-1, E-2, E-3, E-4]
sub_phases: [2-1, 2-2, 2-3, 2-4]
status: DRAFT
notify_prefix: "[PAB-LLMDATA]"
---

# Phase 2 — PAB-LLMDATA 셀프호스팅 클라우드 활용 (Master Plan)

## §0 요약

`PAB-LLMDATA` Obsidian 볼트(64 md, ~640K, Karpathy LLM Wiki 패턴)를 **이미 보유한 인프라(3800X 서버 · 듀얼 RTX 3090 · Tailscale 사설망)** 위에서 "클라우드"로 활용한다. 신규 유료 구독·외부 LLM API 없이 3가지 목표를 모두 충족한다:

1. **다기기 동기화/백업** — PC/MacBook/ThinkBook/모바일 실시간 동기화 + GitHub 오프사이트 백업
2. **쿼리 가능한 RAG/지식베이스** — 볼트를 stateless MCP 서버로 노출, 로컬 LLM·PAB 에이전트가 쿼리
3. **로컬 LLM 자동화** — `/pab:wiki` + Conductor job + 로컬 vLLM으로 무인 노트 수집·합성

**핵심 제약 (사용자 노트 도출 설계 철학 — 절대 준수)**: PAB = Personal AI Brain. 데이터 주권 + 비용 통제. **모든 자동화 추론은 로컬(3800X)**, 엔터프라이즈 API(GPT/Claude/Gemini) 금지. 전 서비스 Tailscale 사설망 내 — 공개 노출 0.

본 Phase는 **4 sub-phase**로 분할되며 AutoCycle handoff로 다음 sub-phase에 자동 진입한다.

## §1 보유 인프라 ("이 프로젝트의 클라우드")

| 자원 | 내용 |
|---|---|
| **3800X 서버** | Ubuntu 22.04, 2×RTX 3090(24GB), Tailscale `100.109.251.86`. Ollama(`:11434`), vLLM Qwen3.6-27B(`:8000`, ~225 tok/s), nginx LB, Docker |
| **PAB 생태계** | Conductor(작업 큐), Khala(앙상블 FastAPI), SSOT-Nexus(Next.js `:3100`), Reader(md 뷰어 `:8070`) — 전부 `deploy.sh`(rsync+ssh+docker compose) 배포 |
| **클라이언트** | PC(WSL2)/MacBook/ThinkBook/모바일 (전부 Tailscale 가입 가능) |
| **백업·알림** | GitHub(`ChoonghoRoh/PAB-obsidian`), Telegram 봇 |

**신규 docker-compose 스택 `pab-vault-cloud`** 하나(couchdb + qdrant + pab-kb-mcp)를 기존 `deploy.sh` 패턴으로 배포 → 3목표 충족.

## §2 SSOT 적용 범위

본 Phase는 [phase-2-exceptions.md](phase-2-exceptions.md)의 4건 예외(E-1~E-4)를 적용한다. **SSOT 본체 무수정**.

| 적용 SSOT 규칙 | HR-1, HR-2, HR-3, HR-4, HR-6, HR-7, HR-8(prefix `[PAB-LLMDATA]`), G0, G1, G2_infra(신설), G4, FRESH-1~12, ENTRY-1~5, AutoCycle handoff, CHAIN-5/6/10/11/13 |
| 비적용/대체 | G2_be/G2_fe → **G2_infra**(E-1, 인프라·배포 검증 게이트) / HR-5 500줄(E-2, 인프라 설정파일 비대상) / G3 pytest → **G3_smoke**(E-3, 서비스 헬스체크·E2E) / 외부 API 추론(E-4, 영구 금지) |

## §3 KPI

| KPI | 목표 | 측정 |
|---|---|---|
| LiveSync 동기화 | 폰(Tailscale) 편집 → PC 수초 반영 | Phase 2-1 |
| per-machine 제외 | `workspace*.json`/`graph.json` 미동기화 | Phase 2-1 |
| GitHub 백업 | 자동 커밋·푸시 도달 | Phase 2-1 |
| MCP 서버 응답 | stateless `search()` → 관련 노트+frontmatter 반환 | Phase 2-2 |
| 인덱싱 | 64파일 임베딩 → Qdrant upsert, 재인덱싱 <1s | Phase 2-2 |
| Claude Code MCP 연결 | `.mcp.json`으로 볼트 쿼리 동작 | Phase 2-2 |
| 자동 ingest | URL 트리거 → 노트 쌍 생성 → 동기화 → 인덱싱 | Phase 2-3 |
| 로컬 추론 검증 | 합성이 vLLM(로컬)으로만, 외부 API 호출 0 | Phase 2-3 |
| broken link | link-check violations=0 (자동 게이트) | Phase 2-3, 2-4 |
| 데이터 주권 | 전 서비스 Tailnet 전용, 공개 포트 0 | Phase 2-4 |

## §4 Sub-Phase 분할

### Phase 2-1: 다기기 동기화 + 백업 인프라 [INFRA]

**목표**: Self-hosted Obsidian LiveSync(CouchDB Docker)를 3800X에 배포하고 전 기기 실시간 동기화 + GitHub 오프사이트 백업 역할 분리를 확립한다.

**도구 결정**: obsidian-livesync + CouchDB **채택** (Syncthing·git-autocommit 대비 — 실시간·모바일 네이티브·Markdown 충돌 처리·Obsidian Sync $4/월 정확 대체·셀프호스팅).

**Tasks**:
- T-1: `pab-vault-cloud/docker-compose.yml`에 CouchDB 서비스 정의 (`:5984`, CORS 허용, `require_valid_user=true`, Tailnet 바인딩)
- T-2: `deploy.sh`에 `pab-vault-cloud` 타겟 추가 (rsync+ssh+`docker compose up -d`) → 3800X 배포
- T-3: 전 기기(PC/Mac/ThinkBook) Obsidian + Self-hosted LiveSync 플러그인 설치·설정 → `http://100.109.251.86:5984/pab-llmdata`
- T-4: 모바일 경로 — 폰 Tailscale 가입 + Obsidian 모바일 + LiveSync 플러그인 연동 검증
- T-5: LiveSync 제외 정책을 `.gitignore`와 일치(`workspace*.json`, `graph.json`, `cache`, `community-plugins.json` 등 per-machine 비동기화)
- T-6: 백업 경로 확정 — 데스크톱 git-authority(권장) 또는 서버 CouchDB→git 미러 cron [결정 포인트 1]

**산출물**: `pab-vault-cloud/docker-compose.yml`(couchdb), `deploy.sh` 타겟, LiveSync 설정 가이드, 동기화 검증 보고서

**G2_infra**: CouchDB 헬스 OK, 2+ 기기 양방향 동기화 확인, per-machine 파일 미동기화 확인

**소요 추정**: 6 task / 60~120분

---

### Phase 2-2: 쿼리 가능한 RAG / MCP 지식베이스 [INFRA] [CLI]

**목표**: 볼트를 **stateless MCP 서버(`pab-kb-mcp`)**로 노출하여 로컬 LLM·PAB 에이전트·Claude Code가 쿼리할 수 있게 한다. 사용자의 2026-07-28 MCP 스펙 노트 + "1차 강제 검색 + 조건부 위임" 전략 반영.

**도구 결정**: 임베딩 **bge-m3(Ollama)** (한/영 혼용 → 다국어 dense+sparse) · 벡터스토어 **Qdrant Docker(`:6333`)** (또는 SQLite-vec — [결정 포인트 2]) · MCP는 **stateless FastAPI**(`initialize` 핸드셰이크·세션ID 없음 → nginx 라운드로빈, JSON Schema 2020-12, Sampling 미사용).

**Tasks**:
- T-1: `pab-vault-cloud/docker-compose.yml`에 Qdrant + pab-kb-mcp 서비스 추가
- T-2: `pab-kb-mcp` 인덱서 — 볼트 순회 → frontmatter 파싱(`_schema.json` 기준) → H2 섹션 청킹 → bge-m3 임베딩 → Qdrant upsert (mtime/git-hash 증분)
- T-3: MCP 도구 3종 구현 — `search(query,k)`(BM25/FTS+dense RRF 융합, frontmatter 반환), `get_note(path)`, `list_notes(type=,domain=)`
- T-4: stateless MCP 엔드포인트(`POST /mcp`, `_meta` 자체완결) + nginx LB upstream(`:8090`, 세션고정 없음) 추가
- T-5: `ollama pull bge-m3` + 64파일 초기 인덱싱 + `POST /reindex` 엔드포인트
- T-6: Claude Code `.mcp.json` 연결(`http://100.109.251.86:8090/mcp`) + 쿼리 smoke test

**산출물**: `pab-kb-mcp/`(MCP 서버·인덱서), docker-compose(qdrant+mcp), nginx upstream, `.mcp.json` 설정

**G2_infra**: stateless 호출(세션ID 없이) 정상, `search`가 관련 노트+frontmatter 반환, 추론은 `/v1/` 유지(MCP는 검색만)

**소요 추정**: 6 task / 120~180분

> **사전 검토 (T-1 전)**: 64파일에 벡터DB는 순수 검색 기준 과하나(ripgrep/SQLite-FTS로도 충분), 사용자 노트가 이미 "MCP search 도구 분리"를 채택 → **MCP 계약을 우선 구축하고 백엔드 엔진은 교체 가능하게** 둔다. v1은 SQLite-vec로 컨테이너 1개 절약 가능.

---

### Phase 2-3: 로컬 LLM 자동화 (auto-ingest) [CLI]

**목표**: `/pab:wiki` + Conductor job + **로컬 vLLM Qwen3.6-27B**로 URL/소스를 무인 수집·합성하고, 동기화·인덱싱·알림까지 자동화한다. (데이터 주권: 무인 추론 전부 로컬)

**파이프라인**: 트리거(Telegram `/ingest <url>` / cron / Conductor enqueue) → 워커가 WebFetch→SOURCE(불변) + 합성(vLLM) → link-check 게이트 → git commit/push + LiveSync 전파 → `POST /reindex` → Telegram 알림.

**자동화 추론 결정 [결정 포인트 3]**: **하이브리드 권장** — 대화형 `/pab:wiki`는 Claude Code 유지, 무인 자동화만 스킬 §3 절차를 vLLM `/v1/chat/completions`로 포팅. (완전 로컬 시 grammar-constrained 출력 + KV `q4_1` + schema 재시도 투자 필요)

**Tasks**:
- T-1: **[사전조건]** `scripts/wiki/wiki.py`(Makefile 참조하나 repo 부재) + `report_to_telegram.sh`(SSOT-Nexus 소속) 위치 확인 또는 신규 구현
- T-2: `/pab:wiki` §3 절차의 헤드리스/로컬-LLM 포팅 (TYPE/DOMAIN 분류·요약·TOC 생성 → vLLM 호출)
- T-3: PAB-Conductor `wiki-ingest` 태스크 타입 등록 + 워커 실행 로직 (기존 큐/워커/하트비트 재사용)
- T-4: 검증 게이트 — `wiki link-check` violations=0 시에만 자동커밋, 아니면 Telegram 수동검토 알림. SOURCE 불변성(`15_Sources/*` 재페치 금지) 준수
- T-5: reindex 훅 + Telegram 트리거(`/ingest <url>`) + cron 다이제스트 옵션
- T-6: 로컬 추론 검증 — 합성 전 과정 로그에서 외부 API 호출 0 확인

**산출물**: 헤드리스 `/pab:wiki` 경로, Conductor `wiki-ingest` job, 검증 게이트, Telegram 트리거

**G2_infra + G3_smoke**: URL→노트쌍 E2E 동작, link-check=0, 외부 API 호출 0

**소요 추정**: 6 task / 120~180분

---

### Phase 2-4: 통합 검증 + 운영 가이드 [INFRA] [VERIFY]

**목표**: 3계층 E2E 통합 검증, 데이터 주권(공개 노출 0) 확인, 운영 가이드·최종 보고서 작성.

**Tasks**:
- T-1: L1 검증 — 폰 편집→PC 반영, per-machine 미동기화, GitHub 백업 도달
- T-2: L3 검증 — stateless `search` 호출, Claude Code MCP 쿼리, nginx 라운드로빈
- T-3: L2 검증 — `/ingest` E2E, 로컬 추론 전용, link-check=0
- T-4: 보안 검증 — 전 서비스 Tailnet 전용 바인딩·공개 포트 0 (`ss -tlnp` 확인)
- T-5: `PAB-LLMDATA/00_MOC/`에 운영 가이드 노트 작성 (3계층 사용법, 트러블슈팅)
- T-6: `docs/phases/phase-2-final-summary-report.md` + NOTIFY-1 발송(`[PAB-LLMDATA] ✅ Phase 2 완료`)

**산출물**: 통합 검증 보고서, 운영 가이드 노트, master-final-report

**G2_infra + G3_smoke**: 전 계층 PASS, 공개 노출 0

**소요 추정**: 6 task / 90~150분

---

## §5 Sub-Phase 의존 관계

```
2-1 (동기화 인프라: CouchDB LiveSync + 백업)
   ↓
2-2 (RAG/MCP: Qdrant + bge-m3 + pab-kb-mcp)  ── reindex 엔드포인트 제공
   ↓
2-3 (LLM 자동화: Conductor wiki-ingest + 로컬 vLLM)  ── 2-1 동기화 타겟 + 2-2 reindex 의존
   ↓
2-4 (통합 검증 + 운영 가이드)
```

각 sub-phase 완료 시 NOTIFY-1(`[PAB-LLMDATA]` prefix) 발송 → 다음 sub-phase status.md 진입.

## §6 G2_infra 통합 판정 기준 (E-1 신설 게이트)

| 등급 | 조건 |
|---|---|
| **Critical (FAIL)** | 서비스 헬스체크 실패 / 데이터 동기화·쿼리 미동작 / **외부 LLM API 호출 발생**(E-4 위반) / 공개 인터넷 노출 |
| **High (PARTIAL)** | per-machine 파일 동기화 누수 / link-check violations>0 자동커밋 / 증분 인덱싱 미동작 |
| **Low (PASS 가능)** | 로그·메트릭 미흡 / 컨테이너 재시작 정책 미설정 |

**판정**: Critical 1건+ → FAIL(수정 후 재검증) / Critical 0·High 있음 → PARTIAL(Team Lead 판단) / Critical 0·High 0 → PASS

## §7 리스크 + 완화

| # | 리스크 | 완화 |
|---|---|---|
| R-1 | CouchDB↔git 이중 쓰기 충돌 | 자동화 쓰기는 LiveSync 피어 기기 경유(파일→LiveSync→git authority 커밋), 쓰기 경로 단일화 |
| R-2 | `.obsidian/workspace.json` 동기화 churn | `.gitignore`와 동일 per-machine 제외 정책(Phase 2-1 T-5) |
| R-3 | 약한 모델 frontmatter/TOC 오류 | link-check 게이트 + schema 재시도, violations>0 자동커밋 금지(Telegram 수동검토) |
| R-4 | SOURCE 불변성 위반 | 기존 `15_Sources/*_source.md` 재페치/덮어쓰기 금지(Phase 2-3 T-4) |
| R-5 | **`wiki.py`·telegram 스크립트 repo 부재** | Phase 2-3 T-1 사전조건 — 위치 확인 또는 신규 구현 후 착수 |
| R-6 | 임베딩 모델 드리프트 | Qdrant 컬렉션에 모델명 태깅, 모델 교체 시 full reindex(64파일 = 자명) |
| R-7 | MCP 아직 RC(최종 2026-07-28) | stateless RC로 구현, Sampling/Roots/Logging 회피, 12개월 deprecation 정책 보호 |

## §8 결정 포인트 (사용자 선택)

| # | 항목 | 옵션 | 권장 |
|---|---|---|---|
| DP-1 | 백업 작성자 | 데스크톱 git-authority vs 서버 CouchDB→git 미러 cron | 데스크톱(단순) |
| DP-2 | 벡터 엔진 | Qdrant 컨테이너 vs SQLite-vec | Qdrant(미래대비·패턴부합) |
| DP-3 | 자동화 추론 | 하이브리드(대화형 Claude Code + 무인 로컬) vs 완전 로컬 | 하이브리드 |
| DP-4 | CouchDB 노출 | raw `:5984`(Tailscale) vs nginx TLS | raw 우선 |

## §9 Handoff 체인 (AutoCycle)

각 sub-phase 종료 시 `phase-2-X-status.md`의 `next_prompt_suggestion`에 다음 진입 명령 자동 기재. CHAIN-13(직전 3 Phase 기억) 자동 로딩.

### Phase 2-1 진입 (handoff #0)

```
Phase 2-1을 시작한다.
1. 0-entrypoint.md 리로드 (FRESH-1)
2. docs/phases/phase-2-1/phase-2-1-status.md 읽기 (ENTRY-1)
3. phase-2-master-plan.md, phase-2-exceptions.md 컨텍스트 로드
4. current_state: IDLE → TEAM_SETUP 전이
5. backend-dev(인프라/배포) + verifier 스폰 (tester 비스폰 — E-3 smoke로 대체)
6. tasks/ 의 task를 backend-dev에게 할당, 검증은 verifier에게 위임(HR-6)
7. 사용자 액션 필요 항목(기기별 LiveSync 플러그인 설치 등)은 안내
```

## §10 산출물 요약 (Phase 2 전체)

| 카테고리 | 파일/디렉터리 |
|---|---|
| Phase 문서 | `phase-2-master-plan.md`(본 문서), `phase-2-exceptions.md`, `phase-2-pre-analysis.md`, `phase-2-final-summary-report.md` |
| Sub-phase 산출물 | `docs/phases/phase-2-1/`~`phase-2-4/` 각 4종(status/plan/todo-list/tasks) |
| 인프라 | `pab-vault-cloud/docker-compose.yml`(couchdb+qdrant+pab-kb-mcp), `deploy.sh` 타겟, nginx upstream |
| MCP 서버 | `pab-kb-mcp/`(인덱서+stateless MCP 도구 3종) |
| 자동화 | 헤드리스 `/pab:wiki` 경로, Conductor `wiki-ingest` job, reindex 훅, Telegram 트리거 |
| 운영 | `PAB-LLMDATA/00_MOC/` 운영 가이드 노트, `.mcp.json` 설정 |

## §11 종료 조건 (Phase 2 DONE)

- [ ] Phase 2-1 ~ 2-4 모두 DONE
- [ ] G2_infra + G3_smoke 전 계층 PASS
- [ ] 3목표 검증: 다기기 동기화 / MCP 쿼리 / 로컬 자동 ingest
- [ ] 외부 LLM API 호출 0 (데이터 주권)
- [ ] 전 서비스 Tailnet 전용, 공개 노출 0
- [ ] master-final-report 작성
- [ ] `[PAB-LLMDATA]` 텔레그램 알림 발송 (각 sub-phase + 최종)
- [ ] `phase-2-exceptions.md` status: ARCHIVED 전이

---

**작성**: Team Lead (메인 세션) | **승인**: 대기(사용자) | **다음 단계**: 사용자 승인 → `phase-2-exceptions.md` + `phase-2-pre-analysis.md` 작성 → Phase 2-1 entry artifacts 생성 → handoff
