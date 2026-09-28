# 단계 단위 — TESTING (tester)

## 1. G3 판정 기준

| 게이트 | 판정 기준 | 결과 |
|--------|----------|------|
| **G3** | 테스트 PASS, 커버리지 >=80%(백엔드), 페이지 로드 OK·콘솔 에러 0건(프론트엔드), E2E PASS, 회귀 테스트 통과, **결함 밀도 ≤ 5건/KLOC** (ISTQB CTFL 4.0 기반) | PASS → INTEGRATION / FAIL → REWINDING → BUILDING |

> **G3 결함 밀도 계산법** (ISTQB CTFL 4.0):
> `결함 밀도 = 발견 결함 수 / (코드 줄 수 ÷ 1000)`
> - 단위: 건/KLOC (Kilo Lines of Code)
> - 기준: ≤ 5건/KLOC 이면 PASS, 초과 시 FAIL
> - 결함 보고서 양식: [TEMPLATES/defect-report-template.md](../../TEMPLATES/defect-report-template.md)

- 이 표가 G3 판정 기준의 정본이다. tester가 이 기준으로 PASS/FAIL을 판정해 Team Lead에게 보고하고, 최종 판정은 Team Lead가 한다. `ROLES/tester.md` · `ROLES/SUB-SSOT/TESTER/testing-procedure.md`는 이 표를 인용한다(LOCK-6).
- **요청 · 측정 대상 고정**(HANDOFF-6): G3 요청에는 대상 SHA와 worktree 경로를 적는다. tester는 그 SHA로 측정하고(실행형 테스트는 그 worktree의 HEAD가 대상 SHA이고 변경이 없을 때만 돌린다), 결과 파일 머리에 `대상 SHA`를 적는다.
- **tester 테스트 코드의 측정 시점**: tester가 쓴 테스트 코드(`ROLES/tester.md`)는 Team Lead 커밋(REPORT-5) 뒤 그 커밋 SHA로 측정한다. 커밋 전 작업 트리는 위 조건(HEAD = 대상 SHA · 변경 없음)을 만족하지 못한다.

## 2. 테스트 범위

**테스트 범위 (선택적 실행 원칙)**: 전체 테스트 실행은 불필요하다. **변경한 코드에 영향받는 테스트만 선택 실행**한다. Team Lead는 테스트 요청 시 **변경 도메인/파일 정보**를 tester에게 전달하고, tester는 변경 도메인·파일에 영향받는 테스트만 선택하여 실행한다.

## 3. 요청·결과 문서화

**테스트 요청·결과 문서화(1주기)**: 요청서(목록)+결과서는 **docs/test-report/** 에 `YYMMDD-HHMM-phase-X-Y-테스트명.md` 로 저장하여 기록 조회.
