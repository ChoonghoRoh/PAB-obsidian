---
title: "[원본] 로컬 이미지 생성(RTX 3090) 종합 평가 보고서 전문 (PAB-MakeIMG, 2026-07-10)"
description: "PAB-MakeIMG 프로젝트의 SwarmUI 배포 실측 × 이미지 생성 모델 연구 교차 분석 보고서 HTML의 전문 텍스트 보존본"
created: 2026-07-10 17:01
updated: 2026-07-10 17:01
type: "[[SOURCE]]"
index: "[[AI]]"
topics: ["[[GPU_MUTEX]]", "[[CLOUD_STRATEGY]]", "[[IMAGE_GENERATION]]"]
tags: [source, imagegen, flux, sdxl, swarmui, rtx3090]
keywords: [FLUX.1 Dev, SDXL, SwarmUI, ComfyUI, vLLM, GPU 스왑, GPT Image 2, Nano Banana, CFG, VRAM, 노동 ROI]
sources: ["PAB-MakeIMG 저장소 docs/reports/260710-imagegen-comprehensive-report.html (69KB, 이미지 15장 별도)"]
aliases: [이미지생성 종합보고서 원본, imagegen 3090 report source]
---

> ⚠️ 변경 금지 — 원본 immutable 보존
> 원본: PAB-MakeIMG 저장소 `docs/reports/260710-imagegen-comprehensive-report.html` (인터랙티브 HTML — SVG 차트·호버 툴팁·이미지 15장 포함).
> 본 파일은 그 텍스트 콘텐츠의 무손실 마크다운 변환본이다. 이미지는 원본 저장소 `docs/reports/images/`의 파일명으로 참조 표기.

# 로컬 이미지 생성(RTX 3090) 종합 평가 보고서 — 원문 전문

- 작성일: 2026-07-10 · 프로젝트: PAB-MakeIMG
- 환경: Ryzen 3800X · RTX 3090 24GB · 32GB RAM · SwarmUI v0.9.8.1 (Docker) · Tailscale 내부망
- 1차 소스: `260710-image-generation-research-report.md` · `swarmui-deployment-plan.md` · 서버 생성물 35장(13장 수록) + 클라우드 실물 2장(GPT Image 2·Gemini) · PNG 임베디드 메타데이터

## 1. 요약 (Executive Summary)

**결론은 "폐기가 아니라 역할 재배치"다.** 3090 로컬 이미지 생성 파이프라인(SwarmUI + FLUX.1 Dev/SDXL)은 하루 만에 배포·검증까지 완료됐고(DoD 5/5) 기술적으로 **정상 동작**한다. 그러나 35장의 실제 생성 실험과 클라우드(GPT Image 2, Gemini Nano Banana) **동일 프롬프트 통제 비교(G5 — 실물 수록)** 결과, **극사실(photoreal) 마지막 10%는 프롬프트·설정·노동을 아무리 투입해도 로컬 모델 세대 격차로 도달 불가**함이 확인됐다. 동시에 3090의 본업(vLLM LLM 추론)과 이미지 생성은 **VRAM상 물리적으로 공존 불가**(21.5 + 17.1 GiB > 24 GiB)라 전환 노동이 상시 발생한다.

핵심 수치 (전부 실측):
- SDXL 1024²: **8~9초** (20 steps) · peak VRAM 7.4 GiB — 가볍고 빠름
- FLUX.1 Dev FP16 1024²: **27~54초** (20~28 steps) · peak VRAM 17.1 GiB · OOM 0건 — 콜드 스타트 시 모델 로드 +114초
- vLLM(Qwen3.6-27B) 상시 예약 21.5 GiB → **이미지 생성과 동시 구동 불가**, 전환 절차(§10 스왑) 왕복 실측 약 3~4분
- 설정 실수의 비용: FLUX에 SDXL 습관(CFG 7)을 적용하면 **86초를 쓰고도 실루엣 붕괴**

### 최종 역할 분담 (연구 보고서 §1 승계 + 실측 근거 보강)

| 용도 | 권장 도구 | 실측/근거 |
|---|---|---|
| **극사실 홍보·발표 이미지** | GPT Image 2 (1순위) · Gemini Nano Banana (2순위) | 동일 프롬프트 3자 대결(G5)로 실물 확정 — 로컬 09 후퇴 vs GPT 함대 서사(14) vs Gemini 완전 실사+HUD(15) |
| 이미지 안 텍스트(로고·문구) | Ideogram / 배경만 AI + Figma 마감 | 연구 §4 — 텍스트 렌더링 정확도 최상위 |
| **내부용(데이터 통제)** | 로컬 FLUX.1 Dev | 공공 프로젝트 자료는 클라우드 선택지 없음 — 유일 대안 |
| 대량·반복·API 통합 | 로컬 3090 | 종량제 비용 0, SwarmUI REST API 검증 완료 (본 배포에서 API로 생성 성공) |
| 비실사(일러스트·아이콘) | 로컬 (조건부) | 갤러리 13(SDXL 아이콘) 양호 — 단 **설정 준수 전제** (12번: steps 6 → 전면 블러) |
| **LLM 추론 (3090 본업)** | 로컬 3090 (vLLM) | 이미지 미사용 시 24GB를 Khala/Qwen에 온전히 할당 |

## 2. 개발 과정 전체 기록

### 2.1 타임라인 (2026-07-09 ~ 07-10)

