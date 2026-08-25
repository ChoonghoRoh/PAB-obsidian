---
title: "로컬 LLM 한계 사다리 실험 프로토콜 (원본) — 3800X/24GB GPU/64GB RAM"
description: "기존 하드웨어로 로컬 LLM을 어디까지 돌릴 수 있는지 한계선을 사다리로 측정하는 실험 프로토콜. RAM 상주 + vRAM 연산(MoE 오프로딩)으로 ~106B 천장까지."
created: 2026-07-16 22:14
updated: 2026-07-16 22:14
type: "[[SOURCE]]"
index: "[[AI]]"
topics: ["[[LOCAL_LLM_HOSTING]]", "[[MOE_OFFLOADING]]"]
tags: [source, local-llm, moe, llama-cpp, ktransformers, benchmark, khala, gguf]
keywords: [limit ladder, MoE offloading, llama.cpp, -ot exps=CPU, -ngl, GLM-4.5-Air, ktransformers, Q4, mmap paging, tok/s, REMOTE_BACKENDS, 3800X, Zen2, 24GB GPU, 64GB RAM]
sources: ["PAB-Khala docs/reports/2026-07-16-로컬LLM-한계사다리-실험프로토콜.md"]
aliases: ["한계 사다리 원본", "limit ladder source", "로컬LLM 한계 실험 원본"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존. 정본은 PAB-Khala `docs/reports/2026-07-16-로컬LLM-한계사다리-실험프로토콜.md`.

# 로컬 LLM 한계 사다리 실험 프로토콜

**하드웨어**: Ryzen 3800X(AM4·Zen2, AMX 없음) · 단일 24GB GPU · RAM 64GB · NVMe
**목적**: 기존 하드웨어로 로컬 LLM을 어디까지 돌릴 수 있는지 한계선을 사다리처럼 올라가며 체감
**범위**: ~106B(메모리 천장)까지 · 문서 산출물(코드/서버 변경 없음, 실측값은 후속 실행에서 기입)
**작성일**: 2026-07-16

## 요약

발단은 콜리브리(GLM-5.2 744B, 디스크 스트리밍) 도입 제안이었으나, 실제 관심은 "특정 대형 모델
도입"이 아니라 기존 하드웨어의 한계를 체감하는 실험이다. 콜리브리처럼 디스크로 내려가기 전,
**시스템 RAM 상주 + vRAM 연산 가속**(= MoE 오프로딩)으로 어디까지 올라갈 수 있는지를 사다리로
측정한다.

하드웨어 예산(한 번에 담기는 가중치):

```
가중치 예산 ≈ vRAM 24GB + RAM 64GB − OS/KV 오버헤드 ≈ 실질 ~70GB
Q4(int4) ≈ 0.56 GB / 1B 파라미터
        → ~100–110B 파라미터 = "메모리에 온전히 얹히는" 천장
그 위 → NVMe 페이징(콜리브리식) → 속도 절벽(이번 범위 밖)
```

실험 사다리(한눈에):

| 단 | 모델 후보 | 상주/오프로드 | 관측 목표 | 예상 decode |
|---|---|---|---|---|
| 0 기준 | 27B int4 (현 `qwen3.6-27b-autoround` 상당 GGUF) | 전량 vRAM | 기준 tok/s 확보 | ~30–40 tok/s |
| 1 | ~70B 밀집 Q4 (Llama-3.3-70B / Qwen2.5-72B) | GPU 레이어분할 + RAM | 밀집 대형의 실용 하한 | ~3–6 tok/s |
| 2 스윗스팟 | GLM-4.5-Air 106B MoE Q4 (~60GB) | 어텐션·공유=vRAM, 전문가=RAM | MoE 오프로딩 체감 | ~5–10 tok/s |
| 3 천장 | 단2 context 확대 / ~110–120B 시도 | RAM 포화 직전 | 64GB 벽 위치 특정 | 급락 시작 |

decode tok/s는 모두 실측 대상(예상치).

## MoE 오프로딩 원리

메모리 계층을 3단으로 보면 콜리브리와 이 실험의 차이가 분명하다.

| 방식 | 가중치 상주 | 연산 | 크기 한계 | 속도 |
|---|---|---|---|---|
| ① vLLM (현재 Khala) | 전량 vRAM(24GB) | GPU | ~27B int4 | 가장 빠름 |
| ② RAM 상주 + vRAM 연산 ← 이 실험 | 시스템 RAM | 핫 경로만 GPU | RAM 용량까지 | 중간 |
| ③ 콜리브리 (디스크 스트리밍) | NVMe 디스크 | GPU | 사실상 무제한 | 가장 느림 |

②는 ③보다 빠르다(RAM 대역폭 ≫ 디스크). 핵심은 MoE: GLM-4.5-Air는 총 106B지만 토큰당 약
12B(활성 전문가)만 계산에 참여한다. 따라서 전문가 가중치 전체를 RAM에 두더라도, 매 토큰 실제로
GPU로 옮겨 곱하는 양이 작아 밀집 70B보다 오히려 빠를 수 있다. GLM 계열이 이 실험의 이상적
대상인 이유다.

병목은 두 곳이다.
- RAM 대역폭: 3800X는 듀얼채널 DDR4(~50GB/s). CPU-상주 전문가를 만질 때의 한계.
- CPU 커널: ktransformers의 최속 경로는 Intel AMX 기반인데 Zen2엔 AMX가 없어 AVX2 경로로 동작
  (이론 최고속 미달). → 주력은 llama.cpp로 잡는다.

## 단별 프로토콜

각 단은 동일 골격이다: 모델 확보 → 실행 명령 → 지표 측정. 모델은 Q4_K_M(또는 동급) GGUF 기준.
실제 파일명·리포지토리는 실행 시 확정(미확인 체크리스트).

### 단 0 — 기준선 (27B, 전량 vRAM)

- 목적: 이후 단의 비교 기준 tok/s 확보(현 프로덕션과 등가 조건).
- 모델: 현 `qwen3.6-27b-autoround`에 상당하는 27B Q4 GGUF.
- 실행:
  ```bash
  ./llama-server -m qwen-27b-Q4_K_M.gguf \
    -ngl 99 -c 8192 --host 127.0.0.1 --port 8000
  ```
  (`-ngl 99` = 전 레이어 GPU. 27B Q4 ≈ ~16GB → 24GB에 여유.)
- 기대: KV 포함 vRAM ~18–20GB, decode ~30–40 tok/s.

### 단 1 — ~70B 밀집 (레이어 분할)

- 목적: 밀집 대형 모델을 GPU/CPU로 쪼갰을 때의 실용 하한 체감.
- 모델: Llama-3.3-70B-Instruct 또는 Qwen2.5-72B, Q4_K_M(~40GB).
- 실행(`-ngl`로 GPU에 올릴 레이어 수 조절 = 핵심 튜닝 노브):
  ```bash
  ./llama-server -m L3.3-70B-Q4_K_M.gguf \
    -ngl 40 -c 8192 --host 127.0.0.1 --port 8000
  # vRAM OOM이면 -ngl 낮추고, 여유면 높여 최적점 탐색
  ```
- 기대: 가중치 ~40GB가 GPU(24GB) + RAM에 분할. decode ~3–6 tok/s(GPU 적재 비율에 좌우).

### 단 2 — GLM-4.5-Air 106B MoE (스윗스팟)

- 목적: 이 실험의 본론. 전문가만 RAM에 두고 나머지는 GPU로 MoE 오프로딩 체감.
- 모델: GLM-4.5-Air (106B total / ~12B active) Q4 GGUF(~60GB).
- 실행(`-ot`로 전문가 텐서를 CPU에 고정, 나머지 GPU):
  ```bash
  ./llama-server -m GLM-4.5-Air-Q4_K_M.gguf \
    -ngl 99 -ot "exps=CPU" -c 8192 \
    --host 127.0.0.1 --port 8000
  # exps=CPU : 라우팅 전문가 텐서는 시스템 RAM 상주,
  #            어텐션·공유·임베딩·KV 는 GPU vRAM
  ```
- 기대: vRAM ~18–22GB(어텐션+공유+KV), RAM ~55–60GB(전문가). decode ~5–10 tok/s.
  밀집 70B(단1)보다 빠르면 MoE 오프로딩의 이점이 실증된 것.

### 단 3 — 천장 탐지 (64GB 벽)

- 목적: "메모리에 온전히 얹히는" 한계선을 실제로 특정.
- 방법 A (context 확대): 단2 모델 유지, `-c`를 8192 → 16384 → 32768로 키우며 KV가 vRAM을
  잠식해 OOM 나는 지점 기록.
- 방법 B (모델 확대): ~110–120B급 MoE Q4를 시도, mmap 페이징이 시작되어(RAM 초과) decode가
  급락하는 순간 포착.
  ```bash
  # mmap 기본 활성 — RAM 초과분은 NVMe에서 자동 페이징(느려짐)
  ./llama-server -m <~120B>-Q4.gguf -ngl 99 -ot "exps=CPU" -c 8192 ...
  # 관찰: decode tok/s 급락 + 디스크 read 폭증 = 벽 도달
  ```
- 산출: "이 하드웨어에서 실용선(예: decode ≥ N tok/s)을 지키는 최대 모델/최대 context" 확정.

확장 아이디어(범위 밖): 단3 벽을 넘어 200B–744B를 계속 밀면 콜리브리와 동일한 디스크
스트리밍(<1 tok/s) 영역이 된다. "절벽" 체감이 목적이면 별도 세션에서.

## 도구와 설치

주력 — llama.cpp(`llama-server`, GGUF). 선택 이유: `-ngl`(GPU/CPU 레이어 분할) · `-ot`(MoE
전문가 CPU 고정) · mmap(RAM 초과 시 자동 디스크 페이징 → 단1→3을 파라미터만 바꿔 연속 체감) ·
로그에 prefill/decode tok/s 직접 출력 · OpenAI 호환 서버 내장.

```bash
# CUDA 빌드
cmake -B build -DGGML_CUDA=ON
cmake --build build -j
# 산출물: build/bin/llama-server
```

비교군(선택) — ktransformers. MoE 오프로딩 특화(어텐션 vRAM + 전문가 CPU). 단 최속 경로가
Intel AMX 기반이라 Zen2(3800X)에선 AVX2 경로로 동작해 이론 최고속에 못 미친다. GLM MoE 지원
여부는 실행 시 실검증 필요(가정 금지). 여유가 되면 단2를 llama.cpp와 A/B로 비교해 CPU 커널
효과만 분리 측정.

## 측정 지표

동일 고정 프롬프트 1개로 `POST /v1/chat/completions`(또는 서버 로그)에서 반복 측정.

| 단 | 로드 | vRAM 점유 | RAM 점유 | prefill tok/s | decode tok/s | 최대 context(OOM 전) | 비고 |
|---|---|---|---|---|---|---|---|
| 0 (27B) | ⬜ | | | | | | |
| 1 (~70B) | ⬜ | | | | | | `-ngl` 최적값 |
| 2 (106B MoE) | ⬜ | | | | | | `-ot exps=CPU` |
| 3 (천장) | ⬜ | | | | | | 벽 위치 |

측정 방법 메모:
- decode tok/s: llama.cpp 응답 로그 `eval time ... tokens per second`.
- prefill tok/s: `prompt eval time ...`.
- 점유: `nvidia-smi`(vRAM) · `free -h`/`htop`(RAM) 스냅샷.
- 벽 판정: decode 급락 + `iostat`/디스크 read 폭증 동시 발생.

## Khala 연계

각 엔진이 OpenAI 호환 서버(127.0.0.1:8000)이므로, 콜리브리·DeepSeek와 동일한 방식으로 Khala에
붙는다.

- 등록 지점: `scripts/run-on-3800x-v5/lib/openai_chat.py`의 `REMOTE_BACKENDS`(28–31행)에 1줄 추가
  ```python
  REMOTE_BACKENDS = {
      "deepseek-v4-pro":   {"base_url": "https://api.deepseek.com", "key_env": "DEEPSEEK_API_KEY"},
      # 실험용(예): 로컬 llama-server
      "glm45-air-local":   {"base_url": "http://127.0.0.1:8000", "key_env": "LOCAL_LLAMA_KEY"},
  }
  ```
- GPU 미충돌: `is_remote_model()`(34행) 매칭 → `scripts/api/handlers/tools.py:122-124`에서
  arbiter/batch 우회 → 기존 vLLM 27B와 GPU 경합 없이 별도 프로세스로 공존.
- A/B 실측: `scripts/ops/model_swap_ab.py` 패턴으로 현 27B(로컬 vLLM) 대비 품질/속도 비교.
- 주의: `_strip_vllm_only()`(59–62행)가 `chat_template_kwargs`를 제거하므로, llama.cpp 쪽
  thinking 토글이 필요하면 전달 경로를 별도 확인해야 한다.

실제 등록/실행은 이 문서 범위 밖(별도 승인). 여기서는 "실험 엔진 = 곧 Khala 백엔드"라는 배선
가능성만 명시한다.

## 미확인 체크리스트

- [ ] GPU 카드 정확 모델(3090/4090 등) — decode tok/s 기대치·`-ngl` 최적점에 영향.
- [ ] GLM-4.5-Air Q4 GGUF 가용성 및 정확한 리포지토리/파일명·양자화 등급.
- [ ] ktransformers의 GLM MoE 지원 여부(Zen2 AVX2 경로 실동작 포함).
- [ ] NVMe 여유 용량(70B ~40GB + 106B ~60GB + 27B ~16GB 동시 보관 시 100GB+ 필요).
- [ ] `-ot "exps=CPU"` 정규식이 대상 GGUF의 실제 전문가 텐서명과 매칭되는지(모델별 상이 가능).

## 출처

- 발단: 콜리브리(GLM-5.2 744B) GitHub README(PAB `pab://lv0/document/87`) + 연구 노트
  (`pab://lv0/document/86`, brain_id=11). 이 문서에서는 콜리브리를 "디스크 스트리밍(③)" 참고
  사례로만 인용.
- Khala 코드 근거: `scripts/run-on-3800x-v5/lib/openai_chat.py:28-31`(REMOTE_BACKENDS),
  `scripts/api/handlers/tools.py:122-124`(arbiter 우회), `scripts/ops/model_swap_ab.py`(A/B 러너).
