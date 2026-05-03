---
title: "AI — Domain MOC"
description: "AI 도메인(LLM·에이전트·NLP·CV·논문) 노트 자동 수집 MOC. type 무관, index가 [[AI]]인 모든 노트."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[DOMAINS]]"]
tags: [moc, domains/ai]
keywords: [moc, ai, llm, agent, nlp]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["AI MOC", "AI Domain Index"]
---

# AI — Domain MOC

## DOMAIN 정의

`AI`는 **인공지능 일반 도메인**이다. 머신러닝·딥러닝·LLM·에이전트·NLP·컴퓨터 비전·강화학습 등 AI/ML 전반의 노트를 모은다. 도구 체인(claude-code 등)은 [[HARNESS]]로 분리하고, 일반 SW 공학(알고리즘/언어)은 [[ENGINEERING]]으로 분리한다.

**포함 주제 예시**: LangGraph, Claude, GPT, multi-agent, prompting, RAG, fine-tuning, attention, transformer, RLHF

## 자동 수집 (dataview)

```dataview
LIST
FROM ""
WHERE index = "[[AI]]"
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

- [[00_MOC/DOMAINS/HARNESS|HARNESS]] — AI 도구 체인 (Claude Code, IDE)
- [[00_MOC/DOMAINS/ENGINEERING|ENGINEERING]] — 일반 SW 공학 (AI 시스템 구현 시 교차)
- [[00_MOC/DOMAINS/KNOWLEDGE_MGMT|KNOWLEDGE_MGMT]] — AI 활용 노트 시스템(LLM-friendly wiki 등)
