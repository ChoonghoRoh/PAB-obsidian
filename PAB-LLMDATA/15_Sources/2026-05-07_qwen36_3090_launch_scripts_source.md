---
title: "qwen3.6-on-rtx3090 GitHub Repository — README + Launch Scripts (Alexander-Ollman)"
description: "Alexander-Ollman/qwen3.6-on-rtx3090 레포지토리 원문: README, launch-27b.sh, launch-35b-moe.sh 전체"
created: 2026-05-07 14:30
updated: 2026-05-07 14:30
type: "[[SOURCE]]"
index: "[[AI]]"
topics: ["[[LOCAL_LLM_HOSTING]]", "[[VLLM]]"]
tags: [source, llm, local-hosting, rtx-3090, vllm, qwen, launch-scripts, docker]
keywords: ["RTX 3090", "Qwen3.6-27B", "Qwen3.6-35B-A3B", "vLLM", "Genesis patches", "AutoRound", "AWQ", "launch script", "Docker", "nginx"]
sources: ["https://github.com/Alexander-Ollman/qwen3.6-on-rtx3090"]
aliases: ["qwen36_3090_launch_scripts_source", "Ollman GitHub repo source"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존

# qwen3.6-on-rtx3090 GitHub Repository — 원문

원본 URL: https://github.com/Alexander-Ollman/qwen3.6-on-rtx3090

---

## README.md

This repository contains reproducible recipes for deploying the Qwen3.6 model family on consumer NVIDIA RTX hardware using vLLM with performance optimizations.

### Key Performance Metrics

The setup achieves "100 tok/s single-stream, **225 tok/s aggregate** at C=4" for the 27B dense variant and "**283 tok/s aggregate**" for the 35B-A3B MoE on dual RTX 3090 cards — representing a 9× improvement over baseline vLLM.

### Repository Contents

The project includes: a detailed investigative blog post in Markdown and self-contained HTML formats with animated charts; launch scripts for both the 27B and 35B MoE configurations; a web UI with OpenAI-compatible proxy at port 9000; and performance visualization files.

### System Requirements

**Operating System:** Ubuntu 22.04.5 LTS or 24.04 LTS with kernel 6.8+

**NVIDIA Stack:** Driver 580.159.03, CUDA 13.0, Docker 24+ with NVIDIA Container Toolkit

**Hardware:** Verified on dual RTX 3090 (24GB each); single 3090 supports 27B only; 4090 and 5090 untested but expected compatible

**Storage:** Approximately 50GB for Docker image, model weights, and patches

### Quick Start Overview

Installation involves: updating to NVIDIA driver 580, pulling the specified vLLM nightly image, cloning patch repositories and downloading model weights via Hugging Face CLI, then executing the appropriate launch script (8400 port for 27B, 8500 for MoE).

### Known Constraints

- Single-GPU 35B-MoE doesn't function on 24GB cards
- Speculative decoding causes performance regression with the MoE variant
- Concurrency beyond 4 sequences crashes the engine
- Tensor parallelism exceeds replication performance on consumer cards without NVLink

### Licensing

Code components use MIT licensing; documentation employs CC BY 4.0.

---

## launch-27b.sh

```bash
#!/usr/bin/env bash

# Bring back the dual-3090 Qwen3.6-27B 2-replica + nginx LB stack.
# Yields ~225 tok/s aggregate at C=4 through http://localhost:8400.
# Requires:
# - driver >= 575 (we used 580)
# - vLLM nightly image already pulled
# - Genesis patches at $STACK/genesis
# - Lorbus AutoRound model in HF cache
# - nginx.conf at $STACK/nginx.conf

set -e

STACK=/home/ver/qwen3.6/overnight-stack
NIGHTLY_TAG=nightly-07351e0883470724dd5a7e9730ed10e01fc99d08
SNAP_REL="snapshots/c3aea2d531678621989e5e2db034e32b22536e79/"
MODEL_CACHE=/home/ver/.cache/huggingface/hub/models--Lorbus--Qwen3.6-27B-int4-AutoRound

docker rm -f qwen36-vllm-1 qwen36-vllm-2 qwen36-lb 2>/dev/null || true

for IDX in 0 1; do
  PORT=$((8500 + IDX))
  docker run -d --name "qwen36-vllm-$((IDX+1))" --gpus '"device='"$IDX"'"' \
    -v "$MODEL_CACHE":/model:ro \
    -v "$STACK/genesis/vllm/_genesis":/usr/local/lib/python3.12/dist-packages/vllm/_genesis:ro \
    -v "$STACK/repo/patches/patch_tolist_cudagraph.py":/patches/patch_tolist_cudagraph.py:ro \
    -p "$PORT":8000 --ipc=host --shm-size=16gb \
    -e VLLM_WORKER_MULTIPROC_METHOD=spawn -e NCCL_CUMEM_ENABLE=0 -e NCCL_P2P_DISABLE=1 \
    -e VLLM_NO_USAGE_STATS=1 -e VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1 \
    -e PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True,max_split_size_mb:512 \
    -e VLLM_FLOAT32_MATMUL_PRECISION=high -e VLLM_USE_FLASHINFER_SAMPLER=1 \
    -e OMP_NUM_THREADS=1 -e CUDA_DEVICE_MAX_CONNECTIONS=8 \
    -e VLLM_ALLOW_LONG_MAX_MODEL_LEN=1 -e VLLM_MARLIN_USE_ATOMIC_ADD=1 \
    -e GENESIS_ENABLE_P64_QWEN3CODER_MTP_STREAMING=1 \
    -e GENESIS_ENABLE_P67_TQ_MULTI_QUERY_KERNEL=1 \
    -e GENESIS_ENABLE_P82=1 \
    -e GENESIS_ENABLE_PN8_MTP_DRAFT_ONLINE_QUANT=1 \
    --entrypoint /bin/bash \
    "vllm/vllm-openai:$NIGHTLY_TAG" \
    -c "set -e
pip install xxhash pandas scipy -q
python3 -m vllm._genesis.patches.apply_all
python3 /patches/patch_tolist_cudagraph.py
exec vllm serve /model/$SNAP_REL \
  --served-model-name qwen36-27b \
  --quantization auto_round --dtype float16 --tensor-parallel-size 1 \
  --max-model-len 16000 --gpu-memory-utilization 0.92 \
  --max-num-seqs 2 --max-num-batched-tokens 2048 \
  --kv-cache-dtype fp8_e5m2 \
  --trust-remote-code --reasoning-parser qwen3 \
  --enable-prefix-caching --enable-chunked-prefill \
  --speculative-config '{\"method\":\"mtp\",\"num_speculative_tokens\":3}' \
  --host 0.0.0.0 --port 8000"
done

docker run -d --name qwen36-lb --network host \
  -v "$STACK/nginx.conf":/etc/nginx/nginx.conf:ro \
  nginx:alpine

echo "Wait ~90s for both replicas to apply Genesis + load weights, then:"
echo " curl http://localhost:8400/v1/models"
```

---

## launch-35b-moe.sh

```bash
#!/usr/bin/env bash

# Bring up Qwen3.6-35B-A3B (MoE) on dual RTX 3090s with TP=2 + expert-parallel.
# Yields ~282 tok/s aggregate at C=4 on http://localhost:8500.
# Single instance only — the model is too big to fit on one 3090, so the
# 2-replica + LB pattern from the 27B stack does not apply here.
#
# Requires:
# - driver >= 575 (we used 580)
# - vLLM nightly image already pulled
# - Genesis patches at $STACK/genesis
# - QuantTrio/Qwen3.6-35B-A3B-AWQ in HF cache

set -e

STACK=/home/ver/qwen3.6/overnight-stack

NIGHTLY_TAG=nightly-07351e0883470724dd5a7e9730ed10e01fc99d08

MODEL_CACHE=/home/ver/.cache/huggingface/hub/models--QuantTrio--Qwen3.6-35B-A3B-AWQ

# Hardcoded snapshot SHA. The dynamic `ls` lookup we previously had only
# worked when the launcher ran on the host — inside the qwen-control
# container /home/ver/.cache isn't mounted, so the lookup returned empty.
# Note: this is the bare SHA (no "snapshots/" prefix); the path below
# already prefixes "/model/snapshots/".

SNAP_REL="119886a1072372348f73ef0df2d801cdcc0f455b"

docker rm -f qwen36-moe 2>/dev/null || true

# Settings rationale:
# --max-num-seqs 4 = peak; bumping to 8 hits a vLLM modular-kernel
# workspace-lock bug under load and crashes the engine.
# --enable-expert-parallel = shards experts across both GPUs,
# less NCCL traffic than dense TP=2.
# No --speculative-config = MTP causes GDN profile_run OOM on Ampere+A3B,
# and published benchmarks show no spec-decode benefit on this MoE anyway.

docker run -d --name qwen36-moe --gpus all \
  -v "$MODEL_CACHE":/model:ro \
  -v "$STACK/genesis/vllm/_genesis":/usr/local/lib/python3.12/dist-packages/vllm/_genesis:ro \
  -v "$STACK/repo/patches/patch_tolist_cudagraph.py":/patches/patch_tolist_cudagraph.py:ro \
  -p 8500:8000 --ipc=host --shm-size=16gb \
  -e VLLM_WORKER_MULTIPROC_METHOD=spawn -e NCCL_CUMEM_ENABLE=0 -e NCCL_P2P_DISABLE=1 \
  -e VLLM_NO_USAGE_STATS=1 -e VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1 \
  -e PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True,max_split_size_mb:512 \
  -e VLLM_FLOAT32_MATMUL_PRECISION=high -e VLLM_USE_FLASHINFER_SAMPLER=1 \
  -e OMP_NUM_THREADS=1 -e CUDA_DEVICE_MAX_CONNECTIONS=8 \
  -e VLLM_ALLOW_LONG_MAX_MODEL_LEN=1 -e VLLM_MARLIN_USE_ATOMIC_ADD=1 \
  -e GENESIS_ENABLE_P67_TQ_MULTI_QUERY_KERNEL=1 \
  -e GENESIS_ENABLE_P82=1 \
  -e GENESIS_ENABLE_PN8_MTP_DRAFT_ONLINE_QUANT=1 \
  --entrypoint /bin/bash \
  "vllm/vllm-openai:$NIGHTLY_TAG" \
  -c "set -e

pip install xxhash pandas scipy -q

python3 -m vllm._genesis.patches.apply_all

python3 /patches/patch_tolist_cudagraph.py

exec vllm serve /model/snapshots/$SNAP_REL \
  --served-model-name qwen36-35b-moe \
  --quantization awq_marlin --dtype float16 --tensor-parallel-size 2 \
  --enable-expert-parallel \
  --max-model-len 32000 --gpu-memory-utilization 0.92 \
  --max-num-seqs 4 --max-num-batched-tokens 4096 \
  --kv-cache-dtype fp8_e5m2 \
  --trust-remote-code --reasoning-parser qwen3 \
  --enable-prefix-caching --enable-chunked-prefill \
  --host 0.0.0.0 --port 8000"

echo "Wait ~90s for Genesis + weight load + profile_run, then:"
echo " curl http://localhost:8500/v1/models"
echo " curl http://localhost:8500/v1/chat/completions \\"
echo " -H 'Content-Type: application/json' \\"
echo " -d '{\"model\":\"qwen36-35b-moe\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}]}'"
```
