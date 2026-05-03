# Phase 1-3 Backend-Dev Report

- **작성**: backend-dev
- **일자**: 2026-05-01
- **범위**: Phase 1-3 T-1 ~ T-5 전 task
- **상태**: 5/5 completed

## §T-1 TYPES MOC 6종

### 산출물

| # | 파일 | 라인 수 | dataview WHERE | type |
|---|---|---:|---|---|
| 1 | `wiki/00_MOC/TYPES/RESEARCH_NOTE.md` | 50 | `type = "[[RESEARCH_NOTE]]"` | `[[REFERENCE]]` |
| 2 | `wiki/00_MOC/TYPES/CONCEPT.md` | 50 | `type = "[[CONCEPT]]"` | `[[REFERENCE]]` |
| 3 | `wiki/00_MOC/TYPES/LESSON.md` | 50 | `type = "[[LESSON]]"` | `[[REFERENCE]]` |
| 4 | `wiki/00_MOC/TYPES/PROJECT.md` | 50 | `type = "[[PROJECT]]"` | `[[REFERENCE]]` |
| 5 | `wiki/00_MOC/TYPES/DAILY.md` | 49 | `type = "[[DAILY]]"` | `[[REFERENCE]]` |
| 6 | `wiki/00_MOC/TYPES/REFERENCE.md` | 52 | `type = "[[REFERENCE]]"` | `[[REFERENCE]]` |

### Frontmatter 검증 (task spec snippet)

```
wiki/00_MOC/TYPES/CONCEPT.md       OK  (WHERE=CONCEPT)
wiki/00_MOC/TYPES/DAILY.md         OK  (WHERE=DAILY)
wiki/00_MOC/TYPES/LESSON.md        OK  (WHERE=LESSON)
wiki/00_MOC/TYPES/PROJECT.md       OK  (WHERE=PROJECT)
wiki/00_MOC/TYPES/REFERENCE.md     OK  (WHERE=REFERENCE)
wiki/00_MOC/TYPES/RESEARCH_NOTE.md OK  (WHERE=RESEARCH_NOTE)
```

- 11필드 frontmatter 전부 존재 (Critical 3: title/created/type 모두 OK)
- 6개 모두 `type: "[[REFERENCE]]"` (MOC는 REFERENCE TYPE에 자기 귀속)
- 6개 모두 `tags`에 `moc` + `types/<slug>` 포함
- dataview WHERE 절의 TYPE_ENUM이 파일명과 일치 (6/6)

### 본문 5섹션 충족

각 MOC 파일은 다음 섹션을 모두 포함: `# {TYPE} — Type MOC` (H1) / `## TYPE 정의` / `## 자동 수집 (dataview)` / `## 폴백 정적 링크` / `## 작성 가이드`

### 발견 issue

1. **schema vs spec tag pattern 불일치 (★ 후속 결정 필요)**: 본 task spec은 `tags: [moc, types/research-note]`처럼 `/`를 포함한 슬러그를 의무화하지만, `wiki/40_Templates/_schema.json`의 `tags` 패턴은 `^[a-z0-9-]+$`로 `/` 미허용. `jsonschema.validate` 실행 시 12건 모두 WARN. spec snippet(yaml.safe_load + 멤버십 체크)은 통과하지만, Phase 1-4 `wiki link-check` 구현이 jsonschema를 사용할 경우 G2_wiki FAIL 가능. → Phase 1-4 진입 전 (a) schema의 tag pattern을 `^[a-z0-9-]+(/[a-z0-9-]+)*$`로 확장 또는 (b) MOC tag 형식을 `moc-types-research-note`로 변경 결정 필요.
2. REFERENCE.md의 dataview는 자기 자신 포함 가능. task spec의 위험 섹션에 명시된 대로 Phase 1-4에서 `WHERE file.path != this.file.path` 추가 권고.

---

## §T-2 DOMAINS MOC 6종

### 산출물

| # | 파일 | 라인 수 | dataview WHERE | 인접 도메인 |
|---|---|---:|---|---|
| 1 | `wiki/00_MOC/DOMAINS/AI.md` | 43 | `index = "[[AI]]"` | HARNESS, ENGINEERING, KNOWLEDGE_MGMT |
| 2 | `wiki/00_MOC/DOMAINS/HARNESS.md` | 43 | `index = "[[HARNESS]]"` | AI, ENGINEERING, KNOWLEDGE_MGMT |
| 3 | `wiki/00_MOC/DOMAINS/ENGINEERING.md` | 43 | `index = "[[ENGINEERING]]"` | AI, HARNESS, PRODUCT |
| 4 | `wiki/00_MOC/DOMAINS/PRODUCT.md` | 43 | `index = "[[PRODUCT]]"` | ENGINEERING, KNOWLEDGE_MGMT, AI |
| 5 | `wiki/00_MOC/DOMAINS/KNOWLEDGE_MGMT.md` | 43 | `index = "[[KNOWLEDGE_MGMT]]"` | HARNESS, AI, PRODUCT |
| 6 | `wiki/00_MOC/DOMAINS/MISC.md` | 45 | `index = "[[MISC]]"` | KNOWLEDGE_MGMT, PRODUCT, AI |

