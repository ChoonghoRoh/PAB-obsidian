---
title: "BeeLlama v0.2.0 — major DFlash update, single RTX 3090 (원본)"
description: "Anbeeld의 llama.cpp 포크 BeeLlama.cpp v0.2.0 (2026-05-22) r/LocalLLaMA 릴리스 게시글 원문. DFlash speculative decoding으로 단일 RTX 3090에서 Qwen3.6-27B 164 tps(4.40x)·Gemma4-31B 177.8 tps(4.93x). Baseline/DFlash/MTP 3-way 벤치 전문 — 원본 immutable 보존."
created: 2026-05-26 16:28
updated: 2026-05-26 16:45
type: "[[SOURCE]]"
index: "[[AI]]"
topics: ["[[LOCAL_LLM_HOSTING]]", "[[SPECULATIVE_DECODING]]"]
tags: [source, llm, llama-cpp, speculative-decoding, dflash, mtp, rtx-3090, qwen, gemma, kv-cache]
keywords: ["BeeLlama.cpp", "DFlash", "MTP", "RTX 3090", "Qwen 3.6 27B", "Gemma 4 31B", "speculative decoding", "llama.cpp b9275", "Anbeeld", "drafter K/V projection caching", "acceptance rate", "prompt processing"]
sources:
  - "https://www.reddit.com/r/LocalLLaMA/comments/1tkpz2y/beellama_v020_major_dflash_update_single_rtx_3090/"
  - "https://github.com/Anbeeld/beellama.cpp"
  - "https://github.com/Anbeeld/beellama.cpp/blob/main/docs/quickstart-qwen36-dflash.md"
  - "https://github.com/Anbeeld/beellama.cpp/blob/main/docs/quickstart-gemma-4-31b-dflash.md"
aliases: ["BeeLlama v0.2.0 원본", "beellama_v020_dflash_3090_source", "DFlash 3090 원본"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy 3계층의 SOURCE 계층)
> ⓘ 사용자 제공 Reddit 게시글 원문 (verbatim). 초기 버전은 페치 차단으로 재구성했으나, 본 파일은 원문 전문으로 교체됨.

# BeeLlama v0.2.0 – major DFlash update. Single RTX 3090: Qwen 3.6 27B up to 164 tps (4.40x), Gemma 4 31B up to 177.8 tps (4.93x). Prompt processing speed near baseline.

## Resources

BeeLlama v0.2.0 is here!

Not quite a pegasus, but close enough.

GitHub | Qwen 3.6 27B Quick Start | Gemma 4 31B Quick Start

- Full Gemma 4 31B support with efficient DFlash implementation and vision.
- Major Qwen 3.6 27B performance update from lower DFlash overhead, cleaner prefill handling, drafter K/V projection caching, and safer CUDA execution.
- DFlash GGUFs with upstream architecture are now supported.
- Fixes to adaptive profit behavior around baseline probing.
- Reduced verifier path is stricter now, with safer fallback to full logits when grammar, sampler state, or reasoning requires it.
- Reasoning and tool-call boundaries were tightened.
- Stricter draft/target validation and better draft-model discovery.
- ...and many more improvements!

## Benchmarks

Setup: Windows 11, AMD Ryzen 7 5700X3D, 32 GB DDR4 RAM, RTX 3090 24 GB

Config: same as in quick start docs, but with reasoning off for non-chat prompts

Baseline and MTP server in comparison: llama.cpp b9275 CUDA 13.1 Windows prebuilt

The full text of the benchmark prompts is in README.md on GitHub

## Qwen 3.6 27B

Target model: Qwen 3.6 27B Q5_K_S or Qwen 3.6 27B MTP Q5_K_S. DFlash model: Q4_K_M.

