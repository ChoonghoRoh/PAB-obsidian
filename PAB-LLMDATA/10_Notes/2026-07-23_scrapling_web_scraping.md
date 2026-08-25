---
title: "Scrapling — 적응형 웹 스크래핑 프레임워크 정리 + Khala webfetch 비교"
description: "Scrapling의 주요 기능·차별점·활용법 요약 + PAB-Khala webfetch/crawling 스택과의 비교"
created: 2026-07-23 23:17
updated: 2026-07-23 23:17
type: "[[RESEARCH_NOTE]]"
index: "[[ENGINEERING]]"
topics: ["[[WEB_SCRAPING]]", "[[ANTI_BOT]]"]
tags: [research-note, web-scraping, scrapling, anti-bot, mcp, khala]
keywords: [Scrapling, web scraping, Playwright, trafilatura, Cloudflare, stealth, adaptive tracking, MCP, spider, Khala webfetch]
sources: ["[[15_Sources/2026-07-23_scrapling_web_scraping_source]]", "https://github.com/D4Vinci/Scrapling"]
aliases: [Scrapling 정리, 스크래플링, scrapling-note]
---

# Scrapling — 적응형 웹 스크래핑 프레임워크 정리

> [[D4Vinci]]/Scrapling (BSD-3, Python 3.10+, ⭐70.9k+). 저자 [[Karim Shoair]].
> 한 문장: **"단일 요청부터 대규모 크롤까지 하나로 처리하는 적응형(adaptive) 웹 스크래핑 프레임워크"**.

## 한눈에 요약