### Frontmatter 검증

```
wiki/00_MOC/DOMAINS/AI.md             OK  (WHERE=AI)
wiki/00_MOC/DOMAINS/ENGINEERING.md    OK  (WHERE=ENGINEERING)
wiki/00_MOC/DOMAINS/HARNESS.md        OK  (WHERE=HARNESS)
wiki/00_MOC/DOMAINS/KNOWLEDGE_MGMT.md OK  (WHERE=KNOWLEDGE_MGMT)
wiki/00_MOC/DOMAINS/MISC.md           OK  (WHERE=MISC)
wiki/00_MOC/DOMAINS/PRODUCT.md        OK  (WHERE=PRODUCT)
```

- 11필드 모두 존재 (Critical 3 OK)
- 6개 모두 `type: "[[REFERENCE]]"`, `index: "[[ROOT]]"`
- 6개 모두 `tags`에 `moc` + `domains/<slug>` 포함
- WHERE 절 DOMAIN_ENUM이 파일명과 일치 (6/6)
- 인접 도메인 cross-link 1개 이상 (모든 DOMAIN MOC가 cross-link로 도달 가능 — closure 검증 OK)

### Phase 1-2 unresolved wikilink 자동 해소

| Phase 1-2의 unresolved wikilink | 해소되는 MOC |
|---|---|
| `[[AI]]` | `wiki/00_MOC/DOMAINS/AI.md` |
| `[[HARNESS]]` | `wiki/00_MOC/DOMAINS/HARNESS.md` |
| `[[ENGINEERING]]` | `wiki/00_MOC/DOMAINS/ENGINEERING.md` |
| `[[PRODUCT]]` | `wiki/00_MOC/DOMAINS/PRODUCT.md` |
| `[[KNOWLEDGE_MGMT]]` | `wiki/00_MOC/DOMAINS/KNOWLEDGE_MGMT.md` |
| `[[MISC]]` | `wiki/00_MOC/DOMAINS/MISC.md` |
| `[[ROOT]]` | `wiki/_INDEX.md` (Phase 1-1, 본 task 외) |

→ Phase 1-2의 6개 unresolved DOMAIN wikilink 모두 1:1 해소.

---

## §T-3 TOPICS placeholder

### 산출물

- **파일**: `wiki/00_MOC/TOPICS/_README.md`
- **라인 수**: 71

### Frontmatter 검증

```
wiki/00_MOC/TOPICS/_README.md  OK
```

- 11필드 모두 존재 (Critical 3 OK)
- `type: "[[REFERENCE]]"`, `tags`에 `moc, topics, placeholder` 포함

### 6섹션 본문 충족

`개념` / `자동 승격 규칙` / `명명 규약` / `dataview 템플릿 스니펫` / `현재 등록된 TOPICS` (placeholder 표 1행) — H2 섹션 포함, dataview 템플릿 2종(단일 TOPIC + TOPIC×TYPE) 모두 포함.

### 승격 규칙 요약 (1줄)

`topics: ["[[FOO]]"]`로 등록된 노트가 **3건 이상** 누적되면 `wiki/00_MOC/TOPICS/FOO.md` MOC를 Phase 1-4 `wiki moc-build`가 자동 생성하며, 임계치는 `--topic-threshold N`로 조정 가능.

---

## §T-4 _INDEX.md 갱신 (3중 인덱스)

### 갱신 전후 diff 요약

| 항목 | 갱신 전 | 갱신 후 |
|---|---|---|
| `By Type` 섹션 | 1줄 placeholder | dataview 블록 + 폴백 wikilink 6개 |
| `By Domain` 섹션 | 1줄 placeholder | dataview 블록 + 폴백 wikilink 6개 |
| `By Topic` 섹션 | 1줄 placeholder | dataview 블록 + `_README` 링크 + placeholder 1행 |
| frontmatter `updated` | `2026-05-01 00:00` | `2026-05-01 22:30` |
| 사용 가이드 | 4줄 | 5줄 (TOPIC 등록 가이드 1줄 추가) |
| 메타 푸터 | "갱신 예정: Phase 1-3" | "**갱신 완료**: Phase 1-3 ..." |
| 전체 라인 수 | 53 | 99 |

### 폴백 wikilink 13개 (전수)

