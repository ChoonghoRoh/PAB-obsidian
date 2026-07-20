---
title: "PAB-Khala 통합 게이트웨이 설계 — 현행 vs 통합 비교 (원문)"
description: "PAB-Khala 저장소 원본 문서 immutable 보존 — docs/design/20260629-khala-unified-gateway-design.md"
created: 2026-06-30 07:58
updated: 2026-06-30 07:58
type: "[[SOURCE]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[API_GATEWAY]]", "[[GPU_MUTEX]]"]
tags: ["source", "khala", "phase6"]
keywords: ["khala", "게이트웨이", "런타임투명", "mutex중재", "현행비교", "호출surface", "arbiter", "ollama", "vllm"]
sources: ["docs/design/20260629-khala-unified-gateway-design.md"]
aliases: ["게이트웨이설계", "khala통합안"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층). 원본 위치: `PAB-Khala/docs/design/20260629-khala-unified-gateway-design.md`

# 설계: Khala 통합 게이트웨이 — 현행 운영 방식 vs 게이트웨이 통합안 비교

> 작성 2026-06-29 · 대상 3800x (`http://3800x:8765` · vLLM `:8020` · Ollama `:11434`)
> 맥락: [PAB-v4 연동 보고서](../analysis/20260629-pab-v4-brain-khala-integration-report.md) §5 GPU 정책 (나) 시간 분리 결정 후속
> 목표: "엔진을 하나로 줄이지 않고, **호출 surface와 GPU 중재를 한 곳(Khala)으로 통합**"하는 안을 현행과 비교

---

## 0. 한 줄 요지

현행은 **호출 대상이 2개(PAB-v4→Ollama 직접, Khala→vLLM)이고 GPU mutex가 요청 경로 밖(대시보드·수동)에서 운영**된다. 통합안은 **Khala 단일 게이트웨이가 런타임을 투명하게 선택하고 mutex를 요청 경로에서 중앙 중재**한다. 핵심은 **Khala가 이미 부품(ops 툴킷·ollama_client·vLLM generate·통합 로깅)을 다 갖고 있어, 신규는 "런타임 셀렉터 + mutex arbiter" 2개뿐**이라는 점이다.

---

## 1. 현행 운영 방식 (실측 기준)

### 1.1 호출 토폴로지

```
[PAB-v4 FastAPI :8001] ──(ollama 파이썬 SDK 직접)──▶ [Ollama :11434]  ← 라벨링·추천·reasoning
                                                          │ (단일 24GB GPU)
[외부/Conductor/SSOT] ──(HTTP)──▶ [Khala :8765] ──(curl)──▶ [vLLM :8020]  ← generate·resumable tools
                                       │
                                       └─(ops shell)──▶ mutex 조작 (대시보드/수동)
```

- **두 개의 독립 호출 경로.** PAB-v4는 Khala를 거치지 않고 Ollama를 직접 부른다(`backend/services/ai/ollama_client.py`).
- Khala는 vLLM만 부른다.

### 1.2 런타임 선택 — **없음 (vLLM 하드코딩)**

`/v1/generate`는 런타임 분기가 없다. `VLLM_ENDPOINT="http://localhost:8020"`로 직접 curl:
```python
# scripts/api/handlers/generate.py:18,54
VLLM_ENDPOINT = "http://localhost:8020"
res = subprocess.run(["curl","-s", VLLM_ENDPOINT+"/v1/chat/completions", ...])
```
→ Khala로 들어온 generate는 **무조건 vLLM**. Ollama로 보낼 길이 없다(메모리 D34 "Ollama 호출 경로 미정의"와 일치).

### 1.3 GPU mutex — **요청 경로 밖에서 운영**

mutex는 `ops.py`가 shell(`scripts/ops/*.sh`)을 감싼 **별도 admin 엔드포인트**로만 조작된다:
- `GET /v1/admin/gpu/state`(SSOT, `runtime_state.sh`) — 대시보드가 3초 폴링
- `POST /v1/admin/{ollama|vllm}/{run|stop|unload}` — 수동/대시보드 트리거, `db.log_swap` 기록

즉 **"누가 GPU를 쓰는가"의 전환은 사람이/대시보드가 호출**한다. generate·tools 요청 자체는 "지금 내가 필요한 런타임이 떠 있는지" 확인하지 않는다 → 잘못된 런타임이 떠 있으면 그냥 실패하거나, 사람이 미리 맞춰놔야 한다.

