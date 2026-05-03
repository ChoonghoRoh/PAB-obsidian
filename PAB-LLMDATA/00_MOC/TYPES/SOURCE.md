---
title: "SOURCE — Type MOC"
description: "SOURCE TYPE에 속하는 모든 원본 보존 노트의 자동 수집 MOC. /pab:wiki 가 자동 생성하는 immutable 원문 사본의 진입점."
created: 2026-05-02 23:00
updated: 2026-05-02 23:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[TYPES]]"]
tags: [moc, types/source]
keywords: [moc, source, type-index, immutable]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["SOURCE MOC", "Source Notes Index", "원본 보존 MOC"]
---

# SOURCE — Type MOC

## TYPE 정의

`SOURCE`는 **외부 자료의 원문 텍스트를 그대로 보존한 immutable 노트**이다. Karpathy LLM Wiki 패턴의 "raw sources" 계층에 해당한다.

- **변경 정책**: 작성 후 *수정 금지*. LLM이 임의로 갱신하는 것을 막기 위한 원칙.
- **짝 관계**: 각 SOURCE 노트는 `wiki/10_Notes/`의 동일 slug 요약본(`RESEARCH_NOTE` 등)과 쌍을 이룬다.
- **생성 방식**: `/pab:wiki <input>` 1회 호출 시 원본+요약 두 파일이 동시 생성됨.
- **저장 위치**: `wiki/15_Sources/YYYY-MM-DD_<slug>_source.md`
- **예시**:
  - `wiki/15_Sources/2026-05-02_karpathy_llm_wiki_source.md` — Karpathy gist 원문
  - 짝: `wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md` — LLM 요약본

## Karpathy 3계층에서의 위치

| 계층 | 역할 | 경로 |
|---|---|---|
| **원본 출처 (immutable)** | SOURCE TYPE — 본 폴더 | `wiki/15_Sources/` |
| 위키 (LLM 유지) | RESEARCH_NOTE 등 | `wiki/10_Notes/` |
| 스키마 (설정) | Constraints + SKILL.md | `wiki/30_Constraints/` + `skills/wiki/` |

## 자동 수집 (dataview)

```dataview
LIST
FROM ""
WHERE type = "[[SOURCE]]"
SORT created DESC
LIMIT 100
```

## 폴백 정적 링크

<!-- moc-build:auto-start -->
_(현재 등록된 노트 없음)_
<!-- moc-build:auto-end -->

> Phase 1-4 `wiki moc-build` 명령으로 자동 채워질 placeholder.

## 작성 가이드

SOURCE 노트는 직접 작성하지 않는다. `/pab:wiki <input>` 호출 시 자동 생성됨.

- 템플릿: [[40_Templates/SOURCE]]
- 명명 규칙: `wiki/15_Sources/YYYY-MM-DD_<slug>_source.md`
- 필수: `type: "[[SOURCE]]"`, `sources: [<외부 URL>]`, "변경 금지" 헤더
- 짝 요약본 wikilink: 요약본의 `sources` 필드에서 자동 참조됨 (backlink)