| 시각 (KST) | 단계 | 내용 · 결과 |
|---|---|---|
| 07-09 21:26 | 프로젝트 설정 | PROJECT.md를 PAB-MakeIMG(fullstack/docker)로 재작성, hooks.env 동기화 |
| 07-09 21:43 | **Phase 0** 사전 점검 | GPU/드라이버/passthrough 정상, 디스크 630G 여유. ⚠ vLLM이 VRAM 94% 상시 점유 확인(지시서의 최대 리스크 적중), RAM은 64GB가 아닌 32GB로 실측 정정 |
| 07-09 21:46~22:05 | **Phase 1** SwarmUI 배포 | 공식 저장소 클론(커밋 8705bcc) → 커스텀 compose(Tailscale IP 바인딩 + restart 정책) → 빌드 → 기동. 이슈 2건: named volume 소유권(공식 fixch로 해결) · CustomWorkflows bind mount root 소유(일회성 컨테이너 chown) |
| 07-09 22:09~22:19 | 초기 설정 자동화 | 공식 InstallConfirmWS WebSocket API 호출로 마법사 무인 완주. WS keepalive 끊김에도 서버측 설치 완주 → ComfyUI 백엔드(venv 포함 ~10GB) 자동 설치·등록·기동 |
| 07-09 21:56~22:17 | **Phase 2** 모델(1) | SDXL base 6.9GB 다운로드(빌드와 병렬) → 모델 인식 확인 |
| 07-09 22:20 | **Phase 3** 내부망 | 0.0.0.0 바인딩 + 호스트 매핑은 Tailscale IP 한정. 타 기기(WSL)에서 HTTP 200. ufw는 Docker가 우회하므로 실질 보호는 IP 바인딩(Q6) |
| 07-09 22:20~22:24 | **Phase 4** 검증(1) SDXL | vLLM 일시 중지(승인 Q1) → SDXL 1장 8.99초 성공 → 재시작 보존 테스트 통과 → vLLM 복귀. 도중 경합 실측: ComfyUI가 모델을 VRAM에 쥔 채 vLLM 재기동 → Exited(1) → §10 스왑 절차로 정식화(Q8) |
| 07-09 22:26 | 1차 알림 | 텔레그램 배포 완료 통지(conductor 봇 재활용, Q9) |
| 07-09 22:33~22:48 | Phase 2 모델(2) | 사용자 HF 라이선스 동의(gated:auto — 폴링 자동 감지) → FLUX.1 Dev 세트 29.5GB 다운로드(UNet FP16 23.8GB + VAE + 인코더 2종, 30~58MB/s) |
| 07-09 22:50~22:53 | **Phase 4** 검증(2) FLUX | vLLM 중지 → FLUX 1장 141초(로드 포함) · peak 17.1 GiB · OOM 0건 → 시각 검증 통과 → vLLM 복귀 → 생성 이미지 2장 텔레그램 전송. **DoD 5/5 달성** |
| 07-09 23:04~23:40 | **사용자 프롬프트 실험** | 웹 UI로 33장 생성 실험 — 군함(모델 비교), 사자(동일 시드 비교쌍), 인물, 아이콘류. 본 보고서 갤러리의 핵심 물증 |
| 07-10 새벽~오후 | 연구·비교 | 클라우드(GPT Image 2/Nano Banana) 동일 컨셉 비교, 프롬프트 기법 검증 → 260710-image-generation-research-report.md 작성 |
| 07-10 | 본 보고서 | 연구 자료 × 실측 데이터 × PNG 메타데이터 교차 분석 → 종합 평가 |

### 2.2 배포 중 자율 결정 사항 (질의 포인트 Q1~Q10)

| # | 결정 | 요지 |
|---|---|---|
| Q1 | vLLM 공유 전략 | 검증 시 일시 중지 → 재기동 (사용자 사전 승인) — DoD의 FLUX FP16 완전 검증을 위한 유일 경로 |
| Q2 | FLUX 수급 | HF 토큰 정식 발급 (사용자) — 게이티드 라이선스 준수 |
| Q3 | Install 마법사 | 공식 WebSocket API로 자동화 — 브라우저 개입 제거 |
| Q4/Q6 | 노출 제어 | 호스트 포트를 Tailscale IP에만 바인딩. ufw 규칙은 Docker 우회로 무의미 판단 |
| Q5 | 재시작 정책 | restart: unless-stopped — 재부팅 자동 복구 |
| Q7 | 검증 순서 | SDXL 선검증(토큰 대기와 분리) — vLLM 중단 창 2회 비용 감수 |
| Q8 | VRAM 경합 해소 | vLLM 재기동 전 SwarmUI 재시작(VRAM 해제) — §10 스왑 절차로 정식화 |
| Q9 | 알림 채널 | PAB_TELEGRAM_* 미설정 → 서버 conductor 봇 재활용(값 비노출) |
| Q10 | "FLUX로 변경" 해석 | 서버 강제 기본 모델 설정 부재 → ⭐ 프리셋 "FLUX1 Dev 기본" 생성으로 구현 |

## 3. 실측 성능 데이터

모든 수치는 생성물 PNG에 임베드된 SwarmUI 메타데이터(generation_time)와 배포 중 nvidia-smi 1초 샘플링에서 추출한 실측값.

### 3.1 생성 시간 — SDXL은 한 자릿수 초, FLUX는 수십 초

1024×1024 1장 생성 시간 (웜 스타트, 실측):

| 케이스 | 시간 |
|---|---|
| SDXL 호수 (20st) | 9.0초 |
| SDXL 군함 (20st) | 8.4초 |
| SDXL 군함 (50st) | 17.9초 |
| FLUX 여우 (20st) | 27.0초 |
| FLUX 군함 (20st) | 35.1초 |
| FLUX 군함·실사기법 (28st) | 44.8초 |
| FLUX 군함·단순화 (28st) | 54.5초 |
| FLUX 사자 ⚠오설정 (CFG7) | 86.1초 ⚠ |

