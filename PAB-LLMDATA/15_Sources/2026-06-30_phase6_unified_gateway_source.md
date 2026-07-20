---
title: "PAB-Khala Phase 6 통합 게이트웨이 마스터플랜 (원문)"
description: "PAB-Khala 저장소 원본 문서 immutable 보존 — docs/phases/phase-6-master-plan.md"
created: 2026-06-30 07:58
updated: 2026-06-30 07:58
type: "[[SOURCE]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[API_GATEWAY]]", "[[GPU_MUTEX]]"]
tags: ["source", "khala", "phase6"]
keywords: ["khala", "phase6", "게이트웨이", "gpu-mutex", "arbiter", "런타임라우팅", "vllm", "ollama", "ssot", "시간분리"]
sources: ["docs/phases/phase-6-master-plan.md"]
aliases: ["phase6마스터플랜", "khala게이트웨이"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층). 원본 위치: `PAB-Khala/docs/phases/phase-6-master-plan.md`

# Phase 6 마스터 플랜 — Khala 통합 게이트웨이 (런타임 투명 + mutex 요청경로 중재)

> **버전**: 1.1 (G0 다중 페르소나 검증 반영 — arbiter v2 견고화)
> **생성일**: 2026-06-29 · **개정**: 2026-06-29 (v1.0→1.1)
> **작성 주체**: planner (PLANNING 단계)
> **표준 적용**: D18 SSOT · SSOT v8.2-renewal-6th
> **선행**: Phase 4(GPU mutex 정책 B, D36) · Phase 5(lineage/workspace 견고화, D38)
> **근거 문서**: `docs/design/20260629-khala-unified-gateway-design.md`, `docs/analysis/20260629-pab-v4-brain-khala-integration-report.md`
> **G0 검증**: `docs/analysis/20260629-phase6-persona-review.md` (동시성·보안·적대QA 3 페르소나, Blocker 2건 발견 → §4.5 반영)

> ⚠️ **v1.0→1.1 변경 요지**: §4.2 초안 arbiter는 G0 적대 검증에서 **Blocker 2건**(swap 실패 중간상태 데드락 / 배치 종료 복귀 트리거 부재) + High 다수가 입증돼 **G2 구현 불가** 판정. §4.5에 **arbiter v2(직렬 swap 워커 + 상태머신 + 복귀 watcher)** 로 견고화. §4.2는 "초안(부결)"으로 보존, **구현 기준은 §4.5**.

---

## §1 원본 프롬프트

> "결국 호출에 의해 오케스트레이션이 되려면 Ollama or vLLM 2개 중 한 개로 통합하는 게 관리는 편리할 듯한데… (분석 후) 통합안을 게이트웨이 통합안으로 설계해서 비교 진행. 통합안 정식 Khala phase로 승격, arbiter 코드 스케치 포함하여 기존 SSOT 워크플로우로 개발 진행."

**요청 분류**: 운영 아키텍처 통합 — 엔진 단일화 대신 **호출 surface + GPU 중재의 단일화**(게이트웨이).

---

## §2 배경 / 목표

단일 24GB GPU에서 vLLM↔Ollama가 mutex로 공존한다. 현행은 **호출 대상 2개**(PAB-v4→Ollama 직접, Khala→vLLM)에 **mutex가 요청 경로 밖**(대시보드·수동)이라 4대 문제를 갖는다:

1. 관리 포인트 2개(책임 경계 모호)
2. mutex 자동성 0 → 배치 중 인터랙티브가 GPU 충돌 유발 가능
3. 관측성 분절(PAB-v4 호출이 Khala 로그·lineage 밖)
4. resumable/lineage가 PAB-v4 워크로드에 미적용

**목표**: 엔진을 둘 다 유지(멀티모델·prefix-cache 강점 보존)하되, **Khala 단일 게이트웨이가 ① 런타임을 투명 선택하고 ② mutex를 요청 경로에서 중앙 중재**한다. GPU 정책 = (나) 시간 분리(보고서 §5 결정)를 **코드로 강제**.

---

## §3 범위 / 비범위

**범위 (구현)**
- 런타임 셀렉터(`route`): 모델·요청유형 → ollama|vllm
- Mutex Arbiter(`ensure`): 요청 경로 GPU 리스 + single-flight swap + 시간분리 정책(409) + hysteresis
- `/v1/generate` Ollama 분기 배선(기존 `lib/ollama_client.py` 재사용)
- `/v1/tools/run` 진입 시 vLLM 보장
- `auth.py` `pab:*` caller
- PAB-v4 측 shim(Ollama SDK 직접 → Khala HTTP, 409 양보)

