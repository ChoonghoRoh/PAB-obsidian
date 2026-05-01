---
title: "PAB Wiki — Index"
description: "PAB Obsidian Karpathy-style Wiki 최상위 진입점. TYPES/DOMAINS/TOPICS 3중 인덱스로 분기."
created: 2026-05-01 00:00
updated: 2026-05-01 00:00
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

## 3중 인덱스 (Phase 1-3에서 채워짐)

### By Type
- (placeholder — Phase 1-3에서 `00_MOC/TYPES/` 링크 자동 채움)

### By Domain
- (placeholder — Phase 1-3에서 `00_MOC/DOMAINS/` 링크 자동 채움)

### By Topic
- (placeholder — Phase 1-3에서 `00_MOC/TOPICS/` 링크 자동 채움)

## 사용 가이드

- 새 노트 작성: `make wiki-new TYPE=research SLUG=my-topic` (Phase 1-4 이후)
- 링크 검증: `make wiki-link-check` (Phase 1-4 이후)
- MOC 갱신: `make wiki-moc-build` (Phase 1-4 이후)
- TOC 추천: `make wiki-toc-suggest NOTE=path/to/note.md` (Phase 1-4 이후)

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

**작성**: Phase 1-1 (2026-05-01) | **갱신 예정**: Phase 1-3 (3중 인덱스 자동 생성)
