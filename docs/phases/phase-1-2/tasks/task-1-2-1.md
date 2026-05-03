---
task_id: "1-2-1"
title: "Frontmatter JSON Schema 작성"
domain: WIKI-META
owner: backend-dev
priority: P0
estimate_min: 20
status: pending
depends_on: []
blocks: ["1-2-2", "1-2-3"]
---

# Task 1-2-1 — Frontmatter JSON Schema 작성

## 목적

PAB Wiki의 모든 노트가 따라야 할 11필드 frontmatter 표준을 **JSON Schema (Draft 2020-12)** 로 정의한다. Phase 1-4의 `wiki link-check`가 본 schema를 로드하여 검증하고, Phase 1-3 MOC, Phase 1-6 시드 노트도 모두 본 schema를 따른다.

## 산출물

`wiki/40_Templates/_schema.json` (단일 파일)

## 11필드 표준 (master-plan + plan.md 참조)

| # | 필드 | 타입 | 필수 등급 | 패턴/제약 |
|---|---|---|---|---|
| 1 | `title` | string | **필수** (Critical) | `minLength: 1` |
| 2 | `description` | string | High | 자유 |
| 3 | `created` | string (date-time) | **필수** | `^\d{4}-\d{2}-\d{2}( \d{2}:\d{2})?$` |
| 4 | `updated` | string (date-time) | High | 동일 패턴 |
| 5 | `type` | string (wikilink) | **필수** | `^\[\[(RESEARCH_NOTE\|CONCEPT\|LESSON\|PROJECT\|DAILY\|REFERENCE)\]\]$` |
| 6 | `index` | string (wikilink) | High | `^\[\[(AI\|HARNESS\|ENGINEERING\|PRODUCT\|KNOWLEDGE_MGMT\|MISC\|ROOT)\]\]$` |
| 7 | `topics` | array of wikilink | High | `^\[\[.+\]\]$` |
| 8 | `tags` | array of string | High | `^[a-z0-9-]+$` (소문자·숫자·하이픈) |
| 9 | `keywords` | array of string | Low | 자유 |
| 10 | `sources` | array of string | Low | 자유 (URL/도서명) |
| 11 | `aliases` | array of string | High | 자유 |

## 실행 절차

1. `wiki/40_Templates/_schema.json` 생성
2. Draft 2020-12 메타스키마 사용:
   ```json
   {
     "$schema": "https://json-schema.org/draft/2020-12/schema",
     "$id": "https://pab-obsidian.local/schemas/frontmatter.json",
     "title": "PAB Wiki Frontmatter v1",
     "description": "Karpathy-style LLM-친화 wiki 노트의 11필드 frontmatter 표준",
     "type": "object",
     "required": ["title", "created", "type"],
     "additionalProperties": false,
     "properties": { ... 11필드 ... }
   }
   ```
3. 각 properties에 `type`, `description`, `pattern`, `examples` 명시
4. `additionalProperties: false`로 미정의 필드 차단 (단, Templater 변수 처리는 별도 — 변수 미치환 노트는 본 schema 검증 대상이 아님, 치환된 노트만 검증)
5. JSON 유효성 검증:
   ```bash
   python3 -c "import json; json.load(open('wiki/40_Templates/_schema.json'))"
   ```
6. (선택) 자체 sample 객체로 검증:
   ```bash
   python3 -c "
   import json
   from jsonschema import validate
   schema = json.load(open('wiki/40_Templates/_schema.json'))
   sample = {
     'title': 'Test',
     'created': '2026-05-01 22:00',
     'type': '[[CONCEPT]]'
   }
   validate(sample, schema)
   print('VALID')
   "
   ```
   `jsonschema` 패키지가 없으면 위 검증은 skip하고 schema 자체의 JSON parse만 통과시킨다.

## 완료 기준

- [ ] `wiki/40_Templates/_schema.json` 존재
- [ ] `python3 json.load` 통과
- [ ] 11필드 모두 정의됨 (`required` 배열에 3개, properties에 11개)
- [ ] 각 properties에 `description` 존재
- [ ] `type`, `index` enum이 master-plan의 6 TYPE / 7 DOMAIN(ROOT 포함) 일치
- [ ] `tags` 패턴이 소문자·숫자·하이픈만 허용

## 보고

`reports/report-backend-dev.md` §T-1 섹션:
- schema 파일 경로 + 라인 수
- `python3 json.load` 결과
- (선택) jsonschema 검증 결과

## 위험

- Draft 2020-12을 지원하지 않는 환경 → Draft-07도 동작하도록 fallback 명시 (본 task는 2020-12 사용)
- Templater 변수 `<% ... %>` 가 schema 검증 시 패턴 위반 → **본 schema는 변수 치환 후 노트를 검증**. 템플릿 자체는 검증 대상 아님 (sample 노트로 검증)
