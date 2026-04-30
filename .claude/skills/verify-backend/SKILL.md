---
name: verify-backend
description: 백엔드 코드 심층 리뷰. G2_be 게이트 검증. SSOT ROLES/verifier.md §2.1 기준 적용.
user-invocable: false
context: fork
agent: Explore
allowed-tools: "Read, Glob, Grep"
---

# verify-backend — 백엔드 코드 심층 리뷰

## 역할

`SSOT/ROLES/verifier.md` §2.1 백엔드 검증 기준에 따라 변경 파일을 검토하고 G2_be 판정을 반환한다.

## 입력

`$ARGUMENTS` — 검증 대상 파일 경로 목록 (공백 구분) 또는 디렉토리 경로

파일 목록이 비어있으면 `git diff --name-only HEAD`에서 `backend/` 하위 파일을 자동 수집한다.

## 검증 기준

### Critical (1건이라도 있으면 FAIL)

1. **구문 오류**: Python import 오류, 문법 오류가 없는지 확인
2. **ORM 사용**: raw SQL (`text(...)`, `execute(...)`)이 아닌 SQLAlchemy ORM 사용 확인
3. **입력 검증**: Pydantic 스키마를 통한 입력 검증 존재 확인
4. **FK 정합성**: DB 변경이 있을 경우 FK 제약조건 정합성 확인
5. **기존 테스트 깨짐**: 변경으로 인해 기존 테스트가 깨지지 않는지 확인

### High (권장 통과)

6. **타입 힌트**: 함수 매개변수 및 반환값에 타입 힌트 존재
7. **에러 핸들링**: try-except + HTTPException 패턴 사용
8. **테스트 파일 존재**: 새 기능에 대한 테스트 파일이 `tests/` 하위에 존재
9. **API 응답 형식**: 일관된 응답 구조 (`{"success": bool, "data": ...}` 등)

### Low (개선 권장)

10. **docstring**: 모듈/클래스/함수에 docstring 존재
11. **로깅**: 적절한 로깅 사용 (print 대신 logger)
12. **명명 일관성**: snake_case 변수/함수, PascalCase 클래스

## 실행 절차

1. `$ARGUMENTS`에서 파일 경로 파싱 (없으면 git diff에서 backend/ 파일 수집)
2. 각 파일을 Read로 읽어 검증 기준 항목별 검사
3. 관련 테스트 파일 존재 여부 확인 (Glob)
4. Pydantic 스키마 사용 여부 확인 (Grep)
5. raw SQL 사용 여부 검사 (Grep)
6. 판정 결과를 아래 형식으로 반환

## 출력 형식

```markdown
## G2_be 검증 결과

### 판정: PASS | FAIL | PARTIAL

### 검사 요약
- Critical: N건
- High: N건
- Low: N건

### 이슈 목록 (FAIL/PARTIAL 시)
| 등급 | 파일:라인 | 설명 |
|------|-----------|------|
| C/H/L | path:NN | ... |

### 검증 파일 목록
- file1.py
- file2.py
```

## 판정 규칙

| 조건 | 판정 |
|------|------|
| Critical 1건 이상 | **FAIL** |
| Critical 0건, High 있음 | **PARTIAL** |
| Critical 0건, High 0건 | **PASS** |
