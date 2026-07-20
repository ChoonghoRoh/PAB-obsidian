---
title: "PAB-Khala 통합 게이트웨이 설계 — 현행 vs 통합 비교"
description: "엔진 통합 대신 게이트웨이 통합. 현행 운영 방식과 통합안을 자산 인벤토리 기반으로 비교"
created: 2026-06-30 07:58
updated: 2026-06-30 07:58
type: "[[CONCEPT]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[API_GATEWAY]]", "[[GPU_MUTEX]]"]
tags: ["concept", "khala", "gateway", "gpu-mutex", "architecture"]
keywords: ["khala", "게이트웨이", "런타임투명", "mutex중재", "현행비교", "호출surface", "arbiter", "ollama", "vllm"]
sources: ["[[15_Sources/2026-06-30_gateway_design_compare_source]]", "docs/design/20260629-khala-unified-gateway-design.md"]
aliases: ["게이트웨이설계", "khala통합안", "현행vs통합"]
---

# PAB-Khala 통합 게이트웨이 설계 — 현행 vs 통합 비교

> "엔진을 하나로 줄이지 말고 **호출 surface와 GPU 중재를 Khala로 통합**"하는 안과 현행을 비교. 원문 전문: [[15_Sources/2026-06-30_gateway_design_compare_source|SOURCE]].

## 현행 운영 방식 (실측)
[[2026-06-30_gateway_design_compare_source#1. 현행 운영 방식 (실측 기준)|원문 §1 →]]

`/v1/generate`는 vLLM 하드코딩(런타임 선택 없음). mutex는 `ops.py` admin 엔드포인트로 **요청 경로 밖**(대시보드·수동) 운영. **핵심 발견 — Khala는 이미 부품을 다 보유**: mutex 툴킷·`ollama_client.py`(미배선)·통합 로깅. 빠진 건 "요청 경로 런타임 선택 + 자동 mutex 중재"뿐.

## 통합안 설계
[[2026-06-30_gateway_design_compare_source#2. 게이트웨이 통합안 설계|원문 §2 →]]

런타임 셀렉터(모델·요청유형→ollama|vllm) + Mutex Arbiter(요청 경로 GPU 리스). PAB-v4는 Ollama 직접 호출을 끊고 Khala로 단일화. 두 엔진은 각자 강점([[GPU_MUTEX]] 멀티모델 / prefix-cache) 유지.

## 현행 vs 통합 비교
[[2026-06-30_gateway_design_compare_source#3. 현행 vs 통합안 비교|원문 §3 →]]

호출 대상 2→1, 런타임 선택 암묵→Khala 셀렉터, mutex 밖→안, GPU 충돌 보장 없음→구조적 보장, 관측 분절→일원화. 대가는 **Khala SPOF 신설** + arbiter 1개 구현.

## 정식화 / 후속
[[2026-06-30_gateway_design_compare_source#5. 단계적 적용|원문 §5 →]]

G0~G4 5단계(스키마→셀렉터→arbiter→e2e→정리). 정식 phase로 승격됨 → [[2026-06-30_phase6_unified_gateway]]. 연동 동기는 [[2026-06-30_pab_v4_brain_integration]].
