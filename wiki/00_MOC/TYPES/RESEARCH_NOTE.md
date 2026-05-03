---
title: "RESEARCH_NOTE — Type MOC"
description: "RESEARCH_NOTE TYPE에 속하는 모든 노트의 자동 수집 MOC. 외부 레퍼런스/논문/실험 노트의 진입점."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[TYPES]]"]
tags: [moc, types/research-note]
keywords: [moc, research-note, type-index]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["RESEARCH_NOTE MOC", "Research Notes Index"]
---

# RESEARCH_NOTE — Type MOC

## TYPE 정의

`RESEARCH_NOTE`는 **외부 자료(논문·블로그·강의·영상·기술 문서 등)를 분석·정제한 노트**이다. 출처(`sources` 필드)를 명확히 갖추고, 인용·요약·자체 해석을 분리하여 LLM이 원천을 추적할 수 있게 한다.

- **작성 시점**: 외부 자료를 학습하면서 (강의 시청 중 / 논문 정독 중 / 블로그 정리 중)
- **예시**:
  - "Agentic Engineering 개론" — Karpathy 강의 분석
  - "LangGraph 멀티에이전트 패턴" — 공식 문서 + arXiv 논문 정리
  - "Claude Code Hook 메커니즘" — Anthropic docs 발췌

## 자동 수집 (dataview)

```dataview
LIST
FROM ""
WHERE type = "[[RESEARCH_NOTE]]"
SORT created DESC
LIMIT 100
```

## 폴백 정적 링크

<!-- moc-build:auto-start -->
_(현재 등록된 노트 없음)_
<!-- moc-build:auto-end -->

> Phase 1-4 `wiki moc-build` 명령으로 자동 채워질 placeholder. dataview 미지원 환경(LLM/CLI)에서도 도달할 수 있도록 정적 링크 리스트를 유지한다.

- (placeholder — Phase 1-4 `wiki moc-build`에서 자동 채움)

## 작성 가이드

새 RESEARCH_NOTE 작성 시 다음 템플릿을 사용한다:

- 템플릿: [[40_Templates/RESEARCH_NOTE]]
- 명명 규칙: `wiki/10_Notes/YYYY-MM-DD_<slug>.md`
- 필수 frontmatter: `type: "[[RESEARCH_NOTE]]"`, `sources: [...]` (외부 URL/도서명 1개 이상)
- 권장 섹션: 개요 / 핵심 주장 / 인용 / 본인 해석 / 후속 질문