오설정(FLUX에 CFG 7 + refiner) — 시간은 2.5배, 품질은 붕괴. 콜드 스타트(모델 첫 로드)는 별도로 FLUX +114초/SDXL +1초 소요.

### 3.2 VRAM — 24GB 한 장 위의 동거 불가 지도

구성 요소별 VRAM 점유 (실측, GiB) · RTX 3090 물리 한계 24 GiB:

| 구성 요소 | VRAM |
|---|---|
| vLLM (상시 예약, --gpu-memory-utilization 0.90) | 21.5 GiB (22,039 MiB) |
| FLUX.1 Dev FP16 생성 peak | 17.1 GiB (17,466 MiB) |
| SDXL 생성 peak | 7.4 GiB (7,559 MiB) |
| ComfyUI idle (모델 언로드) | 0.5 GiB |

vLLM(21.5) + FLUX(17.1) = **38.6 GiB**, vLLM + SDXL도 28.9 GiB — 어느 조합도 24 GiB 안에 들어가지 않는다. 실측 사고: ComfyUI가 SDXL을 쥔 채(7.4) vLLM을 재기동 → 즉시 Exited(1). 전환은 반드시 §10 스왑 절차로.

### 3.3 전환(스왑) 노동의 실측 비용

- LLM → 이미지 모드: `docker stop vllm` 약 5초 → 즉시 생성 가능 (첫 생성만 모델 로드 대기)
- 이미지 → LLM 모드: SwarmUI 재시작(VRAM 해제) ~20초 → vLLM 재기동 후 API 응답까지 실측 약 90초
- 왕복 총합 약 2~3분 + 조작 2회. 자동화 스크립트로 줄일 수 있으나 대기 시간 자체는 소거 불가. 이 시간 동안 PAB-v4/Khala의 LLM 기능이 중단된다는 점이 실질 비용

## 4. 생성 결과물 상세 갤러리

서버 ~/swarmui/Output의 35장 중 분석 가치가 있는 13장 + 클라우드 실물 2장(G5). 로컬 설정값은 PNG 임베디드 메타데이터에서 추출한 실제 생성 파라미터 (재현 가능: 동일 모델·시드·설정).

### G1. 배포 검증 세트 — 파이프라인 정상 동작의 증거

**01 · 산중 호수 (Phase 4 SDXL 검증)** — SDXL · 20 steps · CFG 7 · seed 42 · 8.99초
프롬프트: `a serene mountain lake at golden hour, photorealistic, highly detailed`
관찰: 구도·빛 안정적. 다만 수면 반사와 초목 텍스처에 디퓨전 특유의 균질함. 배포 당일 "화면 띄우고 이미지 나오는지" 목표를 8.99초에 달성한 첫 장. (이미지: 01-sdxl-lake-verify.png)

**02 · 붉은 여우 (Phase 4 FLUX 검증 — DoD 마지막 항목)** — FLUX · 20 steps · CFG 1 · seed 42 · 26.98초 · peak 17.1GiB·OOM 0
프롬프트: `a majestic red fox standing on a moss-covered rock in a misty forest at dawn, cinematic lighting, photorealistic, intricate detail`
관찰: 모피 결·수염·이끼 디테일이 SDXL 대비 확연히 정밀. 프롬프트 요소(이끼 바위/안개 숲/새벽) 전부 반영 — FLUX의 지시 이행력. 단 조명이 약간 "스튜디오 렌더" 톤. (이미지: 02-flux-fox-verify.png)

### G2. 동일 프롬프트·동일 시드 비교쌍 — 모델 격차와 "CFG 함정"을 한 번에

같은 사자 프롬프트, 같은 seed 42, 같은 20 steps. 차이는 모델과 (실수로 남겨진) CFG 7뿐.

**10 · 사자 — SDXL (CFG 7은 SDXL엔 정상)** — SDXL · 20 steps · CFG 7 · seed 42 · 8.23초
프롬프트: `a majestic lion standing on a moss-covered rock in a misty forest at dawn, cinematic lighting, photorealistic, intricate detail`
관찰: SDXL 기준으론 준수 — 갈기 볼륨, 역광 안개. 확대 시 픽셀 노이즈(도트 패턴)와 배경 CG 톤이 남지만 용도에 따라 사용 가능. (이미지: 10-sdxl-lion.png)

**11 · 사자 — FLUX ⚠ CFG 7 오적용 (SDXL 습관의 함정)** — FLUX · 20 steps · CFG 7 ⚠ · seed 42 · 86.08초
관찰: **완전 붕괴.** 디테일 소실 → 실루엣화, 색 뭉개짐, 블러. 연구 보고서 §3.2 "FLUX에 CFG 높이면 색 타고 뭉개짐"의 실물 증거. 같은 시드의 10번보다 수치상 10배 느리고(86초) 품질은 압도적으로 나쁨 — 설정 실수는 시간과 품질을 동시에 태운다. 메타데이터에는 SDXL용 refiner 설정까지 그대로 남아 있었다(설정 재사용의 흔적). (이미지: 11-flux-lion.png)

### G3. 군함 시리즈 — 프롬프트·모델·기법의 진화 서사

목표 컨셉: "군함 + 홀로그램 데이터 네트워크(국방 IT)". 6단계 진화가 모두 메타데이터로 남아 있다.

**04 · [1단계] SDXL + 콤마 나열형 — HUD 전부 소실** — SDXL · 20 steps · CFG 7 · 8.38초
프롬프트: `A modern naval destroyer ... glowing holographic data network and HUD interface overlaid across the sky and sea, interconnected light nodes and streaming data lines, cinematic wide shot, volumetric lighting, ultra detailed, photorealistic, 8k, depth of field`
관찰: 요청의 핵심(홀로그램 네트워크·HUD)이 완전히 무시되고 평범한 군함 사진만. 마스트 주변 노이즈 지글거림. 연구 §3.1 "품질 별로"의 진짜 원인 = 모델 오선택 물증. (이미지: 04-sdxl-destroyer-a.png)

