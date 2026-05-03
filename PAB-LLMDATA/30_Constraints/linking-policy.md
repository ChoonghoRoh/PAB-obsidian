---
title: "Linking Policy"
description: "PAB Wiki 링크 작성 정책 — 상향/하향/횡적/alias 4종 + external link + broken link 방지"
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

# Linking Policy

## 개요

PAB Wiki는 Karpathy-style "**강한 링크 + 짧은 노트**" 원칙을 따른다. 모든 노트는 최소 1개의 상향 링크(DOMAIN MOC)를 가져야 하며, 관련 노트 간 횡적 링크를 풍부하게 작성한다. 이를 통해 Obsidian 그래프 뷰가 유의미한 지식 지도를 형성한다.

## 4종 링크 분류

| 종류 | 방향 | 위치 | 예시 |
|---|---|---|---|
| **상향 (Upward)** | 노트 → MOC | frontmatter `index:` 필드 | `index: "[[AI]]"` |
| **하향 (Downward)** | MOC → 노트 | MOC 본문의 노트 목록 | `- [[2026-05-01_topic]]` |
| **횡적 (Lateral)** | 노트 ↔ 노트 | 본문 인라인 + `topics:` 배열 | `[[2026-04-21_agentic_engineering]]` |
| **alias 활용** | 별칭 → 정식 | 본문 자유 표현 | `[[에이전틱 엔지니어링]]` |

## 상향 링크 (Upward)

**목적**: 노트가 어느 DOMAIN MOC 계층에 속하는지 명시.

**규칙**:
- 모든 노트는 `index:` 필드에 **1개 DOMAIN MOC wikilink** 필수
- 허용 DOMAIN: `[[AI]]` / `[[HARNESS]]` / `[[ENGINEERING]]` / `[[PRODUCT]]` / `[[KNOWLEDGE_MGMT]]` / `[[MISC]]`
- **`[[ROOT]]`는 MOC 노트 전용** (일반 노트에서 사용 금지)
- 본문에 `## Related` 섹션으로 추가 MOC 참조 가능 (선택)

**예시 frontmatter**:

```yaml
index: "[[AI]]"                               # 메인 DOMAIN
topics: ["[[LANGGRAPH]]", "[[MULTI_AGENT]]"]  # TOPIC (보조 분류)
```

**MOC 링크가 없으면**: `wiki moc-build` 자동화(Phase 1-4)가 해당 노트를 DOMAIN MOC에 포함시키지 못함 → 고아 노트(orphan) 처리됨.

## 하향 링크 (Downward)

**목적**: MOC가 자신에 속한 노트를 나열하여 "지도" 역할 수행.

**규칙**:
- **TYPE MOC** (`wiki/00_MOC/TYPES/RESEARCH_NOTE.md`) — `type: "[[RESEARCH_NOTE]]"` 인 모든 노트 나열
- **DOMAIN MOC** (`wiki/00_MOC/DOMAINS/AI.md`) — `index: "[[AI]]"` 인 모든 노트 나열
- **자동화**: Phase 1-4 `wiki moc-build`가 frontmatter 파싱 후 자동 갱신
- **수동 작성**: 자동화 전에도 정적 wikilink로 직접 나열 가능
- **dataview**: plugin 설치 시 동적 쿼리 사용 가능 (단, 정적 wikilink도 항상 폴백으로 유지)

**예시 (`AI.md` 일부)**:

```markdown
## RESEARCH_NOTE
- [[2026-04-21_agentic_engineering]]
- [[2026-05-01_chain_of_thought]]

## CONCEPT
- [[2026-05-01_llm_basics]]
```

## 횡적 링크 (Lateral)

**목적**: 노트 간 의미적 연결 — Karpathy의 "강한 링크" 핵심.

**규칙**:
- 본문에서 자유롭게 `[[파일명]]` 또는 `[[파일명|표시명]]` 사용
- frontmatter `topics:` 배열로 TOPIC 노트 wikilink (UPPER_SNAKE_CASE)
- **TOPIC 파일명 규칙**: `LANGGRAPH.md`, `MULTI_AGENT.md` 등 대문자 (Phase 1-3에서 생성)
- **노트 1건당 1~5개 횡적 링크 권장** — 너무 많으면 의미 희석
- 일반 노트 파일명 wikilink: `[[2026-04-21_agentic_engineering]]`

**예시 (본문 인라인)**:

```markdown
이 노트는 [[2026-04-21_agentic_engineering]]의 후속 연구다.
[[LANGGRAPH]] 프레임워크를 사용하는 구체적인 패턴을 정리한다.
```

**frontmatter topics 예시**:

```yaml
topics: ["[[LANGGRAPH]]", "[[MULTI_AGENT]]", "[[TOOL_CALLING]]"]
```

## alias 활용

**목적**: 한 노트를 여러 표현으로 호출 — 한글·약어·동의어 지원.

**규칙**:
- 노트 frontmatter `aliases:` 배열에 별칭 등록
- 본문에서 `[[표시명]]` 또는 `[[정식파일명|표시명]]` 사용
- Obsidian이 `aliases:`를 보고 자동으로 wikilink 매칭
- **alias 수 권장**: 1~5개 (한글명 1개 + 약어 1~2개)
- 한글 alias 적극 권장 — LLM이 한국어 본문에서 자연스럽게 링크 가능

