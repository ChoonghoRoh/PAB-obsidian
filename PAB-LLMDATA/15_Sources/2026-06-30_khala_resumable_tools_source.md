---
title: "PAB-Khala Resumable Tools API — NVMe 워크스페이스·무손실 재개 (원문)"
description: "PAB-Khala 저장소 원본 문서 immutable 보존 — docs/guides/khala-resumable-tools-api-guide.md"
created: 2026-06-30 07:58
updated: 2026-06-30 07:58
type: "[[SOURCE]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[NVME_WORKSPACE]]"]
tags: ["source", "khala", "phase6"]
keywords: ["khala", "resumable", "nvme", "workspace", "무손실재개", "prefix-cache", "vllm", "workflow-id", "checkpoint", "RAM"]
sources: ["docs/guides/khala-resumable-tools-api-guide.md"]
aliases: ["resumable-tools", "nvme워크스페이스", "무손실재개"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층). 원본 위치: `PAB-Khala/docs/guides/khala-resumable-tools-api-guide.md`

# Khala Resumable Tools API 연결 가이드 — NVMe 워크스페이스 + 무손실 재개

> 작성 2026-06-24 · 대상 서버 3800x (`http://3800x:8765` / vLLM `:8020`)
> 선행 문서: [vLLM Tool Calling 가이드](vllm-tool-calling-guide.md) (`/v1/tools/run` 기본편)

## 0. 한눈에 보기

`POST /v1/tools/run`이 **무손실 재개(resumable)** 를 지원한다. LLM이 도구로 작업하다가 컨텍스트 한계(`max_iter`)에 닿으면, 진행 상황을 **NVMe 워크스페이스**에 남기고 종료한다. 같은 `workflow_id`로 `resume=true` 재호출하면 **직전 상태에서 이어서** 작업한다.

| 개념 | 설명 |
|---|---|
| **2층 구조** | Tier1(엔진): vLLM prefix-cache가 반복 prefix KV를 fp8로 재사용 · Tier2(SW): NVMe `workspace.md` + 자동 체크포인트 |
| **핵심 가치** | 24GB 단일 GPU의 컨텍스트 윈도우를 넘어 **논리적으로 무한히 이어지는 작업** |
| **신규 도구** | `workspace_read`(직전 상태 읽기) · `workspace_write`(전체 상태 저장) |
| **신규 필드** | 요청 `workflow_id`/`resume` · 응답 `workflow_id`/`resumable` |

구현: `scripts/run-on-3800x-v5/lib/{tools.py,openai_chat.py}` + `scripts/api/handlers/tools.py` + `scripts/api/models.py`.

---

## 1. 엔드포인트 스펙

### 요청 `POST /v1/tools/run`

```jsonc
{
  "prompt": "수행할 작업",
  "system": "에이전트 시스템 프롬프트 (워크스페이스 사용 규칙 권장)",
  "tools": ["workspace_read", "workspace_write", "save_file"],  // 화이트리스트 (생략 시 전체)
  "model": "qwen3.6-27b-autoround",
  "endpoint": "http://localhost:8020",
  "max_iter": 8,
  "max_tokens": 1024,
  "temperature": 0.5,
  "workflow_id": "my-task-001",   // 재개 키 (생략 시 신규 생성 후 응답에 반환)
  "resume": false,                 // true = workflow_id 의 직전 워크스페이스에서 이어감
  "metadata": { "caller": "manual:my-client", "request_id": "r-1" }
}
```

### 응답 `ToolsRunResponse`

```jsonc
{
  "status": "ok | max_iter | error",
  "final_response": "최종 답변 (status=ok 일 때)",
  "tool_calls_log": [ { "iter": 0, "name": "workspace_write", "arguments": {...}, "result_size": 1775, "exec_wall_sec": 0.0 } ],
  "iterations": 2,
  "wall_sec": 56.0,
  "workflow_id": "my-task-001",   // ★ 재개에 사용할 키
  "resumable": true,               // ★ true = 이어받기 가능 (max_iter 도달 등)
  "error": "max_iter (2) reached without final response"
}
```

> `caller`는 화이트리스트(`auth.py`) 통과 필요: `conductor:*` / `ssot:*` / `obsidian:*` / `khala-self:*` / `manual:*`.

---

## 2. 연결 절차 (2단계 호출)

### 1차 호출 — 작업 시작

```bash
curl -s http://3800x:8765/v1/tools/run -X POST -H "Content-Type: application/json" -d '{
  "prompt": "주제 X로 3개 섹션 보고서를 작성. 각 섹션을 쓸 때마다 workspace_write로 전체를 저장. 완료 시 save_file(report.md)로 저장.",
  "system": "너는 자율 에이전트다. 매 단계 후 workspace_write로 전체 작업물을 저장하고, 이어받을 때는 먼저 workspace_read로 직전 상태를 확인한 뒤 진행한다.",
  "tools": ["workspace_read","workspace_write","save_file"],
  "model": "qwen3.6-27b-autoround",
  "max_iter": 2,
  "metadata": {"caller":"manual:demo","request_id":"r-1"}
}'
# → {"status":"max_iter","resumable":true,"workflow_id":"tools-run-1782308867", ...}
```

### 2차 호출 — 이어받기 (동일 `workflow_id` + `resume:true`)

