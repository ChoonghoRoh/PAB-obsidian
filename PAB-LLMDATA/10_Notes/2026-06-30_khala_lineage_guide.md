---
title: "PAB-Khala Lineage 연결 가이드 — 호출 연결고리 추적"
description: "GET /v1/tools/lineage — 서버가 prev→current→next 부여·검증. workflow_id/request_id/parent 3종 식별자"
created: 2026-06-30 07:58
updated: 2026-06-30 07:58
type: "[[REFERENCE]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[LINEAGE]]"]
tags: ["reference", "khala", "lineage", "api"]
keywords: ["khala", "lineage", "연결고리", "prev-current-next", "workflow-id", "parent", "resume-valid", "seq", "_index-jsonl"]
sources: ["[[15_Sources/2026-06-30_khala_lineage_guide_source]]", "docs/guides/khala-lineage-api-guide.md"]
aliases: ["lineage가이드", "연결고리추적", "PAB-Khala Lineage"]
---

# PAB-Khala Lineage 연결 가이드 — 호출 연결고리 추적

> stateless HTTP에서 "이 호출이 이전 작업과 이어지는가"를 **서버가 스스로 판정·기록**. 원문 전문: [[15_Sources/2026-06-30_khala_lineage_guide_source|SOURCE]].

## 식별자 3종
[[2026-06-30_khala_lineage_guide_source#1. 식별자 3종|원문 §1 →]]

`workflow_id`(작업 체인 키, 클라이언트) · `request_id`(호출 1건, 클라이언트) · `parent_request_id`(직전 호출 = prev, **서버 부여**).

## 연결 방법 + 조회
[[2026-06-30_khala_lineage_guide_source#2. 연결 방법|원문 §2 →]]

새 체인(resume=false) → 이어가기(동일 wid+resume=true, 서버가 parent 연결) → `GET /v1/tools/lineage/{wid}`로 체인 복원. `resumable=true` 동안 반복 재호출 = auto-resume loop(임의 길이 작업 완주).

## 판정 규칙 + NVMe
[[2026-06-30_khala_lineage_guide_source#4. 호출 연결 판정 규칙 (서버)|원문 §4 →]] · [[2026-06-30_khala_lineage_guide_source#5. NVMe 저장물|원문 §5 →]]

기존 wid+resume=연속(seq=마지막+1), 신규 wid+resume=모순(`resume_valid=false`), 신규+no resume=새 체인. `_runs.jsonl`(호출 1건=1줄) + `_index.jsonl`(request_id→wid 전역 매핑), append-only.

## 관련
설계 배경: [[2026-06-30_khala_lineage_design]] · 워크스페이스 재개: [[2026-06-30_khala_resumable_tools]] · 게이트웨이 노출 시 lineage 조회 인증은 [[2026-06-30_phase6_unified_gateway|Phase 6]] G1에서 보강.