**비범위 (보류)**
- 엔진 단일화(all-Ollama / all-vLLM) — 강점 손실로 미채택
- 프로세스 간 분산 락(멀티 워커) — 현 단일 프로세스 전제(Track B 후보)
- API key 인증 강화 — Phase 5 Track B(외부 진입 트리거)에 종속
- PAB-v4 run-full → resumable 전환은 **G4 이후 후속 phase**(본 phase는 게이트웨이 토대까지)

---

## §4 설계 요약 + arbiter 코드 스케치

### §4.1 런타임 셀렉터

| 입력 | 라우팅 |
|---|---|
| `runtime` 명시(`ollama`/`vllm`) | 그대로 |
| `auto` + Ollama 레지스트리 모델(`qwen3.6:27b`, `qwen2.5:7b`…) | ollama |
| `auto` + vLLM id(`qwen3.6-27b-autoround`) | vllm |
| `/v1/tools/run`(resumable·tool) | **항상 vllm 강제** (prefix-cache + 입증 tool 신뢰성, D16) |

모델→런타임 매핑은 `runtime_state.sh`가 이미 반환하는 `ollama.models`/`vllm` 목록으로 구성(신규 레지스트리 파일 불필요).

### §4.2 Mutex Arbiter — 코드 스케치 (v1.0 초안 · **G0 부결 — §4.5로 대체**)

> ⚠️ 본 §4.2는 G0 페르소나 검증에서 Blocker 2건+High 다수가 입증돼 **구현 기준이 아니다**(역사 보존용). 결함 목록·근거는 `docs/analysis/20260629-phase6-persona-review.md` §1, 견고화 설계는 §4.5 참조.

위치(신규): `scripts/api/lib/arbiter.py`. 기존 `ops/*.sh`(`runtime_state.sh`/`vllm_run.sh`/`ollama_run.sh`/`open_webui_stop.sh`/`ollama_unload.sh`)를 재사용하는 얇은 조정 계층.

