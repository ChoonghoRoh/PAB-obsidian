---
title: "MISC — Domain MOC"
description: "MISC 도메인(미분류 — 위 5개 도메인에 속하지 않는 노트) 자동 수집 MOC."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[DOMAINS]]"]
tags: [moc, domains/misc]
keywords: [moc, misc, uncategorized, inbox]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["MISC MOC", "Misc Domain Index"]
---

# MISC — Domain MOC

## DOMAIN 정의

`MISC`는 **미분류 도메인**이다. AI/HARNESS/ENGINEERING/PRODUCT/KNOWLEDGE_MGMT 5개 어디에도 속하지 않는 노트(개인 로그·일반 메모·분류 전 임시 노트)를 모은다. DAILY 노트의 기본 index 값으로도 사용된다.

**포함 주제 예시**: 개인 로그, 일반 메모, 분류 전 inbox, 미정 영역, life log

> **승격 권고**: MISC 노트가 누적되면 정기적으로 검토하여 5개 주 도메인 중 하나로 재분류한다. `99_Inbox/`도 MISC에 속하므로 inbox 정리 사이클과 연계.

## 자동 수집 (dataview)

```dataview
LIST
FROM ""
WHERE index = "[[MISC]]"
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

- [[00_MOC/DOMAINS/KNOWLEDGE_MGMT|KNOWLEDGE_MGMT]] — MISC 분류 정리 자체가 KM 활동
- [[00_MOC/DOMAINS/PRODUCT|PRODUCT]] — 개인 프로젝트 일부는 MISC → PRODUCT 승격
- [[00_MOC/DOMAINS/AI|AI]] — AI 관련 단편 메모는 AI 승격 후보
