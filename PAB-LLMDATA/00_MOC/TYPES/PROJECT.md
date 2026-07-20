---
title: "PROJECT — Type MOC"
description: "PROJECT TYPE에 속하는 모든 노트의 자동 수집 MOC. 프로젝트 단위 작업 노트의 진입점."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[TYPES]]"]
tags: [moc, types/project]
keywords: [moc, project, type-index]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["PROJECT MOC", "Projects Index"]
---

# PROJECT — Type MOC

## TYPE 정의

`PROJECT`는 **프로젝트 단위 작업 노트**이다. PARA의 P(Project)와 동일하게, 명확한 시작·종료·산출물이 있는 작업 단위를 추적한다. 진행 중 / 완료 / 보류 상태를 frontmatter `tags`(`status/active`, `status/done` 등)로 분류 가능.

- **작성 시점**: 새 프로젝트 시작 시(루트 노트), 또는 Master Plan 단위
- **예시**:
  - "PAB Wiki Project" (본 프로젝트)
  - "Side Project — LangGraph Sandbox"
  - "Phase 1 — wiki bootstrap"

## 자동 수집 (dataview)

```dataview
LIST
FROM ""
WHERE type = "[[PROJECT]]"
SORT created DESC
LIMIT 100
```

## 폴백 정적 링크

<!-- moc-build:auto-start -->
- [[2026-06-30_pab_v4_brain_integration]] — PAB-Khala PAB-v4 Brain 연동 보고서
- [[2026-06-30_phase6_unified_gateway]] — PAB-Khala Phase 6 통합 게이트웨이 마스터플랜
- [[2026-06-30_khala_pab_v4_integration]] — PAB-v4 Khala 연동 아키텍처 — 두 옵션 비교·권장
- [[2026-05-27_pab_mcp_model_sizing]] — PAB × MCP × 모델 사이즈 — RAG에서 tool-call 위임으로, 로컬 약한 모델 vs 엔터프라이즈 의사결정
- [[2026-05-04_pab_reader_overview]] — PAB-Reader — 프로젝트 개요
- [[2026-05-04_pab_ssot_nexus_overview]] — PAB-SSOT-Nexus — 프로젝트 개요
- [[2026-05-04_pab_conductor_overview]] — PAB-Conductor — 프로젝트 개요
- [[2026-05-04_pab_khala_overview]] — PAB-Khala — 프로젝트 개요
- [[2026-05-04_pab_observer_overview]] — PAB-Observer — 프로젝트 개요
<!-- moc-build:auto-end -->

> Phase 1-4 `wiki moc-build` 명령으로 자동 채워질 placeholder.

- (placeholder — Phase 1-4 `wiki moc-build`에서 자동 채움)

## 작성 가이드

새 PROJECT 작성 시:

- 템플릿: [[40_Templates/PROJECT]]
- 명명 규칙: `wiki/10_Notes/YYYY-MM-DD_<project-slug>.md`
- 필수 frontmatter: `type: "[[PROJECT]]"`, `index: "[[PRODUCT]]"` (기본)
- 권장 섹션: 목표 / 산출물 / 일정 / 마일스톤 / 회고 링크([[LESSON]])
