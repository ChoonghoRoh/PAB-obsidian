---
name: phase-init
description: Phase 디렉토리+산출물 자동 생성. CHAIN-6/CHAIN-10 검증.
argument-hint: "<phase_id> [--dry] [--force] [--no-tasks] [--help]"
user-invocable: true
context: fork
agent: general-purpose
allowed-tools: "Read, Glob, Bash, Write, Edit"
---

# phase-init — Phase 디렉토리 및 산출물 자동 생성

## 역할

CHAIN-6(Phase 산출물 생략 금지) 및 CHAIN-10(Phase 문서 경로 규칙)을 준수하며 Phase 디렉토리 구조와 필수 산출물 파일을 자동 생성한다.

## 입력

`$ARGUMENTS` — 위치 인수(`phase_id`, 형식 `{N}-{M}`) + 옵션.

### 옵션

| 옵션 | 종류 | 기본값 | 설명 |
|------|------|--------|------|
| `--dry` | flag | false | 파일 생성 없이 계획만 출력 (검증용) |
| `--force` | flag | false | 동일 phase_id 디렉토리 존재 시에도 강행 (덮어쓰기 주의) |
| `--no-tasks` | flag | false | `tasks/` 디렉토리 생성 생략 |
| `--help` | flag | false | **공통** — 본 작업 미실행, 설명·옵션 표만 출력 후 종료 |

### 상호배타

- `--dry` ‖ `--force` 동시 지정 시 즉시 오류 종료 (의도 충돌)

## 입력 파싱

`$ARGUMENTS`를 공백 단위로 토큰화하여 다음 규칙에 따라 분류:

| 패턴 | 종류 | 예시 |
|------|------|------|
| `--key=value` | 키-값 옵션 | `--path=docs/r.md` |
| `--key="value with spaces"` | 키-값 옵션 (인용) | `--section="비교 분석"` |
| `--flag` | 불린 플래그 (값 없음) | `--dry`, `--force` |
| 그 외 | 위치 인수 | `24-2`, `prepare` |

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

### 1. phase_id 파싱

- 위치 인수 첫 번째를 `phase_id`로 사용한다.
- 형식: `{N}-{M}` (숫자-숫자). 형식이 맞지 않거나 비어 있으면 오류 반환.

### 2. CHAIN-10 검증 — 기존 경로 패턴 확인

- Glob으로 `docs/phases/phase-*/` 패턴을 검색하여 기존 Phase 디렉토리 경로를 확인한다.
- 동일 phase_id 디렉토리가 이미 존재하면:
  - `--force` 미지정 시 경고 출력 후 종료
  - `--force` 지정 시 강행 (덮어쓰기)
- 기존 파일이 `docs/phases/` 루트 하위에 있는지 확인하여 동일 경로 레벨에 생성한다.

### 3. 디렉토리 생성

```bash
mkdir -p docs/phases/phase-{id}
[ "$NO_TASKS" != "true" ] && mkdir -p docs/phases/phase-{id}/tasks
```

`--dry`이면 디렉토리 생성을 건너뛰고 계획만 출력.

### 4. 필수 산출물 생성 (CHAIN-6)

`--dry` 미지정 시 아래 4종을 생성:

#### 4-1. phase-{id}-status.md

```markdown
---
phase_id: "{id}"
title: ""
current_state: "PLANNING"
created_at: "{today}"
updated_at: "{today}"
gate_results:
  G0: null
  G1: null
  G2: null
  G3: null
  G4: null
agents: []
# ↑ 카운터 행(retry_count 등)·current_state 행에 인라인 주석 금지 — state-transition-guard 훅 파싱 대상
---

# Phase {id} Status

상태: PLANNING
```

#### 4-2. phase-{id}-plan.md

```markdown
# Phase {id} Plan

## 목표

(작성 필요)

## 범위

(작성 필요)

## Task 목록

(작성 필요)
```

#### 4-3. phase-{id}-todo-list.md

```markdown
# Phase {id} Todo List

## 체크리스트

- [ ] Plan 작성 완료
- [ ] Task 명세 작성 완료
- [ ] G0 통과
- [ ] 구현 완료
- [ ] G2 통과
- [ ] G3 통과
- [ ] G4 통과
```

#### 4-4. tasks/ 디렉토리

`--no-tasks` 미지정 시 §3에서 이미 생성됨. Task 파일은 Plan 작성 후 개별 생성.

### 5. CHAIN-6 검증

생성된 파일 목록을 확인하고 CHAIN-6 필수 산출물이 모두 존재하는지 검증:

- `phase-{id}-status.md` — 존재 확인
- `phase-{id}-plan.md` — 존재 확인
- `phase-{id}-todo-list.md` — 존재 확인
- `tasks/` 디렉토리 — 존재 확인 (`--no-tasks` 시 SKIP)

## 출력 형식

```markdown
## Phase Init 결과

### 생성된 파일
- docs/phases/phase-{id}/phase-{id}-status.md
- docs/phases/phase-{id}/phase-{id}-plan.md
- docs/phases/phase-{id}/phase-{id}-todo-list.md
- docs/phases/phase-{id}/tasks/ (디렉토리)

### CHAIN-6 검증: PASS | FAIL
- status.md: OK | MISSING
- plan.md: OK | MISSING
- todo-list.md: OK | MISSING
- tasks/: OK | MISSING | SKIPPED

### CHAIN-10 검증: PASS | FAIL
- 경로 레벨: docs/phases/phase-{id}/
- 기존 패턴과 일치: YES | NO
```

## 예시

```
/phase-init 24-2                    # 정식 생성
/phase-init 24-2 --dry              # 계획만 출력
/phase-init 24-2 --force            # 기존 디렉토리 덮어쓰기
/phase-init 24-2 --no-tasks         # tasks/ 디렉토리 생략
/phase-init --help                  # 도움말
```
