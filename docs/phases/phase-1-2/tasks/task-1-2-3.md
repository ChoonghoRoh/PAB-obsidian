---
task_id: "1-2-3"
title: "Frontmatter 사용 가이드 (frontmatter-spec.md)"
domain: WIKI-META
owner: backend-dev
priority: P1
estimate_min: 20
status: pending
depends_on: ["1-2-1"]
blocks: []
---

# Task 1-2-3 — `wiki/30_Constraints/frontmatter-spec.md`

## 목적

사용자(또는 LLM)가 노트를 직접 작성할 때 참조하는 **frontmatter 사용 가이드**를 작성한다. T-1의 JSON Schema는 기계 검증용이고, 본 문서는 사람이 읽고 따라하는 가이드.

## 산출물

`wiki/30_Constraints/frontmatter-spec.md` (단일 파일)

## 문서 구조

문서 자체도 11필드 frontmatter를 포함한다 (self-referential validity 확보).

```yaml
---
title: "Frontmatter Spec"
description: "PAB Wiki 노트의 11필드 frontmatter 표준 — 작성 가이드"
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[CONSTRAINTS]]"]
tags: [reference, frontmatter, spec, constraints]
keywords: [frontmatter, schema, metadata, yaml, obsidian]
sources: ["wiki/40_Templates/_schema.json"]
aliases: ["Frontmatter Spec", "Metadata Spec", "FM Spec"]
---
```

## 본문 필수 섹션

### `## 개요`
- PAB Wiki는 11필드 frontmatter를 모든 노트에 강제
- 검증 도구: `wiki link-check` (Phase 1-4) → JSON Schema(`_schema.json`) 로드

### `## 11필드 표`
master-plan + plan.md의 11필드 표를 그대로 (필드명 / 타입 / 등급 / 설명 / 예시).

### `## 필드 등급`
- **필수 (Critical)**: `title`, `created`, `type` — 누락 시 G2_wiki FAIL
- **High**: `description`, `updated`, `index`, `topics`, `tags`, `aliases` — 누락 시 PARTIAL
- **Low**: `keywords`, `sources` — 빈 배열 허용

### `## 잘못된 예시 5건 vs 올바른 예시 5건`

각 예시는 **잘못된 frontmatter** + **이유** + **올바른 frontmatter** 형태.

1. **`type` 평문 사용** (잘못: `type: RESEARCH_NOTE` → 올바름: `type: "[[RESEARCH_NOTE]]"`)
2. **`created` ISO 8601 풀 형식** (잘못: `created: 2026-05-01T22:00:00Z` → 올바름: `created: 2026-05-01 22:00`)
3. **`tags` 대문자 + 공백** (잘못: `tags: [Multi Agent, LangGraph]` → 올바름: `tags: [multi-agent, langgraph]`)
4. **`topics` 평문** (잘못: `topics: ["LangGraph"]` → 올바름: `topics: ["[[LANGGRAPH]]"]`)
5. **`aliases` 누락** (High 위반) → 빈 배열 또는 1개 이상 명시

### `## TYPE별 frontmatter 차이`
6 TYPE에 대해 `type` / 권장 `tags 첫 항목` / 권장 `index` 기본값 표.

### `## DOMAIN MOC 6종`
- `[[AI]]` — 머신러닝, LLM, 에이전트
- `[[HARNESS]]` — Claude Code, IDE, CLI 도구
- `[[ENGINEERING]]` — 일반 SW 공학
- `[[PRODUCT]]` — 제품·프로젝트
- `[[KNOWLEDGE_MGMT]]` — 노트 시스템, 학습 방법론
- `[[MISC]]` — 기타
- `[[ROOT]]` — 최상위 (MOC·Index 노트만 사용)

### `## 자주 묻는 질문`
- Q1: 시간을 모르면? → `created: 2026-05-01` 만 적어도 OK (시간 부분은 optional)
- Q2: TOPIC이 아직 없으면? → `topics: []` 허용 (단 High 등급)
- Q3: alias를 여러 개 넣어도 되나? → 가능, 하지만 3~5개 이내 권장

### `## 검증 방법`
- 자동: `wiki link-check` (Phase 1-4)
- 수동: `python3 -c "import json; ..."` 또는 `jq '.' < <yq 출력>`

## 완료 기준

- [ ] 파일 존재
- [ ] 자체 frontmatter 11필드 포함
- [ ] 11필드 표 포함
- [ ] 잘못된/올바른 예시 각 5건
- [ ] TYPE별 차이 표
- [ ] DOMAIN MOC 6종 + ROOT 정의
- [ ] FAQ 3건 이상

## 보고

`reports/report-backend-dev.md` §T-3 섹션:
- 파일 경로 + 라인 수
- 자체 frontmatter 검증 결과 (11필드 카운트)

## 위험

- 잘못된/올바른 예시 작성 시 실제 schema가 거부하는지 mental check 필요
- `index` 기본값을 `[[ROOT]]`로 두면 모든 사용자 노트가 ROOT MOC로 몰림 → 작성자가 반드시 변경하도록 명시
