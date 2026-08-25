---
name: notify-telegram
description: Phase 완료/이슈 알림을 Telegram으로 전송한다 (NOTIFY-1, 구 HR-8 — 의무 자동화).
argument-hint: "<--phase=ID> <--status=STATUS> [--summary=TEXT] [--report-path=PATH] [--type=TYPE] [--help]"
user-invocable: true
context: inherit
agent: main
allowed-tools: "Bash, Read"
---

# notify-telegram — Telegram 완료/이슈 알림 전송

## 역할

Phase 또는 Sub-Phase가 DONE 상태에 도달할 때 NOTIFY-1(구 HR-8) 규칙에 따라 Telegram 알림을 자동 발송한다.
`scripts/pmAuto/report_to_telegram.sh`를 호출해 `.env`의 토큰/채널을 사용한다.

## 입력

`$ARGUMENTS` — 옵션 위주.

### 옵션

| 옵션 | 종류 | 기본값 | 필수 | 설명 |
|------|------|--------|------|------|
| `--phase=ID` | key-value | — | ✅ | Phase ID (예: `3-1`, `24-2-1`) |
| `--status=STATUS` | key-value | — | ✅ | `done` / `blocked` / `master-done` 등 |
| `--summary=TEXT` | key-value | (자동) | — | 한 줄 요약. 미지정 시 자동 생성 시도 |
| `--report-path=PATH` | key-value | (없음) | — | 보고서 경로 (메시지에 포함) |
| `--type=TYPE` | key-value | `phase` | — | `phase` / `master-summary` / `alert` |
| `--help` | flag | false | — | **공통** — 본 작업 미실행, 설명·옵션 표만 출력 후 종료 |

### 상호배타

- `--type=master-summary` 와 `--phase` 가 sub-phase 형식이면 경고 (master 요약은 master phase ID 기대)

## 입력 파싱

`$ARGUMENTS`를 공백 단위로 토큰화하여 다음 규칙에 따라 분류:

| 패턴 | 종류 | 예시 |
|------|------|------|
| `--key=value` | 키-값 옵션 | `--phase=3-1` |
| `--key="value with spaces"` | 키-값 옵션 (인용) | `--summary="Phase 3-1 완료"` |
| `--flag` | 불린 플래그 (값 없음) | `--help` |
| 그 외 | 위치 인수 | (사용 안 함) |

### 파싱 절차

1. `$ARGUMENTS`를 공백 기준 토큰화 (`"..."` 또는 `'...'` 안의 공백은 보존)
2. `--`로 시작하는 토큰을 옵션으로 분리
3. 나머지 토큰을 위치 인수로 수집
4. 알 수 없는 옵션은 경고 출력 (실행 계속)
5. **상호배타 옵션이 동시 지정되면 즉시 오류 종료** (결정 #4)
6. **`--help` 우선 처리**: `options.help === true`이면 §0 헬프 출력 후 즉시 종료

## 실행 절차

### 0. --help 처리 (PAB 공통)

§입력 파싱에서 `options.help === true`로 판별되면:

1. 표준 헬프 포맷으로 본 스킬 설명 출력 (description, argument-hint, 옵션 표, 예시)
2. 즉시 종료 (이후 단계 미실행)

### 1. 필수 옵션 검증

- `--phase` 부재 → 오류 종료 (`ERROR: --phase=ID 필수`)
- `--status` 부재 → 오류 종료 (`ERROR: --status=STATUS 필수`)

### 2. 메시지 포맷 구성 (NOTIFY-2 표준)

타입별 표준 양식:

#### `--type=phase` (기본)

```
[{PAB_NOTIFY_LABEL}] {emoji} Phase {phase} {status_label}: {summary}
📊 결과: {핵심 수치 또는 '본문 참조'}
📁 보고서: {report_path 또는 'N/A'}
```

- `status=done` → emoji `✅`, label `완료`
- `status=blocked` → emoji `🚧`, label `차단`
- 기타 → emoji `ℹ️`, label `{status}`

#### `--type=master-summary`

```
[{PAB_NOTIFY_LABEL}] 🎉 Master Plan {phase} 전체 완료
📊 종합: {summary}
📁 보고서: {report_path}
```

#### `--type=alert`

```
[{PAB_NOTIFY_LABEL}] 🚨 {phase} 알림: {summary}
```

> **프로젝트명 prefix**: `.claude/hooks/hooks.env`의 `PAB_NOTIFY_LABEL` 값을 사용한다 (소스: `PROJECT.md` frontmatter `notify_project_label`).
> `PAB_NOTIFY_CHANNEL`이 `none`이면 발송하지 않고 "알림 비활성 (PROJECT.md)" 안내 후 정상 종료한다.

### 3. 스크립트 호출

```bash
. .claude/hooks/hooks.env
bash scripts/pmAuto/report_to_telegram.sh "$PAB_NOTIFY_LABEL" "{포맷된_메시지}"
```

- 스크립트가 `.env` 부재·토큰 미설정 시 ERROR 반환 → 본 스킬도 ERROR 전파.

### 4. 결과 보고

- 발송 성공 시: `✅ Telegram 알림 발송 완료 (phase={phase}, status={status})`
- 실패 시: 스크립트 stderr 출력 + 원인 안내

## 예시

```
/notify-telegram --phase=3-1 --status=done --summary="skill-plugin-poc 완료"
/notify-telegram --phase=3-1 --status=done --report-path=docs/phases/phase-3-1/reports/final.md
/notify-telegram --phase=24 --status=master-done --type=master-summary --summary="Phase 24 전체 완료"
/notify-telegram --phase=3-1 --status=blocked --type=alert --summary="토큰 발급 대기"
/notify-telegram --help
```

## 참조

- NOTIFY-1~3(구 HR-8): `docs/SSOT/core/6-rules-index.md` §1.17, `docs/SSOT/3-workflow.md §3 NOTIFY`
- 스크립트: `scripts/pmAuto/report_to_telegram.sh`
- 토큰: 환경변수 `PAB_TELEGRAM_BOT_TOKEN` / `PAB_TELEGRAM_CHAT_ID` (또는 루트 `.env` — 커밋 금지)
- 세팅 절차: `docs/guide/index.html` → 🗂 기록·알림 위치 §① Telegram 세팅
