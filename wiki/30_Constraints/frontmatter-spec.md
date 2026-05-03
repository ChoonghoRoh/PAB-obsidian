---
title: "Frontmatter Spec"
description: "PAB Wiki 노트의 11필드 frontmatter 표준 — 작성 가이드. 기계 검증은 _schema.json, 본 문서는 사람 가이드."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[CONSTRAINTS]]"]
tags: [reference, frontmatter, spec, constraints]
keywords: [frontmatter, schema, metadata, yaml, obsidian]
sources: ["wiki/40_Templates/_schema.json"]
aliases: ["Frontmatter Spec", "Metadata Spec", "FM Spec"]
---

# Frontmatter Spec

## 개요

PAB Wiki의 모든 노트는 **11필드 frontmatter**를 포함해야 한다. 이는 Karpathy-style LLM-friendly wiki의 핵심 메타데이터 표준이다.

> **SOURCE TYPE immutable 원칙**: `type: "[[SOURCE]]"` 노트는 외부 자료의 원문 텍스트를 보존한다. 작성 후 *수정 금지*. `/pab:wiki`가 자동 생성하며 사람 또는 LLM이 임의 편집해서는 안 된다.

- **기계 검증 도구**: `wiki link-check` (Phase 1-4 구현) — `wiki/40_Templates/_schema.json` 로드 후 검증
- **검증 기준**: [G2_wiki 게이트](../../docs/phases/phase-1-exceptions.md) — Critical 필드 누락 시 FAIL
- **JSON Schema**: `wiki/40_Templates/_schema.json` (Draft 2020-12)

## 11필드 표

| # | 필드 | 타입 | 등급 | 설명 | 예시 |
|---|---|---|---|---|---|
| 1 | `title` | string | **Critical** | 노트 제목 (한글 가능) | `"Agentic Engineering 개론"` |
| 2 | `description` | string | High | 1~2줄 요약 (LLM 검색용) | `"LangGraph 멀티에이전트 연구 노트"` |
| 3 | `created` | string | **Critical** | 작성 날짜·시각 `YYYY-MM-DD HH:MM` | `2026-05-01 22:00` |
| 4 | `updated` | string | High | 마지막 수정 날짜·시각 | `2026-05-01 23:30` |
| 5 | `type` | wikilink | **Critical** | 7 TYPE 중 1개 (`[[INDEX]]`는 wiki/_INDEX.md 1건 전용) | `"[[RESEARCH_NOTE]]"` |
| 6 | `index` | wikilink | High | 소속 DOMAIN MOC | `"[[AI]]"` |
| 7 | `topics` | wikilink[] | High | 관련 TOPIC 배열 | `["[[LANGGRAPH]]", "[[MULTI_AGENT]]"]` |
| 8 | `tags` | string[] | High | Obsidian 태그 (소문자·하이픈, nested `a/b/c` 허용) — `^[a-z0-9-]+(/[a-z0-9-]+)*$` | `[research-note, langgraph]`, `[moc, types/research-note]` |
| 9 | `keywords` | string[] | Low | 자유 키워드 | `["LangGraph", "tool calling"]` |
| 10 | `sources` | string[] | Low | 외부 출처 URL/도서명 | `["https://arxiv.org/..."]` |
| 11 | `aliases` | string[] | High | Obsidian 별칭 | `["에이전틱 엔지니어링"]` |

## 필드 등급

### 필수 (Critical) — 누락 시 G2_wiki FAIL

- `title`: 노트 고유 제목. `minLength: 1`
- `created`: 작성 날짜. `YYYY-MM-DD` 또는 `YYYY-MM-DD HH:MM`
- `type`: 7 TYPE 중 1개 wikilink. `[[RESEARCH_NOTE]]` / `[[CONCEPT]]` / `[[LESSON]]` / `[[PROJECT]]` / `[[DAILY]]` / `[[REFERENCE]]` / `[[INDEX]]` (마지막 `[[INDEX]]`는 `wiki/_INDEX.md` 1건 전용)

