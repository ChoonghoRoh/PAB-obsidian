---
title: "colibrì — 744B MoE를 25GB RAM PC에서 (디스크 스트리밍 MoE 런타임)"
description: "순수 C·의존성 0으로 GLM-5.2(744B MoE)를 소비자 PC에서 구동. 전문가를 디스크에서 스트리밍하고 VRAM/RAM/디스크를 하나의 메모리 계층으로 관리."
created: 2026-07-16 16:18
updated: 2026-07-16 16:18
type: "[[RESEARCH_NOTE]]"
index: "[[AI]]"
topics: ["[[LOCAL_LLM_HOSTING]]", "[[MOE_OFFLOADING]]"]
tags: [research-note, moe, local-llm, inference-engine, glm, quantization, speculative-decoding]
keywords: [colibri, GLM-5.2, MoE offloading, expert streaming, int4, MTP, MLA, DSA, KV persistence, CUDA, Metal, OpenAI-compatible]
sources: ["[[15_Sources/2026-07-16_colibri_glm52_moe_streaming_source]]", "https://github.com/JustVugg/colibri"]
aliases: ["콜리브리", "colibri 엔진", "744B MoE 로컬 구동"]
---

# colibrì — 744B MoE를 25GB RAM PC에서

**한 줄 정의**: [[GLM-5.2]](744B [[MoE]] 모델)를 **순수 C·의존성 0**으로 소비자 PC(~25GB RAM)에서 구동하는 추론 엔진. 핵심 트릭은 **전문가(expert)를 디스크에서 온디맨드 스트리밍**하고 VRAM·RAM·디스크를 단일 메모리 계층으로 관리하는 것. Apache-2.0, 2026-07-01 공개 후 ★14.5k(2026-07-16 기준).

> 관전 포인트: "느리지만 **정확하게** 답한다" — H100 팬값보다 싼 기계에서 프론티어급 744B가 돈다. 기본 정책은 절대 정밀도·라우터 의미를 몰래 바꾸지 않는다(품질 보존).