**By Type (6)**
- `[[00_MOC/TYPES/RESEARCH_NOTE|RESEARCH_NOTE]]`
- `[[00_MOC/TYPES/CONCEPT|CONCEPT]]`
- `[[00_MOC/TYPES/LESSON|LESSON]]`
- `[[00_MOC/TYPES/PROJECT|PROJECT]]`
- `[[00_MOC/TYPES/DAILY|DAILY]]`
- `[[00_MOC/TYPES/REFERENCE|REFERENCE]]`

**By Domain (6)**
- `[[00_MOC/DOMAINS/AI|AI]]`
- `[[00_MOC/DOMAINS/HARNESS|HARNESS]]`
- `[[00_MOC/DOMAINS/ENGINEERING|ENGINEERING]]`
- `[[00_MOC/DOMAINS/PRODUCT|PRODUCT]]`
- `[[00_MOC/DOMAINS/KNOWLEDGE_MGMT|KNOWLEDGE_MGMT]]`
- `[[00_MOC/DOMAINS/MISC|MISC]]`

**By Topic (1)**
- `[[00_MOC/TOPICS/_README|TOPICS — Rules]]`

### Broken link 점검

```
resolve: ok=13 missing=[]
```

13개 wikilink 모두 실제 파일 존재 검증 완료. broken link 없음.

### 검증 출력

```
frontmatter parse OK; updated = 2026-05-01 22:30
dataview code blocks: 3
00_MOC wikilinks count: 13
placeholder remnants -> 0
```

→ 3 placeholder 모두 실 내용으로 치환됨. dataview 코드블록 3개. T-1/T-2/T-3 결과물과 cross-link 정합성 OK (`_INDEX.md` → 13 MOC, 13 MOC의 `index: "[[ROOT]]"` ↔ `_INDEX.md`).

---

## §T-5 TOC 추천 알고리즘 명세

### 산출물

- **파일**: `wiki/30_Constraints/toc-recommendation.md`
- **라인 수**: 227

### Frontmatter 검증

```
wiki/30_Constraints/toc-recommendation.md  OK
```

- 11필드 모두 존재 (Critical 3 OK)
- `type: "[[REFERENCE]]"`, `tags`에 `toc, algorithm, constraints` 포함

### 8섹션 본문 충족

`목적` / `입력` / `출력` / `알고리즘 단계` (Step 1~5) / `의사코드` (Python 1블록, 5단계 모두 반영) / `적용 예시` (Before/After 1건 + JSON) / `Phase 1-4 T-5 인터페이스` (입출력 JSON 스키마) / `위험 및 결정 보류` — 모두 포함.

### 알고리즘 5단계 요약 (1줄)

마크다운 노트를 파싱(Step 1) → heading depth 평탄/깊이 분류(Step 2) → 섹션 길이 임계치(80라인) 기반 split/merge 권고(Step 3) → 선택적 LLM 의미 유사도 보강(Step 4) → markdown/JSON 출력 변환(Step 5).

### 인터페이스

Phase 1-4 T-5가 직접 참조 가능한 입출력 JSON 스키마 명시. `note_path` / `max_depth` / `use_llm` / `length_threshold` 입력, `flatness` / `max_depth_seen` / `suggestions[]` 출력. CLI 사용 예 3건 포함.

---

## 종합 검증 (Phase 1-3 G2_wiki 사전 점검)

| 검증 항목 | 결과 |
|---|---|
| 신규 파일 14건 (TYPES 6 + DOMAINS 6 + TOPICS 1 + toc spec 1) | 14/14 생성 |
| `_INDEX.md` 갱신 | OK (placeholder 0건 잔존) |
| 11필드 frontmatter Critical 3 (title/created/type) | 14/14 OK |
| 11필드 전수 (모든 키 존재) | 14/14 OK |
| dataview WHERE 절 ↔ 파일명 일치 (TYPES 6 + DOMAINS 6) | 12/12 OK |
| `_INDEX.md` 13 wikilink resolve | 13/13 OK |
| jsonschema strict validation | 2/14 PASS, 12 WARN (★ tag pattern issue, T-1 §발견 issue 참조) |

### 후속 조치 권고 (Team Lead 결정 필요)

1. **schema tag pattern 확장 vs MOC tag 재명명**: 위 jsonschema 12 WARN은 task spec과 schema 간 정책 충돌. Phase 1-4 진입 전 결정. → **2026-05-01 사용자 옵션 (a) 채택, T-6에서 해소 (아래 §T-6 참조)**
2. Phase 1-4 `wiki moc-build` 구현 시 본 보고서의 폴백 placeholder 14개를 자동 채움 대상으로 등록.
3. Phase 1-4 `wiki toc-suggest` 구현 시 §T-5 인터페이스 계약 그대로 채택.

---

