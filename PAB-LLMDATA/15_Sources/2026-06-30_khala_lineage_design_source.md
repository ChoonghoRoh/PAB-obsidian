---
title: "PAB-Khala 컨텍스트 이어가기·호출 연결고리 설계 (A⊕B) (원문)"
description: "PAB-Khala 저장소 원본 문서 immutable 보존 — docs/design/20260628-context-continuation-and-call-lineage-design.md"
created: 2026-06-30 07:58
updated: 2026-06-30 07:58
type: "[[SOURCE]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[LINEAGE]]", "[[NVME_WORKSPACE]]"]
tags: ["source", "khala", "phase6"]
keywords: ["khala", "lineage", "연결고리", "컨텍스트이어가기", "nvme", "workspace", "resume", "_runs-jsonl", "계보추적"]
sources: ["docs/design/20260628-context-continuation-and-call-lineage-design.md"]
aliases: ["lineage설계", "호출연결고리설계", "컨텍스트이어가기"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층). 원본 위치: `PAB-Khala/docs/design/20260628-context-continuation-and-call-lineage-design.md`

# 설계: 컨텍스트 이어가기(A) + 호출 연결고리 추적(B) + 통합(A⊕B)

> 작성 2026-06-28 · 대상 서버 3800x (`http://3800x:8765` / vLLM `:8020`)
> 관련: [Resumable Tools API 가이드](../guides/khala-resumable-tools-api-guide.md) · 커밋 `a166380`(A 구현 완료)

## 0. 문제 정의

24GB 단일 GPU의 컨텍스트 윈도우는 작고 고정이다(현 운영 24,576토큰). 외부 API로 열린 LLM은 **stateless HTTP**라, 한 호출이 끝나면 컨텍스트(RAM의 messages)가 사라진다. 두 가지를 분리해 설계한다.

- **(A) 세션간 컨텍스트 이어가기** — 작은 윈도우의 작업 상태를 NVMe/RAM 파일로 외부화해, 다음 호출이 그 파일을 다시 읽어 *내용*을 이어간다. **(커밋 `a166380`에서 구현 완료)**
- **(B) 호출간 연결고리 추적** — "이 호출이 이전 작업 ID와 이어지는가?"를 **서버가 스스로 판정·기록**한다. 호출의 *계보(lineage)* 를 남긴다. **(본 문서에서 신규 설계)**
- **(A⊕B) 통합** — A의 "내용 연속"과 B의 "호출 연결"을 하나의 타임라인으로 추적한다.

---

## 1. 두 메커니즘의 축

| | A: 컨텍스트 이어가기 | B: 연결고리 추적 |
|---|---|---|
| 단위 | `workflow_id` (NVMe 워크스페이스 디렉토리) | 1 API 호출 (`request_id`) |
| 저장물 | `workspace.md`(작업 상태), autosave note/checkpoint | `_runs.jsonl`(호출 체인), `_index.jsonl`(전역 인덱스) |
| 질문 | "직전 작업 *내용*이 무엇이었나?" | "이 호출이 *어느 체인의 몇 번째*인가?" |
| 누가 판정 | 클라이언트가 `resume` 지시 | **서버가 부모/순번 부여 + 모순 검증** |
| 자원 | NVMe(영속) + RAM(page-cache/실행) | NVMe(append-only) + RAM(선택 캐시) |

핵심: **A는 "무엇을 이어가나", B는 "누가 누구와 이어지나"**. 둘은 같은 `workflow_id` 디렉토리를 공유하므로 자연스럽게 결합된다.

---

## 2. (A) 컨텍스트 이어가기 — 구현 완료 (요약)

`tools_run/<workflow_id>/workspace.md`를 단일 누적 작업 문서로 쓴다.

- `workspace_write(content)`: 매 단계 "지금까지의 전체"를 NVMe에 덮어쓰기.
- `resume=true` 호출 시 핸들러가 `workspace_read()`로 직전 상태를 읽어 **system 프롬프트에 주입** → 작은 윈도우가 "이전 기억"을 갖고 시작.
- autosave: 매 iteration `_autosave_messages` + `checkpoints/iter_N.json`(중단 대비).
- 실증: workspace.md 1775→3662B로 누적되며 재시작 없이 이어감(2026-06-24).

상세: 가이드 §3·§4. 코드: `lib/tools.py`(Store), `lib/openai_chat.py`(tool_loop_openai), `handlers/tools.py`(run_tools).

---

## 3. (B) 호출 연결고리 추적 — 신규 설계

### 3.1 현재 한계 (조사 결과)
- `metadata.request_id`가 `run_tools`에서 **미사용** → NVMe·DB 어디에도 안 남음.
- 호출 경계는 `_audit.log` 시간 간격으로만 추정. 부모 포인터·resume 플래그·호출별 결과 **전무**.
- 즉 연결고리는 **클라이언트 주장**일 뿐, 서버가 검증·기록하지 못함. 틀린 id도 통과.