```python
# scripts/api/lib/arbiter.py  (스케치 — Phase 6 G2 구현 대상)
from __future__ import annotations
import json, subprocess, threading, time
from dataclasses import dataclass
from pathlib import Path
from fastapi import HTTPException

OPS = Path(__file__).resolve().parents[1] / "ops"   # ops.py 의 _resolve_ops_dir 규칙 공유
IDLE_HOLDOFF_SEC = 5         # D36 발견 8(R-41-11) 재사용 — swap 진동 억제
SWAP_LOCK_TIMEOUT = 200      # vLLM ready ~120-180s 여유

@dataclass
class Lease:
    runtime: str             # "ollama" | "vllm"
    owner: str               # caller (예: "pab:labeling", "khala-self:batch")
    acquired_at: float

class GpuBusy(HTTPException):
    def __init__(self, active: str, eta: float):
        super().__init__(status_code=409, detail={
            "status": "error", "error_code": "gpu_busy",
            "error_message": f"GPU leased by {active}", "retry_after": round(eta, 1),
        })

def _ops(script: str, *args: str, timeout: int = 180, env: dict | None = None) -> dict:
    res = subprocess.run(["bash", str(OPS / script), *args],
                         capture_output=True, text=True, timeout=timeout,
                         env={**__import__("os").environ, **(env or {})})
    if res.returncode != 0:
        raise HTTPException(status_code=502, detail={
            "status": "error", "error_code": "ops_failed",
            "message": (res.stderr or res.stdout)[-400:]})
    return json.loads(res.stdout) if res.stdout.strip() else {}

def _state() -> dict:
    return _ops("runtime_state.sh", timeout=20)   # SSOT: 활성 런타임·busy 신호

def _active(state: dict) -> str | None:
    if state.get("vllm", {}).get("state") not in (None, "off"):
        return "vllm"
    oll = state.get("ollama", {})
    if oll.get("loaded"):                          # 적재 모델 있으면 ollama 활성
        return "ollama"
    return None                                    # idle (둘 다 비점유)

def _ollama_busy(state: dict) -> bool:
    # D36 운영 표준: ollama_state BUSY 우선 + ss/util 신호 (runtime_state.sh 가 반환)
    return state.get("ollama", {}).get("state") == "busy"

class RuntimeArbiter:
    """단일 GPU 리스 — 요청 경로에서 '필요한 런타임'을 보장. 시간 분리 정책 강제."""
    _lock = threading.Lock()         # single-flight: 동시 swap 직렬화 (단일 프로세스 전제)
    _current: Lease | None = None

    def ensure(self, target: str, *, owner: str) -> Lease:
        st = _state()
        active = _active(st)
        if active == target:                       # ① 이미 맞음 → 즉시 통과
            return Lease(target, owner, time.time())

        with self._lock:                           # ② 전환은 한 번에 하나
            st = _state(); active = _active(st)
            if active == target:
                return Lease(target, owner, time.time())

            # ③ 시간 분리 정책 — 배치(vLLM) 우선권 보호, 인터랙티브(ollama) 양보
            if active == "vllm" and target == "ollama":
                # vLLM 배치 점유 중 인터랙티브 요청 → 양보(선점 금지). PAB-v4 가 큐잉/표기.
                raise GpuBusy("vllm", eta=self._eta(st))
            if active == "ollama" and _ollama_busy(st) and target == "vllm":
                # Ollama 가 실제 작업 중이면 배치 진입 대기(thrash 방지)
                raise GpuBusy("ollama", eta=IDLE_HOLDOFF_SEC)

            # ④ swap 수행 (정책 B). active idle 이거나 양보 대상 아님 → 전환 허용
            self._swap_to(target, owner)
            return self._current

    def _swap_to(self, target: str, owner: str) -> None:
        if target == "vllm":
            _ops("open_webui_stop.sh", timeout=30)         # 정책 B: 채팅 차단
            st = _state()
            for m in (st.get("ollama", {}).get("loaded") or []):
                _ops("ollama_unload.sh", m["name"] if isinstance(m, dict) else m, timeout=60)
            time.sleep(IDLE_HOLDOFF_SEC)                    # hysteresis
            _ops("vllm_run.sh", timeout=SWAP_LOCK_TIMEOUT)  # ready polling 포함
        else:  # ollama
            _ops("vllm_stop.sh", timeout=30)
            _ops("ollama_run.sh", timeout=120)              # 기본 모델 적재
        self._current = Lease(target, owner, time.time())

    @staticmethod
    def _eta(state: dict) -> float:
        # 배치 잔여 추정(미상이면 보수적 상한). G3 에서 _runs.jsonl 진행으로 정밀화.
        return float(state.get("vllm", {}).get("eta_sec", 120))

ARBITER = RuntimeArbiter()
```

### §4.3 `/v1/generate` · `/v1/tools/run` 배선

```python
# handlers/generate.py (수정)
target = route(req)                          # §4.1
ARBITER.ensure(target, owner=req.metadata.caller)   # 없으면 409 GpuBusy
if target == "ollama":
    out = ollama_client.call(req.model, req.prompt, track="B",
                             temperature=req.options.temperature)   # 기존 lib 재사용
    content, pt, ct = out["output"], out["prompt_tokens"], out["completion_tokens"]
else:
    content, pt, ct = _vllm_curl(req)        # 기존 경로 추출
db.log_call(..., runtime=target)             # 로그에 runtime 1필드 추가
```
```python
# handlers/tools.py (수정 — 1줄)
ARBITER.ensure("vllm", owner=req.metadata.caller)   # resumable 은 항상 vLLM
```

### §4.4 PAB-v4 shim

`backend/services/ai/ollama_client.py::ollama_generate` 를 Khala `/v1/generate`(`runtime:"ollama"`, caller `pab:labeling`) 호출로 교체. 시그니처 유지 → 호출부 5지점 무변경.

> G0 정정(Q-7): `409 gpu_busy`/`503` 수신 시 "큐잉"은 **현재 미구현 표현** → 정확히는 **클라이언트 멱등 재시도(지수 백오프+jitter)**. 라벨링 배치(후보 B)는 문서별 seq dedup로 **부분상태/중복 라벨 방지**가 필수 → **T-6-2(shim) 선결조건**으로 명문화. `DIRECT_OLLAMA_FALLBACK`은 mutex 우회 백도어(S-3)라 **기본 미채택**(도입 시 `gpu/state` vLLM-off 가드 강제).

