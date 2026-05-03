---
title: "HARNESS — Domain MOC"
description: "HARNESS 도메인(개발 환경·도구 체인·CLI·IDE·Obsidian) 노트 자동 수집 MOC."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[DOMAINS]]"]
tags: [moc, domains/harness]
keywords: [moc, harness, cli, ide, obsidian, claude-code]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["HARNESS MOC", "Harness Domain Index"]
---

# HARNESS — Domain MOC

## DOMAIN 정의

`HARNESS`는 **개발 환경·도구 체인 도메인**이다. AI 모델 자체가 아닌, 모델·코드를 다루기 위한 외피(harness) — CLI, IDE, hook 시스템, MCP 서버, 에디터 플러그인 등 — 의 노트를 모은다.

**포함 주제 예시**: Claude Code (CLI/SDK), Obsidian (CLI/플러그인), claude-in-chrome MCP, hooks, settings.json, slash commands, Templater

## 자동 수집 (dataview)

```dataview
LIST
FROM ""
WHERE index = "[[HARNESS]]"
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

- [[00_MOC/DOMAINS/AI|AI]] — Harness가 다루는 AI 모델 자체
- [[00_MOC/DOMAINS/ENGINEERING|ENGINEERING]] — Harness 구현에 사용되는 일반 SW 공학
- [[00_MOC/DOMAINS/KNOWLEDGE_MGMT|KNOWLEDGE_MGMT]] — Obsidian 등 노트 도구는 양 도메인에 걸쳐 있음