### High — 누락 시 G2_wiki PARTIAL

- `description`: LLM prefetch·검색용 요약. 빈 문자열보다 1문장이라도 작성 권장.
- `updated`: 첫 작성 시 `created`와 동일하게, 수정마다 갱신.
- `index`: DOMAIN MOC 1개 지정. 빈 채로 두면 MOC 시스템에서 누락됨.
- `topics`: TOPIC 배열. Phase 1-3 이전에는 `[]` 허용.
- `tags`: 첫 항목은 TYPE 슬러그(`research-note` 등) 권장.
- `aliases`: 한글·약어·동의어 1개 이상 권장.

### Low — 빈 배열 허용 (PASS)

- `keywords`: 자유 키워드. 빈 배열 `[]` 가능.
- `sources`: 외부 참조 없으면 `[]`.

## 잘못된 예시 vs 올바른 예시

### 1. `type` 평문 사용

```yaml
# ❌ 잘못된 예 — 평문으로 type 지정
type: RESEARCH_NOTE

# 이유: JSON Schema의 pattern 검사 실패. Obsidian wikilink로도 동작 안 함.

# ✅ 올바른 예 — wikilink 형식
type: "[[RESEARCH_NOTE]]"
```

### 2. `created` ISO 8601 풀 형식

```yaml
# ❌ 잘못된 예 — ISO 8601 전체 형식
created: 2026-05-01T22:00:00Z

# 이유: schema 패턴 `^\d{4}-\d{2}-\d{2}( \d{2}:\d{2})?$` 불일치.

# ✅ 올바른 예 — 공백 구분자 사용
created: 2026-05-01 22:00
# 또는 날짜만
created: 2026-05-01
```

### 3. `tags` 대문자 + 공백

```yaml
# ❌ 잘못된 예 — 대문자·공백 포함
tags: [Multi Agent, LangGraph]

# 이유: schema items 패턴 `^[a-z0-9-]+(/[a-z0-9-]+)*$` — 각 segment는 소문자·숫자·하이픈만 허용.

# ✅ 올바른 예 — 소문자·하이픈
tags: [multi-agent, langgraph]

# ✅ MOC 분류용 nested tag 예 (Obsidian nested tag 표준)
tags: [moc, types/research-note]
tags: [moc, domains/ai]
```

### 4. `topics` 평문 (wikilink 미사용)

```yaml
# ❌ 잘못된 예 — wikilink 없이 평문
topics: ["LangGraph", "Multi Agent"]

# 이유: schema items 패턴 `^\[\[.+\]\]$` 위반. Obsidian 그래프·백링크 동작 안 함.

# ✅ 올바른 예 — wikilink 형식
topics: ["[[LANGGRAPH]]", "[[MULTI_AGENT]]"]
```

### 5. `aliases` 누락 (High 위반)

```yaml
# ❌ 잘못된 예 — aliases 필드 자체 없음
title: "Agentic Engineering 개론"
# aliases 없음

# 이유: High 등급 위반 → G2_wiki PARTIAL. Obsidian alias 검색 불가.

# ✅ 올바른 예 — 최소 1개 alias
aliases: ["Agentic Engineering", "에이전틱 엔지니어링"]
```

## TYPE별 frontmatter 차이

| TYPE | `type` 값 | `tags` 첫 항목 | `index` 기본값 | 특이사항 |
|---|---|---|---|---|
| RESEARCH_NOTE | `"[[RESEARCH_NOTE]]"` | `research-note` | `"[[AI]]"` | `/pab:wiki` 시 SOURCE와 쌍으로 생성 |
| CONCEPT | `"[[CONCEPT]]"` | `concept` | `"[[AI]]"` | |
| LESSON | `"[[LESSON]]"` | `lesson` | `"[[ENGINEERING]]"` | |
| PROJECT | `"[[PROJECT]]"` | `project` | `"[[PRODUCT]]"` | |
| DAILY | `"[[DAILY]]"` | `daily` | `"[[MISC]]"` | |
| REFERENCE | `"[[REFERENCE]]"` | `reference` | `"[[KNOWLEDGE_MGMT]]"` | |
| SOURCE | `"[[SOURCE]]"` | `source` | (짝 요약본의 index와 동일) | 본문=원문 텍스트, **변경 금지**, sources=외부 URL 1개, `wiki/15_Sources/` 저장 |

