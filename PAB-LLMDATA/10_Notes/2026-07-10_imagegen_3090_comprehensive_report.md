---
title: "로컬 이미지 생성(RTX 3090) 종합 평가 — 배포 실측과 클라우드 3자 비교 (PAB-MakeIMG)"
description: "SwarmUI+FLUX/SDXL 하루 배포 실측(DoD 5/5), 동일 프롬프트 GPT/Gemini 3자 통제 비교, 3090 한계 4축과 노동 ROI — 결론은 폐기가 아닌 역할 재배치"
created: 2026-07-10 17:01
updated: 2026-07-10 17:01
type: "[[PROJECT]]"
index: "[[AI]]"
topics: ["[[GPU_MUTEX]]", "[[CLOUD_STRATEGY]]", "[[IMAGE_GENERATION]]"]
tags: [project, imagegen, flux, sdxl, swarmui, rtx3090, cloud-comparison]
keywords: [FLUX.1 Dev, SDXL, SwarmUI, ComfyUI, vLLM, GPU 스왑, GPT Image 2, Nano Banana, CFG 함정, VRAM 배타, 노동 ROI, 프롬프트 이원화]
sources: ["[[15_Sources/2026-07-10_imagegen_3090_comprehensive_report_source]]", "PAB-MakeIMG docs/reports/260710-imagegen-comprehensive-report.html"]
aliases: [이미지생성 종합보고서, 3090 이미지 평가, MakeIMG 종합평가]
---

# 로컬 이미지 생성(RTX 3090) 종합 평가 — 배포 실측과 클라우드 3자 비교

> PAB-MakeIMG 프로젝트 산출물. [[SwarmUI]] 배포 실측 × 연구 검토 교차 분석의 요약본.
> 인터랙티브 원본(SVG 차트·이미지 15장): PAB-MakeIMG `docs/reports/260710-imagegen-comprehensive-report.html`

