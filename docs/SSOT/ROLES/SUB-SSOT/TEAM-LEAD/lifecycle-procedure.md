# Lifecycle Procedure — SUB-SSOT (TEAM-LEAD)

---

## 에이전트 생애주기 상태 기계 — LIFECYCLE-1~6 공통 계약

> **범위**: 본 절은 **상태·주체·판정 분기**만 정의한다. 스폰 게이트 절차와 Leader 외부 계약은 각각 별도 절·별도 문서 소관

### 생애주기 상태 기계

LIFECYCLE-1~6은 규칙 단위로 흩어져 있어 **한 에이전트가 지금 어느 상태인지** 말할 공통 어휘가 없었다. 아래 상태가 그 어휘다.

| 상태 | 진입 조건 | 타임아웃 | 다음 상태 | 주체 |
|------|-----------|----------|-----------|------|
| `SPAWNED` | Agent 스폰 완료 | — | `BRIEFED` | Team Lead |
| `BRIEFED` | 임무 전달 완료 | **60~90s** | `READY` / `SPAWN_UNCONFIRMED` | Team Lead |
| `READY` | 준비 신호(수령 확인) 수신 | — | `WORKING` | 에이전트(자기보고) |
| `WORKING` | Task 착수 | 3분 폴링 | `OK` / `IDLE_REPORTED` / `SUSPECT` | 스크립트 |
| `IDLE_REPORTED` | **시그널 #6** 수신 | — | `WORKING` (nudge 후) | Team Lead |
| `SUSPECT` | 시그널 #4 (inbox 갱신이 180초 넘게 없음) | 다음 3분 폴링에서 재판정 | `OK` / `ZOMBIE-CONFIRMED` | 스크립트 |
| `ZOMBIE-CONFIRMED` | 시그널 #1 또는 #2 | — | respawn | 스크립트(판정) |
| `SHUTDOWN_RECOMMENDED` | Task 완료·부재 | **30분**[^shutdown-timeout] | `SHUTDOWN` | **Team Lead 전용** |
| `SHUTDOWN` | `SHUTDOWN_RECOMMENDED`에서 LIFECYCLE-3 판단(재할당/보류) 완료 + `shutdown_request` 발송 | — | 종료 | **Team Lead 전용** |
| `TEAM_DISBANDED` | LIFECYCLE-4 발동 | — | 종료 | **Team Lead 전용** |

[^shutdown-timeout]: **타임아웃 도출** — 규범은 **LIFECYCLE-2**(미사용 에이전트 즉시 종료, CRITICAL)이며 `LIFECYCLE-1`(5분 무보고 점검)이 아니다 — 대상 사건이 다르다(`SHUTDOWN_RECOMMENDED` 진입 조건은 "Task 완료·부재", `LIFECYCLE-1`은 "무보고"). 본 타임아웃은 그 즉시성이 지켜지지 않은 경우의 **백스톱**이며, 값 = `LIFECYCLE-1` 5분 × **N=6 → 30분**. 도출식은 §LIFECYCLE-5 「시간 기반 종결」의 총 대기 상한과 같다.

**`SPAWN_UNCONFIRMED`**: `BRIEFED` 타임아웃(60~90s) 내에 수령 확인이 오지 않은 상태. 본 절은 이 상태의 **존재와 진입 조건만** 정의한다 — 판정 절차·차단 규칙은 §SPAWN_GATE 소관이다.

**상태명은 규범 어휘다.** 로그와 워처 출력이 이 표기를 그대로 쓴다. 표기가 갈리면 같은 상태를 두 이름으로 부르게 되고, 그 순간 상태 기계는 문서 안에서만 존재하게 된다.
단 **워처 출력은 예외**다 — `ZOMBIE-CONFIRMED`를 `ZOMBIE`로 축약한다. 축약은 이것뿐이며 **신규 어휘가 아니다.**

### 주체 경계 — 스크립트가 할 수 있는 일과 해도 되는 일

- `zombie_check.sh` · `zombie_watch.sh`는 **판정과 출력만** 한다 — 프로세스 종료 · respawn · 파일 정리를 하지 않는다
- 🔴 **`SUSPECT` → 강제종료 경로는 없다.** SUSPECT는 프로세스가 살아 있는 상태다
- **종료(일반 · SSOT 절차)와 respawn은 Team Lead 권한**이다. **LIFECYCLE-3(미완료 Task 재할당/보류 판단)을 건너뛸 수 없다**

> **설계 원칙**: 스크립트는 판정만 한다. 종료 · respawn 판단은 Team Lead에게 남긴다.

#### 이 경계는 기술적 제약이 아니다

> 일반종료·SSOT 절차 종료를 Team Lead 권한으로 두는 근거는 **LIFECYCLE-3의 판단**(미완료 Task를 재할당할 것인가 보류할 것인가)이 자동화가 대신할 수 없는 종류라는 데 있다.

#### 권한 경계는 코드로 강제되지 않는다

