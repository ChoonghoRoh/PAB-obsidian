---
title: "PAB-Khala PAB-v4 Brain 연동 보고서 (원문)"
description: "PAB-Khala 저장소 원본 문서 immutable 보존 — docs/analysis/20260629-pab-v4-brain-khala-integration-report.md"
created: 2026-06-30 07:58
updated: 2026-06-30 07:58
type: "[[SOURCE]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[PAB_V4]]"]
tags: ["source", "khala", "phase6"]
keywords: ["khala", "pab-v4", "brain", "카테고리", "mcp", "lv0", "resumable", "lineage", "조회생성분리", "gpu정책"]
sources: ["docs/analysis/20260629-pab-v4-brain-khala-integration-report.md"]
aliases: ["pab-v4연동보고서", "brain연동"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층). 원본 위치: `PAB-Khala/docs/analysis/20260629-pab-v4-brain-khala-integration-report.md`

# PAB-v4 Brain 카테고리 연결 ⨉ Khala(Lineage / Resumable Tools) 연동 분석 보고서

> 작성 2026-06-29 · 분석 기준: 3800x 배포 소스(`personal-ai-brain-v4`) + Khala v0.2(`:8765`)
> 라이브: PAB-v4 `http://100.109.251.86:8001` · Khala `http://100.109.251.86:8765`
> 선행: [Lineage 가이드](../guides/khala-lineage-api-guide.md) · [Resumable Tools 가이드](../guides/khala-resumable-tools-api-guide.md) · [A⊕B 설계](../design/20260628-context-continuation-and-call-lineage-design.md)

---

## 0. 한 줄 결론

PAB-v4가 설계 중인 **brain 카테고리 연결(`pab-lv0` MCP / `/ext/lv0/v1` REST)** 과 **Khala의 Lineage·Resumable Tools는 서로 다른 층**이다.
- **조회 층**(LV0 결정적 데이터 노출)에 Khala를 끼우면 **안 된다** — LV0은 confidence 1.0 결정적 응답이 가치인데, LLM 게이트웨이를 거치면 그 보증이 깨진다.
- 반면 PAB-v4의 **생성·배치 층**(자동 라벨링·run-full 워크플로·reasoning)은 현재 진행률이 **메모리 전용(서버 재시작 시 소실)** 이고 무재개라, 여기에 **Khala Resumable Tools(workspace.md 영속) + Lineage(체인 추적)** 를 붙이면 직접 이득이 크다.
- **단, 단일 24GB GPU의 vLLM↔Ollama mutex** 때문에 "PAB-v4 Ollama 직접 호출"과 "Khala vLLM 경유"는 동시 점유 불가다. 이 자원 충돌을 먼저 정책으로 정리하지 않으면 연동은 운영에서 깨진다(§5).

---

## 1. 양 시스템 현재 상태 (실측)

### 1.1 PAB-v4 측 — 무엇이 있고 무엇이 설계뿐인가

| 구성 | 상태 | 근거(파일) |
|---|---|---|
| Brain 모델 (`brains`, `brain_documents` M:N) | ✅ 구현·배포 | `backend/models/brain.py:13-48` |
| Brain CRUD API (`/api/brains`, `/{id}/documents`) | ✅ 구현·배포 | `backend/routers/knowledge/brain.py:109-280` |
| 카테고리 = Label 체계(`index`/`type`/`topics` + `labels.label_type`) | ✅ 운영(라벨 185) | `backend/models/models.py:93-116` |
| **`pab-lv0` MCP 명세**(6 tools) | 📝 **설계 완성·구현 0%** | `docs/overview/260627-PAB-v4-LV0-조회API-MCP-명세.md` |
| **`/ext/lv0/v1` REST**(6 endpoint, `X-PAB-Key`) | 📝 **설계 완성·구현 0%** | 동 §4 |
| LLM 호출(자동 라벨링/추천/reasoning) | ✅ 구현 — **Ollama 직접** | `backend/services/ai/ollama_client.py` |
| run-full 배치 워크플로(백그라운드+SSE) | ⚠️ 구현·**진행률 메모리 전용** | `backend/routers/automation/automation.py:206-274` |
| 배치 task state(`active_tasks` dict) | ⚠️ **DB 비영속·재개 불가** | `backend/services/automation/ai_workflow_state.py:15-150` |

핵심 분리(설계 SSOT `260624-LV0-Brain-수동큐레이션-설계.md`):
- **Brain = 사용자가 LV0 문서를 수동 배정한 묶음**(자동 분류 아님). 카테고리는 "필터·제안"일 뿐.
- **`pab-lv0` = 저자 작성 메타데이터(LV0)만 노출** → 모든 응답 `level:"LV0"`, `source:"author"`, `confidence:1.0`. AI 산출물 0.

