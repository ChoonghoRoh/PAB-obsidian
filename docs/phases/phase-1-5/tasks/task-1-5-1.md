---
task_id: "1-5-1"
title: "pab plugin namespace 셋업"
domain: WIKI-SKILL
owner: backend-dev
priority: P0
estimate_min: 15
status: pending
depends_on: []
blocks: ["1-5-2", "1-5-3", "1-5-4"]
---

# Task 1-5-1 — `pab` plugin namespace 셋업

## 목적

Claude Code plugin 표준에 맞춰 PAB-obsidian 프로젝트에 `pab` namespace를 신설한다. 이후 모든 PAB skill (`/pab:wiki`, 향후 `/pab:report`, `/pab:research` 등)이 이 namespace를 통해 호출된다.

## 산출물

- `.claude-plugin/plugin.json` — PAB plugin 매니페스트
- `skills/wiki/` — wiki skill 디렉토리 (T-2에서 SKILL.md 작성)

## 표준 매니페스트

```json
{
  "name": "pab",
  "version": "0.1.0",
  "description": "PAB operational harness — SSOT skills for wiki, knowledge management",
  "author": {
    "name": "chroh",
    "email": "chroh1984@gmail.com"
  }
}
```

> 참고: `nexus` 프로젝트의 `.claude-plugin/plugin.json`과 동일한 `name: pab` 사용. 향후 두 프로젝트 간 skill 이전 시 namespace 충돌 회피를 위해 skill 이름은 `wiki-*`, `nexus-*` 등으로 자연스럽게 분리.

## 실행 절차

1. 프로젝트 루트에서 디렉토리 생성:
   ```bash
   mkdir -p .claude-plugin
   mkdir -p skills/wiki
   ```
2. `.claude-plugin/plugin.json` 작성 (위 표준 매니페스트 그대로)
3. JSON 유효성 검증:
   ```bash
   python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json')))"
   ```
4. 디렉토리 구조 확인:
   ```bash
   ls -la .claude-plugin/ skills/wiki/
   ```

## 완료 기준

- [ ] `.claude-plugin/plugin.json` 존재 + JSON 유효성 PASS
- [ ] 매니페스트 `name: "pab"` 확인
- [ ] `skills/wiki/` 디렉토리 존재 (빈 상태 가능)
- [ ] git status에 두 신규 항목 표시

## 보고

`reports/report-backend-dev.md` §T-1 섹션:
- 매니페스트 JSON 내용 (그대로)
- 디렉토리 구조 (tree 또는 ls 출력)

## 위험

- **L-1**: `.claude-plugin/` 가 이미 존재하는 경우 — 본 task 시작 시점 기준 미존재 확인 (Bash `ls`)
- Claude Code 세션 재시작 후에야 namespace 인식될 수 있음 — T-3에서 확인
