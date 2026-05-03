---
task_id: "1-3-2"
title: "DOMAINS MOC 6종 작성"
domain: WIKI-CONTENT
owner: backend-dev
priority: P0
estimate_min: 25
status: pending
depends_on: []
blocks: ["1-3-4"]
---

# Task 1-3-2 — DOMAINS MOC 6종 작성

## 목적

`index` frontmatter 필드 기준으로 노트를 자동 수집하는 **DOMAINS MOC** 6개를 작성한다. Phase 1-2 schema의 7 DOMAIN enum 중 `ROOT`는 `_INDEX.md` 자체이므로 본 Phase에서는 `AI`/`HARNESS`/`ENGINEERING`/`PRODUCT`/`KNOWLEDGE_MGMT`/`MISC` 6개를 작성한다.

본 task 완료 시 Phase 1-2의 unresolved `[[AI]]`/`[[HARNESS]]` 등 wikilink가 자동 해소된다.

## 산출물

`wiki/00_MOC/DOMAINS/` 디렉토리 + 6개 마크다운 파일:

1. `AI.md`
2. `HARNESS.md`
3. `ENGINEERING.md`
4. `PRODUCT.md`
5. `KNOWLEDGE_MGMT.md`
6. `MISC.md`

## 표준 구조 (각 MOC 파일 공통)

### Frontmatter 11필드 예시 (AI.md 기준)

```yaml
---
title: "AI — Domain MOC"
description: "AI 도메인(LLM·에이전트·NLP·CV·논문) 노트 자동 수집 MOC. type 무관, index가 [[AI]]인 모든 노트."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[DOMAINS]]"]
tags: [moc, domains/ai]
keywords: [moc, ai, llm, agent]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["AI MOC", "AI Domain Index"]
---
```

### 본문 섹션

1. **# {DOMAIN} — Domain MOC** (H1)
2. **## DOMAIN 정의** — 해당 도메인의 의미·범위·포함되는 주제
3. **## 자동 수집 (dataview)** — dataview 쿼리
4. **## 폴백 정적 링크** — placeholder
5. **## 인접 도메인** — 관련 DOMAIN MOC wikilink (예: AI → ENGINEERING/HARNESS)

### dataview 쿼리

```dataview
LIST
FROM ""
WHERE index = "[[<DOMAIN_ENUM>]]"
SORT created DESC
LIMIT 100
```

## 6 DOMAIN 정의 (각 MOC §DOMAIN 정의 본문에 사용)

| DOMAIN | 정의 | 포함 주제 예시 |
|---|---|---|
| AI | 인공지능 일반 — LLM, agent, NLP, CV, 논문 | LangGraph, Claude, GPT, multi-agent, prompting |
| HARNESS | 개발 환경·도구 체인 — CLI, IDE, Obsidian | claude-code, obsidian-cli, hooks, MCP |
| ENGINEERING | 일반 엔지니어링 — 알고리즘·언어·아키텍처 | Python, TypeScript, system design, algorithm |
| PRODUCT | 제품·프로젝트 단위 작업 | PAB Wiki, side project |
| KNOWLEDGE_MGMT | 지식 관리 방법론 | PARA, Zettelkasten, Karpathy wiki, second brain |
| MISC | 미분류 (위 5개에 속하지 않음) | 일반 메모, 개인 로그 |

## 실행 절차

1. `wiki/00_MOC/DOMAINS/` 디렉토리 생성
2. 6개 MOC 파일을 위 표준 구조로 작성. `tags` 슬러그 형식: `domains/ai`, `domains/harness`, `domains/engineering`, `domains/product`, `domains/knowledge-mgmt`, `domains/misc`
3. **인접 도메인** 섹션에 다른 DOMAIN MOC wikilink 1~3개 (모든 MOC가 도달 가능하도록 cross-link)
4. 검증 스니펫:
   ```bash
   python3 -c "
   import yaml, glob
   for f in sorted(glob.glob('wiki/00_MOC/DOMAINS/*.md')):
     fm = open(f).read().split('---')[1]
     d = yaml.safe_load(fm)
     assert d['type'] == '[[REFERENCE]]'
     assert d['index'] == '[[ROOT]]'
     assert 'moc' in d['tags']
     assert any(t.startswith('domains/') for t in d['tags'])
     print(f, 'OK')
   "
   ```

## 완료 기준

- [ ] `wiki/00_MOC/DOMAINS/` 디렉토리 + 6개 파일 존재
- [ ] 각 파일 frontmatter 11필드 모두 존재 (Critical 3 필수)
- [ ] `type: "[[REFERENCE]]"`, `index: "[[ROOT]]"`
- [ ] `tags`에 `moc` + `domains/{slug}` 포함
- [ ] dataview 쿼리 6개 파일 모두 존재 + WHERE 절이 파일명과 일치
- [ ] 인접 도메인 cross-link 존재 (각 파일 1개 이상)
- [ ] `[[AI]]`, `[[HARNESS]]`, `[[ENGINEERING]]`, `[[PRODUCT]]`, `[[KNOWLEDGE_MGMT]]`, `[[MISC]]` 모두 resolve 가능

## 보고

`reports/report-backend-dev.md` §T-2 섹션:
- 6개 파일 경로 + 줄 수
- frontmatter 검증 출력
- Phase 1-2 unresolved wikilink 해소 검증: 어떤 link가 어떤 MOC로 해소되는지 표