> **주의**: `index` 기본값은 템플릿의 placeholder일 뿐. **반드시 작성자가 실제 DOMAIN으로 변경**해야 한다. 모든 노트가 `[[ROOT]]`로 쏠리면 DOMAIN MOC 분류가 무의미해진다.

## DOMAIN MOC 6종

| `index` 값 | 의미 | 대표 주제 |
|---|---|---|
| `[[AI]]` | 머신러닝, LLM, 에이전트 | LangChain, LangGraph, RAG, fine-tuning |
| `[[HARNESS]]` | Claude Code, IDE, CLI 도구 | Claude Code, Obsidian CLI, shell script |
| `[[ENGINEERING]]` | 일반 SW 공학 | 알고리즘, 아키텍처, 디버깅, 성능 |
| `[[PRODUCT]]` | 제품·프로젝트 관리 | 로드맵, PRD, 스프린트, UX |
| `[[KNOWLEDGE_MGMT]]` | 노트 시스템, 학습 방법론 | Zettelkasten, PARA, spaced repetition |
| `[[MISC]]` | 기타 분류 불명 | 임시 노트, 분류 전 |
| `[[ROOT]]` | 최상위 (MOC 전용) | `_INDEX.md`, TYPE/DOMAIN MOC 노트만 |

## 자주 묻는 질문 (FAQ)

**Q1. 시간을 모르면 created를 어떻게 적나요?**
날짜만 적어도 됩니다. `created: 2026-05-01` — 시간 부분은 optional입니다. schema 패턴 `^\d{4}-\d{2}-\d{2}( \d{2}:\d{2})?$`에서 시간은 선택.

**Q2. TOPIC이 아직 없으면 `topics`를 어떻게 하나요?**
`topics: []` 빈 배열로 두어도 됩니다. High 등급이지만 Phase 1-3에서 TOPIC 노트가 생성되기 전에는 빈 배열이 정상입니다. Phase 1-3 이후에는 가능한 채우세요.

**Q3. alias를 여러 개 넣어도 되나요?**
가능합니다. 단, 3~5개 이내를 권장합니다. 너무 많으면 Obsidian 자동완성이 혼잡해집니다.

**Q4. `index`를 `[[ROOT]]`로 두면 안 되나요?**
일반 노트에서는 사용을 피하세요. `[[ROOT]]`는 MOC 노트(TYPES/DOMAINS/TOPICS 계층의 인덱스 노트)만을 위한 값입니다. 일반 노트는 6 DOMAIN 중 하나를 선택하세요.

**Q5. `updated`는 매번 직접 갱신해야 하나요?**
Templater의 `<% tp.date.now("YYYY-MM-DD HH:mm") %>`를 `updated` 값으로 사용하면 템플릿 삽입 시 자동 채워집니다. 이후 수정 시에는 직접 갱신하거나 Templater auto-update 플러그인 활용.

## 검증 방법

### 자동 검증 (Phase 1-4 구현 후)

```bash
# 전체 vault 검증
python3 scripts/wiki/wiki.py link-check --full

# 또는 Makefile 타겟
make wiki-link-check
```

### 수동 검증

```bash
# JSON parse 확인
python3 -c "import json; json.load(open('wiki/40_Templates/_schema.json'))"

# frontmatter 추출 (python-frontmatter 설치 시)
python3 -c "
import frontmatter
note = frontmatter.load('wiki/10_Notes/2026-05-01_example.md')
required = ['title', 'created', 'type']
missing = [f for f in required if f not in note]
print('MISSING:', missing if missing else 'None — OK')
"
```
