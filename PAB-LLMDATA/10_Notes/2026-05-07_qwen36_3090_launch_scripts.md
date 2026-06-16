---
title: "Qwen3.6 on RTX 3090 — 재현 가능한 Launch Scripts 가이드 (Alexander-Ollman GitHub)"
description: "Alexander-Ollman GitHub 레포의 launch-27b.sh / launch-35b-moe.sh 분석: 시스템 요구사항, Docker 실행 파라미터, Genesis 패치 적용법, 알려진 제약사항 정리"
created: 2026-05-07 14:30
updated: 2026-05-07 14:30
type: "[[RESEARCH_NOTE]]"
index: "[[AI]]"
topics: ["[[LOCAL_LLM_HOSTING]]", "[[VLLM]]"]
tags: [research-note, llm, local-hosting, rtx-3090, vllm, qwen, launch-scripts, docker, genesis-patches, autoround, awq, nginx-lb, expert-parallel]
keywords: ["RTX 3090", "Qwen3.6-27B", "Qwen3.6-35B-A3B", "vLLM nightly", "Genesis patches", "AutoRound INT4", "AWQ Marlin", "Docker", "nginx least_conn", "expert-parallel", "MTP", "FP8 KV cache"]
sources:
  - "[[15_Sources/2026-05-07_qwen36_3090_launch_scripts_source]]"
  - "https://github.com/Alexander-Ollman/qwen3.6-on-rtx3090"
aliases: ["Ollman launch scripts", "qwen36 3090 재현 가이드", "qwen36_3090_launch_scripts"]
---

# Qwen3.6 on RTX 3090 — 재현 가능한 Launch Scripts 가이드

> 관련 노트: [[2026-05-07_qwen36_dual_3090_25_to_283_tps]] — 왜 이 설정에 도달했는지 (블로그 포스트 기반 최적화 과정)

