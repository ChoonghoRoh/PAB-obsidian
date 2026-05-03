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
_(현재 등록된 노트 없음)_
<!-- moc-build:auto-end -->

> Phase 1-4 `wiki moc-build` 명령으로 자동 채워질 placeholder.

- (placeholder — Phase 1-4 `wiki moc-build`에서 자동 채움)

## 작성 가이드

새 PROJECT 작성 시:

- 템플릿: [[40_Templates/PROJECT]]
- 명명 규칙: `wiki/10_Notes/YYYY-MM-DD_<project-slug>.md`
- 필수 frontmatter: `type: "[[PROJECT]]"`, `index: "[[PRODUCT]]"` (기본)
- 권장 섹션: 목표 / 산출물 / 일정 / 마일스톤 / 회고 링크([[LESSON]])
