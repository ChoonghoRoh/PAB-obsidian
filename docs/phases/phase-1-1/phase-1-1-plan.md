---
phase: "1-1"
type: plan
created: 2026-05-01
master_plan_ref: docs/phases/phase-1-master-plan.md
---

# Phase 1-1 Plan — Obsidian CLI + Vault 초기화

## 목표

Obsidian 공식 CLI를 macOS에 등록하고, 프로젝트 내 `wiki/` 디렉터리를 Obsidian vault로 초기화한다. 이후 Phase가 의존하는 **모든 인프라**를 마련한다.

## 완료 기준 (Definition of Done)

| # | 기준 | 검증 방법 |
|---|---|---|
| DoD-1 | `which obsidian` → `/usr/local/bin/obsidian` 반환 | Bash |
| DoD-2 | `obsidian --version` 정상 출력 | Bash |
| DoD-3 | `wiki/.obsidian/` 디렉터리 존재 | ls |
| DoD-4 | `wiki/` 하위 7 폴더(`00_MOC`, `10_Notes`, `20_Lessons`, `30_Constraints`, `40_Templates`, `99_Inbox`, `_attachments`) 존재 | ls |
| DoD-5 | `obsidian files --vault wiki` 응답 정상 | Bash |
| DoD-6 | `obsidian search "INDEX" --vault wiki` 결과 ≥1건 | Bash |
| DoD-7 | `wiki/_INDEX.md` 존재, frontmatter 11필드 포함 | Read |
| DoD-8 | `wiki/.obsidian/app.json`, `core-plugins.json`, `appearance.json` 존재 | ls |

## 접근 방식

### 1. 사용자 협조 단계 (T-1)

Obsidian CLI 등록은 macOS sudo 권한이 필요하므로 **Team Lead 또는 backend-dev가 자동 수행 불가**. 사용자에게 다음을 안내:

```
! obsidian register
```

(`!` 프리픽스로 본 세션 내 직접 실행 → stdout이 컨텍스트로 흡수됨)

만약 Obsidian 데스크톱 앱이 설치되어 있지 않으면:
- 사용자에게 https://obsidian.md 다운로드 안내 → BLOCKER 등록 → 설치 완료 후 해제

### 2. Vault 초기화 (T-2 ~ T-3)

`wiki/` 디렉터리를 Obsidian vault로 초기화. macOS 내 첫 vault 열기 시 Obsidian 앱이 `.obsidian/` 폴더를 자동 생성하지만, **CLI-only**로 구축하기 위해 다음 핵심 파일을 사전 작성:

- `wiki/.obsidian/app.json` — 기본 vault 설정 (`alwaysUpdateLinks: true`, `useMarkdownLinks: false`, `newFileLocation: "folder"`, `newFileFolderPath: "99_Inbox"`)
- `wiki/.obsidian/core-plugins.json` — 활성화 코어 플러그인 (`file-explorer`, `global-search`, `switcher`, `graph`, `backlink`, `outline`, `tag-pane`, `templates`, `outgoing-link`, `properties`)
- `wiki/.obsidian/appearance.json` — `enabledCssSnippets: []`, default theme

7 폴더를 `mkdir -p`로 생성.

### 3. CLI Smoke Test (T-4)

설치된 CLI가 정상 동작하는지 4 명령으로 확인:
- `obsidian files --vault wiki` — 파일 enumeration
- `obsidian search "INDEX" --vault wiki` — 검색
- `obsidian tags --vault wiki` — 태그 목록 (빈 vault → 빈 응답이 정상)
- `obsidian unresolved --vault wiki` — broken link (빈 vault → 빈 응답이 정상)

각 명령 stdout/stderr를 `docs/phases/phase-1-1/reports/cli-smoke-test.md`에 기록.

### 4. 진입점 노트 (T-5)

`wiki/_INDEX.md`를 작성. 11필드 frontmatter + placeholder 본문(Phase 1-3에서 3중 인덱스로 갱신될 예정).

```yaml
---
title: "PAB Wiki — Index"
description: "PAB Obsidian Karpathy-style Wiki 최상위 진입점. TYPES/DOMAINS/TOPICS 3중 인덱스로 분기."
created: 2026-05-01 00:00
updated: 2026-05-01 00:00
type: "[[INDEX]]"
index: "[[ROOT]]"
topics: []
tags: [moc, root]
keywords: [pab-wiki, root-index, moc]
sources: []
aliases: ["MOC", "Root", "Wiki Home"]
---
```

## 작업 순서 (의존성)

```
T-1 (사용자 sudo)
  ↓
T-2 (vault 폴더) ─┐
T-3 (.obsidian)  ─┤→ T-4 (smoke test) → T-5 (_INDEX.md)
                  ┘
```

T-2와 T-3은 병렬 가능. 이후 T-4 → T-5 순.

## 위험 + 완화

| # | 위험 | 완화 |
|---|---|---|
| R-1 | Obsidian 앱 미설치 | T-1 시작 전 `which obsidian || ls /Applications/Obsidian.app` 사전 점검 |
| R-2 | sudo 비밀번호 입력 실패 | 사용자 직접 실행 (`!` 프리픽스) — 자동화 불가 명시 |
| R-3 | `.obsidian/` 직접 작성한 JSON 형식 오류 | T-3 종료 시 `python3 -c "import json; json.load(open(...))"` 검증 |
| R-4 | `obsidian` 명령이 GUI 앱을 띄움 (CLI 응답 안 옴) | T-4에서 `--no-gui` 또는 daemon 모드 옵션 확인. 안 되면 폴백 (`obsidiantools` Python) |

## 산출물

- `wiki/.obsidian/app.json`, `core-plugins.json`, `appearance.json`
- `wiki/{00_MOC,10_Notes,20_Lessons,30_Constraints,40_Templates,99_Inbox,_attachments}/` (빈 폴더 + `.gitkeep`)
- `wiki/_INDEX.md`
- `docs/phases/phase-1-1/reports/cli-smoke-test.md` (CLI 응답 로그)
- `docs/phases/phase-1-1/reports/report-backend-dev.md` (작업 보고)
- `docs/phases/phase-1-1/reports/report-verifier.md` (G2_wiki 검증 보고)

## 검증 게이트

- **G2_wiki**:
  - vault 구조 정합성 (DoD-3, DoD-4)
  - CLI 응답 정상 (DoD-5, DoD-6)
  - `_INDEX.md` frontmatter 11필드 (DoD-7)
- **G3 (E-4 비적용)**: 본 sub-phase 비검증
- **G4**: G2_wiki PASS 시 자동 PASS
