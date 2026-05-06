---
title: "GreedySearch-pi — README + skill.md + plugin.json + CHANGELOG v1.8.6 (원본)"
description: "apmantza/GreedySearch-pi 저장소의 공개 산출물(README, skill 메타, plugin manifest, 최신 CHANGELOG 일부)을 immutable 보존"
created: 2026-05-06 07:02
updated: 2026-05-06 07:02
type: "[[SOURCE]]"
index: "[[HARNESS]]"
topics: ["[[BROWSER_AUTOMATION]]", "[[WEB_SEARCH]]", "[[CLAUDE_CODE_PLUGIN]]"]
tags: [source, browser-automation, web-search, pi, claude-code, plugin]
keywords: ["GreedySearch", "Pi", "Perplexity", "Bing Copilot", "Google AI", "Gemini", "headless Chrome", "CDP", "Cloudflare", "Readability", "MIT"]
sources:
  - "https://github.com/apmantza/GreedySearch-pi"
aliases: ["GreedySearch-pi 원본", "greedysearch_pi_source"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy 3계층)

# Repo metadata

| 항목 | 값 |
|---|---|
| full_name | apmantza/GreedySearch-pi |
| description | Headless browser-automation to search Perplexity, Bing Copilot, and Google AI -- synthesized answers and ranked sources |
| author | Apostolos Mantzaris (apmantza@gmail.com) |
| language | JavaScript |
| created_at | 2026-03-15 |
| updated_at / pushed_at | 2026-05-05 |
| stars | 22 |
| default_branch | master |
| license | MIT |
| homepage | (none) |
| size | 780 KB |
| package version | 1.8.6 |
| plugin version | 1.7.4 |
| node engines | >=20.11.0 |
| sister repo | github.com/apmantza/GreedySearch-claude (auto-mirrored) |

# README full text

## GreedySearch for Pi

Multi-engine AI web search for Pi via browser automation.

- No API keys
- Real browser results (Perplexity, Bing Copilot, Google AI)
- Optional Gemini synthesis with source grounding
- Chrome runs headless by default — no window, purely background

## Install

```bash
pi install npm:@apmantza/greedysearch-pi
```

Or from git:

```bash
pi install git:github.com/apmantza/GreedySearch-pi
```

## Tools

- `greedy_search` — multi-engine AI web search
- `websearch` — lightweight DuckDuckGo/Brave search (via pi-webaio)
- `webfetch` / `webpull` — page fetching and site crawling (via pi-webaio)

## Quick usage

```js
greedy_search({ query: "React 19 changes" });
greedy_search({ query: "Prisma vs Drizzle", engine: "all", depth: "fast" });
greedy_search({
  query: "Best auth architecture 2026",
  engine: "all",
  depth: "deep",
});
// Headless is the default — no window. To see the browser:
// Set GREEDY_SEARCH_VISIBLE=1 before launching Pi
```

## Parameters (`greedy_search`)

- `query` (required)
- `engine`: `all` (default), `perplexity`, `bing`, `google`, `gemini`
- `depth`: `standard` (default), `fast`, `deep`
- `fullAnswer`: return full single-engine output instead of preview
- `headless`: set to `false` to show Chrome window (default: `true`)

## Environment variables

| Variable                             | Default       | Description                                               |
| ------------------------------------ | ------------- | --------------------------------------------------------- |
| `GREEDY_SEARCH_VISIBLE`              | (unset)       | Set to `1` to show Chrome window instead of headless      |
| `GREEDY_SEARCH_IDLE_TIMEOUT_MINUTES` | `5`           | Minutes of inactivity before auto-killing headless Chrome |
| `GREEDY_SEARCH_LOCALE`               | `en`          | Default result language (en, de, fr, es, ja, etc.)        |
| `CHROME_PATH`                        | auto-detected | Path to Chrome/Chromium executable                        |

## Depth modes

- `fast` - quickest, no synthesis/source fetching
- `standard` - balanced default for `engine: "all"` (synthesis + fetched sources)
- `deep` - strongest grounding and confidence metadata

## Runtime commands

