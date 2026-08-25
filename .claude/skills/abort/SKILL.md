---
name: abort
description: AutoCycle/Phase/Chain 안전 중단 — 사용자 중단 요청의 표준 진입점. 팀 shutdown + 상태 기록 + 재개 정보 보존까지 일괄 처리.
argument-hint: "[사유] [--help]"
user-invocable: true
context: inherit
agent: main
allowed-tools: "Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, SendMessage"
---

# abort — 사이클/Phase/Chain 안전 중단

## 역할

진행 중인 AutoCycle·Phase·Phase Chain을 **안전하게 중단**하는 표준 명령이다 (3-workflow.md §8.5 "사용자 중단 요청"의 공식 트리거).
단순히 멈추는 것이 아니라 ① 팀원 정리 ② 상태 영속화 ③ 재개 정보 보존까지 수행하여, 이후 Warm Start 재개가 가능하도록 한다.

> 중단은 **파괴적이지 않다** — 산출물·브랜치·worktree는 삭제하지 않고 보존한다. 삭제가 필요하면 별도로 `/worktree` 정리를 사용한다.

## 입력

`$ARGUMENTS` — 중단 사유(자유 텍스트, 선택) + 옵션.

| 옵션 | 설명 |
|------|------|
| `--help` | 본 작업 미실행, 설명·옵션 표만 출력 후 종료 |

## 실행 절차

### 0. --help 처리 (PAB 공통)

`--help` 지정 시 표준 헬프 포맷 출력 후 즉시 종료.

### 1. 현황 파악

1. **활성 Phase**: `docs/phases/phase-*/phase-*-status.md` 중 최신 파일의 `current_state` 확인.
2. **활성 Chain**: `docs/phases/phase-chain-*.md` 중 `status: "running"` 파일 확인.
3. **활성 팀**: 팀 센티넬(`team-sentinel.sh`가 관리) 및 status.md `team_members` 확인.
4. 셋 다 없으면 "중단할 활성 작업 없음"을 보고하고 종료.

### 2. 중단 범위 확인 (AskUserQuestion — 필수)

활성 Chain이 있으면 반드시 범위를 질문한다:

| 선택지 | 동작 |
|--------|------|
| A. 현재 Phase만 중단 | Phase → BLOCKED, Chain은 일시정지(재개 가능 상태 유지) |
| B. Chain 전체 중단 | Phase → BLOCKED + Chain `status: "aborted"` |
| C. 취소 | 아무 것도 하지 않음 |

Chain이 없고 Phase만 활성이면 "현재 Phase를 중단할까요?" 단일 확인만 수행한다.

### 3. 팀 정리 (활성 팀이 있을 때)

1. **LIFECYCLE-3**: 각 팀원의 미완료 Task를 status.md `blockers[]` 또는 tasks 파일에 "ABORT 보류" 로 기록 (재할당하지 않음 — 중단이므로).
2. 전 팀원에게 `SendMessage(type: shutdown_request)` 전송 → 응답 대기.
3. TeamDelete로 팀 해산 (TEAM_SHUTDOWN 상태 경유).

### 4. 상태 영속화

1. **status.md**:
   - `current_state: "BLOCKED"` (모든 상태에서 진입 허용 — state-transition-guard 통과)
   - `blockers[]`에 추가: `"USER_ABORT: {사유} ({ISO 시각})"`
   - `last_action`: "사용자 중단 (/abort)" / `next_action`: "재개 시 FRESH-7 + §8.4 복구 절차"
2. **Chain 파일** (범위 B 선택 시): `status: "aborted"` 로 변경. 범위 A면 변경하지 않는다(§8.4 재개 절차가 그대로 동작).
3. 반복·재시도 카운터(`retry_count`, `pre_build_iteration_counter`, `replan_counter` 등)는 **절대 리셋하지 않는다** — 재개 시 상한이 이어져야 한다.

### 5. 기록·알림

1. **work-log**: `./scripts/log-prompt.sh log "중단 요청 원문" "abort-{phase}" "중단 범위·사유·보류 Task 목록"`
2. **Telegram** (`notify_channel: telegram`인 경우): `/notify-telegram`으로 "[{라벨}] Phase {X-Y} 사용자 중단" 발송.
3. **핸드오프 권고**: 세션을 곧 닫을 예정이면 `/context-handoff prepare` 실행을 사용자에게 권한다 (강제 아님).

### 6. 재개 안내 출력

중단 완료 보고에 다음을 포함한다:

```
재개 방법:
  1. 새/기존 세션에서 /ssot-reload (FRESH-1)
  2. status.md의 BLOCKED 상태 + blockers의 USER_ABORT 항목 확인
  3. Phase 재개: BLOCKED → 중단 시점 상태로 복귀 (BLOCKED에서 모든 상태 복귀 허용)
     Chain 재개(범위 A): 3-workflow.md §8.4 절차 그대로
     Chain 재개(범위 B): chain status를 "running"으로 수동 변경 후 §8.4
```

## 예시

```
/abort                          # 대화형 — 범위 질문 후 중단
/abort 요구사항 변경으로 재계획 필요   # 사유 포함
/abort --help
```

## 참조

- 3-workflow.md §8.5 Chain 중단·재개 / §8.4 `/clear` 후 컨텍스트 복구
- 5-automation.md §컨텍스트 복구 (FRESH-7)
- LIFECYCLE-1~6 (6-rules-index.md) — 팀원 종료 규칙 (LIFECYCLE-5: 좀비 감지 + Respawn · LIFECYCLE-6: 체크 스케줄러)
- `/context-handoff` — 세션 인계 / `/worktree` — worktree 정리
