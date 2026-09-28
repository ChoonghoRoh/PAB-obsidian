# SSOT — 컨텍스트 복구 프로토콜

## 1. 개요

컨텍스트 압축, 세션 중단, 토큰 초과 등으로 작업이 중단된 후 복구하는 경우의 **필수 절차**를 정의한다.
이 프로토콜을 건너뛰고 "이전 요약을 바탕으로 바로 작업 재개"하는 것은 **금지**한다.

훅이 돕는 것: 새 세션 시작 시 SSOT 버전과 Phase 상태를 보여 주고 `PROJECT.md`가 바뀌었으면 `hooks.env`를 다시 만든다(SessionStart). 컨텍스트 압축 뒤에는 이 복구 절차를 알림으로 넣는다(PostCompact). 세션을 끝낼 때 work-log 미기록을 알린다(Stop).

## 2. 복구 절차

```
컨텍스트 복구 시점 (압축 발생 / 세션 재개 / /clear 후)
  │
  ▼
[1] SSOT 리로드 ← FRESH-1 (entrypoint → workflow)
  │
  ▼
[2] Phase Chain 실행 중이면 Chain 파일 읽기 (phase-chain-{name}.md)
  │   → current_index ≥ len(phases) → Chain 완료
  │   → current_index가 가리키는 Phase의 status.md가 DONE → current_index += 1 → 다음 Phase Cold Start
  │   → DONE 아님 → 그 Phase로 [3]
  │
  ▼
[3] 현재 Phase status.md 읽기 ← ENTRY-1
  │   → current_state, task_progress, team_name(정보 기록용 — Agent 도구의 team_name 인자는
  │     CLI가 무시하며, 팀은 세션마다 하나뿐이다) 확인
  │
  ▼
[4] 팀 상태 확인
  │   └── `~/.claude/teams/session-<세션 ID 앞 8자>/` 설정 읽기, idle 팀원 확인(팀은 처음
  │       팀원을 스폰할 때 한 번 생기고 이어진다 — 새로 만드는 도구가 없다. HR-1: 팀 없이
  │       코드 수정 금지는 그대로 지킨다)
  │
  ▼
[5] 미완료 Task 식별
  │   → task_progress에서 status != "DONE" 항목 확인
  │   → 해당 Task의 task-X-Y-N.md 읽기
  │
  ▼
[6] 업무 재분배
  │   ├── 기존 팀원 idle 상태 → SendMessage로 작업 재개 지시
  │   ├── 기존 팀원 없음 → 새 팀원 스폰 + Task 할당
  │   └── Task 미할당 → task 파일에 owner 적기
  │
  ▼
[7] 작업 재개 (current_state 기반)
```

## 3. 복구 시 금지 사항

| 금지 항목 | 이유 |
|----------|------|
| SSOT 리로드 없이 작업 재개 | 규칙 변경·버전 불일치 감지 불가 |
| 팀 없이 Team Lead가 직접 코드 수정 | HR-1 위반. "빠르게 마무리"는 정당한 사유가 아님 |
| 산출물(tasks/, todo-list) 생략 | HR-2 위반. 중단 복구 시에도 산출물 의무 동일 |
| 이전 세션 요약만 보고 상태 추정 | status.md가 단일 진입점 (ENTRY-1). 요약은 참고일 뿐 |

## 4. 복구 판정 기준

| 상황 | 처리 |
|------|------|
| current_state = DONE | 다음 Phase 진행 (Chain이면 current_index 확인) |
| current_state = BUILDING, task 일부 DONE | 미완료 Task만 재할당 |
| current_state = PLANNING/PLAN_REVIEW | planner 재스폰 후 계획 재수립 |
| 팀원 응답 없음 | 팀원에게 shutdown_request 후 재스폰(팀은 세션 안에서 유지된다 — 새로 만들 필요 없음) |
| tasks/ 문서 미생성 상태 | 산출물 먼저 생성 후 BUILDING 진입 |
| current_state = BRANCH_CREATION | Git branch 존재 여부 확인 → 있으면 WORKTREE_SETUP 진입, 없으면 BRANCH_CREATION 재실행 |

## 5. 세션 인계 (context-handoff)

컨텍스트 한계에 가까워지거나 `/clear`로 세션을 바꿀 때 쓴다. 도구: `/context-handoff prepare` · `/context-handoff resume`.

### 5.1 prepare — 인계 문서 작성

- 위치: `docs/handoff/{YYMMDD-HHMM}-handoff.md`
- 내용: 한 줄 요약 · 현재 Phase 상태(phase_id · current_state · 진행 중 작업 · 차단 요인) · 작업 컨텍스트(git 브랜치·상태·최근 커밋, 합의된 결정) · 다음 작업 프롬프트(새 세션에서 그대로 쓰는 지시문)
- 작성 후 `/clear`

### 5.2 resume — 인계 문서로 재개

1. 인계 문서 로드 — 경로를 주지 않으면 `docs/handoff/`에서 가장 최근 파일
2. SSOT 리로드 — §2 [1]
3. 인계 요약 출력
4. 다음 작업 프롬프트 제시 → 사용자 승인 대기
5. 승인 후 §2 [2]~[7]로 작업 재개

인계 문서는 참고다. 상태 판단은 status.md로 한다.
