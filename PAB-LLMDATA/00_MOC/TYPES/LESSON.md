---
title: "LESSON — Type MOC"
description: "LESSON TYPE에 속하는 모든 노트의 자동 수집 MOC. 본인 경험·실험에서 정제된 교훈 노트의 진입점."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[TYPES]]"]
tags: [moc, types/lesson]
keywords: [moc, lesson, type-index, retrospective]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["LESSON MOC", "Lessons Index"]
---

# LESSON — Type MOC

## TYPE 정의

`LESSON`은 **본인의 실험·실패·성공 경험에서 정제된 교훈**이다. RESEARCH_NOTE가 외부 자료 기반인 데 반해, LESSON은 일차 경험에서 출발한다. 향후 동일 상황에서 빠르게 복기·재활용 가능한 형태로 작성한다.

- **작성 시점**: 작업 완료 후 회고, 실수에서 배운 점, 트러블슈팅 결과 정리
- **예시**:
  - "Obsidian CLI Setup 시 hookup 절차"
  - "Claude Code 멀티 에이전트 시 컨텍스트 누수 회피"
  - "Phase G3 검증 자기 평가 회피의 중요성"

## 자동 수집 (dataview)

```dataview
LIST
FROM ""
WHERE type = "[[LESSON]]"
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

새 LESSON 작성 시:

- 템플릿: [[40_Templates/LESSON]]
- 명명 규칙: `wiki/20_Lessons/YYYY-MM-DD_<slug>.md` (LESSON은 별도 폴더)
- 필수 frontmatter: `type: "[[LESSON]]"`
- 권장 섹션: 상황 / 행동 / 결과 / 교훈 (1줄) / 재발 방지 체크리스트