### 1.2 Khala 측 — 무엇을 제공하나

| 기능 | 엔드포인트 | 보장 |
|---|---|---|
| Resumable Tools | `POST /v1/tools/run` (`workflow_id`/`resume`) | `workspace.md` NVMe 영속 + `max_iter` 도달 시 `resumable=true`로 이어받기 |
| 서버측 자동저장(A2) | `tool_loop_openai.on_finalize_workspace` | 모델이 `workspace_write`를 안 불러도 워크스페이스 영속(무손실 입증, Phase 5 KPI 6/6) |
| Lineage(B) | `GET /v1/tools/lineage/{wid}` + `_runs.jsonl`/`_index.jsonl` | 서버가 `seq`/`parent_request_id`/`resume_valid` 부여·검증, append-only 이력 |
| caller 화이트리스트 | `auth.py` | `conductor:*`/`ssot:*`/`obsidian:*`/`khala-self:*`/`manual:*` |

확인된 라이브 상태(2026-06-29): vLLM `off`, Ollama `idle_empty`, 모델 `qwen3.6-27b-autoround`(max_len 24,576). 즉 **현재 GPU는 Ollama 쪽 idle**, Khala vLLM은 내려가 있음.

---

## 2. 연동을 두 축으로 분리한다 (가장 중요한 판단)

### 축 ① 조회 층 — Khala를 **끼우지 않는다** (권고)

`pab-lv0`/`/ext/lv0/v1`은 "결정적·신뢰도 ★★★ 데이터 노출"이 존재 이유다. 이 경로에 Khala(LLM 생성 게이트웨이)를 넣으면:
- confidence 1.0 보증이 LLM 추론으로 오염됨(설계 원칙 위반).
- 응답이 stateless 단순 조회라 resumable/lineage가 줄 이득이 0(수 ms~수십 ms, max_iter 무관).

→ **결론: `pab-lv0` MCP·REST는 PAB-v4 자체 FastAPI로 구현한다. Khala는 호출 경로에 없다.**
다만 *외부 LLM 클라이언트(Claude/Conductor 등)가 pab-lv0 MCP로 brain을 조회한 뒤, 그 결과로 긴 생성 작업을 Khala에 위임*하는 **상위 오케스트레이션**은 성립한다(축 ②로 연결).

### 축 ② 생성·배치 층 — Khala Resumable + Lineage로 **교체/보강** (핵심 이득)

PAB-v4의 약점은 정확히 Khala가 푼 문제와 일치한다:

| PAB-v4 현재(automation.py / ai_workflow_state.py) | Khala가 제공 |
|---|---|
| `_execute_workflow_background`가 메모리 `TaskState`에 단계 기록 | `workspace.md` NVMe 영속(서버 재시작·OOM 후에도 잔존) |
| 서버 재시작 시 진행 전부 소실, **재개 수단 없음** | 같은 `workflow_id`+`resume=true`로 직전 상태에서 이어감 |
| 진행률 추적만(`stages[]`), 부모/순번/감사 없음 | `_runs.jsonl` 체인 = seq·parent·status·workspace_size 불변 이력 |
| 단일 서버 전제, 분산·재시도 미지원 | append-only lineage로 "어느 단계까지 갔나" 서버가 판정 |

---

## 3. 구체 연동 설계 (축 ② 3개 후보)

### 후보 A — run-full 워크플로 → Khala resumable (★ 최우선)

**부착점:** `backend/routers/automation/automation.py:206-226` `_execute_workflow_background`.

현재:
```python
def _execute_workflow_background(task_id):
    workflow_service.execute_workflow(task_id, db)   # 메모리 진행률, 재개 불가
```

연동 후(개념):
```python
def _execute_workflow_background(task_id):
    wid = f"pab-runfull-{task_id}"                    # PAB task_id ↔ Khala workflow_id 1:1
    resume = False
    while True:
        r = khala_tools_run(
            prompt="문서 N건 ingest: 청크→라벨→임베딩→검증. 매 단계 workspace_write.",
            tools=["workspace_read","workspace_write","save_file"],
            model="qwen3.6-27b-autoround",
            workflow_id=wid, resume=resume, max_iter=6,
            metadata={"caller":"pab:automation", "request_id":f"{task_id}#{seq}"},
        )
        ai_workflow_state.update_progress(task_id, ...)   # Khala 응답 → 기존 SSE로 중계
        if not r["resumable"]: break
        resume = True                                      # auto-resume loop
```

