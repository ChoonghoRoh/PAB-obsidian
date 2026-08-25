---
name: worklog
description: 명령형 호출로 work-log에 작업 기록 추가 (SessionStart hook 자동 init과 공존, scripts/log-prompt.sh 위임).
argument-hint: "[init|log|check] [--prompt=TEXT] [--result=TEXT] [--help]"
user-invocable: true
context: inherit
agent: main
allowed-tools: "Read, Write, Edit, Bash, Glob"
---

# worklog — 작업 기록 명시 호출

## 역할

LLM이 명시적으로 작업을 기록할 때 호출. SessionStart hook이 자동 init하는 work-log(`scripts/log-prompt.sh`)와 **공존**하여, 명령형 추가/조회 진입점을 제공한다.

> **구현 위임**: 실제 파일 조작은 `scripts/log-prompt.sh`에 위임한다. 스크립트가 없는 프로젝트에서는 본 스킬이 §3 형식대로 인라인 처리한다(경로·형식 동일).

## 입력

`$ARGUMENTS` — 위치 인수 + 옵션.

### 위치 인수 (1번)

| 값 | 설명 |
|------|------|
| `init` | 오늘자 worklog 파일 초기화 (이미 있으면 idempotent — 변경 없음) |
| `log` | 작업 한 건 추가 (`--prompt=` + `--result=` 필수) |
| `check` | 오늘자 worklog 상태 출력 |
| (생략) | `check`로 동작 |

### 옵션

| 옵션 | 종류 | 기본값 | 설명 |
|------|------|--------|------|
| `--prompt=TEXT` | key-value | — | `log` 모드에서 사용자 프롬프트 요약 (필수) |
| `--result=TEXT` | key-value | — | `log` 모드에서 작업 결과 요약 (필수) |
| `--help` | flag | false | **공통** — 본 작업 미실행, 설명·옵션 표만 출력 후 종료 |

### 상호배타

- `init` 또는 `check` 모드에서 `--prompt`/`--result` 지정은 무시 (경고 출력)

## 입력 파싱

`$ARGUMENTS`를 공백 단위로 토큰화하여 다음 규칙에 따라 분류:

| 패턴 | 종류 | 예시 |
|------|------|------|
| `--key=value` | 키-값 옵션 | `--prompt="Phase 3-1 구현"` |
| `--key="value with spaces"` | 키-값 옵션 (인용) | `--result="task-3-1-1 완료"` |
| `--flag` | 불린 플래그 (값 없음) | `--help` |
| 그 외 | 위치 인수 | `init`, `log`, `check` |

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

### 1. 모드 판정

- 위치 인수 1번이 `init`/`log`/`check` 중 하나인지 확인.
- 비어 있으면 `check`로 동작.
- 알 수 없는 값이면 오류 종료.

### 2. 경로 결정

- 스크립트: `scripts/log-prompt.sh` (존재 시 위임 — 우선)
- 디렉토리: `docs/history/` (없으면 자동 생성)
- 파일명: `docs/history/{YYMMDD}-work-log.md` (오늘 날짜, hook과 동일 규격)

### 3. 모드별 동작

#### 3.1 init 모드

```bash
./scripts/log-prompt.sh init
```

- 파일이 있으면 변경 없음 (idempotent — hook 충돌 방지).
- 스크립트 부재 시: 위 경로에 `# Work Log — {YYYY-MM-DD}` 헤더 + `| 순번 | 시각 | 프롬프트 | 결과 |` 표를 생성.

#### 3.2 log 모드

- `--prompt`/`--result` 부재 시 오류 종료.
- 파일이 없으면 init 모드를 먼저 자동 실행.

```bash
./scripts/log-prompt.sh log "{prompt}" "{result}"
```

- 스크립트 부재 시: 표 마지막에 `| {순번} | {HH:MM} | {prompt} | {result} |` 행 추가 (prompt/result 안의 `|` 문자는 `\|`로 이스케이프).

#### 3.3 check 모드

```bash
./scripts/log-prompt.sh check
```

- 파일이 없으면 "오늘 work-log 미초기화" 안내 후 종료.
- 파일이 있으면 상태 출력 + 마지막 5행 강조.

### 4. 결과 보고

```
✅ worklog [{mode}] 완료: docs/history/{YYMMDD}-work-log.md ({행수} 줄)
```

## 예시

```
/worklog                                                           # check (기본)
/worklog init                                                      # 오늘자 worklog 초기화
/worklog log --prompt="Phase 3-1 구현" --result="task-3-1-1 완료"   # 작업 1건 추가
/worklog check                                                     # 오늘자 상태 조회
/worklog --help                                                    # 도움말
```

## 참조

- 결정 #6: hook(자동 init) + 스킬(명시 기록) 역할 분담
- 구현 표준: `scripts/log-prompt.sh` (SessionStart/Stop hook과 동일 파일 규격 공유)
- hook 연동: `.claude/settings.json` SessionStart(자동 init) · Stop(기록 누락 리마인더)