### §4.5 Mutex Arbiter v2 — 견고화 (G0 페르소나 반영 · **구현 기준**)

> G0 검증 결함(§persona-review §1)은 두 근원으로 수렴: ① 요청구동+락내 장시간 swap(C-1·C-2·C-4·C-5·Q-1), ② 복귀/시간창 트리거 부재(Q-2·Q-3·Q-8). v2는 **전용 직렬 swap 워커 + 상태머신 + 복귀 watcher**로 둘을 동시 해소.

#### §4.5.1 핵심 구조

- **직렬 swap 워커(단일 스레드 큐)**: 모든 GPU 전환을 한 워커가 소유. `arbiter.ensure()`와 **기존 `/v1/admin/*` ops 엔드포인트 둘 다 이 큐에 enqueue**(C-5 해소). 요청은 락을 길게 잡지 않음.
- **상태머신**: `STABLE(runtime)` / `SWAPPING(from→to)` / `UNKNOWN`. in-memory, 워커만 갱신. 읽기는 무락.
- **블록 금지**: 요청은 ① 현재 런타임==target이고 ready면 즉시 통과, ② `SWAPPING`이면 `503{transition, retry_after}`, ③ 정상 점유(상대 busy)면 `409{gpu_busy, retry_after}`. **누구도 락에서 200초 대기하지 않음**(C-1·C-2 해소 → threadpool 보존).
- **swap = 셸 한 줄 위임**: `_do_swap`은 `vllm_run.sh` / `ollama_run.sh`를 **그대로 1회 호출**(busy-wait·holdoff·open-webui-stop·unload·ready-poll은 셸이 이미 보유 — 파이썬 재구현/가드누락 금지, C-3 해소).
- **원자성+롤백**: swap 실패 시 워커가 **직전 안정 런타임으로 복원**(`ollama_run.sh`+`open_webui_run.sh`) 후 에러 표면화. `vllm_stop already_off`(exit4)는 성공으로 흡수(Q-1 해소).
- **idle/busy 구분 + ready-gating**: `_active`는 `_common.sh::vllm_is_busy`/`ollama_is_busy` 사용. idle vLLM은 swap 가능. `starting`은 active 아님 → ready 확인 후 통과(Q-3·Q-4 해소).
- **명시적 복귀 트리거**: 워커 내 idle-TTL watcher — `vllm_is_busy()==false`가 `RESTORE_TTL`(기본 60s) 지속 시 **기본 상주 런타임(ollama)로 자동 복귀** enqueue. + `tools.py:finally`가 배치 종료 release 신호(Q-2 해소). → P6-02 "수동 0" 비로소 실증 가능.
- **caller→target 권한 + 시간창**: 파괴적 vLLM swap(open-webui stop 포함)은 `khala-self:*`/지정 배치 owner 또는 배치 시간창에서만. 주간 `pab:*` tools 요청은 `409{batch_window_only}`. 인터랙티브 `pab:*` generate는 ollama만(S-1·Q-8 해소).
- **cooldown + jitter**: 마지막 swap 후 `SWAP_COOLDOWN` 내 역방향 swap은 409. `retry_after`에 jitter+상한. `eta`는 산출 불가 구간 명시(고정 120 허수 금지, Q-5 해소).

#### §4.5.2 코드 스케치 (구현 기준)

