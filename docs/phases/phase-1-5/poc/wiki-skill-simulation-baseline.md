# /pab:wiki 실행 시뮬레이션 — Baseline (Golden Expected Output)

**작성일**: 2026-05-02
**작성자**: Team Lead (PAB-obsidian, Phase 1-5 진입 전)
**위상**: Phase 1-5 검증 baseline. 실제 `/pab:wiki` skill 호출 결과를 본 보고서와 비교하여 명세 정확도를 검증한다.
**작성 시점**: SKILL.md 작성 *이전* — LLM(Team Lead)이 SKILL.md 절차를 *예측*해서 실행한 결과

---

## 1. 입력

```
/pab:wiki https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f 내용을 읽고 정리해줘.
```

---

## 2. Step 1 — 입력 파싱

| 항목 | 값 |
|---|---|
| URL 추출 | `https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f` |
| 자연어 의도 | "내용을 읽고 정리해줘" → wiki 노트 작성 (저장 의도) |
| `--type` override | 없음 → LLM 자동 판별 |
| `--dry` | 없음 → 실제 저장 |

---

## 3. Step 2 — 외부 콘텐츠 페치 (WebFetch)

**페치 결과**: Karpathy의 "LLM Wiki" 패턴 글
- **핵심 주장**: "위키는 일회용 검색이 아니라 *누적되는 산출물*"
- **3계층 아키텍처**: 원본 출처(immutable) / 위키(LLM 유지) / 스키마(설정)
- **3 운영 모드**: ingest / query / lint
- **역사 참조**: Vannevar Bush 1945년 *Memex*
- **추천 도구**: Obsidian, qmd, Marp, Dataview, Web Clipper

---

## 4. Step 3 — TYPE 자동 판별 (6 TYPE)

| 후보 | 판정 | 사유 |
|---|---|---|
| **RESEARCH_NOTE** | ⭐ **채택** | 외부 글 본문을 정독·정리, 논지·구조 보존이 목적 |
| CONCEPT | △ 차순위 | "LLM Wiki" 개념 정의가 부분 포함되나, 본질은 외부 글 정리 |
| REFERENCE | △ | 도구 인용 다수이나 새 패턴 제시가 우선 |
| LESSON / PROJECT / DAILY | ✗ | 부적합 |

→ **`type: "[[RESEARCH_NOTE]]"`**

---

## 5. Step 4 — DOMAIN 자동 판별 (6 DOMAIN)

| 후보 | 판정 | 사유 |
|---|---|---|
| **KNOWLEDGE_MGMT** | ⭐ **채택** | 본질이 지식 시스템 설계 (PARA·Zettelkasten 계열) |
| AI | △ | LLM은 도구이지 본질이 아님 |
| HARNESS | ✗ | Claude Code/Obsidian CLI 도구 자체가 아님 |

→ **`index: "[[KNOWLEDGE_MGMT]]"`**

---

## 6. Step 5 — TOPIC 매칭

기존 vault TOPIC: `CONSTRAINTS.md` 1개만 존재 → 본 노트와 무관.

| TOPIC 후보 | 처리 |
|---|---|
| `LLM_WIKI` | **신규 TOPIC 마중물 권장** (본 노트가 첫 노트, Phase 1-3 정책: N=3 도달 시 자동 승격) |
| `MEMEX` | 단독 → 보류 |
| `RAG` | 본 노트는 RAG와 *대비*만 함 → 보류 |

→ 안전 모드 (Phase 1-3 정책 준수): **`topics: ["[[LLM_WIKI]]"]`** (1개) — `LLM_WIKI.md` MOC 노트는 미생성, unresolved 상태로 두고 N=3 도달 시 `wiki moc-build`가 자동 승격

---

## 7. Step 6 — 메타데이터 자동 생성

| 필드 | 값 | 결정 근거 |
|---|---|---|
| `title` | `"Karpathy의 LLM Wiki — 누적되는 지식 산출물 패턴"` | 저자 + 핵심 주장 |
| `description` | `"Karpathy가 제안한 LLM 기반 지식 위키 패턴. RAG 대비 누적·합성을 강조."` | 1~2줄 요약 |
| `slug` | `karpathy_llm_wiki` | 저자 + 핵심 주제 (snake_case, 19자) |
| `created` | `2026-05-02 14:30` | 현재 시각 |
| `aliases` | `["LLM Wiki", "Karpathy Wiki Pattern", "LLM 위키"]` | 한글·약어 포함 |
| `tags` | `[research-note, llm, knowledge-management, wiki, karpathy]` | TYPE 슬러그 + 핵심 키워드 |
| `keywords` | `["LLM Wiki", "RAG", "Memex", "Obsidian", "ingest", "lint"]` | 검색 보조 |
| `sources` | gist URL + Memex 위키피디아 | 1차 + 인용 출처 |

