---
title: "AI — Domain MOC"
description: "AI 도메인(LLM·에이전트·NLP·CV·논문) 노트 자동 수집 MOC. type 무관, index가 [[AI]]인 모든 노트."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[DOMAINS]]"]
tags: [moc, domains/ai]
keywords: [moc, ai, llm, agent, nlp]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["AI MOC", "AI Domain Index"]
---

# AI — Domain MOC

## DOMAIN 정의

`AI`는 **인공지능 일반 도메인**이다. 머신러닝·딥러닝·LLM·에이전트·NLP·컴퓨터 비전·강화학습 등 AI/ML 전반의 노트를 모은다. 도구 체인(claude-code 등)은 [[HARNESS]]로 분리하고, 일반 SW 공학(알고리즘/언어)은 [[ENGINEERING]]으로 분리한다.

**포함 주제 예시**: LangGraph, Claude, GPT, multi-agent, prompting, RAG, fine-tuning, attention, transformer, RLHF

## 자동 수집 (dataview)

```dataview
LIST
FROM ""
WHERE index = "[[AI]]"
SORT created DESC
LIMIT 100
```

## 폴백 정적 링크

<!-- moc-build:auto-start -->
- [[2026-06-23_rtx3090_vllm_context_kv_offload_source]] — RTX 3090 환경 NVMe·RAM 컨텍스트 한계 극복 전략 보고서 (원본)
- [[2026-06-23_rtx3090_vllm_context_kv_offload]] — vLLM 컨텍스트 확장 핵심 진단 — 엔진 KV캐시 vs 앱 외부기억 2층위 (RTX3090)
- [[2026-06-01_samsung_sds_public_ax_strategy_source]] — 공공AX 전환 전략: 공공 AI·클라우드 기반 구조 설계 — 삼성SDS 인사이트 원본 (2026)
- [[2026-06-01_samsung_sds_trusted_public_ax_workflow_source]] — 신뢰 기반 공공AX 업무 체계 고도화 전략 — 삼성SDS 인사이트 원본 (2026)
- [[2026-06-01_samsung_sds_public_ax_direction_source]] — 공공AX 추진 방향 및 우선 과제 — 삼성SDS 인사이트 원본 (2026)
- [[2026-06-01_samsung_sds_public_ax_direction]] — 공공AX 추진 방향 및 우선 과제 (삼성SDS, 2026)
- [[2026-06-01_samsung_sds_trusted_public_ax_workflow]] — 신뢰 기반 공공AX 업무 체계 고도화 전략 (삼성SDS, 2026)
- [[2026-06-01_samsung_sds_public_ax_strategy]] — 공공AX 전환 전략 — 공공 AI·클라우드 기반 구조 설계 (삼성SDS, 2026)
- [[2026-05-27_pab_mcp_model_sizing]] — PAB × MCP × 모델 사이즈 — RAG에서 tool-call 위임으로, 로컬 약한 모델 vs 엔터프라이즈 의사결정
- [[2026-05-27_mcp_spec_2026_07_28_rc_source]] — The 2026-07-28 MCP Specification Release Candidate (원본)
- [[2026-05-27_mcp_spec_2026_07_28_rc]] — MCP 스펙 2026-07-28 RC — stateless 프로토콜 + first-class extensions (출시 후 최대 개정)
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
- [[2026-05-04_pab_khala_overview]] — PAB-Khala — 프로젝트 개요
- [[2026-05-03_local_llm_under_3090_source]] — Reddit r/LocalLLaMA — Can you run actually useful LLMs on anything less than 3090? (원문)
- [[2026-05-03_local_llm_under_3090]] — 12GB VRAM(RTX 3060)으로 쓸만한 LLM 호스팅 가능한가 — r/LocalLLaMA 토론 정리
<!-- moc-build:auto-end -->

> Phase 1-4 `wiki moc-build` 명령으로 자동 채워질 placeholder.

- (placeholder — Phase 1-4 `wiki moc-build`에서 자동 채움)

## 인접 도메인

- [[00_MOC/DOMAINS/HARNESS|HARNESS]] — AI 도구 체인 (Claude Code, IDE)
- [[00_MOC/DOMAINS/ENGINEERING|ENGINEERING]] — 일반 SW 공학 (AI 시스템 구현 시 교차)
- [[00_MOC/DOMAINS/KNOWLEDGE_MGMT|KNOWLEDGE_MGMT]] — AI 활용 노트 시스템(LLM-friendly wiki 등)