```bash
# Headless (default, no GUI)
node ~/.pi/agent/git/GreedySearch-pi/bin/launch.mjs
node ~/.pi/agent/git/GreedySearch-pi/bin/launch.mjs --status
node ~/.pi/agent/git/GreedySearch-pi/bin/launch.mjs --kill

# Visible (show browser window — useful for one-time Cloudflare clearance)
node ~/.pi/agent/git/GreedySearch-pi/bin/launch-visible.mjs
node ~/.pi/agent/git/GreedySearch-pi/bin/launch-visible.mjs --kill

# Chrome auto-cleaned after 5 min idle (prevents OOM)
# Override: GREEDY_SEARCH_IDLE_TIMEOUT_MINUTES=10
```

## Requirements

- Chrome
- Node.js 20.11.0+ (22+ recommended)

## Known engine quirks

### Bing Copilot

Bing Copilot detects headless Chrome and sandboxes all AI responses inside nested iframes (`copilot.microsoft.com` → `copilot.fun` → `blob:`). In this mode the copy button is hidden and the Cloudflare Turnstile challenge blocks content delivery. The clipboard-based extraction cannot work.

**Auto-recovery:** When Bing fails with any extraction error (clipboard, verification, Cloudflare), GreedySearch automatically switches to **visible Chrome**, retries the search, and caches Cloudflare clearance cookies in the Chrome profile. You may need to solve the Cloudflare challenge **once** manually when the visible Chrome window appears. After that, all subsequent headless searches bypass the challenge — the cookies persist in the profile.

If you prefer to skip the auto-recovery delay, launch visible Chrome ahead of time:

```bash
node ~/.pi/agent/git/GreedySearch-pi/bin/launch-visible.mjs
```

## Anti-detection

Headless Chrome auto-injects stealth patches before any page JavaScript runs:

- `navigator.webdriver` hidden, plugins/languages faked, `window.chrome` shimmed
- WebGL vendor spoofed (Intel Iris), realistic hardware concurrency / memory
- CDP automation markers deleted, `requestAnimationFrame` kept alive
- Human-like click simulation with coordinate jitter and variable delays

This bypasses casual bot detection (basic `navigator.webdriver` checks) but does not defeat commercial anti-bot services (DataDome, PerimeterX, Kasada). **Bing Copilot specifically detects headless and sandboxes responses behind Cloudflare Turnstile** — see Known engine quirks for the auto-recovery mechanism.

When using `depth: "standard"` or `depth: "deep"`, source content is fetched and synthesized:

- **Reddit** — Uses Reddit's public `.json` API for posts and comments (no scraping)
- **GitHub** — Uses GitHub REST API for repos, READMEs, and file trees
- **General web** — Mozilla Readability extraction with browser fallback for bot-blocked pages
- **Metadata** — title, author/byline, site name, publish date, language, excerpt

## Project layout

- `bin/` — runtime CLIs (`search.mjs`, `launch.mjs`, `launch-visible.mjs`, `visible.mjs`, `cdp.mjs`)
- `extractors/` — engine-specific automation + stealth/consent handling
- `src/` — search pipeline, chrome management, source fetching, formatting
- `skills/` — Pi skill metadata

## Testing

Cross-platform test runner (Windows + Unix):

```bash
npm test              # run all tests
npm run test:quick    # skip slow tests
npm run test:smoke    # basic health check
```

Full bash test suite (Unix only):

```bash
npm run test:bash           # comprehensive tests
./test.sh parallel          # race condition tests
./test.sh flags             # flag/option tests
```

## License

MIT

# skills/greedy-search/skill.md (full text)

```yaml
---
name: greedy-search
description: Live web search via Perplexity, Bing, and Google AI in parallel. Use for library docs, recent framework changes, error messages, dependency selection, or anything where training data may be stale. NOT for codebase search.
---
```

## GreedySearch — Live Web Search

Runs Perplexity, Bing Copilot, and Google AI in parallel. Gemini synthesizes results.

## greedy_search

