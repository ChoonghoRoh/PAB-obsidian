---
aliases: []
created: 2026-06-30 21:49
description: ''
index: '[[ROOT]]'
keywords: []
sources: []
tags:
- moc
- topics/local-llm-hosting
title: Local Llm Hosting
topics: []
type: '[[REFERENCE]]'
updated: 2026-06-30 21:49
---

## Dataview 쿼리

```dataview
LIST FROM "" WHERE contains(topics, "[[LOCAL_LLM_HOSTING]]") SORT created DESC
```

## 폴백 정적 링크

<!-- moc-build:auto-start -->
- [[2026-05-26_beellama_v020_dflash_3090_source]] — BeeLlama v0.2.0 — major DFlash update, single RTX 3090 (원본)
- [[2026-05-26_beellama_v020_dflash_3090]] — BeeLlama.cpp v0.2.0 — DFlash로 단일 RTX 3090에서 Qwen3.6-27B 164 tps(4.40x)·Gemma4-31B 177.8 tps(4.93x)
- [[2026-05-07_qwen36_3090_launch_scripts_source]] — qwen3.6-on-rtx3090 GitHub Repository — README + Launch Scripts (Alexander-Ollman)
- [[2026-05-07_qwen36_3090_launch_scripts]] — Qwen3.6 on RTX 3090 — 재현 가능한 Launch Scripts 가이드 (Alexander-Ollman GitHub)
- [[2026-05-07_qwen36_dual_3090_25_to_283_tps_source]] — From 25 to 283 tok/s: Serving Qwen3.6 on Dual RTX 3090s — Alexander Ollman (원본)
- [[2026-05-07_qwen36_dual_3090_25_to_283_tps]] — Qwen3.6 듀얼 RTX 3090 풀스택 서빙 — 25 → 283 tok/s (Round 1 dense + Round 2 MoE)
- [[2026-05-05_qwen36_27b_3090_218k_pn12_source]] — Reddit r/LocalLLaMA — Qwen3.6-27B on 1× RTX 3090, pushing to ~218K context (PN12 fix follow-up, 원본)
- [[2026-05-05_qwen36_27b_3090_218k_pn12]] — Qwen3.6-27B on 1× RTX 3090 — 218K context + PN12 fix (Reddit follow-up)
- [[2026-05-05_club_3090_source]] — club-3090 — README (원본)
- [[2026-05-05_club_3090]] — club-3090 — RTX 3090에서 LLM 서빙하는 두 가지 경로 (vLLM dual / llama.cpp single)
- [[2026-05-03_local_llm_under_3090_source]] — Reddit r/LocalLLaMA — Can you run actually useful LLMs on anything less than 3090? (원문)
- [[2026-05-03_local_llm_under_3090]] — 12GB VRAM(RTX 3060)으로 쓸만한 LLM 호스팅 가능한가 — r/LocalLLaMA 토론 정리
<!-- moc-build:auto-end -->