---
title: "KNOWLEDGE_MGMT — Domain MOC"
description: "KNOWLEDGE_MGMT 도메인(지식 관리 방법론·노트 시스템) 노트 자동 수집 MOC."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[DOMAINS]]"]
tags: [moc, domains/knowledge-mgmt]
keywords: [moc, knowledge-management, para, zettelkasten, second-brain]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["KNOWLEDGE_MGMT MOC", "Knowledge Mgmt Domain Index", "KM MOC"]
---

# KNOWLEDGE_MGMT — Domain MOC

## DOMAIN 정의

`KNOWLEDGE_MGMT`는 **지식 관리 방법론 도메인**이다. PARA·Zettelkasten·Karpathy wiki·second brain·스페이스드 리피티션 등 노트 시스템의 이론과 실천 노트를 모은다. 본 PAB Wiki 자체의 메타 노트(MOC 설계, 폴더 구조 등)도 이 도메인에 귀속.

**포함 주제 예시**: PARA, Zettelkasten, Karpathy wiki, second brain, spaced repetition, Obsidian workflow, MOC design, note-taking heuristics

## 자동 수집 (dataview)

```dataview
LIST
FROM ""
WHERE index = "[[KNOWLEDGE_MGMT]]"
SORT created DESC
LIMIT 100
```

## 폴백 정적 링크

<!-- moc-build:auto-start -->
- [[2026-05-05_pab_ssot_portability]] — PAB SSOT — 다른 프로젝트 이식 가이드 (Portability)
- [[2026-05-05_pab_ssot_intro]] — PAB SSOT v8.2-renewal-6th — 진입점·버전·3계층 아키텍처 개요
- [[2026-05-05_pab_ssot_templates]] — PAB SSOT — 템플릿 11종 (TEMPLATES/)
- [[2026-05-05_pab_ssot_persona_qc]] — PAB SSOT — 9 PERSONA Charter + 11명 Verification Council (QUALITY/10-persona-qc)
- [[2026-05-05_pab_ssot_roles]] — PAB SSOT — 역할 9종 정의 (ROLES/)
- [[2026-05-05_pab_ssot_workflow]] — PAB SSOT — 워크플로우·상태 머신·게이트·Phase Chain
- [[2026-05-05_pab_ssot_rules_chain]] — PAB SSOT — 96개 규칙 통합 인덱스 + 공통 포맷 (6-rules-index + 7-shared-definitions)
- [[2026-05-04_pab_ssot_nexus_overview]] — PAB-SSOT-Nexus — 프로젝트 개요
- [[2026-05-02_karpathy_llm_wiki_v1_backup]] — Karpathy의 LLM Wiki — 누적되는 지식 산출물 패턴
- [[2026-05-02_karpathy_llm_wiki_source]] — LLM Wiki (Karpathy) — 원문
- [[2026-05-02_karpathy_llm_wiki]] — Karpathy의 LLM Wiki — 누적되는 지식 산출물 패턴
<!-- moc-build:auto-end -->

> Phase 1-4 `wiki moc-build` 명령으로 자동 채워질 placeholder.

- (placeholder — Phase 1-4 `wiki moc-build`에서 자동 채움)

## 인접 도메인

- [[00_MOC/DOMAINS/HARNESS|HARNESS]] — Obsidian/CLI 등 KM 도구 체인
- [[00_MOC/DOMAINS/AI|AI]] — LLM-friendly wiki 등 AI 활용 KM
- [[00_MOC/DOMAINS/PRODUCT|PRODUCT]] — KM 시스템을 제품화하는 경우