이득:
- **무손실**: A2 서버측 자동저장으로 모델이 도구를 빼먹어도 워크스페이스 영속.
- **재개**: PAB 서버가 죽어도 Khala `workspace.md`가 NVMe에 남아 다음 호출이 이어감.
- **감사**: `GET /v1/tools/lineage/pab-runfull-{task_id}`가 단계 체인을 그대로 복원 → PAB의 휘발성 `stages[]`를 영속 대체.

**매핑 표:**

| PAB-v4 개념 | Khala 개념 |
|---|---|
| `task_id`(uuid) | `workflow_id` (`pab-runfull-<task_id>`) |
| `TaskState.stages[]` | `_runs.jsonl` 체인(seq별) |
| stage 진행률(SSE) | 각 호출 응답 + `workspace_size` 증가분 |
| 재시작 후 복구(현재 불가) | `resume=true` 재호출 |

### 후보 B — batch-auto-label → Khala (문서별 sub-chain)

**부착점:** `automation.py:156` `/api/automation/labels/batch-auto`.
문서 묶음을 `workflow_id=pab-label-<batchid>`로 묶고, 문서별 seq로 진행. 라벨 결과는 PAB의 `/api/approval/chunks/batch/add-labels`로 환류(human-in-the-loop 유지). 단시간 작업이라 이득은 **중간**(주로 재시작 내성).

### 후보 C — reasoning/ask → Khala generate (선택)

**부착점:** `backend/routers/reasoning/reason.py:72`.
짧은 동기 RAG 응답은 resumable 이득이 작다. 다만 **여러 brain·folder_scope를 가로지르는 장문 reasoning**이라면 resumable이 의미. 우선순위 낮음.

---

## 4. 인증·식별자 정리 (구현 전 필수 합의)

1. **caller prefix 신규 등록**: Khala `auth.py` 화이트리스트에 `pab:*`(또는 기존 `khala-self:*` 재사용) 추가 필요. 미등록이면 `assert_allowed`에서 거절.
2. **request_id 규약**: PAB가 `metadata.request_id`를 `<task_id>#<seq>`로 항상 부여 → Khala가 `_index.jsonl`로 역추적 가능(없으면 `<wid>#<seq>` 폴백).
3. **workflow_id 네임스페이스**: `pab-runfull-*` / `pab-label-*` 접두로 충돌·오용 방지(A1 `_safe_key` 검증을 통과하는 안전 문자만).

---

## 5. ⚠️ 결정적 리스크 — 단일 GPU vLLM↔Ollama mutex

**가장 먼저 풀어야 할 운영 충돌.** (Khala D34/D35/D36, 정책 B)

- 3800x는 **단일 24GB(3090)** 에서 vLLM과 Ollama를 **동시 점유 불가**. Khala가 vLLM을 띄우면 정책 B로 open-webui를 stop하고 Ollama 진행분만 마무리시킨다.
- **그런데 PAB-v4의 자동 라벨링·reasoning은 지금 Ollama를 직접 호출**한다(`ollama_client.py`). 즉:
  - run-full을 Khala(vLLM)로 돌리는 **동안에는 PAB-v4 자신의 Ollama 라벨링·reasoning이 막힌다.**
  - 반대로 PAB-v4가 Ollama로 작업 중이면 Khala vLLM 배치를 띄울 수 없다.
- 현재 라이브가 `vLLM off / Ollama idle`인 것도 이 mutex 때문(둘 중 하나만 활성).

**→ 결정(2026-06-29): 정책 (나) 시간 분리 채택.**
- 짧은 인터랙티브(라벨 제안·reasoning)는 **Ollama 유지**(현 코드 무변경).
- **야간/온디맨드 대량 ingest(run-full)만 Khala vLLM** 배치로 우회.
- 전제 규율(필수): **vLLM 배치와 Ollama 작업의 동시 실행 금지.** PAB-v4가 Khala 배치를 띄우기 전, Khala `GET /v1/admin/gpu/state`로 Ollama가 `idle`인지 확인 → 정책 B(open-webui stop + ollama unload)로 vLLM 점유 → 배치 종료 후 Ollama 복귀. 배치 중 들어온 인터랙티브 라벨 요청은 큐잉하거나 사용자에게 "배치 진행 중" 표기.
- 미채택: (가) 전면 vLLM 이주(코드 대수술), (다) 연동 보류(DB 영속화만).

---

## 6. Lineage/Resumable의 한계와 PAB-v4 노출 시 주의

A⊕B 설계 §7 적대적 재검증에서 드러난 **미해소 항목**(Track B 보류, 내부망 단독 전제):