**05 · [2단계] SDXL steps 50·CFG 8 — 스텝을 올려도 해결 안 됨** — SDXL · 50 steps · CFG 8 · 17.87초
관찰: 같은 나열형 프롬프트에 스텝만 2.5배 — 시간 2배, HUD는 여전히 부재. 모델의 조합 능력 부족은 스텝으로 못 산다는 물증. (이미지: 05-sdxl-destroyer-b.png)

**07 · [3단계] FLUX로 교체 — 그러나 CFG 7 그대로** — FLUX · 20 steps · CFG 7 ⚠ · 32.36초
관찰: 모델은 바꿨지만 SDXL 설정을 끌고 온 중간 단계. 11번(사자)만큼 붕괴하진 않았으나 색 과포화·대비 과잉. "모델 교체 ≠ 끝, 파라미터 문법도 함께 교체" 교훈. (이미지: 07-flux-destroyer-b.png)

**06 · [4단계] FLUX + 문장형 + CFG 3 + Euler/Simple — 컨셉 구현 성공** — FLUX · 20 steps · CFG 3 · euler/simple · seed 42 · 35.12초
프롬프트: `A modern naval destroyer cutting through deep blue ocean waves at golden hour, with a glowing translucent holographic data network stretching across the sky and reflecting on the water. Interconnected light nodes and streaming lines of data float in the air around the ship, suggesting a connected defense IT system. ...`
관찰: SDXL이 무시한 데이터 네트워크 노드·연결선이 실제로 그려졌고 수면 반사까지. FLUX의 다중 요소 조합력 입증. 동시에 한계도 보임 — 수면이 유리처럼 매끈, 전체적으로 "고품질 3D 렌더" 톤(연구 §3.4의 잔존 문제). (이미지: 06-flux-destroyer-a.png)

**08 · [5단계] 실사화 기법 총동원 — 로컬 도달 가능한 최대치** — FLUX · 28 steps · CFG 3 · euler/simple · 44.84초
프롬프트: `A photograph of a modern naval destroyer ... shot on a Sony A7R IV with a 70mm lens. Faint, subtle translucent data points glow softly near the ship, barely visible ... film grain, shallow depth of field.`
관찰: 카메라·렌즈 명시 효과로 항공 구도·항적 파도 등 "사진 문법"에 근접. 그러나 (1) 절제 지시대로 데이터 요소가 거의 소멸 — 컨셉 표현과 실사감의 트레이드오프, (2) 갑판 금빛 반사·수면이 여전히 렌더 톤. **프롬프트로 90%, 마지막 10%는 불가**(연구 §3.4)의 실물. (이미지: 08-flux-destroyer-photo-prompt.png)

**09 · [6단계·역검증] 클라우드용 단순 프롬프트를 로컬에 — 오히려 저하** — FLUX · 28 steps · CFG 3 · 54.45초 · 07-10 생성
프롬프트: `A realistic photograph of a modern naval destroyer ... blending naturally into the scene without looking artificial. Natural sunlight, realistic water, cinematic but photorealistic, documentary style.`
관찰: 연구 §8의 "클라우드용(단순화)" 프롬프트를 로컬 FLUX에 그대로 적용한 실험. 결과는 **후퇴** — 전면 소프트 블러, 뱃머리 물보라가 로우폴리 3D처럼 뭉개짐, 함체 디테일 소실. **새 발견: 프롬프트는 모델 계층에 맞춰 비대칭으로 써야 한다.** (이미지: 09-flux-destroyer-realistic-0710.png)

### G4. 최소 프롬프트와 비실사 용도 — 로컬의 남은 자리

**03 · "girl" 한 단어** — FLUX · 20 steps · CFG 3 · 32.69초
관찰: 한 단어로도 조형 파탄 없는 완성 일러스트 — FLUX 정상 작동의 증거(연구 §3.1). 단, 스타일 미지정 시 FLUX는 3D 애니메이션풍 캐릭터를 임의 선택했다. 실사 인물이 목적이면 스타일 명시가 필수라는 부수 교훈. (이미지: 03-flux-girl.png)

**13 · 웹 클라우드 아이콘 — 비실사 용도의 가능성** — SDXL · 20 steps · CFG 7 · 8.18초
프롬프트: `icon simple web cloude` (오타 포함 즉흥 입력)
관찰: 오타가 섞인 즉흥 프롬프트에도 사용 가능한 수준의 플랫 아이콘. 8초·비용 0. 내부용 임시 에셋·목업엔 로컬로 충분하다는 근거. 정식 에셋은 벡터(Recraft/Figma)가 여전히 우위. (이미지: 13-sdxl-icon-cloud.png)

**12 · 선박 아이콘 ⚠ steps 6 — 설정 미달의 실패** — FLUX · 6 steps ⚠ · CFG 2 · 10.07초
관찰: 전면 블러 — FLUX.1 Dev(비증류)는 최소 ~20스텝 필요. 6스텝 고속 생성은 Schnell(증류판)의 영역. "비실사면 로컬 OK"는 올바른 설정이 전제임을 보여주는 반례. (이미지: 12-flux-icon-ship.png)

미수록 20장 요약: 군함 변형 6장(유사 톤), 바다·미니멀 풍경 SDXL 6장(무난), 십대 소녀 SDXL 2장(인물 왜곡), 트리맵·마우스 아이콘 등 유틸 시도 4장, FLUX 아이콘 재시도 2장(12번과 동일 증상).

