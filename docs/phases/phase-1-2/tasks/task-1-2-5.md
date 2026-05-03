---
task_id: "1-2-5"
title: "링크 정책 (linking-policy.md)"
domain: WIKI-META
owner: backend-dev
priority: P1
estimate_min: 20
status: pending
depends_on: []
blocks: []
---

# Task 1-2-5 — `wiki/30_Constraints/linking-policy.md`

## 목적

PAB Wiki의 wikilink 작성 정책을 정의한다. 상향(노트→MOC) / 하향(MOC→노트) / 횡적(노트↔노트) / alias 활용 4종 + 외부 링크 규칙을 명시하여 Karpathy-style "강한 링크 + 짧은 노트" 원칙을 구현한다.

## 산출물

`wiki/30_Constraints/linking-policy.md` (단일 파일)

## 문서 frontmatter (자기참조)

```yaml
---
title: "Linking Policy"
description: "PAB Wiki 링크 작성 정책 — 상향/하향/횡적/alias 4종 + external link"
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[CONSTRAINTS]]"]
tags: [reference, linking, wikilink, constraints]
keywords: [link, wikilink, alias, backlink, moc]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["Linking Policy", "Wikilink Rules", "Link Spec"]
---
```

## 본문 필수 섹션

### `## 4종 링크 분류`

| 종류 | 방향 | 위치 | 예시 |
|---|---|---|---|
| **상향 (Upward)** | 노트 → MOC | frontmatter `index:` 필드 + 본문 `## Related` | `index: "[[AI]]"` |
| **하향 (Downward)** | MOC → 노트 | MOC 본문의 노트 목록 | `- [[2026-05-01_topic]]` |
| **횡적 (Lateral)** | 노트 ↔ 노트 | 본문 + frontmatter `topics:` | `[[2026-04-21_agentic_engineering]]`, `topics: ["[[LANGGRAPH]]"]` |
| **alias 활용** | 별칭 → 정식 | 본문 자유 표현 | `[[LangGraph|랭그래프]]` |

### `## 상향 링크 (Upward)`

**목적**: 노트가 어느 MOC 계층에 속하는지 명시.

**규칙**:
- 모든 노트는 `index:` 필드에 1개 DOMAIN MOC wikilink 필수
- DOMAIN: `[[AI]]` / `[[HARNESS]]` / `[[ENGINEERING]]` / `[[PRODUCT]]` / `[[KNOWLEDGE_MGMT]]` / `[[MISC]]`
- MOC 노트만 `[[ROOT]]` 사용
- 본문에 추가로 `## Related` 또는 인라인 wikilink로 MOC 참조 가능 (선택)

**예시**:
```yaml
index: "[[AI]]"          # 메인 DOMAIN
topics: ["[[LANGGRAPH]]", "[[MULTI_AGENT]]"]  # TOPIC (보조 분류)
```

### `## 하향 링크 (Downward)`

**목적**: MOC가 자신에 속한 노트를 나열.

**규칙**:
- TYPE MOC (`wiki/00_MOC/TYPES/RESEARCH_NOTE.md`)은 모든 RESEARCH_NOTE 타입 노트를 나열
- DOMAIN MOC (`wiki/00_MOC/DOMAINS/AI.md`)는 `index: "[[AI]]"` 인 모든 노트 나열
- 자동화: Phase 1-4 `wiki moc-build` 명령이 frontmatter 파싱해서 자동 갱신
- 수동 작성도 허용 (자동화 전 단계)
- dataview plugin 사용 시 동적 쿼리 가능 (폴백으로 정적 wikilink도 항상 작성)

**예시 (`AI.md` 일부)**:
```markdown
## RESEARCH_NOTE
- [[2026-04-21_agentic_engineering]]
- [[2026-05-01_chain_of_thought]]
```

### `## 횡적 링크 (Lateral)`

**목적**: 노트 간 의미적 연결 — Karpathy의 "강한 링크" 핵심.

