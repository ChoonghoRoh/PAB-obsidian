---
title: "DAILY — Type MOC"
description: "DAILY TYPE에 속하는 모든 노트의 자동 수집 MOC. 일별 메모·로그 노트의 진입점."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[TYPES]]"]
tags: [moc, types/daily]
keywords: [moc, daily, type-index, journal]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["DAILY MOC", "Daily Notes Index"]
---

# DAILY — Type MOC

## TYPE 정의

`DAILY`는 **일별 메모·로그 노트**이다. 짧은 단편 — 오늘 한 일, 내일 할 일, 떠오른 아이디어 등을 시간순으로 모은다. 후일 정제할 가치가 있는 항목은 RESEARCH_NOTE / CONCEPT / LESSON으로 승격시킨다.

- **작성 시점**: 매일 1회 (선택), 큰 변동 있는 날
- **예시**:
  - "2026-05-01 Daily — wiki bootstrap kickoff"
  - "2026-05-02 Daily — Phase 1-2 frontmatter 확정"

## 자동 수집 (dataview)

```dataview
LIST
FROM ""
WHERE type = "[[DAILY]]"
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

새 DAILY 작성 시:

- 템플릿: [[40_Templates/DAILY]]
- 명명 규칙: `wiki/10_Notes/YYYY-MM-DD_daily.md`
- 필수 frontmatter: `type: "[[DAILY]]"`, `index: "[[MISC]]"` (기본)
- 권장 섹션: 한 일 / 배운 것 / 막힌 것 / 내일 할 일 / 승격 후보 노트
