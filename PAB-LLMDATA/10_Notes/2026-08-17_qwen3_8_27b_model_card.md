---
title: "Qwen3.8-27B — Qwen 오픈모델 최신 세대 비전-언어 모델 카드 정리"
description: "Hugging Face Qwen3.8-27B 모델 카드 정리 — Gated DeltaNet 하이브리드 아키텍처·262K 네이티브 컨텍스트·비전-언어 통합·에이전트 벤치마크·배포 옵션"
created: 2026-08-17 10:05
updated: 2026-08-17 10:05
type: "[[RESEARCH_NOTE]]"
index: "[[AI]]"
topics: ["[[QWEN]]", "[[LOCAL_LLM_HOSTING]]"]
tags:
  - research-note
  - qwen
  - llm
keywords: [qwen3.8, 27b, gated-deltanet, hybrid-attention, vision-language, reasoning-effort, yarn, long-context, agentic, apache-2.0]
sources: ["[[15_Sources/2026-08-17_qwen3_8_27b_model_card_source]]", "https://huggingface.co/Qwen/Qwen3.8-27B"]
aliases: ["Qwen3.8-27B", "큐원3.8"]
---

# Qwen3.8-27B — Qwen 오픈모델 최신 세대 비전-언어 모델 카드 정리

## 개요
[원본 §Model Introduction →](2026-08-17_qwen3_8_27b_model_card_source.md#model-introduction)

[[QWEN]] 팀이 공개한 오픈모델 계열의 최신 세대. Qwen3.5 기반 위에 코딩·전문 작업·리서치·장기 에이전트 과업을 강화했고, 이미지·비디오를 네이티브로 이해하는 **비전-언어 통합 모델**이다. 현재 PAB 로컬 스택이 [[VLLM]]으로 호스팅 중인 Qwen3.6-27B와 같은 27B급의 후속 세대라는 점에서 [[LOCAL_LLM_HOSTING]] 갱신 후보로 주목할 만하다.

## 하이라이트
[원본 §Qwen3.8 Highlights →](2026-08-17_qwen3_8_27b_model_card_source.md#qwen38-highlights)

- 코딩·전문 작업·리서치·**장기(long-horizon) 에이전트 과업** 전반 개선
- 자율 계획·환경 피드백 처리 강화 (에이전트 실행 축)
- 사고(thinking)는 기본 활성 — `reasoning_effort`(xhigh/medium/low)로 조절
- 이미지·비디오 네이티브 이해

## 아키텍처 사양
[원본 §Model Architecture →](2026-08-17_qwen3_8_27b_model_card_source.md#model-architecture)

| 항목 | 값 |
|------|-----|
| 파라미터 | 27B |
| 히든 차원 / 레이어 | 5120 / 64 |
| 레이아웃 | 16 × (3 × (Gated DeltaNet → FFN) → 1 × (Gated Attention → FFN)) — **하이브리드 어텐션** |
| 컨텍스트 | 네이티브 262,144 → YaRN으로 1,000,000까지 확장 |
| 토큰 임베딩 | 248,320 (패딩 포함) |

선형 계열(Gated DeltaNet) 3층마다 표준 어텐션 1층을 섞는 구조로, 장문 컨텍스트 비용을 낮추면서 검색 정밀도를 보전하는 설계다.

## 벤치마크
[원본 §Benchmark Results →](2026-08-17_qwen3_8_27b_model_card_source.md#benchmark-results)

- **텍스트**: SWE-bench Pro 61.7 · Terminal Bench 2.1 73.0 · GPQA Diamond 89.2 · LiveCodeBench v6 90.3
- **비전-언어**: OSWorld-Verified 84.3 · WebArena-Verified 64.8 · AndroidWorld 81.9 · MathVision(CI) 94.6

27B급에서 에이전트·코딩 벤치마크 수치가 두드러진다 — 특히 OS/웹/모바일 조작 계열(OSWorld·WebArena·AndroidWorld)은 비전 통합의 실효를 보여주는 축.

## 사용법·추론 설정
[원본 §Usage Examples →](2026-08-17_qwen3_8_27b_model_card_source.md#usage-examples)
[원본 §Configuration Parameters →](2026-08-17_qwen3_8_27b_model_card_source.md#configuration-parameters)

- OpenAI 호환 Chat API로 호출 — `reasoning_effort` 파라미터로 사고 강도 지정
- 이미지는 `image_url`, 비디오는 URL + `fps` 프레임 샘플링으로 입력
- 권장 샘플링: **사고 모드**(기본) temperature 1.0 · top_p 0.95 · top_k 20 / **인스트럭트 모드** temperature 0.7 · top_p 0.80 · presence_penalty 1.5
- 사고 내용을 대화 턴 간 보존(Preserved Thinking)하는 것이 기본값

## 배포 옵션
[원본 §Deployment Options →](2026-08-17_qwen3_8_27b_model_card_source.md#deployment-options)

SGLang · [[VLLM]] · TokenSpeed · Hugging Face Transformers 지원. PAB 환경 기준으로는 기존 vLLM 스택(:8020) 재사용이 자연스러운 경로 — 다만 하이브리드 어텐션 아키텍처의 vLLM 지원 버전 요구는 도입 시 확인 필요.

## 라이선스·인용
[원본 §License →](2026-08-17_qwen3_8_27b_model_card_source.md#license)
[원본 §Citation →](2026-08-17_qwen3_8_27b_model_card_source.md#citation)

**Apache 2.0** — 상용·수정·재배포 자유. 인용은 Qwen 팀 2026년 8월 발표(Qwen3.8-Max: A New Bar for Coding and Cowork).
