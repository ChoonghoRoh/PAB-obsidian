---
title: "PAB-Khala Phase 6 통합 게이트웨이 마스터플랜"
description: "Khala 단일 게이트웨이로 런타임 투명 선택 + GPU mutex 요청경로 중재. arbiter v2 견고화(G0 페르소나 반영)"
created: 2026-06-30 07:58
updated: 2026-06-30 07:58
type: "[[PROJECT]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[API_GATEWAY]]", "[[GPU_MUTEX]]"]
tags: ["project", "khala", "phase6", "gpu-mutex", "arbiter", "gateway"]
keywords: ["khala", "phase6", "게이트웨이", "gpu-mutex", "arbiter", "런타임라우팅", "vllm", "ollama", "시간분리", "ssot"]
sources: ["[[15_Sources/2026-06-30_phase6_unified_gateway_source]]", "docs/phases/phase-6-master-plan.md"]
aliases: ["phase6마스터플랜", "khala게이트웨이", "PAB-Khala Phase6"]
---

# PAB-Khala Phase 6 통합 게이트웨이 마스터플랜

> 엔진을 줄이지 않고 **호출 surface + GPU 중재를 Khala 한 곳으로 통합**하는 정식 phase(SSOT D18). 원문 전문: [[15_Sources/2026-06-30_phase6_unified_gateway_source|SOURCE]].

## 배경 — 현행 4대 문제
[[2026-06-30_phase6_unified_gateway_source#§2 배경 / 목표|원문 §2 →]]

단일 24GB GPU에서 vLLM↔Ollama가 mutex로 공존. 현행은 호출 대상 2개(PAB-v4→Ollama 직접, Khala→vLLM) + mutex가 요청 경로 밖이라 ① 관리 2점 ② mutex 자동성 0 ③ 관측 분절 ④ resumable 미적용.

## 범위 — 게이트웨이 토대까지
[[2026-06-30_phase6_unified_gateway_source#§3 범위 / 비범위|원문 §3 →]]

런타임 셀렉터 + arbiter + `/v1/generate` Ollama 배선 + `pab:*` caller. **엔진 단일화는 미채택**(멀티모델·prefix-cache 강점 보존). PAB-v4 shim·run-full→resumable은 G4 이후 후속.

## arbiter v2 (구현 기준)
[[2026-06-30_phase6_unified_gateway_source#§4 설계 요약 + arbiter 코드 스케치|원문 §4 →]]

**직렬 swap 워커 + 상태머신(STABLE/SWAPPING/UNKNOWN) + 롤백 + idle-TTL 복귀 watcher**. 요청은 락에서 블록하지 않고 409/503로 양보. 정책 = (나) 시간 분리를 코드 강제(배치 선점 금지). 기존 [[KHALA]] `ops/*.sh` + `lib/ollama_client.py` 재사용 → 신규는 `arbiter.py` 1개.

## KPI / G0 판정
[[2026-06-30_phase6_unified_gateway_source#§6 KPI|원문 §6 →]] · [[2026-06-30_phase6_unified_gateway_source#§9 G0 페르소나 검증 판정|원문 §9 →]]

P6-01~08(런타임투명·mutex자동·시간분리·single-flight·회귀·관측·swap실패복원·복귀자동성). v1.0 초안은 G0 적대 검증에서 Blocker 2건 → arbiter v2로 견고화(v1.1). 현재 **G0-REVIEW**. 검증 상세는 [[2026-06-30_phase6_persona_review]].

## 관련 노트
- 설계 비교: [[2026-06-30_gateway_design_compare]]
- 연동 동기: [[2026-06-30_pab_v4_brain_integration]]
- 페르소나 검증: [[2026-06-30_phase6_persona_review]]
