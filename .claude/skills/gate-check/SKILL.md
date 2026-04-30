---
name: gate-check
description: G0~G4 기준 표시 + 현재 Phase 상태 대비 판정.
user-invocable: true
context: fork
agent: Explore
allowed-tools: "Read, Glob, Grep"
---

# gate-check -- 게이트 기준 조회 및 판정

## 역할

3-workflow.md에 정의된 G0~G4 게이트 기준을 추출하고, 현재 Phase 상태와 대비하여 게이트 진입 가능 여부를 판정한다.

## 입력

`$ARGUMENTS` -- gate_id (선택)

- 특정 게이트 지정: "G0", "G1", "G2", "G3", "G4"
- 인수 없음: 전체 게이트(G0~G4) 기준을 모두 표시

## 실행 절차

### 1. gate_id 파싱

- `$ARGUMENTS`에서 gate_id를 파싱한다.
- 유효값: G0, G1, G2, G3, G4 (대소문자 무관)
- 인수가 없으면 전체 게이트를 대상으로 한다.
- 유효하지 않은 값이면 오류를 반환한다.

### 2. 게이트 기준 추출

- `SSOT/3-workflow.md`를 읽는다.
- Grep으로 해당 게이트 섹션을 찾아 기준 항목을 추출한다.

### 3. 현재 Phase 상태 읽기

- Glob으로 `docs/phases/phase-*/phase-*-status.md` 패턴을 검색한다.
- 가장 최근 Phase의 status.md를 읽는다.
- YAML frontmatter에서 `current_state`와 `gate_results`를 추출한다.

### 4. 판정

각 게이트에 대해:
- 현재 Phase 상태가 해당 게이트 진입 조건을 충족하는지 확인한다.
- gate_results에 이미 판정 결과가 있으면 해당 값을 표시한다.
- 진입 가능/불가/이미 통과를 판정한다.

## 출력 형식

```markdown
## Gate Check 결과

### 현재 Phase
- Phase: {phase_id}
- 상태: {current_state}

### 게이트 기준 및 판정

| 게이트 | 기준 요약 | 현재 결과 | 진입 가능 |
|--------|-----------|-----------|-----------|
| G0 | {기준} | PASS/FAIL/null | YES/NO/DONE |
| G1 | {기준} | PASS/FAIL/null | YES/NO/DONE |
| G2 | {기준} | PASS/FAIL/null | YES/NO/DONE |
| G3 | {기준} | PASS/FAIL/null | YES/NO/DONE |
| G4 | {기준} | PASS/FAIL/null | YES/NO/DONE |

### 판정 상세 (지정 게이트가 있는 경우)

#### {gate_id} 기준 항목
1. {기준 항목 1} -- 충족/미충족
2. {기준 항목 2} -- 충족/미충족
...

### 결론
{gate_id} 진입: 가능 | 불가 (미충족 항목: N건)
```
