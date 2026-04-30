---
name: verify-implementation
description: Task 구현 검증 오케스트레이터. 도메인([BE]/[FE]/[FS])을 판별하고 verify-backend, verify-frontend 스킬을 호출하여 G2 통합 리포트 생성.
argument-hint: "[task-id or file-paths]"
user-invocable: true
context: fork
agent: Explore
allowed-tools: "Read, Glob, Grep, Skill"
---

# verify-implementation — G2 통합 검증 오케스트레이터

## 역할

Task 구현 결과를 검증하는 오케스트레이터. 변경 파일의 도메인을 자동 판별하고 해당 도메인의 검증 스킬을 호출하여 통합 G2 리포트를 생성한다.

## 입력

`$ARGUMENTS` — 다음 중 하나:
- Task ID (예: `15-1-2`) → 해당 Task의 변경 파일을 자동 수집
- 파일 경로 또는 디렉토리 (예: `backend/routers/admin/`) → 직접 검증
- 비어있으면 → `git diff --name-only HEAD`에서 전체 변경 파일 수집

## 실행 절차

### 1단계: 변경 파일 수집

- `$ARGUMENTS`가 Task ID 형식이면:
  - `docs/phases/` 하위에서 해당 Task 내역서(task-X-Y-N-*.md) 검색
  - 내역서의 파일 변경 계획에서 대상 파일 추출
  - 또는 `git diff --name-only HEAD`에서 관련 파일 필터링
- `$ARGUMENTS`가 파일/디렉토리 경로이면:
  - 해당 경로의 파일 직접 수집 (Glob)
- 비어있으면:
  - `git diff --name-only HEAD` 전체 변경 파일 사용

### 2단계: 도메인 자동 판별

| 파일 경로 패턴 | 도메인 |
|---------------|--------|
| `backend/**` | BE |
| `web/**` | FE |
| `tests/**` | TEST (BE 관련) |
| `e2e/**` | TEST (FE 관련) |
| `alembic/**` | DB (BE 관련) |

판별 결과:
- BE 파일만 → `[BE]` → verify-backend 호출
- FE 파일만 → `[FE]` → verify-frontend 호출
- BE + FE 모두 → `[FS]` → verify-backend + verify-frontend 모두 호출

### 3단계: 도메인별 스킬 호출

- `[BE]` 또는 `[FS]`: `/verify-backend <BE 파일 목록>` 호출
- `[FE]` 또는 `[FS]`: `/verify-frontend <FE 파일 목록>` 호출

### 4단계: 통합 G2 리포트 생성

각 도메인 스킬의 결과를 종합하여 통합 리포트를 생성한다.

## 출력 형식

```markdown
## G2 통합 검증 리포트

### 도메인: [BE] | [FE] | [FS]

### 최종 판정: PASS | FAIL | PARTIAL

---

### 백엔드 (G2_be) — 해당 시
- 판정: PASS | FAIL | PARTIAL
- Critical: N건
- High: N건
- Low: N건

### 프론트엔드 (G2_fe) — 해당 시
- 판정: PASS | FAIL | PARTIAL
- Critical: N건
- High: N건
- Low: N건

---

### 이슈 목록 (FAIL/PARTIAL 시)
| 도메인 | 등급 | 파일:라인 | 설명 |
|--------|------|-----------|------|
| BE/FE | C/H/L | path:NN | ... |

### 검증 파일 목록
- backend/...
- web/...
```

## 통합 판정 규칙

| 조건 | 최종 판정 |
|------|----------|
| G2_be=FAIL 또는 G2_fe=FAIL | **FAIL** |
| G2_be=PARTIAL 또는 G2_fe=PARTIAL (FAIL 없음) | **PARTIAL** |
| 모두 PASS | **PASS** |

## 참조

- `SSOT/ROLES/verifier.md` — G2 판정 기준 상세
- `SSOT/2-architecture.md` §8 — 검증 기준 체크리스트
- `SSOT/1-project.md` §4 — 품질 게이트 정의
