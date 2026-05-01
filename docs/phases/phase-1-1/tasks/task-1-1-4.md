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

Obsidian CLI가 본 vault(프로젝트 루트, `PAB-obsidian`)에 대해 정상 동작하는지 4 명령으로 확인. 향후 Phase 1-4 자동화의 기반이 된다.

## CLI 호출 규약 (확인된 실제 문법)

- vault 지정 없이 호출 시 default(open: true) vault 사용 — 본 프로젝트는 `PAB-obsidian` 단독이므로 인자 불필요
- 다른 vault를 명시적으로 지정하려면 `vault=<name>` (key=value 문법, 위치 인자 아님)
- 인자는 `key=value` 또는 단독 플래그 형태. 예: `obsidian search query="text"`
- Obsidian 데스크톱 앱이 실행 중이어야 CLI 응답 (앱이 명령을 처리)

## 검증 명령 (4건)

### 1. `obsidian files` — 파일 enumeration

```bash
obsidian files
```

**기대**: vault 내 `.md` 파일 목록 출력. wiki/ 7 폴더(빈 폴더 + .gitkeep) + SSOT/docs/.claude의 .md 파일들이 함께 enumeration됨 (vault root = 프로젝트 루트). 에러 없이 종료(exit 0).

### 2. `obsidian search` — 검색

```bash
obsidian search query="INDEX"
```

**기대**: T-5에서 `wiki/_INDEX.md` 작성 전 → SSOT 등 다른 .md에 "INDEX" 단어가 있을 수 있음. 에러 없이 종료.

### 3. `obsidian tags` — 태그 enumeration

```bash
obsidian tags
```

**기대**: 기존 SSOT/docs 노트의 frontmatter `tags`가 있으면 enumerate. 에러 없이 종료.

### 4. `obsidian unresolved` — broken link 검출

```bash
obsidian unresolved
```

**기대**: 기존 .md의 unresolved wikilink 검출 (있으면 출력, 없으면 빈 응답). 본 sub-phase는 broken link 정리가 목적이 아니므로 결과는 참고용. 에러 없이 종료.

## 실행 절차

각 명령을 순차 실행하고 stdout + stderr + exit code를 캡처:

```bash
mkdir -p docs/phases/phase-1-1/reports
{
  echo "# CLI Smoke Test — $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "vault: $(obsidian vault info=name 2>&1)"
  echo "vault path: $(obsidian vault info=path 2>&1)"
  echo
  echo "## 1. obsidian files"
  echo '```'
  obsidian files 2>&1 | head -50
  echo "exit: $?"
  echo '```'
  echo
  echo '## 2. obsidian search query="INDEX"'
  echo '```'
  obsidian search query="INDEX" 2>&1 | head -30
  echo "exit: $?"
  echo '```'
  echo
  echo "## 3. obsidian tags"
  echo '```'
  obsidian tags 2>&1 | head -30
  echo "exit: $?"
  echo '```'
  echo
  echo "## 4. obsidian unresolved"
  echo '```'
  obsidian unresolved 2>&1 | head -30
  echo "exit: $?"
  echo '```'
} > docs/phases/phase-1-1/reports/cli-smoke-test.md
```

## 완료 기준

- [ ] 4 명령 모두 exit 0 (또는 정상 응답 패턴)
- [ ] `reports/cli-smoke-test.md` 생성
- [ ] 모든 stdout 캡처

## 위험

- **R-1**: Obsidian 데스크톱 앱이 종료된 상태에서 호출 → "The CLI is unable to find Obsidian" 에러. 완화: 앱 실행 후 재시도 (`open -a Obsidian` + `until obsidian vaults; do sleep 2; done`)
- **R-2**: 명령 인자 문법 변경 (Obsidian CLI 버전 업데이트) → `obsidian <cmd> --help` 또는 `obsidian help` 로 재확인 후 적용
- **R-3**: 명령 자체가 미존재 → CLI 등록 미완료. T-1 재실행

## 폴백 절차 (R-1 발생 시)

CLI가 응답하지 않으면:
1. `pgrep -f Obsidian` 으로 앱 프로세스 확인
2. 미실행 시 `open -a Obsidian` + 기동 대기 (`until obsidian vaults 2>/dev/null; do sleep 2; done`)
3. 재시도해도 실패 시 본 task는 BLOCKED → Team Lead에 보고
