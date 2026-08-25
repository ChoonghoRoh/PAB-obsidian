---
name: ssot-reload
description: FRESH-1 절차 자동 실행. SSOT 0->1->2->3 순서 읽기 + 버전 확인.
argument-hint: "[--help]"
user-invocable: true
context: fork
agent: Explore
allowed-tools: "Read, Glob"
---

# ssot-reload — SSOT 리로드 절차 자동 실행

## 역할

FRESH-1(컨텍스트 복구 시 SSOT 리로드 필수) 절차를 자동화한다. SSOT 문서를 정해진 순서대로 읽고 현재 프로젝트 상태를 요약한다.

## 연계

`context-handoff resume` 모드가 본 스킬을 `Skill` 도구로 호출하여 FRESH-1 절차를 재사용한다. resume 시 사용자 명시 호출 없이 자동 트리거된다.

## 입력

`$ARGUMENTS` — 본 스킬은 위치 인수·키-값 옵션을 사용하지 않음. 공통 `--help` 만 지원.

### 옵션

| 옵션 | 종류 | 기본값 | 설명 |
|------|------|--------|------|
| `--help` | flag | false | **공통** — 본 작업 미실행, 설명·옵션 표만 출력 후 종료 |

### 상호배타

- 해당 없음 (옵션 단일).

## 입력 파싱

`$ARGUMENTS`를 공백 단위로 토큰화하여 다음 규칙에 따라 분류:

| 패턴 | 종류 | 예시 |
|------|------|------|
| `--key=value` | 키-값 옵션 | (사용 안 함) |
| `--key="value with spaces"` | 키-값 옵션 (인용) | (사용 안 함) |
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

### 1. SSOT 문서 순차 읽기

아래 순서대로 Read로 파일을 읽는다:

1. `docs/SSOT/0-entrypoint.md`
2. `docs/SSOT/1-project.md`
3. `docs/SSOT/2-architecture.md`
4. `docs/SSOT/3-workflow.md`

파일이 존재하지 않으면 해당 파일을 MISSING으로 표시하고 다음으로 진행한다.

### 2. VERSION 확인

- `docs/SSOT/VERSION.md` 파일을 읽는다.
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

## 예시

```
/ssot-reload          # FRESH-1 절차 실행
/ssot-reload --help   # 도움말
```
