---
title: "Naming Convention"
description: "PAB Wiki 파일·폴더 명명 규약 — YYYY-MM-DD_slug.md 패턴 + slug 규칙 + 폴더 prefix + 첨부 파일 명명"
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

# Naming Convention

## 노트 파일명 표준

**패턴**: `YYYY-MM-DD_slug.md`

| 부분 | 규칙 | 예시 |
|---|---|---|
| 날짜 prefix | `YYYY-MM-DD` (4-2-2 자릿수 엄수) | `2026-05-01` |
| 구분자 | 언더스코어 1개 (`_`) | |
| slug | snake_case 영문·숫자, 50자 이하 | `agentic_engineering` |
| 확장자 | `.md` 강제 | |

**전체 예시**:
- `2026-04-21_agentic_engineering.md`
- `2026-05-01_obsidian_cli_setup.md`
- `2026-05-01_karpathy_llm_wiki.md`

**왜 날짜 prefix?**
- Obsidian 파일 탐색기에서 자동으로 시간순 정렬됨
- 동명 토픽 충돌 회피 (같은 주제를 다른 날 다시 정리 가능)
- LLM이 파일명만 보고 "언제, 무엇"을 즉시 파악

## slug 규칙

| 규칙 | 허용 | 금지 |
|---|---|---|
| 문자 | 소문자 영문 `a-z`, 숫자 `0-9` | 한글, 대문자, 특수문자 |
| 구분자 | 언더스코어 `_` | 하이픈 `-`, 공백 |
| 길이 | 1~50자 | 50자 초과 |
| 시작 문자 | 소문자 또는 숫자 | 언더스코어 시작 (`_slug`) |

**slug 작성 가이드**:
- 노트 `title` (한글 가능)을 영문 핵심 키워드로 압축
- 명사형, 동명사 모두 가능 (`agentic_engineering`, `building_llm_agents`)
- 약어는 그대로 허용 (`llm`, `rag`, `moc`, `pab`)
- 너무 길면 핵심 2~3 단어로 줄이기 (`2026_05_01_my_long_research_note_about_langgraph` → `langgraph_research`)

**검증 정규식**: `^\d{4}-\d{2}-\d{2}_[a-z0-9_]{1,50}\.md$`

## 폴더 prefix 규칙

| 폴더 | 의미 | 용도 |
|---|---|---|
| `00_` | MOC (Map of Content) | 인덱스·분류 계층 |
| `10_` | Notes | 실제 노트 본체 (YYYY-MM-DD_slug.md) |
| `15_` | Sources (원본 보존) | 외부 자료 원문 immutable 사본 (`/pab:wiki` 자동 생성, 변경 금지) |
| `20_` | Lessons | 정제된 교훈 (LESSON type) |
| `30_` | Constraints | 규약·제약 문서 (본 문서 포함) |
| `40_` | Templates | Templater 템플릿 (TYPE별 7종 + `_schema.json`) |
| `99_` | Inbox | 미분류 임시 보관 |
| `_` (언더스코어 시작) | 시스템 폴더 | `_attachments` — Obsidian default |

**왜 숫자 prefix?**
- Obsidian 파일 트리에서 자동 정렬 → `00_MOC`가 항상 최상단
- 폴더 의미·계층이 숫자만으로 즉시 파악됨
- LLM이 vault 구조를 탐색할 때 혼란 최소화

## 첨부 파일 명명

**위치**: `wiki/_attachments/` (Obsidian 기본 첨부 경로)

**패턴**: `YYYY-MM-DD_slug_kind.ext`

| 부분 | 규칙 |
|---|---|
| 날짜 | `YYYY-MM-DD` (노트와 동일 기준) |
| slug | 연관 노트 slug 또는 내용 설명 |
| kind | `screenshot` / `diagram` / `figure` / `pdf` / `audio` |
| ext | `.png`, `.jpg`, `.pdf`, `.mp3` 등 실제 확장자 |

**예시**:
- `2026-04-21_agentic_engineering_screenshot.png`
- `2026-05-01_pab_wiki_architecture_diagram.png`
- `2026-05-01_karpathy_lecture_notes_pdf.pdf`

## MOC 파일명 (Phase 1-3에서 채워짐)

| 폴더 | 파일명 패턴 | 예시 | 이유 |
|---|---|---|---|
| `00_MOC/TYPES/` | `<TYPE>.md` (대문자 그대로) | `RESEARCH_NOTE.md`, `CONCEPT.md` | `type: "[[RESEARCH_NOTE]]"` wikilink와 파일명 일치 |
| `00_MOC/DOMAINS/` | `<DOMAIN>.md` (대문자 그대로) | `AI.md`, `HARNESS.md` | `index: "[[AI]]"` wikilink와 파일명 일치 |
| `00_MOC/TOPICS/` | `<TOPIC>.md` (UPPER_SNAKE_CASE) | `LANGGRAPH.md`, `MULTI_AGENT.md` | `topics: ["[[LANGGRAPH]]"]` wikilink와 파일명 일치 |

**왜 대문자?** Obsidian wikilink가 `[[AI]]`, `[[LANGGRAPH]]` 등 대문자 패턴이므로, 파일명도 대문자로 일치시켜야 백링크·그래프가 정확히 동작한다.

## 잘못된/올바른 예시 5건

### 1. 한글·공백 포함 파일명

```
❌ LangGraph 정리.md
   이유: 한글·공백 → OS 간 호환성 문제, LLM slug 파싱 불가

✅ 2026-05-01_langgraph_basics.md
```

### 2. 날짜 자릿수 오류

```
❌ 2026-5-1_topic.md
   이유: 월·일이 2자리여야 함. 파일명 정렬 오류 발생.

✅ 2026-05-01_topic.md
```

### 3. 하이픈 구분자 사용

```
❌ 2026-05-01-agentic-engineering.md
   이유: 날짜 구분자(-) 와 slug 구분자가 동일 → slug 경계 모호.

✅ 2026-05-01_agentic_engineering.md
```

### 4. 첨부 파일 날짜·맥락 없음

```
❌ screenshot.png
   이유: 어떤 노트·주제인지 불명. 시간 정보 없음.

✅ 2026-04-21_agentic_engineering_screenshot.png
```

### 5. 날짜·slug 없는 일반 노트

```
❌ notes.md
   이유: 날짜 prefix·slug 모두 없음 → 정렬·검색·링크 불가.

✅ 2026-05-01_meeting_summary.md
```

## 검증 방법

### 자동 (Phase 1-4 구현 후)

```bash
python3 scripts/wiki/wiki.py link-check
# 또는
make wiki-link-check
```

### 수동 정규식

```bash
# 노트 파일명 규약 위반 탐지
find wiki/ -name "*.md" | grep -v "^wiki/40_Templates\|^wiki/30_Constraints\|^wiki/_INDEX\|^wiki/00_MOC" \
  | grep -v -E "/[0-9]{4}-[0-9]{2}-[0-9]{2}_[a-z0-9_]{1,50}\.md$"
# 결과 없으면 모두 정상
```
