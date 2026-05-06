---
title: "GreedySearch-pi — API 키 없이 헤드리스 브라우저로 Perplexity/Bing/Google AI 병렬 검색 (Pi + Claude Code 플러그인)"
description: "Apostolos Mantzaris의 멀티 엔진 web search 플러그인. 브라우저 자동화로 3개 AI 검색 엔진을 병렬 호출하고 Gemini가 합성. headless 기본 + 자동 visible 복구로 Bing Cloudflare 우회. Pi 패키지 + Claude Code 플러그인 듀얼 발행."
created: 2026-05-06 07:02
updated: 2026-05-06 07:02
type: "[[RESEARCH_NOTE]]"
index: "[[HARNESS]]"
topics: ["[[BROWSER_AUTOMATION]]", "[[WEB_SEARCH]]", "[[CLAUDE_CODE_PLUGIN]]"]
tags: [research-note, browser-automation, web-search, pi, claude-code, plugin, github]
keywords: ["GreedySearch", "Pi", "Perplexity", "Bing Copilot", "Google AI", "Gemini", "headless Chrome", "CDP", "Cloudflare Turnstile", "Mozilla Readability", "anti-detection", "stealth"]
sources:
  - "[[15_Sources/2026-05-06_greedysearch_pi_source]]"
  - "https://github.com/apmantza/GreedySearch-pi"
aliases: ["GreedySearch-pi", "greedy_search 도구", "apmantza GreedySearch"]
---

# GreedySearch-pi — API 키 없이 헤드리스 브라우저로 Perplexity/Bing/Google AI 병렬 검색