```python
# scripts/api/lib/arbiter.py  (v2 — Phase 6 G2 구현 기준)
import queue, threading, time, random
from dataclasses import dataclass
from enum import Enum

class GpuState(Enum): STABLE="stable"; SWAPPING="swapping"; UNKNOWN="unknown"
DEFAULT_RESIDENT = "ollama"        # 주간 인터랙티브 상주
RESTORE_TTL = 60                   # vLLM idle 지속 시 ollama 자동 복귀
SWAP_COOLDOWN = 15                 # 역방향 swap 최소 간격 (thrash 차단)

DESTRUCTIVE_OK = lambda owner: owner.startswith("khala-self:") or owner.endswith(":batch")

@dataclass
class _Status:
    state: GpuState; runtime: str | None; since: float; last_swap: float

class SwapError(Exception): ...

class RuntimeArbiter:
    """단일 직렬 swap 워커. ensure()와 admin ops 둘 다 enqueue. 요청은 블록하지 않음."""
    def __init__(self):
        self._q: queue.Queue = queue.Queue()
        self._st = _Status(GpuState.UNKNOWN, None, time.time(), 0.0)
        self._lk = threading.Lock()                 # _st 갱신 보호 (짧게만)
        threading.Thread(target=self._worker, daemon=True).start()

    # ── 요청 경로: 블록 금지, 즉시 판정 ──
    def ensure(self, target: str, *, owner: str) -> None:
        st = self._snapshot()                       # 무락 읽기
        if st.state is GpuState.SWAPPING:
            raise GpuBusy503(eta=self._eta())
        active = self._active_runtime()             # _common.sh idle/busy 반영 + ready
        if active == target:
            return                                  # ① 이미 맞고 ready → 통과
        # ② 전환 필요 — 정책 검사 후 enqueue, 본인은 409 (블록 안 함)
        if target == "vllm" and not DESTRUCTIVE_OK(owner) and not self._in_batch_window():
            raise GpuBusy409(reason="batch_window_only", eta=self._eta())
        if self._busy(active) :                     # 상대가 실제 작업 중 → 양보
            raise GpuBusy409(reason="gpu_busy", eta=self._eta())
        if time.time() - st.last_swap < SWAP_COOLDOWN:
            raise GpuBusy409(reason="cooldown", eta=SWAP_COOLDOWN)
        self._enqueue_swap(target, owner)           # 워커가 처리
        raise GpuBusy503(reason="transition_started", eta=self._eta())

    def admin_swap(self, target: str, *, owner: str) -> None:
        self._enqueue_swap(target, owner)           # 대시보드 수동 swap도 같은 큐 (C-5)

    def _enqueue_swap(self, target, owner):
        with self._lk:
            if self._st.state is GpuState.SWAPPING:  # 이미 전환 중 → 중복 enqueue 무시(single-flight)
                return
            self._st = _Status(GpuState.SWAPPING, self._st.runtime, time.time(), self._st.last_swap)
        self._q.put((target, owner))

    # ── 워커: 직렬 처리 + 롤백 + idle-TTL 복귀 ──
    def _worker(self):
        self._st = _Status(GpuState.STABLE, self._active_runtime(), time.time(), 0.0)
        while True:
            try:
                target, owner = self._q.get(timeout=RESTORE_TTL)
                self._do_swap(target, owner)
            except queue.Empty:                      # idle-TTL 만료 → 복귀 검사 (Q-2)
                if (self._st.runtime == "vllm" and not self._busy("vllm")
                        and self._st.runtime != DEFAULT_RESIDENT):
                    self._q.put((DEFAULT_RESIDENT, "khala-self:restore"))

    def _do_swap(self, target, owner):
        prev = self._st.runtime
        try:
            ops_run(f"{target}_run.sh")              # 셸 한 줄 위임 — 가드는 셸이 보유 (C-3)
            self._set_stable(target)
        except Exception as e:                       # 롤백 (Q-1)
            try:
                ops_run(f"{DEFAULT_RESIDENT}_run.sh"); ops_run("open_webui_run.sh")
                self._set_stable(DEFAULT_RESIDENT)
            finally:
                self._set_unknown()
            raise SwapError(f"swap→{target} 실패, {DEFAULT_RESIDENT} 복원: {e}")

    def _set_stable(self, rt): 
        with self._lk: self._st = _Status(GpuState.STABLE, rt, time.time(), time.time())
    # _snapshot/_active_runtime/_busy/_in_batch_window/_eta: _common.sh·runtime_state.sh 배선
ARBITER = RuntimeArbiter()
```

> 미해결 한계(정직성): `_eta` 정밀화는 G3에서 vLLM `num_requests_waiting`/배치 시작시각 기반(현재는 "추정 불가" 표기). 멀티워커 분산락은 Track B. `--workers>1` fail-fast 가드는 G1에 포함.

