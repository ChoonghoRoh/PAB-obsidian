---
title: "PRODUCT — Domain MOC"
description: "PRODUCT 도메인(제품·프로젝트 단위 작업) 노트 자동 수집 MOC."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[DOMAINS]]"]
tags: [moc, domains/product]
keywords: [moc, product, project, roadmap, prd]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["PRODUCT MOC", "Product Domain Index"]
---

# PRODUCT — Domain MOC

## DOMAIN 정의

`PRODUCT`는 **제품·프로젝트 단위 작업 도메인**이다. 특정 제품(PAB Wiki, side project 등) 또는 프로젝트의 로드맵·PRD·스프린트·UX 결정 노트를 모은다. 일반적으로 `type: "[[PROJECT]]"` 노트가 이 도메인에 귀속된다.

**포함 주제 예시**: PAB Wiki, side project, roadmap, PRD, sprint, UX research, OKR, product spec

## 자동 수집 (dataview)

```dataview
LIST
FROM ""
WHERE index = "[[PRODUCT]]"
SORT created DESC
LIMIT 100
```

## 폴백 정적 링크

<!-- moc-build:auto-start -->
_(현재 등록된 노트 없음)_
<!-- moc-build:auto-end -->

> Phase 1-4 `wiki moc-build` 명령으로 자동 채워질 placeholder.

- (placeholder — Phase 1-4 `wiki moc-build`에서 자동 채움)

## 인접 도메인

- [[00_MOC/DOMAINS/ENGINEERING|ENGINEERING]] — 제품 구현의 기술 스택
- [[00_MOC/DOMAINS/KNOWLEDGE_MGMT|KNOWLEDGE_MGMT]] — 제품 노트 시스템·회고 방법론
- [[00_MOC/DOMAINS/AI|AI]] — AI 기반 제품일 경우 교차 참조
