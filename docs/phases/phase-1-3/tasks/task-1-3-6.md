---
task_id: "1-3-6"
title: "Schema Strict 정렬 — tag pattern 확장 + INDEX type enum 추가"
domain: WIKI-META
owner: backend-dev
priority: P0
estimate_min: 10
status: pending
depends_on: ["1-3-1", "1-3-2", "1-3-3", "1-3-4", "1-3-5"]
blocks: []
---

# Task 1-3-6 — Schema Strict 정렬

## 목적

T-1~T-5 산출물은 task spec 기준 G2_wiki PASS이지만, `wiki/40_Templates/_schema.json`을 jsonschema strict로 검증 시 13건 WARN이 발생한다. 본 task는 옵션 (a) — schema 확장으로 13 WARN을 모두 해소하여 Phase 1-4 `wiki link-check` 구현 시 strict 검증을 통과하도록 한다.

## 사용자 결정 (2026-05-01)

- **옵션 (a)**: schema 확장 — `_schema.json` tag pattern을 `^[a-z0-9-]+(/[a-z0-9-]+)*$`로 확장 + type enum에 `INDEX` 추가
- 옵션 (b): MOC tag flat 변환 → 기각 (Obsidian nested tag 표준 활용 포기)

## 산출물

1. `wiki/40_Templates/_schema.json` (수정 — 2 properties)
2. `wiki/30_Constraints/frontmatter-spec.md` (수정 — tag/type 섹션 동기화)
3. `wiki/30_Constraints/linking-policy.md` (수정 — INDEX 언급 시 동기화)

## 변경 명세 (정확한 diff)

### `_schema.json` line 35 — type pattern

```diff
- "pattern": "^\\[\\[(RESEARCH_NOTE|CONCEPT|LESSON|PROJECT|DAILY|REFERENCE)\\]\\]$",
+ "pattern": "^\\[\\[(RESEARCH_NOTE|CONCEPT|LESSON|PROJECT|DAILY|REFERENCE|INDEX)\\]\\]$",
```

### `_schema.json` line 36 — type description

```diff
- "description": "노트 TYPE — 6종 중 1개 wikilink. Critical 필드. 허용값: [[RESEARCH_NOTE]] / [[CONCEPT]] / [[LESSON]] / [[PROJECT]] / [[DAILY]] / [[REFERENCE]]",
+ "description": "노트 TYPE — 7종 중 1개 wikilink. Critical 필드. 허용값: [[RESEARCH_NOTE]] / [[CONCEPT]] / [[LESSON]] / [[PROJECT]] / [[DAILY]] / [[REFERENCE]] / [[INDEX]] ([[INDEX]]는 wiki/_INDEX.md 1건 전용)",
```

### `_schema.json` line 37 — type examples

```diff
- "examples": ["[[RESEARCH_NOTE]]", "[[CONCEPT]]", "[[LESSON]]", "[[PROJECT]]", "[[DAILY]]", "[[REFERENCE]]"]
+ "examples": ["[[RESEARCH_NOTE]]", "[[CONCEPT]]", "[[LESSON]]", "[[PROJECT]]", "[[DAILY]]", "[[REFERENCE]]", "[[INDEX]]"]
```

### `_schema.json` line 59 — tags items pattern

```diff
- "pattern": "^[a-z0-9-]+$",
- "description": "소문자·숫자·하이픈만 허용하는 태그."
+ "pattern": "^[a-z0-9-]+(/[a-z0-9-]+)*$",
+ "description": "소문자·숫자·하이픈 허용. nested tag(`a/b/c`)도 허용 — Obsidian nested tag 표준 정합. 각 segment는 `^[a-z0-9-]+$`."
```

### `_schema.json` line 62~63 — tags description / examples

```diff
- "description": "Obsidian tag pane 검색용 태그 배열. 첫 항목은 TYPE 소문자·하이픈 형태 권장. High 필드.",
- "examples": [["research-note", "langgraph", "multi-agent"], ["concept", "llm"]]
+ "description": "Obsidian tag pane 검색용 태그 배열. 첫 항목은 TYPE 소문자·하이픈 형태 권장. nested tag(`types/research-note`, `domains/ai`)는 MOC 분류 시 사용 가능. High 필드.",
+ "examples": [["research-note", "langgraph", "multi-agent"], ["moc", "types/research-note"], ["moc", "domains/ai"]]
```

