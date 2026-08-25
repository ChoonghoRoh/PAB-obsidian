---
title: "Scrapling — Adaptive Web Scraping Framework (D4Vinci/Scrapling README 원문)"
description: "GitHub D4Vinci/Scrapling README 페치 원문 — 적응형 웹 스크래핑 프레임워크 기능·벤치마크·API"
created: 2026-07-23 23:17
updated: 2026-07-23 23:17
type: "[[SOURCE]]"
index: "[[ENGINEERING]]"
topics: ["[[WEB_SCRAPING]]", "[[ANTI_BOT]]"]
tags: [source, web-scraping, scrapling, anti-bot, mcp]
keywords: [Scrapling, web scraping, Playwright, Cloudflare, stealth, adaptive, MCP, spider, TLS fingerprint, proxy rotation]
sources: ["https://github.com/D4Vinci/Scrapling"]
aliases: [Scrapling 원문, scrapling-source]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층)
> 페치 방식: WebFetch (2026-07-23), README 구조화 추출본

# Scrapling: Comprehensive GitHub README Extraction

## Project Overview

**Scrapling** is described as "An adaptive Web Scraping framework that handles everything from a single request to a full-scale crawl." The tagline emphasizes "Effortless Web Scraping for the Modern Web."

The framework positions itself as a unified solution spanning from simple HTTP requests to enterprise-scale concurrent crawls, with built-in anti-bot capabilities and adaptive element tracking.

---

## Key Features

### Spider Framework
- **Scrapy-like API**: Supports `start_urls`, async `parse` callbacks, `Request`/`Response` objects
- **Concurrent crawling** with configurable limits and per-domain throttling
- **Multi-session support**: Route requests between HTTP and browser-based fetchers
- **Pause & resume**: Checkpoint-based persistence; graceful shutdown via Ctrl+C
- **Streaming mode**: Real-time item streaming with statistics
- **Blocked request detection**: Automatic retry logic
- **Robots.txt compliance**: Optional `robots_txt_obey` with per-domain caching
- **Development mode**: Response caching for iterative parsing
- **Built-in export**: JSON/JSONL format support

### Fetchers & Session Management
- **HTTP Requests** (`Fetcher`): TLS fingerprint impersonation, HTTP/3 support
- **Dynamic Loading** (`DynamicFetcher`): Playwright Chromium automation
- **Stealth Mode** (`StealthyFetcher`): Anti-bot bypass, Cloudflare Turnstile solving
- **Session Classes**: `FetcherSession`, `StealthySession`, `DynamicSession` for state management
- **Proxy rotation**: Built-in `ProxyRotator` with cyclic strategies
- **Domain/ad blocking**: Block specific domains or ~3,500 ad/tracker sites
- **DNS-over-HTTPS**: Cloudflare DoH support for proxy users
- **Full async support**: Async variants of all sessions

### Adaptive Scraping & AI
- **Smart element tracking**: Relocates elements after design changes using similarity algorithms
- **Flexible selection**: CSS, XPath, filter-based, text-based, regex search
- **Element similarity**: Auto-locate similar elements
- **MCP server**: AI integration for Claude/Cursor with custom Scrapling capabilities

### Performance & Architecture
- Outperforms most Python scraping libraries
- 92% test coverage with full type hints
- 10x faster JSON serialization than stdlib
- Memory-efficient with lazy loading
- Battle-tested by hundreds of users daily

### Developer Experience
- **Interactive shell**: IPython-based with curl-to-Scrapling conversion
- **CLI without code**: Terminal-based scraping without Python scripts
- **Rich navigation**: Parent/sibling/child traversal methods
- **Auto-selector generation**: Generate robust CSS/XPath selectors
- **Familiar API**: Similar to Scrapy/BeautifulSoup
- **Type hints**: Full IDE support via PyRight/MyPy scanning
- **Docker image**: Pre-built with all browsers

---

## Differentiation from Other Libraries

| Aspect | Scrapling | Comparison |
|--------|-----------|-----------|
| **Adaptive tracking** | Smart element relocation | BeautifulSoup/lxml: static selectors only |
| **Anti-bot bypass** | Built-in Cloudflare Turnstile | Selenium/Playwright: manual setup |
| **Spider framework** | Unified sync/async with multi-session | Scrapy: HTTP-only by default |
| **Pause/resume** | Checkpoint persistence | Most libraries: restart from scratch |
| **Stealth mode** | TLS fingerprint spoofing, headless | Playwright: requires configuration |
| **Proxy rotation** | Native support across all fetchers | BeautifulSoup: no built-in support |
| **MCP integration** | AI-assisted extraction | No competitors offer this |
| **CLI capability** | Extract without Python code | Unique to Scrapling |

