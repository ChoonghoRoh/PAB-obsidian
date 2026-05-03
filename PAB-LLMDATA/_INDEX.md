---
title: "PAB Wiki — Index"
description: "PAB Obsidian Karpathy-style Wiki 최상위 진입점. TYPES/DOMAINS/TOPICS 3중 인덱스로 분기."
created: 2026-05-01 00:00
updated: 2026-05-01 22:30
type: "[[INDEX]]"
index: "[[ROOT]]"
topics: []
tags: [moc, root]
keywords: [pab-wiki, root-index, moc]
sources: []
aliases: ["MOC", "Root", "Wiki Home"]
---

# PAB Wiki — Index

## 안내

본 wiki는 Karpathy-style LLM-friendly knowledge base이다. 모든 노트는 `YYYY-MM-DD_topic.md` 파일명 + 11필드 frontmatter를 따른다.

## 3중 인덱스

### By Type

> 노트의 `type` 필드 기준 자동 수집. dataview 사용 시 자동, 미사용 시 폴백 정적 링크로 도달.

```dataview
LIST
FROM "00_MOC/TYPES"
SORT file.name ASC
```

**폴백 정적 링크**:

- [[00_MOC/TYPES/RESEARCH_NOTE|RESEARCH_NOTE]] — 외부 자료 분석 노트
- [[00_MOC/TYPES/CONCEPT|CONCEPT]] — 개념·이론 정리
- [[00_MOC/TYPES/LESSON|LESSON]] — 경험 기반 교훈
- [[00_MOC/TYPES/PROJECT|PROJECT]] — 프로젝트 노트
- [[00_MOC/TYPES/DAILY|DAILY]] — 일별 메모
- [[00_MOC/TYPES/REFERENCE|REFERENCE]] — 참조·치트시트·MOC

### By Domain

> 노트의 `index` 필드(소속 DOMAIN MOC) 기준 자동 수집. 6 DOMAIN(+ROOT는 MOC 전용).

```dataview
LIST
FROM "00_MOC/DOMAINS"
SORT file.name ASC
```

**폴백 정적 링크**:

- [[00_MOC/DOMAINS/AI|AI]] — LLM·에이전트·NLP·CV·논문
- [[00_MOC/DOMAINS/HARNESS|HARNESS]] — Claude Code·CLI·IDE·Obsidian
- [[00_MOC/DOMAINS/ENGINEERING|ENGINEERING]] — 알고리즘·언어·아키텍처
- [[00_MOC/DOMAINS/PRODUCT|PRODUCT]] — 제품·프로젝트 단위 작업
- [[00_MOC/DOMAINS/KNOWLEDGE_MGMT|KNOWLEDGE_MGMT]] — PARA·Zettelkasten·KM 방법론
- [[00_MOC/DOMAINS/MISC|MISC]] — 미분류·일반 메모

### By Topic

> TOPIC은 동적 MOC. 노트 frontmatter `topics: ["[[FOO]]"]` 누적 시 자동 승격(기본 3건).

```dataview
LIST
FROM "00_MOC/TOPICS"
WHERE file.name != "_README"
SORT file.name ASC
```

**폴백 정적 링크**:

- [[00_MOC/TOPICS/_README|TOPICS — Rules]] — 자동 승격 규칙 + dataview 템플릿
- (placeholder — Phase 1-4 `wiki moc-build`로 자동 채움)

## 사용 가이드

- 새 노트 작성: `make wiki-new TYPE=research SLUG=my-topic` (Phase 1-4 이후)
- 링크 검증: `make wiki-link-check` (Phase 1-4 이후)
- MOC 갱신: `make wiki-moc-build` (Phase 1-4 이후)
- TOC 추천: `make wiki-toc-suggest NOTE=path/to/note.md` (Phase 1-4 이후)
- 새 TOPIC 등록: 노트 frontmatter `topics: ["[[NEW_TOPIC]]"]` 추가 → 3건 누적 시 자동 MOC 승격 (Phase 1-4 `wiki moc-build`)

## 폴더 구조

| 폴더 | 용도 |
|---|---|
| `00_MOC/` | TYPES/DOMAINS/TOPICS Map of Content |
| `10_Notes/` | 시간순 노트 (`YYYY-MM-DD_*.md`) |
| `20_Lessons/` | 정제된 교훈 |
| `30_Constraints/` | 규약·제약 (frontmatter 스펙·네이밍·링크 정책) |
| `40_Templates/` | Templater 템플릿 (TYPE별 6종) |
| `99_Inbox/` | 미분류 임시 보관 |
| `_attachments/` | 이미지·첨부 |

---

**작성**: Phase 1-1 (2026-05-01) | **갱신 완료**: Phase 1-3 (2026-05-01) — 3중 인덱스 자동 생성 + 폴백 정적 링크