| 항목 | 현 상태 | PAB-v4 연동 영향 |
|---|---|---|
| `workflow_id` 경로 주입 | **A1로 차단됨**(`_safe_key`+`is_relative_to`) | 안전. `pab-*` 접두 권장 |
| A 무손실 | **A2 서버 자동저장으로 입증**(KPI PASS) | run-full에 그대로 활용 가능 |
| `resume_valid` 강제력 | ⚠️ 표시만, 차단 안 함 | PAB가 모순 체인이어도 진행됨 → PAB측에서 `resume_valid=false` 응답 시 alert |
| 인증(lineage 조회) | ⚠️ `assert_allowed` 미적용 | LAN 노출 시 누구나 체인 조회 가능 → PAB-v4 프록시 뒤로 숨기기 |
| 동시성 락 | ⚠️ 무락(`record_run` read→len→append) | **PAB가 같은 wid로 동시 호출 금지**(배치 직렬화 필수). A6 동시 wid 409는 디렉토리 단위만 |
| DoS/SSRF | 미구현(Track B) | 내부망 단독 유지 전제. 외부 노출 계획 시 선결 |

---

## 7. 권고 — 단계적 도입 로드맵 (확정: 둘 다 / 시간 분리)

> 결정(2026-06-29): **범위 = 두 축 모두 로드맵**, **GPU 정책 = (나) 시간 분리**. 두 축은 독립이므로 **조회 층(Phase 1)을 먼저 완주**하고, 생성 층(Phase 2~)은 시간 분리 규율 위에서 뒤따른다.

**Phase 0 (선결 — 1회):**
- Khala `auth.py` 화이트리스트에 `pab:*` caller 등록(미등록 시 `assert_allowed` 거절).
- Khala `GET /v1/admin/gpu/state` 폴링 헬퍼를 PAB-v4 측에 추가(배치 진입 전 Ollama idle 확인용 — 시간 분리 규율의 코드 훅).

**Phase 1 (조회 층 — brain 카테고리 연결 본체, Khala 무관):**
- `pab-lv0` MCP 6 tools + `/ext/lv0/v1` REST 6 endpoint를 **PAB-v4 자체 구현**(`X-PAB-Key`/`read:lv0`).
- 저자링크 파서(명세 §5) 구현 + `lv0_query_events` 로깅.
- ← 이게 사용자가 말한 "brain 카테고리로 연결하는 API/MCP"의 본체. **Khala 의존 0, GPU mutex 무관**(LLM 호출 없음).

**Phase 2 (생성 층 PoC — 시간 분리 위에서):**
- run-full 1건만 Khala resumable로 우회(후보 A). 진입 전 `gpu/state`로 Ollama idle 확인(시간 분리).
- `task_id↔workflow_id` 1:1 매핑 + auto-resume loop + lineage 조회로 **"서버 재시작 후 재개"** 실증.
- 동시 실행 금지: 배치 진행 중 인터랙티브 라벨 요청은 큐잉 또는 "배치 중" 표기.

**Phase 3 (확장):**
- batch-label(후보 B) + 진행률 SSE를 Khala 응답 중계로 전환.
- reasoning(C)은 우선순위 낮음(보류). 야간 배치 스케줄러(온디맨드 트리거)로 시간 분리 자동화 검토.

**상호 연결(상위 오케스트레이션):** 외부 LLM이 Phase 1의 `pab-lv0` MCP로 brain을 조회 → 그 결과로 Phase 2의 Khala 장기 생성 작업을 위임하는 흐름은 두 축을 잇는 자연스러운 사용 시나리오(축 ①→②).

---

## 8. 부록 — 핵심 파일 인덱스

**PAB-v4**
- Brain 모델: `backend/models/brain.py:13-48`
- Brain API: `backend/routers/knowledge/brain.py:109-280`
- Label/카테고리: `backend/models/models.py:93-116`
- LLM 클라이언트(Ollama): `backend/services/ai/ollama_client.py`
- 배치 워크플로: `backend/routers/automation/automation.py:206-274`
- Task state(메모리): `backend/services/automation/ai_workflow_state.py:15-150`
- pab-lv0 MCP/REST 명세: `docs/overview/260627-PAB-v4-LV0-조회API-MCP-명세.md`
- Brain 수동 큐레이션 설계: `docs/storyboard/260624-LV0-Brain-수동큐레이션-설계.md`

**Khala**
- Resumable Tools 가이드: `docs/guides/khala-resumable-tools-api-guide.md`
- Lineage 가이드: `docs/guides/khala-lineage-api-guide.md`
- A⊕B 설계+검증: `docs/design/20260628-context-continuation-and-call-lineage-design.md`
- 구현: `scripts/api/handlers/tools.py` · `scripts/run-on-3800x-v5/lib/{tools.py,openai_chat.py}` · `scripts/api/models.py`