### G5. 동일 프롬프트 3자 대결 — 로컬 FLUX vs GPT Image 2 vs Gemini Nano Banana

세 시스템에 완전히 동일한 프롬프트(연구 §8 클라우드용)를 투입한 통제 비교. 프롬프트라는 변수를 고정했으므로 남는 차이는 순수하게 모델 계층의 차이다.

```
A realistic photograph of a modern naval destroyer cutting through the ocean at
golden hour. Faint, subtle glowing data points and thin light lines float softly
near the ship, blending naturally into the scene without looking artificial.
Natural sunlight, realistic water, cinematic but photorealistic, documentary style.
```

**09(재수록) · 로컬 FLUX.1 Dev — 3자 중 최하** — 1024² · 54.45초 · 전기료만
관찰: 전면 소프트 블러, 물보라 로우폴리화, 데이터 요소 사실상 부재. 카메라 힌트가 빠진 단순 프롬프트에서 로컬의 실체가 그대로 노출된다.

**14 · GPT Image 2 — 스토리를 만들어내는 최상위** — 1538×1022 (3:2) · 클라우드
관찰: 완전한 사진 톤(파도 질감·대기 산란·역광 플레어). 지시에 없던 **두 번째 함선을 원경에 배치**해 "네트워크로 연결된 함대" 서사를 스스로 완성 — 연구 §3.5 "최고 결과" 평가의 실물. 와이드 비율로 히어로 배너 적합. 결점도 §3.5 그대로: 노드 주변에 흐릿한 가짜 텍스트 혼입(하늘·수면부) → `no text labels` 지시로 억제 가능. (이미지: 14-gpt-destroyer.png)

**15 · Gemini Nano Banana — 판독 가능한 HUD가 실사 위에 안착** — 2816×1536 (초와이드) · 클라우드
관찰: 3자 중 최대 해상도·최고 실사 밀도 — 갑판 위 승조원 실루엣 다수, 함수 번호 "88", 부서지는 파도의 물방울 단위 질감. 결정적 차별점: 데이터 오버레이가 가짜 글자가 아니라 **판독 가능한 정합 텍스트**(SPEED 32 KTS / HDG 084° · DDG 88 · RANGE 14 NM · TRACK 1014: 275/12k ft)로 렌더링되어 전술 HUD로 "읽힌다". (이미지: 15-gemini-destroyer.png)

3자 비교의 결론:
- 같은 문장이 로컬에선 **후퇴**(09), 클라우드에선 **완성**(14·15) — §7의 "프롬프트 이해 계층" 격차가 단일 변수 실험으로 증명됨.
- 클라우드 내부 서열: 컨셉 서사 확장은 GPT(함대 구성), 실사 밀도·텍스트 정합·해상도는 Gemini — 연구 §1의 용도별 분담과 부합.
- 극사실 홍보 이미지에서 로컬의 자리는 없다는 §1 결론이 실물로 확정됐다. 로컬의 가치 축은 데이터 통제·대량·API·비실사에 있다.

## 5. 연구 보고서와 실측 교차 검증

연구 보고서(260710-image-generation-research-report.md)의 주장을 배포 실측·메타데이터로 대조한 결과. 모든 핵심 주장이 물증으로 확인됐고, 두 가지 새 발견이 추가됐다.

| 연구 보고서 주장 | 판정 | 실측 물증 |
|---|---|---|
| §3.1 "품질 별로"의 원인은 모델 오선택 — 군함을 SDXL base로 생성, HUD 소실 | 확인 ✓ | 04·05번 메타데이터: model: sd_xl_base_1.0 + 나열형 프롬프트 → HUD 부재. 동일 컨셉 06번(flux1-dev + 문장형)은 네트워크 노드 구현. 스텝 50으로 올려도(05) 해결 안 됨 |
| §3.2 FLUX에 SDXL 습관(CFG 6~8) 적용 시 "색 타고 뭉개짐" | 확인 ✓ | 11번(사자, CFG 7): 실루엣 붕괴 + 86초. 07번(군함, CFG 7): 과포화. 11번 메타데이터엔 SDXL refiner 설정 잔존 |
| §3.2 FLUX 권장 설정 = CFG 3.x·Euler/Simple·20~28st·Negative 비움 | 확인 ✓ | 성공작 3장(02·06·08) 전부 이 설정. negativeprompt 필드 실제로 빈 문자열 |
| §3.3 "A photograph of" + 카메라·렌즈 명시가 실사화에 가장 효과적 | 확인 ✓ | 08번(Sony A7R IV·70mm 명시): 시리즈 중 최대 실사감 |
| §3.4 프롬프트로 90%까지, 마지막 10%(진짜 사진 톤)는 로컬 불가 | 확인 ✓ | 최대 시도 08번에도 렌더 톤 잔존. 동일 프롬프트 3자 대결(G5)이 격차를 단일 변수로 증명 |
| §3.5 클라우드 실측 — GPT는 함대 스토리+가짜 텍스트, Nano Banana는 HUD 자연 안착 | 확인 ✓ (실물 수록) | 14번: 두 번째 함선 배치·가짜 텍스트 흔적까지 §3.5 기술과 일치. 15번: HUD가 판독 가능한 정합 텍스트로 안착 — 기술을 상회 |
| §1 "비실사(아이콘·일러스트)는 로컬로 충분" | 조건부 ✓ | 13번(SDXL 아이콘 8초) 사용 가능. 단 12번(FLUX steps 6 → 블러) — 설정 준수 전제 |
| (신규) 클라우드용 단순 프롬프트를 로컬에 재사용하면? | 역효과 ⚠ | 09번: 블러·로우폴리로 후퇴. 프롬프트 아카이브는 모델 계층별로 분리 유지해야 함 |
| (신규) 스타일 미지정 최소 프롬프트의 기본값 | 주의 ⚠ | 03번("girl"): FLUX는 실사가 아닌 3D 애니메이션풍을 기본 선택 — 실사도 명시적 지시 필요 |

