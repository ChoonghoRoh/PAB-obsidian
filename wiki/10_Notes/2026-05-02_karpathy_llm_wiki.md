---
title: "Karpathy의 LLM Wiki — 누적되는 지식 산출물 패턴"
description: "Karpathy가 제안한 LLM 기반 지식 위키 패턴. RAG 대비 누적·합성을 강조. 원본 immutable 보존 + LLM 요약본 두 계층으로 구성."
created: 2026-05-02 23:15
updated: 2026-05-02 23:15
type: "[[RESEARCH_NOTE]]"
index: "[[KNOWLEDGE_MGMT]]"
topics: ["[[LLM_WIKI]]"]
tags: [research-note, llm, knowledge-management, wiki, karpathy]
keywords: ["LLM Wiki", "RAG", "Memex", "Obsidian", "ingest", "lint", "compounding artifact"]
sources:
  - "[[15_Sources/2026-05-02_karpathy_llm_wiki_source]]"
  - "https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f"
aliases: ["LLM Wiki", "Karpathy Wiki Pattern", "LLM 위키"]
---

# Karpathy의 LLM Wiki — 누적되는 지식 산출물 패턴

## 핵심 주장

[원본 §The core idea →](2026-05-02_karpathy_llm_wiki_source.md#the-core-idea)

> "The wiki is a persistent, compounding artifact."

[[RAG]]가 매번 원본을 *재검색*하는 일회용 도구라면, LLM Wiki는 LLM이 한 번 처리한 결과를 **마크다운 위키에 누적**시킨다. 새 출처가 들어오면 기존 10~15개 페이지와 자동으로 통합·교차참조된다. 지식이 쿼리마다 재도출되는 것이 아니라 *한 번 컴파일되고 계속 갱신*된다.

인간은 소싱·탐색·올바른 질문에 집중하고, LLM이 요약·교차참조·파일링·정합성 유지를 담당한다. Obsidian이 IDE, LLM이 프로그래머, 위키가 코드베이스.

## 3계층 아키텍처

[원본 §Architecture →](2026-05-02_karpathy_llm_wiki_source.md#architecture)

| 계층 | 역할 | 변경 가능성 |
|---|---|---|
| **원본 출처 (Raw sources)** | 페이퍼·아티클·노트 등 immutable 자료 | ❌ 불변 |
| **위키 (LLM 유지)** | 마크다운 노트 — 합성·정리·교차참조 | ✅ LLM이 지속 갱신 |
| **스키마** | LLM의 동작 규약 (구조·컨벤션·워크플로우) | ⚠️ 큐레이터가 관리 |

PAB-obsidian의 구현: `wiki/15_Sources/` (원본) / `wiki/10_Notes/` (위키) / `wiki/30_Constraints/` + `skills/wiki/SKILL.md` (스키마).

## 3 운영 모드

[원본 §Operations →](2026-05-02_karpathy_llm_wiki_source.md#operations)

- **Ingest**: 새 출처 추가 → LLM이 위키 자동 갱신 (단일 소스가 10~15 페이지에 영향)
- **Query**: 위키 기반 질의응답 — 좋은 답변은 새 페이지로 *다시 위키에 저장* (탐색도 누적됨)
- **Lint**: 위키 건강도 점검 (모순·오래된 주장·고아 페이지·미완성 교차참조)

## 인덱싱·로그 구조

[원본 §Indexing and logging →](2026-05-02_karpathy_llm_wiki_source.md#indexing-and-logging)

| 파일 | 용도 |
|---|---|
| `index.md` | 콘텐츠 카탈로그 (엔티티·개념 페이지 분류, 100 소스 규모까지 RAG 불요) |
| `log.md` | 시간순 append-only 기록 (`## [날짜] ingest | 제목` prefix → unix tools 파싱 가능) |

## 추천 도구 스택

[원본 §Optional: CLI tools →](2026-05-02_karpathy_llm_wiki_source.md#optional-cli-tools)
[원본 §Tips and tricks →](2026-05-02_karpathy_llm_wiki_source.md#tips-and-tricks)

- [[Obsidian]] — 그래프 뷰, 플러그인 생태계 (IDE 역할)
- [[qmd]] — 로컬 마크다운 검색 엔진 (BM25/벡터 하이브리드, CLI + MCP 서버)
- [[Marp]] — 마크다운 → 슬라이드 변환 (Obsidian 플러그인)
- [[Dataview]] — Obsidian 메타데이터 쿼리 (YAML frontmatter 활용)
- [[Obsidian-Web-Clipper]] — 웹 → 마크다운 자동 변환
- Git repo 그대로 — 버전 히스토리·브랜치·협업 무료 제공

## 왜 효과적인가

[원본 §Why this works →](2026-05-02_karpathy_llm_wiki_source.md#why-this-works)

위키 유지의 번거로운 부분은 독서·사고가 아니라 *교차참조 갱신·모순 파악·정합성 유지* 같은 부기(bookkeeping)다. 인간은 관리 부담이 가치를 앞지르면 위키를 포기한다. LLM은 지루해하지 않고, 교차참조 갱신을 잊지 않으며, 한 번에 15개 파일을 수정할 수 있다. 유지 비용이 거의 0에 수렴.

## 역사적 맥락 — Memex

[원본 §Why this works →](2026-05-02_karpathy_llm_wiki_source.md#why-this-works)

[[Memex]] — Vannevar Bush의 1945년 논문 "As We May Think"에서 제시된 개인 지식 저장소 개념의 현대적 구현체. Bush의 비전은 웹이 된 것보다 이 패턴에 더 가깝다: 사적·능동적 큐레이션, 문서 간 연결이 문서 자체만큼 가치 있음. Bush가 해결하지 못한 *유지관리 담당자* 문제를 LLM이 해결한다.

## 커뮤니티 구현 사례

[원본 §Architecture →](2026-05-02_karpathy_llm_wiki_source.md#architecture)

gist가 40+ 구현체를 파생시킴:
- **SwarmVault** — 멀티에이전트 통합
- **TheKnowledge** — 인용 검증 기능
- **ΩmegaWiki** — 타입 지정 그래프 실행
- 인용 근거·업데이트 검증 없이 RAG 대체를 주장하는 것의 한계도 제기됨

## 본 프로젝트와의 연결

PAB-obsidian([[PROJECT]])이 본 패턴의 직접 구현체. Phase 1-1~1-4에서 Karpathy 스키마를 **6 TYPE × 6 DOMAIN × N TOPIC**의 3중 인덱스로 확장. Phase 1-5에서 ingest 자동화(`/pab:wiki`)를 skill로 제공 — 1회 호출 시 원본(`wiki/15_Sources/`) + 요약본(`wiki/10_Notes/`) 두 파일 동시 생성.

## 참고

- [원문 gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) → 원본 보존: [[15_Sources/2026-05-02_karpathy_llm_wiki_source]]
- [As We May Think — Memex (Wikipedia)](https://en.wikipedia.org/wiki/Memex)
