---
task_id: "1-1-1"
title: "Obsidian CLI 등록 (사용자 sudo 필요)"
domain: WIKI-INFRA
owner: user                  # E-5 + R-1 — sudo 필요로 user 직접 수행
priority: P0
estimate_min: 5
status: pending
depends_on: []
blocks: ["1-1-2", "1-1-3", "1-1-4", "1-1-5"]
---

# Task 1-1-1 — Obsidian CLI 등록

## 목적

Obsidian 데스크톱 앱의 CLI 기능을 macOS 시스템에 등록하여 `/usr/local/bin/obsidian` 심볼릭 링크를 생성한다.

## 사전 조건

- macOS
- Obsidian 데스크톱 앱 설치됨 (`/Applications/Obsidian.app` 존재)

## 실행 절차

### 1. 사전 점검 (Team Lead가 먼저 실행)

```bash
ls /Applications/Obsidian.app 2>&1 | head -1
which obsidian || echo "NOT_REGISTERED"
```

### 2. 미설치 시 (BLOCKER)

`/Applications/Obsidian.app` 없으면:
- 사용자에게 https://obsidian.md/download 안내
- `phase-1-1-status.md`의 `blockers`에 `["obsidian-app-not-installed"]` 추가
- `current_state` → BLOCKED
- 사용자 설치 완료 보고 시 BLOCKED 해제

### 3. CLI 등록 (사용자 직접 — sudo 필요)

Obsidian 앱을 열고 **Settings → General → Enable CLI** 토글. 또는 사용자가 본 세션에서 직접:

```
! obsidian register
```

(`!` 프리픽스로 본 Claude Code 세션 내에서 실행 — sudo 패스워드 입력 가능)

### 4. 등록 검증

```bash
which obsidian
obsidian --version
obsidian --help | head -20
```

기대 출력:
- `which obsidian` → `/usr/local/bin/obsidian`
- `obsidian --version` → 버전 문자열
- `obsidian --help` → 명령 목록 (`daily`, `search`, `create`, `eval`, `files`, `unresolved` 등)

## 완료 기준

- [ ] `which obsidian` → `/usr/local/bin/obsidian`
- [ ] `obsidian --version` 정상 출력
- [ ] `obsidian --help` 정상 출력 (16+ 명령 노출)

## 보고

`docs/phases/phase-1-1/reports/cli-smoke-test.md`의 §0 (등록 결과) 섹션에 위 3 명령 stdout 캡처.

## 위험

- **R-1**: sudo 비밀번호 실패 → 재시도 또는 GUI에서 Settings → General 토글 안내
- **R-2**: macOS 보안 정책으로 심볼릭 링크 차단 → System Settings → Privacy 확인 안내