| 게이트 | 단계 | 태스크 | 산출물 |
|---|---|---|---|
| **G0** | RESEARCH REVIEW | T-6-1-0: 설계·보고서 2종 검토 승인(현행 분석·비교·리스크 SPOF/thrash 타당성) | 본 master-plan 승인 |
| **G1** | DEV: 스키마/auth/가드 | T-6-1-1: `auth.py` `pab:*` + `GenerateRequest.runtime`(`auto` 기본) + 로그 `runtime` 필드 + **`/v1/tools/lineage` `assert_allowed`(S-5)** + **`--workers>1` fail-fast 가드(C-6)**. **기존 vLLM 동작 불변(회귀 0)** | models.py/auth.py/tools.py/main.py |
| **G1** | DEV: 셀렉터+배선 | T-6-1-2: `lib/router.py` route() + `generate.py` Ollama 분기(`lib/ollama_client` 재사용). arbiter 없이 "떠 있는 런타임만, 불일치 409" 먼저 | router.py/generate.py |
| **G2** | DEV: arbiter v2 | T-6-1-3: `lib/arbiter.py`(**§4.5**) — 직렬 swap 워커 + 상태머신 + 롤백 + idle-TTL 복귀 watcher + idle/busy 구분 + caller→target 권한 + cooldown. tools.py `ensure("vllm")` + `finally` release. **admin ops도 같은 큐 경유(C-5)** | arbiter.py/tools.py/ops.py |
| **G3** | VALIDATION: e2e | T-6-1-4: 시나리오 매트릭스(아래) 실행 + KPI 측정. 로그 3800x→repo 복사 | phase-6-1-status, 로그 |
| **G4** | FINAL | T-6-1-5: summary + decision_d39 + MEMORY 인덱스. PAB-v4 shim(T-6-2)은 후속 sub-phase로 분기 | final-summary, D39 |

### 시나리오 매트릭스 (G3) — G0 반영 (S6·S7 추가)

| ID | 시나리오 | 자동화 | KPI |
|---|---|---|---|
| S1 | `runtime:vllm` generate (회귀) | 가능 | P6-05 |
| S2 | `runtime:ollama` generate (신규 배선) → `db.log_call(runtime=ollama)` | 가능 | P6-01 |
| S3 | Ollama 활성 중 vLLM 요청(배치 owner) → 자동 swap(정책 B) → 응답 | 가능 | P6-02 |
| S4 | vLLM **busy** 점유 중 Ollama 요청 → `409 gpu_busy` (선점 0). vLLM **idle** 중 Ollama 요청 → swap 허용(과잉차단 0) | 배경 curl | P6-03 |
| S5 | 전환 중 다중 요청 → 즉시 `503`(블록 0, <1s) + 중복 swap 0 | 배경 병렬 | P6-04 |
| **S6** | **swap 실패 주입**(`vllm_run.sh` 강제 실패) → 직전 안정 런타임 자동 복원 + 503, GPU 고아 0 | 실패 주입 | **P6-07** |
| **S7** | **배치 종료** → `RESTORE_TTL` 내 Ollama 자동 복귀 + 후속 ollama 요청 200 (수동 swap 0) | 가능 | **P6-08** |

---

## §6 KPI

| KPI | 지표 | to-be | 측정 |
|---|---|---|---|
| P6-01 | 런타임 투명 | `runtime:ollama`/`vllm`/`auto` 모두 정확 라우팅 + 로그 runtime 일치 | S1·S2 |
| P6-02 | mutex 자동 중재 | 불일치 런타임 요청 시 정책 B swap 자동 완료(수동 0) | S3 |
| P6-03 | 시간 분리 강제 | 배치 점유 중 인터랙티브 = 409, **배치 선점 0** | S4 |
| P6-04 | single-flight | 동시 swap 트리거 시 실제 swap 1회(중복 0) | S5 |
| P6-05 | 회귀 | 기존 vLLM generate/tools/resumable/lineage e2e 유지 | S1 + Phase 5 재실행 |
| P6-06 | 관측성 | 모든 generate 호출(ollama 포함)이 `db.log_call`에 runtime 포함 적재 | S2 |
| **P6-07** | **swap 실패 복원** | vLLM 기동 실패 시 **GPU 고아 0** + 직전 안정 런타임 복원 + 데드락 0 | **S6** |
| **P6-08** | **복귀 자동성** | 배치 종료 후 `RESTORE_TTL` 내 Ollama 자동 복귀, **수동 swap 0** | **S7** |

---

## §7 리스크 / 트레이드오프 (G0 페르소나 검증 반영)

> 정정(v1.1): v1.0 §7-3의 "단일 프로세스면 동시성 OK" 서술은 **부정확**. C-1~C-5는 **워커 1개에서도** 발생(sync 핸들러 threadpool·TOCTOU·이중 swap 경로·admin 충돌). §4.5 v2가 직렬 워커로 해소.

