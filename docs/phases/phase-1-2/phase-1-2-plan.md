---
phase: "1-2"
type: plan
created: 2026-05-01
master_plan_ref: docs/phases/phase-1-master-plan.md
---

# Phase 1-2 Plan — Frontmatter 스키마 + Templater 템플릿

## 목표

Karpathy-style LLM-친화 wiki의 **메타데이터 표준**을 확립한다. 11필드 frontmatter JSON Schema를 정의하고, TYPE별 6종 템플릿을 작성하며, 노트 작성 시 일관성을 강제하는 3종 constraints 문서(frontmatter-spec / naming-convention / linking-policy)를 정비한다. 이후 Phase 1-3(MOC) 및 Phase 1-6(시드 노트)이 본 산출물을 의존한다.

## 11필드 Frontmatter 표준 (master-plan + Phase 1-1 `_INDEX.md` 검증 패턴)

| # | 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|---|
| 1 | `title` | string | ✅ | 노트 제목 (사람이 읽는 형태, 한글 가능) |
| 2 | `description` | string | High | 1~2줄 요약 (LLM 검색·prefetch용) |
| 3 | `created` | datetime | ✅ | `YYYY-MM-DD HH:MM` |
| 4 | `updated` | datetime | ✅ | 노트 수정 시 갱신 |
| 5 | `type` | wikilink | ✅ | `[[RESEARCH_NOTE]]` / `[[CONCEPT]]` / `[[LESSON]]` / `[[PROJECT]]` / `[[DAILY]]` / `[[REFERENCE]]` 중 1 |
| 6 | `index` | wikilink | ✅ | DOMAIN MOC 링크 (`[[AI]]` / `[[HARNESS]]` / `[[ENGINEERING]]` / `[[PRODUCT]]` / `[[KNOWLEDGE_MGMT]]` / `[[MISC]]` / `[[ROOT]]`) |
| 7 | `topics` | wikilink[] | High | TOPIC 노트 wikilink 배열 (예: `["[[LANGGRAPH]]", "[[MULTI_AGENT]]"]`) |
| 8 | `tags` | string[] | High | 태그 배열 (Obsidian tag pane 검색용, 소문자·하이픈) |
| 9 | `keywords` | string[] | Low | 자유 키워드 (대소문자·공백 허용, LLM/검색 보강) |
| 10 | `sources` | string[] | Low | 외부 출처(URL/논문·도서명) 배열 — 외부 참조 없으면 빈 배열 |
| 11 | `aliases` | string[] | High | Obsidian 별칭 (대문자·약어·동의어) |

**필수 필드** (Critical 검증): `title`, `created`, `type` 누락 시 G2_wiki FAIL
**High 필드**: `description`, `topics`/`tags` 빈 배열 시 PARTIAL
**Low 필드**: `keywords`, `sources` 빈 배열 허용 (PASS)

## 완료 기준 (Definition of Done)

| # | 기준 | 검증 방법 |
|---|---|---|
| DoD-1 | `wiki/40_Templates/_schema.json` 존재 + JSON valid | `python3 -c "import json; json.load(open(...))"` |
| DoD-2 | JSON Schema가 Draft 2020-12 또는 Draft-07 표준 준수 | `jsonschema` 검증 또는 verifier 수동 |
| DoD-3 | 6 템플릿 모두 `wiki/40_Templates/{TYPE}.md` 형태로 존재 | ls |
| DoD-4 | 6 템플릿 frontmatter 모두 11필드 100% 포함 (Templater 변수 OK) | verifier 수동 |
| DoD-5 | 6 템플릿 본문에 TYPE별 권장 섹션 헤더 포함 | grep `^##` |
| DoD-6 | `wiki/30_Constraints/frontmatter-spec.md` 존재 + 11필드 모두 설명 + 예시 1+ | Read |
| DoD-7 | `wiki/30_Constraints/naming-convention.md` 존재 + `YYYY-MM-DD_topic.md` 패턴 + slug 규칙 | Read |
| DoD-8 | `wiki/30_Constraints/linking-policy.md` 존재 + 상향/하향/횡적/alias 4종 정의 | Read |
| DoD-9 | 3 constraints 문서 자체도 11필드 frontmatter 포함 (자기참조) | verifier |
| DoD-10 | 모든 wikilink가 정합 (broken link 0) | `obsidian unresolved` 또는 수동 |

## 접근 방식

### 1. Schema 우선 작성 (T-1)

JSON Schema를 먼저 작성하여 이후 템플릿·constraints의 단일 진실 공급원으로 삼는다. 11필드 + alias 처리(`aliases` 배열) + 검증 규칙(필수/타입/패턴) 포함.

```jsonc
// wiki/40_Templates/_schema.json (개요)
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://pab-obsidian.local/schemas/frontmatter.json",
  "title": "PAB Wiki Frontmatter v1",
  "type": "object",
  "required": ["title", "created", "type"],
  "properties": {
    "title": { "type": "string", "minLength": 1 },
    "description": { "type": "string" },
    "created": { "type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}( \\d{2}:\\d{2})?$" },
    "updated": { "type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}( \\d{2}:\\d{2})?$" },
    "type": { "type": "string", "pattern": "^\\[\\[(RESEARCH_NOTE|CONCEPT|LESSON|PROJECT|DAILY|REFERENCE)\\]\\]$" },
    "index": { "type": "string", "pattern": "^\\[\\[(AI|HARNESS|ENGINEERING|PRODUCT|KNOWLEDGE_MGMT|MISC|ROOT)\\]\\]$" },
    "topics": { "type": "array", "items": { "type": "string", "pattern": "^\\[\\[.+\\]\\]$" } },
    "tags": { "type": "array", "items": { "type": "string", "pattern": "^[a-z0-9-]+$" } },
    "keywords": { "type": "array", "items": { "type": "string" } },
    "sources": { "type": "array", "items": { "type": "string" } },
    "aliases": { "type": "array", "items": { "type": "string" } }
  }
}
```

