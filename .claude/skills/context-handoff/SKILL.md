---
name: context-handoff
description: 컨텍스트 한계 도달 시 현재 세션을 새 세션으로 무손실 인계 (prepare/resume 모드).
argument-hint: "<prepare|resume> [handoff-path] [--phase=ID] [--summary=TEXT] [--no-clear-hint] [--help]"
user-invocable: true
context: inherit
agent: main
allowed-tools: "Read, Glob, Bash, Write, Skill"
---

# context-handoff — 세션 간 컨텍스트 인계

## 역할

HR-3(컨텍스트 복구 시 SSOT 리로드 필수) + CHAIN-13(직전 3 Phase 자동 로딩) 자동화. 컨텍스트 한계 도달 또는 `/clear` 직전에 현재 작업 상태를 핸드오프 .md로 직렬화하고, 새 세션에서 이를 로드해 무손실로 작업을 재개한다.

## 입력

`$ARGUMENTS` — 위치 인수 + 옵션.

### 위치 인수

| 위치 | 값 | 필수 | 설명 |
|------|------|------|------|
| 1번 | `prepare` ‖ `resume` | ✅ | 모드 |
| 2번 | `handoff-path` | — | resume 모드 전용. 미지정 시 가장 최근 핸드오프 자동 선택 |

### 옵션

| 옵션 | 종류 | 기본값 | 설명 |
|------|------|--------|------|
| `--phase=ID` | key-value | (자동) | prepare 모드 시 명시. 미지정 시 git/디렉토리에서 추론 |
| `--summary=TEXT` | key-value | (자동) | 핸드오프 1줄 요약 |
| `--no-clear-hint` | flag | false | prepare 종료 후 `/clear` 안내 메시지 생략 |
| `--help` | flag | false | **공통** — 본 작업 미실행, 설명·옵션 표만 출력 후 종료 |

### 상호배타

- `prepare` 모드에서 `handoff-path` 위치 인수 지정은 무시 (경고 출력)
- `resume` 모드에서 `--phase` 지정은 무시 (핸드오프 .md에서 추출)

## 입력 파싱

`$ARGUMENTS`를 공백 단위로 토큰화하여 다음 규칙에 따라 분류:

| 패턴 | 종류 | 예시 |
|------|------|------|
| `--key=value` | 키-값 옵션 | `--phase=3-1` |
| `--key="value with spaces"` | 키-값 옵션 (인용) | `--summary="구현 50% 진행"` |
| `--flag` | 불린 플래그 (값 없음) | `--no-clear-hint`, `--help` |
| 그 외 | 위치 인수 | `prepare`, `resume`, `docs/handoff/...md` |

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

- 위치 인수 1번이 `prepare` ‖ `resume` 인지 검증.
- 둘 다 아니면 오류 종료 (`ERROR: 모드는 prepare 또는 resume 이어야 합니다`).

### 2. prepare 모드

#### 2.1 컨텍스트 수집

다음을 수집:

- 현재 Phase 추론: `--phase` 또는 git branch / `docs/phases/phase-*/phase-*-status.md` 중 `current_state != DONE` 항목.
- Phase status.md 본문 (요약).
- 직전 3개 Phase의 final-summary 파일 (CHAIN-13).
- `git status --short` + 최근 commit 5건 (`git log --oneline -5`).
- 최근 대화에서 합의된 결정·차단 요인·다음 작업.
- `--summary=TEXT`가 있으면 1줄 요약으로 사용; 없으면 자동 생성.

#### 2.2 핸드오프 .md 작성

경로: `docs/handoff/{YYMMDD-HHMM}-handoff.md` (예: `260501-1130-handoff.md`).

5섹션 표준:

```markdown
# Handoff — {phase} ({timestamp})

## 1. 한 줄 요약
{summary}

## 2. 현재 Phase 상태
- phase_id: {phase}
- current_state: {state}
- 진행 중 작업: {in_progress}
- 차단 요인: {blockers or '없음'}

## 3. 직전 3 Phase 기억 (CHAIN-13)
- {phase-N-1}: {1줄 요약}
- {phase-N-2}: {1줄 요약}
- {phase-N-3}: {1줄 요약}

## 4. 작업 컨텍스트
- git branch: {branch}
- git status: {modified count} M / {untracked count} ??
- 최근 commit:
  - {hash} {msg}
  - ...
- 합의된 결정:
  - {결정 1}
  - ...

## 5. 다음 작업 프롬프트
{새 세션에서 그대로 사용 가능한 한국어 프롬프트}
```

#### 2.3 종료 안내

`--no-clear-hint` 미지정 시 사용자에게:

```
✅ 핸드오프 작성 완료: {경로}

다음 단계:
1. /clear 로 새 세션 시작
2. 새 세션에서 /context-handoff resume 호출 (자동으로 가장 최근 핸드오프 로드)
   또는 /context-handoff resume {경로} 명시 호출
```

### 3. resume 모드

#### 3.1 핸드오프 로드

- 위치 인수 2번이 있으면 해당 경로 사용.
- 없으면 `docs/handoff/*-handoff.md` 중 가장 최근(파일명 timestamp 정렬) 자동 선택.
- **핸드오프 파일 부재 시**: 다음 메시지 출력 후 종료
  > 핸드오프 파일을 찾을 수 없습니다. 먼저 `/context-handoff prepare`를 호출하여 산출물을 작성한 후 resume을 시도하세요.

#### 3.2 SSOT 리로드 (FRESH-1)

`Skill` 도구로 `ssot-reload` 호출:

```
Skill(skill="ssot-reload")
```

(allowed-tools에 `Skill` 포함 필수.)

#### 3.3 압축 컨텍스트 출력

핸드오프 5섹션을 사용자에게 요약 출력:

```
📌 Resume — {phase} ({timestamp})
한 줄: {summary}
현재 상태: {state} | 진행 중: {in_progress} | 차단: {blockers}
직전 3 Phase: {phase-N-1}, {phase-N-2}, {phase-N-3}
git: {branch}, {M}M/{??}??
합의된 결정: {결정 N건}
```

#### 3.4 다음 작업 프롬프트 제시 + 대기

- 핸드오프 §5 "다음 작업 프롬프트"를 그대로 출력.
- 사용자 승인 또는 추가 지시 대기.

## 예시

```
/context-handoff prepare                          # 자동 추론
/context-handoff prepare --phase=3-1 --summary="구현 50%"
/context-handoff prepare --no-clear-hint          # /clear 안내 생략
/context-handoff resume                           # 가장 최근 핸드오프
/context-handoff resume docs/handoff/260501-1130-handoff.md
/context-handoff --help
```

## 참조

- HR-3: 컨텍스트 복구 시 SSOT 리로드 필수
- CHAIN-13: 직전 3 Phase 기억 자동 로딩
- 연계 스킬: `ssot-reload` (resume 모드 내부 호출)
- 산출물 위치: `docs/handoff/`
