---
title: "REFERENCE — Type MOC"
description: "REFERENCE TYPE에 속하는 모든 노트의 자동 수집 MOC. 빠른 참조용(체크리스트·치트시트·MOC) 진입점."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[TYPES]]"]
tags: [moc, types/reference]
keywords: [moc, reference, type-index, cheatsheet]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["REFERENCE MOC", "References Index"]
---

# REFERENCE — Type MOC

## TYPE 정의

`REFERENCE`는 **빠른 참조용 노트**이다. 체크리스트·치트시트·표·MOC 자체가 모두 REFERENCE에 속한다. 본 wiki의 MOC 노트(TYPES/DOMAINS/TOPICS)도 모두 `type: "[[REFERENCE]]"`로 자기-귀속한다.

- **작성 시점**: 자주 참조해야 하는 표·절차·룰을 정리할 때
- **예시**:
  - "PARA Method 정리"
  - "Obsidian Templater 단축키 치트시트"
  - 본 MOC 자체 ([[00_MOC/TYPES/REFERENCE]])

## 자동 수집 (dataview)

```dataview
LIST
FROM ""
WHERE type = "[[REFERENCE]]"
SORT created DESC
LIMIT 100
```

> **주의**: 본 MOC 자체도 `type: "[[REFERENCE]]"`이므로 자기 자신이 결과에 포함된다. Phase 1-4 폴백 정적 링크 갱신 시 `WHERE file.path != this.file.path` 조건을 추가하여 self-link 제거 가능.

## 폴백 정적 링크

<!-- moc-build:auto-start -->
- [[naming-convention]] — Naming Convention
- [[frontmatter-spec]] — Frontmatter Spec
- [[toc-recommendation]] — TOC Recommendation Algorithm
- [[linking-policy]] — Linking Policy
<!-- moc-build:auto-end -->

> Phase 1-4 `wiki moc-build` 명령으로 자동 채워질 placeholder.

- (placeholder — Phase 1-4 `wiki moc-build`에서 자동 채움)

## 작성 가이드

새 REFERENCE 작성 시:

- 템플릿: [[40_Templates/REFERENCE]]
- 명명 규칙: `wiki/10_Notes/YYYY-MM-DD_<slug>.md` 또는 영구 참조는 `wiki/30_Constraints/<slug>.md`
- 필수 frontmatter: `type: "[[REFERENCE]]"`
- 권장 섹션: 요약 / 표 또는 체크리스트 / 사용 시점 / 갱신 이력