### `frontmatter-spec.md` 동기화

다음 두 항목을 갱신:

1. **§11필드 표 §5 type 행** — 6 TYPE → 7 TYPE (INDEX 추가, MOC root index 전용 명시)
2. **§11필드 표 §8 tags 행** — pattern 설명에 nested tag 허용 명시 (`^[a-z0-9-]+(/[a-z0-9-]+)*$`)
3. **§필드 등급 §Critical type 항목** — 7 TYPE wikilink 허용값 재기재
4. **§예시 섹션** — MOC frontmatter 예시 1개 추가 (nested tag 사용)

기존 텍스트 검색 후 정확히 부합하는 줄을 Edit한다.

### `linking-policy.md` 동기화 (영향 있을 시만)

- 본 파일에 `type` enum 또는 tag pattern이 명시되어 있으면 동기화. 없으면 변경 없음 (확인만).

## 실행 절차

1. **변경 1**: Edit으로 `_schema.json` 5개 위치 수정 (위 diff 그대로 적용)
2. **변경 2**: `frontmatter-spec.md` 4개 항목 동기화
3. **변경 3**: `linking-policy.md` 검색 → type enum/tag pattern 언급 있으면 동기화, 없으면 skip
4. **검증 1 — JSON 파싱**:
   ```bash
   python3 -c "import json; json.load(open('wiki/40_Templates/_schema.json')); print('JSON OK')"
   ```
5. **검증 2 — jsonschema strict (선택)**:
   ```bash
   python3 << 'EOF'
   import json, glob, yaml
   try:
       from jsonschema import validate, ValidationError
   except ImportError:
       print("jsonschema not installed; skipping strict check")
       exit(0)

   schema = json.load(open('wiki/40_Templates/_schema.json'))
   files = (
       glob.glob('wiki/00_MOC/TYPES/*.md') +
       glob.glob('wiki/00_MOC/DOMAINS/*.md') +
       ['wiki/00_MOC/TOPICS/_README.md',
        'wiki/_INDEX.md',
        'wiki/30_Constraints/toc-recommendation.md']
   )
   passed = failed = 0
   for f in sorted(files):
       fm = open(f).read().split('---')[1]
       data = yaml.safe_load(fm)
       try:
           validate(data, schema)
           passed += 1
           print(f, "OK")
       except ValidationError as e:
           failed += 1
           print(f, "FAIL:", e.message)
   print(f"\n{passed}/{passed+failed} PASS")
   EOF
   ```
   - 14개 파일 (TYPES 6 + DOMAINS 6 + TOPICS 1 + _INDEX 1 + toc-recommendation 1) 모두 PASS 기대
6. **보고**: `reports/report-backend-dev.md` §T-6 섹션 추가 (라인 수 + 검증 결과 + 13 WARN → 0 해소 확인)

## 완료 기준

- [ ] `_schema.json` 5개 위치 수정 완료
- [ ] `frontmatter-spec.md` 4개 항목 동기화 완료
- [ ] `linking-policy.md` 동기화 (필요 시)
- [ ] JSON parse 통과
- [ ] jsonschema strict 검증 14/14 PASS (jsonschema 미설치 시 manual diff 확인)
- [ ] 보고서 §T-6 추가

## 보고

`reports/report-backend-dev.md` §T-6 섹션:
- 변경된 파일 + 라인 위치 표
- JSON parse 결과
- jsonschema strict 검증 결과 (또는 fallback manual diff)
- 13 WARN → 0 해소 확인 표

## 위험

- frontmatter-spec.md 동기화 시 기존 줄과 정확히 일치하는 텍스트 검색 필요. Edit 실패 시 Read로 정확한 텍스트 확인 후 재시도.
- linking-policy.md에 영향 없으면 skip 가능 — 없는 줄을 수정하려 하면 Edit 실패하므로 사전 grep으로 확인 권고.
