---
phase: "1-2"
role: backend-dev
type: report
created: 2026-05-01
---

# Phase 1-2 Backend-Dev 작업 보고서

## 요약

| Task | 산출물 | 라인 수 | 상태 |
|---|---|---|---|
| T-1 | `wiki/40_Templates/_schema.json` | 93 | ✅ DONE |
| T-2 | `wiki/40_Templates/{RESEARCH_NOTE,CONCEPT,LESSON,PROJECT,DAILY,REFERENCE}.md` | 27/27/27/30/27/27 | ✅ DONE |
| T-3 | `wiki/30_Constraints/frontmatter-spec.md` | 196 | ✅ DONE |
| T-4 | `wiki/30_Constraints/naming-convention.md` | 164 | ✅ DONE |
| T-5 | `wiki/30_Constraints/linking-policy.md` | 257 | ✅ DONE |

---

## §T-1 Frontmatter JSON Schema

**산출물**: `wiki/40_Templates/_schema.json` (93줄)

### 검증 결과

```
python3 -c "import json; json.load(open('wiki/40_Templates/_schema.json'))"
→ JSON PARSE: OK (에러 없음)
```

### Schema 구조 확인

| 항목 | 값 |
|---|---|
| `$schema` | `https://json-schema.org/draft/2020-12/schema` |
| `$id` | `https://pab-obsidian.local/schemas/frontmatter.json` |
| `title` | `"PAB Wiki Frontmatter v1"` |
| `type` | `"object"` |
| `required` | `["title", "created", "type"]` (3개) |
| `additionalProperties` | `false` |
| `properties` 수 | 11개 |

### 11필드 properties

| # | 필드 | 타입 | 패턴/제약 |
|---|---|---|---|
| 1 | `title` | string | minLength: 1 |
| 2 | `description` | string | 자유 |
| 3 | `created` | string | `^\d{4}-\d{2}-\d{2}( \d{2}:\d{2})?$` |
| 4 | `updated` | string | `^\d{4}-\d{2}-\d{2}( \d{2}:\d{2})?$` |
| 5 | `type` | string | `^\[\[(RESEARCH_NOTE|CONCEPT|LESSON|PROJECT|DAILY|REFERENCE)\]\]$` |
| 6 | `index` | string | `^\[\[(AI|HARNESS|ENGINEERING|PRODUCT|KNOWLEDGE_MGMT|MISC|ROOT)\]\]$` |
| 7 | `topics` | array | items: `^\[\[.+\]\]$` |
| 8 | `tags` | array | items: `^[a-z0-9-]+$` |
| 9 | `keywords` | array | items: 자유 string |
| 10 | `sources` | array | items: 자유 string |
| 11 | `aliases` | array | items: 자유 string |

### DoD 체크

- [x] DoD-1: 파일 존재 + JSON valid
- [x] DoD-2: Draft 2020-12 표준 준수
- [x] required 배열 3개 (title, created, type)
- [x] 각 properties에 description 존재
- [x] type enum 6종 정확
- [x] index enum 7종 (ROOT 포함) 정확
- [x] tags pattern 소문자·숫자·하이픈만

**비고**: `jsonschema` 패키지 미설치 환경 — `json.load()` PASS (DoD-1 충족). jsonschema 검증은 Skip.

---

## §T-2 TYPE별 6 템플릿

**산출물**: `wiki/40_Templates/` 하위 6개 파일

### 파일 목록 + 라인 수

| 파일 | 라인 수 | `type` 값 | `tags` 첫 항목 | `index` 기본값 |
|---|---|---|---|---|
| `RESEARCH_NOTE.md` | 27 | `"[[RESEARCH_NOTE]]"` | `research-note` | `"[[AI]]"` |
| `CONCEPT.md` | 27 | `"[[CONCEPT]]"` | `concept` | `"[[AI]]"` |
| `LESSON.md` | 27 | `"[[LESSON]]"` | `lesson` | `"[[ENGINEERING]]"` |
| `PROJECT.md` | 30 | `"[[PROJECT]]"` | `project` | `"[[PRODUCT]]"` |
| `DAILY.md` | 27 | `"[[DAILY]]"` | `daily` | `"[[MISC]]"` |
| `REFERENCE.md` | 27 | `"[[REFERENCE]]"` | `reference` | `"[[KNOWLEDGE_MGMT]]"` |

