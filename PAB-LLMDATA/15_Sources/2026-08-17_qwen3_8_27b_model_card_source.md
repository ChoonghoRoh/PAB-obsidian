---
title: "Qwen3.8-27B 모델 카드 원문 (Hugging Face)"
description: "Qwen3.8-27B Hugging Face 모델 카드 페치 원문 보존 — 아키텍처 사양·벤치마크·사용법·배포 옵션·라이선스"
created: 2026-08-17 10:05
updated: 2026-08-17 10:05
type: "[[SOURCE]]"
index: "[[AI]]"
topics: ["[[QWEN]]", "[[LOCAL_LLM_HOSTING]]"]
tags:
  - source
  - qwen
  - llm
keywords: [qwen3.8, 27b, model-card, gated-deltanet, vision-language, reasoning-effort, long-context, apache-2.0]
sources: ["https://huggingface.co/Qwen/Qwen3.8-27B"]
aliases: ["Qwen3.8-27B 원문", "큐원3.8 모델카드 원문"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (2026-08-17 WebFetch 페치본)

# Qwen3.8-27B Model Card Summary

## Model Introduction

Qwen3.8-27B represents "the most capable generation in the Qwen open-model family to date," built on Qwen3.5's foundation with improvements for coding, professional work, research, and agentic tasks. It's a native vision-language model supporting images and videos.

## Qwen3.8 Highlights

- **Core Capabilities**: Improvements across coding, professional work, research, and long-horizon agentic tasks
- **Agent Execution**: Stronger autonomous planning and environment feedback handling
- **Downstream Compatibility**: Broader support for popular development tools
- **Flexible Thinking Control**: Thinking enabled by default; adjustable via `reasoning_effort`
- **Vision-Language**: Native image and video understanding

## Model Architecture

**Language Model Specifications:**
- Parameters: 27B
- Hidden Dimension: 5120
- Layers: 64
- Hidden Layout: 16 × (3 × (Gated DeltaNet → FFN) → 1 × (Gated Attention → FFN))
- Context Length: 262,144 tokens natively; extensible to 1,000,000
- Token Embedding: 248,320 (Padded)
- FFN Intermediate Dimension: 17,408

## Benchmark Results

**Text Performance** highlights:
- SWE-bench Pro: 61.7
- Terminal Bench 2.1: 73.0
- GPQA Diamond: 89.2
- LiveCodeBench v6: 90.3

**Vision-Language Performance** highlights:
- OSWorld-Verified: 84.3
- WebArena-Verified: 64.8
- AndroidWorld: 81.9
- MathVision (with CI): 94.6

## Usage Examples

**Text-Only Input (Chat API):**
```python
from openai import OpenAI
client = OpenAI()
messages = [{"role": "user", "content": "Write a Python function to merge two sorted linked lists."}]
completion = client.chat.completions.create(
    model="Qwen/Qwen3.8-27B",
    messages=messages,
    reasoning_effort="xhigh"
)
```

**Image Input:**
Supports multimodal queries with image URLs passed via `image_url` parameter in message content.

**Video Input:**
Accepts video URLs with optional frame sampling configuration via `fps` parameter.

## Deployment Options

- **SGLang**: Dedicated serving engine with Qwen3.8 support
- **vLLM**: Production inference framework
- **TokenSpeed**: Optimized serving solution
- **Hugging Face Transformers**: Direct model loading and inference

## Configuration Parameters

**Thinking Mode (Default):**
- temperature: 1.0
- top_p: 0.95
- top_k: 20

**Instruct Mode:**
- temperature: 0.7
- top_p: 0.80
- presence_penalty: 1.5

## Key Features

- **Reasoning Effort Levels**: xhigh, medium, low
- **Preserved Thinking**: Retains reasoning across conversation turns (default enabled)
- **Long Context Support**: Handles up to 1M tokens with YaRN scaling
- **Multi-turn Agentic Tasks**: Maintains reasoning context across interactions

## Citation

```
@misc{qwen38,
    title = {{Qwen3.8-Max}: A New Bar for Coding and Cowork},
    url = {https://qwen.ai/blog?id=qwen3.8},
    author = {{Qwen Team}},
    month = {August},
    year = {2026}
}
```

## License

Apache 2.0