## §T-6 Schema Strict 정렬 (옵션 a)

### 사용자 결정

2026-05-01 — 옵션 (a) 채택: `_schema.json`을 확장하여 nested tag 및 INDEX type을 정식 지원. 옵션 (b)(MOC tag flat 변환)는 기각.

### 변경된 파일 + 라인 위치

| # | 파일 | 위치 | 변경 내용 |
|---|---|---|---|
| 1 | `wiki/40_Templates/_schema.json` | line 35 (`type.pattern`) | enum에 `INDEX` 추가 → `^\[\[(...|REFERENCE|INDEX)\]\]$` |
| 2 | `wiki/40_Templates/_schema.json` | line 36 (`type.description`) | 6 TYPE → 7 TYPE, INDEX 전용 설명 추가 |
| 3 | `wiki/40_Templates/_schema.json` | line 37 (`type.examples`) | `"[[INDEX]]"` 추가 |
| 4 | `wiki/40_Templates/_schema.json` | line 59 (`tags.items.pattern` + description) | `^[a-z0-9-]+(/[a-z0-9-]+)*$` — nested tag 허용 |
| 5 | `wiki/40_Templates/_schema.json` | line 62~63 (`tags.description` + `tags.examples`) | nested tag(`types/research-note`) 사용 명시 + examples 추가 |
| 6 | `wiki/30_Constraints/frontmatter-spec.md` | §11필드 표 §5 type 행 | "6 TYPE" → "7 TYPE (`[[INDEX]]`는 wiki/_INDEX.md 1건 전용)" |
| 7 | `wiki/30_Constraints/frontmatter-spec.md` | §11필드 표 §8 tags 행 | nested 허용 패턴 명시 + `[moc, types/research-note]` 예 추가 |
| 8 | `wiki/30_Constraints/frontmatter-spec.md` | §필드 등급 §Critical type 항목 | 7 TYPE wikilink 허용값 재기재 |
| 9 | `wiki/30_Constraints/frontmatter-spec.md` | §잘못된 vs 올바른 §3 tags | 패턴 표기 갱신 + nested tag 올바른 예 2건 추가 |
| 10 | `wiki/30_Constraints/linking-policy.md` | — | type enum/tag pattern 명시 부재 → 변경 없음 (skip 확인) |

### JSON parse 결과

```
JSON OK
type pattern: ^\[\[(RESEARCH_NOTE|CONCEPT|LESSON|PROJECT|DAILY|REFERENCE|INDEX)\]\]$
tags items pattern: ^[a-z0-9-]+(/[a-z0-9-]+)*$
```

### jsonschema strict 검증 (15 파일)

```
wiki/00_MOC/TYPES/CONCEPT.md            OK
wiki/00_MOC/TYPES/DAILY.md              OK
wiki/00_MOC/TYPES/LESSON.md             OK
wiki/00_MOC/TYPES/PROJECT.md            OK
wiki/00_MOC/TYPES/REFERENCE.md          OK
wiki/00_MOC/TYPES/RESEARCH_NOTE.md      OK
wiki/00_MOC/DOMAINS/AI.md               OK
wiki/00_MOC/DOMAINS/ENGINEERING.md      OK
wiki/00_MOC/DOMAINS/HARNESS.md          OK
wiki/00_MOC/DOMAINS/KNOWLEDGE_MGMT.md   OK
wiki/00_MOC/DOMAINS/MISC.md             OK
wiki/00_MOC/DOMAINS/PRODUCT.md          OK
wiki/00_MOC/TOPICS/_README.md           OK
wiki/_INDEX.md                          OK
wiki/30_Constraints/toc-recommendation.md OK

15/15 PASS
```

### 13 WARN → 0 해소 확인

| 원본 WARN 그룹 | 건 수 | 원인 | T-6 해소 방법 |
|---|---:|---|---|
| TYPES MOC `tags[1] = types/X` | 6 | tag pattern `^[a-z0-9-]+$`에 `/` 없음 | tag pattern을 `^[a-z0-9-]+(/[a-z0-9-]+)*$`로 확장 |
| DOMAINS MOC `tags[1] = domains/Y` | 6 | 동일 | 동일 |
| `_INDEX.md` `type = "[[INDEX]]"` | 1 | type enum에 INDEX 부재 | type enum에 INDEX 추가 |
| **합계** | **13** | — | **0 WARN, 15/15 PASS** |

### 산출물 무결성 (T-1~T-5 미수정 확인)

T-6은 `_schema.json` + `frontmatter-spec.md` 메타 변경만 수행. T-1~T-5에서 생성된 13개 wiki MOC 파일과 `_INDEX.md`(T-4 산출물)의 frontmatter·본문은 일체 미수정. 변경 없이 strict 검증 PASS 확보.
