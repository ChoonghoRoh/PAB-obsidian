---
title: "Obsidian wiki → 웹서비스 레이어 전환 문제점 분석 (원본 토의)"
description: "현재 Obsidian+CouchDB LiveSync+pab-v4 LV0 구조를 별도 웹서비스 레이어로 전환할 때의 6대 리스크와 하이브리드 권고에 대한 세션 토의 전문(immutable 보존)."
created: 2026-06-23 22:22
updated: 2026-06-23 22:22
type: "[[SOURCE]]"
index: "[[ENGINEERING]]"
topics: ["[[WIKI_ARCHITECTURE]]", "[[LIVESYNC]]"]
tags: [source, wiki-architecture, livesync, web-service, migration]
keywords: [CouchDB, LiveSync, livesync-bridge, pab-v4, wiki-LV0, single-writer, conflict, 99_Inbox, mobile-capture]
sources: ["PAB-obsidian 세션 토의 2026-06-23 (대화 기반, 외부 URL 없음)"]
aliases: ["웹서비스 전환 토의 원본", "Web Service Migration Discussion"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층). 요약본은 [[10_Notes/2026-06-23_wiki_webservice_migration_risks]].

# Obsidian wiki → 웹서비스 레이어 전환 문제점 분석 (원본 토의)

## 질문

옵시디언 프로젝트는 Obsidian 앱을 활용해 wiki를 저장하는 프로젝트였는데, 현재 구조를 웹서비스로 변경해서 별도 서비스 레이어로 구성할 경우 문제점을 파악. 현재 pab-v4의 wiki LV0에 연결되어 서비스 중이고, 모바일 앱으로는 데이터를 수집하지 못하고 있음.

## 현재 구조 (데이터 흐름)

```
[Obsidian 앱 — 맥북/레노버/아이폰]   ← 편집 + 포맷 정의(.md/frontmatter/wikilink)
        │ LiveSync 플러그인 (청크 포맷)
        ▼
[CouchDB pab-llmdata]              ← 다기기 양방향 동기화 (Tailscale)
        │ livesync-bridge (단방향, R-1: 역방향 쓰기 금지)
        ▼
[/home/oceanui/pab-vault-mirror/*.md]  ← 평문 미러
        │ read-only 마운트
        ▼
[pab-v4 = wiki LV0]               ← scan(mtime) → embed → Qdrant RAG
```

핵심은 Obsidian이 단순 뷰어가 아니라 **(1) 편집 클라이언트이자 (2) 데이터 포맷의 정의자이자 (3) 동기화 프로토콜의 주체**라는 점. 웹서비스로 갈아끼우면 세 역할이 동시에 흔들린다.

## 웹서비스 별도 레이어 전환 시 문제점 6가지

### 1. CouchDB 데이터 포맷 종속 (가장 치명적)

CouchDB에 들어있는 건 평문 .md가 아니라 Obsidian LiveSync 플러그인의 청크(eden chunk) + 메타 문서 포맷이다. 평문 .md는 livesync-bridge가 나가는 쪽에서만 변환해 준다. 웹서비스가 CouchDB에 직접 쓰려면 LiveSync의 청크 프로토콜·revision 트리를 그대로 재현해야 하고, 안 그러면 Obsidian 클라이언트들이 그 노트를 못 읽거나 동기화가 깨진다. 사실상 플러그인 내부 구현을 역설계해야 하는 결합.

### 2. 두 번째 쓰기 경로 = 충돌 구조

현재 설계의 안정성은 "쓰기는 Obsidian만, 미러는 단방향"(R-1)이라는 단일 writer 원칙에서 나온다. 웹서비스가 수집·편집을 하면 writer가 둘이 된다 → CouchDB MVCC `_conflicts`, revision 충돌이 발생하고, Obsidian LiveSync 자체 충돌 처리를 외부 writer가 우회하게 된다. 미러를 직접 쓰면 이번엔 Obsidian 쪽에 그 노트가 영영 안 보인다.

### 3. 품질 로직(규약) 재구현 부담

