---
title: "로컬 LLM 한계 사다리 실험 — 기존 하드웨어로 어디까지 (3800X/24GB GPU/64GB RAM)"
description: "콜리브리 디스크 스트리밍 대신 RAM 상주+vRAM 연산(MoE 오프로딩)으로 27B→106B까지 사다리로 올라가며 하드웨어 한계를 체감하는 실험 프로토콜. 주력 llama.cpp -ot exps=CPU."
created: 2026-07-16 22:14
updated: 2026-07-16 22:14
type: "[[PROJECT]]"
index: "[[AI]]"
topics: ["[[LOCAL_LLM_HOSTING]]", "[[MOE_OFFLOADING]]"]
tags: [project, local-llm, moe, llama-cpp, ktransformers, benchmark, khala, gguf]
keywords: [limit ladder, MoE offloading, llama.cpp, -ot exps=CPU, -ngl, GLM-4.5-Air, ktransformers, Q4, mmap paging, tok/s, REMOTE_BACKENDS, 3800X, Zen2, 24GB GPU, 64GB RAM]
sources: ["[[15_Sources/2026-07-16_local_llm_limit_ladder_source]]", "PAB-Khala docs/reports/2026-07-16-로컬LLM-한계사다리-실험프로토콜.md"]
aliases: ["한계 사다리 실험", "로컬LLM 한계 실험", "limit ladder experiment"]
---

# 로컬 LLM 한계 사다리 실험 — 기존 하드웨어로 어디까지

> **한 줄 정의**: Ryzen 3800X · 24GB GPU · 64GB RAM으로 **로컬 LLM을 어디까지 돌릴 수 있는지**
> 27B→106B까지 사다리로 올라가며 한계선을 체감하는 실험 프로토콜.
> 발단은 [[콜리브리]](GLM-5.2 744B 디스크 스트리밍) 도입 제안이었으나, 의도가 "대형 모델 도입"에서
> **"하드웨어 한계 체감"**으로 재정의됨. 정본: PAB-Khala `docs/reports/2026-07-16-로컬LLM-한계사다리-실험프로토콜.md`.

## 왜 이 실험인가 — 메모리 3계층
[원본 요약 →](2026-07-16_local_llm_limit_ladder_source.md#요약)

로컬 대형 모델은 가중치를 **어디에 두느냐**로 속도·크기가 갈린다.

| 방식 | 상주 | 크기 한계 | 속도 |
|---|---|---|---|
| ① [[vLLM]] (현재 [[KHALA\|Khala]]) | 전량 vRAM(24GB) | ~27B int4 | 최고속 |
| **② RAM 상주 + vRAM 연산** ← 이 실험 | 시스템 RAM | RAM 용량까지 | 중간 |
| ③ [[콜리브리]] (디스크 스트리밍) | NVMe 디스크 | 사실상 무제한 | 최저속 |

찾는 것은 **②**: 콜리브리처럼 디스크로 내려가기 전, RAM에 얹고 vRAM으로 가속하는 중간 계층
(= [[MOE_OFFLOADING\|MoE 오프로딩]]).

## 하드웨어 예산 — ~106B가 천장
[원본 MoE 오프로딩 원리 →](2026-07-16_local_llm_limit_ladder_source.md#moe-오프로딩-원리)

```
가중치 예산 ≈ vRAM 24GB + RAM 64GB − 오버헤드 ≈ 실질 ~70GB
Q4(int4) ≈ 0.56 GB / 1B → ~100–110B = "메모리에 온전히 얹히는" 천장
```

**MoE가 핵심**: GLM-4.5-Air는 총 106B라도 토큰당 ~12B만 활성 → 전문가를 RAM에 둬도 매 토큰
GPU로 옮기는 양이 작아 **밀집 70B보다 빠를 수 있다**. 병목은 DDR4 대역폭(~50GB/s)과 Zen2의
AMX 부재(→ AVX2 경로).

## 실험 사다리 (단 0→3)
[원본 단별 프로토콜 →](2026-07-16_local_llm_limit_ladder_source.md#단별-프로토콜)

| 단 | 모델 | 방식 | 예상 decode |
|---|---|---|---|
| **0 기준** | 27B int4 | 전량 vRAM (`-ngl 99`) | ~30–40 tok/s |
| **1** | ~70B 밀집 Q4 | GPU/CPU 레이어분할 (`-ngl 40`) | ~3–6 tok/s |
| **2 스윗스팟** | GLM-4.5-Air 106B MoE | 전문가만 RAM (`-ot exps=CPU`) | ~5–10 tok/s |
| **3 천장** | context 확대 / ~120B | RAM 포화 → 64GB 벽 특정 | 급락 |

- **단2가 본론**: `-ngl 99 -ot "exps=CPU"` → 어텐션·공유·KV는 vRAM, 라우팅 전문가는 RAM.
- **단3 판정**: decode 급락 + 디스크 read 폭증이 동시 발생하는 순간 = mmap 페이징 시작 = 벽.
- (범위 밖) 그 위로 200B–744B를 밀면 콜리브리식 디스크 스트리밍(<1 tok/s) 절벽.

## 주력 도구 — llama.cpp
[원본 도구와 설치 →](2026-07-16_local_llm_limit_ladder_source.md#도구와-설치)

`llama-server`(GGUF)를 주력으로: `-ngl`(레이어 분할) · `-ot "exps=CPU"`(MoE 전문가 CPU 고정) ·
**mmap**(RAM 초과 시 자동 디스크 페이징 → 파라미터만 바꿔 단1→3 연속 체감) · tok/s 로그 · OpenAI
호환 서버 내장. 비교군으로 **ktransformers**(MoE 특화지만 Zen2는 AVX2 경로) 선택 A/B.

## 측정 지표
[원본 측정 지표 →](2026-07-16_local_llm_limit_ladder_source.md#측정-지표)

단마다 동일: 로드 성공 / vRAM·RAM 점유 / prefill tok/s / **decode tok/s** / OOM 전 최대 context.
동일 고정 프롬프트로 `/v1/chat/completions` 반복 측정. **표는 빈칸(실측값)으로 두고 후속 실행에서
채운다** — 그 실행이 프로토콜의 최종 검증.

## Khala 연계 (배선 가능성)
[원본 Khala 연계 →](2026-07-16_local_llm_limit_ladder_source.md#khala-연계)

각 엔진이 OpenAI 호환 서버라 [[콜리브리]]·DeepSeek와 **동일하게** Khala `REMOTE_BACKENDS`
(`openai_chat.py:28-31`)에 1줄 등록 → `is_remote_model()` 매칭으로 [[GPU_MUTEX\|arbiter]] 우회
(`tools.py:122-124`) → 기존 vLLM 27B와 GPU 미충돌 공존. `model_swap_ab.py`로 A/B 실측 가능.
**실험 엔진이 곧 Khala 백엔드**가 되는 구조(실제 등록은 별도 승인).

## 실행 전 확인 (가정 금지)
[원본 미확인 체크리스트 →](2026-07-16_local_llm_limit_ladder_source.md#미확인-체크리스트)

GPU 카드 정확 모델 · GLM-4.5-Air Q4 GGUF 가용성 · ktransformers GLM 지원(Zen2 AVX2) · NVMe
여유 용량(100GB+) · `-ot "exps=CPU"` 정규식이 대상 GGUF 전문가 텐서명과 매칭되는지.
