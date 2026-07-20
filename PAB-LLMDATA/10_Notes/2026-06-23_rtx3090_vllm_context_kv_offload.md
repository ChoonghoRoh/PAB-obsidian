---
title: "vLLM 컨텍스트 확장 핵심 진단 — 엔진 KV캐시 vs 앱 외부기억 2층위 (RTX3090)"
description: "RTX3090 NVMe·RAM 컨텍스트 보고서 비판적 진단 — 보고서 3전략은 모두 앱 레이어. vLLM 엔진의 KV캐시 오프로딩(APC/swap/LMCache)이 누락. 둘을 결합해야 '사실상 무한 컨텍스트'가 완성됨."
created: 2026-06-23 22:49
updated: 2026-06-23 22:49
type: "[[RESEARCH_NOTE]]"
index: "[[AI]]"
topics: ["[[VLLM]]", "[[KV_CACHE]]", "[[CONTEXT_WINDOW]]"]
tags: [research-note, vllm, kv-cache, context-window, prefix-caching, lmcache, rtx3090, khala]
keywords: [vLLM, KV cache offload, prefix caching, APC, LMCache, swap-space, max_position_embeddings, RoPE, YaRN, Custom Python Loop, workspace, Khala, tool_loop_openai]
sources: ["[[15_Sources/2026-06-23_rtx3090_vllm_context_kv_offload_source]]", "PAB-Khala/docs/analysis/20260633-RTX3090_컨텍스트_확장_전략_보고서.md"]
aliases: ["vLLM 컨텍스트 확장 진단", "KV캐시 2층위", "엔진 vs 앱 컨텍스트"]
---

# vLLM 컨텍스트 확장 핵심 진단 — 엔진 KV캐시 vs 앱 외부기억 2층위

> 원본 [[15_Sources/2026-06-23_rtx3090_vllm_context_kv_offload_source|RTX3090 NVMe·RAM 컨텍스트 보고서]]에 대한 비판적 진단. 보고서 방향은 옳으나 [[vLLM]] 관점에서 중요한 **층위 구분**이 빠져 있다.