**파일 경로**: `wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md`

---

## 8. Step 7 — 본문 생성 + Step 8 — 최종 산출물 (생성될 .md 파일 전문)

````markdown
---
title: "Karpathy의 LLM Wiki — 누적되는 지식 산출물 패턴"
description: "Karpathy가 제안한 LLM 기반 지식 위키 패턴. RAG 대비 누적·합성을 강조."
created: 2026-05-02 14:30
updated: 2026-05-02 14:30
type: "[[RESEARCH_NOTE]]"
index: "[[KNOWLEDGE_MGMT]]"
topics: ["[[LLM_WIKI]]"]
tags: [research-note, llm, knowledge-management, wiki, karpathy]
keywords: ["LLM Wiki", "RAG", "Memex", "Obsidian", "ingest", "lint"]
sources:
  - "https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f"
  - "https://en.wikipedia.org/wiki/Memex"
aliases: ["LLM Wiki", "Karpathy Wiki Pattern", "LLM 위키"]
---

# Karpathy의 LLM Wiki — 누적되는 지식 산출물 패턴

## 핵심 주장

> "The wiki is a persistent, compounding artifact."

[[RAG]]가 매번 원본을 *재검색*하는 일회용 도구라면, LLM Wiki는 LLM이 한 번 처리한 결과를 **마크다운 위키에 누적**시킨다. 새 출처가 들어오면 위키의 기존 15개 페이지와 자동으로 상호참조·연결된다.

## 3계층 아키텍처

| 계층 | 역할 | 변경 가능성 |
|---|---|---|
| **원본 출처** | 페이퍼·아티클·노트 등 immutable 자료 | ❌ 불변 |
| **위키 (LLM 유지)** | 마크다운 노트 — 합성·정리·교차참조 | ✅ LLM이 지속 갱신 |
| **스키마** | LLM의 동작 규약 (어떻게 인덱싱·정리할지) | ⚠️ 큐레이터가 관리 |

## 3 운영 모드

- **ingest**: 새 출처 추가 → LLM이 위키 자동 갱신
- **query**: 위키 기반 질의응답 (원본 재검색 불요)
- **lint**: 위키 건강도 점검 (끊긴 링크·고아·중복)

## 인덱싱 표준

| 파일 | 용도 |
|---|---|
| `index.md` | 콘텐츠 카탈로그 (entity·concept 페이지 분류) |
| `log.md` | 시간순 작업 기록 |

## 추천 도구 스택

- [[Obsidian]] — 그래프 뷰, 플러그인 생태계
- [[qmd]] — 로컬 마크다운 검색 엔진
- [[Marp]] — 마크다운 → 슬라이드 변환
- [[Dataview]] — Obsidian 메타데이터 쿼리
- [[Obsidian-Web-Clipper]] — 웹 → 마크다운 자동 변환
- [[MCP]] 서버 연동으로 LLM 외부 접근

## 역사적 맥락 — Memex

Vannevar Bush의 1945년 논문 "As We May Think"에서 제시된 [[Memex]] 개념의 현대적 구현체. 개인 지식 저장소 + 문서 간 연결(trail) 개념이 본 패턴의 사상적 뿌리.

## 작동 원리 — 왜 이게 효과적인가

LLM이 *반복적 유지보수*를 담당하므로, 인간 큐레이터의 부담이 극적으로 감소한다. 인간은 출처 추가·스키마 조정만 담당.

## 커뮤니티 구현 사례

- **SwarmVault** — 48개 에이전트 통합
- **Beever Atlas** — 팀 협업 버전
- **TheKnowledge** — 인용 검증 기능
- **ΩmegaWiki** — 타입 지정 그래프 실행

## 본 프로젝트와의 연결

PAB-obsidian([[PROJECT]])이 본 패턴의 직접 구현체. Phase 1-1~1-4에서 Karpathy 스키마를 **6 TYPE × 6 DOMAIN × N TOPIC**의 3중 인덱스로 확장. Phase 1-5에서 ingest 자동화(`/pab:wiki`)를 skill로 제공.

## 참고

