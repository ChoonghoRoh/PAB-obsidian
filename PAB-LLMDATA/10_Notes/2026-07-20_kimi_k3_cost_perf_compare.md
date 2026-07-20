---
title: "Kimi K3(Moonshot AI) 소개·비용·성능 + Opus 4.8/Fable 5/DeepSeek V4-Pro 비교"
description: "Kimi Code 공식 문서 기반 Kimi K3 소개·요금·벤치마크 종합 + Claude Opus 4.8·Fable 5·DeepSeek V4-Pro 4자 비교(가격·컨텍스트·성능)"
created: "2026-07-20 23:32"
updated: "2026-07-21"
type: "[[RESEARCH_NOTE]]"
index: "[[AI]]"
topics: ["[[PUBLIC_AI]]", "[[MODEL_COMPARISON]]"]
tags: [research-note, kimi-k3, llm-pricing, benchmark, model-comparison, moonshot, deepseek, claude]
keywords: [Kimi K3, Kimi Code, Moonshot AI, Claude Opus 4.8, Claude Fable 5, DeepSeek V4-Pro, SWE-bench, 토큰 가격, MoE, 오픈웨이트, 컨텍스트 윈도우]
sources: ["[[15_Sources/2026-07-20_kimi_k3_cost_perf_compare_source]]", "[[15_Sources/2026-07-21_kimi_k3_platform_docs_source]]", "https://www.kimi.com/code/docs/en/", "https://platform.kimi.ai/docs/guide/kimi-k3-quickstart"]
aliases: ["Kimi K3 비교", "Kimi K3 가격 성능", "LLM 4종 비교 2026"]
---

# Kimi K3(Moonshot AI) 소개·비용·성능 + Opus 4.8 / Fable 5 / DeepSeek V4-Pro 비교

> **정확성 노트**: 벤더마다 벤치마크 스위트가 달라 교차 비교는 **부분적으로만** 성립한다(아래 §4·§5에서 명시). 가격·컨텍스트는 출처 확인값이며, 확인되지 않은 수치는 "미공개"로 표기했다. **"DeepSeek Pro4" = DeepSeek V4-Pro**로 해석했다(2026-04-24 출시 플래그십).

---

