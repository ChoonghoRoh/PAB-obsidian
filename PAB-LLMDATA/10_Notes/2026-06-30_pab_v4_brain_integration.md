---
title: "PAB-Khala PAB-v4 Brain 연동 보고서"
description: "PAB-v4 brain 카테고리 연결(MCP/REST)과 Khala Lineage·Resumable을 두 축(조회/생성)으로 분리한 연동 분석"
created: 2026-06-30 07:58
updated: 2026-06-30 07:58
type: "[[PROJECT]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[PAB_V4]]"]
tags: ["project", "khala", "pab-v4", "brain", "integration"]
keywords: ["khala", "pab-v4", "brain", "카테고리", "mcp", "lv0", "resumable", "lineage", "조회생성분리", "gpu정책"]
sources: ["[[15_Sources/2026-06-30_pab_v4_brain_integration_source]]", "docs/analysis/20260629-pab-v4-brain-khala-integration-report.md"]
aliases: ["pab-v4연동보고서", "brain연동", "PAB-Khala PAB-v4연동"]
---

# PAB-Khala PAB-v4 Brain 연동 보고서

> [[PAB_V4]] brain 카테고리 연결 API/MCP와 [[KHALA]]를 어떻게 잇나 — 가장 중요한 판단은 **두 축 분리**. 원문 전문: [[15_Sources/2026-06-30_pab_v4_brain_integration_source|SOURCE]].

## 양 시스템 현재 상태
[[2026-06-30_pab_v4_brain_integration_source#1. 양 시스템 현재 상태 (실측)|원문 §1 →]]

PAB-v4: Brain 모델·CRUD API 구현, `pab-lv0` MCP/`/ext/lv0/v1` REST는 **설계 완성·구현 0%**, LLM은 Ollama 직접, run-full 배치 진행률은 **메모리 전용(재시작 시 소실)**. Khala: resumable(workspace.md 영속)+lineage 제공.

## 두 축으로 분리 (핵심)
[[2026-06-30_pab_v4_brain_integration_source#2. 연동을 두 축으로 분리한다 (가장 중요한 판단)|원문 §2 →]]

- **축① 조회 층(`pab-lv0`)** — Khala 끼우지 말 것. confidence 1.0 결정적 응답이 가치라 LLM 게이트웨이가 보증을 깸. PAB-v4 자체 구현.
- **축② 생성·배치 층(run-full 등)** — Khala resumable+lineage로 보강(메모리 소실 구멍을 메움). `task_id↔workflow_id` 매핑.

## 결정적 리스크 — GPU mutex
[[2026-06-30_pab_v4_brain_integration_source#5. ⚠️ 결정적 리스크 — 단일 GPU vLLM↔Ollama mutex|원문 §5 →]]

단일 24GB에서 vLLM↔Ollama 동시 점유 불가. PAB-v4가 Ollama 직접 호출 → 배치를 Khala(vLLM)로 돌리면 충돌. **결정: 정책 (나) 시간 분리** — 인터랙티브는 Ollama, 대량 ingest만 Khala vLLM.

## 로드맵
[[2026-06-30_pab_v4_brain_integration_source#7. 권고 — 단계적 도입 로드맵 (확정: 둘 다 / 시간 분리)|원문 §7 →]]

조회 층(Phase1, Khala 무관) 먼저 → 생성 층(Phase2+)은 시간 분리 위에서. 이 GPU 충돌 해소가 [[2026-06-30_gateway_design_compare]] / [[2026-06-30_phase6_unified_gateway]]로 발전.
