---
name: ssot-reload
description: FRESH-1 절차 자동 실행. SSOT 0->1->2->3 순서 읽기 + 버전 확인.
user-invocable: true
context: fork
agent: Explore
allowed-tools: "Read, Glob"
---

# ssot-reload -- SSOT 리로드 절차 자동 실행

## 역할

FRESH-1(컨텍스트 복구 시 SSOT 리로드 필수) 절차를 자동화한다. SSOT 문서를 정해진 순서대로 읽고 현재 프로젝트 상태를 요약한다.

## 입력

`$ARGUMENTS` -- 없음 (인수 불필요)

## 실행 절차

### 1. SSOT 문서 순차 읽기

아래 순서대로 Read로 파일을 읽는다:

1. `SSOT/0-entrypoint.md`
2. `SSOT/1-project.md`
3. `SSOT/2-architecture.md`
4. `SSOT/3-workflow.md`

파일이 존재하지 않으면 해당 파일을 MISSING으로 표시하고 다음으로 진행한다.

### 2. VERSION 확인

- `SSOT/VERSION.md` 파일을 읽는다.
- 버전 번호와 최종 갱신일을 추출한다.
- 파일이 없으면 VERSION MISSING으로 표시한다.

### 3. 현재 Phase 상태 확인

- Glob으로 `docs/phases/phase-*/phase-*-status.md` 패턴을 검색한다.
- 가장 최근 Phase의 status.md를 읽는다.
- `current_state` 값을 추출하여 현재 상태를 표시한다.
- Phase가 없으면 NO ACTIVE PHASE로 표시한다.

### 4. 로딩 확인

모든 단계가 완료되면 SSOT 로딩 완료 메시지를 출력한다.

## 출력 형식

```markdown
## SSOT Reload 결과

### SSOT Version
- 버전: {version} | MISSING
- 최종 갱신: {date} | MISSING

### SSOT 문서 로딩
| 순서 | 파일 | 상태 |
|------|------|------|
| 0 | 0-entrypoint.md | OK / MISSING |
| 1 | 1-project.md | OK / MISSING |
| 2 | 2-architecture.md | OK / MISSING |
| 3 | 3-workflow.md | OK / MISSING |

### 현재 Phase 상태
- Phase: {phase_id} | NO ACTIVE PHASE
- 상태: {current_state}
- 최종 갱신: {updated_at}

### SSOT 리로드: COMPLETE
FRESH-1 절차 완료. 작업 재개 가능.
```