[원본 §Project Overview →](2026-07-23_scrapling_web_scraping_source.md#project-overview)

Scrapling은 파싱 라이브러리([[BeautifulSoup]]/[[lxml]])와 크롤링 프레임워크([[Scrapy]]), 브라우저 자동화([[Playwright]]/[[Selenium]])의 경계를 하나로 묶은 **올인원 스크래핑 스택**이다. 세 가지 축이 핵심 셀링 포인트:

1. **적응형 요소 추적(adaptive tracking)** — 사이트 디자인이 바뀌어도 유사도 알고리즘으로 요소를 재추적.
2. **내장 안티봇 우회** — [[Cloudflare]] Turnstile 자동 해결·TLS 지문 위장·헤드리스 탐지 회피가 기본 탑재.
3. **[[MCP]] 서버 내장** — LLM(Claude/Cursor)이 스크래핑 결과를 토큰 효율적으로 소비하도록 사전 추출.

## 주요 기능

[원본 §Key Features →](2026-07-23_scrapling_web_scraping_source.md#key-features)

- **Fetcher 3종**: `Fetcher`(HTTP, TLS 위장·HTTP/3) → `DynamicFetcher`([[Playwright]] Chromium, JS 렌더링) → `StealthyFetcher`(안티봇·Cloudflare 우회). 각각 `FetcherSession`/`DynamicSession`/`StealthySession` 세션 클래스로 상태 관리, 모두 async 변형 제공.
- **Spider 프레임워크**: Scrapy 유사 API(`start_urls`·async `parse`·`Request`/`Response`). 동시 크롤 + 도메인별 스로틀 + **일시정지/재개(체크포인트 persistence)** + 스트리밍 + robots.txt 준수 + JSON/JSONL 내보내기.
- **멀티 세션 라우팅**: 한 스파이더 안에서 보호된 링크는 stealth, 일반 링크는 fast HTTP로 요청을 분기(`sid`).
- **인프라**: `ProxyRotator` 프록시 순환, ~3,500 광고/트래커 도메인 차단, DNS-over-HTTPS.

## 다른 라이브러리와의 차별점

[원본 §Differentiation from Other Libraries →](2026-07-23_scrapling_web_scraping_source.md#differentiation-from-other-libraries)

| 축 | Scrapling | 기존 라이브러리 |
|---|---|---|
| 적응형 추적 | 디자인 변경 후 요소 자동 재배치 | BS4/lxml: 정적 셀렉터만 |
| 안티봇 | Cloudflare Turnstile 내장 해결 | Selenium/Playwright: 수동 셋업 |
| 스파이더 | sync/async 통합 + 멀티세션 | Scrapy: 기본 HTTP 전용 |
| 일시정지/재개 | 체크포인트 지속 | 대부분: 처음부터 재시작 |
| CLI | 코드 없이 추출 | 유일 |
| MCP | AI 사전 추출 | 경쟁자 없음 |

**핵심 우위**: (1) 셀렉터가 깨져도 살아남는 적응성, (2) 안티봇·stealth의 "배터리 포함(batteries-included)", (3) LLM 파이프라인과의 1급 통합.

## 성능 벤치마크

[원본 §Performance Benchmarks →](2026-07-23_scrapling_web_scraping_source.md#performance-benchmarks)

- **텍스트 추출(5000 중첩 요소)**: Scrapling 1.98ms ≈ Parsel/Scrapy 1.99ms, Raw lxml 2.48ms. BS4+lxml 대비 **~775배**, BS4+html5lib 대비 **~1711배** 빠름.
- **요소 유사도/텍스트 검색**: Scrapling 2.29ms vs AutoScraper 12.46ms(**5.4배**).
- 파싱 속도는 lxml/parsel급이면서 적응형·안티봇 기능을 얹은 것이 실질 강점(순수 속도만의 승부는 아님).

## 활용 방법 (설치 + API)

[원본 §Installation →](2026-07-23_scrapling_web_scraping_source.md#installation)

```bash
pip install scrapling               # 파서만
pip install "scrapling[fetchers]"   # 페처+브라우저
scrapling install                   # 브라우저 바이너리
pip install "scrapling[ai]"         # MCP 서버
```

[원본 §Usage Examples →](2026-07-23_scrapling_web_scraping_source.md#usage-examples)

```python
from scrapling.fetchers import Fetcher, StealthyFetcher

# 정적
page = Fetcher.get('https://quotes.toscrape.com/')
quotes = page.css('.quote .text::text').getall()

# 안티봇 우회
page = StealthyFetcher.fetch('https://nopecha.com/demo/cloudflare')
```

선택 API는 CSS/XPath/`find_all`(BS4 스타일)/`find_by_text`/`find_similar`(유사 요소 자동 탐색)/DOM 탐색(`parent`·`next_sibling`·`below_elements`)을 모두 지원.

**CLI(코드 없이)**: `scrapling extract get <url> content.md --css-selector '#products'`, `scrapling extract stealthy-fetch <url> out.html --solve-cloudflare`.

## Khala webfetch / crawling 기능과 비교

> 본 노트의 확장 요청 항목 — [[PAB-Khala]]의 웹 취득 스택과 Scrapling을 대조.

Khala에는 웹 취득 기능이 **세 갈래**로 존재한다:

| Khala 컴포넌트 | 스택 | 성격 |
|---|---|---|
| `skills/webfetch` (`/pab:webfetch`) | urllib + [[trafilatura]] (static) → [[Playwright]] headless (js fallback) | **단일 URL → 본문 Markdown 추출** |
| `run-on-3800x-v3/lib/fetch_url.py` | urllib GET + `<script>` 본문만 제거 | LLM toolcall용, HTML/CSS/텍스트 **디자인 정보 보존** |
| `multipage-html-gen` (01_collect 등) | [[BeautifulSoup]] + 정규식 | 도메인 특화 **멀티페이지 합성 파이프라인**(header/footer/CSS var/연락처 추출) |

### 기능 대조표

| 항목 | Scrapling | Khala webfetch |
|---|---|---|
| 목적 | 범용 스크래핑 **프레임워크** | LLM 워크플로용 **본문 추출 유틸** |
| JS 렌더링 | DynamicFetcher(Playwright) | auto 모드 시 Playwright fallback |
| 본문 추출 | 원시 요소/셀렉터 반환 | trafilatura로 **본문만 정제** (LLM 토큰 절약) |
| 안티봇/Cloudflare | ✅ Turnstile 자동 해결·TLS 위장 | ❌ (Phase 3-1 한계, headless 차단 시 fail) |
| 프록시 순환 | ✅ ProxyRotator 내장 | ❌ |
| 다중 페이지 크롤 | ✅ Spider(동시·재개·스로틀) | △ multipage 파이프라인(도메인 특화, 범용 크롤 아님) |
| 적응형 요소 추적 | ✅ 유사도 재배치 | ❌ |
| 특수 사이트 | (일반 처리) | reddit `.json`·github REST API 자동 감지 |
| 출력 포맷 | txt/md/html | md(frontmatter)/text/html/json |
| AI 통합 | MCP 서버 | Khala 워크플로/toolcall 직접 호출(`fetch_url_js` 계획) |

### 시사점 (Khala 관점)

- **Khala webfetch의 약점 = Scrapling의 강점**: Cloudflare/Turnstile 등 상업 안티봇 우회는 Khala가 못 하는 지점(SKILL §6 명시). Scrapling의 StealthyFetcher가 정확히 그 갭을 메운다.
- **역방향 강점**: Khala webfetch는 trafilatura 본문 정제로 **LLM 토큰 효율**이 좋고, reddit/github 네이티브 API 자동 감지가 있어 특정 소스에서는 더 실용적. Scrapling도 MCP·"사전 추출" 철학으로 같은 방향을 지향하지만, Khala는 이미 워크플로에 배선되어 있음.
- **통합 후보**: Khala의 계획된 `fetch_url_js` toolcall(Phase 5 toolkit) 또는 Phase 3-2 "visible-once cookie cache" 대신, **Scrapling StealthyFetcher를 백엔드로 채택**하면 안티봇 갭을 코드 최소로 메울 수 있음(향후 검토 후보 — 사용 사례 정의 선행 필요, [[feedback_yagni_no_use_case]]).
- **역할 분담 정리**: Scrapling = "가져오기(안티봇 뚫고 원시 HTML/요소 확보)", Khala webfetch = "정제·LLM 소비용 본문 추출" + 워크플로 오케스트레이션. 상호 배타가 아니라 **보완재**.

## 안티봇·AI 통합 요약

[원본 §Anti-Bot & Stealth Capabilities →](2026-07-23_scrapling_web_scraping_source.md#anti-bot--stealth-capabilities)

TLS 지문 위장·Cloudflare Turnstile 자동 해결·헤드리스 탐지 회피·헤더 스푸핑·HTTP/3·프록시 순환·DNS-over-HTTPS.

[원본 §AI & MCP Integration →](2026-07-23_scrapling_web_scraping_source.md#ai--mcp-integration)

MCP 서버 내장으로 Claude/Cursor가 Scrapling을 "사전 추출기"로 사용 → AI에 넘기기 전 타깃 콘텐츠만 뽑아 **토큰·비용 절감**. 이는 Khala가 trafilatura로 달성하려는 목표와 동일한 철학.
