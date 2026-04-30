---
task_id: "1-1-5"
title: "wiki/_INDEX.md 진입점 노트 작성"
domain: WIKI-INFRA
owner: backend-dev
priority: P0
estimate_min: 5
status: pending
depends_on: ["1-1-2", "1-1-4"]
blocks: []
---

# Task 1-1-5 — `wiki/_INDEX.md` 진입점 노트 작성

## 목적

vault 최상위 진입점 노트(`_INDEX.md`)를 작성. frontmatter 11필드 스키마를 준수하며, Phase 1-3에서 3중 인덱스(TYPES/DOMAINS/TOPICS)로 갱신될 placeholder 본문을 포함한다.

## 작성 내용

```markdown
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
```

## 실행 절차

Write 도구로 `wiki/_INDEX.md` 파일 생성. 위 내용 그대로 사용.

## 검증

```bash
# 파일 존재
ls wiki/_INDEX.md

# frontmatter 11필드 확인
python3 -c "
import yaml
with open('wiki/_INDEX.md') as f:
    content = f.read()
front = content.split('---')[1]
data = yaml.safe_load(front)
required = ['title', 'description', 'created', 'updated', 'type', 'index', 'topics', 'tags', 'keywords', 'sources', 'aliases']
missing = [k for k in required if k not in data]
assert not missing, f'Missing fields: {missing}'
print('OK: all 11 fields present')
print(data)
"

# Obsidian이 인식하는지 확인
obsidian search "Index" --vault "$(pwd)/wiki"
```

## 완료 기준

- [ ] `wiki/_INDEX.md` 존재
- [ ] frontmatter 11필드 모두 존재 (검증 스크립트 통과)
- [ ] `obsidian search "Index"` 결과에 `_INDEX.md` 포함
- [ ] 본문에 폴더 구조 표 + 사용 가이드 포함

## 보고

backend-dev는 `reports/report-backend-dev.md`의 §T-5 섹션에 검증 스크립트 출력 캡처.

## 위험

- frontmatter 날짜 형식 (`2026-05-01 00:00` 형식) 파싱 — `yaml.safe_load`가 Python `datetime` 객체로 변환할 수 있음. 검증 스크립트는 키 존재만 체크하므로 OK.
