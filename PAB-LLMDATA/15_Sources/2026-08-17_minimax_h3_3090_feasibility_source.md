---
title: "MiniMax-H3 모델 카드 원문 (Hugging Face)"
description: "MiniMaxAI/MiniMax-H3 Hugging Face 모델 카드 페치 원문 보존 — 33B 옴니모달 비디오+오디오 생성 시스템·배포 요구·라이선스"
created: 2026-08-17 10:20
updated: 2026-08-17 10:20
type: "[[SOURCE]]"
index: "[[AI]]"
topics: ["[[VIDEO_GENERATION]]", "[[LOCAL_LLM_HOSTING]]"]
tags:
  - source
  - minimax
  - video-generation
keywords: [minimax-h3, video-generation, omni-modal, 33b, stereo-audio, sglang, comfyui, community-license]
sources: ["https://huggingface.co/MiniMaxAI/MiniMax-H3"]
aliases: ["MiniMax-H3 원문", "미니맥스 H3 모델카드"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (2026-08-17 WebFetch 페치본)

# MiniMax H3 Model Card Summary

## Model Introduction

MiniMax H3 is a general-purpose, omni-modal generative system supporting unified understanding of multimodal contexts (text, images, video, audio) and generating video with native stereo audio at resolutions up to 2K for durations of 4–15 seconds.

## Architecture Specifications

**Total Parameters:** 33B (H3-Omni-Transformer)
- Approximately 13B parameters in AdaLN-related branches (not required for inference-only)

**Active Parameters:** Dense, single-stream architecture without modality-specific structures in attention/FFN layers

**MoE:** No

**Layers:** Not explicitly specified in document

**Context Length:** Supports long sequences with native sparse attention (sparse-attention implementation not included in initial release)

## Model Variants

| Variant | Input Mode | Specifications |
|---------|-----------|----------------|
| H3-Base-FL2VA | First-and-last-frame | 0–2 images; text-to-video, first/last-frame, or first-and-last-frame modes |
| H3-Base-Ref2VA | Omni-reference | ≤9 images, ≤3 video clips (2–15s each), ≤3 audio clips (2–15s each), max 12 files total |

## Output Specifications

- **Duration:** 4–15 seconds
- **Aspect Ratios:** 21:9, 16:9, 4:3, 1:1, 3:4, 9:16
- **Resolution:** Default shorter side 768px; 2K via H3-Regenerate-2K
- **Frame Rate:** 24 FPS
- **Audio:** 32 kHz stereo
- **Supported Languages:** Arabic, Chinese, English, French, German, Italian, Japanese, Korean, Portuguese, Russian, Spanish

## Usage

### Installation (Diffusers)

```
pip install -U diffusers transformers accelerate
```

### Basic Code

```python
import torch
from diffusers import DiffusionPipeline

pipe = DiffusionPipeline.from_pretrained(
    "MiniMaxAI/MiniMax-H3",
    dtype=torch.bfloat16,
    device_map="cuda"
)
prompt = "Astronaut in a jungle, cold color palette, muted colors, detailed, 8k"
image = pipe(prompt).images[0]
```

## Deployment

### Recommended Frameworks

- **SGLang** – Primary recommendation with deployment guide
- **vLLM** – With vLLM recipes
- **Diffusers** – Native support with ModularPipeline
- **ComfyUI** – With templates for T2V and R2V workflows

### SGLang Deployment Example

**FL2VA:**
```
sglang serve \
  --model-path MiniMaxAI/MiniMax-H3 \
  --num-gpus 4 \
  --ulysses-degree 4 \
  --performance-mode speed \
  --host 0.0.0.0 \
  --port 30010 \
  --model-variant fl2va
```

**Ref2VA:**
```
sglang serve \
  --model-path MiniMaxAI/MiniMax-H3 \
  --num-gpus 4 \
  --ulysses-degree 4 \
  --performance-mode speed \
  --host 0.0.0.0 \
  --port 30011 \
  --model-variant ref2va
```

### Hardware Requirements

- **Minimum:** 4 GPUs (examples use 4x GPU deployment)
- **Precision:** BF16 (bfloat16)
- **Memory:** Requires substantial VRAM; specific requirements depend on resolution and sequence length (not detailed in document)

## System Components

1. **H3-Context-IR:** Hosted preprocessing system for multimodal input understanding and conversion to intermediate representation (not open-sourced)

2. **H3-Base:** Video/audio generation at 768p using:
   - H3-Encoder (based on Qwen3-VL-32B, layer 50)
   - H3-VisualVAE (16× spatial, 4× temporal compression, 24 latent channels)
   - H3-AudioVAE (32 kHz, 40 Hz temporal rate, stereo)
   - H3-Omni-Transformer with 3D Multimodal Rotary Position Embeddings

3. **H3-Regenerate-2K:** In-context regeneration for 2K resolution (not open-sourced; API available)

## License

**MiniMax H3 Community License Agreement**
- Application form required for USA/EU/UK/South Korea
- Q&A documentation available on repository

## Additional Resources

- **Online API:** platform.minimax.io (Global) / platform.minimaxi.com (CN)
- **Web App:** hailuoai.video (Global) / hailuoai.com (CN)
- **Desktop:** hub.minimax.io (Global) / hub.minimaxi.com (CN)
- **Prompting Guides:** VIDEO_PROMPT_WRITING_GUIDE_base_en.md and VIDEO_PROMPT_WRITING_GUIDE_ref_en.md on repository
- **Skills Repository:** github.com/MiniMax-AI/MiniMax-H3/tree/main/skills

**Contact:** model@minimax.io
