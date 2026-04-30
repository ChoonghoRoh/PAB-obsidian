---
name: phase-init
description: Phase 디렉토리+산출물 자동 생성. CHAIN-6/CHAIN-10 검증.
user-invocable: true
context: fork
agent: general-purpose
allowed-tools: "Read, Glob, Bash, Write, Edit"
---

# phase-init -- Phase 디렉토리 및 산출물 자동 생성

## 역할

CHAIN-6(Phase 산출물 생략 금지) 및 CHAIN-10(Phase 문서 경로 규칙)을 준수하며 Phase 디렉토리 구조와 필수 산출물 파일을 자동 생성한다.

## 입력

`$ARGUMENTS` -- phase_id (예: "24-2", "3-1")

phase_id가 비어있으면 오류를 반환하고 종료한다.

## 실행 절차

### 1. phase_id 파싱

- `$ARGUMENTS`에서 첫 번째 인수를 phase_id로 파싱한다.
- 형식: `{N}-{M}` (숫자-숫자). 형식이 맞지 않으면 오류 반환.

### 2. CHAIN-10 검증 -- 기존 경로 패턴 확인

- Glob으로 `docs/phases/phase-*/` 패턴을 검색하여 기존 Phase 디렉토리 경로를 확인한다.
- 동일 phase_id의 디렉토리가 이미 존재하면 경고를 출력하고 종료한다.
- 기존 파일이 `docs/phases/` 루트 하위에 있는지 확인하여 동일 경로 레벨에 생성한다.

### 3. 디렉토리 생성

```bash
mkdir -p docs/phases/phase-{id}/tasks
```

### 4. 필수 산출물 생성 (CHAIN-6)

아래 4종 파일을 생성한다:

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

tasks/ 하위 디렉토리는 3단계에서 이미 생성됨. Task 파일은 Plan 작성 후 개별 생성한다.

### 5. CHAIN-6 검증

생성된 파일 목록을 확인하고 CHAIN-6 필수 산출물이 모두 존재하는지 검증한다:

- `phase-{id}-status.md` -- 존재 확인
- `phase-{id}-plan.md` -- 존재 확인
- `phase-{id}-todo-list.md` -- 존재 확인
- `tasks/` 디렉토리 -- 존재 확인

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
- tasks/: OK | MISSING

### CHAIN-10 검증: PASS | FAIL
- 경로 레벨: docs/phases/phase-{id}/
- 기존 패턴과 일치: YES | NO
```
