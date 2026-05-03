---
title: "Karpathy의 LLM Wiki — 누적되는 지식 산출물 패턴"
description: "Karpathy가 제안한 LLM 기반 지식 위키 패턴. RAG의 일회성 검색과 대비해 LLM이 마크다운 위키를 지속 갱신하여 지식이 누적·합성되도록 한다."
created: 2026-05-02 23:16
updated: 2026-05-02 23:16
type: "[[RESEARCH_NOTE]]"
index: "[[KNOWLEDGE_MGMT]]"
topics: ["[[LLM_WIKI]]"]
tags: [research-note, llm, knowledge-management, wiki, karpathy]
keywords: ["LLM Wiki", "RAG", "Memex", "Obsidian", "ingest", "query", "lint", "compounding"]
sources:
  - "https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f"
  - "https://en.wikipedia.org/wiki/Memex"
aliases: ["LLM Wiki", "Karpathy Wiki Pattern", "LLM 위키"]
---

# Karpathy의 LLM Wiki — 누적되는 지식 산출물 패턴

## 핵심 주장

> "The wiki is a persistent, compounding artifact."

[[RAG]]가 매 쿼리마다 원본 자료를 *재검색*하는 일회용 도구라면, **LLM Wiki**는 LLM이 한 번 처리한 결과를 마크다운 위키에 누적시킨다. 새 자료가 들어오면 기존 10~15개 페이지에 즉시 반영되어, 교차참조와 모순 표기가 *이미 존재하는 상태*에서 다음 쿼리가 시작된다. 지식베이스의 진짜 부담은 독서가 아니라 "사무 작업(bookkeeping) — 교차참조·일관성·갱신"이고, 이를 LLM이 전담한다.

## 3계층 아키텍처

| 계층 | 역할 | 변경 가능성 |
|---|---|---|
| **원본 출처(Raw sources)** | 페이퍼·아티클·노트 등 immutable 자료 | ❌ 불변 |
| **위키(LLM 유지)** | 마크다운 노트 — 요약·엔티티·컨셉·종합 페이지 | ✅ LLM이 지속 갱신 |
| **스키마(Schema)** | LLM 동작 규약 (예: [[CLAUDE_MD]], AGENTS.md) | ⚠️ 큐레이터 관리 |

## 3 운영 모드

- **Ingest**: 새 자료 추가 → LLM이 읽고 요약 페이지 작성 → 영향받는 10~15개 페이지 동시 갱신 → log.md 기록
- **Query**: 위키에 질문 → 관련 페이지 검색·종합 → 좋은 답변은 새 페이지로 저장 (탐색이 누적)
- **Lint**: 주기적 건강도 점검 — 모순·구식 주장·고아 페이지·끊긴 교차참조·데이터 갭 식별 후 LLM이 다음 조사 항목 제안

## 인덱싱 표준

| 파일 | 용도 |
|---|---|
| `index.md` | 콘텐츠 카탈로그 (페이지 목록 + 한 줄 요약 + 카테고리) — 매 ingest마다 갱신, 쿼리 시 가장 먼저 읽음 |
| `log.md` | 시간순 작업 로그 (append-only). 일관된 prefix(`## [YYYY-MM-DD] ingest \| Title`)로 유닉스 도구 파싱 가능 |

## 인간 vs LLM 역할 분담

- **인간**: 자료 큐레이션, 분석 방향 설정, 의미 부여
- **LLM**: 요약·교차참조·일관성 유지·파일 관리 등 *모든 grunt work*

> "The LLM does all the grunt work."
> "The tedious part of maintaining a knowledge base is not the reading or the thinking — it's the bookkeeping."

## 추천 도구 스택

- [[Obsidian]] — 마크다운 vault, 그래프 뷰, 플러그인 생태계
- [[Obsidian-Web-Clipper]] — 웹 → 마크다운 자동 변환
- [[qmd]] — 로컬 마크다운 검색 엔진 (BM25/벡터 + LLM 재순위), 소규모면 `index.md`만으로 충분
- [[Marp]] — 마크다운 → 슬라이드
- [[Dataview]] — frontmatter 기반 동적 쿼리
- [[MCP]] — LLM ↔ 외부 도구 연동
- [[Git]] — 마크다운 버전 관리 + 협업

## 역사적 맥락 — Memex

Vannevar Bush의 1945년 논문 *"As We May Think"*에서 제시된 [[Memex]] 개념의 현대적 구현체. 개인 큐레이션 지식저장소 + 문서 간 trail(연결)이 본 패턴의 사상적 뿌리. Bush가 풀지 못한 "유지 담당자 부재" 문제를 LLM이 해결한다.

## 적용 사례

개인 자기계발·건강·심리, 논문 읽기, 책 정리(장별·인물·테마 페이지), 팀 내부 위키(Slack/회의록/고객 통화), 경쟁분석·실사(due diligence), 강의 노트, 취미 탐구 등.

## 본 프로젝트와의 연결

[[PROJECT]] **PAB-obsidian**(본 vault)이 이 패턴의 직접 구현체. Phase 1-1~1-4에서 Karpathy 스키마를 **6 TYPE × 6 DOMAIN × N TOPIC** 3중 인덱스로 확장했고, Phase 1-5에서 ingest 자동화(`/pab:wiki`)를 단일 LLM skill로 제공한다.

## 한계와 비판

- 벤치마크 부재 — 정량 비교 자료 없음
- 손실 압축 위험 — LLM 요약이 원문 뉘앙스를 잃을 수 있음
- 대규모 다중 사용자 환경 미검증
- [[RAG]] 완전 대체가 아니라 *특정 시나리오*에 유용

## 참고

- [원문 Gist (Karpathy, 2026-04)](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- [As We May Think — Memex (Wikipedia)](https://en.wikipedia.org/wiki/Memex)
- 커뮤니티 구현: SwarmVault(48 에이전트), TheKnowledge(인용 검증), ΩmegaWiki(타입 그래프), WikiLoom(Python CLI), Kompl(웹 UI), Keppi(그래프 검색) 외 다수
