---
title: "MiniMax-H3 — 33B 옴니모달 비디오 생성 모델의 RTX 3090 24GB 구동 검토"
description: "MiniMax-H3 모델 카드 정리 + 3090 24GB 로컬 구동 타당성 — 원본 BF16(42.5GB+)은 불가, 커뮤니티 양자화(GGUF Q4~Q5+INT8 인코더+오프로딩)로 실사용 가능. 한국은 라이선스 신청서 필요"
created: 2026-08-17 10:20
updated: 2026-08-17 10:20
type: "[[RESEARCH_NOTE]]"
index: "[[AI]]"
topics: ["[[VIDEO_GENERATION]]", "[[LOCAL_LLM_HOSTING]]"]
tags:
  - research-note
  - minimax
  - video-generation
keywords: [minimax-h3, video-generation, rtx-3090, 24gb-vram, gguf, quantization, nvfp4, comfyui, offloading, community-license]
sources: ["[[15_Sources/2026-08-17_minimax_h3_3090_feasibility_source]]", "https://huggingface.co/MiniMaxAI/MiniMax-H3"]
aliases: ["MiniMax-H3", "미니맥스 H3", "H3 3090 검토"]
---

# MiniMax-H3 — 33B 옴니모달 비디오 생성 모델의 RTX 3090 24GB 구동 검토

> **한 줄 결론**: MiniMax-H3는 **텍스트 LLM이 아니라 비디오+오디오 생성 모델**이다. 원본 BF16은
> 3090 24GB 단독 구동 **불가**(체크포인트만 42.5GB+·공식 예시 4 GPU). 커뮤니티 양자화
> (GGUF Q4~Q5 + INT8 텍스트 인코더 + 오프로딩) 경로로는 **실사용 가능** — 단일 3090에서
> 15초 클립+오디오 생성 실증 사례가 있다(10초 ~12분·15초 ~25분).