### 11필드 frontmatter 검증

```
6개 파일 모두: fields: 11 → ALL 11 FIELDS: OK
```

### Templater 변수 확인

- `title: "<% tp.file.title %>"` — 전체 6개 파일 ✅
- `created: <% tp.date.now("YYYY-MM-DD HH:mm") %>` — 전체 6개 파일 ✅
- `updated: <% tp.date.now("YYYY-MM-DD HH:mm") %>` — 전체 6개 파일 ✅
- `# <% tp.file.title %>` (본문 H1) — 전체 6개 파일 ✅

### 권장 섹션 헤더 grep 결과

```
CONCEPT.md: ## Definition / ## Why it matters / ## Examples / ## Related (4개)
DAILY.md: ## Log / ## Done / ## TODO / ## Reflection (4개)
LESSON.md: ## Context / ## What I learned / ## Mistakes / ## Apply next time (4개)
PROJECT.md: ## Goal / ## Status / ## Tasks / ## Decisions / ## Risks (5개)
REFERENCE.md: ## Source / ## Summary / ## Quotes / ## My take (4개)
RESEARCH_NOTE.md: ## Question / ## Findings / ## Sources / ## Next (4개)
```

### DoD 체크

- [x] DoD-3: 6 파일 모두 존재
- [x] DoD-4: 6 파일 모두 11필드 100%
- [x] DoD-5: TYPE별 권장 섹션 헤더 포함

---

## §T-3 frontmatter-spec.md

**산출물**: `wiki/30_Constraints/frontmatter-spec.md` (196줄)

### 자체 frontmatter 검증

```
fields: 11 → ALL 11 FIELDS: OK
type: "[[REFERENCE]]" ✅
index: "[[ROOT]]" ✅
topics: ["[[CONSTRAINTS]]"] ✅
```

### 본문 섹션 확인

| 섹션 | 포함 여부 |
|---|---|
| `## 개요` | ✅ |
| `## 11필드 표` | ✅ (11행 표) |
| `## 필드 등급` (Critical/High/Low) | ✅ |
| `## 잘못된/올바른 예시` | ✅ (5건: type평문/created형식/tags대문자/topics평문/aliases누락) |
| `## TYPE별 frontmatter 차이` | ✅ (6 TYPE 표) |
| `## DOMAIN MOC 6종` | ✅ (AI/HARNESS/ENGINEERING/PRODUCT/KNOWLEDGE_MGMT/MISC/ROOT) |
| `## FAQ` | ✅ (5건 Q&A) |
| `## 검증 방법` | ✅ |

### DoD 체크

- [x] DoD-6: 파일 존재 + 11필드 설명 + 예시 포함
- [x] DoD-9: 자체 frontmatter 11필드

---

## §T-4 naming-convention.md

**산출물**: `wiki/30_Constraints/naming-convention.md` (164줄)

### 자체 frontmatter 검증

```
fields: 11 → ALL 11 FIELDS: OK
type: "[[REFERENCE]]" ✅
index: "[[ROOT]]" ✅
```

### 본문 섹션 확인

| 섹션 | 포함 여부 |
|---|---|
| `## 노트 파일명 표준` (`YYYY-MM-DD_slug.md` 패턴) | ✅ |
| `## slug 규칙` (허용/금지, 50자 이하) | ✅ |
| 검증 정규식 `^\d{4}-\d{2}-\d{2}_[a-z0-9_]{1,50}\.md$` | ✅ |
| `## 폴더 prefix 규칙` (00_~99_, _ 시스템) | ✅ |
| `## 첨부 파일 명명` (`YYYY-MM-DD_slug_kind.ext`) | ✅ |
| `## MOC 파일명 규칙` (Phase 1-3 대비 대문자 패턴) | ✅ |
| `## 잘못된/올바른 예시` | ✅ (5건) |
| `## 검증 방법` (정규식 + bash find) | ✅ |