- [원문 gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- [As We May Think (Wikipedia)](https://en.wikipedia.org/wiki/Memex)
````

---

## 9. Step 9 — 후처리 검증 (예상)

```bash
$ python3 scripts/wiki/wiki.py link-check wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md
```

| 검증 항목 | 결과 |
|---|---|
| frontmatter 11필드 (Critical 3) | ✅ PASS — title/created/type 모두 존재 |
| frontmatter High 5개 | ✅ PASS — index/topics/tags/aliases/updated 모두 채움 |
| 파일명 규약 (`YYYY-MM-DD_slug.md`) | ✅ PASS |
| 슬러그 정규식 (`[a-z0-9_]{1,50}`) | ✅ PASS (19자) |
| Critical wikilink 해소 (TYPE/DOMAIN MOC) | ✅ PASS — `[[RESEARCH_NOTE]]`, `[[KNOWLEDGE_MGMT]]` 모두 vault 존재 |
| TOPIC wikilink | ⚠️ unresolved 1건 — `[[LLM_WIKI]]` (정상, 신규 TOPIC 마중물) |
| 본문 wikilink (도구·개념) | ⚠️ unresolved 8건 — `[[Memex]]`, `[[Obsidian]]`, `[[RAG]]` 등 (정상, 미래 노트) |

**최종 판정**: ✅ **PASS** (Critical/High 100% + unresolved는 미래 노트로 의도된 것)

---

## 10. Step 10 — 사용자 응답 메시지 (예상)

```
✅ 노트 생성 완료

📄 파일: wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md (3.4 KB)
🏷️  TYPE: RESEARCH_NOTE  |  DOMAIN: KNOWLEDGE_MGMT  |  TOPIC: LLM_WIKI (신규)
🔗 wikilink 9개 자동 삽입 (8개 미래 노트, 1개 신규 TOPIC)

⚠️  TOPIC `LLM_WIKI`는 vault에 처음 등장 — 노트 3개 도달 시
    `make wiki-moc-build`로 MOC 자동 승격됩니다.

옵시디언 vault 인덱싱은 자동입니다.
```

---

## 11. 비교 검증 기준 (실제 skill 호출 시 적용)

실제 `/pab:wiki` 호출 결과가 본 baseline과 다음 항목에서 일치해야 한다:

### 11.1 결정적 일치 항목 (Hard Match)

| 항목 | 일치 기준 |
|---|---|
| 파일 경로 | `wiki/10_Notes/2026-05-02_*.md` (날짜는 호출 당일로 변동 가능) |
| 파일명 슬러그 정규식 | `^[a-z0-9_]{1,50}\.md$` |
| frontmatter 11필드 존재 | 11개 모두 존재 |
| `type` 값 | `"[[RESEARCH_NOTE]]"` |
| `index` 값 | `"[[KNOWLEDGE_MGMT]]"` |
| `topics` wikilink 형식 | `"[[...]]"` 패턴 |
| `created`/`updated` 패턴 | `^\d{4}-\d{2}-\d{2}( \d{2}:\d{2})?$` |
| `tags` 첫 항목 | `research-note` (TYPE 슬러그) |
| `wiki link-check` PASS | Critical/High 모두 존재 |

### 11.2 의미적 일치 항목 (Soft Match — LLM 판단)

| 항목 | 허용 범위 |
|---|---|
| `title` | "Karpathy" + "LLM Wiki" 두 키워드 포함 |
| `description` | RAG 대비·누적 개념 중 하나 이상 언급 |
| `slug` | `karpathy` 또는 `llm_wiki` 키워드 포함 |
| 본문 섹션 수 | 5~10개 (너무 짧거나 과도하지 않게) |
| 본문 내 wikilink 개수 | 5개 이상 (Memex/Obsidian/RAG 등 핵심 용어 포함) |
| 핵심 인용 | "compounding artifact" 또는 "누적되는 산출물" 표현 포함 |

### 11.3 차이 분석 시 처리 방침

- **결정적 항목 불일치** → SKILL.md 명세 보강 필요 (FAIL)
- **의미적 항목 차이** → SKILL.md 휴리스틱 가이드 보강 (WARN, 사용자 판단)
- **baseline보다 더 나은 결과** → baseline 갱신, 차이 사유 기록 (PASS+)

---

**참고**: 본 baseline은 작성 시점 LLM의 *추정 결과*이며, 실제 skill 호출 결과가 다를 수 있다. 차이는 SKILL.md 명세 정확도 진단의 입력이다.