### 2. TYPE별 6 템플릿 (T-2)

각 템플릿은 Templater 친화적 변수(`<% tp.date.now("YYYY-MM-DD HH:mm") %>`, `<% tp.file.title %>`)와 정적 frontmatter를 결합. 본문은 TYPE별 권장 섹션 헤더만 제공 (LLM이 채울 placeholder).

| TYPE | 본문 권장 섹션 |
|---|---|
| RESEARCH_NOTE | `## Question`, `## Findings`, `## Sources`, `## Next` |
| CONCEPT | `## Definition`, `## Why it matters`, `## Examples`, `## Related` |
| LESSON | `## Context`, `## What I learned`, `## Mistakes`, `## Apply next time` |
| PROJECT | `## Goal`, `## Status`, `## Tasks`, `## Decisions`, `## Risks` |
| DAILY | `## Log`, `## Done`, `## TODO`, `## Reflection` |
| REFERENCE | `## Source`, `## Summary`, `## Quotes`, `## My take` |

### 3. 3종 Constraints (T-3 ~ T-5)

`wiki/30_Constraints/`는 사용자(또는 LLM)가 노트 직접 작성 시 참조하는 규약 문서. 각 문서 자체도 11필드 frontmatter를 포함하여 self-referential validity를 확보한다.

- **frontmatter-spec.md** — 11필드 표 + 필수/High/Low 등급 + 5개 잘못된 예시 vs 5개 올바른 예시
- **naming-convention.md** — `YYYY-MM-DD_topic.md` 패턴 / slug 규칙(snake_case, 영문, 50자 이하) / TYPE별 prefix 부재 명시 / 첨부 파일 명명
- **linking-policy.md** — 상향(`index:`, MOC 링크) / 하향(MOC → 노트) / 횡적(`topics:`, 본문 wikilink) / alias 활용 / external link 정책

## 작업 순서 (의존성)

```
T-1 (JSON Schema)
   ↓
T-2 (6 템플릿) ─┐
T-3 (frontmatter-spec) ─┤ (병렬 가능)
T-4 (naming-convention) ─┤
T-5 (linking-policy) ─┘
```

T-1 완료 후 T-2~T-5 병렬 가능. 단, T-3은 T-1 schema를 직접 참조하므로 T-1 완료 필수. T-4/T-5는 schema 의존성 적음.

## 위험 + 완화

| # | 위험 | 완화 |
|---|---|---|
| R-1 | Templater 변수가 frontmatter parsing 실패 | 변수는 본문·`title:`·`created:` 등 string 필드에만 사용. Schema 검증은 변수 미치환 raw 형태와 치환 후 형태 모두 통과해야 함 — 검증 시 `<% ... %>` 패턴 허용 또는 별도 sample 노트로 검증 |
| R-2 | JSON Schema 표준 버전 충돌 | Draft 2020-12 사용 (최신, jsonschema 4.18+ 지원). 폴백으로 Draft-07도 명시 |
| R-3 | 11필드 중 `index` vs `type` wikilink 형태가 혼동 | `type`은 TYPE 6종 wikilink, `index`는 DOMAIN 6종 wikilink — schema에 enum 정확히 명시 |
| R-4 | 사용자가 직접 노트 작성 시 frontmatter 누락 | Phase 1-4 `wiki link-check`에서 검증. 본 Phase에서는 spec 문서로 가이드만 제공 |
| R-5 | 템플릿 본문이 너무 prescriptive 하면 LLM 자유도 저하 | 권장 섹션만 제공, 본문은 1줄 placeholder로 채워 사용자가 자유롭게 변경 |

## 산출물

### `wiki/40_Templates/`
- `_schema.json` — JSON Schema 본체
- `RESEARCH_NOTE.md`
- `CONCEPT.md`
- `LESSON.md`
- `PROJECT.md`
- `DAILY.md`
- `REFERENCE.md`

### `wiki/30_Constraints/`
- `frontmatter-spec.md`
- `naming-convention.md`
- `linking-policy.md`

### `docs/phases/phase-1-2/reports/`
- `report-backend-dev.md` (작업 보고)
- `report-verifier.md` (G2_wiki 검증 보고)

## 검증 게이트

- **G2_wiki**:
  - **Critical (FAIL)**: JSON Schema 파싱 실패 / 6 템플릿 중 1개라도 11필드 누락 / 파일명·디렉터리 위치 위반 / 3 constraints 자체 frontmatter 누락
  - **High (PARTIAL)**: 템플릿 본문 권장 섹션 누락 / constraints에 예시 부족 / cross-link(`linking-policy ↔ frontmatter-spec`) 끊김
  - **Low (PASS 가능)**: `report-*.md` 누락 / `description` 필드 짧음
- **G3 (E-4 비적용)**: 본 sub-phase 비검증
- **G4**: G2_wiki PASS 시 자동 PASS

## 다음 Phase 연결 (Phase 1-3 의존성)

본 Phase 1-2의 산출물은 Phase 1-3 (MOC 시스템)에서 다음과 같이 활용된다:
- `_schema.json` — Phase 1-3 MOC 노트도 11필드 frontmatter 준수
- `RESEARCH_NOTE.md` 등 6 TYPE 템플릿 — Phase 1-3에서 `wiki/00_MOC/TYPES/` 6 MOC 노트 작성 시 참조
- `frontmatter-spec.md` — Phase 1-6 시드 노트 작성 시 사용자 가이드