### 1.4 현행 자산 인벤토리 (이미 있는 것 — 통합안 비용을 낮추는 핵심)

| 자산 | 위치 | 상태 |
|---|---|---|
| mutex 툴킷(state/run/stop/unload) | `handlers/ops.py` + `ops/*.sh` | ✅ 운영 중 |
| Ollama 호출 래퍼(track A/B keep_alive) | `lib/ollama_client.py` | ✅ 존재(미배선) |
| vLLM generate | `handlers/generate.py` | ✅ 운영 중 |
| resumable tools(vLLM) | `handlers/tools.py` | ✅ 운영 중 |
| 통합 호출 로깅 | `db.log_call` / `db.log_swap` | ✅ 운영 중 |
| swap 이력 DB | `/v1/admin/swap/history` | ✅ 운영 중 |
| caller 화이트리스트 | `auth.py` | ✅ (`pab:*` 미등록) |

### 1.5 현행 문제점

1. **관리 포인트 2개**: PAB-v4 운영자는 Ollama를, Khala 운영자는 vLLM을 각각 신경. GPU 충돌 시 책임 경계 모호.
2. **mutex 자동성 0**: 요청이 런타임 가용성을 모름 → vLLM 배치 중 PAB-v4가 Ollama를 때리면 mutex 위반(둘 다 24GB 점유 시도) 또는 한쪽 OOM/실패.
3. **PAB-v4 호출은 Khala 로깅·lineage 밖**: 라벨링/ reasoning 호출이 Khala `db.log_call`에 안 남음 → 관측성 분절.
4. **resumable/lineage가 PAB-v4 워크로드에 적용 안 됨**: PAB-v4가 Khala를 안 거치므로 무손실 재개 이득 0.

---

## 2. 게이트웨이 통합안 설계

### 2.1 원칙 (엔진 통합과의 차이)

- **엔진은 둘 다 유지** (Ollama=멀티모델 인터랙티브, vLLM=resumable agentic). 각자 강점 보존.
- **호출 surface 1개**: PAB-v4 포함 모든 클라이언트가 Khala만 호출. Ollama 직접 호출 폐지.
- **런타임 투명**: 클라이언트는 "무엇을" 요청, Khala가 "어디서" 돌릴지 결정.
- **mutex 중앙 중재**: GPU 점유 전환을 Khala가 요청 경로에서 단독 중재(시간 분리 규율을 코드가 강제).

### 2.2 신규 #1 — 런타임 셀렉터 (RuntimeRouter)

`GenerateRequest`에 `runtime: "auto"|"ollama"|"vllm" = "auto"` 추가. 선택 규칙:

| 입력 | 라우팅 |
|---|---|
| `runtime` 명시 | 그대로 |
| `auto` + 모델이 Ollama 레지스트리(`qwen3.6:27b`, `qwen2.5:7b` …) | → Ollama |
| `auto` + 모델이 vLLM id(`qwen3.6-27b-autoround`) | → vLLM |
| `/v1/tools/run`(resumable·tool) | **항상 vLLM 강제** (prefix-cache + 입증된 tool 신뢰성, D16) |

모델→런타임 매핑은 `gpu/state`가 이미 반환하는 ollama.models / vllm 모델 목록으로 구성(신규 레지스트리 파일 불필요).

### 2.3 신규 #2 — Mutex Arbiter (요청 경로 내장)

요청이 필요한 런타임을 **보장**하는 단일 GPU 리스(lease) 계층:

```python
# 개념: scripts/api/lib/arbiter.py (신규)
class RuntimeArbiter:
    _lock = threading.Lock()          # single-flight: 동시 swap 방지
    def ensure(self, target, *, lease_owner, max_wait):
        state = gpu_state()           # runtime_state.sh (기존)
        if state.active == target:    # 이미 맞음 → 즉시 통과
            return Lease(target)
        with self._lock:              # 전환은 한 번에 하나
            if gpu_state().active == target: return Lease(target)
            if state.busy:            # 상대 런타임이 작업 중
                # 시간 분리 정책: 배치(vLLM) 우선권 보호, 인터랙티브는 양보
                raise GpuBusy(409, retry_after=state.eta)
            swap_to(target)           # 기존 ops shell: vllm_run/ollama_run + 상대 stop/unload
            return Lease(target)
```