`SendMessage`의 `from` 필드는 검증되지 않는다 — 팀에 없는 이름도 그대로 발신자로 표시된다.

> **`from: "team-lead"` 사칭이 가능하다.** **본 절의 주체 경계는 규범으로만 유지되며 코드로 강제되지 않는다.**

### 시그널 #6 `idle_notification` — 2층 기술

**인터페이스 층 (확정)**

| 항목 | 내용 |
|------|------|
| 수신 의미 | **생존 확정 + 무작업** — "살아있고, 지금 할 일이 없다" |
| 대응 | **nudge 1회**. respawn **금지** |
| 방향 | **단방향** — 수신은 무작업을 증명하지만 **미수신은 아무것도 증명하지 않는다** |

미수신을 근거로 삼지 않는 것이 핵심이다. 미수신에 의미를 부여하는 순간 "신호가 없다 = 죽었다"가 되며, 그것이 정확히 피해야 할 추론이다.

**수단 층 (미확정)**

관측 경로가 확인되지 않았다. 실측할 질문:

> *`idle_notification` 발생 시 파일시스템/로그에 관측 가능한 흔적이 남는가. 남는다면 경로·포맷·갱신 시점은 무엇인가.*

**폴백**: 관측 경로가 끝내 확인되지 않으면 Team Lead가 `status.md` 의 `agents[].last_report_at` 을 갱신한다 (`workflow.md` **status 스키마 §`agents` 블록**의 기존 필드).

🔴 *관측 경로가 확인되지 않은 신호는 규정하지 않는다.* 그래서 #6을 2층으로 나눈다 — 인터페이스(무엇을 의미하는가)는 지금 확정할 수 있지만, 수단(어떻게 관측하는가)은 실측 없이 확정할 수 없다.

### "완료 미보고" vs "죽음" — 판정 분기

에이전트가 **작업을 끝내고도 보고하지 않은 채 유휴 상태**이면 `zombie_check.sh`는 `OK(rc=0)`를 반환한다.

```
inbox mtime 정체 감지
  ├ 시그널 #1(프로세스 부재) 또는 #2(shell prompt) → ZOMBIE-CONFIRMED → shutdown_request + respawn (Step 3)
  ├ 시그널 #6(idle_notification) 수신 이력 있음     → IDLE_REPORTED   → nudge 1회 (respawn 금지)
  └ 위 어느 것도 아님                                → SUSPECT         → wake-up 1회 + 다음 3분 폴링에서 재판정
```

**대응이 정반대다. 잘못 판단하면 완료된 작업을 버린다.** `IDLE_REPORTED` 를 `ZOMBIE-CONFIRMED` 로 오판하면 respawn이 발동하고, 그 에이전트가 이미 끝내 둔 산출물은 회수되지 않는다.

**도구가 고장난 것이 아니라 묻는 질문이 달랐다** — `zombie_check.sh` 는 *"살아있는가"* 에는 정확히 답한다. 알아야 할 것은 *"일하고 있는가"* 였다. 시그널 #6이 그 질문에 답하는 신호이고, 위 분기의 두 번째 가지가 그 답을 소비하는 자리다.

완료 판정은 메시지가 아니라 결과 파일 · 파일 상태로 한다(REPORT-6). 에이전트는 작업 경계(수령 · 착수 · 완료)에서 한 줄 보고를 보낸다(REPORT-3) — 이 보고가 늦거나 배달이 밀려도 파일 상태가 진행을 보여 주면 죽음으로 단정하지 않는다.

### 상주 역할 판정 — LIFECYCLE-1 · 2 예외

상주 역할(planner — PLANNING부터 G4 입력 제출까지)은 Task 사이 대기를 할당 상태로 본다(정본: `WORKFLOW/workflow.md` §AGENT-LIFECYCLE 상주 예외).