### DoD 체크

- [x] DoD-7: 파일 존재 + `YYYY-MM-DD_topic.md` 패턴 + slug 규칙
- [x] DoD-9: 자체 frontmatter 11필드

---

## §T-5 linking-policy.md

**산출물**: `wiki/30_Constraints/linking-policy.md` (257줄)

### 자체 frontmatter 검증

```
fields: 11 → ALL 11 FIELDS: OK
type: "[[REFERENCE]]" ✅
index: "[[ROOT]]" ✅
sources: ["wiki/30_Constraints/frontmatter-spec.md"] ✅ (cross-link)
```

### 본문 섹션 확인

| 섹션 | 포함 여부 |
|---|---|
| `## 4종 링크 분류` (표) | ✅ |
| `## 상향 링크` (노트→MOC, index 필드 규칙) | ✅ |
| `## 하향 링크` (MOC→노트, moc-build 자동화 언급) | ✅ |
| `## 횡적 링크` (본문 인라인 + topics 배열) | ✅ |
| `## alias 활용` (한글 alias 포함) | ✅ |
| `## 외부 링크` (sources 배열 + 마크다운 링크) | ✅ |
| `## broken link 방지` (G2_wiki Critical 기준) | ✅ |
| `## 잘못된/올바른 예시` | ✅ (5건) |
| `## 검증 방법` | ✅ |

### DoD 체크

- [x] DoD-8: 파일 존재 + 상향/하향/횡적/alias 4종 정의
- [x] DoD-9: 자체 frontmatter 11필드

---

## 종합 DoD 체크리스트

| DoD | 기준 | 결과 |
|---|---|---|
| DoD-1 | `_schema.json` 존재 + JSON valid | ✅ PASS |
| DoD-2 | JSON Schema Draft 2020-12 준수 | ✅ PASS |
| DoD-3 | 6 템플릿 파일 모두 존재 | ✅ PASS |
| DoD-4 | 6 템플릿 frontmatter 11필드 100% | ✅ PASS |
| DoD-5 | 6 템플릿 TYPE별 권장 섹션 헤더 포함 | ✅ PASS |
| DoD-6 | `frontmatter-spec.md` 존재 + 11필드 설명 + 예시 1+ | ✅ PASS |
| DoD-7 | `naming-convention.md` 존재 + 패턴 + slug 규칙 | ✅ PASS |
| DoD-8 | `linking-policy.md` 존재 + 4종 정의 | ✅ PASS |
| DoD-9 | 3 constraints 자체 frontmatter 11필드 | ✅ PASS |
| DoD-10 | broken link 0건 (TOPIC은 Phase 1-3 후 해소) | ⚠️ PARTIAL — `[[CONSTRAINTS]]` `[[LANGGRAPH]]` 등 TOPIC unresolved (Phase 1-3 이전 정상) |

**DoD-10 판정**: Critical 아님. `[[CONSTRAINTS]]` 등 TOPIC 노트는 Phase 1-3에서 생성 예정. `phase-1-2-plan.md`에서 "TOPIC 노트는 아직 없으므로 Phase 1-3 후 해소되는 것이 정상"으로 명시됨.

## G2_wiki 자체 판정

- Critical 위반: **0건**
- High 위반: **0건** (description 있음, topics 빈 배열은 템플릿 placeholder로 의도적)
- Low 위반: 0건

**G2_wiki: PASS** (Critical 0 / High 0)

---

작성: backend-dev | 일시: 2026-05-01 | Phase 1-2 모든 산출물 완료
