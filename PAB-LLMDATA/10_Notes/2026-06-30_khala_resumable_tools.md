---
title: "PAB-Khala Resumable Tools API — NVMe 워크스페이스·무손실 재개"
description: "POST /v1/tools/run 무손실 재개 — NVMe workspace.md + 자동 체크포인트 + vLLM prefix-cache(2층 구조)"
created: 2026-06-30 07:58
updated: 2026-06-30 07:58
type: "[[REFERENCE]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[NVME_WORKSPACE]]"]
tags: ["reference", "khala", "resumable", "nvme", "api"]
keywords: ["khala", "resumable", "nvme", "workspace", "무손실재개", "prefix-cache", "vllm", "workflow-id", "checkpoint", "RAM"]
sources: ["[[15_Sources/2026-06-30_khala_resumable_tools_source]]", "docs/guides/khala-resumable-tools-api-guide.md"]
aliases: ["resumable-tools", "nvme워크스페이스", "무손실재개", "PAB-Khala Resumable"]
---

# PAB-Khala Resumable Tools API — NVMe 워크스페이스·무손실 재개

> `POST /v1/tools/run`이 컨텍스트 한계(`max_iter`)에서 NVMe에 상태를 남기고, 같은 `workflow_id`+`resume`로 이어감. 원문 전문: [[15_Sources/2026-06-30_khala_resumable_tools_source|SOURCE]].

## 2층 구조 (RAM 엔진 + NVMe SW)
[[2026-06-30_khala_resumable_tools_source#0. 한눈에 보기|원문 §0 →]]

Tier1(엔진): vLLM prefix-cache가 반복 prefix KV를 fp8 VRAM으로 재사용. Tier2(SW): [[NVME_WORKSPACE|NVMe workspace.md]] + 자동 체크포인트. 24GB 윈도우를 넘어 논리적으로 무한히 이어지는 작업.

## 엔드포인트 + 연결 절차
[[2026-06-30_khala_resumable_tools_source#1. 엔드포인트 스펙|원문 §1 →]] · [[2026-06-30_khala_resumable_tools_source#2. 연결 절차 (2단계 호출)|원문 §2 →]]

요청 `workflow_id`/`resume`, 응답 `workflow_id`/`resumable`. 1차 `max_iter` 도달 → `resumable=true` → 2차 동일 wid+`resume:true` → `workspace_read`가 직전 상태를 system에 주입 → 이어감. `caller`는 화이트리스트(`pab:*`/`conductor:*`/…) 필요.

## NVMe 레이아웃 + 신규 도구
[[2026-06-30_khala_resumable_tools_source#3. 작동 체인|원문 §3 →]] · [[2026-06-30_khala_resumable_tools_source#4. 신규 도구 2종|원문 §4 →]]

`tools_run/<wid>/{workspace.md, notes/, checkpoints/, artifacts/, _audit.log}`. OOM·강제종료에도 거의 무손실 재개. `workspace_read()`/`workspace_write(content)` 2종.

## 운영 주의
[[2026-06-30_khala_resumable_tools_source#6. 운영 주의 / 트레이드오프|원문 §6 →]]

tool 워크로드는 `tools-text.yml`(75K·fp8 KV)로 기동. `tool_choice=auto` 한계(명명 산출물 누락 가능, 단 workspace는 영속). [[GPU_MUTEX]]: vLLM 점유 중 Ollama 채팅 불가. 호출 계보는 [[2026-06-30_khala_lineage_guide]], 설계는 [[2026-06-30_khala_lineage_design]].