정책(시간 분리, 보고서 §5 결정 반영):
- **기본 상주 = Ollama**(주간 인터랙티브). 
- **vLLM 배치 진입**: Ollama idle 확인(`ollama_is_busy` = ss+util, D36 신호 재사용) → 정책 B(open-webui stop + ollama unload) → vLLM run → 배치 → 종료 후 Ollama 복귀.
- **vLLM 배치 점유 중 들어온 Ollama 요청**: `409 GpuBusy{retry_after}` → PAB-v4가 큐잉하거나 "배치 진행 중" 표기. **배치를 선점하지 않음**(thrash 방지 + 무손실 배치 보호).
- **hysteresis**: D36 idle holdoff 5s 재사용으로 swap 진동 억제.

### 2.4 `/v1/generate` 확장 (기존 분기 + Ollama 배선)

```python
@router.post("/v1/generate")
def generate(req):
    assert_allowed(req.metadata.caller)
    target = route(req)                       # 2.2 셀렉터
    lease = arbiter.ensure(target, ...)       # 2.3 보장 (없으면 409)
    if target == "ollama":
        out = ollama_client.call(req.model, req.prompt, track="B", ...)  # 기존 lib 재사용
    else:
        out = _vllm_curl(req)                 # 기존 경로
    db.log_call(..., runtime=target)          # 로깅에 runtime 1필드 추가
    return GenerateResponse(...)
```

→ **Ollama 호출 로직은 신규 작성 아님**(`lib/ollama_client.py` 그대로 배선). generate는 분기 + arbiter 2줄 추가.

### 2.5 PAB-v4 측 변경 — Ollama 직접 → Khala HTTP 클라이언트

`backend/services/ai/ollama_client.py`의 `ollama_generate`를 **Khala `/v1/generate` 호출로 교체**(thin shim):
```python
def ollama_generate(prompt, model, ...):       # 시그니처 유지 → 호출부 무변경
    r = httpx.post(f"{KHALA}/v1/generate", json={
        "prompt": prompt, "model": model, "runtime": "ollama",
        "metadata": {"caller": "pab:labeling", "request_id": ...},
        "options": {"temperature": ..., "max_tokens": ...}})
    if r.status_code == 409:                   # GpuBusy → 큐잉/표기
        raise GpuBusyRetry(r.json()["retry_after"])
    return r.json()["response"]
```
호출부(자동 라벨링·추천·reasoning 5지점)는 시그니처가 같아 **무변경**. 단 `409` 처리(배치 중 인터랙티브 양보)만 신규.

### 2.6 auth — `pab:*` caller 추가

```python
# auth.py ALLOWED_CALLERS 에 1줄
re.compile(r"^pab:[\w\-]+$"),
```

### 2.7 통합 흐름

```
[PAB-v4] ─┐
[Conductor]├─(HTTP)─▶ [Khala :8765 게이트웨이]
[SSOT]    ─┘            │ ① route(req) → target runtime
                        │ ② arbiter.ensure(target) ── (필요 시) ops shell swap (정책 B)
                        │ ③ 실행: ollama_client.call  OR  vLLM curl  OR  resumable tools
                        │ ④ db.log_call(runtime=…) + (tools면) lineage 기록
                        ▼
                  [단일 24GB GPU] — 한 시점 한 런타임만 (Khala가 보장)
```

### 2.8 구현 범위 (파일별)

| 파일 | 변경 | 신규/수정 |
|---|---|---|
| `scripts/api/lib/arbiter.py` | RuntimeArbiter(lease+single-flight+정책) | **신규(핵심)** |
| `scripts/api/lib/router.py` | route() 모델→런타임 | **신규(소)** |
| `handlers/generate.py` | runtime 분기 + arbiter + ollama 배선 | 수정(소) |
| `handlers/tools.py` | 진입 시 `arbiter.ensure("vllm")` | 수정(1줄) |
| `models.py` | `GenerateRequest.runtime` + 로그 `runtime` 필드 | 수정(소) |
| `auth.py` | `pab:*` | 수정(1줄) |
| PAB-v4 `services/ai/ollama_client.py` | Ollama SDK → Khala HTTP shim | 수정(PAB측) |

신규 인프라는 사실상 **arbiter 1개**. 나머지는 기존 부품 배선.

---

## 3. 현행 vs 통합안 비교