---

## Performance Benchmarks

### Text Extraction (5000 nested elements)

| Rank | Library | Time (ms) | vs Scrapling |
|------|---------|----------|--------------|
| 1 | Scrapling | 1.98 | 1.0x |
| 2 | Parsel/Scrapy | 1.99 | 1.005x |
| 3 | Raw Lxml | 2.48 | 1.253x |
| 4 | PyQuery | 23.15 | ~12x |
| 5 | Selectolax | 196.09 | ~99x |
| 6 | MechanicalSoup | 1531.24 | ~773.4x |
| 7 | BS4 with Lxml | 1535.19 | ~775.3x |
| 8 | BS4 with html5lib | 3388.16 | ~1711.2x |

### Element Similarity & Text Search

| Library | Time (ms) | vs Scrapling |
|---------|----------|--------------|
| Scrapling | 2.29 | 1.0x |
| AutoScraper | 12.46 | 5.441x |

---

## Installation

### Basic Installation
```bash
pip install scrapling
```
*Note: Parser-only; fetchers/spiders require additional dependencies.*

### With Fetchers & Browsers
```bash
pip install "scrapling[fetchers]"
scrapling install           # normal install
scrapling install --force   # force reinstall
```

### Optional Features
```bash
pip install "scrapling[ai]"      # MCP server
pip install "scrapling[shell]"   # Interactive shell
pip install "scrapling[all]"     # Everything
```

### Docker
```bash
docker pull pyd4vinci/scrapling
# or
docker pull ghcr.io/d4vinci/scrapling:latest
```

---

## Usage Examples

### Basic HTTP Requests
```python
from scrapling.fetchers import Fetcher, FetcherSession

with FetcherSession(impersonate='chrome') as session:
    page = session.get('https://quotes.toscrape.com/', stealthy_headers=True)
    quotes = page.css('.quote .text::text').getall()

# One-off requests
page = Fetcher.get('https://quotes.toscrape.com/')
quotes = page.css('.quote .text::text').getall()
```

### Stealth Mode (Anti-bot)
```python
from scrapling.fetchers import StealthyFetcher, StealthySession

with StealthySession(headless=True, solve_cloudflare=True) as session:
    page = session.fetch('https://nopecha.com/demo/cloudflare')
    data = page.css('#padded_content a').getall()

# One-off request
page = StealthyFetcher.fetch('https://nopecha.com/demo/cloudflare')
```

### Dynamic/JavaScript Rendering
```python
from scrapling.fetchers import DynamicFetcher, DynamicSession

with DynamicSession(headless=True, network_idle=True) as session:
    page = session.fetch('https://quotes.toscrape.com/', load_dom=False)
    data = page.xpath('//span[@class="text"]/text()').getall()

page = DynamicFetcher.fetch('https://quotes.toscrape.com/')
```

### Spider Framework
```python
from scrapling.spiders import Spider, Response

class QuotesSpider(Spider):
    name = "quotes"
    start_urls = ["https://quotes.toscrape.com/"]
    concurrent_requests = 10

    async def parse(self, response: Response):
        for quote in response.css('.quote'):
            yield {
                "text": quote.css('.text::text').get(),
                "author": quote.css('.author::text').get(),
            }

        next_page = response.css('.next a')
        if next_page:
            yield response.follow(next_page[0].attrib['href'])

result = QuotesSpider().start()
result.items.to_json("quotes.json")
```

### Multi-Session Spider
```python
from scrapling.spiders import Spider, Request, Response
from scrapling.fetchers import FetcherSession, AsyncStealthySession

class MultiSessionSpider(Spider):
    name = "multi"
    start_urls = ["https://example.com/"]

    def configure_sessions(self, manager):
        manager.add("fast", FetcherSession(impersonate="chrome"))
        manager.add("stealth", AsyncStealthySession(headless=True), lazy=True)

    async def parse(self, response: Response):
        for link in response.css('a::attr(href)').getall():
            if "protected" in link:
                yield Request(link, sid="stealth")
            else:
                yield Request(link, sid="fast", callback=self.parse)
```

### Pause & Resume
```python
QuotesSpider(crawldir="./crawl_data").start()
# Press Ctrl+C to pause gracefully
# Restart with same crawldir to resume
```