```
greedy_search({ query: "React 19 changes", depth: "standard" })
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `query` | string | required | Search question |
| `engine` | string | `"all"` | `all`, `perplexity`, `bing`, `google`, `gemini` |
| `depth` | string | `"standard"` | `fast`, `standard`, `deep` |
| `fullAnswer` | boolean | `false` | Full answer vs ~300 char summary |

| Depth | Engines | Synthesis | Source Fetch | Time |
|-------|---------|-----------|--------------|------|
| `fast` | 1 | — | — | 15-30s |
| `standard` | 3 | Gemini | — | 30-90s |
| `deep` | 3 | Gemini | top 5 | 60-180s |

**When engines agree** → high confidence. **When they diverge** → note both perspectives.

## coding_task (NOTE: removed in 1.8.6 — see CHANGELOG)

Second opinion from Gemini/Copilot on hard problems.

```
coding_task({ task: "debug race condition", mode: "debug", engine: "gemini" })
```

| Parameter | Type | Default | Options |
|-----------|------|---------|---------|
| `task` | string | required | — |
| `engine` | string | `"gemini"` | `gemini`, `copilot`, `all` |
| `mode` | string | `"code"` | `debug`, `plan`, `review`, `test`, `code` |
| `context` | string | — | Code snippet |

# .claude-plugin/plugin.json (full)

```json
{
  "name": "greedysearch",
  "version": "1.7.4",
  "description": "Multi-engine AI web search — Perplexity, Bing Copilot, and Google AI in parallel with Gemini synthesis. No API keys needed.",
  "author": {
    "name": "Apostolos Mantzaris",
    "email": "apmantza@gmail.com"
  },
  "repository": "https://github.com/apmantza/GreedySearch-claude",
  "license": "MIT",
  "keywords": ["search", "perplexity", "bing", "google", "gemini", "research", "web-search"],
  "skills": "./skills/"
}
```

# package.json (full)

```json
{
  "name": "@apmantza/greedysearch-pi",
  "version": "1.8.6",
  "description": "Headless multi-engine AI search (Perplexity, Bing Copilot, Google AI) via browser automation -- NO API KEYS needed. Extracts answers with sources, optional synthesis. Grounded AI answers from real browser interactions.",
  "type": "module",
  "keywords": ["pi-package"],
  "repository": {"type": "git", "url": "git+https://github.com/apmantza/GreedySearch-pi.git"},
  "author": "Apostolos Mantzaris",
  "image": "docs/banner.png",
  "license": "MIT",
  "scripts": {
    "test": "node test.mjs",
    "test:quick": "node test.mjs quick",
    "test:smoke": "node test.mjs smoke",
    "test:bash": "./test.sh",
    "test:bash:quick": "./test.sh quick",
    "test:bash:smoke": "./test.sh smoke"
  },
  "engines": {"node": ">=20.11.0"},
  "files": ["index.ts", "test.mjs", "bin/", "src/", "skills/", "extractors/", "CHANGELOG.md", "README.md", "docs/banner.png"],
  "pi": {"extensions": ["./index.ts"], "skills": ["./skills"]},
  "dependencies": {"@mozilla/readability": "^0.6.0", "jsdom": "^24.0.0", "turndown": "^7.1.2"},
  "peerDependencies": {"@mariozechner/pi-coding-agent": "*", "@sinclair/typebox": "*"}
}
```

# File tree

```
.claude-plugin/marketplace.json                              761
.claude-plugin/plugin.json                                   491
.github/workflows/ci.yml                                     1018
.github/workflows/mirror-to-claude.yml                       2594
.github/workflows/sync-to-webaio.yml                         2682
CHANGELOG.md                                                 27761
LICENSE                                                      1056
README-claude.md                                             2039
README.md                                                    5738
autoresearch.jsonl                                           1295
bin/cdp.mjs                                                  26889
bin/launch-visible.mjs                                       6042
bin/launch.mjs                                               11057
bin/search.mjs                                               15274
bin/visible.mjs                                              1574
docs/banner.png                                              111597
docs/banner.svg                                              4585
extractors/bing-copilot.mjs                                  8002
extractors/common.mjs                                        19269
extractors/consent.mjs                                       11979
extractors/gemini.mjs                                        4222
extractors/google-ai.mjs                                     3901
extractors/google-search.mjs                                 7402
extractors/perplexity.mjs                                    4317
extractors/selectors.mjs                                     2780
index.ts                                                     3456
package-lock.json                                            150631
package.json                                                 1235
scripts/run-tests.ps1                                        6097
skills/greedy-search/skill.md                                1623
sonar-project.properties                                     173
src/fetcher.mjs                                              16591
src/formatters/results.ts                                    2264
src/formatters/sources.ts                                    3225
src/formatters/synthesis.ts                                  2504
src/github.mjs                                               6721
src/reddit.mjs                                               5591
src/search/chrome.mjs                                        10079
src/search/constants.mjs                                     1494
src/search/defaults.mjs                                      756
src/search/engines.mjs                                       1816
src/search/fetch-source.mjs                                  7356
src/search/output.mjs                                        1392
src/search/sources.mjs                                       12876
src/search/synthesis-runner.mjs                              2925
src/search/synthesis.mjs                                     6350
src/tools/greedy-search-handler.ts                           3464
src/tools/shared.ts                                          4677
src/types.ts                                                 3247
src/utils/content.mjs                                        1739
src/utils/helpers.ts                                         953
test.mjs                                                     17217
test.sh                                                      32736
test/compare-fetch.mjs                                       9058
test/fetcher-cli.mjs                                         1709
test/urls.txt                                                636
```

# CHANGELOG.md — v1.8.6 (head sections)

## v1.8.6 — 2026-05-04

### Bing Copilot — Headless Cloudflare Recovery

- **Auto-retry triggers on all Bing failures** — Error pattern expanded from `input not found|verification` to include `clipboard` failures, so any extraction failure triggers the visible Chrome recovery.
- **Clipboard retry** — `bing-copilot.mjs` now retries clipboard extraction once with a 2s delay, matching the Perplexity extractor pattern.
- **Cloudflare detection** — If the clipboard is empty and the AI copy button is hidden, the extractor checks the accessibility tree for Cloudflare challenge text and logs it explicitly for faster diagnosis.
- **DOM extraction fallback** — If clipboard fails and the copy button is missing (headless anti-bot behavior), attempts direct text extraction from the `copilot.fun` → blob: iframe chain via CDP targets. Falls through to the visible auto-retry if Cloudflare blocks the iframe.
- **Investigation confirmed** — In headless mode, Copilot renders the AI response inside a `copilot.fun` → blob: iframe sandbox with a Cloudflare Turnstile challenge. The `copy-ai-message-button` (`data-testid`) is hidden. Content is unreachable from both the main frame JS (cross-origin) and CDP iframe traversal (Cloudflare blocks load). The only viable path is visible Chrome recovery — once cookies are cached in the profile, subsequent headless searches pass transparently.

### Visible Chrome Recovery

- **Mode-aware `ensureChrome()`** — `src/search/chrome.mjs` reads a mode marker file (`greedysearch-chrome-mode`) written by `launch.mjs`. When `GREEDY_SEARCH_VISIBLE=1` and Chrome is running headless, kills and relaunches in visible mode with a forced relaunch guard.
- **`launch.mjs` mode check on reuse** — When Chrome is already running and visible is requested (`GREEDY_SEARCH_VISIBLE=1`), checks the mode file. If headless, kills the running instance and launches visible.
- **`bin/launch-visible.mjs`** — Standalone visible Chrome launcher. Nukes any process on port 9222 (by PID file + port scan), launches Chrome without `--headless`, and writes `"visible"` to the mode file.
- **Progress notification** — When the auto-retry launches visible Chrome for manual Cloudflare verification, a `PROGRESS:bing:needs-human` line is emitted to stderr. Pi UI renders `🔓 bing needs manual verification`.

### Headless Mode (default)

- **Chrome now runs headless by default** — no window, no GUI, purely background. Set `GREEDY_SEARCH_VISIBLE=1` to show the browser window.
- **Anti-detection stealth** — Patches injected via `Page.addScriptToEvaluateOnNewDocument` (runs before any page JS):
  - `Runtime.enable` / CDP marker deletion (`__REBROWSER_*`, `__nightmare`, `__phantom`, etc.)
  - `navigator.webdriver` → `false`, `navigator.plugins` → realistic list, `navigator.languages` → `['en-US', 'en']`
  - `window.chrome` shim, WebGL vendor → Intel Iris, `hardwareConcurrency` → 8, `deviceMemory` → 8
  - `TrustedTypes` policy, `requestAnimationFrame` keep-alive (prevents headless stall detection)
  - `--disable-blink-features=AutomationControlled`, realistic `--user-agent`, `--window-size=1920,1080`
- **Human click simulation** — All verification/clicks now use CDP `Input.dispatchMouseEvent` with multi-event `mouseMoved→pressed→released`, ±3px coordinate jitter, and random delays (80–180ms hover, 30–90ms hold).
- **Idle auto-cleanup** — Headless Chrome auto-killed after `GREEDY_SEARCH_IDLE_TIMEOUT_MINUTES` (default 5 min) of inactivity. Kills only the PID-tracked instance on port 9222 — never touches the main Chrome session.

### Performance

- **Timeouts cut ~40–50%** across all extractors — typical search ~60–90s → ~30–45s.

### Security

- **SonarCloud security hotspots fixed** — replaced `Math.random()` with `crypto.randomInt()`; `spawn("node", ...)` → `spawn(process.execPath, ...)`.
- **Query/prompt leakage prevention** — Queries and synthesis prompts no longer appear in OS process tables. All `spawn()` calls now pipe query/prompt through stdin via `--stdin` flag instead of command-line arguments.

### Removed

- **`coding_task` tool removed** — `bin/coding-task.mjs`, `src/formatters/coding.ts`, registration deleted (644 lines).
- **`deep_research` tool removed** — handler, test, and `formatDeepResearch` + helpers deleted (521 lines). Use `greedy_search` with `depth: "deep"`.

# CHANGELOG — earlier versions (key items)

## v1.8.5 — 2026-04-29

- **CodeQL: Incomplete URL substring sanitization (6 alerts)** — Replaced loose `includes()` / `endsWith()` checks on raw URL strings with proper hostname parsing in `src/github.mjs`, `src/reddit.mjs`, `src/fetcher.mjs`, and `extractors/bing-copilot.mjs`. Prevents bypasses where arbitrary subdomains could spoof trusted domains (e.g. `evilgithub.com`, `reddit.com.evil.com`).
- **CodeQL: Resource exhaustion** — `cdp loadall` now bounds `intervalMs` to 100–30,000ms.
- **Dependabot security updates** — Bumped `basic-ftp`, `yaml`, `brace-expansion`, `protobufjs`, `fast-xml-parser`, and `@mozilla/readability`.

## v1.8.4 — 2026-04-27

- **Double-escaped enum params (issue #2)** — `pi-coding-agent` v0.70.2 wraps string enum values in extra quotes (e.g. `"all"` → `"\"all\""`) before validation, causing every `greedy_search`/`deep_research`/`coding_task` call to reject. Fixed by switching `engine`, `depth`, and `mode` parameters from `Type.Union([Type.Literal(...)])` to `Type.String()`, then stripping the extra quotes via shared `stripQuotes()` utility.

## v1.8.3 — 2026-04-24

- **Perplexity extraction fixed** — copy button selector returned the first matching button ("Copy question") instead of the answer copy button. Changed `.find()` to `.filter().pop()` to get the last matching button.
- **Reddit JSON API support** — Reddit post URLs now use Reddit's public `.json` API instead of HTML scraping. Falls back to HTTP fetch if API fails.

## v1.8.2 — 2026-04-20

- **Node.js test runner (`test.mjs`)** — cross-platform test runner that works on Windows, macOS, and Linux without requiring bash.
- **Added `engines` field** — `node: ">=20.11.0"` requirement for `import.meta.dirname` support.

## v1.8.0 — 2026-04-16

- **`cdpAvailable()` missing `baseDir` argument** — two callsites in `index.ts` (session_start handler and coding_task handler) were calling `cdpAvailable()` without the required `baseDir` parameter.
- **Duplicated `ENGINES` map removed** — `ENGINES` was defined identically in both `src/search/constants.mjs` and `src/search/engines.mjs`. Now `engines.mjs` imports and re-exports from `constants.mjs`.

## v1.7.7 — 2026-04-14

- **`--deep` flag leaking into queries** — `depth: "deep"` was passing `--deep` as a bare flag to `search.mjs`, which didn't recognize it and appended it to the query string.
- **GitHub fetch always failing** — `git clone` was being `await`-ed on a non-Promise `ChildProcess` object, so the clone never actually completed. Replaced git clone entirely with GitHub REST API calls (~2-5s vs 30-60s).
- **Rich source metadata** — HTTP-fetched sources now include `publishedTime`, `lastModified`, `byline`, `siteName`, and `lang`. Gemini is instructed to flag sources older than 2 years as potentially stale.

## v1.7.6 — 2026-04-11

- **Close Gemini synthesis tab** — after synthesis completes, the Gemini tab is now closed instead of merely activated, preventing stale tabs from accumulating across searches.

## v1.7.5 — 2026-04-10

- **Claude Code plugin** — added `.claude-plugin/plugin.json` and `marketplace.json` so GreedySearch can be installed directly as a Claude Code plugin via `claude plugin install`.
- **Auto-mirror GH Action** — every push to `GreedySearch-pi/master` automatically syncs to `GreedySearch-claude/main`, keeping the Claude plugin up to date.
