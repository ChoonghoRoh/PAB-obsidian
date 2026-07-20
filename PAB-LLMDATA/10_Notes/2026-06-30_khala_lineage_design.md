---
title: "PAB-Khala 컨텍스트 이어가기·호출 연결고리 설계 (A⊕B)"
description: "NVMe workspace.md(A 내용 이어가기) + _runs.jsonl(B 호출 계보)을 한 타임라인으로 추적하는 lineage 설계"
created: 2026-06-30 07:58
updated: 2026-06-30 07:58
type: "[[CONCEPT]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[LINEAGE]]", "[[NVME_WORKSPACE]]"]
tags: ["concept", "khala", "lineage", "nvme", "resume"]
keywords: ["khala", "lineage", "연결고리", "컨텍스트이어가기", "nvme", "workspace", "resume", "_runs-jsonl", "계보추적", "RAM"]
sources: ["[[15_Sources/2026-06-30_khala_lineage_design_source]]", "docs/design/20260628-context-continuation-and-call-lineage-design.md"]
aliases: ["lineage설계", "호출연결고리설계", "컨텍스트이어가기", "A⊕B설계"]
---

# PAB-Khala 컨텍스트 이어가기·호출 연결고리 설계 (A⊕B)

> 작은 24GB 컨텍스트 윈도우와 stateless HTTP를 NVMe로 외부화 — **A(무엇을 이어가나) + B(누가 누구와 이어지나)**를 분리·통합. 원문 전문: [[15_Sources/2026-06-30_khala_lineage_design_source|SOURCE]].

## 두 메커니즘의 축
[[2026-06-30_khala_lineage_design_source#1. 두 메커니즘의 축|원문 §1 →]]

A = `workflow_id` 단위 [[NVME_WORKSPACE|workspace.md]](작업 상태) + RAM page-cache/실행. B = 1 API 호출(`request_id`) 단위 `_runs.jsonl`(호출 체인). 같은 `workflow_id` 디렉토리를 공유해 결합.

## A — 컨텍스트 이어가기 (NVMe/RAM)
[[2026-06-30_khala_lineage_design_source#2. (A) 컨텍스트 이어가기 — 구현 완료 (요약)|원문 §2 →]]

`workspace_write`가 매 단계 "전체"를 NVMe에 덮어쓰기. `resume=true` 시 `workspace_read`로 직전 상태를 system에 주입 → 작은 윈도우가 "기억"을 갖고 시작. autosave checkpoint로 중단 대비.

## B — 호출 연결고리 추적
[[2026-06-30_khala_lineage_design_source#3. (B) 호출 연결고리 추적 — 신규 설계|원문 §3 →]]

서버가 `seq`/`parent_request_id`/`resume_valid` 부여·검증. `_runs.jsonl`(append-only 불변) + `_index.jsonl`(전역 매핑). 모순(신규 wid+resume) 탐지. → [[2026-06-30_khala_lineage_guide]].

## A⊕B 통합 + 검증
[[2026-06-30_khala_lineage_design_source#4. (A⊕B) 통합 — 두 추적을 하나의 타임라인으로|원문 §4 →]] · [[2026-06-30_khala_lineage_design_source#7. 검증 결과 (2026-06-28 실 e2e, 3800x)|원문 §7 →]]

한 레코드가 `parent_request_id`(B)+`workspace_size`(A)를 동시 증명. 적대 페르소나 재검증으로 A 무손실 미입증 정정 → Phase 5 Track A(A2 서버 자동저장)로 입증 전환. 운영 API는 [[2026-06-30_khala_resumable_tools]].
