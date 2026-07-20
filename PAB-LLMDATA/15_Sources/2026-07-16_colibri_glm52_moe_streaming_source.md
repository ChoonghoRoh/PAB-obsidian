---
title: "colibrì — GLM-5.2(744B MoE)를 25GB RAM PC에서 (GitHub README 원문)"
description: "JustVugg/colibri README 원문 — 디스크 스트리밍 MoE 런타임, 순수 C·의존성 0. immutable 보존본."
created: 2026-07-16 16:18
updated: 2026-07-16 16:18
type: "[[SOURCE]]"
index: "[[AI]]"
topics: ["[[LOCAL_LLM_HOSTING]]", "[[MOE_OFFLOADING]]"]
tags: [source, moe, local-llm, inference-engine, glm, quantization, c-lang]
keywords: [colibri, GLM-5.2, MoE, expert streaming, int4, MTP, speculative decoding, MLA, DSA, CUDA, Metal, OpenAI-compatible]
sources: ["https://github.com/JustVugg/colibri"]
aliases: ["colibri 원문", "콜리브리 README", "colibrì source"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy 3계층 sources). 요약·해석은 짝 노트 `10_Notes/2026-07-16_colibri_glm52_moe_streaming.md` 참조.

---

**Repository:** JustVugg/colibri · Apache-2.0 · pure C
**Description:** Run GLM-5.2 (744B MoE) on a 25GB-RAM consumer machine — pure C, zero deps, experts streamed from disk. Tiny engine, immense model. 🐦
**URL:** https://github.com/JustVugg/colibri
**Language:** C · **Stars:** 14,472 · **Forks:** 1,233 (fetched 2026-07-16)
**Created:** 2026-07-01 · **Pushed:** 2026-07-16

---

**Tiny engine, immense model.** Run **GLM-5.2 (744B-parameter MoE)** on a consumer machine with ~25 GB of RAM — in pure C, with zero dependencies, by streaming experts from disk.

Colibrì is a lightweight, quality-preserving MoE runtime that treats VRAM, RAM, and storage as one managed memory hierarchy. Insufficient fast memory may reduce speed, but the default policy never silently changes model precision or router semantics.

```
$ ./coli chat
  🐦 colibrì v1.0 — GLM-5.2 · 744B MoE · int4 · streaming CPU
  ✓ ready in 32s · resident 9.9 GB
  › ciao!
  ◆ Ciao! 😊 Come posso aiutarti oggi?
```

## The idea

A 744B Mixture-of-Experts model activates only ~40B parameters per token — and only ~11 GB of those change from token to token (the routed experts). So:

- the **dense part** (attention, shared experts, embeddings — ~17B params) stays **resident in RAM at int4** (~9.9 GB);
- the **19,456 routed experts** (75 MoE layers × 256 experts + the MTP head, ~19 MB each at int4) live **on disk** (~370 GB) and are **streamed on demand**, with a per-layer LRU cache, an optional pinned hot-store, and the OS page cache as a free L2.

The engine is a single C file (`c/glm.c`) plus small headers. No BLAS, no Python at runtime, no GPU required (an opt-in CUDA tier for pinned experts exists — see below).

## What's implemented

