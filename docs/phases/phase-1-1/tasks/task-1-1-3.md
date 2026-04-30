---
task_id: "1-1-3"
title: ".obsidian/ 핵심 설정 파일 작성"
domain: WIKI-INFRA
owner: backend-dev
priority: P0
estimate_min: 10
status: pending
depends_on: ["1-1-1"]
blocks: ["1-1-4"]
---

# Task 1-1-3 — `.obsidian/` 핵심 설정 파일 작성

## 목적

Obsidian 앱이 vault를 인식할 수 있는 최소 설정 파일 3종을 사전 작성. 사용자가 처음 vault를 열어도 일관된 환경이 보장되도록 한다.

## 작성 파일

### 1. `wiki/.obsidian/app.json`

```json
{
  "alwaysUpdateLinks": true,
  "newFileLocation": "folder",
  "newFileFolderPath": "99_Inbox",
  "useMarkdownLinks": false,
  "attachmentFolderPath": "_attachments",
  "showLineNumber": true,
  "spellcheck": false,
  "promptDelete": true
}
```

**핵심 의도**:
- `alwaysUpdateLinks: true` — 노트 이동 시 wikilink 자동 갱신 (링크 그래프 무결성)
- `useMarkdownLinks: false` — `[[wikilink]]` 사용 (Karpathy 방식)
- `newFileLocation: "folder"` + `newFileFolderPath: "99_Inbox"` — 새 노트는 Inbox로
- `attachmentFolderPath: "_attachments"` — 이미지·첨부 폴더 통일

### 2. `wiki/.obsidian/core-plugins.json`

```json
[
  "file-explorer",
  "global-search",
  "switcher",
  "graph",
  "backlink",
  "outgoing-link",
  "tag-pane",
  "outline",
  "templates",
  "properties",
  "command-palette",
  "markdown-importer"
]
```

**핵심 플러그인**:
- `properties` — frontmatter 속성 패널 (스크린샷의 "속성" UI)
- `outline` — 노트 TOC 사이드바
- `graph` — 링크 그래프 시각화
- `backlink` + `outgoing-link` — 양방향 링크 추적
- `templates` — 템플릿 삽입

### 3. `wiki/.obsidian/appearance.json`

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
mkdir -p wiki/.obsidian
# 각 파일을 Write 도구로 생성 (위 JSON 내용)
# 또는 cat <<EOF > ... 사용

# 검증
python3 -c "
import json
for p in ['wiki/.obsidian/app.json', 'wiki/.obsidian/core-plugins.json', 'wiki/.obsidian/appearance.json']:
    with open(p) as f:
        json.load(f)
        print(f'OK: {p}')
"
```

## 완료 기준

- [ ] 3 파일 모두 존재
- [ ] 모두 valid JSON (Python `json.load` 통과)
- [ ] `app.json`에 위 8 키 포함
- [ ] `core-plugins.json`에 12 플러그인 포함
- [ ] `appearance.json`에 4 키 포함

## 보고

backend-dev는 `reports/report-backend-dev.md`의 §T-3 섹션에 검증 스크립트 출력 캡처.

## 위험

- JSON 형식 오류 → 검증 스크립트로 사전 검출
- `core-plugins.json`이 배열 형식이 아닌 객체로 저장 시 Obsidian이 무시 → 반드시 배열(`[...]`)