## TL;DR
[원본 §README full text →](2026-05-06_greedysearch_pi_source.md#readme-full-text)

- [[Apostolos Mantzaris]]가 만든 **멀티 엔진 AI web search 플러그인** — `Perplexity` + `Bing Copilot` + `Google AI`를 헤드리스 [[Chrome]]으로 병렬 호출, [[Gemini]]가 결과를 합성. **API 키 일체 불필요**.
- 작동 원리: 사용자가 브라우저로 검색하던 행동을 [[CDP]] (Chrome DevTools Protocol)로 자동화하고, 답변 텍스트를 클립보드/DOM에서 추출.
- **헤드리스 기본** (1.8.6 부터). [[Bing Copilot]]이 헤드리스를 차단하면 자동으로 visible Chrome으로 retry → [[Cloudflare Turnstile]] 쿠키를 프로파일에 캐시 → 이후 헤드리스도 통과.
- **듀얼 발행**: Pi 패키지(`@apmantza/greedysearch-pi` v1.8.6) + [[Claude Code]] 플러그인(`greedysearch` v1.7.4, `apmantza/GreedySearch-claude` 자매 repo로 자동 미러).
- 라이선스 [[MIT]], 2026-03-15 시작, 22 stars, 활발히 업데이트 중 (2026-05-05 마지막 push).

## 핵심 가치 — "No API keys" web search
[원본 §README full text →](2026-05-06_greedysearch_pi_source.md#readme-full-text)

- **다른 web search 도구와 차별점**: Perplexity/Bing/Google AI의 **공식 API 없음** 또는 유료 → 일반 사용자 브라우저처럼 페이지를 열고 답변을 긁어옴. 즉시 사용 가능.
- 트레이드오프: 안티봇·CAPTCHA·iframe 샌드박싱 등 "사람이 아닌 듯 보이면" 깨지는 영역과의 지속적 싸움. CHANGELOG가 그 싸움 기록 그 자체.
- 본질: **사용자 = LLM 에이전트 (Pi/Claude Code)** → 도구 = 검색엔진 → 매개 = 헤드리스 Chrome. LLM이 self-serve로 web evidence를 가져오는 흐름.

## 아키텍처 — 디렉토리별 책임
[원본 §File tree →](2026-05-06_greedysearch_pi_source.md#file-tree)

```
bin/         runtime CLIs — search.mjs, launch.mjs, launch-visible.mjs, cdp.mjs
extractors/  엔진별 자동화 — perplexity, bing-copilot, gemini, google-ai, google-search
             + common.mjs (CDP 헬퍼), consent.mjs (쿠키/검증 클릭), selectors.mjs
src/search/  파이프라인 — chrome 관리, source fetch, synthesis, output
src/         소스 페치 — fetcher.mjs (Readability), github.mjs (REST API), reddit.mjs (.json API)
src/tools/   greedy-search-handler.ts (Pi/Claude tool 핸들러)
src/formatters/  results.ts / sources.ts / synthesis.ts (출력 포매터)
skills/      Pi/Claude skill 메타 (greedy-search/skill.md)
.claude-plugin/  plugin.json + marketplace.json (Claude Code plugin 매니페스트)
.github/workflows/  ci, mirror-to-claude, sync-to-webaio (자동화)
```

- **언어 혼합**: `.mjs` (브라우저 자동화 핵심 코드, ESM JavaScript) + `.ts` (Pi tool 핸들러·포매터·타입 정의). 빌드 단계 거의 없는 가벼운 스택.
- **외부 의존**: 단 3종 — `@mozilla/readability` (콘텐츠 추출), `jsdom` (DOM 파싱), `turndown` (HTML→Markdown).

## 작동 모드 — headless 기본 + visible 자동 복구
[원본 §Visible Chrome Recovery →](2026-05-06_greedysearch_pi_source.md#visible-chrome-recovery)

| 모드 | 트리거 | 동작 |
|---|---|---|
| **Headless** (default) | 항상 | 백그라운드 Chrome, 5분 idle 자동 정리 (`GREEDY_SEARCH_IDLE_TIMEOUT_MINUTES`) |
| **Visible auto-recovery** | Bing 추출 실패 / Cloudflare 감지 | 헤드리스 종료 → visible로 재기동 → 사용자가 1회 Cloudflare 풀면 → 쿠키 캐시 → 다시 headless로 전환 |
| **Visible manual** | `GREEDY_SEARCH_VISIBLE=1` 또는 `bin/launch-visible.mjs` | 사용자가 명시적으로 visible 가동 |

- **모드 마커 파일** `greedysearch-chrome-mode`로 launch.mjs ↔ chrome.mjs 사이 모드 동기화. 잔존 chrome 프로세스에 대해서도 모드 검사 후 필요 시 재기동.
- **PID 기반 정리**: `port=9222`의 PID-tracked 인스턴스만 kill — 사용자의 메인 Chrome 세션은 절대 안 건드림 (격리 원칙).

## 안티 디텍션 — 사이트 JS 실행 *전*에 패치 주입
[원본 §Headless Mode (default) →](2026-05-06_greedysearch_pi_source.md#headless-mode-default)

`Page.addScriptToEvaluateOnNewDocument` API로 페이지 JavaScript가 시작되기 전에 다음 패치 주입:

| 영역 | 패치 |
|---|---|
| Navigator | `webdriver: false`, `plugins` 가짜 리스트, `languages: ['en-US','en']` |
| Window | `window.chrome` shim, `TrustedTypes` 정책 |
| WebGL | vendor → "Intel Iris" 스푸핑 |
| Hardware | `hardwareConcurrency: 8`, `deviceMemory: 8` |
| CDP markers | `__REBROWSER_*`, `__nightmare`, `__phantom` 흔적 삭제 |
| Animation | `requestAnimationFrame` keep-alive (헤드리스 정지 감지 회피) |
| Chrome flags | `--disable-blink-features=AutomationControlled`, 정상 UA, `--window-size=1920,1080` |

**사람 클릭 시뮬레이션**: 모든 검증 클릭이 [[CDP]] `Input.dispatchMouseEvent`로 mouseMoved → pressed → released 순서, ±3px 좌표 jitter, 80–180ms hover/30–90ms hold 랜덤 지연. Turnstile / reCAPTCHA / Cloudflare / MS auth / Copilot modal 모두 적용.

⚠️ **한계 명시**: 기본 [[navigator.webdriver]] 검사는 우회되지만 [[DataDome]], [[PerimeterX]], [[Kasada]] 같은 상업 안티봇 서비스는 무력화 못함. Bing Copilot이 그 대표 사례.

## Cloudflare 우회 — Bing Copilot 사례
[원본 §Bing Copilot →](2026-05-06_greedysearch_pi_source.md#bing-copilot)

**문제**: 헤드리스 모드 [[Bing Copilot]]은 AI 응답을 `copilot.microsoft.com` → `copilot.fun` → `blob:` 의 **중첩 iframe sandbox**에 격납하고 [[Cloudflare Turnstile]] 챌린지를 띄움. copy 버튼은 hidden 처리되어 클립보드 추출 불가능. cross-origin 때문에 main frame JS도 못 읽고, CDP iframe traversal도 Cloudflare가 load 자체를 차단.

**해결 — 5단계 자동 복구 시퀀스**:

1. headless 추출 실패 감지 (clipboard / verification / Cloudflare 패턴)
2. headless Chrome kill → **visible mode로 relaunch**
3. 진행 신호 stderr로 `PROGRESS:bing:needs-human` 송출 → Pi UI에 `🔓 bing needs manual verification`
4. 사용자가 **1회** Cloudflare Turnstile 클릭 → 쿠키가 Chrome 프로파일에 영속 저장
5. 검색 재시도 → 통과 → visible kill → headless 재기동

→ 다음 검색부터는 **headless에서도 통과** (쿠키 캐시 영속).

> 이 패턴은 우리 워크플로우에 시사점이 있다 — [[WebFetch]]가 Reddit/특정 사이트에서 차단된다면, 같은 idea로 visible-once → cookie cache → 이후 자동화 가능. 다만 *컨텍스트별 윤리·ToS 검토* 필수.

## 검색 깊이 — fast / standard / deep
[원본 §Depth modes →](2026-05-06_greedysearch_pi_source.md#depth-modes)

| Depth | 엔진 수 | Synthesis | Source Fetch | 시간 |
|---|---|---|---|---|
| `fast` | 1 | — | — | 15–30s |
| `standard` (default) | 3 | Gemini | — | 30–90s |
| `deep` | 3 | Gemini | top 5 | 60–180s |

**합의 vs 발산 휴리스틱**: skill.md에 명시 — *엔진 결과가 일치하면 high confidence, 발산하면 양쪽 관점 모두 노트*. LLM 에이전트가 사용 시점에 적용할 수 있는 가벼운 신뢰도 모델.

```js
greedy_search({ query: "React 19 changes" });                          // 기본 standard
greedy_search({ query: "Prisma vs Drizzle", engine: "all", depth: "fast" });
greedy_search({ query: "Best auth architecture 2026", depth: "deep" });
```

→ 1.8.6에서 `coding_task`와 `deep_research` 도구는 **삭제** — `greedy_search` + depth 파라미터로 일원화.

## 소스 페치 — Reddit/GitHub native API + Readability fallback
[원본 §Anti-detection →](2026-05-06_greedysearch_pi_source.md#anti-detection)

`depth: standard|deep`에서 합성 단계로 들어가기 전 **출처 콘텐츠 fetch**. 사이트별 전략:

| 출처 | 전략 | 이유 |
|---|---|---|
| **Reddit** | 공식 `.json` API 사용 (1.8.3 추가) | HTML 스크래핑보다 안정. 댓글 nesting 구조 유지 |
| **GitHub** | REST API (repo/README/file tree) | git clone 폐기 (1.7.7) — 2-5s vs 30-60s |
| **일반 웹** | [[Mozilla Readability]] | 본문 추출 + browser fallback (봇 차단 시) |
| **메타데이터** | `publishedTime`, `lastModified`, `byline`, `siteName`, `lang`, excerpt | Gemini synthesis prompt에 주입. 2년 이상 자료는 stale 경고 |

> 직전 Reddit 노트 작성 시 우리도 같은 `.json` 패턴을 수동으로 적용했음 — GreedySearch는 이를 도구화. 패턴 차용 가치 ↑.

## 듀얼 발행 — Pi + Claude Code 플러그인
[원본 §package.json (full) →](2026-05-06_greedysearch_pi_source.md#packagejson-full)

| 측면 | Pi 패키지 | Claude Code 플러그인 |
|---|---|---|
| 이름 | `@apmantza/greedysearch-pi` | `greedysearch` |
| 버전 | 1.8.6 | 1.7.4 |
| 진입점 | `index.ts` (Pi extension) | `.claude-plugin/plugin.json` |
| Skill 매니페스트 | `skills/greedy-search/skill.md` | 동일 (재사용) |
| Repo | `apmantza/GreedySearch-pi` (master) | `apmantza/GreedySearch-claude` (main) |
| 동기화 | — | **`mirror-to-claude.yml` GH Action** — pi master push 시마다 자동 미러 (1.7.5 추가) |

→ 한 코드베이스를 두 ecosystem에 발행. 공통 자산은 `skills/`와 핵심 `.mjs` 파일들. 플러그인 매니페스트만 분기.

→ 우리 PAB의 [[plugin namespace]] 운용에 참고할 패턴: **single source repo + auto-mirror to ecosystem-specific repo**.

## 보안·코드 품질 동향
[원본 §CHANGELOG.md — v1.8.6 (head sections) →](2026-05-06_greedysearch_pi_source.md#changelogmd--v186-head-sections)

- **CodeQL** — URL substring sanitization 6건 fix (1.8.5): `evilgithub.com` 같은 도메인 스푸핑 차단을 위해 `includes()`/`endsWith()` 대신 hostname 파싱.
- **SonarCloud** — 보안 핫스팟 review 20건, 이슈 batch fix ~52건 (1.8.6). `Math.random()` → `crypto.randomInt()`, `spawn("node",...)` → `spawn(process.execPath,...)` 등.
- **stdin pipe로 query 전달** (1.8.6) — 검색 쿼리·합성 prompt가 OS 프로세스 테이블에 노출되지 않도록 `--stdin` 플래그 + stdin pipe.
- **Workflow permissions 명시** (1.8.5) — `permissions: contents: read`로 GITHUB_TOKEN scope 최소화.
- **Dependabot** 정기 적용 — `basic-ftp`, `yaml`, `brace-expansion`, `protobufjs`, `fast-xml-parser`, `@mozilla/readability` 등.

→ 단순 hobby project가 아닌 **상용 보안 표준** 수준의 운용. 22 stars 대비 코드 품질 인프라가 매우 성숙.

## 활용 시사점 — 우리 워크플로우 관점
[원본 §README full text →](2026-05-06_greedysearch_pi_source.md#readme-full-text)

| 측면 | 시사점 |
|---|---|
| **WebFetch 차단 대응** | 직전 Reddit 노트 작성 시 [[WebFetch]]가 차단됨 → curl + JSON API fallback 수동 적용. GreedySearch는 같은 idea를 도구화 (visible-once cookie cache 패턴 포함) |
| **/pab:wiki 와의 보완** | wiki 노트는 *깊이 있는 1편* 정리. greedy_search는 *광범위한 1차 발견*. **순서**: greedy_search로 사방 훑기 → 가치 있는 source 선별 → /pab:wiki로 immutable 저장 |
| **dual-publish 패턴** | Pi 패키지 ↔ Claude Code 플러그인 자동 미러는 **PAB skill 배포 전략**에 직접 차용 가능. master push → mirror-to-X workflow |
| **headless ↔ visible 자동 전환** | LLM 에이전트가 안티봇 영역에 진입했을 때 *자동으로 사람 도움 요청*하는 UX 패턴 (`PROGRESS:bing:needs-human`). PAB의 NOTIFY 시스템과 결합 가능 |
| **Gemini synthesis 합의/발산 휴리스틱** | "엔진 합의 → high confidence, 발산 → both sides" — 우리 verifier 게이트의 다중 의견 종합에 응용 가능 |

→ **차용 가치 높은 항목**: ① mirror-to-claude.yml 패턴, ② visible-once cookie 캐시, ③ Reddit/GitHub native API 우선 페치, ④ stdin pipe로 query leak 방지.

→ **차용 신중 항목**: 안티봇 우회는 *해당 사이트의 ToS·로봇 정책* 검토 후. 단순 모방 금지.

## 한계 / 미해결
[원본 §Anti-detection →](2026-05-06_greedysearch_pi_source.md#anti-detection)

- 상업 안티봇 ([[DataDome]], [[PerimeterX]], [[Kasada]]) 통과 못함. 명시된 한계.
- Bing Copilot의 visible-once 패턴은 **사용자 1회 수동 클릭** 필요 — 완전 무인 자동화 아님.
- Chrome 프로파일 의존 — 쿠키 캐시는 사용자 머신에 종속. CI 환경 운영은 별도 설계 필요.
- `coding_task` / `deep_research` 도구 삭제 — 1.8.6 이전 통합 사용자는 호출 깨짐. `depth: deep`으로 마이그레이션 필요.
- 22 stars 소규모 프로젝트 — 활발하지만 1인 운영 (Apostolos Mantzaris). 운영 의존성 리스크 평가 필요.

## 관련 노트

- 직전 wiki 작업: [[2026-05-05_qwen36_27b_3090_218k_pn12|Qwen3.6-27B 218K + PN12 fix]] — 이 노트 작성 중 [[WebFetch]]의 Reddit 차단을 만나 curl + JSON fallback 사용. GreedySearch가 같은 idea를 도구화한 사례.
- vault 일반 가이드: [[2026-05-02_karpathy_llm_wiki|Karpathy LLM 외부 뇌 위키]]