## 6. 3090 24GB 로컬의 한계 분석

### 6.1 물리 한계 — VRAM이 가르는 모델 세대
- 24GB는 이미지 생성 "현세대"의 상한선이자, 차세대의 진입 장벽. FLUX.1 Dev FP16(23.8GB 파일, peak 17.1GiB)이 사실상 3090에 맞춘 마지노선. FLUX.2 Klein 9B는 29GB 요구로 탑재 자체가 불가.
- FP8 텐서코어 부재(Ampere 세대): FLUX.2 계열은 RTX 40+ FP8 최적화 전제. 3090은 FP8 가중치를 "저장"할 순 있어도 "가속"하지 못해 세대가 갈수록 상대 열세 심화.
- 클라우드 모델은 이 제약이 없다 — 격차는 하드웨어를 바꾸지 않는 한 시간이 갈수록 벌어지는 구조.

### 6.2 운영 한계 — LLM 본업과의 배타성 (실측)
- vLLM(21.5GiB 상시 예약)과는 어떤 이미지 모델도 공존 불가. SDXL(7.4GiB)조차 vLLM 잔여 2.5GiB에 안 들어감.
- 전환 왕복 2~3분 + 그 동안 PAB-v4/Khala LLM 중단. 실측 사고: 순서를 지키지 않으면 vLLM Exited(1).
- 결론: 3090 한 장 체제에서 이미지 생성은 구조적으로 "간헐 모드". 상시 서비스화하려면 GPU 분리(전용 카드 추가)가 선행 조건.

### 6.3 품질 한계 — 프롬프트가 못 넘는 벽 (갤러리 물증)
- 도달 가능: 다중 요소 조합(06), 사진 문법 근사(08), 비실사 에셋(13), 지시 이행(02).
- 도달 불가: "진짜 사진" 톤 — 수면 질감, 대기 산란, 미세 불완전함. 08번(기법 총동원)에도 잔존한 렌더 톤이 상한선의 위치를 보여준다.
- 이 상한은 realism 파인튜닝(RealFlux 계열)·업스케일로 소폭 밀어올릴 수 있으나 소멸시킬 수 없다.

### 6.4 노동 한계 — "무료"가 아니라 "노동 지불"
로컬의 비용은 전기료가 아니라 사람의 시간이다: 모델·설정 문법 학습(G2·G3의 실수 비용이 그 수업료), 프롬프트를 모델 계층별로 이원 관리(09번 교훈), GPU 스왑 조작, 스토리지 관리(모델 세트 36GB+). 클라우드는 이 전부를 구독료에 외주화한 것과 같다.

## 7. 클라우드 대비 차이 (GPT Image 2, Gemini)

| 축 | 로컬 3090 (FLUX.1 Dev) | GPT Image 2 | Gemini Nano Banana |
|---|---|---|---|
| 극사실 품질 | 90% 상한 — 렌더 톤 잔존 (08번) · 동일 프롬프트에선 후퇴 (09번) | 최상위 — 함대 스토리로 확장, 히어로 배너급 (실물 14번) | 최상위권 — 완전 실사 + 판독 가능 HUD 안착 (실물 15번, 2816×1536) |
| 요소 조합 정확도 | 양호 (06번 — SDXL 대비 우위) | 최상 (두 번째 함선 배치 등 스토리 구성) | 상 (레퍼런스 기반 일관성 강점) |
| 프롬프트 노동 | 높음 — 문장형+카메라 힌트+파라미터 문법 필수 (09번 역효과) | 낮음 — 단순 문장으로 실사 기본 제공 | 낮음 + 이미지 첨부 편집 가능 |
| 결점 | 마지막 10% 불가, GPU 스왑 노동 | 가짜 텍스트 혼입(노드 주변) — 프롬프트로 억제 가능 | - |
| 데이터 통제 | **완전 통제 (유일 강점 축)** | 외부 전송 | 외부 전송 |
| 비용 구조 | 전기료 + 노동 (조작·학습·관리) | 구독/종량제 | 구독/종량제 |
| 통합성 | REST API 완전 통제 (SwarmUI — 본 배포에서 API 생성 검증) | API 종량제 | API 종량제 |
| 재현성 | 완전 — 시드·모델 고정 (본 갤러리 전부 재현 가능) | 제한적 | 제한적 |
| 가용성 | vLLM과 배타 — 간헐 모드 | 상시 | 상시 |

차이의 구조적 원인:
1. **모델 규모·세대**: FLUX.1 Dev는 24GB 소비자 GPU에 맞춘 크기(12B급). 클라우드 프런티어 모델은 자릿수가 다른 규모 + 최신 학습 데이터·정렬 기법.
2. **후처리 파이프라인**: 클라우드 서비스는 생성 후 보정·업스케일·안전 필터가 통합된 "제품". 로컬은 원시 디퓨전 출력.
3. **프롬프트 이해 계층**: GPT/Gemini는 LLM이 프롬프트를 재해석·증강한 뒤 생성기에 전달 — 단순 문장으로 충분한 이유. 로컬은 T5 인코더 직행이라 사용자가 그 증강을 수동으로 해야 한다(= 09번에서 확인된 비대칭).

## 8. 워크플로 개선 노동 대비 품질 ROI

