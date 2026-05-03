---
title: "TOPICS — Dynamic MOC Placeholder"
description: "TOPIC MOC 자동 생성 규칙 + Phase 1-4 wiki moc-build 참조 문서. TOPIC은 노트가 등장하면서 동적으로 승격된다."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[TOPICS]]"]
tags: [moc, topics, placeholder]
keywords: [topic-moc, dynamic-moc, promotion-threshold]
sources: ["wiki/30_Constraints/frontmatter-spec.md", "wiki/30_Constraints/linking-policy.md"]
aliases: ["Topics README", "Topic MOC Rules"]
---

# TOPICS — Dynamic MOC Placeholder

## 개념

TOPIC은 TYPES/DOMAINS와 달리 **사전 정의된 enum이 아니다**. 노트가 작성되면서 frontmatter `topics: ["[[FOO]]"]` 필드에 등록된 wikilink가 일정 임계치 이상 누적되면 비로소 `wiki/00_MOC/TOPICS/FOO.md` MOC가 **동적으로 승격·생성**된다.

| 구분 | TYPES (정적) | DOMAINS (정적) | TOPICS (동적) |
|---|---|---|---|
| enum 사전 정의 | ✅ 6개 (RESEARCH_NOTE 등) | ✅ 7개 (AI 등 + ROOT) | ❌ 노트 등장 후 결정 |
| MOC 파일 생성 | Phase 1-3에 일괄 | Phase 1-3에 일괄 | Phase 1-4 `wiki moc-build` 자동 |
| 신규 추가 | schema 갱신 필요 | schema 갱신 필요 | 노트 작성만으로 자동 |

## 자동 승격 규칙

- **임계치 기본값**: `topics: ["[[FOO]]"]`로 등록된 노트가 **3건 이상** 누적되면 `wiki/00_MOC/TOPICS/FOO.md` MOC 자동 생성
- **임계치 조정**: Phase 1-4 `wiki moc-build --topic-threshold N` 옵션으로 변경 가능 (기본 N=3)
- **자동 생성된 MOC의 구조**: 본 _README.md의 [[#dataview 템플릿 스니펫|dataview 템플릿]] 섹션을 따라 자동 작성
- **재생성 정책**: 임계치 미만으로 떨어진 TOPIC MOC는 자동 삭제하지 않음 (수동 정리). 노트 누적 시 idempotent하게 갱신.

## 명명 규약

| 위치 | 형식 | 예시 |
|---|---|---|
| frontmatter `topics` 항목 | `[[FOO_BAR]]` (UPPER_SNAKE_CASE wikilink) | `[[LANGGRAPH]]`, `[[MULTI_AGENT]]` |
| `tags` 항목 | `topics/foo-bar` (소문자 + 하이픈) | `topics/langgraph`, `topics/multi-agent` |
| MOC 파일명 | `wiki/00_MOC/TOPICS/FOO_BAR.md` (UPPER_SNAKE_CASE + `.md`) | `wiki/00_MOC/TOPICS/LANGGRAPH.md` |

> **주의**: schema의 `tags` 패턴은 `^[a-z0-9-]+$`이므로 `tags: [topics/langgraph]`처럼 `/`를 포함한 슬러그 사용 시 검증 정책 확정이 필요. 현재 본 wiki는 슬러그 형식을 권고로 두고 schema 갱신은 Phase 1-4에서 결정.

## dataview 템플릿 스니펫

자동 생성될 TOPIC MOC가 사용할 기본 쿼리:

```dataview
LIST
FROM ""
WHERE contains(topics, "[[<TOPIC_NAME>]]")
SORT created DESC
LIMIT 100
```

TYPE 결합 검색이 필요할 경우 (예: LANGGRAPH 관련 RESEARCH_NOTE만):

```dataview
LIST
FROM ""
WHERE contains(topics, "[[<TOPIC>]]") AND type = "[[RESEARCH_NOTE]]"
SORT created DESC
```

## 현재 등록된 TOPICS

> Phase 1-4 `wiki moc-build` 실행 후 자동 채워질 placeholder.

| TOPIC | 노트 수 | MOC 경로 | 상태 |
|---|---|---|---|
| (없음 — Phase 1-4 이후 자동 채움) | — | — | placeholder |