| Prompt | Server | Output | Median | Best | Speedup | Acceptance |
|---|---|---|---|---|---|---|
| Task store module | Baseline | ~1K tok | 37.2 tok/s | 37.2 tok/s | 1.00x | N/A |
| Task store module | DFlash | ~1K tok | 163.9 tok/s | 181.9 tok/s | 4.40x | 67.7% / 89.2% |
| Task store module | MTP | ~1K tok | 69.3 tok/s | 69.6 tok/s | 1.86x | 92.0% / 73.3% |
| KV report module | Baseline | ~1K tok | 34.6 tok/s | 36.5 tok/s | 1.00x | N/A |
| KV report module | DFlash | ~1K tok | 157.7 tok/s | 162.5 tok/s | 4.56x | 58.8% / 88.9% |
| KV report module | MTP | ~1K tok | 67.3 tok/s | 68.1 tok/s | 1.94x | 89.3% / 73.0% |
| Doubly-linked list | Baseline | ~4K tok | 36.8 tok/s | 36.9 tok/s | 1.00x | N/A |
| Doubly-linked list | DFlash | ~4K tok | 130.8 tok/s | 154.1 tok/s | 3.56x | 50.4% / 86.8% |
| Doubly-linked list | MTP | ~4K tok | 66.3 tok/s | 68.0 tok/s | 1.80x | 87.8% / 72.5% |
| Prompt processing | Baseline | ~20K tok | 1229.5 tok/s | 1229.5 tok/s | 1.00x | N/A |
| Prompt processing | DFlash | ~20K tok | 1214.4 tok/s | 1221.7 tok/s | 0.99x | N/A |
| Prompt processing | MTP | ~20K tok | 1162.6 tok/s | 1164.7 tok/s | 0.95x | N/A |
| Multi-turn coding | Baseline | ~28K tok | 33.3 tok/s | 33.3 tok/s | 1.00x | N/A |
| Multi-turn coding | DFlash | ~30K tok | 64.6 tok/s | 65.4 tok/s | 1.94x | 24.9% / 72.9% |
| Multi-turn coding | MTP | ~34K tok | 56.5 tok/s | 56.5 tok/s | 1.70x | 71.9% / 68.3% |

Acceptance: accepted to proposed draft tokens / accepted draft tokens to final generated tokens

## Gemma 4 31B

Target model: Gemma 4 31B Q4_K_S. DFlash model: Q5_K_M.

| Prompt | Server | Output | Median | Best | Speedup | Acceptance |
|---|---|---|---|---|---|---|
| Task store module | Baseline | ~1K tok | 36.1 tok/s | 36.1 tok/s | 1.00x | N/A |
| Task store module | DFlash | ~1K tok | 177.8 tok/s | 182.0 tok/s | 4.93x | 65.7% / 90.0% |
| KV report module | Baseline | ~1K tok | 35.9 tok/s | 36.0 tok/s | 1.00x | N/A |
| KV report module | DFlash | ~1K tok | 154.3 tok/s | 162.8 tok/s | 4.29x | 55.7% / 88.6% |
| Doubly-linked list | Baseline | ~1.9K tok | 36.0 tok/s | 36.0 tok/s | 1.00x | N/A |
| Doubly-linked list | DFlash | ~1.9K tok | 116.6 tok/s | 127.3 tok/s | 3.24x | 44.5% / 84.9% |
| Prompt processing | Baseline | ~24K tok | 1021.3 tok/s | 1021.3 tok/s | 1.00x | N/A |
| Prompt processing | DFlash | ~24K tok | 954.5 tok/s | 954.9 tok/s | 0.93x | N/A |
| Multi-turn coding | Baseline | ~12K tok | 34.8 tok/s | 34.8 tok/s | 1.00x | N/A |
| Multi-turn coding | DFlash | ~12K tok | 60.6 tok/s | 64.1 tok/s | 1.74x | 24.4% / 72.3% |

Acceptance: accepted to proposed draft tokens / accepted draft tokens to final generated tokens

## GitHub

- https://github.com/Anbeeld/beellama.cpp/blob/main/docs/quickstart-qwen36-dflash.md
- https://github.com/Anbeeld/beellama.cpp/blob/main/docs/quickstart-gemma-4-31b-dflash.md

## Comments

