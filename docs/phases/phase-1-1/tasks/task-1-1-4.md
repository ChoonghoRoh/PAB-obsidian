---
task_id: "1-1-4"
title: "Obsidian CLI 4 명령 smoke test"
domain: WIKI-CLI
owner: backend-dev
priority: P0
estimate_min: 10
status: pending
depends_on: ["1-1-1", "1-1-2", "1-1-3"]
blocks: ["1-1-5"]
---

# Task 1-1-4 — Obsidian CLI 4 명령 smoke test

## 목적

Obsidian CLI가 본 vault(`wiki/`)에 대해 정상 동작하는지 4 명령으로 확인. 향후 Phase 1-4 자동화의 기반이 된다.

## 검증 명령 (4건)

### 1. `obsidian files` — 파일 enumeration

```bash
obsidian files --vault "$(pwd)/wiki"
```

**기대**: 빈 vault → `_attachments`/`.gitkeep` 정도만 나오거나 빈 응답. 에러 없이 종료(exit 0).

### 2. `obsidian search` — 검색

```bash
obsidian search "INDEX" --vault "$(pwd)/wiki"
```

**기대**: 빈 vault → 결과 0건. `_INDEX.md`가 T-5에서 만들어진 후에는 1건 매칭. 본 단계에서는 0건이 정상.

### 3. `obsidian tags` — 태그 enumeration

```bash
obsidian tags --vault "$(pwd)/wiki"
```

**기대**: 빈 vault → 빈 응답.

### 4. `obsidian unresolved` — broken link 검출

```bash
obsidian unresolved --vault "$(pwd)/wiki"
```

**기대**: 빈 vault → 빈 응답.

## 실행 절차

각 명령을 순차 실행하고 stdout + stderr + exit code를 캡처:

```bash
mkdir -p docs/phases/phase-1-1/reports
{
  echo "# CLI Smoke Test — $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## 1. obsidian files"
  echo '```'
  obsidian files --vault "$(pwd)/wiki" 2>&1
  echo "exit: $?"
  echo '```'
  echo
  echo "## 2. obsidian search 'INDEX'"
  echo '```'
  obsidian search "INDEX" --vault "$(pwd)/wiki" 2>&1
  echo "exit: $?"
  echo '```'
  echo
  echo "## 3. obsidian tags"
  echo '```'
  obsidian tags --vault "$(pwd)/wiki" 2>&1
  echo "exit: $?"
  echo '```'
  echo
  echo "## 4. obsidian unresolved"
  echo '```'
  obsidian unresolved --vault "$(pwd)/wiki" 2>&1
  echo "exit: $?"
  echo '```'
} > docs/phases/phase-1-1/reports/cli-smoke-test.md
```

## 완료 기준

- [ ] 4 명령 모두 exit 0
- [ ] `reports/cli-smoke-test.md` 생성
- [ ] 모든 stdout 캡처

## 위험

- **R-3**: `obsidian` 명령이 GUI 앱을 띄움 → 응답 안 옴. 완화: `--no-gui` 또는 daemon 모드 옵션 확인. 안 되면 `obsidiantools` Python 폴백.
- **R-4**: `--vault` 인자명이 다를 수 있음 (`-v` 등). 첫 명령(`obsidian files`)에서 에러 나면 `obsidian help files` 호출하여 실제 옵션 확인 후 적용.
- **R-5**: 명령 자체가 미존재 → CLI 등록 미완료(T-1 검증 누락). T-1 재실행.

## 폴백 절차 (R-3 발생 시)

CLI가 GUI를 띄워 hang 되면:
1. `pkill -f Obsidian` 또는 GUI 종료
2. `obsidian --help` 재확인
3. 폴백: Python `obsidiantools.api.Vault` 사용 (Phase 1-4에서 정식 도입 예정)
4. 본 task는 PARTIAL로 종료, 보고서에 사유 명시
