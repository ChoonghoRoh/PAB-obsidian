---
task_id: "1-3-1"
title: "TYPES MOC 6종 작성"
domain: WIKI-CONTENT
owner: backend-dev
priority: P0
estimate_min: 25
status: pending
depends_on: []
blocks: ["1-3-4"]
---

# Task 1-3-1 — TYPES MOC 6종 작성

## 목적

`type` frontmatter 필드 기준으로 노트를 자동 수집하는 **TYPES MOC** 6개를 작성한다. Phase 1-2에서 정의된 6 TYPE enum(`RESEARCH_NOTE`/`CONCEPT`/`LESSON`/`PROJECT`/`DAILY`/`REFERENCE`)에 1:1 대응한다.

## 산출물

`wiki/00_MOC/TYPES/` 디렉토리 + 6개 마크다운 파일:

1. `RESEARCH_NOTE.md`
2. `CONCEPT.md`
3. `LESSON.md`
4. `PROJECT.md`
5. `DAILY.md`
6. `REFERENCE.md`

## 표준 구조 (각 MOC 파일 공통)

### Frontmatter 11필드 예시 (RESEARCH_NOTE.md 기준)

```yaml
---
title: "RESEARCH_NOTE — Type MOC"
description: "RESEARCH_NOTE TYPE에 속하는 모든 노트의 자동 수집 MOC. 외부 레퍼런스/논문/실험 노트의 진입점."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[TYPES]]"]
tags: [moc, types/research-note]
keywords: [moc, research-note, type-index]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["RESEARCH_NOTE MOC", "Research Notes Index"]
---
```

### 본문 섹션

1. **# {TYPE} — Type MOC** (H1)
2. **## TYPE 정의** — 해당 TYPE의 의미·작성 시점·예시 (frontmatter-spec와 일관)
3. **## 자동 수집 (dataview)** — dataview 쿼리 블록
4. **## 폴백 정적 링크** — placeholder 섹션 (Phase 1-4 `wiki moc-build`로 자동 채움)
5. **## 작성 가이드** — 본 TYPE 노트 작성 시 권장 템플릿 wikilink (`[[40_Templates/{TYPE}]]`)

### dataview 쿼리 (각 TYPE별 치환)

```dataview
LIST
FROM ""
WHERE type = "[[<TYPE_ENUM>]]"
SORT created DESC
LIMIT 100
```

예: `RESEARCH_NOTE.md`는 `WHERE type = "[[RESEARCH_NOTE]]"`

## 6 TYPE 정의 요약 (각 MOC의 §TYPE 정의 본문에 사용)

| TYPE | 정의 | 예시 |
|---|---|---|
| RESEARCH_NOTE | 외부 자료(논문·블로그·강의) 분석 노트 | "Agentic Engineering 개론" |
| CONCEPT | 개념·이론 정리 | "Karpathy LLM Wiki 개념" |
| LESSON | 본인 경험·실험에서 정제된 교훈 | "Obsidian CLI Setup 시 hookup 절차" |
| PROJECT | 프로젝트 단위 작업 노트 | "PAB Wiki Project" |
| DAILY | 일별 메모·로그 | "2026-05-01 Daily" |
| REFERENCE | 빠른 참조용 (체크리스트·치트시트·MOC) | "PARA Method", 본 MOC 자체 |

## 실행 절차

1. `wiki/00_MOC/TYPES/` 디렉토리 생성
2. 6개 MOC 파일을 위 표준 구조로 작성. `tags` 슬러그 형식 주의: `types/research-note` (소문자 + 하이픈)
3. JSON Schema 패턴 부합 검증:
   ```bash
   python3 -c "
   import re, glob, yaml
   for f in glob.glob('wiki/00_MOC/TYPES/*.md'):
     fm = open(f).read().split('---')[1]
     d = yaml.safe_load(fm)
     assert d['type'] == '[[REFERENCE]]', f
     assert 'moc' in d['tags'], f
     print(f, 'OK')
   "
   ```
4. dataview 쿼리는 본 단계에서 syntax 검토만 수행 (실제 dataview plugin 호출은 Obsidian GUI에서 사용자 확인)

## 완료 기준

- [ ] `wiki/00_MOC/TYPES/` 디렉토리 + 6개 파일 존재
- [ ] 각 파일 frontmatter 11필드 모두 존재 (Critical 3 필수: title/created/type)
- [ ] `type` 필드는 모두 `"[[REFERENCE]]"` (MOC는 REFERENCE TYPE에 귀속)
- [ ] `tags`에 `moc` + `types/{slug}` 포함
- [ ] dataview 쿼리 6개 파일 모두 존재 + 각 파일별 TYPE_ENUM이 파일명과 일치
- [ ] 본문 5섹션(TYPE 정의/dataview/폴백/작성 가이드 포함) 충족

## 보고

`reports/report-backend-dev.md` §T-1 섹션:
- 6개 파일 경로 + 각 파일 줄 수
- frontmatter 검증 결과 (위 python 스니펫 출력)
- dataview 쿼리 정합성 (각 파일의 WHERE 절이 파일명과 일치하는지)
- 발견된 issue (있으면)

## 위험

- MOC가 본인 TYPE에 자기 매칭(`type = "[[REFERENCE]]"` MOC가 REFERENCE.md에 자기 자신 등장)될 수 있음 → 본 task는 정상 동작으로 간주, Phase 1-4 폴백 정적 링크 갱신 시 `WHERE file.path != this.file.path` 추가 가능