**zenray:** what about 16gb vram? use cHunter789/Qwen3.6-27B-i1-IQ4_XS-GGUF?
> **Anbeeld (OP):** Yes, or Q3.

**Shoddy-Tutor9563:** What's the catch? There must be one :)
> **Anbeeld (OP):** Your first born might need to be sacrificed or it won't launch.
> > **Shoddy-Tutor9563:** Can I trade him for ex-mother-in-law?
> > > **Anbeeld (OP):** I'll ask Satan.

**kenzu82:** Will this work on my 2 old Tesla P100? / Have to test then.. 😅

**LPFchan:** is effective context halving when using dflash due to rollback still a thing??

**StardockEngineer:** Your build docs say to download the original llama.cpp? Are you just trying to say building is the same?
> **Anbeeld (OP):** Whoops, will fix.

**oldeastvan:** I'm using prebuilt cuda12 with a 3090 and just get constant: `decode: failed to initialize batch` / `llama_decode: failed to decode, ret = -1` / `dflash: drafter decode failed with -1` / `init: the tokens of sequence 0 in the input batch have inconsistent sequence positions: the last position stored in the KV cache for sequence 0 is X = 40 - the tokens for sequence 0 in the input batch have a starting position of Y = 782 - it is required that Y = X + 1`. output is around 20 tokens per sec. Anyone?

**thecalmgreen:** Looks awesome, OP. Any test with Gemma 4 26B A4B? And if anyone wants a simple GUI: https://andercoder.com/hexllama/ — works with pretty much any llama.cpp-based backend.

**Kyunle:** my 5090 32gb config for updated beellama. My daily runner "Qwopus3.6-27B-v2-MTP Q6_K" didn't start. But "Qwen3.6-27B Q6_K + DFlash" is almost the same as current master llama.cpp, ~20% slower than old beta pre-MTP-merge config.

**CatTwoYes (10 upvotes):** The fork complaints miss the point. llama.cpp mainline has to support 50+ backends and keep production setups stable — never going to move as fast as a single-dev fork targeting one GPU and two models. Forks like this are the R&D layer. Flash attention, KV cache quants, speculative decoding — all started as forks before trickling upstream. Same story here.

**ludos1978:** what context size can this handle on a 3090?
> **Anbeeld (OP):** Check quick start docs, they talk about context in detail. You can fit up to 150k with moderate cache quantization.

**Address-Street:** dual GPU, decode error with `--tensor-split 1.1,1 -ctk q8_0 -ctv q8_0`: same `inconsistent sequence positions` (X=79, Y=509) / `decode: failed to initialize batch`.

**fdrch:** Does it work with single GPU only? Can I use 2 x 16 Gb?

**caetydid (independent bench, Gemma4, via svelte webui):**
> doubly linked list (your prompt) 1k7 → 100-130 tok/s; "implement double linked list in python" 1k1 → 100-110; "write snake game in python" 1k6 → 50-70; "write a tale about a fox and a rabbit" 700 → 33-37; summarize 40k diary 700 → 29-33; summarize (pp) → 800-1000. Could not quite reach your numbers, but impressive! top-k < 64 preserves slightly better speed for the slow cases.

**laul_pogan:** For long agentic chats, the acceptance rate column tells the story. DFlash drops to 24.9% at 28K multi-turn while MTP holds 71.9% on the same prompt. Speculative decoding lives and dies on acceptance; low acceptance means paying draft overhead without the payoff. DFlash wins hard on short-burst prompts (4x+ on 1K output) but MTP's acceptance stays consistent across context length. For 200k rolling sessions, MTP likely edges out. Worth benchmarking acceptance at your actual typical context depth before committing.
> **Anbeeld (OP):** I agree, but can you explain that in the style of a microwave manual?

**_Punda:** Best year to own a 3090. On 0.1.2 I got improvements turning on DDTree + low branch budget (narrow tree, ~2 branches) increased speed at cost of VRAM. Old DDTree config slows down in new version. People combine DFlash and ngram-mod together — curious about plans. Adding `-t 8` gave ~4 extra TPS (7800X3D, physical core count).
> **Anbeeld (OP):** Regarding ngram, yes combinations of this kind are promising, currently in early exploration phase.

