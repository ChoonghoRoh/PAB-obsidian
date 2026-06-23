---
title: "Obsidian wiki를 웹서비스 레이어로 전환할 때의 6대 리스크"
description: "Obsidian이 편집·포맷정의·동기화주체 3역할을 겸하는 구조를 별도 웹서비스로 분리할 때의 핵심 문제점과, 모바일 수집은 capture/store 분리로 푸는 하이브리드 권고."
created: 2026-06-23 22:22
updated: 2026-06-23 22:41
type: "[[CONCEPT]]"
index: "[[ENGINEERING]]"
topics: ["[[WIKI_ARCHITECTURE]]", "[[LIVESYNC]]"]
tags: [concept, wiki-architecture, livesync, web-service, migration, capture-store-separation, llm-synthesis-quality]
keywords: [CouchDB, LiveSync, livesync-bridge, pab-v4, wiki-LV0, single-writer, MVCC-conflict, mtime-ingest, 99_Inbox, mobile-capture, hybrid, synthesis-worker, claude-agent-sdk, headless-worker, remote-control, desktop-app]
sources: ["[[15_Sources/2026-06-23_wiki_webservice_migration_risks_source]]"]
aliases: ["웹서비스 전환 리스크", "Web Service Migration Risks", "wiki 레이어 분리"]
---

# Obsidian wiki를 웹서비스 레이어로 전환할 때의 6대 리스크

현재 wiki는 [[Obsidian]]이 단순 뷰어가 아니라 **편집 클라이언트 · 데이터 포맷 정의자 · 동기화 프로토콜 주체**의 3역할을 겸한다. 이를 별도 [[웹서비스]] 레이어로 갈아끼우면 세 역할이 동시에 흔들린다. 핵심은 — 전환 동기가 "모바일 수집"이라면 전체 교체는 과잉이며, 수집과 저장을 분리하는 [[하이브리드]]가 리스크 대비 효과가 가장 크다.

## 현재 구조

