# 단계 단위 — BUILDING (backend-dev · frontend-dev)

## 1. 작업 공간 (WT-3)

- 팀원(backend-dev/frontend-dev)은 작업 착수 전에 `pwd` 결과가 주입된 CWD 와 일치하는지 검증하고, 불일치 시 `[BLOCKER] WT-3 위반 — CWD 주입 불일치` 를 즉시 보고하여 작업을 중단한다.

## 2. G2 진입 전 확인


G2 코드 리뷰에 진입하기 전, 다음 항목이 충족되어야 한다:

| # | 항목 | 설명 | 확인 |
|:-:|------|------|:----:|
| 1 | Task 구현 완료 | todo-list의 해당 Task 체크박스 모두 체크 | [ ] |
| 2 | 자체 테스트 실행 | 구현자가 완료 판단용으로 로컬 테스트를 실행해 PASS를 확인한다(게이트 증거 아님 — 판정용 실행 금지, 판정은 verifier · tester) | [ ] |
| 3 | 줄수 확인 | 신규/수정 파일 500줄 이하 (HR-5 REFACTOR-3) | [ ] |
| 4 | import 정리 | 미사용 import 제거, 순환 참조 없음 | [ ] |
| 5 | 디버그 코드 제거 | console.log, print, debugger, TODO(temp) 등 제거 | [ ] |

## 3. G2 지적 수정

G2 PARTIAL(Critical 0건, High만)·FAIL이면 REWINDING → BUILDING으로 돌아와 verifier 이슈 목록에 적힌 항목만 수정한다. 반복 상한은 `retry_count` 누적 3회다.

## 4. [FE] Task의 입력

`[FE]` Task에 `[DS]` 산출물(화면 시안 · UI 설계 명세)이 있으면 그것을 기준으로 구현한다. 명세와 다르게 구현해야 하면 보고의 「지시와 다르게 한 것」에 적는다.