## 1. Kimi Code / Kimi K3 개요
[원본 §What is Kimi Code →](2026-07-20_kimi_k3_cost_perf_compare_source.md#what-is-kimi-code)

[[Kimi Code]]는 [[Moonshot AI]]의 **Kimi 멤버십에 포함된 개발자용 AI 코딩 서비스**로, CLI·VS Code 확장·[[Claude Code]] 등에서 코드 읽기·파일 편집·명령 실행을 제공한다. 백엔드는 Moonshot의 최신 플래그십 모델이며, 현재 최상위가 **[[Kimi K3]]**(모델 ID `k3`)이다. K3는 웹 검색 종합상 **2026-07-16 공개된 2.8T 파라미터 [[MoE]] 오픈웨이트 모델**로, 컨텍스트 윈도우는 1M 토큰이다([VentureBeat](https://venturebeat.com/technology/chinas-moonshot-ai-releases-kimi-k3-the-largest-open-source-model-ever-rivaling-top-u-s-systems), [BenchLM](https://benchlm.ai/models/kimi-3)).

- **속도 티어 2종**: Standard / HighSpeed(약 5–6× 빠름), 출력 최대 100 tokens/s.
- **동시성**: 5시간 창당 약 300–1,200 요청, 최대 30 동시.
- K3는 `low`/`high`/`max` **thinking 레벨**을 지원(추론 깊이 조절).

## 2. 모델 라인업 (Kimi Code)
[원본 §Available Models →](2026-07-20_kimi_k3_cost_perf_compare_source.md#available-models)

| 모델 ID | 이름 | 접근 등급 | 특징 |
|---|---|---|---|
| `k3` | Kimi K3 | Moderato+ | 최신 플래그십, thinking low/high/max |
| `kimi-for-coding` | Kimi K2.7 Code | 전 멤버 | 코딩 특화 |
| `kimi-for-coding-highspeed` | Kimi K2.7 Code HighSpeed | Allegretto+ | 고속 |

API는 **OpenAI 호환**(`api.kimi.com/coding/v1`)과 **Anthropic 호환**(`.../v1/messages`) 두 엔드포인트를 노출한다. 즉 기존 OpenAI/Claude SDK 코드로 바로 호출 가능.

## 3. 비용 (멤버십 + API)
[원본 §API Access →](2026-07-20_kimi_k3_cost_perf_compare_source.md#api-access)

Kimi는 **두 과금 체계가 분리**돼 있다 — 멤버십(Kimi Code, 정액)과 공개 API(Kimi Platform, 종량).

**멤버십(음악 템포 등급)** ([Kimi Help Center](https://www.kimi.com/help/membership/membership-pricing)):
| 등급 | 월 요금 | K3 접근 |
|---|---|---|
| Adagio | **무료** | ✅ K3 + Deep Research + 월 200 Professional Data |
| Moderato | $19 | Kimi Code 입문 크레딧 |
| Allegretto | $39 | Kimi Code 확대 할당 |

**K3 공개 API 요금**(1M 토큰당) ([thepricer](https://www.thepricer.org/how-much-does-kimi-k3-cost/)):
- 캐시 입력 **$0.30** · 비캐시 입력 **$3** · 출력 **$15**

## 4. Kimi K3 성능·벤치마크
[원본 §Core Advantages →](2026-07-20_kimi_k3_cost_perf_compare_source.md#core-advantages)

Moonshot·트래커 보고치 (출처: [BenchLM](https://benchlm.ai/models/kimi-3), [NxCode](https://www.nxcode.io/resources/news/kimi-k3-benchmarks-coding-agent-evaluation-guide-2026), [aitoolsreview](https://aitoolsreview.co.uk/insights/kimi-k3-launch)):

| 영역 | 벤치마크 | 점수 |
|---|---|---|
| 코딩 | DeepSWE | 67.5 |
| 코딩 | ProgramBench (raw pass) | 77.8 |
| 코딩 | Terminal-Bench 2.1 | 88.3 |
| 코딩 | FrontierSWE | 81.2 |
| 코딩 | SWE Marathon | 42.0 |
| 지식 | GPQA Diamond | 93.5% (공개시점 오픈웨이트 최고) |
| 에이전트 | BrowseComp | 91.2% (공개시점 최고) |
| 에이전트 | Humanity's Last Exam (w/tools) | 56.0% |
| 에이전트 | MCP Atlas | 84.2% |

> K3는 6개 코딩 벤치마크에서 상위 3위 안에 일관 진입, SWE Marathon·ProgramBench에서 선두. Terminal-Bench 2.1은 GPT-5.6 Sol에 0.5점차 2위로 보고됨.

## 5. 4자 비교 — Opus 4.8 / Fable 5 / DeepSeek V4-Pro / Kimi K3

> Claude 스펙은 Anthropic `claude-api` 레퍼런스(cached 2026-06-24) 기준. DeepSeek는 2026 웹 종합.

### 5.1 가격·스펙 표

| 항목 | **Kimi K3** | **Claude Opus 4.8** | **Claude Fable 5** | **DeepSeek V4-Pro** |
|---|---|---|---|---|
| 모델 ID | `k3` | `claude-opus-4-8` | `claude-fable-5` | `deepseek-v4-pro` |
| 제공사 | Moonshot AI | Anthropic | Anthropic | DeepSeek |
| 컨텍스트 | 1M | 1M | 1M | 1M |
| 최대 출력 | 미공개 | 128K | 128K | 384K |
| 입력 $/1M | $3 (캐시 $0.30) | $5 | $10 | **$0.435** (캐시 $0.003625) |
| 출력 $/1M | $15 | $25 | $50 | **$0.87** |
| 가중치 | 오픈 (2.8T MoE) | 비공개 | 비공개 | 오픈 MIT (1.6T MoE, 49B active) |
| 포지셔닝 | 오픈웨이트 코딩·에이전트 최상위 | SOTA 장기지평 에이전트·지식작업 | Anthropic 최상위, 최난도 추론·초장기 에이전트 | 초저가 오픈웨이트, SWE 상위권 |

가격 출처: Claude = `claude-api` 스킬 모델표 · DeepSeek = [Morph](https://www.morphllm.com/deepseek-v4)·[NxCode](https://www.nxcode.io/resources/news/deepseek-api-pricing-complete-guide-2026) · Kimi = 위 §3.

### 5.2 비용 격차 (출력 토큰 기준)

DeepSeek V4-Pro($0.87)를 1로 두면 — **Kimi K3 ≈ 17× · Opus 4.8 ≈ 29× · Fable 5 ≈ 57×**. (Morph 보고: V4-Pro는 Opus 4.8 대비 출력 토큰당 28.7× 저렴.)

### 5.3 성능 — 교차 비교의 한계 ⚠️

벤더가 **서로 다른 스위트**를 보고해 직접 비교는 제한적이다. 공통 지표는 **SWE-bench Verified** 정도:

| 모델 | SWE-bench Verified | 비고 |
|---|---|---|
| DeepSeek V4-Pro(-Max) | **80.6%** | 오픈웨이트 최고, Gemini 3.1 Pro와 동률 |
| Claude Opus 4.7 | 80.8% | V4-Pro와 통계적 동률([codersera](https://codersera.com/blog/deepseek-v4-pro-review-benchmarks-pricing-2026/)) |
| Claude Opus 4.8 | 미공개(본 조사 출처 없음) | 4.7 상위로 포지셔닝, 정확 수치 미확인 |
| Claude Fable 5 | 미공개 | Anthropic 최상위 포지셔닝 |
| Kimi K3 | 미보고(SWE-bench Verified) | 대신 FrontierSWE 81.2·SWE Marathon 42.0 보고(§4) |

- **Kimi K3**는 SWE-bench Verified가 아닌 FrontierSWE/DeepSWE/SWE Marathon 등으로 보고 → V4-Pro/Claude와 **동일 축 비교 불가**.
- **Claude Opus 4.8·Fable 5**의 공개 벤치 수치는 본 조사 출처에 없어 **의도적으로 비워 둠**(추정 기입 금지). Anthropic 포지셔닝상 Opus 4.8 = 장기지평 에이전트 SOTA, Fable 5 = 최상위 추론.

## 6. 요약·시사점
[원본 §Platform Comparison →](2026-07-20_kimi_k3_cost_perf_compare_source.md#platform-comparison)

- **비용**: DeepSeek V4-Pro가 압도적 최저가(오픈·MIT), Kimi K3가 중간(오픈), Claude가 프리미엄(비공개). 출력 기준 Fable 5는 V4-Pro의 ~57배.
- **성능**: 오픈웨이트 진영(K3·V4-Pro)이 SWE 계열에서 상위권으로 클로즈드 최상위(Opus 4.7 80.8%)에 근접. 단 벤치 스위트가 달라 순위 단정은 위험.
- **선택 가이드**: 초장기 자율 에이전트·최난도 추론 = Claude(Opus 4.8/Fable 5) / 비용 최우선·오픈 자가호스팅 = DeepSeek V4-Pro / 오픈웨이트로 코딩·에이전트 최상위 성능 = Kimi K3.
- **연동 관점**: Kimi Code·DeepSeek 모두 OpenAI 호환 엔드포인트를 노출 → [[Khala]]의 외부 API 모델 스왑(remote 백엔드) 경로와 호환 가능성(로컬 vLLM 대비 한자 드리프트·검증은 별도 확인 필요).

> **한계**: 본 노트의 Claude 벤치 공란과 Kimi/DeepSeek 벤치의 스위트 상이는 **실측 갱신 시 보완 대상**. 가격은 2026-07 시점 스냅샷(할인·개편 가능).

## 7. Kimi K3 플랫폼 기술 상세 (platform.kimi.ai 뎁스 탐색 · 2026-07-21 추가)
[원문 캡처 → [[15_Sources/2026-07-21_kimi_k3_platform_docs_source]]]

`platform.kimi.ai` quickstart + 뎁스 6페이지(pricing·thinking·caching·tool-calling·vision)에서 추가 확보한 K3 기술 상세.

- **모델 ID·API**: `kimi-k3` · base URL `https://api.moonshot.ai/v1`(OpenAI 호환, Bearer `MOONSHOT_API_KEY`). ⚠️ [[Kimi Code]] 구독형 `api.kimi.com/coding/v1`과 **별개** — 종량제 공개 API는 `moonshot.ai`.
- **아키텍처(신규)**: **Kimi Delta Attention(KDA) + Attention Residuals**, [[MoE]] **896 experts 중 16 active**. 2.8T 파라미터·1M 컨텍스트. 네이티브 vision + long-horizon coding.
- **Thinking 상시 ON**: `reasoning_effort` low/high/max(기본 max), Preserved Thinking → `reasoning_content` 반환. 멀티턴·툴콜 시 **assistant 메시지 원형(reasoning_content·tool_calls 포함)을 그대로 재전달 필수**.
- **파라미터**: `max_completion_tokens` 기본 131072·최대 1048576. 고정 temperature=1.0·top_p=0.95·penalties=0.
- **정확 가격(공식 확정)**: 입력 캐시미스 **$3.00** / 캐시히트 **$0.30** / 출력 **$15.00** (1M·USD). 컨텍스트 길이 티어링 없음, 세금 별도. → §3·§5.1 가격과 일치 확인.
- **자동 컨텍스트 캐싱**: 전 요청 자동(캐시ID·TTL 불요), 반복 prefix 감지 → **최대 90% 비용 압축**. 고정 컨텍스트를 `messages` 앞에 배치.
- **동적 tool loading**: `search_tools`+핵심툴만 선언 → 후보 검색 후 시스템 메시지로 tool 정의 주입. `tool_choice` required→auto, **prefix 캐시 무효화 안 함**.
- **Vision**: base64 또는 파일업로드(`ms://`), **URL 이미지 미지원**. PNG/JPEG/WebP/GIF · 최대 4K · 본문 ≤100MB · `content`는 JSON 배열(문자열 직렬화 금지).

> **[[Khala]] 연동 시사점**: `moonshot.ai/v1`은 OpenAI 호환이라 [[Khala]] `REMOTE_BACKENDS`에 [[DeepSeek V4-Pro]] 방식으로 등록 가능. 단 K3는 **thinking 상시 + `reasoning_content` 재전달 필수**라 Khala tool-loop의 메시지 재조립이 이를 보존해야 함(미보존 시 오작동). 자동 캐싱(90%↓)은 고정 시스템 프롬프트 재사용 시 원가 급감 → 배치 수집에 유리.
