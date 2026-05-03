---
title: "CONCEPT — Type MOC"
description: "CONCEPT TYPE에 속하는 모든 노트의 자동 수집 MOC. 개념·이론·정의 노트의 진입점."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[TYPES]]"]
tags: [moc, types/concept]
keywords: [moc, concept, type-index]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["CONCEPT MOC", "Concepts Index"]
---

# CONCEPT — Type MOC

## TYPE 정의

`CONCEPT`은 **개념·이론·정의를 정제한 노트**이다. 외부 출처가 있더라도 핵심은 "이 개념이 무엇인가"를 자기 언어로 정리하는 데 있다. 여러 RESEARCH_NOTE에서 추출된 공통 개념을 하나의 CONCEPT 노트로 승격시킨다.

- **작성 시점**: 동일 개념이 2회 이상 등장하여 별도 정리가 필요할 때, 또는 강의·문서에서 핵심 정의를 분리할 때
- **예시**:
  - "Karpathy LLM Wiki 개념"
  - "Map of Content (MOC) 정의"
  - "Tool Calling vs Function Calling"

## 자동 수집 (dataview)

```dataview
LIST
FROM ""
WHERE type = "[[CONCEPT]]"
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

새 CONCEPT 작성 시:

- 템플릿: [[40_Templates/CONCEPT]]
- 명명 규칙: `wiki/10_Notes/YYYY-MM-DD_<slug>.md`
- 필수 frontmatter: `type: "[[CONCEPT]]"`
- 권장 섹션: 정의 (1줄) / 배경 / 주요 속성 / 대비 개념 / 연관 노트
