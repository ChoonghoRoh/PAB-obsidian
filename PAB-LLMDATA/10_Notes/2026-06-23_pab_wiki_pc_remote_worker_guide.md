---
title: "/pab:wiki PC 구현 가이드 — 데스크톱·Remote Control·headless 워커"
description: "로컬 PC에서 /pab:wiki 스킬을 (1)데스크톱 앱 (2)모바일 Remote Control (3)상시 headless 워커로 돌리는 단계별 실전 가이드. 명령어·권한 플래그·주의점 포함."
created: 2026-06-23 22:45
updated: 2026-06-23 22:45
type: "[[REFERENCE]]"
index: "[[HARNESS]]"
topics: ["[[WIKI_ARCHITECTURE]]", "[[CLAUDE_CODE]]"]
tags: [reference, claude-code, pab-wiki, remote-control, headless, worker, cli]
keywords: [remote-control, headless, "claude -p", allowedTools, permission-mode, dontAsk, bare, cron, synthesis-worker, desktop-app, WIKI_VAULT_ROOT]
sources: ["https://code.claude.com/docs/en/remote-control", "https://code.claude.com/docs/en/headless", "https://code.claude.com/docs/en/cli-reference"]
aliases: ["pab:wiki PC 가이드", "Remote Control 가이드", "wiki headless 워커"]
---

# /pab:wiki PC 구현 가이드 — 데스크톱·Remote Control·headless 워커