이 wiki의 가치는 11필드 frontmatter + wikilink + MOC + Karpathy 3계층(원본/요약/스키마)에서 나온다. 그런데 이 검증·생성 로직은 Claude Code 스킬(`/pab:wiki`)과 Python 스크립트(`wiki.py link-check`, JSON Schema)에 있지 서비스에 있지 않다. 웹서비스는 TYPE/DOMAIN/TOPIC 자동분류, SOURCE-요약 쌍 생성, link-check를 전부 다시 구현해야 하고, 안 하면 데이터 품질이 무너진다.

### 4. pab-v4 LV0 연계 파급

LV0 ingest는 파일시스템 .md의 mtime 변동을 신호로, `10_Notes/15_Sources/20_Lessons` 경로 필터·dedup·SOURCE 쌍을 전제로 동작한다. 소스 레이어를 바꾸면 — 웹서비스가 미러에 직접 쓰든 CouchDB에 쓰든 — 이 mtime 신호·경로 규약·중복 제거가 깨질 위험이 있다. LV0를 건드리지 않으려면 결국 "웹서비스도 동일한 .md를 동일 경로에 mtime과 함께 떨군다"를 보장해야 하는데, 그러면 웹서비스가 얻는 이점이 줄어든다.

### 5. 네트워크·보안 경계 확장

현재는 전부 Tailscale 사설망(IP 한정 노출, CouchDB 공개 인터넷 차단) 안에 있다. 웹서비스는 본질적으로 HTTP 노출 레이어 → 인증·TLS·rate limit·세션이 새로 필요하고, 그동안 사설이던 vault가 공격 표면에 올라온다.

### 6. 로컬-우선·편집 UX·백업 경로 상실

- 로컬-우선: Obsidian은 오프라인·즉시 편집·"그냥 디스크 위 파일"의 내구성/이식성을 준다. 웹서비스는 네트워크 의존이라 이걸 잃는다.
- UX: graph view·backlink·canvas·live preview·플러그인은 공짜로 받는 것. 일부만 재구현해도 큰 공수이고 품질은 떨어진다.
- git 백업: 현재 노트는 git에 커밋된다. 소스 오브 트루스가 서비스 DB로 옮겨가면 이 백업·버전관리 경로를 다시 설계해야 한다.

## 모바일 수집 문제는 "별개"

핵심: 모바일 수집이 안 되는 것 때문에 전체 Obsidian 레이어를 웹서비스로 갈아끼울 필요는 없다. 수집(capture)과 저장·편집(store/edit)은 분리되는 문제다.

- 모바일 수집 실패 원인은 구조 문제가 아니라 운영 문제(아이폰 Obsidian + LiveSync + Tailscale 미검증, 폰 offline)에 가깝다.
- 이미 스택에 Telegram이 있다(`report_to_telegram.sh`, `Telegram /ingest <url>` 파이프라인). 모바일에서 텔레그램 봇으로 메모/URL을 던지면 → `99_Inbox/`에 .md로 떨구는 얇은 capture 엔드포인트만 추가하면, 무거운 웹서비스 없이 모바일 수집이 풀린다.
- 이렇게 하면 위 1~6번 리스크를 전부 회피하면서(쓰기 경로는 Inbox로 격리, 미러·LV0 미영향) 실제 가려운 부분만 해결된다.

## 권고 — 역할 분리형 하이브리드

전면 교체(rip-and-replace)보다 역할 분리형 하이브리드를 권한다.

| 레이어 | 담당 | 변경 |
|---|---|---|
| 저장·편집·동기화 | Obsidian + CouchDB LiveSync | 유지 (포맷·충돌·UX 리스크 회피) |
| 수집(capture) | Telegram 봇 → `99_Inbox/` 얇은 엔드포인트 | 신규 (모바일 문제 해결) |
| 읽기·서비스 | pab-v4 LV0 (미러 read-only) | 유지 |
| (선택) 외부 열람 | 미러 .md → 정적 웹 퍼블리시(읽기 전용) | 필요 시 추가 |

즉 "웹서비스로 쓰기까지 한다"가 아니라 수집은 얇게 추가, 열람은 읽기 전용으로 추가, 쓰기 단일성은 Obsidian에 유지하는 게 리스크 대비 효과가 가장 크다.