**규칙**:
- 본문에서 자유롭게 `[[다른_노트_파일명]]` 또는 `[[다른_노트_파일명|표시명]]` 사용
- frontmatter `topics:` 배열로 TOPIC 노트 wikilink (TOPIC 노트는 Phase 1-3에서 동적 생성)
- TOPIC은 UPPER_SNAKE_CASE (`[[LANGGRAPH]]`, `[[MULTI_AGENT]]`)
- 노트 1건당 1~5개 횡적 링크 권장 (너무 많으면 의미 희석)

**예시 (본문)**:
```markdown
이 노트는 [[2026-04-21_agentic_engineering]]의 후속이다.
[[LANGGRAPH]] 토픽도 함께 참고하라.
```

### `## alias 활용`

**목적**: 한 노트를 여러 표현으로 호출 (한글·약어·동의어).

**규칙**:
- 노트 frontmatter `aliases:` 배열에 별칭 명시
- 본문에서 `[[정식파일명|표시명]]` 또는 `[[표시명]]` (Obsidian이 alias 자동 매칭)
- alias는 1~5개 권장
- 한글 alias 권장 (LLM이 한글 본문에서 자연스럽게 링크 가능)

**예시**:
```yaml
# 2026-04-21_agentic_engineering.md
aliases: ["Agentic Engineering", "에이전틱 엔지니어링", "Agent-driven dev"]
```

본문에서:
```markdown
오늘 [[에이전틱 엔지니어링]] 강의를 봤다.
```

### `## 외부 링크 (External Link)`

**규칙**:
- frontmatter `sources:` 배열에 URL 명시 (정적 출처)
- 본문에서 `[표시명](URL)` 마크다운 링크 사용 (인라인 출처)
- wikilink와 명확히 구분 (wikilink는 내부 노트만)

**예시**:
```yaml
sources: ["https://www.youtube.com/watch?v=...", "https://arxiv.org/abs/..."]
```

본문:
```markdown
[Karpathy의 LLM 강의](https://www.youtube.com/watch?v=...)에서 영감.
```

### `## broken link 방지`

- Phase 1-4 `wiki link-check` (또는 `obsidian unresolved`)이 자동 검출
- G2_wiki Critical: broken link 1건 이상 → FAIL
- 노트 작성 시 wikilink 직후 Obsidian autocomplete가 정확한지 확인 권장

### `## 잘못된/올바른 예시 5건`

1. ❌ `index: "AI"` (평문) → ✅ `index: "[[AI]]"`
2. ❌ `topics: ["LangGraph"]` → ✅ `topics: ["[[LANGGRAPH]]"]`
3. ❌ 본문에 `https://arxiv.org/...` 만 적기 → ✅ `[제목](https://arxiv.org/...)` + `sources:` 등록
4. ❌ alias 없이 한글로 본문에서 노트 호출 → ✅ `aliases: ["한글명"]` 등록 후 `[[한글명]]`
5. ❌ MOC 본문이 비어있음 (하향 링크 없음) → ✅ TYPE/DOMAIN별 노트 wikilink 나열 (또는 dataview 쿼리)

### `## 검증 방법`

- 자동: `wiki link-check` (Phase 1-4) — broken `[[wikilink]]` 검출
- 수동: `obsidian unresolved` CLI 명령

## 완료 기준

- [ ] 파일 존재
- [ ] 자체 frontmatter 11필드 포함
- [ ] 4종 링크 분류 + 외부 링크
- [ ] 각 종류별 규칙 + 예시
- [ ] 잘못된/올바른 예시 5건
- [ ] broken link 정책

## 보고

`reports/report-backend-dev.md` §T-5 섹션:
- 파일 경로 + 라인 수
- 4종 링크 표 캡처

## 위험

- alias 한글 처리 시 인코딩 문제 가능 → UTF-8 강제 (Obsidian 기본)
- TOPIC 노트가 아직 없으므로(`[[LANGGRAPH]]` 등) Phase 1-3 전까지는 unresolved 상태 — 정상, Phase 1-3에서 placeholder 생성으로 해소