## 핵심 진단: 컨텍스트 확장은 서로 다른 두 층위다
[원본 §개요 →](2026-06-23_rtx3090_vllm_context_kv_offload_source.md#개요)

보고서의 세 전략([[Letta]] / [[CrewAI]] / Custom Loop)은 **전부 앱 레이어(애플리케이션 레벨 외부 기억)** 다. 모델의 컨텍스트 윈도우 자체는 그대로 두고(예: 32K), NVMe·RAM에는 "요약본·워크스페이스 파일"을 둔다. 모델이 한 번에 보는 토큰 수는 늘지 않는다.

그런데 [[vLLM]]에는 보고서 철학("VRAM=캐시, NVMe·RAM=영속")을 **엔진 레벨에서 진짜로 구현하는 기능**이 따로 있다. 이게 빠지면 반쪽짜리다.

| 층위 | NVMe·RAM에 두는 것 | 효과 | 보고서 |
|---|---|---|---|
| **엔진 레이어 ([[KV_CACHE]])** | 모델의 KV cache 블록 | 긴 프롬프트·툴정의 **재계산 제거**, 동시 긴-컨텍스트 수용량 ↑ | ❌ 누락 |
| **앱 레이어 (외부 기억)** | 요약·워크스페이스 .md | 윈도우를 **논리적으로 무한** 연장, OOM 복원 | ✅ 3전략 |

## 솔직한 한계 — 단일 시퀀스는 max_position_embeddings를 못 넘는다
[원본 §개요 →](2026-06-23_rtx3090_vllm_context_kv_offload_source.md#개요)

NVMe에 KV를 오프로드해도 단일 시퀀스가 모델의 `max_position_embeddings`(RoPE/YaRN 한계, Qwen 계열 32K~128K)를 넘진 못한다. 즉 **"무한히 이어가기"는 결국 앱 레이어가 반드시 필요**하다. 엔진 레이어는 그걸 *싸고 빠르게* 만들어주는 보완재다. 두 층을 결합해야 보고서가 말한 "사실상 무한 컨텍스트"가 완성된다.

## Tier 1 — 엔진 레이어 (vLLM 자체 기능)
[원본 §1 →](2026-06-23_rtx3090_vllm_context_kv_offload_source.md#1-memgpt현-letta--os-메모리-페이징-기법-차용)

club-3090(24GB)에서 바로 켤 수 있는 순서:

1. **Automatic Prefix Caching** — `--enable-prefix-caching`. 시스템 프롬프트 + 툴 정의(긴 JSON schema)가 매 요청 반복되는데, APC가 prefix KV를 재사용해 TTFT 대폭 단축. 비용 0, 효과 즉시. **최우선.**
2. **CPU swap space** — `--swap-space 16`. KV가 VRAM 초과 시 preemption된 시퀀스를 RAM으로 스왑. OOM 강제종료 대신 우아한 처리. GPU mutex 환경과 부합.
3. **[[LMCache]] 통합** — KV cache를 VRAM→RAM→NVMe 계층적 오프로드 + 요청 간 재사용. vLLM production-stack 공식 통합. 보고서의 "NVMe를 외부 기억으로" 철학의 엔진-레벨 정답. 도입 복잡도 있으니 APC 효과 측정 후 단계적 도입.

> ### ⚠️ 실측 정정 (2026-06-24, 3800x 직접 점검)
> 위 Tier 1 제안은 **현행 스택을 과소평가**했다. `vllm-qwen36-27b-long-text`는 `club-3090` + **Genesis 패치 + TurboQuant 3-bit KV** 커스텀 빌드이고, docker **compose**로 관리된다(`docker run` 재구성은 멀티라인 entrypoint·MTP JSON 인자·Genesis 패치 볼륨을 깨뜨려 부적합 → 작성했던 `vllm_create.sh` 철회).
> 실제 인자: `--max-model-len 32768`(파일엔 변종별 48K/75K/180K/214K) · `--gpu-memory-utilization 0.90` · `--kv-cache-dtype turboquant_3bit_nc`(fp8보다 더 압축) · `--enable-prefix-caching` ✅ · `--enable-chunked-prefill` ✅ · `--max-num-seqs 1` · MTP n=3.
> 결론: **엔진 레이어는 이미 정점.** 내가 더할 것이 없다 — APC/chunked-prefill 이미 on, KV는 3-bit로 fp8보다 압축적, `--swap-space`는 `max-num-seqs=1`이라 preemption 대상이 없어 무의미, `--max-model-len` 상향은 문서화된 OOM cliff(Cliff 2/2b)에 막힘.
> **진짜 레버 = 컴포즈 변종 선택**(이미 club-3090이 워크로드별로 튜닝): `long-text.yml`(214K)는 **tool-schema/IDE-agent 워크로드에 안전하지 않음**(Cliff 2b) → Khala 툴콜링은 **`tools-text.yml`(75K + fp8 KV + PN8)** 또는 default(48K)를 써야 한다. 이는 [[decision_d16_tools_text_breakthrough|D16 tools-text]] 발견과 정확히 일치. 변종 전환은 운영 결정 → 사용자 판단 영역.

## Tier 2 — 앱 레이어 (보고서 3전략 Khala 적합도)
[원본 §3 →](2026-06-23_rtx3090_vllm_context_kv_offload_source.md#3-custom-python-loop--가장-빠르고-직관적인-워크스페이스-패턴)

**Custom Python Loop가 [[Khala]]엔 이미 절반 구현돼 있다.** 보고서 권고("Loop로 시작 → 나중에 Letta")와 일치.

- **Custom Python Loop ✅ 채택** — `tool_loop_openai()`(`openai_chat.py`)가 이미 OpenAI 호환 루프 엔진. 여기에 `workspace.md` 패턴(NVMe 상태 저장 + `<WORKSPACE>` 태그 파싱)을 **새 도구(`workspace_read`/`workspace_write`)로 추가**하면 됨. 기존 화이트리스트(`tools.py`)에 끼워 넣는 작업이라 신규 인프라 거의 없음. OOM/mutex swap으로 끊겨도 재개 가능 → mutex 정책 B와 궁합.
- **[[Letta]]** ⏭ 후속 — 자율 장기기억이 실제 필요해지는 시점에. 지금은 YAGNI.
- **[[CrewAI]]/AutoGen** ⚠ — Khala 자체가 이미 오케스트레이터라 역할 중복. 프레임워크 도입보다 Khala workflow에 릴레이 단계를 직접 넣는 게 일관적.

## 권장 실행 순서
[원본 §결론 →](2026-06-23_rtx3090_vllm_context_kv_offload_source.md#결론-및-권장-사항)

| 단계 | 작업 | 비용 | 위치 |
|---|---|---|---|
| 1 | `vllm_run.sh`에 `--enable-prefix-caching` + `--swap-space` 추가 | 거의 0 | `scripts/ops/vllm_run.sh` |
| 2 | 툴콜 루프 전후 TTFT/throughput 측정 (효과 검증) | 측정만 | — |
| 3 | `workspace_read/write` 도구 + `<WORKSPACE>` 체크포인트 패턴 추가 | 소 | `tools.py` + lib |
| 4 | (필요 시) [[LMCache]] 도입 | 중 | 별도 sub-phase |

핵심 한 줄: **Tier 1(엔진)으로 "반복 prefix를 싸게", Tier 2(앱 워크스페이스)로 "윈도우를 무한히" — 둘을 합쳐야 '사실상 무한 컨텍스트'가 완성된다.**

## ✅ 라이브 실증 + 체인 재점검 (2026-06-24, 3800x tools-text 기동)

**기동:** GPU mutex 정책 B(open-webui stop + ollama unload, VRAM 23.2GB→9MiB) → `docker-compose.tools-text.yml` up (`MAX_MODEL_LEN=24576` env 오버라이드, .env 불변). 75K/0.97 기본은 .env가 32768/0.90으로 캡 → 0.90 예산에선 KV 1.73GB뿐이라 32768 부팅 실패(추정 최대 28800) → 24576로 부팅 성공. served `qwen3.6-27b-autoround`, fp8_e5m2 KV.

**무손실 재개 e2e (Khala `/v1/tools/run`):**
1. 1차 `max_iter=2` → `status=max_iter, resumable=true, workflow_id=tools-run-1782308867`. `workspace_read→workspace_write`로 섹션1을 **NVMe**(`~/khala-data/tools_run/<wid>/workspace.md`, 1775B)에 적재 + autosave note(3699B) + checkpoint `iter_1`.
2. 2차 동일 `workflow_id` + `resume=true` → 핸들러가 `workspace_read`로 직전 상태를 system에 seed → 모델이 **재시작 없이 섹션2로 이어감** → `status=ok`, workspace 1775→3662B. ← **무손실 재개 입증.**

**측정된 Tier 1 기여:** vLLM `/metrics` — `prefix_cache_hits_total/queries_total = 1600/6825 = 23%`. 반복 prefix(system+tools schema+누적 메시지)의 KV를 fp8로 재사용(재계산 제거). 단 `external_prefix_cache_hits=0` / `kv_offloading_backend=native` → **엔진 KV의 RAM/NVMe 오프로드는 미적용** = LMCache(T1-4)의 정확한 빈자리.

### 작동하는 체인 (오늘 실증)
```
HTTP req ─▶ [Tier1 엔진] prefix-cache가 system+tools prefix KV 재사용(fp8 VRAM, 23% hit)
        ─▶ tool_loop_openai ─▶ workspace_write
        ─▶ [Tier2 SW] NVMe workspace.md + autosave(note/checkpoint)
        ─▶ max_iter ─▶ resumable=true
        ─▶ resume req ─▶ workspace_read가 NVMe 상태를 system에 seed ─▶ 이어서 진행 ─▶ status=ok
```

### 재점검 결론 — 더 "의미있는 결과"로 가는 2 레버
1. **엔진 KV → RAM/NVMe (Tier1 빈자리):** 현재 `external_prefix_cache=0`. [[LMCache]] 또는 vLLM KV connector로 prefix KV를 RAM/NVMe에 영속하면, **컨테이너 재시작·요청 간에도 prefix 재계산 0** (RAG·고정 system+tools 워크로드에 직접 이득). 이것이 보고서가 말한 "NVMe를 외부 기억으로"의 엔진-레벨 실현. `max-num-seqs=1`이라 preemption swap 이득은 여전히 작음.
2. **SW 산출물 종단 (Tier2):** workspace.md(NVMe)는 이미 영속 산출물. 명명된 deliverable(`save_file`)까지 강제하려면 `tool_loop_openai`가 `tool_choice`를 전달/강제하도록 보강 필요(현재 auto → 모델이 본문 답변 택하면 도구 미호출). e2e 3차에서 이 한계 관측.