**caetydid:** rebuilt cleanly with cuda 13.1 but v0.2.0 crashes on first inference: `argmax.cu:557: GGML_ASSERT(K <= 32) failed`. Update: it is the `--top-k 64`. Lowered to 20 and now works for Gemma too. Also better to limit `make -j 2` otherwise OOMs easily.
> **Anbeeld (OP):** Already merged a PR that was supposed to fix it. Check if you have the latest main pulled.

**Vegetable-Photo972:** What about tool calling? Tested with Codex, OpenCode, other agent?
> **Anbeeld (OP):** I tested with OpenCode many times, recently VSCode Copilot. v0.2.0 is very stable around tool calling: correct grammar handling with DFlash, prevention of mistakenly outputted EOS inside reasoning, quarantine of failed tool calls instead of dumping into user-visible output, benchmarks for better KV cache quant recommendations. The biggest problem: every time I set V cache to q4_0 it butchers tool call syntax from precision loss — advise against it, use q4_1 at the very least. :)
> > **Godde:** seeing bad tool calls and reasoning stopping a few turns in. Message about drafting being suspended in tool calls due to lazy grammar. My agentic work is ~50% thinking + 50% tool calls which run without specdec. Long edits hurt and would be perfect prediction targets.

**ArtfulGenie69:** How hard to set up on vLLM (vLLM already accepts dflash)?
> **Anbeeld (OP):** Does vLLM need it? Haven't tried, except with MTP once a month ago.
> > **ArtfulGenie69:** vLLM hits ~120 t/s running dflash on qwen3.6 27b not 170t/s. vLLM uses int4/int8 (gguf doesn't), which is why it's already fast. Could 200t/s be possible?
> > > **Anbeeld (OP):** No vLLM experience but yeah, what I've done can be theoretically ported to other inference engines.

**coherentspoon:** `argmax.cu:557: GGML_ASSERT(K <= 32) failed` when I prompt.
> **Anbeeld (OP):** Just merged a PR that should fix it, pull and rebuild.
> > **coherentspoon:** it was something with `--spec-dflash-cross-ctx 1024`.

**wreckerone1 / Terrible-Mongoose-84 / HungryMachines / Sear_Oc / fdrch (multi-GPU questions):**
> **Anbeeld (OP):** Multi-GPU not properly supported yet. I don't own it myself, so I apply fixes based on reports, and there wasn't much of them lately. If you try it and something won't work, send a report in GitHub issues.

**TheKeiron:** getting great results with qwen 35b a3b with dflash on 8gb vram, around 40 tokens/second.

**No_Field3913:** my biggest pains are prompt processing; whenever agent reads a large file it adds prefill time, the slowest part. The new optimization improving prefill too?
> **Anbeeld (OP):** Yes! Prefill is very close to baseline, and is better than mainline MTP at the moment. Check the benchmarks, there's a separate one for prefill specifically.

**Rikers88:** rocking qwen 3.6 27b UD Q4 K XL on 5090! PS I sponsored your project at PyData Amsterdam — well received. The combination of DFlash and Turboquant is killing it. Can I stack multiple speculative techniques (dflash + ngram + copyspec)? Boundary V like TheTom turboquant / turboquant plus?
> **Anbeeld (OP):** Stacking possible in theory, early exploration phase, very promising next direction. Boundary V — I'll try to keep up.

**ltduff69:** Got it working with `.\llama-server.exe`. Used q5_K_S model. 140t/s first prompt, impressive.

**No_Field3913:** Yet another fork? Better to have minimal-drift fork aimed at upstreaming. Risk fragmenting the community.
> **Anbeeld (OP):** Sorry to distract you. Would you help me PR this into mainline? ... I plan to update up to mainline soon to keep up with their MTP and general spec architecture. If a fork is properly supported, users basically get usual llama.cpp with extra features. My upstream fork (buun's) was updated to mainline recently.

**Zarzou (6 upvotes):** bee-llama → buun-llama → TheTom/llama → llama.cpp. Such fragmentation is to be avoided.
> **Anbeeld (OP):** What I care about is being able to ship good stuff to the community, that's it. (18 upvotes)

**caetydid:** are the speed gains for qwen MTP expected to be smaller, or just not yet optimized? acceptance rates seem high compared to dflash.
> **Anbeeld (OP):** MTP uses fixed draft-n-max 3 by default, which I left as is for benchmarks. BeeLlama DFlash uses draft-n-max 16 and a profit-based adaptive controller that dynamically lowers it if needed. So the reason DFlash has much lower acceptance is because it drafts much more tokens. Drafting was made cheap back in v0.1.2 so it's more profitable to try more, even if most fail. The important number is the second one — accepted draft tokens to final generated tokens. In every single benchmark DFlash had it higher than MTP did. MTP just has high accepted-to-proposed ratio, but without context it doesn't mean anything; the context is that it drafts very conservatively.
> > **caetydid:** Hence dflash seems almost always preferable over MTP... unless I want to aggressively save VRAM (gemma4 MTP layer is very small).
> > > **Anbeeld (OP):** DFlash is very conservative with VRAM as well, the whole thing needs just 1-2 GB based on model etc., that's for 27B-31B dense models.

**craftogrammer:** something for 16GB VRAM poors?
> **Anbeeld (OP):** Didn't have time to tinker with smaller models yet, but if they use the same architecture it might work as is. If you squeeze Qwen 3.6 27B into Q3 (UD-Q3 might not be that bad), it should fit into 16 GB. Maybe turbo3_tcq KV cache for comfortable context size.

**My_Unbiased_Opinion:** I've used UD iq3XXS. Works well as a Hermes agent for me.

**sagiroth (14 upvotes):** Squeezing that 3090 like a lemon.
> **Anbeeld (OP):** Wait until I get a second one. The juice will flow like a river.

**Poha_Best_Breakfast:** Isn't DFLASH support still pending on llama.cpp mainline?
> **Anbeeld (OP):** That's the power of forks: no idea what's mainline stance on DFlash. I did some stuff, it seems to work, I share it with the community.

**FerLuisxd:** MTP seems so slow, other comparisons differ — not optimized yet?
> **Anbeeld (OP):** I used default settings for both methods, latest llama.cpp build, usual unsloth models. Maybe MTP benefits from tinkering with draft-n-max — that's what you've seen in other tests? Had too much benchmarking with my own stuff to explore MTP configs.

**Shockersam:** any accuracy drops using dflash and/or mtp?
> **Anbeeld (OP):** Shouldn't be, with proper implementation. All output of the drafter is verified by the target model, so the lil bro can't just output nonsense unsupervised.

**pmttyji:** Can you add Qwen3.5-9B MTP, Qwen3.6-35B-A3B & Gemma-4-26BA4B to Plug-and-Play Setups?
> **Anbeeld (OP):** Will add more models over time. For MoE I'm planning a separate update focused solely on them. v0.2.0 was a crazy time sink, and there's upstream MTP + general spec architecture to merge.

**caetydid (54 upvotes):** and here goes my evening...

**xeeff:** support rocm or vulkan
> **Anbeeld (OP):** Don't own AMD to test, but folks PR'd some stuff for HIP/ROCm, so should be working.

**Toastti:** For agentic coding, 200k context large chats on opencode — is MTP from latest llama.cpp or DFlash faster?
> **Dany0:** stopped testing it because on real prompts I got 60 tok/s. Acceptance rate tanks past ~32k context because zai lab didn't train on it.
> **Anbeeld (OP):** Depends a lot on prompts and context. In v0.2.0 both DFlash and prompt processing should be in a good state for Qwen 3.6 27B and Gemma 4 31B. In a multi-turn chat benchmark DFlash beat MTP, but it's only a benchmark. Did long-context chats in OpenCode and VSCode Copilot, pleasant experience, minimal tool-call issues. Honest answer: try both. Windows has prebuilts.
