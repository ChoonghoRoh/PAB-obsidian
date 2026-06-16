---
task: "2-1-5"
title: "per-machine 제외 정책 (.gitignore 정정)"
domain: "[INFRA]"
assignee: backend-dev
status: completed
---

# Task 2-1-5: per-machine 제외 정책

## 목표
LiveSync 동기화/git 추적에서 기기별 상태 파일을 제외해 churn·충돌을 막는다 (R-2).

## 작업
- `.gitignore` Obsidian 패턴이 루트 기준(`.obsidian/...`)이라 실제 vault `PAB-LLMDATA/.obsidian/...`에 미매칭 → **경로 정정**
- 대상: `workspace*.json`, `cache`, `graph.json`, `community-plugins.json`, `plugins/`, `themes/`, `snippets/`, `hotkeys.json`, `trash/`
- 중복 항목(`PAB-LLMDATA/.obsidian/workspace.json`) → `workspace*.json` 패턴으로 통합
- `plugins/` 통째 무시 유지 (LiveSync 플러그인은 기기별 LiveSync로 동기화)

## 검증
- 정정 후 `git status`에서 `community-plugins.json`, `plugins/` untracked 사라짐 확인

## 잔여
- `graph.json`/`workspace.json`은 과거 커밋되어 tracked 상태 → 추적 중단 원하면 `git rm --cached` 별도 필요 (이번엔 미수행)