> [[10_Notes/2026-06-23_wiki_webservice_migration_risks|웹서비스 전환 리스크]] 분석의 실행편. 결론은 "스킬을 모바일로 옮긴다"가 아니라 **"PC를 [[synthesis worker]]로 두고 입력만 원격에서 보낸다"**. 단계별로 지금 바로 구현 가능한 순서로 정리한다. 명령어는 [code.claude.com/docs](https://code.claude.com/docs) 공식 표기 기준.

## 전제조건 (공통)

- **Claude Code 버전**: `claude --version` → Remote Control은 **v2.1.51 이상** 필요
- **구독**: Remote Control은 **Pro / Max / Team / Enterprise** (Free·API키 단독 불가). headless는 API 키 또는 `claude setup-token`
- **인증**: `claude` 실행 후 `/login` (claude.ai 계정)
- **vault 환경변수**: `export WIKI_VAULT_ROOT="/Users/map-rch/WORKS/PAB-obsidian/PAB-LLMDATA"` — 현재 셸/서비스에 반드시 노출되어야 스킬이 올바른 vault에 쓴다
- **동작 확인(단계 0)**: 로컬 터미널에서 `cd /Users/map-rch/WORKS/PAB-obsidian && claude` → `/pab:wiki <url>` 정상 생성 확인. 이게 되면 아래 모든 단계의 기반이 선다.

## 단계 1 — PC 데스크톱 앱에서 그대로 사용 (가장 쉬움)

[[Claude Code]]가 통합된 **데스크톱 앱(Mac/Win)**을 열어 PAB-obsidian 프로젝트를 열면 터미널과 100% 동일하게 `/pab:wiki`가 동작한다(로컬 파일·`WIKI_VAULT_ROOT`·bash·`wiki.py` 전부 접근).

- 용도: PC 앞에서의 일상 작업. 비주얼 diff 리뷰·멀티세션이 덤.
- 한계: **모바일 수집 문제는 못 푼다**(PC 앞에 있어야 함).

## 단계 2 — 모바일에서 사용: Remote Control (지금 바로 가능한 모바일 해법)

로컬 PC를 켜둔 채 폰에서 진짜 `/pab:wiki`를 그대로 실행. **품질 = 현재와 동일**(같은 모델·SKILL.md·vault).

### 2-1. 로컬 PC에서 띄우기 (서버 모드 — 권장)

```bash
cd /Users/map-rch/WORKS/PAB-obsidian
claude remote-control --name "PAB-obsidian wiki"
```

- 프로세스가 떠 있는 상태로 유지되고 세션 URL이 출력된다.
- **스페이스바**를 누르면 QR 코드 표시.

대안(로컬 터미널도 동시에 쓰고 싶으면 인터랙티브 모드):
```bash
claude --remote-control "PAB-obsidian wiki"
```
이미 대화형 세션이 떠 있으면 슬래시 명령으로 켜기: `/remote-control PAB-obsidian wiki`

### 2-2. 폰에서 연결

- **방법 A (권장)**: Claude 모바일 앱에서 QR 스캔 → 바로 연결
- **방법 B**: 모바일 앱 → **Code** 탭 → 이름(`PAB-obsidian wiki`, 녹색 상태 점)으로 세션 선택
- 연결 후 폰 입력창에 `/pab:wiki <url>` 입력 → 실제 실행은 **로컬 PC**가 수행

### 2-3. 종료

- 로컬: 터미널 `Ctrl+C` 또는 창 닫기 (Remote Control 프로세스는 로컬에서만 돈다 — 클라우드로 안 나감)
- 폰: 앱 닫으면 원격 연결만 끊기고 로컬은 계속 유지

### 한계

- **PC가 켜져 있고 `remote-control` 세션이 떠 있어야** 한다. "PC 꺼진 채 외출 중 폰에서 스크랩"은 불가 → 그건 단계 3으로.

## 단계 3 — 상시 서버 워커: headless `claude -p` (PC 상시 가동 제약 제거)

항상 떠 있는 머신(3800X 등)에서 비대화형으로 스킬을 실행. 모바일/텔레그램/큐는 **트리거만** 보내고 요약은 워커가 수행 → [[capture/store 분리]]의 정식 구현.

### 3-1. 기본 호출 (슬래시 스킬을 -p로)

```bash
cd /Users/map-rch/WORKS/PAB-obsidian
claude -p "/pab:wiki https://example.com/article" \
  --permission-mode dontAsk \
  --allowedTools "Bash(python3 *)" "Read" "Write" "WebFetch"
```

- `-p` (= `--print`): 프롬프트 1회 실행 후 종료(비대화형). 프롬프트 문자열에 `/pab:wiki ...`를 넣으면 슬래시 스킬이 확장·실행된다.
- `--permission-mode dontAsk`: `.claude/settings.json`의 `permissions.allow` + `--allowedTools` 규칙만 실행하고 나머지는 거부(프롬프트 없음) → cron/CI에 적합.
- `--allowedTools`: 스코프 필터는 괄호 앞 공백 없이 `Bash(python3 *)` 형태. 스킬이 쓰는 툴(Bash/Read/Write/WebFetch)을 모두 허용해야 한다.

### 3-2. ⚠️ `--bare`는 쓰지 말 것 (중요)

CI 가이드에 흔히 나오는 `claude --bare -p`는 **hooks·skills·plugins·MCP·CLAUDE.md를 전부 스킵**한다. `/pab:wiki`는 **플러그인 스킬**이므로 `--bare`를 붙이면 스킬이 로드되지 않아 실행 자체가 안 된다.

- 원칙: 스킬 실행 headless에서는 **`--bare` 미사용**.
- 굳이 빠른 시작이 필요하면 `--bare --plugin-dir <pab 플러그인 경로>`로 플러그인만 다시 붙이는 방식이 있으나, 권장은 그냥 `--bare` 없이 실행.

### 3-3. 인증·세션·출력

```bash
export ANTHROPIC_API_KEY="sk-..."          # 또는 claude setup-token (장기 토큰)
claude -p "/pab:wiki <url>" \
  --permission-mode dontAsk \
  --allowedTools "Bash(python3 *)" "Read" "Write" "WebFetch" \
  --output-format json \
  --no-session-persistence                  # 일회성 워커면 세션 저장 끔
```

- `--output-format json` → `jq -r '.result'` / `.session_id` 파싱 가능
- exit code: 0 성공 / 1 실패. `--max-turns N`, `--max-budget-usd N`으로 폭주 방지

### 3-4. cron 예시 (워커 스크립트)

```bash
#!/bin/bash
set -euo pipefail
export ANTHROPIC_API_KEY="sk-..."
export WIKI_VAULT_ROOT="/Users/map-rch/WORKS/PAB-obsidian/PAB-LLMDATA"
cd /Users/map-rch/WORKS/PAB-obsidian

claude -p "/pab:wiki $1" \
  --permission-mode dontAsk \
  --allowedTools "Bash(python3 *)" "Read" "Write" "WebFetch" \
  --output-format json \
  > "/var/log/pab-wiki-$(date +%Y%m%d-%H%M%S).log" 2>&1
```

### 3-5. 서버 워커 주의점

- **`--bare` 금지** (3-2). 스킬·CLAUDE.md 컨텍스트가 필요하므로.
- **백그라운드 Bash**: `-p`는 결과 반환 후 ~5초 내 셸 종료 → 워커 안에서 장기 백그라운드 작업 띄우지 말 것(`CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS`로 조정은 가능하나 권장 안 함).
- **단방향 미러 침범 금지**: 워커는 vault(`PAB-LLMDATA`)에 쓰고, 그다음은 기존 LiveSync→bridge→pab-v4 LV0 경로를 그대로 탄다. 미러(`/home/oceanui/pab-vault-mirror`)에 직접 쓰지 말 것(R-1 위반).
- **트리거 연결**: 텔레그램 봇/웹훅이 위 스크립트에 URL을 인자로 넘기면 모바일 수집이 완성된다.

## 단계별 선택 가이드

| 목표 | 추천 단계 | 비용/제약 |
|---|---|---|
| PC 앞 일상 작업 | 단계 1 (데스크톱 앱) | 없음 |
| 지금 당장 폰에서 시험 | 단계 2 (Remote Control) | PC 상시 가동 |
| 외출 중에도 폰/텔레그램 수집 | 단계 3 (headless 워커) | 상시 서버 + 트리거 구축 |

→ **검증 순서**: 단계 0(로컬 동작) → 단계 2(Remote Control로 폰 연결 빠르게 확인) → 단계 3(상시 워커로 운영 제약 제거). 단계 2가 단계 3의 개념(프런트=입력, 워커=요약)을 가장 빠르게 증명한다.

## 검증 체크리스트

- [ ] `claude --version` ≥ v2.1.51
- [ ] `echo $WIKI_VAULT_ROOT` → PAB-LLMDATA 경로 출력
- [ ] 로컬 `/pab:wiki <url>` 정상 생성 + `python3 scripts/wiki/wiki.py link-check` 통과
- [ ] `claude remote-control --name ...` → 스페이스바 QR → 폰 연결 성공
- [ ] 폰에서 `/pab:wiki <url>` 실행 → 10_Notes/15_Sources에 파일 생성 확인
- [ ] (워커) `claude -p "/pab:wiki <url>" --permission-mode dontAsk --allowedTools ...` 단발 성공 (exit 0)
- [ ] (워커) `--bare` 미사용 확인