1. **SPOF**: Khala 다운 = PAB-v4 LLM까지 정지. 완화 = **supervisor 자동재시작 + PAB-v4 멱등 재시도**(mutex 불변식 유지). `DIRECT_OLLAMA_FALLBACK`은 **mutex 우회 백도어**(S-3)라 채택 보류 — 도입 시 `gpu/state`로 vLLM off 확인 가드 필수. 본 phase는 게이트웨이 토대까지, shim은 후속(T-6-2).
2. **swap thrash/라이브락**: 교번 swap 폭발. 차단 = §4.5 **SWAP_COOLDOWN 게이트 + 시간창 + idle/busy 구분 + 배치 선점 금지**(P6-03). 시간 분리는 운영 규율이 아니라 **코드 강제**(주간 `pab:*` vLLM swap = 409).
3. **swap 실패 중간상태(Blocker, Q-1)**: §4.5 워커 롤백 + `already_off` 흡수 + 상태머신으로 해소(P6-07). 데드락 방지.
4. **복귀 트리거(Blocker, Q-2)**: §4.5 idle-TTL watcher + 배치 release로 자동 복귀(P6-08). 미반영 시 P6-02 거짓.
5. **단일 프로세스 락 전제**: §4.5 워커도 in-process. **G1에 `--workers>1` fail-fast 가드 + systemd `--workers 1` 명시** 포함. 멀티워커 분산락(flock/pg_advisory)은 Track B.
6. **eta 정밀도**: 현재 `runtime_state.sh`에 `eta_sec` 부재(Q-5) → retry_after는 "추정 불가" 명시 + jitter. G3에서 vLLM `num_requests_waiting`/배치시작시각 기반 산출.
7. **auth/lineage**: `pab:*`는 화이트리스트 PoC(외부 시 API key=Track B). 단 **`/v1/tools/lineage` 조회 무인증(S-5)은 회귀성 결함 → G1에 `assert_allowed` 추가**(저비용·내부망에서도 적용).
8. **권한 상승(S-1)**: 낮은 caller가 파괴적 swap(open-webui stop) 간접 트리거 → §4.5 caller→target 권한 매트릭스로 제한.

---

## §8 실행 순서

1. **G0**: 본 master-plan v1.1 + 설계/보고서 + **페르소나 검증(persona-review)** 사용자 재승인.
2. **G1**: T-6-1-1(스키마/auth/lineage인증/워커가드, 회귀 0) → T-6-1-2(셀렉터+Ollama 배선, arbiter 전 단계).
3. **G2**: T-6-1-3(arbiter **v2** §4.5 — 직렬 워커+상태머신+롤백+복귀 watcher).
4. 3800x 배포(드리프트 점검 → scp → restart).
5. **G3**: S1~S7 e2e + P6-01~08 KPI 측정(특히 **S6 실패주입·S7 복귀**) → 로그 repo 복사.
6. **G4**: summary + D39 + MEMORY. PAB-v4 shim(T-6-2)·run-full resumable(보고서 후보 A)은 후속 sub-phase로 승격.

> G1 착수는 G0 승인 후. 본 문서는 "phase 승격" 산출물이며 arbiter **구현 기준은 §4.5 v2**(§4.2는 부결 초안 보존).

---

## §9 G0 페르소나 검증 판정

`docs/analysis/20260629-phase6-persona-review.md` — 동시성·보안·적대QA 3 페르소나 독립 검증.

- **판정**: v1.0 arbiter(§4.2) **G2 구현 불가** — Blocker 2건(Q-1 swap 실패 데드락 / Q-2 복귀 트리거 부재) + High 다수 입증.
- **반영**: §4.5 arbiter v2(직렬 워커+상태머신+롤백+복귀 watcher+idle/busy+권한+cooldown) + S6/S7·P6-07/08 + §7 정정. G1에 lineage 인증·워커 가드 추가.
- **과장 배제**(Phase 5 교훈): 명령주입(S-4) 기각, "단일 프로세스=동시성 OK" 정정, 권한상승(S-1)은 정책제약형으로 한정.
- **Track B 유지**(외부 트리거): API key 인증, prompt 집적 마스킹/TTL, 분산 락 본구현, swap 악의적 증폭 방어.
- **재승인 필요**: v1.1은 결함 반영본. G1 착수 전 사용자 G0 재승인.