### 3.2 데이터 모델 (NVMe append-only)

**`tools_run/<wid>/_runs.jsonl`** — 호출 1건 = 1줄(append-only, 불변 이력):
```jsonc
{
  "seq": 1,                       // 이 워크플로 내 호출 순번 (0부터)
  "request_id": "req-2",          // 이 호출 식별자 (없으면 "<wid>#<seq>")
  "parent_request_id": "req-1",   // ★ 직전 호출 = prev 연결고리 (서버가 부여)
  "workflow_id": "demo-wf-001",
  "resume_requested": true,       // 클라이언트가 이어가기를 요청했나
  "resume_valid": true,           // ★ 서버 검증: resume인데 parent 없으면 false (모순)
  "status": "ok|max_iter|error",
  "iterations": 2,
  "resumable": true,              // 다음 호출로 이어받기 가능 신호
  "workspace_size": 3662,         // ★ A의 상태 크기 = 내용 연속의 물증
  "t": "2026-06-28T13:00:00"
}
```

**`tools_run/_index.jsonl`** — 전역 매핑(request_id만 알 때 체인 역추적):
```jsonc
{"request_id": "req-2", "workflow_id": "demo-wf-001", "seq": 1, "t": "..."}
```

### 3.3 서버 판정 규칙 (호출이 연결되는지)

| 클라이언트 입력 | 서버 동작 |
|---|---|
| `workflow_id` 기존 + `resume=true` | `_runs.jsonl` 읽어 `seq=len`, `parent=마지막 request_id` → **연속으로 기록** |
| `workflow_id` 신규 + `resume=true` | `parent=None` → `resume_valid=false`로 **모순 표시**(연결 안 됨을 서버가 감지) |
| `workflow_id` 신규 + `resume=false` | `seq=0, parent=None` → **새 체인 시작** |
| 직전 `request_id`만 보유 | `_index.jsonl`로 `workflow_id` 역추적 후 위 규칙 |
| 식별자 없음 | **연결 불가** — stateless HTTP의 원리적 한계(내용기반 자동추론은 비채택) |

### 3.4 조회
- `GET /v1/tools/lineage/{workflow_id}` → 체인 전체(`_runs.jsonl`) 반환.
- `request_id`로 prev/next: `_index.jsonl` → wid → 체인에서 `seq±1`.

---

## 4. (A⊕B) 통합 — 두 추적을 하나의 타임라인으로

A와 B를 잇는 고리는 **`_runs.jsonl`의 한 레코드가 두 사실을 동시에 증명**한다는 점이다:

- `parent_request_id` → **B(호출이 누구와 이어지는가)**
- `workspace_size` → **A(내용이 실제로 커졌는가)**

따라서 한 워크플로의 `_runs.jsonl`을 시간순으로 읽으면 통합 스토리가 나온다:

```
seq0 req-1 parent=∅  resume=F  status=max_iter  ws=1775B   ← 새 체인 시작, 내용 1775B 적재
seq1 req-2 parent=req-1 resume=T status=max_iter ws=3662B  ← req-1에 이어짐(B) + 내용 1775→3662 성장(A)
seq2 req-3 parent=req-2 resume=T status=ok       ws=3662B  ← 완료
```

→ "호출 req-2는 req-1의 연속이며(B), 그 결과 워크스페이스가 1775→3662B로 자랐다(A)" 를 **단일 레코드로 검증**. 이것이 두 메커니즘을 이어 추적하는 방법이다.

무결성 교차검증: `_runs.jsonl`의 호출 수 = `_audit.log`의 `record_run` op 수 = `_index.jsonl`의 해당 wid 항목 수 (3중 일치).

---

## 5. 구현 범위

| 파일 | 변경 |
|---|---|
| `lib/tools.py` | `Store.record_run(...)`(append `_runs.jsonl`+`_index.jsonl`) + `Store.lineage()` |
| `handlers/tools.py` | `run_tools`: 루프 후 `record_run` 호출 + `GET /v1/tools/lineage/{wid}` 추가 |
| `models.py` | `ToolsRunResponse`에 `seq`/`parent_request_id`/`resume_valid` 추가 |

설계 원칙: **기존 store 파일과 별도 파일**(간섭 0), **append-only**(이력 불변), `request_id` 없으면 `<wid>#<seq>` 폴백.

---

## 6. 검증 계획 (실 e2e)

1. 배포 후 3-call 체인 실행: ① 신규(resume=F) → ② 재개(resume=T) → ③ 재개완료(resume=T).
2. 모순 케이스: 신규 wid에 resume=T → `resume_valid=false` 확인.
3. `GET /v1/tools/lineage/{wid}`로 체인 복원 확인.
4. NVMe `_runs.jsonl`/`_index.jsonl` 생성 확인 → **3800x에서 repo로 복사해 기록 보존**.
5. 3중 일치(runs=audit record_run=index) 무결성 확인.