## 1. 핵심 아이디어 — 왜 25GB로 되는가
[원본 The idea →](2026-07-16_colibri_glm52_moe_streaming_source.md#the-idea)

744B MoE는 토큰당 **~40B만 활성**되고, 그중 **토큰마다 바뀌는 건 ~11GB(라우팅된 전문가)뿐**. 그래서 계층을 나눈다:
- **dense 부분**(어텐션·공유 전문가·임베딩 ~17B) → **int4로 RAM 상주(~9.9GB)**.
- **19,456개 라우팅 전문가**(75 MoE층 × 256 + MTP head, 각 ~19MB@int4) → **디스크(~370GB)에 두고 온디맨드 스트리밍**. 층별 LRU 캐시 + 옵션 pinned hot-store + OS 페이지 캐시를 공짜 L2로 활용.

엔진은 단일 C 파일(`c/glm.c`) + 소형 헤더. BLAS 없음, 런타임 Python 없음, GPU 불필요(핀 전문가용 opt-in CUDA 계층은 별도).

## 2. 정확성·품질 보존 설계
[원본 What's implemented →](2026-07-16_colibri_glm52_moe_streaming_source.md#whats-implemented)

- **충실한 GLM-5.2 forward** — `transformers` oracle 대비 토큰 단위 정확 검증(TF 32/32, greedy 20/20).
- **[[MLA]] 어텐션 + 압축 KV캐시**: 토큰당 576 float(32,768 대비 57× 축소, GLM-5.2는 64 head·GQA 없음). decode 시 weight absorption으로 per-token k/v 재구성 제거.
- **[[DSA]] 희소 어텐션**: lightning indexer, 층별 top-2048 인과 키 선택(`out-idx-*`에서 자동 감지). 전키 유지 시 dense와 토큰 단위 동일.
- **DeepSeek-V3식 sigmoid 라우터**(noaux_tc), 공유 전문가, 앞 3개 dense 층.
- **양자화 커널**: int8/int4/int2 패킹, per-row scale, AVX2 dequant-on-use. int8 컨테이너와 bit-identical 검증.
- **RAM 안전**: `MemAvailable` 기반 전문가 캐시 자동 사이징 → OOM 킬러 미발화.

## 3. MTP 추측 디코딩과 "정확하지만 바이트-비동일" 이슈
[원본 What's implemented (MTP) →](2026-07-16_colibri_glm52_moe_streaming_source.md#whats-implemented)

GLM-5.2 자체 MTP head(층 78)가 draft → 본 모델이 한 번의 batched forward로 검증.
- **head는 반드시 int8**이어야 함: int4면 accept 0–4%로 추측이 아예 안 걸림. int8이면 **39–59% accept, 2.2–2.8 tok/forward**(커뮤니티 실측 #8).
- **정확 산술상 무손실이지만 실제로는 non-speculative greedy와 바이트-비동일**(#100): 양자화 정수 커널이 shape 의존적이라 batched(S>1)/GPU forward가 단일 토큰 경로와 미세하게 다르게 반올림 → int4 GLM-5.2는 argmax 접전이라 토큰이 뒤집힐 수 있음. MTP·CUDA 전문가 계층·batched prefill이 같은 민감성을 건드리는 세 경로.
- 방출 토큰은 여전히 *유효한* forward의 argmax → 연속성은 정확. **바이트 재현성 필요 시 `DRAFT=0` (+ 커널/GPU 독립까지면 `IDOT=0 COLI_CUDA=0`)**.
- 정직한 함정: **cold 캐시**에선 검증 draft마다 전문가가 더 로드(~660→~1100/token) → 캐시/핀이 데워지기 전엔 추측이 *시간 손해*일 수 있음.
- **문법 강제 draft**(`GRAMMAR=*.gbnf`, #48): JSON/함수호출 등 제약 출력에서 유일 합법 바이트 구간을 pre-accepted draft(~1.0 accept)로 주입 — int4 head에서도 작동, 샘플링은 절대 제약 안 함(틀린 문법도 최악이 draft 기각).

## 4. 성능 실측 — "빠르지 않다, 그러나 옳다"
[원본 Honest numbers →](2026-07-16_colibri_glm52_moe_streaming_source.md#honest-numbers-wsl2-12-cores-25-gb-ram-nvme-via-vhdx)

개발 기준기(WSL2, 12코어, 25GB RAM, ~1GB/s NVMe): **cold ~0.05–0.1 tok/s**. 디스크=370GB, RAM 상주 9.9GB, 로드 ~30s, 채팅 중 peak RSS ~20GB(자동 캡). cold decode는 토큰당 ~11GB 디스크 읽기(75층×8전문가).

커뮤니티 실측(stock, greedy, --ngen 32, MTP on):

| 기계 | 설정 | 실측 |
|---|---|---|
| Intel Ultra 7 270K(24t)·WSL2·24GB(#2) | default → `--topp 0.7` | 0.07 → **0.11 tok/s** |
| Apple M5 Max·128GB unified(#4,5) | default, MTP off | **1.06 tok/s**, hit 23% |
| M5 Max·**Metal**(#72,87) | Metal·`--ram 96`·39.7GB pin | **1.83 tok/s**, hit 66%(warm) |
| M5 Max·46.9GB pin·1024-tok(#103) | Metal(experts+attn) | **2.06 tok/s**, hit 72.5% |

**속도 지렛대**: 워밍 캐시 + hot 전문가 pin + MTP. 디스크가 근본 병목이므로 **더 빠른 NVMe/더 많은 RAM/더 많은 코어**가 곧 성능 노브. 예측: PCIe5 NVMe+64GB(핀 ~40GB) ~2–4 tok/s, 128–256GB+24–32코어/VNNI ~5–15 tok/s(대화형).

## 5. 배포·운영 — 모델 획득과 CLI 워크플로
[원본 Download the model →](2026-07-16_colibri_glm52_moe_streaming_source.md#download-the-model)

- **모델**: HF `mateogrgic/GLM-5.2-colibri-int4-with-int8-mtp` (int8 MTP head 버전 필수). 원본 미러(jlnsrk)는 int4 head라 accept 0% — "왜 MTP 0%?"의 최빈 원인. `ls -l <model>/out-mtp-*`로 확인.
- **변환기**(`convert_fp8_to_int4.py`): FP8 shard를 하나씩(~5GB) 받아 dequant→int4 재양자화→삭제 → 756GB FP8 전체가 디스크에 동시에 있을 필요 없음. resumable.
- **CLI**: `coli plan`(safetensors 헤더만 읽어 배치 계획, 텐서 미할당) · `coli doctor`(read-only 준비도 점검) · `--auto-tier`(계획을 chat/run/serve/bench에 적용) · `coli bench`(MMLU/HellaSwag/ARC).
- **플랫폼**: Linux/WSL2·macOS·**Windows 11 네이티브(MinGW-w64, `compat.h` POSIX↔Win API 매핑)**. 모델은 반드시 로컬 NVMe(ext4/NTFS, 네트워크/9p 금지).

## 6. 가속 백엔드 (opt-in) — CUDA / Metal
[원본 Experimental CUDA →](2026-07-16_colibri_glm52_moe_streaming_source.md#experimental-resident-cuda-backend)

- **CUDA**(Linux): 모델 상주 텐서용. 스트리밍 전문가는 일부러 CPU 경로 유지(전문가를 매번 GPU 복사하면 디스크 병목을 PCIe 병목으로 바꿀 뿐). `PIN`/`PIN_GB`로 hot 전문가를 VRAM 상주 승격. **6×RTX 5090 + 251GiB 호스트**에서 `CUDA_EXPERT_GB=auto`+`PIN_GB=all` → 176.7GB VRAM+191.3GB RAM(전 19,456 전문가 상주) → **6.00 tok/s decode**(hit 100%, disk wait 0) — 호스트 특화 결과, 이식 기본값 아님. 한계: 독립 device 컨텍스트, 동기 host-staged 복사, P2P/NCCL 미구현, 단일 전문가 미분할.
- **Metal**(Apple Silicon): 통합 메모리로 PCIe 복사세 제거 → routed-expert SwiGLU·fused decode attention·prefill GEMM을 GPU에서. 토큰 단위 CPU와 동일. M4 Max 0.30→**0.42 tok/s(~1.4×)**.

## 7. 서빙·UI — OpenAI 호환 + 웹 대시보드
[원본 OpenAI-compatible API →](2026-07-16_colibri_glm52_moe_streaming_source.md#openai-compatible-api)

- **`coli serve`**: 텍스트 전용 OpenAI 호환 HTTP API(stdlib 게이트웨이). `/v1/chat/completions`(+SSE), `/v1/models`. 744B가 단일 프로세스 상주 → **동시 요청은 큐잉**(모델 중복 로드 안 함), bounded FIFO(`--max-queue` 8, `--queue-timeout` 300s), 포화 시 HTTP 429. `enable_thinking`/`reasoning_effort`로 reasoning 블록.
- **격리 KV 슬롯**(`--kv-slots N`, 최대 16): `cache_slot` 필드로 선택, 슬롯별 독립 히스토리·crash-safe 지속. 여전히 순차 실행 — 스레드 HTTP를 continuous batching인 척하지 않음(정직).
- **KV 지속**(`.coli_kv`): 매 턴 압축 MLA KV를 디스크 append → 재시작 시 **재-prefill 0**으로 warm 재개(byte-identical 검증).
- **웹 대시보드**(`./coli web`): 라이브 tok/s·TTFT·큐 대기, 하드웨어/전문가 계층 바, 그리고 **Brain**(76×256 cortex, 셀=전문가, 색=계층·밝기=라우팅 heat, 턴마다 라우팅된 전문가 흰색 점멸 — "모델이 생각하는 걸 본다". code/중국어/수학/법 전문가는 층 11–22에 상주).

---

## 인사이트 — Khala/PAB 관점 메모

- **정직성(honesty)이 설계 미학**: 큐잉을 "continuous batching인 척"하지 않고, 벤치도 cold/warm·페이지 캐시 오염을 명시. Khala 봉투 `model`/`runtime` **서버 사실 표기** 원칙(interop C4 §4.5)과 같은 철학 — 관찰값을 왜곡하지 않는다. → [[LOCAL_LLM_HOSTING]]
- **MoE 오프로딩 vs Khala vLLM 상주**: colibrì는 "느려도 정확·초저메모리"(디스크 스트리밍), Khala는 "`KHALA_DEFAULT_RESIDENT=vllm` 상주로 지연 최소화". 정반대 축 — 로컬 초대형 모델을 *어떻게든 돌리는* 실험 트랙으로 참고 가치. → [[MOE_OFFLOADING]] [[VLLM]]
- **OpenAI 호환 + KV 슬롯**: Khala tools/run 동시요청 A/B(wid 분리) 설계와 대비 — colibrì는 물리적 단일 KV라 슬롯으로 소유권만 명시. 동시성 한계를 솔직히 노출하는 방식이 유사.
- **바이트-비동일 재현성 이슈(#100)**: 양자화 커널 shape 의존성 → greedy 결정성 붕괴. PAB "붕괴출력" rev.7 검증 트랙에서 *재현성 보증*을 논할 때 참조할 실사례.
