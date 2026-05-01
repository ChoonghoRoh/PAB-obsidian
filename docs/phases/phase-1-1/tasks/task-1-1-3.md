---
task_id: "1-1-3"
title: "프로젝트 루트 .obsidian/ 핵심 설정 파일 검증·튜닝"
domain: WIKI-INFRA
owner: backend-dev
priority: P0
estimate_min: 10
status: pending
depends_on: ["1-1-1"]
blocks: ["1-1-4"]
---

# Task 1-1-3 — 프로젝트 루트 `.obsidian/` 핵심 설정 파일 검증·튜닝

## 배경

vault.path = 프로젝트 루트 (`/Users/map-rch/WORKS/PAB-obsidian`)이며, Obsidian 앱 첫 실행 시 자동으로 프로젝트 루트에 `.obsidian/` 폴더가 생성된 상태. 자동 생성된 설정은 default 값이므로 본 프로젝트 정책에 맞춰 3종 핵심 설정을 덮어쓴다.

## 작성 파일 (모두 프로젝트 루트 `.obsidian/` 위치)

### 1. `.obsidian/app.json`

```json
{
  "alwaysUpdateLinks": true,
  "newFileLocation": "folder",
  "newFileFolderPath": "wiki/99_Inbox",
  "useMarkdownLinks": false,
  "attachmentFolderPath": "wiki/_attachments",
  "showLineNumber": true,
  "spellcheck": false,
  "promptDelete": true
}
```

**핵심 의도**:
- `alwaysUpdateLinks: true` — 노트 이동 시 wikilink 자동 갱신 (링크 그래프 무결성)
- `useMarkdownLinks: false` — `[[wikilink]]` 사용 (Karpathy 방식)
- `newFileLocation: "folder"` + `newFileFolderPath: "wiki/99_Inbox"` — 새 노트는 wiki/99_Inbox로 (vault root 기준 상대경로)
- `attachmentFolderPath: "wiki/_attachments"` — 이미지·첨부 폴더 통일 (vault root 기준 상대경로)

### 2. `.obsidian/core-plugins.json`

> **명세 정정 (2026-05-01, Phase 1-1 verifier 권고)**: Obsidian v1.12.7는 배열이 아닌 **객체 형식** 사용. 다음과 같이 작성한다 (각 플러그인 키를 `true`로 설정).

```json
{
  "file-explorer": true,
  "global-search": true,
  "switcher": true,
  "graph": true,
  "backlink": true,
  "outgoing-link": true,
  "tag-pane": true,
  "outline": true,
  "templates": true,
  "properties": true,
  "command-palette": true,
  "markdown-importer": true
}
```

**핵심 플러그인**:
- `properties` — frontmatter 속성 패널 (스크린샷의 "속성" UI)
- `outline` — 노트 TOC 사이드바
- `graph` — 링크 그래프 시각화
- `backlink` + `outgoing-link` — 양방향 링크 추적
- `templates` — 템플릿 삽입

### 3. `.obsidian/appearance.json`

```json
{
  "baseFontSize": 16,
  "enabledCssSnippets": [],
  "theme": "obsidian",
  "translucency": false
}
```

**의도**: 테마는 사용자 취향이므로 default로 설정. 향후 사용자가 직접 변경.

## 실행 절차

```bash
# .obsidian 폴더는 이미 존재 (Obsidian 첫 실행 시 자동 생성됨)
# 자동 생성된 빈 JSON을 위 내용으로 덮어쓴다 (Write 도구 사용)

# 검증
python3 -c "
import json
for p in ['.obsidian/app.json', '.obsidian/core-plugins.json', '.obsidian/appearance.json']:
    with open(p) as f:
        json.load(f)
        print(f'OK: {p}')
"
```

## 완료 기준

- [ ] 3 파일 모두 존재 (프로젝트 루트 `.obsidian/`)
- [ ] 모두 valid JSON (Python `json.load` 통과)
- [ ] `app.json`에 위 8 키 포함
- [ ] `core-plugins.json`에 12 플러그인 포함
- [ ] `appearance.json`에 4 키 포함

## 보고

backend-dev는 `reports/report-backend-dev.md`의 §T-3 섹션에 검증 스크립트 출력 캡처.

## 위험

- JSON 형식 오류 → 검증 스크립트로 사전 검출
- `core-plugins.json`은 객체 형식 `{"plugin": true, ...}` 사용 (Obsidian v1.12.7 실제 형식, 배열은 구형)
- Obsidian 앱이 실행 중이면 사용자 변경이 덮어쓰기될 가능성 → 작성 전 앱 종료 권장 (또는 작성 후 앱 재실행)