```bash
curl -s http://3800x:8765/v1/tools/run -X POST -H "Content-Type: application/json" -d '{
  "prompt": "이전 작업을 이어서 완료하라.",
  "system": "(1차와 동일한 system)",
  "tools": ["workspace_read","workspace_write","save_file"],
  "model": "qwen3.6-27b-autoround",
  "workflow_id": "tools-run-1782308867",
  "resume": true,
  "max_iter": 6,
  "metadata": {"caller":"manual:demo","request_id":"r-2"}
}'
# → {"status":"ok","resumable":false,"workflow_id":"tools-run-1782308867", ...}
```

`resume:true`면 핸들러가 `workspace_read()`로 직전 워크스페이스를 읽어 **system 프롬프트에 자동 주입**한다. 모델은 처음부터 다시 하지 않고 그 지점부터 이어간다.

> 외부 클라이언트 패턴: `resumable=true`인 동안 같은 `workflow_id`로 재호출을 반복하면, 임의 길이 작업을 완주시킬 수 있다(auto-resume loop).

---

## 3. 작동 체인

```
HTTP req ─▶ [Tier1 엔진] prefix-cache가 system+tools schema prefix KV 재사용 (fp8 VRAM)
        ─▶ tool_loop_openai ─▶ workspace_write
        ─▶ [Tier2 SW] NVMe workspace.md + autosave(note/checkpoint)
        ─▶ max_iter ─▶ resumable=true
        ─▶ resume req ─▶ workspace_read가 NVMe 상태를 system에 seed ─▶ 이어감 ─▶ status=ok
```

### NVMe 저장소 레이아웃

`/v1/tools/run`은 `workflow_id`별로 독립 Store를 만든다(`$KHALA_DATA_DIR/tools_run/<workflow_id>/`):

```
tools_run/<workflow_id>/
├── workspace.md        # ★ 현재 작업 상태 1건 (workspace_write가 전체 덮어쓰기)
├── notes/              # save_note + 자동저장(_autosave_messages.md)
├── checkpoints/        # iter_N.json (매 iteration autosave) + _latest.txt
├── artifacts/          # save_file 산출물
└── _audit.log          # 모든 op 감사 로그
```

OOM·프로세스 강제종료에도 `workspace.md`와 마지막 checkpoint가 NVMe에 남아 **거의 손실 없이 재개**된다.

---

## 4. 신규 도구 2종

| 도구 | 시그니처 | 동작 |
|---|---|---|
| `workspace_read` | `() -> str` | `workspace.md` 전체 반환 (없으면 "비어있음"). 이어받기 시 가장 먼저 호출 |
| `workspace_write` | `(content: str) -> str` | `workspace.md`를 통째로 덮어쓰기 + audit. 매 단계 후 "누적 전체"를 저장 |

기존 `save_note`(다건 메모) / `checkpoint`(단계 기록)와 공존한다. 워크스페이스는 **"지금까지의 전체 작업물 1건"** 이라는 점이 다르다. 도구 목록: `GET /v1/tools/list`.

---

## 5. 라이브 실증 (2026-06-24, 3800x · tools-text variant)

| 호출 | 결과 |
|---|---|
| 1차 `max_iter=2` | `status=max_iter, resumable=true` — 섹션1을 NVMe `workspace.md`(1775B)에 적재 + autosave/checkpoint |
| 2차 `resume=true` | NVMe 상태 seed → **재시작 없이 섹션2로 이어감** → `status=ok`, workspace 1775→3662B |

**엔진 KV 재사용 (vLLM `/metrics`):** `prefix_cache_hits/queries = 1600/6825 = 23%`. 반복 prefix(system+tools schema+누적 메시지)의 KV를 fp8로 재사용 → 재계산 제거.

---

## 6. 운영 주의 / 트레이드오프

- **vLLM variant**: tool-schema(=IDE-agent급) 워크로드는 **`docker-compose.tools-text.yml`**(75K·fp8 KV·agent-safe)로 기동할 것. `long-text.yml`(214K)은 Cliff 2b로 tool 워크로드에 **안전하지 않음**. 기동: GPU mutex(open-webui stop + ollama unload) → `docker compose -f docker-compose.tools-text.yml up -d`.
- **`tool_choice=auto` 한계**: 루프가 도구 호출을 강제하지 않아, 모델이 `save_file` 대신 본문으로 답하면 명명된 산출물이 안 나올 수 있다. 단, `workspace.md`(NVMe)는 항상 영속된다. (후속: 마지막-N-iter tool_choice 강제 설계)
- **`max-num-seqs=1`**: 단일 시퀀스 운용 → preemption swap 이득은 작음. 컨텍스트 레버는 prefix-cache 재사용 + 워크스페이스 재개.
- **엔진 KV의 RAM/NVMe 오프로드(미적용)**: 현재 `external_prefix_cache=0`(native). LMCache 도입 시 컨테이너 재시작·요청 간에도 prefix 재계산이 0이 된다 — RAG·고정 system+tools 워크로드의 다음 레버(별도 sub-phase).
- **GPU mutex**: vLLM 점유 중에는 Ollama 채팅 불가(단일 24GB). 복구는 `ops/open_webui_run.sh` + vLLM stop.

---

## 7. 빠른 체크리스트

- [ ] tools-text variant로 vLLM 기동(`:8020` ready)
- [ ] `GET /v1/tools/list`에 `workspace_read`/`workspace_write` 노출 확인
- [ ] 1차 호출 `max_iter` 낮게 → `resumable=true` + `workflow_id` 수신
- [ ] 동일 `workflow_id` + `resume=true` 재호출 → `status=ok`
- [ ] NVMe `tools_run/<wid>/workspace.md` 누적 확인