### Advanced Parsing & Navigation
```python
from scrapling.fetchers import Fetcher

page = Fetcher.get('https://quotes.toscrape.com/')

# Multiple selection methods
quotes = page.css('.quote')                    # CSS
quotes = page.xpath('//div[@class="quote"]')   # XPath
quotes = page.find_all('div', class_='quote')  # BeautifulSoup-style
quotes = page.find_by_text('quote', tag='div') # Text search

# Navigation
quote_text = page.css('.quote')[0].css('.text::text').get()
first_quote = page.css('.quote')[0]
author = first_quote.next_sibling.css('.author::text')
parent = first_quote.parent

# Similarity & relationships
similar = first_quote.find_similar()
below = first_quote.below_elements()
```

### Using Parser Directly
```python
from scrapling.parser import Selector

page = Selector("<html>...</html>")
# Same API as fetchers
```

### Async Session Examples
```python
import asyncio
from scrapling.fetchers import FetcherSession, AsyncStealthySession

async with FetcherSession(http3=True) as session:
    page1 = session.get('https://quotes.toscrape.com/')
    page2 = session.get('https://quotes.toscrape.com/', impersonate='firefox135')

async with AsyncStealthySession(max_pages=2) as session:
    tasks = [session.fetch(url) for url in urls]
    print(session.get_pool_stats())  # Browser pool status
    results = await asyncio.gather(*tasks)
```

---

## Selection Methods

| Method | Example | Purpose |
|--------|---------|---------|
| **CSS** | `page.css('.quote .text::text').get()` | Standard CSS selectors |
| **XPath** | `page.xpath('//span[@class="text"]/text()')` | XML path expressions |
| **BeautifulSoup-style** | `page.find_all('div', class_='quote')` | Familiar interface |
| **Text search** | `page.find_by_text('quote', tag='div')` | Content-based finding |
| **Similarity** | `element.find_similar()` | Auto-locate similar elements |
| **Navigation** | `element.parent`, `.next_sibling`, `.below_elements()` | DOM traversal |

---

## Anti-Bot & Stealth Capabilities

- **TLS fingerprint spoofing**: Impersonate Chrome/Firefox browsers
- **Cloudflare Turnstile bypass**: Automatic CAPTCHA solving
- **Headless browser detection evasion**: Full stealth mode
- **Header spoofing**: Stealthy header injection
- **HTTP/3 support**: Modern protocol support
- **Proxy integration**: Native rotation across all fetchers
- **DNS leak prevention**: DNS-over-HTTPS routing

---

## AI & MCP Integration

- **MCP server**: Built-in Model Context Protocol server for AI assistants
- **AI-assisted extraction**: Works with Claude/Cursor
- **Custom capabilities**: Leverage Scrapling before passing to AI
- **Token efficiency**: Minimize AI token usage via pre-extraction
- **Reduced costs**: Extract targeted content before AI processing

---

## CLI Features

### Interactive Shell
```bash
scrapling shell
```

### Extract Without Code
```bash
# Extract body content to Markdown
scrapling extract get 'https://example.com' content.md

# Extract specific CSS selector
scrapling extract get 'https://example.com' content.txt --css-selector '#products'

# With impersonation
scrapling extract get 'https://example.com' content.md --impersonate 'chrome'

# Dynamic fetching
scrapling extract fetch 'https://example.com' content.md

# Stealth mode with Cloudflare bypass
scrapling extract stealthy-fetch 'https://nopecha.com/demo/cloudflare' captchas.html --solve-cloudflare
```

**Output formats**:
- `.txt`: Plain text extraction
- `.md`: Markdown representation
- `.html`: Raw HTML content

---

## Citation

```bibtex
@misc{scrapling,
  author = {Karim Shoair},
  title = {Scrapling},
  year = {2024},
  url = {https://github.com/D4Vinci/Scrapling},
  note = {An adaptive Web Scraping framework...}
}
```

---

## Project Stats

- **70.9k+ GitHub stars**
- **7k+ forks**
- **92% test coverage**
- **Full type hint coverage**
- **49 releases** (as of v0.4.11, July 2026)
- **1,533 commits**
- **Python 3.10+** required
- **BSD-3-Clause License**

---

## Sponsorship & Support

**Platinum Sponsors**: DataImpulse, NodeMaven, Proxidize, ColdProxy, Hyper Solutions, Evomi, TikHub, PetroSky, The Web Scraping Club, Swiftproxy

**Regular Sponsors**: SerpApi, Decodo, HasData, ProxyEmpire, Webshare, Proxiware

**Community**: Discord, X/Twitter, GitHub Discussions