- **Faithful GLM-5.2 (`glm_moe_dsa`) forward** — validated token-exact against a `transformers` oracle (teacher-forcing 32/32, greedy 20/20 on a tiny-random model with the real architecture).
- **MLA attention** (q/kv-LoRA, interleaved partial RoPE) with **compressed KV-cache**: 576 floats/token instead of 32,768 (57× smaller — GLM-5.2 has 64 heads and no GQA).
- **DeepSeek-V3-style sigmoid router** (noaux_tc, routed_scaling_factor), shared expert, first-3-dense layers.
- **Native MTP speculative decoding** — GLM-5.2's own multi-token-prediction head (layer 78) drafts tokens that the main model verifies in one batched forward. **The head must be int8** (the converter does this by default): at int4 draft acceptance collapses to 0–4% and speculation never engages; at int8 it's 39–59% acceptance, **2.2–2.8 tokens/forward** (community-measured, #8). Lossless *in exact arithmetic* — but **not byte-identical to non-speculative greedy in practice** (#100). This isn't MTP-specific: colibrì's quantized integer kernels are shape-dependent, so any batched (S>1) or GPU forward rounds slightly differently from the single-token path, and int4 GLM-5.2 sits close enough to argmax ties that such a rounding change can flip a token. MTP, the CUDA expert tier, and batched prefill are three different ways to trip the same sensitivity. Every emitted token is still the argmax of a *valid* forward. For byte-exact reproducibility: `DRAFT=0` (no speculation), plus `IDOT=0 COLI_CUDA=0` if you also want kernel-family/GPU independence. Under sampling, rejection sampling keeps the distribution correct. Honest caveat: on a **cold** cache each verified draft routes to extra experts (~660 → ~1100 expert-loads/token), so speculation can be a net *time* loss until the cache/pin warms up.
- **Grammar-forced speculative drafts** (`GRAMMAR=file.gbnf`, #48) — on constrained-output workloads (JSON/NDJSON, function calling, structured extraction) the grammar itself is a third draft source: wherever it admits exactly **one** legal byte (braces, quotes, key names, enum bodies), that forced span is tokenized and injected as pre-accepted drafts with ~1.0 acceptance — no draft head, no lookup table, and it engages even with the int4 MTP head. It never constrains sampling: forced spans are verified in the same batch-union forward as any draft, so a wrong or out-of-sync grammar cannot change the output — worst case is rejected drafts, and an adaptive guard turns the source off below 50% acceptance. Byte-level GBNF subset (literals, char classes, `| ( ) ? * +`, comments); `GRAMMAR_DRAFT=n` caps the forced span per forward (default 24). Composes with `DRAFT`/MTP. Full reference: docs/grammar-draft.md.
- **True sampling** — temperature + nucleus, defaults tuned for int4 reality (0.7 / 0.90; the official 1.0 / 0.95 samples quantization noise from the tail).
- **Integer-dot kernels** (Q8_0-style int8 activations, AVX2 `maddubs`): int8 matmuls 1.4–2.5× faster (119 GFLOP/s measured), int4 1.8× in batch — routing decided per shape by measurement (int4 single-row stays f32: it measured slower).
- **MLA weight absorption** (DeepSeek trick) for decode: no per-token k/v reconstruction — the query absorbs `kv_b`, context is projected after attention. Validated exact: TF 32/32 and generation 20/20 with absorption forced everywhere.
- **Async expert readahead**: while one block of experts is being multiplied, the kernel is already reading the next (`WILLNEED`).
- **Quantization kernels**: int8 / packed int4 / packed int2, per-row scales, AVX2, dequant-on-use. Packing validated bit-identical to the int8 container.
- **DSA sparse attention** — GLM-5.2's lightning indexer, faithful to the reference `glm_moe_dsa` modeling: per-layer top-2048 causal key selection (full/shared indexer layers), auto-detected from the `out-idx-*` weights (`--indexer` converter mode, ~189 MB extracted from the FP8 repo). Validated exact: forcing the selection to keep every key reproduces dense attention token-for-token. `DSA=0` disables, `DSA_TOPK` overrides.
- **KV-cache persistence** — conversations reopen **warm** across engine restarts: serve mode appends the compressed MLA KV to `.coli_kv` after every turn (~182 KB/token, crash-safe) and resumes it at startup with zero re-prefill. Validated byte-identical to an uninterrupted session. `KVSAVE=0` disables.
- **Router-lookahead prefetch** (`PILOT=1`, experimental) — the next layer's routing is 71.6% predictable from the current layer's post-attention state (measured); a dedicated I/O thread prefetches those experts while the current layer computes.
- **Batch-union MoE**: in prefill (and MTP verification), each unique expert of the batch is read once and applied to every position that routes to it.
- **Byte-level BPE tokenizer in C** (GPT-2-style with Unicode-property regex, 320k merges).
- **RAM safety**: the expert cache is auto-sized from `MemAvailable` at startup — an honest peak projection so the kernel OOM-killer never fires.
- **Offline FP8→int4 converter** (`c/tools/convert_fp8_to_int4.py`): downloads one shard at a time (~5 GB), dequants (128×128 block scales), requantizes to the engine's container, deletes the shard — the 756 GB FP8 checkpoint never needs to exist on disk at once. Resumable.

## Honest numbers (WSL2, 12 cores, 25 GB RAM, NVMe via VHDX)

Detailed GPU experiment: GLM-5.2 on 6x RTX 5090 (docs/experiments/glm52-6x5090-2026-07-12.md) — full expert residency across VRAM+RAM reaches 6.84 tok/s single-request decode.

| metric | value |
|---|---|
| model on disk (int4 container) | ~370 GB |
| resident RAM (dense, int4) | 9.9 GB |
| load time | ~30 s |
| peak RSS during chat | ~20 GB (auto-capped) |
| cold decode cost | ~11 GB disk reads/token (75 layers × 8 experts) |
| disk ceiling (this dev box's drive) | ~1 GB/s → ~0.05–0.1 tok/s cold |
| MTP speculation (int8 head) | 2.2–2.8 tok/forward measured (#8) |

This is not fast. It is a 744B frontier-class model **answering correctly on a machine that costs less than one H100 fan**. Warm cache, pinned hot experts and MTP push the useful-response latency down considerably; the physics of the disk does the rest.

### SSD note
Cold starts are heavy on random reads (~11 GB/token), but reads don't meaningfully wear an SSD — colibrì's streaming is read-only. The real concerns under heavy use are (1) **swap traffic** if the system runs out of RAM (keep a sane `--ram` budget) and (2) **sustained thermals**: hours at full read duty cycle will heat cheaper drives. Monitor drive temperature and health.

## Download the model

A pre-converted **GLM-5.2 int4** model for colibrì is available on Hugging Face — **use the version with the int8 MTP heads** (matey-0's clone):

**https://huggingface.co/mateogrgic/GLM-5.2-colibri-int4-with-int8-mtp**

> ⚠️ **The MTP head must be int8.** The original mirror (jlnsrk/GLM-5.2-colibri-int4) ships **int4** MTP heads, which give **0% draft acceptance** — speculation silently never engages. The int8 head gives the measured **39–59% acceptance**. Check: `ls -l <model>/out-mtp-*` · int8 (correct): `3527131672 / 5366238584 / 1065950496` · int4 (0%): `1765523544 / 2686077736 / 536747200`.

```bash
COLI_MODEL=/path/to/GLM-5.2-colibri-int4-with-int8-mtp ./coli chat
```

### Quick start

```bash
cd c
./setup.sh                      # checks gcc/OpenMP, builds, self-tests
# ONE command does everything model-side: downloads GLM-5.2-FP8 shard by shard,
# converts to int4, then converts the MTP head. Resumable.
./coli convert --model /nvme/glm52_i4     # ~400 GB free on ext4/NVMe
COLI_MODEL=/nvme/glm52_i4 ./coli chat
```

Inspect / validate placement before loading:

```bash
COLI_MODEL=/nvme/glm52_i4 ./coli plan
COLI_MODEL=/nvme/glm52_i4 ./coli plan --gpu 0,1 --ram 128 --vram 48 --json
COLI_MODEL=/nvme/glm52_i4 ./coli chat --auto-tier
COLI_MODEL=/nvme/glm52_i4 ./coli doctor          # read-only readiness check
```

`coli plan` reads only safetensors headers and reports the exact dense/expert footprint, RAM reserve, safe expert-cache cap, and bounded VRAM hot tier; it does not allocate tensors. `--auto-tier` applies the plan to chat/run/serve/benchmarks. `coli doctor` validates model dir, config, tokenizer, headers, engine executable, RAM, NVIDIA devices, CUDA linkage — never starts glm. The engine at runtime is pure C; python is only used by the one-time converter.

### Windows 11 (native, no WSL)

colibrì builds/runs natively on Windows 11 x86-64 with MinGW-w64. The port adds a `_WIN32` compatibility layer in `c/compat.h` (pread → ReadFile+OVERLAPPED, posix_fadvise no-op, aligned allocation, MoveFileEx rename, GlobalMemoryStatusEx RAM detection). Toolchain: GCC via winlibs or MSYS2 MinGW-w64 (tested GCC 16.1.0).

```powershell
scoop install mingw-winlibs                    # or: pacman -S mingw-w64-x86_64-gcc make
make glm.exe                                    # static, no DLL deps
make glm.exe ARCH=native                        # enable AVX-VNNI on Alder Lake+
SNAP=D:\glm52_i4 ./glm.exe 64 4 16
python coli chat --model D:\glm52_i4
python coli serve --model D:\glm52_i4
.\warmup.ps1 -Rounds 1 -Ngen 32                # overnight cache priming
```

**NVIDIA GPU (optional, via runtime DLL):** build CUDA backend into standalone `coli_cuda.dll` (nvcc+MSVC), host `glm.exe` loads it via `LoadLibrary` (`c/backend_loader.c`); if the DLL is absent the engine falls back to CPU. `CUDA_ARCH` must match GPU compute capability (`sm_120` Blackwell/RTX50, `sm_89` Ada/RTX40). Status: Phase 1 complete (compiles, correct, static-linked); Windows GPU tier verified on RTX 50-series. O_DIRECT (Phase 2) and full-model oracle validation remain separate workstreams.

### OpenAI-compatible API

`coli serve` keeps one model process loaded and exposes a text-only OpenAI-compatible HTTP API (stdlib-only gateway; inference in the dependency-free C engine).

```bash
COLI_MODEL=/nvme/glm52_i4 COLI_API_KEY=local-secret ./coli serve \
  --host 127.0.0.1 --port 8000 --model-id glm-5.2-colibri
```

Endpoints: `GET /v1/models`, `GET /v1/models/{model}`, `POST /v1/chat/completions`, legacy `POST /v1/completions`. Supports JSON + SSE streaming, usage counts, `max_tokens`/`max_completion_tokens`, `temperature`, `top_p`. Extension `enable_thinking: true` enables GLM-5.2's reasoning block; `reasoning_effort` also enables it unless `none`. First version is deliberately text-only and serves one generation at a time: the 744B model stays in one persistent process, so concurrent HTTP requests **queue** instead of duplicating the model. Tools, image/audio, custom stops, logprobs, token penalties return an explicit error. Default bind localhost; set `COLI_API_KEY` before exposing. Bounded FIFO admission queue: `--max-queue N` (default 8), `--queue-timeout SECONDS` (default 300); saturated/timed-out → HTTP 429. `GET /health` exposes active/queued/completed/rejected; responses include `x-colibri-queue-wait-ms`.

### Isolated KV contexts

`coli serve --kv-slots N` allocates up to 16 independent sequence contexts. Requests select one with the optional integer `cache_slot` field; ordinary clients omit it (slot 0). Each slot owns token history, compressed MLA/DSA KV, MTP window, crash-safe persistence (`.coli_kv`, `.coli_kv.1`, ...). Still one sequence at a time; establishes explicit KV ownership without pretending threaded HTTP is continuous batching. At default 4096-token context, every slot costs hundreds of MB.

### Experimental Metal backend (Apple Silicon)

Unified memory removes the PCIe copy tax → opt-in Metal backend runs routed-expert SwiGLU (batched, zero-copy from RAM slabs), fused decode attention (full MLA layer in one command buffer, S≤4), and prefill's large GEMMs on GPU. Token-exact vs CPU.

```bash
make glm METAL=1          # macOS; shader compiles at runtime, no Xcode
make metal-test
COLI_METAL=1 COLI_MODEL=/path/glm52_i4 ./coli chat --ram 96
```

Measured M4 Max (128 GB, warm, MTP on): CPU 0.30 → Metal **0.42 tok/s (~1.4×)**. Metal's ~5 ms submit latency makes per-matmul dispatch a loss — everything batched into few command buffers per layer; resident experts' GPU work submitted before missed experts' disk reads. `COLI_METAL_GEMM_MIN` tunes prefill GEMM threshold (default 16). Numerics dequant→f32-MAC (same as CUDA); greedy byte-identical to CPU.

### Experimental resident CUDA backend

Opt-in CUDA backend for model-resident tensors. Streaming experts deliberately stay on CPU path (copying an expert NVMe→GPU per use just trades disk for PCIe). Resident quantized tensors uploaded lazily once and reused.

```bash
make CUDA=1
COLI_CUDA=1 COLI_GPU=0 CUDA_DENSE=1 SNAP=/nvme/glm52_i4 ./glm 64 4 4
```

Requirements: Linux, NVIDIA driver, CUDA Toolkit at `/usr/local/cuda` (override `CUDA_HOME`). CUDA defaults to expert-only accelerator; `CUDA_DENSE=1` distributes resident dense/attention tensors round-robin across devices. On six RTX 5090s w/ 150 GB expert tier, a warmed 2-req/64-tok run improved 1.650 → 2.157 aggregate tok/s (+30.8%). `PIN`/`PIN_GB` promote hottest experts into the persistent VRAM tier. `CUDA_EXPERT_GB=auto` + `PIN_GB=all` on a dedicated 251 GiB host w/ six RTX 5090s selected a 176.7 GB VRAM tier + 191.3 GB RAM tier (all 19,456 experts resident) → **6.00 tok/s decode** (up from 2.20), 100% hit rate, zero disk wait — host-specific, not a portable default. Current limits: independent device contexts, synchronous host-staged copies, no P2P/NCCL yet; a single expert is not sharded; correctness-first custom kernels (not cuBLAS/Tensor Core).

### Web interface & dashboard

`web/` — community React + TypeScript UI, pure API client (never touches the engine). Speaks standard OpenAI Chat Completions + SSE. One command serves API **and** web console on the same port:

```bash
cd web && npm install && npm run build   # once
./coli web --model <model-dir>
```

- **Chat** with live metrics (flashing token counter, tok/s, TTFT, prompt→completion counts, queue wait);
- **Runtime panel**: hardware (CPU, GPUs+VRAM, RAM, cores), scheduler, live expert-tier bar (how many of the 19,456 experts sit in VRAM/RAM/disk now);
- **Brain**: the whole model as a 76×256 cortex, one cell per expert. Colour = tier, brightness = routing heat; experts routed each turn flash white and decay. Hover for tier/heat and measured topic affinity (specialists for code, Chinese, math, law live in layers 11–22).

The dashboard talks to the engine over two protocol lines (`TIERS`, `EMAP`/`HITS`) + plain JSON.

### Resource policy & knobs

`--policy quality` / `--policy balanced` preserve checkpoint quantization and router decisions unless `--topk`/`--topp` passed (those lossy overrides warn + proceed). Disk is an immutable recovery source, not a normal decode target. `PIPE=1` deferred cold-expert pipeline (`PIPE_WORKERS=n`, default 8). `--policy balanced` enables lossless live placement (`REPIN=64`, LFRU, ≤4 swaps, 25% hysteresis).

Key knobs: `--temp T` (0.7 + nucleus 0.90; 0=greedy), `--topp 0.7` adaptive expert top-p (30–40% less disk), `--ngen N`, `--repin N`, `AUTOPIN=0`, `THINK=1` reasoning, `DRAFT=n` MTP depth, `GRAMMAR=g.gbnf`, `TF=1` teacher-forcing, `PILOT=1` router-lookahead prefetch, `URING=1` (Linux batched expert I/O), `PIPE=0`, `RAM_GB=<n>`, `CAP_RAISE=0`.

- **Expert cache auto-sizes to RAM (since 2026-07-10)**: the engine now *raises* the LRU cap to fill `--ram` instead of only lowering it. Before this fix a 128 GB machine ran the same 8-experts/layer cache as a 16 GB one (issue #12) — **if you benchmarked before this date, rerun; your numbers were capped.**
- **Router-lookahead prefetch** (`PILOT=1`): applying layer L+1's router to layer L's post-attention state recalls **71.6%** of the true top-8 (vs 41.3% for "same as last token").
- **The learning cache**: engine records routed experts (`.coli_usage`, updated every turn), auto-pins the hottest at startup — colibrì gets faster the more you use it.
- **Conversations reopen warm** (`.coli_kv`, since 2026-07-10): compressed MLA KV persisted after every turn (~182 KB/token, crash-safe), zero re-prefill on reopen, byte-identical to uninterrupted session. `:reset` clears, `KVSAVE=0` disables.

## Got a better machine? Try it — here's what to expect

Built on humble hardware (12 cores, 25 GB RAM, older DRAM-less NVMe behind WSL2 VHDX ~1 GB/s random — note WSL2 VHDX isn't inherently slow: a 5090 box measured 10.5 GB/s O_DIRECT, #101). Needs: Linux/WSL2, macOS, or Windows 11 native (MinGW-w64); gcc w/ OpenMP, AVX2, ≥16 GB RAM, ~370 GB int4 model on local NVMe (ext4/NTFS — never network/9p).

```bash
cd c && ./setup.sh                 # build + self-test (expects 32/32)
gcc -O2 -fopenmp iobench.c -o iobench
./iobench /path/to/glm52_i4/out-00069.safetensors 19 64 8 1   # O_DIRECT true number
COLI_MODEL=/path/to/glm52_i4 ./coli chat
STATS=stats.txt ./coli chat; PIN=stats.txt PIN_GB=20 ./coli chat
./coli bench                       # MMLU/HellaSwag/ARC
```

**Back-of-envelope predictions** (decode is disk-bound: cold token ~11.4 GB reads; MTP ~halves effective cost once warm; RAM turns cold reads into free hits):

| machine | expected |
|---|---|
| this dev box (WSL2 VHDX, ~1 GB/s, 25 GB RAM) | ~0.05–0.1 tok/s cold — proven baseline |
| native Linux, PCIe4 NVMe (~3–5 GB/s), 32 GB | ~0.5–1 tok/s |
| PCIe5 NVMe or 2×NVMe RAID0 (~8–12 GB/s), 64 GB (PIN ~40 GB) | ~2–4 tok/s |
| 128–256 GB RAM, 12 cores (hot experts cached) | ~2–4 tok/s — matmul-bound |
| same RAM + 24–32 cores, or AVX-512/VNNI kernels | ~5–15 tok/s — interactive |

### Community benchmarks (measured)

Stock build (setup.sh, gcc 13), greedy, `--ngen 32`, MTP active:

| machine | config | measured |
|---|---|---|
| Intel Core Ultra 7 270K Plus (24t) · WSL2 · 24 GB · NVMe VHDX (#2) | default | 0.07 tok/s · hit 3–4% · RSS 14.1 GB |
| 〃 | `--topp 0.7` | **0.11 tok/s** · hit 11% |
| Apple M5 Max (18c) · 128 GB unified · SSD (#4,#5) | default, MTP off | **1.06 tok/s** · hit 23% · RSS 21.8 GB |
| Apple M5 Max · **Metal backend** (#72,#87) | Metal · `--ram 96` · 39.7 GB pin · MTP off | **1.83 tok/s** · hit 66% (warmed 1.11→1.83) |
| 〃 · 46.9 GB pin · `--ram 110` · 1024-tok (#103) | Metal (experts+attention) · MTP off | **2.06 tok/s** · hit 72.5% · fastest datapoint yet |