1. 워처는 상주 역할(팀원 이름이 `planner` 또는 respawn 이름 `planner_r1`~`planner_r5` — D4 suffix)의 idle TTL `SUSPECT`(시그널 #4)를 내지 않는다. 대신 다른 상태에서 상주 대기로 넘어갈 때와 워처 기동 뒤 첫 폴링(`--once` 포함)에 `OK: <이름> (상주 대기 — LIFECYCLE-1 예외)`(예: `OK: planner (…)` · `OK: planner_r1 (…)`)를 한 줄 내고, 대기가 이어지는 동안에는 다시 내지 않는다. 판정 값은 `OK` · rc 0이다(`leader-contract.md` §3 어휘 무변경) — 전이를 기억하려고 상태 파일에 적는 `RESIDENT`는 배달이 아닌 워처 자신의 기억이다(`leader-contract.md` §1). 활동이 돌아오면 `OK`를 한 번 낸다
2. 생존은 시그널 #1 · #2와 지시 ack(COMM-1)로 본다. 필요하면 한 줄 지시를 보내 ack를 받는다
3. `SHUTDOWN_RECOMMENDED`(Task 완료 · 부재)로 넘기지 않는다. G4 입력을 낸 뒤에는 LIFECYCLE-2를 그대로 적용한다
4. 워처의 상주 예외는 idle TTL(#4)만 덮는다. 시그널 #1 · #2의 `ZOMBIE`는 상주 역할에도 그대로 나고 LIFECYCLE-5 절차를 따른다. 이름이 `planner` 또는 `planner_r1`~`planner_r5`가 아닌 planner(`planner-a1` 등 초안 작성용)는 예외가 아니다

---

## §SPAWN_GATE — 스폰 확인 게이트 (LIFECYCLE-6.1)

> **규칙 ID**: **LIFECYCLE-6.1** — 신규 상위 규칙이 아니라 **LIFECYCLE-6의 하위**다.
> SPAWN_GATE는 독립 규칙이 아니라 LIFECYCLE-6 정의에 이미 있는 "spawn+30초 1차 체크"의 **강화판**(대기 60~90초 + 판정 비대칭)이다.

### 게이트 위치와 순서

게이트는 **팀원을 스폰하는 모든 상태 진입**(HANDOFF-1 대상 상태 — `WORKFLOW/handoff/gate.md` HANDOFF-1)에 둔다 — 전달 게이트(HANDOFF-1)를 통과해 스폰한 직후다. BUILDING 진입에서는 LIFECYCLE-6 워처 arm 검사와 **같은 자리**다. 상태 진입이 아닌 스폰(respawn · 같은 상태 안에서 Task별로 더하는 스폰 · 겹쳐 진행하는 판정자 스폰)에도 같은 게이트를 둔다 — 적용 범위는 모든 스폰이다.

```
스폰 → 임무 전달 → 준비 신호 대기(60~90s) → SPAWN_GATE 판정 → 해당 상태 작업 착수
```

⛔ **"준비 확인 전에는 Task를 할당하지 않는다"로 설계하지 않는다.** 준비 신호는 **임무를 수령해야** 나온다. 임무를 주지 않으면 수령 확인이라는 사건 자체가 발생할 수 없고, 게이트는 영원히 열리지 않는다. 순서를 뒤집으면 역설이 되므로 **임무 전달이 대기보다 앞**이다.

### 타임아웃 60~90초

| 항목 | 값 | 근거 |
|------|-----|------|
| 준비 신호 대기 | **60~90초** | SSOT 로딩 단계 **실측 65초** |
| 신호 횟수 | 1회 | 스폰 프롬프트 규약(아래) |

SSOT 로딩이 끝나기 전에 판정하지 않도록 60~90초를 둔다. 정상 기동 중인 에이전트를 미확인으로 모는 게이트는 게이트가 아니라 잡음원이다.

### 스폰 프롬프트 규약

- 에이전트는 **착수 즉시 준비 완료 신호를 1회** 남긴다 — 지시 수령 한 줄 ack(COMM-1)가 그 신호다. 재는 대상은 "기동했는가"가 아니라 **"임무를 수령했는가"**다 — 프로세스 생존은 시그널 #1이 이미 재고 있고, 게이트가 알아야 할 것은 임무가 도달했는지다
- ⚠ **시간 기반 지시("N분마다 보고하라")는 채택하지 않는다.** 에이전트는 자신의 경과 시간을 신뢰성 있게 알지 못하므로 지킬 수 없는 규약이 된다
- 규약화 대상은 **작업 경계 이벤트**뿐이다 — 수령 · 착수 · 완료. 경계는 에이전트가 스스로 아는 사건이라 지킬 수 있다

### 🔴 판정 비대칭 — 무응답은 죽음의 증거가 아니다

| 관측 | 판정 | 근거 |
|------|------|------|
| 준비 신호 **수신** | **살아있음 확정** | 강한 신호. 단독으로 게이트 통과 |
| 준비 신호 **무응답** | **아무것도 확정하지 않음** → `SPAWN_UNCONFIRMED` | 무응답은 죽음·지연·신호 유실 어느 쪽과도 양립한다 |

`SPAWN_UNCONFIRMED` 에서는 **시그널 #1(프로세스 부재)·#2(shell prompt) 객관 판정으로 전환**한다.

- 🔴 **`SPAWN_UNCONFIRMED` 상태에서 자동 respawn 금지.** ZOMBIE 확정(시그널 #1 또는 #2) 시에만 respawn하며, 그 외에는 **Team Lead 에스컬레이션**이다
- 이 비대칭은 §"완료 미보고 vs 죽음" 판정 분기와 같은 원리다 — **수신은 증명하고, 미수신은 증명하지 않는다.** 미수신에 판정을 걸면 정상 작업 중인 에이전트를 죽은 것으로 처리하게 된다

### 훅 기반 자동화는 불가 — 실측 결과

> `SubagentStart`/`SubagentStop` 은 agent team teammate 에 대해 **발화하지 않는다.** HR-1 센티넬은 이 이벤트에 기대지 않는다(리더 `PreToolUse`(Agent) · `Stop`).

따라서 유효 경로는 다음뿐이다:

1. **Team Lead 명시 `--once` 호출**
2. **Leader 외부 폴링**

### agent teams ↔ subagent 트레이드오프

종료된 teammate 에게 `SendMessage` 로 auto-resume 할 수 없다 (`No agent named ... is reachable`). 따라서 **respawn이 유일한 복구 수단**이다.

🔴 **한쪽만 골라 쓰면 안 된다.** resume 개선은 `teammateMode` 를 끄는 선택과 묶이고, **그 순간 시그널 #2(tmux pane 콘텐츠)가 사라진다** — 복구 편의를 얻는 대신 감지 신호 하나를 잃는다. 두 축을 함께 놓고 보지 않은 결정은 한쪽 지표만 좋아 보인다.

---

## §LIFECYCLE-5 RESPAWN — 좀비 감지 + 자동 복구 상세 절차

### 배경

tmux pane 환경에서 claude.exe가 spawn 직후 silent fail 하여 pane이 shell prompt로 복귀하는 "좀비" 현상이 관측됨. 근본 원인(tmux race condition 등)은 회피 불가로 판단 — **감지 + 복구** 메커니즘을 채택한다.

### 좀비 감지 시그널 (신뢰도 순)

| # | 시그널 | 검출 방법 | 신뢰도 | 적용 환경 | 비고 |
|---|--------|----------|--------|-----------|------|
| 1 | claude.exe 프로세스 부재 | `ps -eo pid,command \| grep "agent-id <name>@<team>"` 0 라인 | **최상** | 전 환경 (macOS·Linux 실측) | 확정적. 플랫폼 분기 없음(공통 문법) |
| 2 | tmux pane 콘텐츠 shell prompt | `tmux -L <소켓> capture-pane -t <paneId> -p \| tail -1` — 마지막 줄이 `$`로 끝나면 해당. 소켓명은 **대상 에이전트 PID의 ppid 체인**에서 역추적(유령 소켓은 `list-sessions` 생존 확인으로 배제) | **상** (구현 교체 전제) | tmux 설치 환경 한정. 미설치 → SKIP(3) | **오탐 리스크**: 판정식 `[[ "$pane_tail" =~ \$[[:space:]]*$ ]]` 는 `$` 로 끝나는 임의의 줄에 매칭되어 셸 스니펫·정규식 표시 중 오탐 가능 — #2 는 단독 확정→ZOMBIE→상시 emit→respawn 경로라 대가가 크다. 판정식 변경은 실증 후 판단한다 |
| 4 | 활동 신호원 mtime 정체 | `inboxes/<name>.json`(에이전트별) mtime. `inboxes/` 부재 시 `config.json`(팀 전체) 폴백 | **상** (신호원 교체 전제) | 전 환경 | **`config.json`(팀원 합류·이탈 시에만 갱신)은 정상 작업 중에도 3분 후 SUSPECT를 유발해`inboxes/{agent}.json`(메시지 송수신 시 갱신)을 쓴다. 그래도 통신 없이 순수 작업만 3분 넘게 지속되면 여전히 SUSPECT 가능 — 폴링 계약(최소 유예 5분)이 이 잔여 간극의 안전장치** |

**조합 규칙**:
- 시그널 #1 (프로세스 부재) 단독으로 좀비 확정
- 시그널 #2 (shell prompt 복귀) 단독으로 좀비 확정
- 시그널 #4 단독은 좀비 추정 (wake-up 1회 발송 후 재확인)
- 시그널 #1·#2·#4 전부 조회 불가면 (오탐 대신) SKIP(3) 반환

### 폴링 계약 — LIFECYCLE-1 절차 3.a 구체화

LIFECYCLE-1은 "5분 이상 idle → 점검 후 필요 시 종료"만 규정하므로, 재시도 횟수·간격·최소 유예 시간을 아래 폴링 계약으로 정한다.

**폴링 계약 (확정값)**:

| 파라미터 | 확정값 |
|----------|--------|
| 최소 판정 유예 | **5분** (LIFECYCLE-1 임계값 — 단축 절대 금지) |
| 1차 확인 메시지 | 5분 경과 시 **1회만** 발송 (반복 재촉 금지) |
| 확인 메시지 TTL | **2분** |
| 2차 무응답 시 | 사람의 재판단이 아니라 **`zombie_check.sh` 호출**로 전환 (주관적 판단 → 객관적 신호) |
| 에스컬레이션 | `exit 1`(확정) → 즉시 respawn(Step 3) / `exit 2`(추정) → wake-up 1회 후 재확인 / `exit 3`(SKIP) → **respawn 보류, 로그만 기록** |

**respawn 이전 최소 경과 시간 = 5분(최소 유예) + 2분(TTL) = 7분.**

### 시간 기반 종결

respawn 5회 상한(하단 Step 5)은 "감지에 성공했을 때"만 작동하는 카운터다. 스케줄러 자체가 멈추면 이 카운터는 증가하지 않아 무한 대기가 가능해진다.

**총 대기 시간 상한: 30분**(LIFECYCLE-1 5분 임계값의 6배). Task 위임 시각으로부터 30분이 경과하면 respawn 카운터·감지 성공 여부와 **무관하게** 해당 task를 BLOCKED로 전이하고 사용자에게 보고한다. respawn 5회 상한과 **독립된 별개의 백스톱**이며, 목적은 스케줄러가 멈춘 경우에도 무한 대기를 방지하는 것이다.

### 감지 + Respawn 절차 (Step 1~5)

```
[Step 1] spawn 직후 30초 zombie check
  - zombie_check 함수 호출 (시그널 #1 + #2)
  - 좀비 확인 → 즉시 Step 3 진입 (정기 check timer 우회)
  - 정상 → Step 2 진입

[Step 2] 3분 정기 check (LIFECYCLE-1 5분 무보고 점검과 별도 병행)
  - 시그널 #1 · #2 · #4로 판정
  - 좀비 확정 → Step 3
  - 단순 idle → wake-up 1회 발송 → 다음 3분 폴링에서도 무응답이면 Step 3

[Step 3] shutdown + respawn
  a. SendMessage type=shutdown_request (config 정리용)
  b. agent name suffix: `<name>_r1` → `<name>_r2` → `<name>_r3` → `<name>_r4` → `<name>_r5`
  c. Agent 재spawn (동일 subagent_type / model / prompt)
  d. task metadata.respawn_count += 1 기록
  🔴 동일 모델 respawn 2회 연속 실패 → 3회차는 모델을 바꾸지 않고 재시도하지 않는다 (Step 4 옵션 B로 전환)

[Step 4] respawn 2회차 (count=2) — 원인 분석 권고
  - 옵션 A: spec 수정 후 재spawn
  - 옵션 B: 대기 후 재spawn — **장애 신호(API 529/overload/rate limit) 동반 시 1순위** (전 역할 opus 단일, model 승격 개념 없음)
  - 옵션 C: task 분할 (단일 → 2 sub-task)
  - **장애 신호 정의**: 스폰·respawn 실패 응답에 API 529/overload/rate limit 관측(세션 모델 경로 동반 실패)
  - **상한 정합**: spec을 바꾼 respawn(옵션 A · 모델 전환 포함)도 상한 5회·suffix `_r1`~`_r5` 계산에 포함된다(별도 예산 신설 금지 — 상한 우회 경로 차단)

[Step 5] respawn 5회차 도달 (count=5) — 상한 도달
  - task 상태 BLOCKED 전이
  - 사용자 보고: "[respawn 상한] task=#N agent=<name> 누적 5회 좀비 — 원인 진단 필요"
  - 자동 respawn 중단 → 사용자 결정 대기
```

> **사례(실증)** — 규칙이 아니라 Step 3 🔴 줄(같은 모델로 세 번째 재시도하지 않는다)의 근거 기록이다: 529 누적 8회 → wake-up 2회 → 동일 모델 respawn 2회 실패 → 모델 전환 뒤 성공.

### zombie_check.sh 호출 예시

```bash
# 개별 호출 (종료 코드: 0=정상 / 1=좀비 확정 / 2=추정 좀비 / 3=판정 불가(SKIP))
bash scripts/zombiecheck/zombie_check.sh <agent_name> <team_name>
echo "exit=$?"

# 자체 단위 테스트 (PROJECT.md test_cmd)
bash scripts/zombiecheck/zombie_check.sh --self-test
```

### Task metadata 필드 (LIFECYCLE-5 연계)

```yaml
metadata:
  respawn_count: 0      # 0 → 1 → 2 → 3 → 4 → 5 (5 도달 시 BLOCKED)
  respawn_history:
    - { at: "2026-05-22T13:00:00Z", reason: "process absent 30s", suffix: "_r1" }
    - { at: "2026-05-22T13:03:00Z", reason: "shell prompt visible", suffix: "_r2" }
  status: "active"      # active | blocked | abandoned
```

### suffix 명명 규칙

- 원본 spawn: `backend-dev`
- 1~5회차 respawn: `backend-dev_r1` → `backend-dev_r2` → `backend-dev_r3` → `backend-dev_r4` → `backend-dev_r5` → 도달 시 BLOCKED

**원본 name 재사용 금지** — 동시 등록 불가 + 이력 추적성 보장.

---

## §LIFECYCLE-6 SCHEDULER — 체크 스케줄러 arm/해제 + BUILDING 진입 차단

> **2층 기술**: 하네스 종속을 피하기 위해 **인터페이스(무엇을 언제)** 와 **수단(참조 구현)** 을 분리한다. 타 하네스로 이식할 때는 수단 층만 교체하면 된다.

### 인터페이스 — 무엇을 언제 (하네스 독립)

| 항목 | 규정 |
|------|------|
| arm 시점 | **팀원 0→1 스폰 직후**(팀원 ≥1). `BUILDING` 차단 게이트는 이행 재확인용 **2차 방어선**(존치·강화). 팀원 0인 Phase는 N/A |
| 폴링 주기 | 3분 |
| 1차 체크 | spawn+30초 — 3분 루프와 **다른 경로** |
| 판정 값 | 0=OK / 1=ZOMBIE(확정) / 2=SUSPECT(추정) / 3=SKIP(판정 불가) — `zombie_check.sh` 계약 그대로 |
| emit 조건 | 상태 **변화** 시 1줄 + **ZOMBIE는 항상** + **기동 시 1회 무조건** (조용한 미작동 방지) |
| 해제 시점 | TEAM_SHUTDOWN 도달 또는 팀원 0 |
| 감시 대상 | tmux pane(`tmuxPaneId`)이 있는 팀원은 그대로 폴링. pane이 없는 팀원(in-process 모드 등, team-lead 제외 — 대기 포함)은 세션 transcript 무기록으로 감시한다(TD-109, 아래 §in-process 팀원 감시). 파일을 못 찾거나 못 읽으면 `SKIP` |
| arm 판정 근거 | **사실 확인 3단**(마커 존재 + PID 생존 + 명령줄 대조). `status.md` 워처 필드는 **가시성용이며 판정 근거가 아니다** |

### 수단 — 참조 구현 (`zombie_watch.sh`)

| 서브커맨드 | 용도 |
|-----------|------|
| `--arm <team>` | 폴링 루프 백그라운드 기동(자기 detach) |
| `--stop <team>` | 해제 + 마커 정리 — **기본(`/tmp`) 상태 루트 구성 한정. 오버라이드 구성 금지**(아래 §`--stop` 사용 조건 참조) |
| `--status <team>` | arm 여부 3단 판정 결과 출력 |
| `--once <team> [agent]` | 1회 체크(spawn+30초 경로 전용) |
| `--self-test` | 내장 단위 테스트 |

**호출 규약**: `zombie_check.sh`는 **subprocess로만** 호출한다(`bash zombie_check.sh <agent> <team>`) — `source` 절대 금지. 반복 소싱하면 `readonly` 충돌 · 이름 충돌 · `set -euo pipefail` 전파가 생긴다. **적용 범위**: 이 금지는 zombie_check.sh 호출에 한정한다 — zombie_watch.sh는 readonly · export를 쓰지 않으므로 자체 헬퍼 모듈(zombie_watch_lib.sh · zombie_watch_poll.sh) 소싱에는 해당하지 않는다.

### arm / 해제 절차

- **arm 판정 3단**: ① 마커 파일 존재 ② 마커 PID **생존** ③ 그 PID의 **명령줄이 워처 루프 모드이고 같은 팀명이 단어 단위로 들어 있다**. 셋 중 하나라도 실패하면 미arm(유령 마커·PID 재사용을 마커 존재만으로 arm 오판정하지 않기 위함)
- **해제** — `--stop`(기본 구성 한정, 아래 §`--stop` 사용 조건 참조)이 마커 PID에 TERM(필요 시 KILL) 전송 후 마커 삭제. 정상 해제 외에도 마커 정리는 `trap` EXIT/TERM/INT에서 수행 — 비정상 종료로 마커가 남아도 2·3단이 유령 arm 오판정을 방어한다
- **잔류 확인 시 기본 tmux 소켓 조회 금지** — 본 하네스의 팀은 기본 소켓이 아니라 `claude-swarm-{PID}` 별도 소켓에서 동작하므로, `tmux list-sessions`(기본 소켓)로 잔류 팀원을 확인하면 항상 "부재"가 반환되어 생존 중인 팀원을 잔류 0명으로 오판정한다. 잔류 확인은 `zombie_check.sh`의 소켓 해소 경로(대상 PID의 ppid 체인 역추적 + `list-sessions` 생존 확인)를 경유한다

### arm 호출 규약 — 누가 · 언제 · 어떤 인자로

> 🔴 **관측성 공백**: 폴링 루프는 jq나 config를 못 읽으면 기동 때 한 번만 SKIP을 알리고 이후 조용하다. 그래서 루프가 죽었는지 조용한지 로그로는 구별되지 않는다. `--arm`은 팀 디렉토리가 없으면 루프를 띄우지 않는다(rc=3).

| 항목 | 규약 |
|------|------|
| **호출 주체** | **Team Lead**(본인 — 자동화 훅이 아니다). `SubagentStart`는 agent team teammate에 발화하지 않아(위 "훅 기반 자동화는 불가" 참조) 그 경로로는 훅 기반 자동 arm이 불가하다 — 서브에이전트 `SubagentStart`에는 `agent_id`가 있고 리더 `PreToolUse`(Agent)의 `name`으로도 자동 arm은 기술적으로 가능하나, 채택은 별도 설계 판단이다 |
| **호출 시점** | **팀원 0→1 스폰 직후**(팀원 ≥1 확인 시점). `BRANCH_CREATION → BUILDING`(또는 `TASK_SPEC → BUILDING`) 전이 시점의 차단 게이트는 arm 이행을 **재확인하는 2차 방어선**이며, 그 시점에도 미arm이면 즉시 arm 후 진입 |
| **`<team>` 인자** | 🔴 **팀 디렉토리명(= 세션 디렉토리명)이다** — `~/.claude/teams/<team>/config.json`이 실재하는 그 이름. **Phase ID(`phase-N-M`)를 넣지 않는다.** Phase ID는 세션 디렉토리명과 다를 수 있고, 팀 디렉토리가 없으면 `--arm`이 rc=3으로 거부한다 |
| **차단 게이트 집행 주체** | **Team Lead.** LIFECYCLE-6은 판정 근거(arm 3단)만 정의하며, 게이트를 실제로 세우고 `--arm`을 호출해 여는 행위는 자동화가 아니라 Team Lead의 절차 준수다 |

### 차단 게이트 — BUILDING 진입 시

```
BUILDING 진입 시 (출발점이 TASK_SPEC 이든 BRANCH_CREATION 이든 무관):
  팀원 수 ≥ 1  AND  LIFECYCLE-6 워처 미arm  →  진입 차단
  → Team Lead 가 zombie_watch.sh --arm 으로 워처를 arm 한 후 진입 허용
  → 팀 미사용(팀원 0) Phase 는 N/A
```

> `TEAM_SETUP → BUILDING`은 **존재하지 않는 전이**다. 실제 경로는 `TASK_SPEC → BUILDING` 또는 `TASK_SPEC → BRANCH_CREATION → WORKTREE_SETUP → BUILDING`이며 재진입 경로가 여럿이지만, **모든 경로가 `workflow.md` §3.1 Action Table의 BUILDING 행 하나로 수렴**하므로 조건은 "BUILDING 진입 시" 하나로 충분하다. WT-7 G-C(worktree 미설정 차단) 선례를 준용한다.

정상 경로에서는 이 게이트가 열려 있을 일이 없다 — arm은 이미 팀원 0→1 스폰 직후 수행됐어야 한다(위 인터페이스 표). 본 게이트는 그 이행이 누락된 경우를 잡는 **재확인·안전망**이다.

### spawn+30초 1차 체크 — 루프 밖 별도 경로

- 3분 폴링 루프와 **다른 경로**다. Team Lead가 `Bash run_in_background`로 1회성 지연 체크를 걸고, 좀비 확인 시 즉시 §LIFECYCLE-5 Step 3(respawn)로 진입해 정기 체크 타이머를 우회한다
- `spawned_at`은 **Team Lead가 status.md `agents[]`에 직접 기록**한다
- `SubagentStart`/`SubagentStop`은 agent team teammate에 발화하지 않는다(위 참조) — 그래서 `spawned_at`을 훅으로 자동 기록할 수 없다. `team-sentinel.sh`는 리더 `PreToolUse`(Agent) 스폰과 `Stop` 대조로 팀 활성 여부를 관리한다

### 진행 신호(pane 콘텐츠 해시) — 시그널 #4의 거짓 양성 억제 게이트

```
진행 신호(pane 콘텐츠 해시)의 성격과 적용 범위:
  성격: 시그널 #4의 거짓 양성 억제 게이트 — 신규 좀비 감지 수단이 아니다
  ✅ inbox mtime stale + 화면 변화 있음 → SUSPECT 취소 (통신 없는 정상 작업 보호)
  ❌ 유휴 정지 좀비 감지 불가 — 정상 유휴 대기와 관측값이 동일(둘 다 고정, 실측)
  ❌ 턴 중 교착 감지 불가 — TUI 타이머로 해시가 계속 변함 (실측)
     이 영역은 총 대기 상한 30분이 종결한다(자동 복구 아님)
전제: Claude Code TUI가 alternate screen(alternate_on=1)이며 유휴 시 갱신을 멈춘다는 실측
      (tmux 3.6a). TUI 버전 변경 시 재검증 필요
```

**게이트 조건**: `inbox mtime stale(>180s) AND pane 해시 변화 없음 → SUSPECT` / `stale BUT 해시 변화 있음 → OK(억제)`. **해시는 워처 프로세스 메모리에만 보관**한다(파일 금지 — 유령 마커 방지). **상태 키는 `(agent_name, pane_id)` 쌍**이다 — respawn(`<name>` → `<name>_r1`)은 새 pane을 가지므로 이름만 키잉하면 낡은 pane 해시와 새 pane을 비교해 억제 게이트가 항상 SUSPECT를 취소하고 **respawn 직후 좀비를 영구히 놓친다**(누락 A). `config.json` 부재로 `pane_id` 조회 자체가 불가하면(누락 B) 게이트는 unavailable이 되어 **기존 시그널 #4 판정을 그대로 유지**한다(억제 실패가 확정 판정으로 새지 않도록).

### 좀비 유형 커버리지 — 미커버를 명시한다 (과장 금지)

| 유형 | 수단 | 상태 |
|------|------|:----:|
| (a) 프로세스 사망 | 시그널 #1 | ✅ |
| (b) 세션 사망(shell prompt 복귀) | 시그널 #2(ppid 체인 복구) | ✅ |
| (c) 살아있으나 유휴 정지 | **미커버** | ❌ |
| (d) 턴 진행 중 교착 | **감지 불가** — 총 대기 상한 30분이 종결(자동 복구 아님, BLOCKED + 사용자 보고) | ❌ |

LIFECYCLE-6이 좀비를 전부 잡는 것처럼 기술하지 않는다 — (c)·(d)는 본 스케줄러의 설계상 한계이며, (d)는 총 대기 상한(§시간 기반 종결)이 담당한다.

**자기 발신 보정**: wake-up 발송이 대상의 inbox mtime을 갱신하므로, 그대로 재확인하면 OK로 보인다. 그래서 워처는 SUSPECT를 낸 뒤 inbox가 갱신되면 다음 OK 판정을 한 번 SKIP으로 낮춘다(출력에 `R2-5` 표기).

### in-process 팀원 감시 — TD-109

pane 없는 팀원(in-process 모드 — 이 프로젝트 기본)은 시그널 #1·#2를 쓸 수 없다. `zombie_watch.sh`는 이런 팀원(`tmuxPaneId`가 `%숫자`가 아니고 `team-lead`가 아닌 멤버, 대기 포함)을 세션 transcript로 감시한다 — `isActive`는 작업 중/대기 표지일 뿐이라 이 판정에 쓰지 않는다.

| 칸 | 내용 |
|---|---|
| 신호 | 멤버 `cwd` → `~/.claude/projects/<cwd에서 영숫자·'-' 밖 문자를 '-'로>` 최상위 `*.jsonl` 중 `agentName`·`teamName`이 일치하는 줄의 마지막 기록. 같은 이름의 옛 세션이 여럿이면 "전체 마지막 기록"이 가장 늦은 파일을 고른다 |
| 판정 | 판정 대상은 `attachment`·`system` 기록(턴 종료 직후 hook이 남기는 부산물 — 턴 경계가 아니다)을 건너뛴 마지막 `assistant`·`user` 기록이다. 그 기록이 `assistant`+`end_turn`(응답 종료)이면 턴 끝 대기 → `OK`(무기록 시간과 무관). 그 밖(도구 호출·도구 결과 등 턴 도중)이고 무기록 시간 ≥ 임계(기본 300초 — LIFECYCLE-1 5분과 합치, `_ZW_INPROC_TTL_SEC_OVERRIDE`로 조정)면 `SUSPECT`. transcript를 못 찾거나 못 읽으면 `SKIP` |
| 부작용 | 진단만(P-3) — transcript는 읽기만 한다 |

**Team Lead 확인**: 워처가 이 경로에서 `SKIP`이거나 `SUSPECT`를 냈으면, 지시 뒤 커밋·결과 파일·transcript 증가를 직접 확인하고 멈췄으면 깨우기 1회(§LIFECYCLE-5 Step 2와 같은 절차).

### `--stop` 사용 조건 — 조건부 강등

🔴 **`--stop`은 기본(`/tmp`) 상태 루트 구성에서만 허용한다.** `cmd_stop`의 실제 동작은 `rm -rf "${_ZW_STATE_ROOT:?}/${team}"`이며, `_ZW_STATE_ROOT`를 프로젝트 내부 경로로 오버라이드한 구성에서 그대로 실행하면 **프로젝트 디렉터리 자체가 삭제될 위험**이 있다 — 오버라이드 구성에서는 `--stop` 사용을 금지한다.

**표준 회수 절차**: `--stop` 대신 자식 프로세스 kill을 우선한다. bash 3.2 환경에서 `trap` 처리 지연이 실측됐다 — 정리 신호가 즉시 반영되지 않을 수 있으므로, kill 후 arm 3단 판정(§arm/해제 절차)으로 실제 해제(미arm)를 확인한다.

### arm·회수 체크리스트

**arm** (팀원 0→1 스폰 직후 즉시):
1. 팀 디렉토리명 확인 — `~/.claude/teams/<team>/config.json`이 실재하는 그 이름을 쓴다. **Phase ID(`phase-N-M`)를 넣지 않는다**
2. `zombie_watch.sh --arm <team>` 실행
3. `zombie_watch.sh --status <team>` = ARMED 확인 + 마커 PID의 실행 경로(명령줄)가 `zombie_watch.sh`인지 대조

**회수** (TEAM_SHUTDOWN 도달 또는 팀원 0):
1. 자식 프로세스 kill을 우선한다 — 기본(`/tmp`) 구성이 아니면 `--stop` 금지(위 §`--stop` 사용 조건)
2. `zombie_watch.sh --status <team>`로 재확인 — 미arm(해제 완료) 확인