## 개요 — 전제 정정: LLM이 아니다
[원본 §Model Introduction →](2026-08-17_minimax_h3_3090_feasibility_source.md#model-introduction)

멀티모달 컨텍스트(텍스트·이미지·비디오·오디오)를 통합 이해하고 **네이티브 스테레오 오디오를
동반한 비디오**(4~15초, 최대 2K)를 생성하는 옴니모달 생성 시스템. 즉 현재 PAB 로컬 스택의
[[VLLM]] 텍스트 합성(:8020)에 얹는 [[LOCAL_LLM_HOSTING]] 후보가 아니라, [[ComfyUI]] 계열
**비디오 생성 스택**에 속하는 물건이다. 질문의 "로컬 LLM으로 사용"이라는 전제부터 갈린다.

## 아키텍처·시스템 구성
[원본 §Architecture Specifications →](2026-08-17_minimax_h3_3090_feasibility_source.md#architecture-specifications)
[원본 §System Components →](2026-08-17_minimax_h3_3090_feasibility_source.md#system-components)

- **H3-Omni-Transformer 33B dense**(MoE 아님) — 이 중 ~13B는 AdaLN 계열 분기로 **추론 전용이면 불필요**
- 구성 3계층: H3-Context-IR(전처리 — **비공개·호스티드**) / H3-Base(768p 생성 — 공개) /
  H3-Regenerate-2K(2K 재생성 — **비공개·API만**)
- H3-Encoder는 **Qwen3-VL-32B 기반**(layer 50) — 텍스트 인코더 자체가 대형이라 VRAM 계산에서 무시 못 한다
- VisualVAE(16× 공간·4× 시간 압축) + AudioVAE(32kHz 스테레오)

## 출력 사양·변형
[원본 §Model Variants →](2026-08-17_minimax_h3_3090_feasibility_source.md#model-variants)
[원본 §Output Specifications →](2026-08-17_minimax_h3_3090_feasibility_source.md#output-specifications)

- 변형 2종: **FL2VA**(첫/끝 프레임 지정 T2V) · **Ref2VA**(참조 이미지≤9·비디오≤3·오디오≤3 조합)
- 4~15초 · 24 FPS · 기본 768p(단변) · 한국어 포함 11개 언어

## 공식 배포 요구 — 3090 단독의 벽
[원본 §Deployment →](2026-08-17_minimax_h3_3090_feasibility_source.md#deployment)

- 공식 예시는 **SGLang 4 GPU**(`--num-gpus 4`) · BF16
- 체크포인트 실측: **T2V/I2V 42.47GB · Ref2VA 포함 63.44GB** — BF16 원본은 24GB에 들어갈 여지가 없다
- 여기에 Qwen3-VL-32B 기반 인코더 + VAE(~5.8GB)가 추가

## ★ 3090 24GB 구동 검토 (조사 종합)

**⑴ 원본(BF16): 불가.** 위 수치로 종결 — 42.5GB 체크포인트 + 대형 인코더 + 비디오 latent
활성 메모리를 24GB에 넣을 방법이 없다.

**⑵ 양자화 경로: 가능 — 실증 사례 있음.** 단일 3090(24GB·시스템 RAM 31GB)에서 **15초
클립+오디오 생성 성공** 사례(tonyd2wild/minimax-h3-local). 핵심 플래그:
`--disable-pinned-memory --fp16-intermediates` (ComfyUI가 리눅스에서 시스템 RAM 90%를
page-lock하는 문제 회피). 체감 속도: **10초 클립 ~12분 · 15초 클립 ~25분** — 배치 생성용이지
대화형은 아니다.

**⑶ 24GB 권장 조합** (커뮤니티 가이드 종합):
| 구성 요소 | 권장 | 크기 |
|-----------|------|------|
| UNet(Transformer) | **GGUF Q5_K_M** (24GB 기준 권장) | 23.9GB — 오프로딩 전제. 여유를 원하면 Q4 계열 |
| 텍스트 인코더 | `qwen3vl_32b_minimax_h3_int8_convrot.safetensors` (INT8) | 14.6~27.1GB — 순차 로드/오프로딩 |
| VAE | Visual+Audio | ~5.8GB |

GGUF Q2~Q5·pruned INT4/INT8·NVFP4까지 커뮤니티 양자화 4개 저장소가 공개돼 있고(8월 3일),
대부분 ComfyUI 워크플로 동봉. ComfyUI는 Day-0 네이티브 지원.

**⑷ PAB 환경 판단**: 3090 24GB로 "돌아간다"는 답은 **ComfyUI + GGUF Q4~Q5 + 오프로딩**
조합에 한정된다. 상시 서비스(수집 파이프라인류)에 붙일 물건은 아니고, 필요 시 온디맨드
배치 생성 용도가 현실적. vLLM 스택과는 무관하므로 기존 Qwen3.6-27B 서빙과 GPU를 공유하려면
**동시 상주 불가** — 전환 운용(GPU mutex)이 필요하다.

## 라이선스 주의 — 한국은 신청서 필요
[원본 §License →](2026-08-17_minimax_h3_3090_feasibility_source.md#license)

**MiniMax H3 Community License** — 오픈웨이트지만 **미국·EU·영국·한국은 신청서(application
form) 제출이 요구**된다. 한국 사용자인 우리에게 직접 해당 — 로컬 다운로드·사용 전 신청 절차
확인 필수. (Apache/MIT류 무조건 자유 사용이 아님.)

## 조사 출처 (2026-08-17 검색)

- [tonyd2wild/minimax-h3-local — 단일 3090 15초 클립 실증](https://github.com/tonyd2wild/minimax-h3-local)
- [MiniMax H3 Community Quants: GGUF, INT4, NVFP4 (ComfyUI Wiki)](https://comfyui-wiki.com/en/news/2026-08-03-minimax-h3-community-quants)
- [MiniMax H3 Day-0 Support in ComfyUI (공식 블로그)](https://blog.comfy.org/p/minimax-h3-day-0-support-in-comfyui)
- [MiniMax H3 GGUF: Quant Levels, Sizes & Low-VRAM Setup](https://minimaxh3.co/open-source/gguf)
- [MiniMax H3 Requirements: VRAM, INT8 vs FP8](https://wan2-7.io/blog/minimax-h3-local-requirements/)
- [molbal/MiniMax-H3-GGUF](https://huggingface.co/molbal/MiniMax-H3-GGUF) · [Abiray/MiniMax-H3-Pruned-GGUF](https://huggingface.co/Abiray/MiniMax-H3-Pruned-GGUF)