## 한 줄 결론 — 역할 재배치
[원본 §1. 요약 →](2026-07-10_imagegen_3090_comprehensive_report_source.md#1-요약-executive-summary)

**"폐기가 아니라 역할 재배치."** [[RTX 3090]] 로컬 파이프라인([[SwarmUI]] + [[FLUX.1 Dev]]/[[SDXL]])은 하루 만에 배포·검증 완료(DoD 5/5)됐고 정상 동작한다. 그러나 **극사실 마지막 10%는 어떤 노동으로도 도달 불가**(모델 세대 격차)이며, 3090의 본업인 [[vLLM]] LLM 추론과 **VRAM상 물리적 공존 불가**(21.5+17.1 > 24 GiB)다. 최종 분담:

- **극사실 홍보·발표** → [[GPT Image 2]] (1순위) · [[Gemini Nano Banana]] (2순위)
- **데이터 통제(공공 프로젝트)·대량·API 통합·비실사** → 로컬 [[FLUX.1 Dev]]/[[SDXL]]
- **3090 본업** → [[vLLM]] LLM 추론 (이미지는 간헐 모드)

## 하루 만의 배포 — 과정과 자율 결정
[원본 §2. 개발 과정 →](2026-07-10_imagegen_3090_comprehensive_report_source.md#2-개발-과정-전체-기록)

2026-07-09 21:26 프로젝트 설정 → 22:53 FLUX 검증 완료(DoD 5/5)까지 **약 1.5시간**. [[Docker]] compose 커스텀([[Tailscale]] IP 바인딩), 공식 `InstallConfirmWS` WebSocket API로 설치 마법사 무인 완주, HF 게이티드 라이선스 폴링 자동 감지 등. 권한 이슈 2건·WS 끊김·VRAM 경합 사고 1건을 전부 해결하고 질의 포인트 Q1~Q10으로 자율 결정을 기록. 이후 사용자가 웹 UI로 33장 프롬프트 실험(23:04~23:40) — 이것이 본 평가의 핵심 물증이 됐다.

## 실측 수치 — 시간·VRAM·스왑 비용
[원본 §3. 실측 성능 →](2026-07-10_imagegen_3090_comprehensive_report_source.md#3-실측-성능-데이터)

- **생성 시간(1024², 웜)**: SDXL 8~9초(20st) · FLUX 27~54초(20~28st) · 콜드 로드 FLUX +114초
- **VRAM peak**: vLLM 상시 21.5 GiB / FLUX 17.1 / SDXL 7.4 / ComfyUI idle 0.5 → **어떤 조합도 24 GiB 불가** ([[GPU_MUTEX]])
- **스왑 왕복**: 2~3분 + 조작 2회. 실측 사고 — [[ComfyUI]]가 모델을 쥔 채 vLLM 재기동 → `Exited(1)`. 반드시 "SwarmUI 재시작 → VRAM 확인 → vLLM start" 순서(§10 스왑 절차)
- **오설정 비용**: FLUX에 CFG 7 → 86초를 쓰고도 실루엣 붕괴

## 15장의 물증 — 설정 함정과 진화 서사
[원본 §4. 갤러리 →](2026-07-10_imagegen_3090_comprehensive_report_source.md#4-생성-결과물-상세-갤러리)

PNG 임베디드 메타데이터(모델·프롬프트·steps·CFG·seed·생성시간)를 기계 추출해 전 이미지 재현 가능:

- **G2 사자 비교쌍** (동일 프롬프트·시드): SDXL CFG 7 = 정상 vs **FLUX CFG 7 = 완전 붕괴** — "SD 습관의 함정" 실물
- **G3 군함 6단계 진화**: SDXL 나열형(HUD 소실) → 스텝 50 무효 → FLUX+CFG7(과포화) → **FLUX 문장형 CFG3(컨셉 성공)** → 카메라 힌트 총동원(**로컬 실사 최대치, 렌더 톤 잔존**) → 단순 프롬프트(역효과·후퇴)
- **G4 비실사**: SDXL 아이콘 8초 사용 가능 vs FLUX steps 6 전면 블러(Dev는 20st 미만 불가 — 고속은 Schnell 영역)

## 동일 프롬프트 3자 대결 — 클라우드 격차의 통제 실험
[원본 §4 G5 →](2026-07-10_imagegen_3090_comprehensive_report_source.md#4-생성-결과물-상세-갤러리) · [원본 §7. 클라우드 대비 →](2026-07-10_imagegen_3090_comprehensive_report_source.md#7-클라우드-대비-차이-gpt-image-2-gemini)

**완전히 같은 프롬프트**를 세 시스템에 투입 — 남는 차이는 모델 계층뿐:

| 시스템 | 결과 |
|---|---|
| 로컬 [[FLUX.1 Dev]] | **후퇴** — 전면 블러, 물보라 로우폴리화 |
| [[GPT Image 2]] | 완전 사진 톤 + 지시에 없던 두 번째 함선 배치로 "함대 네트워크" 서사 완성. 결점: 가짜 텍스트 혼입 |
| [[Gemini Nano Banana]] | 2816×1536 최고 실사 밀도 + **판독 가능한 정합 HUD**("SPEED 32 KTS / HDG 084°") |

구조적 원인: 모델 규모·세대 격차, 후처리 파이프라인 유무, 그리고 **프롬프트 이해 계층** — GPT/Gemini는 LLM이 프롬프트를 재해석·증강해 생성기에 전달하지만 로컬은 T5 인코더 직행이라 그 증강을 사람이 수동으로 해야 한다.

## 교차 검증 — 연구 주장 전부 확인 + 신규 발견 2건
[원본 §5. 교차 검증 →](2026-07-10_imagegen_3090_comprehensive_report_source.md#5-연구-보고서와-실측-교차-검증)

연구 보고서(260710-image-generation-research-report.md)의 핵심 주장 7건이 **전부 메타데이터 물증으로 확인**: 모델 오선택(§3.1), CFG 함정(§3.2), FLUX 권장 설정, 카메라 힌트 효과(§3.3), 마지막 10% 불가(§3.4), 클라우드 실측(§3.5 — 실물 수록), 비실사 조건부 적합.

**실측이 추가한 신규 발견 2건**:
1. **프롬프트 계층 비대칭** — 클라우드용 단순 프롬프트를 로컬에 재사용하면 역효과(블러 후퇴). 프롬프트 아카이브는 로컬용(카메라 힌트 필수)/클라우드용으로 **이원 관리** 필수
2. **FLUX 최소 프롬프트의 기본값은 실사가 아님** — "girl" 한 단어 → 3D 애니메이션풍 임의 선택. 실사도 명시적 지시 필요

## 3090의 네 가지 한계
[원본 §6. 한계 분석 →](2026-07-10_imagegen_3090_comprehensive_report_source.md#6-3090-24gb-로컬의-한계-분석)

1. **물리**: 24GB는 현세대 상한이자 차세대 진입 장벽 — FLUX.2 Klein 9B(29GB) 탑재 불가, Ampere는 FP8 가속 부재 → 격차는 시간이 갈수록 확대
2. **운영**: vLLM과 전면 배타([[GPU_MUTEX]]) — 이미지 생성은 구조적으로 간헐 모드. 상시화는 전용 GPU 추가가 선행 조건
3. **품질**: 다중 요소 조합·사진 문법 근사까지는 도달, "진짜 사진" 톤(수면 질감·대기 산란·미세 불완전함)은 불가 — 파인튜닝으로도 소멸 안 됨
4. **노동**: 로컬의 진짜 비용은 전기료가 아니라 사람의 시간(설정 문법 학습·프롬프트 이원 관리·스왑 조작·스토리지) — 클라우드는 이를 구독료에 외주화

## 노동 ROI — 첫 1일이 전부
[원본 §8. 노동 ROI →](2026-07-10_imagegen_3090_comprehensive_report_source.md#8-워크플로-개선-노동-대비-품질-roi)

개선 노동 8종 평가 결과: **① 파라미터 교정(0.5일)과 ② 프롬프트 공학(0.5~1일)이 가치의 대부분**을 실현(붕괴→정상→로컬 최대치). ③ 파인튜닝, ④ 업스케일, ⑤ LoRA(2~5일+)는 전부 **극사실 상한(≈90%)을 돌파하지 못하는** 수확 체감 구간. 클라우드 전환(⑧ 0.1일)은 그 상한을 기본값으로 제공. → **극사실 목표의 로컬 파인튜닝 씨름은 하지 말 것.** 이미 완료: ⭐ 프리셋 "FLUX1 Dev 기본" 서버 배포(재발 방지).

## 운영 수칙과 다음 단계
[원본 §9. 결론 →](2026-07-10_imagegen_3090_comprehensive_report_source.md#9-결론-및-권고) · [원본 §10. 부록 →](2026-07-10_imagegen_3090_comprehensive_report_source.md#10-부록)

**수칙 6조**: ① 용도 판별 먼저(외부 전송 가능+극사실=클라우드) ② 로컬은 프리셋으로 시작 ③ 불만 시 PNG 메타데이터부터 확인 ④ 프롬프트 계층별 이원 관리 ⑤ GPU 전환은 스왑 절차로만 ⑥ VRAM 우선순위는 LLM.

**다음 단계**: 즉시 = 스왑 자동화 스크립트(주 1회+ 사용 시) → 단기 = 프롬프트 아카이브 자산화 → 중기 = SwarmUI REST API 기반 커스텀 React 프론트(내부 사용자 2인+ 시, [[PAB_SSOT]] AutoCycle로) → 보류 = 영상 생성(수요 발생 시 클라우드 종량제부터).

검증된 프롬프트 아카이브(로컬용/클라우드용 원문)는 [원본 §10 부록](2026-07-10_imagegen_3090_comprehensive_report_source.md#10-부록) 참조.
