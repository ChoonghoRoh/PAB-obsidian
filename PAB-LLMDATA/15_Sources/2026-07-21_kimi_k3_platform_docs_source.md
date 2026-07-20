---
title: "Kimi K3 Platform Docs (platform.kimi.ai 원문 캡처)"
description: "Kimi K3 quickstart + 뎁스 탐색(pricing·thinking·caching·tool-calling·vision) 원문 캡처 — KDA 아키텍처·정확 가격·API 파라미터 보존"
created: "2026-07-21"
updated: "2026-07-21"
type: "[[SOURCE]]"
index: "[[AI]]"
topics: ["[[PUBLIC_AI]]", "[[MODEL_COMPARISON]]"]
tags: [source, kimi-k3, moonshot, api, platform-docs]
keywords: [kimi-k3, Kimi Delta Attention, KDA, MoE, reasoning_effort, context caching, tool calling, vision, moonshot.ai, pricing, quickstart]
sources: ["https://platform.kimi.ai/docs/guide/kimi-k3-quickstart", "https://platform.kimi.ai/docs/pricing/chat-k3", "https://platform.kimi.ai/docs/guide/use-thinking-effort", "https://platform.kimi.ai/docs/guide/use-context-caching-feature-of-kimi-api", "https://platform.kimi.ai/docs/guide/kimi-k3-tool-calling-best-practice", "https://platform.kimi.ai/docs/guide/use-kimi-vision-model", "https://platform.kimi.ai/docs/llms.txt"]
aliases: ["Kimi K3 platform docs source", "Kimi K3 API 원문"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층). 페치 2026-07-21 · 출처 platform.kimi.ai (뎁스 탐색 6페이지)

# Kimi K3 Platform Docs — 원문 캡처 (뎁스 탐색)

## 1. Quickstart — `/docs/guide/kimi-k3-quickstart`

- **Model ID:** `kimi-k3`
- **Parameters:** 2.8 trillion
- **Context Window:** 1M tokens (1,048,576)
- **Architecture:** Kimi Delta Attention (KDA) with Attention Residuals; Mixture of Experts (**896 experts, 16 active**)
- **Native Capabilities:** Visual understanding, long-horizon coding
- **Thinking Mode:** Always enabled
- **API Base URL:** `https://api.moonshot.ai/v1` · Auth: Bearer via `MOONSHOT_API_KEY` · OpenAI-compatible SDK (Python 3.9+)
- **Key Parameters:**
  - `reasoning_effort`: "low" | "high" | "max" (default: **max**)
  - `max_completion_tokens`: default **131072**, max **1048576**
  - Fixed: temperature=1.0, top_p=0.95, n=1, penalties=0
- **Pricing model:** flat pay-as-you-go, **no tiering by context length**; input (separate cache hit/miss) + output per-token.

## 2. Pricing — `/docs/pricing/chat-k3`

Per 1M tokens (USD):
- Input (Cache Miss): **$3.00**
- Input (Cache Hit): **$0.30**
- Output: **$15.00**
- Context Window: 1,048,576 tokens
- Notes: automatic context caching supported; no explicit batch discount or context-length tiering; prices exclude applicable taxes (final at checkout by jurisdiction).

## 3. Thinking Effort — `/docs/guide/use-thinking-effort`

- `reasoning_effort` ∈ {"low","high","max"}, default **max**, optional, set at top level of Chat Completions.
- "K3 always has thinking and Preserved Thinking enabled and may return `reasoning_content`."
- Multi-turn/tool calls: "K3 requires the complete assistant message returned by the API to be passed back to messages as-is, including `reasoning_content` and `tool_calls`."
- Code:
```python
completion = client.chat.completions.create(
    model="kimi-k3",
    messages=[{"role": "user", "content": "Your query"}],
    reasoning_effort="high",
)
message = completion.choices[0].message
if hasattr(message, "reasoning_content"):
    print(getattr(message, "reasoning_content"))
```

## 4. Context Caching — `/docs/guide/use-context-caching-feature-of-kimi-api`

- **Fully automatic** — "Context Caching is automatically enabled for all model requests", no manual cache creation/IDs/TTL.
- Automatic detection of repeated initial contexts (system prompts, documents, tools).
- Cost compression "up to 90%" in specific scenarios (exact rates → pricing page).
- Requirement: place large fixed contexts at the beginning of `messages`; keep knowledge/system prompts/tool definitions relatively stable for better hit rates.

## 5. Tool Calling Best Practice — `/docs/guide/kimi-k3-tool-calling-best-practice`

- **Dynamic tool loading** for large tool inventories: declare only `search_tools` + core tools initially; model searches candidate tools, app injects matching tool definitions via system messages containing a `tools` field.
- **tool_choice**: `required` on first turn (ensure retrieval before answering) → `auto` after. "Changing `tool_choice` does not invalidate the prefix cache."
- `reasoning_effort` decided before conversation start; "does not affect the cached prefix" when appended dynamically.
- System messages can carry `tools` fields independently; dynamic tool declarations apply per-request only (not retained server-side); same format as top-level.

## 6. Vision — `/docs/guide/use-kimi-vision-model`

- K3 **natively supports vision** ("The Kimi Vision Model (including `kimi-k3`) can understand visual content...").
- Image transmission: **base64** (`data:image/{format};base64,{data}`) or **file upload** (`ms://` file ID). **URL images NOT supported.**
- Formats: PNG, JPEG, WebP, GIF · max resolution 4K (4096×2160) recommended · request body ≤ 100MB · no per-request image count limit.
- `message.content` must be a JSON array of objects (do NOT serialize to string).

## 7. 문서 인덱스 링크 (탐색 근거)

Thinking Effort `/guide/use-thinking-effort` · Vision `/guide/use-kimi-vision-model` · Structured Output `/guide/response_format` · Partial Mode `/guide/use-partial-mode-feature-of-kimi-api` · Tool Choice `/guide/use-tool-choice` · Dynamic Tool Loading `/guide/use-dynamic-tool-loading` · Tool Calling Best Practice `/guide/kimi-k3-tool-calling-best-practice` · Official Tools `/guide/use-official-tools` · Context Caching `/guide/use-context-caching-feature-of-kimi-api` · Streaming `/guide/utilize-the-streaming-output-feature-of-kimi-api` · Pricing `/pricing/chat-k3` · Docs Index `https://platform.kimi.ai/docs/llms.txt` · Playground `https://platform.kimi.ai/playground` · API Keys `https://platform.kimi.ai/console/api-keys`