[원본 §현재 구조 데이터 흐름 →](2026-06-23_wiki_webservice_migration_risks_source.md#현재-구조-데이터-흐름)

`Obsidian 앱 → [[CouchDB]] LiveSync(다기기 양방향) → [[livesync-bridge]](단방향 미러) → [[pab-v4]] wiki LV0(read-only, mtime scan→embed→Qdrant)`. 쓰기는 Obsidian 한 곳, 미러는 [[단방향]](R-1: 역방향 쓰기 금지)이라는 단일 writer 원칙 위에 안정성이 서 있다.

## 리스크 1 — CouchDB 데이터 포맷 종속

[원본 §1 CouchDB 데이터 포맷 종속 가장 치명적 →](2026-06-23_wiki_webservice_migration_risks_source.md#1-couchdb-데이터-포맷-종속-가장-치명적)

CouchDB에는 평문 .md가 아니라 LiveSync 플러그인의 **청크(eden chunk) + 메타 문서** 포맷이 들어있다. 평문 변환은 livesync-bridge가 나가는 쪽에서만 해준다. 웹서비스가 직접 쓰려면 청크 프로토콜·revision 트리를 역설계·재현해야 하고, 실패하면 Obsidian 클라이언트가 노트를 못 읽는다. (가장 치명적)

## 리스크 2 — 두 번째 쓰기 경로 = 충돌 구조

[원본 §2 두 번째 쓰기 경로 충돌 구조 →](2026-06-23_wiki_webservice_migration_risks_source.md#2-두-번째-쓰기-경로--충돌-구조)

웹서비스가 수집·편집을 하면 writer가 둘이 된다 → CouchDB [[MVCC]] `_conflicts`·revision 충돌 발생, Obsidian LiveSync 자체 충돌 처리를 외부 writer가 우회. 미러를 직접 쓰면 그 노트는 Obsidian 쪽에 영영 안 보인다. 단일 writer 원칙이 깨지는 게 본질.

## 리스크 3 — 품질 로직(규약) 재구현 부담

[원본 §3 품질 로직 규약 재구현 부담 →](2026-06-23_wiki_webservice_migration_risks_source.md#3-품질-로직규약-재구현-부담)

wiki의 가치인 [[11필드 frontmatter]] · [[wikilink]] · [[MOC]] · [[Karpathy 3계층]] 검증/생성 로직은 `/pab:wiki` 스킬과 Python(`wiki.py link-check`, JSON Schema)에 있다. 웹서비스는 TYPE/DOMAIN/TOPIC 자동분류·SOURCE쌍 생성·link-check를 전부 재구현해야 하며, 안 하면 데이터 품질이 무너진다.

## 리스크 4 — pab-v4 LV0 연계 파급

[원본 §4 pab-v4 LV0 연계 파급 →](2026-06-23_wiki_webservice_migration_risks_source.md#4-pab-v4-lv0-연계-파급)

LV0 ingest는 파일시스템 .md의 **mtime 신호** + 경로필터(`10_Notes/15_Sources/20_Lessons`) + dedup + SOURCE쌍을 전제로 동작한다. 소스 레이어를 바꾸면 이 신호 체계가 깨질 위험. LV0를 안 건드리려면 결국 "동일 .md를 동일 경로에 mtime과 함께 떨군다"를 보장해야 해서 웹서비스 이점이 상쇄된다.

## 리스크 5 — 네트워크·보안 경계 확장

[원본 §5 네트워크 보안 경계 확장 →](2026-06-23_wiki_webservice_migration_risks_source.md#5-네트워크보안-경계-확장)

현재는 전부 [[Tailscale]] 사설망(CouchDB 공개 인터넷 차단) 안. 웹서비스는 HTTP 노출 레이어라 인증·TLS·rate limit이 새로 필요하고, 사설이던 vault가 공격 표면에 올라온다.

## 리스크 6 — 로컬-우선·편집 UX·git 백업 상실

[원본 §6 로컬-우선 편집 UX 백업 경로 상실 →](2026-06-23_wiki_webservice_migration_risks_source.md#6-로컬-우선편집-ux백업-경로-상실)

[[로컬-우선]] 오프라인·즉시편집·디스크파일 내구성, graph view·backlink·canvas, git 커밋 백업 경로를 잃는다. 일부만 재구현해도 큰 공수이고 품질은 열위.

## 심화 검토 — 진짜 병목은 인프라가 아니라 'LLM 요약 지능'

> 2026-06-23 추가 검토. 앞 리스크 1·2·4·5는 인프라 문제라 이식하면 풀린다. 그러나 **리스크 3의 핵심은 검증 스캐폴딩(frontmatter·link-check)이 아니라, 요약·스크랩을 실제로 수행하는 LLM 지능 그 자체**다. 지금 그 품질은 [[Claude Code]] 터미널이 보장한다 — 이 보장은 웹/타앱으로 옮기는 순간 자동으로 따라오지 않는다.

현재 품질을 만드는 (눈에 안 보이는) 자산:

| 자산 | 현재 (Claude Code) | 웹/타앱 전환 시 |
|---|---|---|
| 프론티어 모델 | Opus급 추론으로 TYPE/DOMAIN/TOPIC 분류·섹션 구조화·앵커 매핑 | 비용상 저가 모델 → 퀄리티 급락 위험 |
| 에이전트 루프 | [[WebFetch]] 전문(全文) 페치·실패 복구·다단계 보강 | 단발 API 호출이면 멀티스텝·재시도 소실 |
| 세션 컨텍스트 | "위에서 논의한 내용 정리" = 직전 대화 전체 활용 | 웹 폼은 입력창 텍스트만 → 컨텍스트 빈곤 |
| SKILL.md 하네스 | 12-step 절차가 런타임에서 강제 | system prompt로 이식해도 약한 모델은 미준수 |
| self-correct 검증 | 생성 직후 같은 에이전트가 link-check 돌려 교정 | 생성/검증 분리되면 루프 단절 |

**핵심 재정의**: "어디서 입력하나(프런트)"는 쉬운 문제이고, **"누가 요약하나([[synthesis worker]])"가 진짜 문제**다. 따라서 보존 전략은 프런트와 요약 워커를 분리하는 것:

| 옵션 | 방식 | 품질 |
|---|---|---|
| **A (권장)** | 웹/모바일은 입력·트리거만 → 작업 큐 → [[Claude Agent SDK]]/Claude Code headless(`claude -p`) 워커가 `/pab:wiki`를 그대로 실행 | **현재와 동일** (같은 모델·같은 SKILL.md) |
| B | 웹이 직접 [[Anthropic API]] 호출 + SKILL.md를 system prompt로 이식 + tool use(WebFetch/link-check) 재현 | 가능하나 에이전트 하네스 재구축이 운영 책임 |
| C (안티패턴) | 웹앱 내장 저가 LLM으로 요약을 떠안음 | 보장 불가 → 데이터 오염 |

**결론**: 요약 지능은 프런트가 아니라 **워커의 속성**이다. 웹 전환을 하더라도 synthesis 워커를 Claude Code/Agent SDK로 유지하면 품질은 보존된다. 진짜 안티패턴은 웹앱이 자체 LLM으로 요약을 떠안는 것 — 이건 아래 [[capture/store 분리]] 권고와 정확히 같은 결론으로 수렴한다(capture=웹/모바일, synthesis=Claude 워커).

## 실행 환경별 `/pab:wiki` 스킬 호환성

> 2026-06-23 추가 검토. "내가 만든 스킬을 모바일/PC 앱에서 쓸 수 있나"의 답. 핵심 — 스킬은 SKILL.md 파일만이 아니라 **[[Claude Code]] 런타임 + 로컬 vault·`wiki.py`·`WIKI_VAULT_ROOT`**에 묶여 있어 환경마다 갈린다.

| 환경 | 동작 | 핵심 이유 |
|---|---|---|
| **PC 데스크톱 앱** (Mac/Win) | ✅ 가능 | Claude Code 통합 — 로컬 파일·환경변수·bash·`wiki.py` 전부 접근 |
| **모바일 앱 — 직접** | ❌ 불가 | 모바일 앱은 claude.ai 챗 UI, Claude Code 런타임 없음 |
| **모바일 앱 — [[Remote Control]] 경유** | ✅ 조건부 | 로컬 PC를 Remote Control로 띄워 폰에서 원격 조종. **PC 상시 가동 전제** (Pro/Max) |
| **claude.ai Agent Skills** (SKILL.md 업로드) | ⚠️ 부분만 | 클라우드 sandbox — 로컬 vault·환경변수 접근 불가, zip 번들 스크립트만 |

**이 표가 "synthesis 워커" 명제를 재확인한다**: Remote Control은 옵션 A의 즉석 버전 — 폰(프런트)은 입력만, 실제 요약은 로컬 PC의 Claude Code 워커가 수행 → 품질 보존. 단 PC 상시 가동이라는 운영 제약이 붙는다. 이 제약을 없애려면 로컬 PC 대신 **항상 떠 있는 서버에 [[Claude Agent SDK]] / `claude -p` headless 워커**를 두고 모바일은 트리거만 보낸다.

→ 즉 "스킬을 모바일로 옮긴다"가 아니라 **"스킬을 상시 서버 워커로 만들고 모바일은 트리거만 보낸다"**가 현실적인 답. 당장 검증은 Remote Control이 가장 빠르다. 실제 PC 구현 절차는 [[10_Notes/2026-06-23_pab_wiki_pc_remote_worker_guide|PC 구현 가이드]] 참조.

## 모바일 수집은 별개 문제 — capture/store 분리

[원본 §모바일 수집 문제는 별개 →](2026-06-23_wiki_webservice_migration_risks_source.md#모바일-수집-문제는-별개)

모바일 수집 실패는 구조 문제가 아니라 운영 문제(아이폰 Obsidian+LiveSync+Tailscale 미검증)다. 이미 스택에 있는 [[Telegram]] 봇 → `99_Inbox/`에 .md를 떨구는 얇은 capture 엔드포인트만 추가하면 무거운 웹서비스 없이 모바일 수집이 풀린다. 쓰기 경로는 Inbox로 격리되어 리스크 1~6을 회피한다.

## 권고 — 역할 분리형 하이브리드

[원본 §권고 역할 분리형 하이브리드 →](2026-06-23_wiki_webservice_migration_risks_source.md#권고--역할-분리형-하이브리드)

| 레이어 | 담당 | 변경 |
|---|---|---|
| 저장·편집·동기화 | Obsidian + CouchDB LiveSync | 유지 |
| 수집(capture) | Telegram 봇 → `99_Inbox/` | 신규 |
| 읽기·서비스 | pab-v4 LV0 (미러 read-only) | 유지 |
| (선택) 외부 열람 | 미러 .md → 정적 웹 퍼블리시(읽기 전용) | 필요 시 |

전면 교체보다 **수집은 얇게 추가, 열람은 읽기 전용, 쓰기 단일성은 Obsidian에 유지**가 리스크 대비 효과 최대.
