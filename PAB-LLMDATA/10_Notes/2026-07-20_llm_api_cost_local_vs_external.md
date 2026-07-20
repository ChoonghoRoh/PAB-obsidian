---
title: "LLM 자료수집 비용 — Khala 로컬 vLLM vs 외부 API 손익분기 (PAB-Prove)"
description: "PAB-Prove 요약 워크로드 기준 로컬 vLLM(RTX 3090) 한계비용 vs 외부 API(DeepSeek/Kimi K3/Claude/GPT) 블렌디드 단가·손익분기·월 시나리오. 무인 기본=로컬(E-4) 근거."
created: "2026-07-20"
updated: "2026-07-21"
type: "[[RESEARCH_NOTE]]"
index: "[[AI]]"
topics: ["[[LOCAL_LLM_HOSTING]]", "[[VLLM]]", "[[PUBLIC_AI]]", "[[KHALA]]"]
tags: [research-note, llm-pricing, cost-analysis, vllm, deepseek, kimi-k3, break-even, e4]
keywords: [LLM 비용, 손익분기, RTX 3090, vLLM, tokens per sec, DeepSeek V4-Pro, Kimi K3, Claude Opus, GPT-5.5, 프롬프트 캐싱, 전력요금, E-4]
sources: ["works/PAB-Prove/docs/reports/R-02-llm-api-cost.md", "https://api-docs.deepseek.com/quick_start/pricing/", "https://openrouter.ai/moonshotai/kimi-k3", "https://platform.claude.com/docs/en/about-claude/pricing", "https://developers.openai.com/api/docs/pricing"]
aliases: ["LLM 비용계산", "로컬 vs 외부 API 비용", "R-02 비용"]
---

# LLM 자료수집 비용 — Khala 로컬 vLLM vs 외부 API 손익분기

> **환율** 1 USD ≈ 1,480원(2026-07). **워크로드 가정**: 위키 요약 1건 = 입력 7,000 + 출력 1,500 = 8,500 tok(82:18). 전문: `works/PAB-Prove/docs/reports/R-02-llm-api-cost.md`. 모델별 상세 비교는 [[2026-07-20_kimi_k3_cost_perf_compare]] 참조.

---

## 1. 외부 API 현행 가격 (per 1M, 요약 블렌디드)

| 모델 | 입력 $/1M | 출력 $/1M | 블렌디드 원/1M |
|---|---|---|---|
| DeepSeek V4-Flash | $0.14 | $0.28 | **244** |
| [[DeepSeek V4-Pro]] | $0.435 | $0.87 | **757** |
| [[Kimi K3]] | $3.00 (캐시 $0.30) | $15.00 | **7,574** |
| Kimi K2.6 | $0.95 | $4.00 | 2,203 |
| [[Claude Opus 4.6]] | $5.00 | $25.00 | 12,624 |
| GPT-5.5 | $5.00 | $30.00 | 13,930 |

> **명명 검증**: `Kimi k3`=실존(2.8T·1M ctx, 입력$3/캐시$0.30/출력$15) · `DeepSeek pro v4`=V4-Pro · `Claude Opus 4.6`=$5/$25(4.8 동일가) · `GPT-5.5`=플래그십(더 최신 5.6 존재).

## 2. 로컬 vLLM 한계비용 (RTX 3090, [[Khala]] 공유)

- 게이트웨이가 24/7 가동 중 → 요약 워커 **한계비용 = 전력비뿐**.
- 배치(~600 tok/s): **33~67원/1M** · 단일스트림(47.6~80 tok/s, Khala 실측 47.6): **250~840원/1M**.
- **≈ DeepSeek Flash 이하 ~ 사실상 0** → **무인 기본=로컬([[VLLM]], E-4)의 핵심 근거**.

## 3. 손익분기 (로컬을 전용자산 고정비 ≈ 55,000원/월로 계상 시)

| 대상 | 원/건 | 손익분기(건/월) |
|---|---|---|
| GPT-5.5 | 118.4 | ~465 |
| Claude Opus 4.6 | 107.3 | ~513 |
| Kimi K3 | 64.4 | ~854 |
| Kimi K2.6 | 18.7 | ~2,940 |
| DeepSeek V4-Pro | 6.4 | ~8,540 |

→ 프리미엄 API(Claude/GPT)는 월 ~500건↑이면 로컬 유리. 저가 API(DeepSeek/Kimi)는 이 워크로드 단독으론 로컬이 이기기 어려움(GPU 대부분 유휴). **공유자산 관점(한계비용)에선 로컬 상시 우위.**

## 4. 권고

- **무인 기본 = 로컬 [[VLLM]](E-4)** — 한계비용≈0·프라이버시·무한호출·환율 방어.
- **고품질 옵트인 1순위 = [[DeepSeek V4-Pro]]**(757원/1M, Claude/GPT의 ~1/17, [[Khala]] `REMOTE_BACKENDS`에 이미 등록).
- **품질 최우선 = [[Claude]]**(Opus). GPT-5.5는 출력 $30 최고가라 요약엔 비효율.
- **[[Kimi K3]]**: 2.8T·1M 플래그십이나 요약 블렌디드 7,574원/1M로 과투자 → 초장문·최고품질 필요 시에만.
- **프롬프트 캐싱**: 고정 시스템/지침을 캐시 히트로 → Claude/GPT 입력 90%↓, DeepSeek 50~120배↓. 대량 백필은 배치 API 50%↓ + **심야 스케줄**(전력 저녁피크 회피).

## 5. 2차 고려

- **가격 변동성**: 모델 세대 6개월 단위 교체 → 워커는 **모델 ID를 설정값으로 추상화**([[Khala]]가 이미 레지스트리化).
- **동시성 한계**: 3090 24GB 단일 → 30B급 1~2개 상주 한계 → 피크 시 외부 API 폴백(옵트인).
- **실측 캘리브레이션**: 처리량·전력·요금이 최대 불확실 → `vllm bench` + 스마트미터 실측 권장.

## 연결

- 자료수집: [[2026-07-20_external_data_collection_tooling]] · 인덱싱: [[2026-07-20_obsidian_indexing_rag_ontology]]
- 모델 상세 비교: [[2026-07-20_kimi_k3_cost_perf_compare]] · [[GPU_MUTEX]] · [[Khala]]
