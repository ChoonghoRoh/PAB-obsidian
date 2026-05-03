---
task_id: "1-2-4"
title: "파일명 규약 (naming-convention.md)"
domain: WIKI-META
owner: backend-dev
priority: P1
estimate_min: 15
status: pending
depends_on: []
blocks: []
---

# Task 1-2-4 — `wiki/30_Constraints/naming-convention.md`

## 목적

PAB Wiki의 모든 파일·폴더 명명 규칙을 정의한다. 노트 파일명, 첨부 파일, MOC, 폴더 prefix 규칙을 일관되게 강제한다.

## 산출물

`wiki/30_Constraints/naming-convention.md` (단일 파일)

## 문서 frontmatter (자기참조)

```yaml
---
title: "Naming Convention"
description: "PAB Wiki 파일·폴더 명명 규약 — YYYY-MM-DD_slug.md 패턴 + slug 규칙"
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[CONSTRAINTS]]"]
tags: [reference, naming, convention, constraints]
keywords: [filename, slug, snake-case, attachment]
sources: []
aliases: ["Naming Convention", "Filename Spec", "Slug Rules"]
---
```

## 본문 필수 섹션

### `## 노트 파일명 표준`

**패턴**: `YYYY-MM-DD_slug.md`

| 부분 | 규칙 | 예시 |
|---|---|---|
| 날짜 prefix | `YYYY-MM-DD` (4-2-2 자릿수) | `2026-05-01` |
| 구분자 | 언더스코어 1개 (`_`) | |
| slug | snake_case 영문 + 숫자, 50자 이하 | `agentic_engineering` |
| 확장자 | `.md` 강제 | |

**전체 예시**: `2026-04-21_agentic_engineering.md`, `2026-05-01_obsidian_cli_setup.md`

**왜 날짜 prefix?**
- Obsidian 파일 탐색기 정렬이 자연스럽게 시간순
- 동명 노트 충돌 회피 (같은 토픽을 다른 날 다시 정리할 수 있음)
- LLM이 파일명만 보고 "언제, 무엇" 즉시 인식

### `## slug 규칙`

| 규칙 | 허용 | 금지 |
|---|---|---|
| 문자 | 소문자 영문 a-z, 숫자 0-9 | 한글, 대문자, 특수문자 |
| 구분자 | 언더스코어 `_` | 하이픈 `-`, 공백 |
| 길이 | 1~50자 | 50자 초과 |
| 시작 | 소문자 또는 숫자 | 언더스코어 시작 |

**slug 작성 가이드**:
- 노트 `title` (한글 가능)을 영문 키워드로 압축
- 명사형, 동명사 가능 (`agentic_engineering`, `building_llm_agents`)
- 약어는 그대로 (`llm`, `rag`, `moc`)

### `## 폴더 prefix 규칙`

| 폴더 | 의미 |
|---|---|
| `00_` | MOC (Map of Content) — 인덱스 |
| `10_` | Notes — 실제 노트 본체 |
| `20_` | Lessons — 정제된 교훈 |
| `30_` | Constraints — 규약·제약 |
| `40_` | Templates — Templater 템플릿 |
| `99_` | Inbox — 미분류 임시 |
| `_` (언더스코어 시작) | 시스템 폴더 (`_attachments`) |

**왜 숫자 prefix?**
- Obsidian 파일 트리에서 자동 정렬 → MOC가 항상 최상단
- 경계가 명확하여 LLM이 폴더 의미를 즉시 파악

### `## 첨부 파일 명명`

**위치**: `wiki/_attachments/` (Obsidian default)

**패턴**: `YYYY-MM-DD_slug_kind.ext`
- `kind`: `screenshot` / `diagram` / `figure` / `pdf` / `audio`
- 예시: `2026-04-21_agentic_engineering_screenshot.png`

### `## MOC 파일명 (Phase 1-3에서 채움)`

| 폴더 | 패턴 | 예시 |
|---|---|---|
| `00_MOC/TYPES/` | `<TYPE>.md` (대문자 그대로) | `RESEARCH_NOTE.md`, `CONCEPT.md` |
| `00_MOC/DOMAINS/` | `<DOMAIN>.md` (대문자 그대로) | `AI.md`, `HARNESS.md` |
| `00_MOC/TOPICS/` | `<TOPIC>.md` (UPPER_SNAKE_CASE) | `LANGGRAPH.md`, `MULTI_AGENT.md` |

**왜 대문자?** wikilink가 `[[AI]]`, `[[LANGGRAPH]]` 등 대문자 패턴이므로 파일명도 일치.

### `## 잘못된/올바른 예시 5건`

1. ❌ `LangGraph 정리.md` → ✅ `2026-05-01_langgraph_basics.md`
2. ❌ `2026-5-1_topic.md` (자릿수 오류) → ✅ `2026-05-01_topic.md`
3. ❌ `2026-05-01-agentic-engineering.md` (하이픈) → ✅ `2026-05-01_agentic_engineering.md`
4. ❌ `screenshot.png` (날짜·맥락 없음) → ✅ `2026-04-21_agentic_engineering_screenshot.png`
5. ❌ `notes.md` (날짜·slug 누락) → ✅ `2026-05-01_meeting_summary.md`

### `## 검증 방법`

- 자동: Phase 1-4 `wiki link-check`의 파일명 규약 검증 모듈
- 수동 정규식: `^\d{4}-\d{2}-\d{2}_[a-z0-9_]{1,50}\.md$`

## 완료 기준

- [ ] 파일 존재
- [ ] 자체 frontmatter 11필드 포함
- [ ] 노트 파일명 패턴 정의
- [ ] slug 규칙 명시
- [ ] 폴더 prefix 규칙
- [ ] 첨부 파일 명명
- [ ] MOC 파일명 규칙 (Phase 1-3 대비)
- [ ] 잘못된/올바른 예시 5건

## 보고

`reports/report-backend-dev.md` §T-4 섹션:
- 파일 경로 + 라인 수
- 정규식 패턴 캡처
