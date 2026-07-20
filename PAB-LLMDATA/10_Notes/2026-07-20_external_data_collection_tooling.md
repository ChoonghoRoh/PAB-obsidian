---
title: "외부 자료수집 툴링 조사 — 메신저·크롤러·웹fetch (PAB-Prove 수집 확장)"
description: "PAB-Prove 수집 파이프라인 확장을 위한 2026 현행 툴링 조사 — Telegram long-poll 수집·trafilatura/Playwright 크롤러·hishel/protego/Docling. 폐쇄망·워커 최소권한 정합 권고."
created: "2026-07-20"
updated: "2026-07-21"
type: "[[RESEARCH_NOTE]]"
index: "[[ENGINEERING]]"
topics: ["[[LLM_WIKI]]", "[[DATA_COLLECTION]]", "[[WEB_SCRAPING]]", "[[PAB_ECOSYSTEM]]"]
tags: [research-note, data-collection, web-scraping, telegram-bot, crawler, fetcher, self-host]
keywords: [자료수집, Telegram Bot, getUpdates, long polling, trafilatura, Crawl4AI, Firecrawl, Jina Reader, Playwright, Docling, MarkItDown, hishel, protego, Naver iframe, lethal trifecta]
sources: ["works/PAB-Prove/docs/reports/R-01-data-collection-tooling.md", "https://core.telegram.org/bots/api", "https://github.com/adbar/trafilatura", "https://github.com/unclecode/crawl4ai", "https://github.com/docling-project/docling", "https://github.com/karpetrosyan/hishel"]
aliases: ["자료수집 툴링", "수집 크롤러 조사", "R-01 자료수집"]
---

# 외부 자료수집 툴링 조사 — 메신저·크롤러·웹fetch

> **맥락**: [[PAB-Prove]]의 `/pab:wiki` 수집을 확장하기 위한 2026-07 현행 툴 조사. 불변 제약 = [[Tailscale|Tailnet]] 폐쇄망·self-host 선호·**워커 최소권한([[lethal trifecta]] 방어)**·SOURCE 불변. 전문: `works/PAB-Prove/docs/reports/R-01-data-collection-tooling.md`.

---

## 1. 권고 요약 (TL;DR)

| 영역 | 1차 권고 | 배제/주의 |
|---|---|---|
| **메신저 수집** | [[Telegram]] Bot `getUpdates`(long polling) + `chat_id` 화이트리스트 → 수집 큐 | KakaoTalk 공식(webhook·비즈채널), webhook 방식(공개 endpoint) |
| **크롤러/추출** | [[trafilatura]](정적·무키·F1~0.97) → 실패 시 [[Playwright]] 렌더 재추출/[[Crawl4AI]] | [[Firecrawl]]/[[Jina Reader]] **cloud API**(URL 외부유출) |
| **fetch/캐시** | 기존 httpx + [[hishel]](RFC9111) + [[protego]](robots) + trafilatura, 파일=[[Docling]] | readability-lxml(비활성)·newspaper3k(방치) |

**핵심 정합**: 모든 네트워크 fetch·추출을 **fetcher 계층**에서 끝내고 워커(LLM)엔 **선페치 텍스트만** 주입 → [[lethal trifecta]] 방어와 완전 정합. cloud 추출 API는 대상 URL을 제3자로 보내 이 경계를 파괴하므로 배제.

## 2. 메신저 기반 수집

- **수신 방식이 폐쇄망 정합을 결정**: `getUpdates`(long polling)는 봇→Telegram **아웃바운드만** → 공개 endpoint 불필요(최적). `setWebhook`은 인바운드(공개 HTTPS 필요)라 부적합. (둘은 상호배타, webhook 설정 시 getUpdates 409)
- **수신 타입**: text/URL/파일(`getFile`, cloud 20MB / self-host local Bot API server 2GB).
- **★ 선행 자산**: PAB-obsidian `scripts/wiki/telegram_ingest_listener.sh`가 이미 존재 → `chat_id` 화이트리스트 + 큐 enqueue로 정식화하면 됨.
- **보안**: `chat_id`/`user_id` 화이트리스트(그 외 drop), 토큰 회전, `/setprivacy`, `update_id` offset 중복방지.
- **대안**: 순수 폐쇄망 최우선 시 Tailnet 내 [[Matrix]](Synapse/Conduit) — 데이터 외부 미유출. KakaoTalk 공식은 webhook+비즈채널 필수라 개인용 부적합.

## 3. 크롤러·추출 비교 (2026-07)

| 도구 | self-host | 추출품질 | JS·차단대응 | 라이선스 | 상태 |
|---|---|---|---|---|---|
| **[[trafilatura]]** | ✅ | 본문+메타→MD, **최상위급(F1~0.97)** | 정적만 | Apache-2.0 | v2.1(활발) |
| **[[Crawl4AI]]** | ✅ | `fit_markdown` | Playwright JS렌더 O | Apache-2.0 | v0.9(트렌딩) |
| [[Firecrawl]] | ⚠️부분 | scrape/crawl/map | cloud만 안티봇 | AGPL-3.0 | 활발 |
| [[Playwright]] | ✅ | (렌더 엔진) | JS렌더 O | Apache-2.0 | MS·표준 |

- **모바일 URL 정규화**: `m.*`→desktop, tracking 제거, 단축URL 확장. **Naver 블로그**는 본문이 iframe(`mainFrame`) 내부 → 사이트별 핸들러 필요.
- **파일→MD**: [[Docling]](MIT·air-gapped 명시, ~88% F1) 우선 / [[MarkItDown]](경량·고속).

## 4. PAB-Prove 통합 파이프라인 (권고)

```
[Telegram long-poll | 웹앱] → 큐(chat_id 화이트리스트)
  → fetcher: httpx+hishel → (실패)Playwright / URL정규화 / protego
  → 추출: trafilatura(HTML) · Docling(파일)
  → ★ 정제 텍스트만 → 워커(요약, 최소권한) → vault(SOURCE 불변)
```
단계: ① `telegram_ingest_listener.sh` 정식화 → ② `fetchers.py`에 trafilatura+hishel → ③ 파일=Docling → ④ 필요 시 Playwright 폴백(격리 컨테이너·egress 제한).

## 5. 2차 고려·시사점

- **프라이버시**: Telegram 봇은 E2E 아님(콘텐츠가 Telegram cloud 경유) → 극도 요구 시 Matrix.
- **운영부담**: 헤드리스 Chromium(Playwright/Crawl4AI)은 이미지·메모리↑ → 별도 컨테이너 격리.
- **[[prompt injection]]**: 추출 텍스트의 숨은 지시 → 워커 최소권한(무툴·무URL)이 최종 방어선.
- **라이선스**: trafilatura/Crawl4AI/Playwright=Apache-2.0(안전), Firecrawl=AGPL(배포 시 copyleft 주의).

## 연결

- 비용 관점: [[2026-07-20_llm_api_cost_local_vs_external]] · 인덱싱: [[2026-07-20_obsidian_indexing_rag_ontology]]
- 소비 시스템: [[Khala]] 추론 · [[PAB_ECOSYSTEM]]