| 차원 | ① 현행 | ② 게이트웨이 통합안 |
|---|---|---|
| 호출 대상(관리 포인트) | **2개**(Ollama 직접 + Khala) | **1개**(Khala) |
| 런타임 선택 주체 | 클라이언트가 엔드포인트로 암묵 결정 | **Khala 셀렉터**(투명) |
| mutex 중재 위치 | 요청 경로 **밖**(대시보드·수동) | 요청 경로 **안**(arbiter 자동) |
| GPU 충돌 방지 | ⚠️ 보장 없음(사람이 사전 정렬) | ✅ 단일 리스로 구조적 보장 |
| 시간 분리 규율 | 운영자 규율(휴먼) | **코드 강제**(409+swap) |
| PAB-v4 코드 변경 | — | shim 1파일(호출부 무변경) |
| resumable/lineage 적용 | vLLM·Khala 직접 호출만 | PAB-v4 배치까지 확장 가능 |
| 멀티모델 hot-swap | ✅ 유지 | ✅ 유지(Ollama 그대로) |
| prefix-cache(vLLM) | ✅ 유지 | ✅ 유지(vLLM 그대로) |
| 관측성(로깅 일원화) | ⚠️ 분절(PAB는 Khala 로그 밖) | ✅ `db.log_call`에 전부 집계 |
| 장애 표면 | 분산(각자) | Khala 단일 → **SPOF 신설**(아래 리스크) |
| 구현 비용 | — | **arbiter 1개 + 배선**(부품 기존) |
| 엔진 통합 대비 | — | 두 엔진 강점 안 버림 |

**요약**: 통합안은 현행의 4대 문제(관리 2점·mutex 비자동·관측 분절·resumable 미적용)를 **엔진을 줄이지 않고** 해소한다. 비용은 arbiter 1개. 대신 **Khala가 모든 LLM 트래픽의 SPOF**가 되는 새 리스크가 생긴다(§4).

---

## 4. 리스크 / 트레이드오프

1. **SPOF**: Khala 다운 = PAB-v4 라벨링·reasoning까지 정지(현행은 Ollama 직접이라 독립). → 완화: PAB-v4 shim에 `KHALA_DIRECT_OLLAMA_FALLBACK` 플래그(게이트웨이 장애 시 Ollama 직타 폴백). 단 폴백 시 mutex 보장 깨짐 주의.
2. **레이턴시 추가**: 인터랙티브 라벨 요청에 Khala 1홉 + arbiter state 체크(수 ms~수십 ms) 추가. Ollama 이미 떠 있으면 `ensure`는 즉시 통과라 무시 가능.
3. **swap thrash**: 인터랙티브와 배치가 번갈아 들어오면 GPU swap(vLLM ready ~120-180s) 폭발. → 시간 분리 정책(배치는 야간/온디맨드, 주간 Ollama 상주) + hysteresis로 차단. **arbiter가 인터랙티브를 위해 배치를 선점하지 않는 것이 핵심**.
4. **동시성 락**: arbiter `_lock`은 단일 프로세스 가정. Khala가 멀티 워커(gunicorn)면 프로세스 간 락 필요(파일락/DB advisory lock). 현 단일 프로세스면 OK.
5. **auth 강도**: `pab:*` 추가는 화이트리스트 PoC 수준. LAN 노출 확대 시 API key(보고서 §6 Track B)로 진화 필요.

---

## 5. 단계적 적용

- **G0**: `auth.py` `pab:*` + `GenerateRequest.runtime`(`auto` 기본) + 로그 `runtime` 필드. (호환: 기존 vLLM 동작 불변)
- **G1**: `router.py` 셀렉터 + `generate.py`에 Ollama 분기 배선(`lib/ollama_client` 재사용). arbiter 없이 "이미 떠 있는 런타임만 사용, 불일치 시 409" 먼저.
- **G2**: `arbiter.py` — 자동 swap(정책 B)·single-flight·hysteresis. tools.py에 `ensure("vllm")`.
- **G3**: PAB-v4 shim 교체(`pab:labeling`/`pab:reasoning` caller) + 409 큐잉 처리. → 호출 surface 통합 완료.
- **G4**: PAB-v4 run-full 배치를 `/v1/tools/run` resumable로(보고서 후보 A) — 통합 게이트웨이 위에서 lineage·무손실 확보.

검증: G1까지는 기존 vLLM e2e 회귀 + Ollama generate 1건. G2는 "배치 점유 중 Ollama 409 → 배치 후 자동 복귀" 시나리오. G3는 PAB-v4 라벨링이 Khala 경유로 `db.log_call`에 남는지.