핵심 결론: 초기 1일의 노동(설정+프롬프트)은 ROI가 매우 높지만, 그 이후 어떤 투자도 클라우드 기본값(진짜 사진 톤)에 도달하지 못한다.

| 개선 항목 | 노동 추정 | 기대 효과 (근거) | 극사실 상한 돌파? |
|---|---|---|---|
| ① FLUX 파라미터 교정 (CFG 3.x·Euler/Simple·20~28st) | 0.5일 | 매우 큼 — 붕괴(11번) → 정상(06번). 필수 기초 | — |
| ② 프롬프트 공학 (문장형·카메라 힌트·모델별 이원화) | 0.5~1일 | 큼 — 04→08 진화로 입증. 아카이브 자산화 가능 | ✗ (08번에 렌더 톤 잔존) |
| ③ realism 파인튜닝 체크포인트 도입 (RealFlux 계열) | 0.5~1일 | 중간 — 톤 개선, 검증 필요 | ✗ |
| ④ 업스케일·후처리 파이프라인 (ComfyUI 워크플로) | 1~2일 | 중간 — 해상도·선명도 개선, 톤 문제는 그대로 | ✗ |
| ⑤ LoRA 학습 (자체 스타일/도메인) | 2~5일+ | 용도 한정 큼 (시리즈 일관성) — 극사실 일반화엔 무관 | ✗ |
| ⑥ GPU 스왑 자동화 스크립트 (원커맨드 전환) | 0.5일 | 운영 편의 — 품질 무관, 조작 2회→1회. 대기 2~3분은 잔존 | — |
| ⑦ 커스텀 웹 프론트 (React + SwarmUI API) | 5~10일 | UX·서비스 통합 — 생성 품질 자체는 불변 | — |
| ⑧ (비교) 클라우드 전환 — GPT/Gemini 구독 | 0.1일 | 극사실 즉시 확보 — 단 데이터 외부 전송·종량 비용 | **기본 제공** |

노동-품질 개념 곡선 (블라인드 평가와 갤러리 실측의 정성 배치): 기본 설정(55%) → +0.5일 파라미터 교정(72%, 06번) → +1일 프롬프트 공학(85%, 08번) → +2일 파인튜닝(87%) → +4일 업스케일·LoRA(89%) → **로컬 상한 ≈ 90% 점근**. 클라우드 기본값 = 100% 기준선. 가치의 대부분이 첫 1일에 실현되고, 이후는 상한으로의 수확 체감.

권고 투자 라인:
- 즉시 (완료): ① 파라미터 교정 — ⭐ 프리셋 "FLUX1 Dev 기본"으로 고정 배포됨 (Q10)
- 할 가치 있음 (총 1~1.5일): ② 프롬프트 아카이브 이원화 + ⑥ 스왑 자동화 스크립트
- 필요 시에만: ⑦ 커스텀 프론트 (AutoCycle로). ③~⑤는 내부용 극사실 요구가 실제 발생할 때만
- 하지 말 것: 극사실 홍보 이미지를 위한 로컬 파인튜닝 씨름 — 상한 아래에서의 수확 체감

## 9. 결론 및 권고

결론 (연구 보고서 §0 재확인 + 실측 보강): 로컬 3090 이미지 생성은 **역할 재배치**로 귀결된다. 극사실 홍보·발표용은 클라우드(GPT Image 2 / Nano Banana), 데이터 통제·대량·비실사·API 통합은 로컬 FLUX/SDXL, 그리고 3090의 본업은 LLM 추론(vLLM)이다. 이번 배포로 로컬 축은 "언제든 켤 수 있는 검증된 자산"(DoD 5/5 · 재현 가능한 프리셋 · 운영 절차 문서화)이 됐고, 그 인프라(GPU 서빙·Docker·Tailscale·REST API)는 이미지와 무관하게 PAB-v4/Khala에 재사용된다 — 낭비가 아니다.

운영 수칙 (재발 방지 체크리스트):
1. 용도 판별이 먼저: 데이터 외부 전송 가능 + 극사실 → 처음부터 클라우드. 통제 필요/대량/비실사/API → 로컬.
2. 로컬은 반드시 프리셋으로 시작: ⭐ "FLUX1 Dev 기본"(CFG 1~3.5·Euler/Simple·20~28st·1024²) — CFG 7, steps 6 재발 방지.
3. 불만이 나오면 메타데이터부터: 결과물 PNG에 모델·프롬프트·설정이 전부 박혀 있다.
4. 프롬프트는 계층별 이원 관리: 로컬용(카메라·필름 힌트 필수)과 클라우드용(단순 문장)을 섞어 쓰지 말 것 — 09번 역효과.
5. GPU 전환은 §10 스왑 절차로만: ComfyUI가 VRAM을 쥔 채 vLLM을 올리면 Exited(1) — 실측 사고.
6. VRAM 우선순위는 LLM: 이미지 생성은 간헐 모드. 상시화가 필요해지면 전용 GPU 추가가 선행 조건.

다음 단계 제안:

| 단계 | 내용 | 트리거 조건 |
|---|---|---|
| 즉시 | 스왑 자동화 스크립트(imgmode.sh/llmmode.sh) 작성 | 이미지 생성을 주 1회 이상 쓰게 되면 |
| 단기 | 프롬프트 아카이브를 리포에 자산화 (로컬/클라우드 이원) | 홍보 이미지 제작 시즌 진입 시 |
| 중기 | SwarmUI REST API 기반 커스텀 React 프론트 (Phase 5 + AutoCycle /plan) | 내부 사용자 2인 이상 or 서비스 통합 확정 시 |
| 보류 | 영상(Seedance 등)·로컬 영상 모델(Wan) | I2V 수요 발생 시 클라우드 종량제부터 |

## 10. 부록