결과: §7 참조.

---

## 7. 검증 결과 (2026-06-28 실 e2e, 3800x)

배포(`lib/tools.py`+`handlers/tools.py`+`models.py`) 후 실제 `/v1/tools/run`로 실행. 로그 원본은
[`../analysis/lineage-e2e-20260628/`](../analysis/lineage-e2e-20260628/)에 3800x에서 복사·보존.

**클린 체인 (`_runs.jsonl` 실데이터):**
```
seq0 clin-1 parent=∅      resume=F valid=T status=ok       ws=689B
seq1 clin-2 parent=clin-1 resume=T valid=T status=ok       ws=689B
seq2 clin-3 parent=clin-2 resume=T valid=T status=max_iter ws=2821B  ← 7섹션 누적
```

| 검증 항목 | 결과 |
|---|---|
| B: 연결고리(parent 부여) | ✅ clin-1→clin-2→clin-3 서버가 부여 |
| B: 모순 탐지 | ✅ 새 wid+resume=true → `resume_valid=false` (단 표시뿐, 차단 안 함) |
| B: 조회 API | ✅ `GET /v1/tools/lineage/{wid}` 체인 복원 |
| A: 내용 이어가기 | ⚠️ **부분 실패** — 아래 정정 참조 |
| A⊕B 통합 | △ 레코드에 parent+workspace_size 동시 기록은 됨. 단 무결성 주장은 약함 |
| 3중 무결성 | △ runs=audit=index=3 이나 **동일 record_run의 자기복제 카운트**(독립 교차검증 아님) |

### ⚠️ 적대적 페르소나 재검증 정정 (2026-06-28)

다중 페르소나(동시성/보안/적대적 QA) 검토로 §7 초안의 과장·결함을 정정한다:

- **A "무손실" 미입증·반증**: `clean_chain_workspace.md`는 7섹션이 아니라 **2섹션(2번 유실)**. audit상 중간 resume 호출(seq1)은 `workspace_write`를 호출하지 않아 `workspace_size`가 689→689 불변 — 섹션2가 NVMe에 저장 안 됨(`tool_choice=auto`로 모델이 도구 대신 본문 답변). **워크스페이스 영속이 모델 규율에 의존**하는 구조적 취약점이 노출됨.
- **resume_valid 강제력 없음**: 모순(false)이어도 호출은 정상 수행되고 `resumable=true`로 다음 호출이 이어받음 → 표시만 하는 경고.
- **보안(Critical)**: `workflow_id`가 검증 없이 디렉토리 경로로 사용됨(`handlers/tools.py` run_tools / lineage). `../` 주입 시 DATA_ROOT 밖 디렉토리 생성·append 가능. `_safe_key` 미적용. **LAN 노출 전 필수 차단**. lineage 엔드포인트는 인증(`assert_allowed`)도 없음.
- **동시성**: sync 핸들러(threadpool 병렬) + `record_run`의 read→len→append 무락 → 동일 wid 동시 호출 시 seq 중복·parent fork·workspace lost-update.

**수정된 결론: (B) 호출 연결고리 추적은 단일 라이터·순차 사용 전제에서 견고하게 입증됨. (A) 무손실 이어가기는 이 e2e에서 부분 실패했고, "무손실"은 `workspace_write` 강제 + 동시성 락 + workflow_id 검증이 갖춰져야 성립.** 상세 결함·수정안은 본 세션 페르소나 리뷰 참조.

### 7.1 Track A 견고화 후속 검증 (2026-06-28, Phase 5)

위 §7의 결함들을 Track A(A1~A6)로 구현·배포·재검증해 **6/6 KPI PASS**. 실증: [`../analysis/lineage-e2e-20260628-p5a/README.md`](../analysis/lineage-e2e-20260628-p5a/README.md).

- **A 무손실 — 입증으로 전환**: A2 서버측 자동저장(`tool_loop_openai.on_finalize_workspace`)으로, 모델이 `workspace_write`를 한 번도 호출하지 않은 3-call 체인에서도 3섹션 전부 영속(workspace_size 26→3128B 누적). §7의 "모델 규율 의존" 취약점 해소.
- **workflow_id 검증(A1)**: `_safe_key` 강제 + Store `base` 하위 `is_relative_to` 검증 → 비정상 wid 전부 400.
- **error parent 격리(A3)**, **원자 쓰기(A4, tmp+os.replace)**, **동시 wid 409(A6)** 모두 실호출 PASS.
- **단, resume_valid 강제력·인증·DoS·SSRF·본격 동시성 락은 Track B(외부 진입 트리거)로 보류** — 내부망 단독 전제라 미구현.
