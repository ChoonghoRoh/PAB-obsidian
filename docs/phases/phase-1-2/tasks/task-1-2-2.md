---
task_id: "1-2-2"
title: "TYPE별 6 템플릿 작성"
domain: WIKI-META
owner: backend-dev
priority: P0
estimate_min: 30
status: pending
depends_on: ["1-2-1"]
blocks: []
---

# Task 1-2-2 — TYPE별 6 템플릿 작성

## 목적

`wiki/40_Templates/` 하위에 TYPE별 6 템플릿(.md)을 작성한다. 각 템플릿은 11필드 frontmatter + Templater 변수(`<% tp.date.now(...) %>`, `<% tp.file.title %>`)를 결합하고, TYPE별 권장 본문 섹션을 제공한다.

## 산출물

- `wiki/40_Templates/RESEARCH_NOTE.md`
- `wiki/40_Templates/CONCEPT.md`
- `wiki/40_Templates/LESSON.md`
- `wiki/40_Templates/PROJECT.md`
- `wiki/40_Templates/DAILY.md`
- `wiki/40_Templates/REFERENCE.md`

## 공통 frontmatter 패턴 (예시: RESEARCH_NOTE.md)

```yaml
---
title: "<% tp.file.title %>"
description: ""
created: <% tp.date.now("YYYY-MM-DD HH:mm") %>
updated: <% tp.date.now("YYYY-MM-DD HH:mm") %>
type: "[[RESEARCH_NOTE]]"
index: "[[AI]]"           # 작성자가 선택: AI/HARNESS/ENGINEERING/PRODUCT/KNOWLEDGE_MGMT/MISC
topics: []                 # 예: ["[[LANGGRAPH]]", "[[MULTI_AGENT]]"]
tags: [research-note]
keywords: []
sources: []
aliases: []
---
```

> 주의: `type`은 TYPE별로 고정(`[[RESEARCH_NOTE]]` / `[[CONCEPT]]` / `[[LESSON]]` / `[[PROJECT]]` / `[[DAILY]]` / `[[REFERENCE]]`).
> `index`는 작성자가 채워야 하므로 placeholder(`[[AI]]` 등) 또는 `[[ROOT]]` 기본값.
> `tags` 첫 항목은 TYPE 자체(`research-note`, `concept`, `lesson`, `project`, `daily`, `reference`)로 디폴트.

## TYPE별 본문 권장 섹션

### RESEARCH_NOTE.md
```markdown
# <% tp.file.title %>

## Question
<!-- 무엇을 알아내려 하는가? -->

## Findings
<!-- 핵심 발견 -->

## Sources
<!-- 외부 출처 (frontmatter `sources`와 별개로 본문 인용) -->

## Next
<!-- 후속 질문 / 다음 노트 -->
```

### CONCEPT.md
```markdown
# <% tp.file.title %>

## Definition
<!-- 한 문단 정의 -->

## Why it matters
<!-- 왜 중요한가, 어디에 쓰이는가 -->

## Examples
<!-- 구체 예시 1~3개 -->

## Related
<!-- [[관련 CONCEPT]] [[연관 LESSON]] -->
```

### LESSON.md
```markdown
# <% tp.file.title %>

## Context
<!-- 어떤 상황에서 발생 -->

## What I learned
<!-- 핵심 교훈 -->

## Mistakes
<!-- 무엇을 잘못 가정했는가 -->

## Apply next time
<!-- 다음에 어떻게 적용 -->
```

### PROJECT.md
```markdown
# <% tp.file.title %>

## Goal
<!-- 프로젝트의 한 줄 목표 -->

## Status
<!-- 현재 상태 (active / paused / done) -->

## Tasks
- [ ] ...

## Decisions
<!-- 주요 의사결정 (날짜 + 결정 + 근거) -->

## Risks
<!-- 알려진 리스크 -->
```

### DAILY.md
```markdown
# <% tp.file.title %>

## Log
<!-- 시간순 기록 -->

## Done
- [x] ...

## TODO
- [ ] ...

## Reflection
<!-- 하루 회고 1~2줄 -->
```

### REFERENCE.md
```markdown
# <% tp.file.title %>

## Source
<!-- 출처 1줄 (저자/제목/URL) -->

## Summary
<!-- 핵심 요약 -->

## Quotes
<!-- 인용구 (페이지/타임스탬프 포함) -->

## My take
<!-- 내 해석·반응 -->
```

## 실행 절차

1. 6개 파일을 `wiki/40_Templates/` 하위에 생성
2. 각 파일에 위 frontmatter + 본문 권장 섹션 작성
3. Templater 변수 형태가 정확한지 확인 (`<% tp.date.now("YYYY-MM-DD HH:mm") %>`, `<% tp.file.title %>`)
4. 각 파일 첫 줄이 `---` 시작, frontmatter 종료가 `---`로 닫힘 확인
5. `tags` 첫 항목 = TYPE의 소문자·하이픈 형태 (`research-note` 등) 6종 차이 확인

## 완료 기준

- [ ] 6 파일 모두 존재 (`ls wiki/40_Templates/*.md`)
- [ ] 6 파일 모두 11필드 frontmatter 포함
- [ ] `type` 필드가 TYPE별로 정확 (RESEARCH_NOTE.md → `[[RESEARCH_NOTE]]`)
- [ ] 각 파일에 권장 섹션 헤더(`## ...`) 4~5개 존재
- [ ] Templater 변수 형식이 `<% ... %>` 패턴
- [ ] schema 검증: 각 템플릿의 frontmatter를 변수 치환 형태로 sample 객체화 시 schema 통과 (verifier 단계에서 실시)

## 보고

`reports/report-backend-dev.md` §T-2 섹션:
- 6 파일 경로 + 라인 수
- 각 파일의 `type` 필드 값 캡처
- 권장 섹션 헤더 grep 결과

## 위험

- Templater 미설치 환경에서는 변수가 그대로 보임 — 정상 (Phase 1-1 T-3에서 templates 코어 플러그인만 활성화, Templater는 사용자가 추후 설치)
- `topics: []` 빈 배열은 G2_wiki에서 High 등급 — 본 템플릿은 의도적으로 빈 배열 (작성자가 채울 placeholder)