**frontmatter 예시**:

```yaml
# 2026-04-21_agentic_engineering.md
aliases: ["Agentic Engineering", "에이전틱 엔지니어링", "Agent-driven dev"]
```

**본문에서 호출**:

```markdown
오늘 [[에이전틱 엔지니어링]] 강의를 봤다.
[[Agentic Engineering|에이전틱 엔지니어링]]도 동일하게 동작한다.
```

## 외부 링크 (External Link)

**목적**: 내부 wikilink와 외부 URL을 명확히 구분하여 broken link 방지.

**규칙**:
- frontmatter `sources:` 배열에 URL 정적 등록
- 본문에서는 `[표시명](URL)` 마크다운 링크 사용
- `[[URL]]` 형식의 wikilink로 외부 URL 사용 금지 (broken link 처리됨)

**frontmatter 예시**:

```yaml
sources:
  - "https://www.youtube.com/watch?v=..."
  - "https://arxiv.org/abs/2401.12345"
  - "Attention Is All You Need (Vaswani et al., 2017)"
```

**본문 인용 예시**:

```markdown
[Karpathy의 LLM 강의](https://www.youtube.com/watch?v=...)에서 영감을 받았다.
[원논문](https://arxiv.org/abs/2401.12345)의 §3을 참고하라.
```

## broken link 방지

**G2_wiki Critical 조건**: broken `[[wikilink]]` 1건 이상 → FAIL

**broken link 발생 원인**:
1. 존재하지 않는 파일명으로 wikilink (`[[없는_노트]]`)
2. 파일 삭제·이름 변경 후 wikilink 미갱신
3. TOPIC 노트가 아직 생성되지 않은 경우 (Phase 1-3 전 `[[LANGGRAPH]]` 등 — **정상**, PARTIAL 아님)

**방지 규칙**:
- 노트 작성 시 Obsidian 자동완성으로 정확한 파일명 확인 후 wikilink 삽입
- 파일 삭제·이름 변경 시 반드시 backlink 패널에서 참조 노트 수정
- Phase 1-3 전 TOPIC wikilink (`[[LANGGRAPH]]` 등)는 unresolved 상태가 정상 — G2_wiki에서 PARTIAL이 아닌 Low 처리

**자동 검출**:

```bash
# obsidian CLI (Phase 1-1에서 설치)
obsidian unresolved

# Phase 1-4 구현 후
python3 scripts/wiki/wiki.py link-check
make wiki-link-check
```

## 잘못된/올바른 예시 5건

### 1. `index` 평문 사용

```yaml
# ❌ 잘못된 예 — 평문
index: "AI"

# 이유: Obsidian이 wikilink로 인식 못 함. MOC 그래프 연결 불가.

# ✅ 올바른 예
index: "[[AI]]"
```

### 2. `topics` wikilink 미사용

```yaml
# ❌ 잘못된 예 — 평문 토픽
topics: ["LangGraph", "Multi Agent"]

# 이유: Obsidian 백링크 동작 안 함. TOPIC MOC(Phase 1-3)와 연결 불가.

# ✅ 올바른 예
topics: ["[[LANGGRAPH]]", "[[MULTI_AGENT]]"]
```

### 3. 외부 URL을 wikilink로 사용

```markdown
❌ [[https://arxiv.org/abs/2401.12345]]
   이유: 외부 URL → 즉시 broken link. G2_wiki FAIL.

✅ [Attention Is All You Need](https://arxiv.org/abs/2401.12345)
   + frontmatter sources에 URL 등록
```

### 4. alias 없이 한글로 본문에서 노트 호출

```markdown
# ❌ alias 미등록 상태에서 한글 호출
[[에이전틱 엔지니어링]]  → broken link (파일명이 영문이므로)

# ✅ frontmatter에 alias 등록 후 호출
# 파일: 2026-04-21_agentic_engineering.md
# aliases: ["에이전틱 엔지니어링"]
[[에이전틱 엔지니어링]]  → 정상 (alias 자동 매칭)
```

### 5. MOC 본문에 하향 링크 없음

```markdown
# ❌ AI.md — 빈 내용
# AI DOMAIN

(내용 없음)

# 이유: MOC가 하향 링크 없으면 그래프 연결 단절.

# ✅ AI.md — 하향 링크 나열
# AI DOMAIN

## RESEARCH_NOTE
- [[2026-04-21_agentic_engineering]]

## CONCEPT
- [[2026-05-01_llm_basics]]
```

## 검증 방법

### 자동

```bash
# broken link 검출 (obsidian CLI)
obsidian unresolved

# 전체 검증 (Phase 1-4 구현 후)
python3 scripts/wiki/wiki.py link-check --full
make wiki-link-check
```

### 수동

```bash
# obsidian unresolved 결과 확인
obsidian unresolved | grep -v "TOPIC\|CONSTRAINTS"
# TOPIC/CONSTRAINTS wikilink는 Phase 1-3 전 unresolved 정상
```