### A. 검증된 프롬프트 아카이브 (계층별 이원화)

**로컬 FLUX용** — 카메라·필름 힌트 필수 (08번으로 검증):
```
A photograph of a modern naval destroyer cutting through deep blue ocean at golden hour,
shot on a Sony A7R IV with a 70mm lens. Faint, subtle translucent data points glow softly
near the ship, barely visible and blending naturally into the atmosphere. Realistic ocean
water with fine spray, natural sunlight, soft atmospheric haze, documentary photography,
photorealistic, film grain, shallow depth of field.
```
설정: Steps 28 | CFG 3.0 | Euler | Simple | 1024×1024 | Negative 비움 | FP16 — ⭐ 프리셋 "FLUX1 Dev 기본"

**클라우드용 (GPT/Gemini)** — 단순 문장, 실사는 기본 제공. 로컬에 재사용 금지 (09번 역효과):
```
A realistic photograph of a modern naval destroyer cutting through the ocean at
golden hour. Faint, subtle glowing data points and thin light lines float softly
near the ship, blending naturally into the scene without looking artificial.
Natural sunlight, realistic water, cinematic but photorealistic, documentary style.
```
보조: 가짜 텍스트 억제 `abstract glowing nodes and lines only, no text labels` · 시리즈 확장 `same visual style, different scene` + 레퍼런스 첨부(Nano Banana)

### B. 수록 이미지 전체 메타데이터

| # | 파일 | 모델 | steps | CFG | sampler | seed | 생성 시간 | 비고 |
|---|---|---|---|---|---|---|---|---|
| 01 | sdxl-lake-verify | sd_xl_base_1.0 | 20 | 7.0 | (기본) | 42 | 8.99초 | Phase 4 검증 · negative 있음 |
| 02 | flux-fox-verify | flux1-dev | 20 | 1.0 | (기본) | 42 | 26.98초 | DoD 마지막 · prep 114.06초(콜드) |
| 03 | flux-girl | flux1-dev | 20 | 3.0 | euler/simple | 42 | 32.69초 | 한 단어 프롬프트 |
| 04 | sdxl-destroyer-a | sd_xl_base_1.0 | 20 | 7.0 | (기본) | 761182292 | 8.38초 | HUD 소실 |
| 05 | sdxl-destroyer-b | sd_xl_base_1.0 | 50 | 8.0 | (기본) | 1273515341 | 17.87초 | 스텝 증가 무효 |
| 06 | flux-destroyer-a | flux1-dev | 20 | 3.0 | euler/simple | 42 | 35.12초 | 컨셉 구현 성공작 |
| 07 | flux-destroyer-b | flux1-dev | 20 | 7.0 ⚠ | (기본) | 1282446543 | 32.36초 | CFG 과다 — 과포화 |
| 08 | flux-destroyer-photo-prompt | flux1-dev | 28 | 3.0 | euler/simple | 42 | 44.84초 | 실사 기법 총동원 |
| 09 | flux-destroyer-realistic-0710 | flux1-dev | 28 | 3.0 | euler/simple | 42 | 54.45초 | 클라우드용 프롬프트 역효과 |
| 10 | sdxl-lion | sd_xl_base_1.0 | 20 | 7.0 | (기본) | 42 | 8.23초 | 비교쌍 기준 |
| 11 | flux-lion | flux1-dev | 20 | 7.0 ⚠ | (기본) | 42 | 86.08초 | CFG 함정 — 붕괴 |
| 12 | flux-icon-ship | flux1-dev | 6 ⚠ | 2.0 | euler/simple | 42 | 10.07초 | 스텝 미달 — 블러 |
| 13 | sdxl-icon-cloud | sd_xl_base_1.0 | 20 | 7.0 | (기본) | 725954748 | 8.18초 | 비실사 가능성 |
| 14 | gpt-destroyer | GPT Image 2 (클라우드) | — | — | — | — | — | 1538×1022 · 07-10 수령 |
| 15 | gemini-destroyer | Gemini Nano Banana (클라우드) | — | — | — | — | — | 2816×1536 · 07-10 수령 |

공통(01~13): 1024×1024 · SwarmUI 0.9.8.1 · FLUX = flux1-dev.safetensors(FP16) + ae VAE + t5xxl fp8 scaled/clip_l · SDXL = sd_xl_base_1.0.safetensors. 14~15는 클라우드 산출물로 내부 파라미터 비공개 — 입력 프롬프트(G5)와 산출 해상도만 기록.

### C. 환경 및 참조 문서

- 서버: Ryzen 3800X · RTX 3090 24GB (드라이버 590.48.01 / CUDA 13.1) · RAM 32GB · Ubuntu 22.04 · Docker 29.2.1
- 배포: SwarmUI v0.9.8.1 (커밋 8705bcc) · ComfyUI 백엔드 자동 설치 · ~/swarmui/docker-compose.yml (Tailscale IP 바인딩 · restart: unless-stopped)
- 접근: http://100.109.251.86:7801 (Tailscale 내부망 전용 · 공개 인터넷 미노출)
- 참조: swarmui-deployment-plan.md(배포 지시서·진행 로그·Q1~Q10·§10 GPU 스왑 절차) · docs/reports/260710-image-generation-research-report.md(1차 연구 소스) · work-log docs/history/260709~10-work-log.md
- 생성물 원본: 서버 ~/swarmui/Output/local/raw/2026-07-09~10/ (총 35장 · 본 보고서 13장 수록)

---
(원문 끝 — PAB-MakeIMG · 2026-07-10 · 모든 생성 파라미터는 PNG 임베디드 메타데이터에서 기계 추출 · 차트 팔레트는 dataviz 검증 통과 · 작성: Claude Code)