## TL;DR
[원본 §README.md →](2026-05-07_qwen36_3090_launch_scripts_source.md#readmemd)

- 듀얼 [[RTX 3090]] (24GB×2)에서 [[Qwen3.6]]-27B 덴스 **225 tok/s** / 35B-A3B MoE **283 tok/s** aggregate를 재현하는 Docker 기반 launch 스크립트 레포.
- 27B: `2 replicas + nginx least_conn LB` (TP=1 per replica) — 포트 8400
- 35B-A3B MoE: `TP=2 + --enable-expert-parallel` 단일 인스턴스 — 포트 8500
- 공통 베이스: [[vLLM]] nightly `07351e0` + [[Genesis Patches]] (Sandermage) + `patch_tolist_cudagraph.py`

## 시스템 요구사항
[원본 §System Requirements →](2026-05-07_qwen36_3090_launch_scripts_source.md#system-requirements)

| 항목 | 사양 |
|---|---|
| OS | Ubuntu 22.04.5 LTS / 24.04 LTS (커널 6.8+) |
| NVIDIA 드라이버 | **580.159.03** (최소 575), CUDA 13.0 |
| Docker | 24+ + NVIDIA Container Toolkit |
| GPU | 듀얼 RTX 3090 24GB (단일 3090은 27B만 가능) |
| 스토리지 | ~50GB (Docker 이미지 + 모델 가중치 + 패치) |
| vLLM 이미지 | `vllm/vllm-openai:nightly-07351e0883470724dd5a7e9730ed10e01fc99d08` |

## launch-27b.sh 분석 (Qwen3.6-27B 덴스)
[원본 §launch-27b.sh →](2026-05-07_qwen36_3090_launch_scripts_source.md#launch-27bsh)

### 토폴로지

```
GPU 0 → Docker qwen36-vllm-1 (port 8500) ─┐
                                             ├─ nginx least_conn → :8400
GPU 1 → Docker qwen36-vllm-2 (port 8501) ─┘
```

- **모델**: `Lorbus/Qwen3.6-27B-int4-AutoRound` (HF cache 마운트, read-only)
- `--tensor-parallel-size 1` — 각 replica가 단일 GPU 독점

### 핵심 vLLM 파라미터

```
--quantization auto_round --dtype float16
--max-model-len 16000 --gpu-memory-utilization 0.92
--max-num-seqs 2 --max-num-batched-tokens 2048
--kv-cache-dtype fp8_e5m2
--speculative-config '{"method":"mtp","num_speculative_tokens":3}'
--enable-prefix-caching --enable-chunked-prefill
```

### Genesis 패치 환경변수 (27B 전용 포함)

| 환경변수 | 역할 |
|---|---|
| `GENESIS_ENABLE_P64_QWEN3CODER_MTP_STREAMING=1` | **27B 전용** — MTP streaming 최적화 |
| `GENESIS_ENABLE_P67_TQ_MULTI_QUERY_KERNEL=1` | TurboQuant multi-query kernel |
| `GENESIS_ENABLE_P82=1` | (공통) |
| `GENESIS_ENABLE_PN8_MTP_DRAFT_ONLINE_QUANT=1` | MTP draft 온라인 양자화 |

### 공통 NCCL/환경변수

```
VLLM_WORKER_MULTIPROC_METHOD=spawn
NCCL_CUMEM_ENABLE=0   NCCL_P2P_DISABLE=1
PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True,max_split_size_mb:512
VLLM_FLOAT32_MATMUL_PRECISION=high
VLLM_USE_FLASHINFER_SAMPLER=1
OMP_NUM_THREADS=1
CUDA_DEVICE_MAX_CONNECTIONS=8
VLLM_MARLIN_USE_ATOMIC_ADD=1
```

### 기동 순서

1. 기존 컨테이너 제거 (`docker rm -f`)
2. GPU 0/1 각각 `docker run -d` (백그라운드)
3. 컨테이너 내부: `pip install xxhash pandas scipy` → `python3 -m vllm._genesis.patches.apply_all` → `patch_tolist_cudagraph.py` 적용
4. `nginx:alpine` LB 컨테이너 기동 (`--network host`)
5. **~90초 대기** 후 `curl http://localhost:8400/v1/models` 확인

## launch-35b-moe.sh 분석 (Qwen3.6-35B-A3B MoE)
[원본 §launch-35b-moe.sh →](2026-05-07_qwen36_3090_launch_scripts_source.md#launch-35b-moesh)

### 토폴로지

```
GPU 0 + GPU 1 → Docker qwen36-moe (--gpus all, TP=2 + expert-parallel) → :8500
```

- **모델**: `QuantTrio/Qwen3.6-35B-A3B-AWQ` (하드코딩된 snapshot SHA)
- `--tensor-parallel-size 2 --enable-expert-parallel` — 24GB 단일 카드 불가, 양 GPU 필수

### 핵심 vLLM 파라미터 (27B와의 차이)

```
--quantization awq_marlin          # AutoRound → AWQ Marlin
--tensor-parallel-size 2           # TP=1 → TP=2
--enable-expert-parallel           # 추가: expert sharding
--max-model-len 32000              # 16000 → 32000
--max-num-seqs 4                   # 2 → 4 (천장: 8 이상 크래시)
--max-num-batched-tokens 4096      # 2048 → 4096
# NO --speculative-config          # MTP 제거 (OOM + net regress)
```

### P64 미포함 이유

27B의 `GENESIS_ENABLE_P64_QWEN3CODER_MTP_STREAMING=1`은 MoE 스크립트에 없음 — MTP 자체가 제거됐기 때문.

### Snapshot SHA 하드코딩 배경

동적 `ls` 조회는 `qwen-control` 컨테이너 내부에서 `/home/ver/.cache`가 마운트되지 않아 빈 결과를 반환. SHA를 하드코딩해 해결.

## 알려진 제약사항 및 버그
[원본 §Known Constraints →](2026-05-07_qwen36_3090_launch_scripts_source.md#known-constraints)

| 제약 | 원인 | 대응 |
|---|---|---|
| `--max-num-seqs > 4` 크래시 (MoE) | vLLM modular-kernel workspace-lock 버그 | 4로 고정 |
| 35B-MoE 단일 3090 불가 | 24GB 초과 | 듀얼 GPU 필수 |
| MoE + 스펙 디코딩 성능 저하 | profile_run OOM + net regress | MTP 미사용 |
| 27B TP=2 성능 열위 | NVLink 없는 PCIe NCCL all-reduce 병목 | 2 replicas 패턴 채택 |

## 모델 체크포인트 정보
[원본 §launch-27b.sh →](2026-05-07_qwen36_3090_launch_scripts_source.md#launch-27bsh)

| 모델 | HF 리포 | 양자화 |
|---|---|---|
| Qwen3.6-27B | `Lorbus/Qwen3.6-27B-int4-AutoRound` | AutoRound INT4 (MTP head BF16 보존) |
| Qwen3.6-35B-A3B | `QuantTrio/Qwen3.6-35B-A3B-AWQ` | AWQ → Marlin kernel |

## 라이선스

- 코드(스크립트): MIT
- 문서(블로그): CC BY 4.0
