---
title: "PAB-Khala Lineage 연결 가이드 — 호출 연결고리 추적 (원문)"
description: "PAB-Khala 저장소 원본 문서 immutable 보존 — docs/guides/khala-lineage-api-guide.md"
created: 2026-06-30 07:58
updated: 2026-06-30 07:58
type: "[[SOURCE]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[LINEAGE]]"]
tags: ["source", "khala", "phase6"]
keywords: ["khala", "lineage", "연결고리", "prev-current-next", "workflow-id", "parent", "resume-valid", "seq", "_index-jsonl"]
sources: ["docs/guides/khala-lineage-api-guide.md"]
aliases: ["lineage가이드", "연결고리추적"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층). 원본 위치: `PAB-Khala/docs/guides/khala-lineage-api-guide.md`

# Khala Lineage 연결 가이드 — 호출 연결고리 추적 (prev→current→next)

> 작성 2026-06-28 · 대상 서버 3800x (`http://3800x:8765` / vLLM `:8020`)
> 선행: [Resumable Tools API 가이드](khala-resumable-tools-api-guide.md) · 설계: `docs/design/20260628-context-continuation-and-call-lineage-design.md`

## 0. 무엇을 해결하나

외부 API로 열린 LLM은 stateless HTTP라, "이 호출이 이전 작업과 이어지는가?"를 서버가 스스로 알 수 없었다. Lineage는 **호출 1건을 NVMe 체인에 기록**해, 서버가 **부모(prev)·순번(seq)을 부여하고 resume 모순을 검증**한다.

- **A(컨텍스트 이어가기)** = "무엇을 이어가나" → `workspace.md`
- **B(연결고리 추적, 이 문서)** = "누가 누구와 이어지나" → `_runs.jsonl`

두 축은 같은 `workflow_id`를 공유해 한 레코드에서 동시에 추적된다.

---

## 1. 식별자 3종

| 식별자 | 의미 | 누가 부여 |
|---|---|---|
| `workflow_id` | 작업 체인(=NVMe 디렉토리) 키 | 클라이언트(미지정 시 서버 생성 후 응답 반환) |
| `request_id` | 호출 1건 식별자(`metadata.request_id`) | 클라이언트(없으면 서버가 `<wid>#<seq>` 폴백) |
| `parent_request_id` | 직전 호출 = prev 연결고리 | **서버가 부여** |

---

## 2. 연결 방법

### 2.1 새 체인 시작 (resume=false)
```bash
curl -s http://3800x:8765/v1/tools/run -X POST -H "Content-Type: application/json" -d '{
  "prompt": "작업 시작 ...",
  "tools": ["workspace_read","workspace_write"],
  "model": "qwen3.6-27b-autoround",
  "workflow_id": "my-job-001",
  "max_iter": 2,
  "metadata": {"caller":"manual:demo","request_id":"r-1"}
}'
# → {"seq":0,"parent_request_id":null,"resume_valid":true,"resumable":true,"workflow_id":"my-job-001", ...}
```

### 2.2 이어가기 (동일 workflow_id + resume=true)
```bash
curl -s http://3800x:8765/v1/tools/run -X POST -H "Content-Type: application/json" -d '{
  "prompt": "이전 작업을 이어서 ...",
  "tools": ["workspace_read","workspace_write"],
  "model": "qwen3.6-27b-autoround",
  "workflow_id": "my-job-001",
  "resume": true,
  "max_iter": 2,
  "metadata": {"caller":"manual:demo","request_id":"r-2"}
}'
# → {"seq":1,"parent_request_id":"r-1","resume_valid":true, ...}   ← 서버가 r-1에 연결
```

### 2.3 체인 조회
```bash
curl -s http://3800x:8765/v1/tools/lineage/my-job-001 | python3 -m json.tool
```
```jsonc
{
  "workflow_id": "my-job-001",
  "chain_len": 2,
  "chain": [
    {"seq":0,"request_id":"r-1","parent_request_id":null,"resume_requested":false,"resume_valid":true,"status":"max_iter","workspace_size":689, ...},
    {"seq":1,"request_id":"r-2","parent_request_id":"r-1","resume_requested":true,"resume_valid":true,"status":"ok","workspace_size":2821, ...}
  ],
  "resumable_tail": false
}
```

---

## 3. 응답 필드 (연결고리 관련)

| 필드 | 의미 |
|---|---|
| `workflow_id` | 이 호출이 속한 체인 키 |
| `seq` | 체인 내 호출 순번(0부터) |
| `parent_request_id` | 직전 호출 id(첫 호출이면 `null`) |
| `resume_valid` | **`false`면 모순** — resume 요청했는데 이어갈 체인이 없음(틀린 wid 등) |
| `resumable` | 다음 호출로 이어받기 가능(예: max_iter 도달) |

---

## 4. 호출 연결 판정 규칙 (서버)

| 입력 | 판정 |
|---|---|
| 기존 wid + resume=true | 연속 — `seq=마지막+1`, `parent=마지막 request_id` |
| 신규 wid + resume=true | **모순** — `resume_valid=false` (이어갈 게 없음) |
| 신규 wid + resume=false | 새 체인 — `seq=0`, `parent=null` |
| 직전 `request_id`만 보유 | `_index.jsonl`로 wid 역추적 후 위 규칙 |
| 식별자 없음 | 연결 불가(stateless HTTP 원리적 한계) |

> 자동 연속 루프: 응답 `resumable=true`인 동안 같은 `workflow_id`+`resume=true`로 재호출을 반복하면 임의 길이 작업을 완주시킬 수 있다.

---

## 5. NVMe 저장물

```
tools_run/<workflow_id>/_runs.jsonl   # 호출 1건=1줄 (seq,request_id,parent,resume_valid,status,workspace_size,t)
tools_run/_index.jsonl                 # request_id → workflow_id 전역 매핑
```
append-only(이력 불변)이며 기존 `workspace.md`/`checkpoints`와 별도 파일이라 간섭이 없다.

다음: 실제 동작 확인은 [Lineage 검증 가이드](khala-lineage-verification-guide.md) 참조.
