# Lifecycle Procedure — SUB-SSOT (TEAM-LEAD)

> **버전**: 1.3 | **생성일**: 2026-08-11 (Phase 9-2, REFACTOR-2 Lv1 분리) | **갱신**: 2026-08-11 (9-2-4 — 생애주기 상태 기계 9상태 + 주체 경계 + 시그널 #6 신설) · 2026-08-12 (9-3-3 — `SHUTDOWN` 상태 정의 행 추가 + `SHUTDOWN_RECOMMENDED` 타임아웃 30분 부여, 9상태 → **10상태**, DEF-9-3-001 ①②) · 2026-08-14 (9-4-4 — FB-01-1 모델 전환 조건부 승격 + FB-01-5 arm 시점 재정의(TEAM_SETUP 직후) 및 arm·회수 체크리스트 신설)
> **출처**: `docs/analysis/260522-zombie-detection-proposal.md` · `docs/handoff/260522-ver6-1-fork-checkpoint.md §5` · `docs/phases/phase-8-3/phase-8-3-plan.md` · `docs/phases/pre/phase-8-progress-signal-decision.md` (rev.2) — 원 절 출처 승계
> **적용 범위**: ver6-2 PoC 라인 한정. 정본 병합 전까지 본 문서가 유일한 상세 근거
> **분리 이력**: 1-orchestration-procedure.md 671/700 → Lv1 분리 (Phase 9-2)
> **문서 관리**: 본문(§LIFECYCLE-5 이하)은 1-orchestration-procedure.md L291–490 무수정 이관 — 바이트 대조 diff 무차이

---

## 에이전트 생애주기 상태 기계 — LIFECYCLE-1~6 공통 계약 (Phase 9-2)

> **출처**: `docs/phases/pre/phase-9-pre-analysis.md` §3(요구 7항목)·§10.4(3인 전원·4회 관측) · Phase 9-2 spike 실측(9-2-2, 2026-08-11)
> **배치 규약**: 본 절은 §LIFECYCLE-5 RESPAWN **앞**에 둔다. 뒤에 붙이면 9-2-1 이관 무결성 증명(`sed -n '/^## §LIFECYCLE-5 RESPAWN/,$p'` 바이트 대조)의 추출 범위가 넓어져 증명이 깨진다 — 증명을 계속 재현 가능하게 두기 위한 배치다
> **범위**: 본 절은 **상태·주체·판정 분기**만 정의한다. 스폰 게이트 절차와 Leader 외부 계약은 각각 별도 절·별도 문서 소관

### 생애주기 상태 기계 (요구 7항목 매핑)

LIFECYCLE-1~6은 규칙 단위로 흩어져 있어 **한 에이전트가 지금 어느 상태인지** 말할 공통 어휘가 없었다. 아래 10상태가 그 어휘다(Phase 9-3-3, `SHUTDOWN` 상태 정의 행 추가 — DEF-9-3-001 ①). `요구#` 열은 pre-analysis §3 요구 7항목의 추적용이며 **1~7이 전부 등장한다**.

| 상태 | 진입 조건 | 타임아웃 | 다음 상태 | 주체 | 요구# |
|------|-----------|----------|-----------|------|:----:|
| `SPAWNED` | Agent 스폰 완료 | — | `BRIEFED` | Team Lead | 1 |
| `BRIEFED` | 임무 전달 완료 | **60~90s** | `READY` / `SPAWN_UNCONFIRMED` | Team Lead | 1 |
| `READY` | 준비 신호(수령 확인) 수신 | — | `WORKING` | 에이전트(자기보고) | 1 |
| `WORKING` | Task 착수 | 3분 폴링 | `OK` / `IDLE_REPORTED` / `SUSPECT` | 스크립트 | 2·4 |
| `IDLE_REPORTED` | **시그널 #6** 수신 | — | `WORKING` (nudge 후) | 스크립트 판정 / TL 조치 | 3 |
| `SUSPECT` | 시그널 #4 (inbox mtime 정체) | TTL 2분 | `OK` / `ZOMBIE-CONFIRMED` | 스크립트 | 3 |
| `ZOMBIE-CONFIRMED` | 시그널 #1 또는 #2 | — | `CLEANED` → respawn | 스크립트(잔해 정리) | 6 |
| `SHUTDOWN_RECOMMENDED` | Task 완료·부재 | **30분**[^shutdown-timeout] | `SHUTDOWN` | **Team Lead 전용** | 5 |
| `SHUTDOWN` | Team Lead가 `SHUTDOWN_RECOMMENDED` 수신 후 LIFECYCLE-3 판단(재할당/보류) 완료 + `shutdown_request` 발송 | — | 종료 | **Team Lead 전용** | 5 |
| `TEAM_DISBANDED` | LIFECYCLE-4 발동 | — | 종료 | **Team Lead 전용** | 7 |

[^shutdown-timeout]: **타임아웃 도출(Phase 9-3-3, DEF-9-3-001 ②, G1 확정값)** — 종전엔 `—`(나올 강제력 정의상 0)였다. 규범은 **LIFECYCLE-2**(미사용 에이전트 즉시 종료, CRITICAL)이며 `LIFECYCLE-1`(5분 무보고 점검)이 아니다 — 대상 사건이 다르다(`SHUTDOWN_RECOMMENDED` 진입 조건은 "Task 완료·부재", `LIFECYCLE-1`은 "무보고"). 본 타임아웃은 그 즉시성이 지켜지지 않은 경우의 **백스톱**이며, 값 = `LIFECYCLE-1` 5분 × **N=6 → 30분**. 근거는 결함 E 선례(본 문서 §LIFECYCLE-5 "시간 기반 종결": *"총 대기 시간 상한 30분(LIFECYCLE-1 5분 임계값의 6배 — SSOT 내부 값에서 직접 도출한 값이며 임의로 정한 값이 아니다)"*) — 동일 도출식을 재사용했다. 23h30m 잔류(Phase 9-3 실측, C-1)가 이 칸이 `—`였을 때의 실제 대가였다.

**`SPAWN_UNCONFIRMED`**: `BRIEFED` 타임아웃(60~90s) 내에 수령 확인이 오지 않은 상태. 본 절은 이 상태의 **존재와 진입 조건만** 정의한다 — 판정 절차·차단 규칙은 §SPAWN_GATE 소관이다.

**상태명은 규범 어휘다.** 이벤트·로그·JSON enum이 이 표기를 그대로 쓴다. 표기가 갈리면 같은 상태를 두 이름으로 부르게 되고, 그 순간 상태 기계는 문서 안에서만 존재하게 된다.
단 **전선(wire) 표기 1건은 예외**다 — JSON `status` 는 `ZOMBIE-CONFIRMED` 를 `ZOMBIE` 로 축약한다(`3-leader-contract.md §3.1` 대응표). 축약은 이 1건뿐이며 **신규 어휘가 아니다.**

### 주체 경계 — 스크립트가 할 수 있는 일과 해도 되는 일

- **강제종료 = 좀비 잔해 정리**. `ZOMBIE-CONFIRMED` 한정이며, 대상은 pane·고아 프로세스·상태 마커 회수다
- 🔴 **`SUSPECT` → 강제종료 경로는 정의상 부재**다. SUSPECT는 프로세스가 살아 있는 상태이므로 **정리할 잔해가 없다.** 이것은 "하지 마라"는 금지 규칙을 덧붙인 것이 아니라 **구조**다 — 대상이 없으므로 경로가 생길 수 없다
- **일반종료·SSOT 절차 종료는 Team Lead 권한**이다. 스크립트는 `SHUTDOWN_RECOMMENDED` 이벤트 발신까지만 하고 멈춘다. **LIFECYCLE-3(미완료 Task 재할당/보류 판단)을 자동화가 건너뛸 수 없다**

> **설계 원칙**: 스크립트는 죽은 것을 치운다. 살아있는 것을 죽이는 판단은 Team Lead에게 남긴다.

#### 이 경계는 기술적 제약이 아니다 (9-2-2 spike 실측 반영)

> 스크립트가 에이전트에게 직접 발신할 수단은 **존재한다** — Phase 9-2 spike 실측 결과 **배달 경로 = 둘 다**(inbox 직접 쓰기 3/3 · tmux send-keys 2/2).
> 그럼에도 일반종료·SSOT 절차 종료를 Team Lead 권한으로 두는 것은 **기술적 제약이 아니라 정책적 결정**이다. 근거는 수단의 부재가 아니라 **LIFECYCLE-3의 판단**(미완료 Task를 재할당할 것인가 보류할 것인가)이 자동화가 대신할 수 없는 종류라는 데 있다.

*"할 수 없어서 안 한다"* 와 *"할 수 있지만 안 한다"* 는 다르다. 전자는 수단이 생기는 순간 무너지며, spike가 바로 그 수단을 실측으로 확인했다 — 전자로 썼다면 이 절은 **작성 시점에 이미 거짓**이었다. 후자는 근거가 판단에 있으므로 수단이 늘어나도 무너지지 않는다.

#### 권한 경계는 코드로 강제되지 않는다

spike VAL-4 실측: 팀에 존재하지 않는 `zombie-watch` 이름이 `<teammate-message teammate_id="zombie-watch">` 로 **그대로 렌더**됐다. `from` 필드는 검증되지 않는다.

> **`from: "team-lead"` 사칭이 가능하다.** 스크립트가 자기 정체를 밝히고 발신할 수 있다는 것은 장점이지만, 같은 메커니즘으로 권한 있는 발신자를 위장할 수도 있다. **본 절의 주체 경계는 규범으로만 유지되며 코드로 강제되지 않는다** — 이 사실을 감추지 않는다.

강제 수단(발신자 서명·채널 분리 등)은 본 Phase 범위 밖이다. 규범과 강제 사이의 간극을 **기록해 두는 것**이 지금 할 수 있는 일이다.

### 시그널 #6 `idle_notification` — 2층 기술

**인터페이스 층 (9-2 확정)**

| 항목 | 내용 |
|------|------|
| 수신 의미 | **생존 확정 + 무작업** — "살아있고, 지금 할 일이 없다" |
| 대응 | **nudge 1회**. respawn **금지** |
| 방향 | **단방향** — 수신은 무작업을 증명하지만 **미수신은 아무것도 증명하지 않는다** |

미수신을 근거로 삼지 않는 것이 핵심이다. 미수신에 의미를 부여하는 순간 "신호가 없다 = 죽었다"가 되며, 그것이 정확히 Phase 8-4에서 폐기된 추론이다.

**수단 층 (9-3 확정 — 본 Phase 미확정)**

관측 경로가 확인되지 않았다. 9-3이 실측할 질문을 명시한다:

> *`idle_notification` 발생 시 파일시스템/로그에 관측 가능한 흔적이 남는가. 남는다면 경로·포맷·갱신 시점은 무엇인가.*

**폴백**: 관측 경로가 끝내 확인되지 않으면 Team Lead가 `status.md` 의 `agents[].last_report_at` 을 갱신한다 (`3-workflow.md` **status 스키마 §`agents` 블록** 기존 필드 재사용 — **신규 스키마 불요**).

🔴 **시그널 #5 재발 방지**: *관측 경로가 확인되지 않은 신호는 규정하지 않는다.* 시그널 #5(`last_send_at`)는 구현 근거 없이 규정되었다가 Phase 8-4에서 폐기됐다. 본 절이 #6을 2층으로 나눈 이유가 이것이다 — 인터페이스(무엇을 의미하는가)는 지금 확정할 수 있지만, 수단(어떻게 관측하는가)은 실측 없이 확정할 수 없다.

### "완료 미보고" vs "죽음" — 판정 분기

pre-analysis §10.4 실측: 3인 전원·4회 관측에서 `zombie_check.sh` 는 전부 `OK(rc=0)` 를 반환했다. 에이전트들은 **작업을 끝내고도 보고하지 않은 채 유휴 상태**였다.

```
inbox mtime 정체 감지
  ├ 시그널 #1(프로세스 부재) 또는 #2(shell prompt) → ZOMBIE-CONFIRMED → 잔해 정리 + respawn
  ├ 시그널 #6(idle_notification) 수신 이력 있음     → IDLE_REPORTED   → nudge 1회 (respawn 금지)
  └ 위 어느 것도 아님                                → SUSPECT         → wake-up 1회 + TTL 2분
```

**대응이 정반대다. 잘못 판단하면 완료된 작업을 버린다.** `IDLE_REPORTED` 를 `ZOMBIE-CONFIRMED` 로 오판하면 respawn이 발동하고, 그 에이전트가 이미 끝내 둔 산출물은 회수되지 않는다.

**도구가 고장난 것이 아니라 묻는 질문이 달랐다** — `zombie_check.sh` 는 *"살아있는가"* 에는 정확히 답했다(4/4 rc=0). 알아야 할 것은 *"일하고 있는가"* 였다. 시그널 #6이 그 질문에 답하는 신호이고, 위 분기의 두 번째 가지가 그 답을 소비하는 자리다.

---

## §SPAWN_GATE — 스폰 확인 게이트 (LIFECYCLE-6.1, Phase 9-2)

> **규칙 ID**: **LIFECYCLE-6.1** — 신규 상위 규칙이 아니라 **LIFECYCLE-6의 하위**다. 총 규칙 수 **104 불변**.
> SPAWN_GATE는 독립 규칙이 아니라 LIFECYCLE-6 정의에 이미 있는 "spawn+30초 1차 체크"의 **강화판**(30초 → 60~90초 + 판정 비대칭)이다. 상위 ID를 신설하면 104→105가 되어 `README.md`·`PROJECT.md`·`docs/guide/index.html`·`VERSION.md`·`6-rules-index.md` **5파일 숫자 연쇄 갱신**이 따라온다 — ver6-1(102→103)·Phase 8-3(103→104) 선례가 그 비용을 치렀다.
> **출처**: `docs/phases/pre/phase-9-pre-analysis.md` §10.1(훅 실측)·§10.2(auto-resume 실측) · Phase 9-2 spike(9-2-2)

### 게이트 위치와 순서

게이트는 **`BRANCH_CREATION → BUILDING` 진입 차단** 지점에 둔다 — LIFECYCLE-6 워처 arm 검사가 **이미 쓰고 있는 같은 자리**다. 신규 차단 지점을 만들지 않는다.

```
스폰 → 임무 전달 → 준비 신호 대기(60~90s) → SPAWN_GATE 판정 → BUILDING
```

⛔ **"준비 확인 전에는 Task를 할당하지 않는다"로 설계하지 않는다.** 준비 신호는 **임무를 수령해야** 나온다. 임무를 주지 않으면 수령 확인이라는 사건 자체가 발생할 수 없고, 게이트는 영원히 열리지 않는다. 순서를 뒤집으면 역설이 되므로 **임무 전달이 대기보다 앞**이다.

### 타임아웃 60~90초 (기존 30초 폐기)

| 항목 | 값 | 근거 |
|------|-----|------|
| 준비 신호 대기 | **60~90초** | SSOT 로딩 0→1→2→3 단계 **실측 65초** |
| 신호 횟수 | 1회 | 스폰 프롬프트 규약(아래) |

30초는 **로딩이 끝나기도 전에 판정하는 값**이었다. 실측 65초가 상한 안쪽에 들어오도록 60~90초로 넓힌다. 정상 기동 중인 에이전트를 미확인으로 모는 게이트는 게이트가 아니라 잡음원이다.

### 스폰 프롬프트 규약

- 에이전트는 **착수 즉시 준비 완료 신호를 1회** 남긴다. 재는 대상은 "기동했는가"가 아니라 **"임무를 수령했는가"**다 — 프로세스 생존은 시그널 #1이 이미 재고 있고, 게이트가 알아야 할 것은 임무가 도달했는지다
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

pre-analysis §10.1 실측:

> `SubagentStart`/`SubagentStop` 은 agent team teammate 에 대해 **발화하지 않는다.** 실험군 **0건** / 대조군 `PostToolUse` **2건** — **설정 미적용이 아니라 이벤트 자체가 미발생**이다.

대조군이 2건 잡힌 것이 이 결론의 핵심이다. 훅 설정이 통째로 죽어 있었다면 대조군도 0건이었을 것이고, 그랬다면 "설정 문제"와 "이벤트 미발생"을 가를 수 없었다. 대조군이 그 둘을 갈랐다. 따라서 유효 경로는 **2가지뿐**이다:

1. **Team Lead 명시 `--once` 호출**
2. **Leader 외부 폴링**

### agent teams ↔ subagent 트레이드오프

pre-analysis §10.2 실측: 종료된 teammate 에게 `SendMessage` 로 auto-resume 하는 것은 **불가**하다 (`No agent named ... is reachable`). 따라서 **respawn이 유일한 복구 수단**이다.

🔴 **한쪽만 골라 쓰면 안 된다.** resume 개선은 `teammateMode` 를 끄는 선택과 묶이고, **그 순간 시그널 #2(tmux pane 콘텐츠)가 사라진다** — 복구 편의를 얻는 대신 감지 신호 하나를 잃는다. 두 축을 함께 놓고 보지 않은 결정은 한쪽 지표만 좋아 보인다.

> **K-7 측정 주석**: 본 게이트의 KPI(K-7)는 **합성 좀비 케이스(spawn 직후 silent fail 재현) N건 중 미검출 0건 + 오탐 0건**으로 측정한다. 배경 수치인 **좀비율 60%(Phase 1-8-G 관측, 2026-05-22, n=5, 현행 버전 미검증)** 는 *이 게이트가 왜 필요한가*를 설명하는 관측이며 **측정 분모가 아니다.**
> 60%는 재측정이 불가능하다 — 좀비 발생률을 통제할 수 없고, 유의미한 n 을 모으려면 수십 회 spawn 이 필요하다. **재측정 불가능한 값을 목표의 분모로 쓰면 측정 자체가 수행되지 않는다.** 합성 케이스로 측정할 것.

---

## §LIFECYCLE-5 RESPAWN — 좀비 감지 + 자동 복구 상세 절차 (ver6-1 PoC)

> **출처**: `docs/analysis/260522-zombie-detection-proposal.md` (제안서 §2) + `docs/handoff/260522-ver6-1-fork-checkpoint.md` §5 (확정 결정값 D1~D6)
> **적용 범위**: ver6-2 PoC 라인 한정. 정본(`docs/SSOT/docs/`) 병합 전까지는 본 SUB-SSOT가 유일한 상세 근거

### 배경

tmux pane 환경에서 claude.exe가 spawn 직후 silent fail 하여 pane이 shell prompt로 복귀하는 "좀비" 현상이 관측됨 (Phase 1-8-G 운영 중 좀비율 60%, 5건 중 3건). 근본 원인(tmux race condition 등)은 회피 불가로 판단 — **감지 + 복구** 메커니즘을 채택한다.

### 좀비 감지 시그널 (신뢰도 순, **Phase 8-4 결함 F 재평가 — 적용 환경 열 신설**)

> **재평가 배경**: Phase 8-2/8-4에서 시그널 #2·#4가 실측과 다르게 규정돼 있었음이 드러났다(각각 사문화·신호원 부적절). #5는 구현 근거 자체가 존재하지 않는다. 아래 표는 실측 결과를 정직하게 반영한다 — 규정과 실제가 다르면 규정을 실제에 맞춘다.

| # | 시그널 | 검출 방법 | 신뢰도 | 적용 환경 | 비고 |
|---|--------|----------|--------|-----------|------|
| 1 | claude.exe 프로세스 부재 | `ps -eo pid,command \| grep "agent-id <name>@<team>"` 0 라인 | **최상** | 전 환경 (macOS·Linux 실측, Phase 8-2) | 확정적. 플랫폼 분기 0건(공통 문법) |
| 2 | tmux pane 콘텐츠 shell prompt | `tmux -L <소켓> capture-pane -t <paneId> -p \| tail -2` → `bash $` 표시. 소켓명은 **대상 에이전트 PID의 ppid 체인**에서 역추적(Phase 8-4 A-1, 유령 소켓은 `list-sessions` 생존 확인으로 배제) | **상** (구현 교체 전제) | tmux 설치 환경 한정. 미설치 → SKIP(3) | **8-2까지는 스크립트 자신의 `${PPID}`를 소켓명으로 오용해 실제 소켓과 한 번도 일치한 적이 없었다(사문화 실측 확인). Phase 8-4에서 ppid 체인 방식으로 복구** — "신뢰도 하향"이 아니라 "구현 오류 수정". **오탐 리스크(Phase 8-5)**: 판정식 `[[ "$pane_tail" =~ \$[[:space:]]*$ ]]` 는 `$` 로 끝나는 임의의 줄에 매칭되어 셸 스니펫·정규식 표시 중 오탐 가능 — #2 는 단독 확정→ZOMBIE→상시 emit→respawn 경로라 대가가 크다. 본 Phase는 기록만 하며, 판정식 변경은 8-6 실증 후 판단한다 |
| 3 | inbox 전체 unread | `cat inboxes/<name>.json` 큐 길이(미소비 메시지 수) > 0 — **Phase 8-5 정정**: 실제 포맷은 `.read` 필드를 가진 객체 배열이 아니라 소비 후 비워지는 drain 큐(실측: 전 파일 `[]`, size 2)이므로 `jq '.[].read'` 는 표현식 자체가 성립하지 않는다 | 중, **검증 보류** | 미확인 | `.read` 필드를 가진 실 데이터를 확보하지 못해 포맷을 직접 검증하지 못했다(Phase 8-4 조사). **8-4에서 손대지 않는다.** 실 표본(큐가 쌓인 상태) 확보 후 발동 조건 확정 — 8-6 |
| 4 | 활동 신호원 mtime 정체 | `inboxes/<name>.json`(에이전트별, Phase 8-4 L-2) mtime. `inboxes/` 부재 시 `config.json`(팀 전체) 폴백 | **상** (신호원 교체 전제) | 전 환경 | **8-2까지는 `config.json`(팀원 합류·이탈 시에만 갱신) 사용 — 정상 작업 중에도 3분 후 SUSPECT 유발(verifier 실측 idle 225s). Phase 8-4에서 `inboxes/{agent}.json`(메시지 송수신 시 갱신)로 교체해 개선했으나, 통신 없이 순수 작업만 3분 넘게 지속되면 여전히 SUSPECT 가능 — 결함 D 폴링 계약(최소 유예 5분)이 이 잔여 간극의 안전장치** |
| 5 | SendMessage 회신 0 TTL | `last_send_at` diff ≥ 3분 (D2) | **하, 구현 근거 불명확** | 미구현 | `last_send_at` 필드가 저장소·SSOT 어디에도 기록되지 않음을 확인(Phase 8-4 조사) — **규정만 있고 구현이 없는 시그널**. 결함 A(시간 기반 실행체 부재)와 같은 종류 |

**조합 규칙** (Phase 8-5 정정 — F-2: 코드는 헤더·구현이 일치하므로 단독 이탈자였던 문서를 코드에 맞춘다):
- 시그널 #1 (프로세스 부재) 단독으로 좀비 확정
- 시그널 #2 (shell prompt 복귀) 단독으로 좀비 확정 — #3 은 검증 보류이므로 AND 조건에서 제외 (Phase 8-5, 코드 실측 정합)
- 시그널 #4 단독은 좀비 추정 (wake-up 1회 발송 후 재확인). #5 는 미구현이므로 조합에서 제외
- 시그널 #3·#5 는 현재 판정에 참여하지 않는다 — 표의 적용 환경 열 참조
- 시그널 #1·#2·#4 전부 조회 불가면 (오탐 대신) SKIP(3) 반환

### 폴링 계약 — LIFECYCLE-1 절차 3.a 구체화 (Phase 8-4 결함 D)

> **대상**: `3-workflow.md §AGENT-LIFECYCLE` "Team Lead 에이전트 관리 절차" 3.a("Task 진행 중 + 정상 → 메시지로 상태 확인 요청")를 구체화한다. `3-workflow.md` 본문은 수정하지 않는다(헤드룸 28줄은 8-3 몫).

LIFECYCLE-1은 "5분 이상 idle → 점검 후 필요 시 종료"만 규정하고 재시도 횟수·간격·최소 유예 시간을 정의하지 않았다. **실사례(2026-08-07, Phase 8-2 진행 중)**: Team Lead가 2분 만에 확인 메시지를 2회 발송한 뒤 무응답으로 판단해 respawn을 발동했으나, 대상 verifier는 정상 작동 중이었고 곧 보고서를 전달했다 — 규정 부재가 만든 불필요한 respawn이었다.

**폴링 계약 (확정값)**:

| 파라미터 | 확정값 |
|----------|--------|
| 최소 판정 유예 | **5분** (LIFECYCLE-1 기존 임계값 — 단축 절대 금지) |
| 1차 확인 메시지 | 5분 경과 시 **1회만** 발송 (반복 재촉 금지) |
| 확인 메시지 TTL | **2분** |
| 2차 무응답 시 | 사람의 재판단이 아니라 **`zombie_check.sh` 호출**로 전환 (주관적 판단 → 객관적 신호) |
| 에스컬레이션 | `exit 1`(확정) → 즉시 respawn(Step 3) / `exit 2`(추정) → wake-up 1회 후 재확인 / `exit 3`(SKIP) → **respawn 보류, 로그만 기록** |

**respawn 이전 최소 경과 시간 = 5분(최소 유예) + 2분(TTL) = 7분.** 이 구조가 지켜지면 2026-08-07 사건(2분 만에 respawn)은 구조적으로 재발할 수 없다 — 기존 LIFECYCLE-1 최소 유예 시간을 그대로 지키기만 했어도 예방 가능했던 사건이었다.

### 시간 기반 종결 (Phase 8-4 결함 E)

respawn 5회 상한(D3, 하단 Step 5)은 "감지에 성공했을 때"만 작동하는 카운터다. 결함 A(시간 기반 실행체 부재)가 재발해 스케줄러 자체가 멈추면, 이 카운터는 증가하지 않아 무한 대기가 가능해진다.

**총 대기 시간 상한: 30분**(LIFECYCLE-1 5분 임계값의 6배 — SSOT 내부 값에서 직접 도출한 값이며 임의로 정한 값이 아니다). Task 위임 시각으로부터 30분이 경과하면 respawn 카운터·감지 성공 여부와 **무관하게** 해당 task를 BLOCKED로 전이하고 사용자에게 보고한다. respawn 5회 상한과 **독립된 별개의 백스톱**이며, 목적은 결함 A가 재발한 최악의 경우에도 무한 대기를 방지하는 것이다.

### 감지 + Respawn 절차 (Step 1~5)

```
[Step 1] spawn 직후 30초(D1) zombie check
  - zombie_check 함수 호출 (시그널 #1 + #2)
  - 좀비 확인 → 즉시 Step 3 진입 (정기 check timer 우회)
  - 정상 → Step 2 진입

[Step 2] 3분(D2) 정기 check (LIFECYCLE-1 5분 무보고 점검과 별도 병행)
  - 시그널 #1~#5 종합 판정
  - 좀비 확정 → Step 3
  - 단순 idle → wake-up 1회 발송 (TTL 3분) → 무응답 시 Step 3

[Step 3] shutdown + respawn
  a. SendMessage type=shutdown_request (config 정리용)
  b. agent name suffix: `<name>_r1` → `<name>_r2` → `<name>_r3` → `<name>_r4` → `<name>_r5` (D4)
  c. Agent 재spawn (동일 subagent_type / model / prompt)
  d. task metadata.respawn_count += 1 기록
  🔴 동일 모델 respawn 2회 연속 실패 → 3회차는 모델을 바꾸지 않고 재시도하지 않는다 (Step 4 옵션 B로 전환, Phase 9-4 FB-01-1)

[Step 4] respawn 2회차 (count=2) — 원인 분석 권고
  - 옵션 A: spec 수정 후 재spawn
  - 옵션 B: model 승격 (sonnet → opus, Team Leader 판단) — **장애 신호(API 529/overload/rate limit) 동반 시 1순위**로 적용(조건부 승격, 기존 옵션 자체는 신설 아님)
  - 옵션 C: task 분할 (단일 → 2 sub-task)
  - **장애 신호 정의**: 스폰·respawn 실패 응답에 API 529/overload/rate limit 관측(세션 모델 경로 동반 실패)
  - **실증(TR-01)**: 529 누적 8회 → wake-up 2회 → 동일 모델 respawn 2회 실패 → opus 전환 성공
  - **상한 정합**: 모델 전환 respawn도 상한 5회·suffix `_r1`~`_r5` 계산에 포함된다(별도 예산 신설 금지 — 상한 우회 경로 차단)

[Step 5] respawn 5회차(D3) 도달 (count=5) — 상한 도달
  - task 상태 BLOCKED 전이
  - 사용자 보고: "[respawn 상한] task=#N agent=<name> 누적 5회 좀비 — 원인 진단 필요"
  - 자동 respawn 중단 → 사용자 결정 대기
```

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
  respawn_count: 0      # 0 → 1 → 2 → 3 → 4 → 5 (5 도달 시 BLOCKED, D3)
  respawn_history:
    - { at: "2026-05-22T13:00:00Z", reason: "process absent 30s", suffix: "_r1" }
    - { at: "2026-05-22T13:03:00Z", reason: "shell prompt visible", suffix: "_r2" }
  status: "active"      # active | blocked | abandoned
```

### suffix 명명 규칙 (D4)

- 원본 spawn: `backend-dev`
- 1~5회차 respawn: `backend-dev_r1` → `backend-dev_r2` → `backend-dev_r3` → `backend-dev_r4` → `backend-dev_r5` → 도달 시 BLOCKED

**원본 name 재사용 금지** — 동시 등록 불가 + 이력 추적성 보장.

---

## §LIFECYCLE-6 SCHEDULER — 체크 스케줄러 arm/해제 + BUILDING 진입 차단 (ver6-2 PoC, Phase 8-3)

> **출처**: `docs/phases/phase-8-3/phase-8-3-plan.md` + `docs/phases/pre/phase-8-progress-signal-decision.md` (rev.2)
> **적용 범위**: ver6-2 PoC 라인 한정. §LIFECYCLE-5 RESPAWN과 마찬가지로 정본(`docs/SSOT/docs/`) 병합 전까지는 본 SUB-SSOT가 유일한 상세 근거
> **배경**: LIFECYCLE-1·LIFECYCLE-5는 규칙만 있고 **실행체(스케줄러)가 없었다**(결함 A) — spawn+30초 체크와 3분 정기 체크가 실제로는 한 번도 발동하지 않았다. 본 절이 그 실행체를 규정한다.
> **2층 기술**: 하네스 종속(R-1)을 피하기 위해 **인터페이스(무엇을 언제)** 와 **수단(참조 구현)** 을 분리한다. 타 하네스로 이식할 때는 수단 층만 교체하면 된다.

### 인터페이스 — 무엇을 언제 (하네스 독립)

| 항목 | 규정 |
|------|------|
| arm 시점 | **TEAM_SETUP 완료 직후**(팀원 ≥1) — Phase 9-4 FB-01-5 재정의. `BUILDING` 차단 게이트는 이행 재확인용 **2차 방어선**(존치·강화). 팀원 0인 Phase는 N/A |
| 폴링 주기 | 3분(D2) |
| 1차 체크 | spawn+30초(D1) — 3분 루프와 **다른 경로** |
| 판정 값 | 0=OK / 1=ZOMBIE(확정) / 2=SUSPECT(추정) / 3=SKIP(판정 불가) — `zombie_check.sh` 계약 그대로 |
| emit 조건 | 상태 **변화** 시 1줄 + **ZOMBIE는 항상** + **기동 시 1회 무조건** (조용한 미작동 방지, R-12) |
| 해제 시점 | TEAM_SHUTDOWN 도달 또는 팀원 0 |
| arm 판정 근거 | **사실 확인 3단**(마커 존재 + PID 생존 + 명령줄 대조). `status.md` 워처 필드는 **가시성용이며 판정 근거가 아니다** |

### 수단 — 참조 구현 (`zombie_watch.sh`)

| 서브커맨드 | 용도 |
|-----------|------|
| `--arm <team>` | 폴링 루프 백그라운드 기동(자기 detach) |
| `--stop <team>` | 해제 + 마커 정리 — **기본(`/tmp`) 상태 루트 구성 한정. 오버라이드 구성 금지**(아래 §`--stop` 사용 조건 참조) |
| `--status <team>` | arm 여부 3단 판정 결과 출력 |
| `--once <team> [agent]` | 1회 체크(spawn+30초 경로 전용) |
| `--self-test` | 내장 단위 테스트 |

**호출 규약**: `zombie_check.sh`는 **subprocess로만** 호출한다(`bash zombie_check.sh <agent> <team>`) — `source` 절대 금지. 반복 소싱의 `readonly` 충돌(A-2)·이름 충돌(P-1)·`set -euo pipefail` 전파(P-3)가 전부 소싱에서 나온다. 스케줄러 자체 상수는 `_ZW_` 접두사를 쓰고 `EXIT_OK`/`EXIT_SKIP` 등 일반적 이름을 export하지 않는다. **적용 범위**: 이 금지는 zombie_check.sh 호출에 한정한다 — zombie_watch.sh 는 readonly·export 를 쓰지 않으므로(코드행 실측 0건) 자체 헬퍼 모듈(zombie_watch_lib.sh·zombie_watch_poll.sh) 소싱에는 해당하지 않는다(Phase 9-1).

### arm / 해제 절차

- **arm 판정 3단** — `_is_watcher_armed()`: ① 마커 파일 존재 ② 마커 PID **생존** ③ 해당 PID **명령줄이 `zombie_watch.sh`를 포함**. 셋 중 하나라도 실패하면 미arm(유령 마커·PID 재사용을 마커 존재만으로 arm 오판정하지 않기 위함 — A-1 `list-sessions` 생존 확인, F-1 `declare -p` 실제 선언 확인에 이어 본 프로젝트 세 번째 적용)
- **해제** — `--stop`(기본 구성 한정, 아래 §`--stop` 사용 조건 참조)이 마커 PID에 TERM(필요 시 KILL) 전송 후 마커 삭제. 정상 해제 외에도 마커 정리는 `trap` EXIT/TERM/INT에서 수행 — 비정상 종료로 마커가 남아도 2·3단이 유령 arm 오판정을 방어한다
- **잔류 확인 시 기본 tmux 소켓 조회 금지** — 본 하네스의 팀은 기본 소켓이 아니라 `claude-swarm-{PID}` 별도 소켓에서 동작하므로, `tmux list-sessions`(기본 소켓)로 잔류 팀원을 확인하면 항상 "부재"가 반환되어 생존 중인 팀원을 잔류 0명으로 오판정한다(2026-08-08 Team Lead 실측 — 생존 중이던 `backend-dev`·`verifier` 2인을 잔류 0명으로 오판정, A-1과 동일한 실패 모드가 운영 절차에서 재현된 사례). 잔류 확인은 `zombie_check.sh`의 소켓 해소 경로(`_zc_resolve_socket_real`, 대상 PID의 ppid 체인 역추적 + `list-sessions` 생존 확인)를 경유한다

### arm 호출 규약 — 누가 · 언제 · 어떤 인자로 (Phase 9-3-4, DEF-9-3-001 ③)

> **실측 배경**: `cmd_arm`이 실팀에 대해 실행된 이력이 저장소 전체에 **0회**다(`/tmp/zombie-watch-markers/session-*.log` 부재로 확정). 규정·판정 기준·실행체는 이미 있었고 **부르는 주체만 정의돼 있지 않았다** — 결함 A와 동형이다. PAB-Leader가 `<team>` 자리에 **Phase ID**(`phase-2-1`)를 넣어 arm해 무한 SKIP 중이던 실사례(PID 18305, `~/.claude/teams/phase-2-1/` 부재)가 이 공백이 만든 결과다.
>
> 🔴 **관측성 공백 — 죽었는지 조용한 것인지 로그로 구별되지 않는다.** 위 PID는 **지금(2026-08-12 23:31 기준) 존재하지 않는다.** 그런데 마지막 로그 기록은 2026-08-11 21:00, **26시간 전**이다 — 언제·왜 사라졌는지는 로그로 판정할 수 없다. 폴링 루프의 SKIP 알림은 `list_warned`(§인터페이스, R2-1 알람 스팸 방지)로 **기동 1회만 emit하고 이후 무출력**하도록 설계돼 있으며, selftest 케이스 [18]·[19]가 이 침묵을 **정상 동작으로 단언**한다. 그 결과 "설계대로 조용한 것"과 "프로세스가 죽어서 조용한 것"이 로그상 **구별되지 않는다.** 이것이 아래 완료 기준이 `rc≠0` 뿐 아니라 **«반복 고지»도 동등한 대안으로 인정한 이유**다. Phase 9-3-4는 아래 ②(`cmd_arm` 검증)에서 **arm 시점 사전 차단**(존재하지 않는 팀은 애초에 루프를 띄우지 않음, rc=3)을 택했다 — 반복 고지 쪽으로 갔다면 케이스 [18]·[19]가 검증해 둔 "1회만 emit" 계약을 깨뜨렸을 것이기 때문이다. 이미 뜬 루프의 관측성(죽었는지 조용한지 사후에 구분하는 문제)은 본 Task 범위 밖으로 남는다.

| 항목 | 규약 |
|------|------|
| **호출 주체** | **Team Lead**(본인 — 자동화 훅이 아니다). §SPAWN_GATE와 같은 이유로 `SubagentStart`가 에이전트 식별자를 전달하지 않아(`settings.json:117-121` 실측) 훅 기반 자동 arm은 불가하다 |
| **호출 시점** | **TEAM_SETUP 완료 직후**(팀원 ≥1 확인 시점) — Phase 9-4 FB-01-5, arm 시점 조기화. `BRANCH_CREATION → BUILDING`(또는 `TASK_SPEC → BUILDING`) 전이 시점의 차단 게이트는 arm 이행을 **재확인하는 2차 방어선**이며, 그 시점에도 미arm이면 즉시 arm 후 진입 |
| **`<team>` 인자** | 🔴 **팀 디렉토리명(= 세션 디렉토리명)이다** — `~/.claude/teams/<team>/config.json`이 실재하는 그 이름. **Phase ID(`phase-N-M`)를 넣지 않는다.** Phase ID는 세션 디렉토리명과 다를 수 있고, 다르면 `cmd_arm`이 대상 없는 루프를 무한히 돈다(위 실사례) |
| **차단 게이트 집행 주체** | **Team Lead.** LIFECYCLE-6은 판정 근거(arm 3단)만 정의하며, 게이트를 실제로 세우고 `--arm`을 호출해 여는 행위는 자동화가 아니라 Team Lead의 절차 준수다 |

### 차단 게이트 — BUILDING 진입 시

```
BUILDING 진입 시 (출발점이 TASK_SPEC 이든 BRANCH_CREATION 이든 무관):
  팀원 수 ≥ 1  AND  LIFECYCLE-6 워처 미arm  →  진입 차단
  → Team Lead 가 zombie_watch.sh --arm 으로 워처를 arm 한 후 진입 허용
  → 팀 미사용(팀원 0) Phase 는 N/A
```

> `TEAM_SETUP → BUILDING`은 **존재하지 않는 전이**다(master-plan §3.3 초안 오류, 취소선 정정 완료). 실제 경로는 `TASK_SPEC → BUILDING`(4th) 또는 `TASK_SPEC → BRANCH_CREATION → BUILDING`(5th)이며 재진입 경로가 15곳 이상이지만, **모든 경로가 `3-workflow.md` §3.1 Action Table의 BUILDING 행 하나로 수렴**하므로 조건은 "BUILDING 진입 시" 하나로 충분하다. WT-7 G-C(worktree 미설정 차단) 선례를 준용한다.

정상 경로에서는 이 게이트가 열려 있을 일이 없다 — arm은 이미 TEAM_SETUP 완료 직후 수행됐어야 한다(위 인터페이스 표). 본 게이트는 그 이행이 누락된 경우를 잡는 **재확인·안전망**이다(Phase 9-4 FB-01-5).

### spawn+30초 1차 체크 — 루프 밖 별도 경로

- 3분 폴링 루프와 **다른 경로**다. Team Lead가 `Bash run_in_background`로 1회성 지연 체크를 걸고, 좀비 확인 시 즉시 §LIFECYCLE-5 Step 3(respawn)로 진입해 정기 체크 타이머를 우회한다
- `spawned_at`은 **Team Lead가 직접 기록**한다 — `/tmp/agent-spawn-times/{team}_{agent}.ts`
- `SubagentStart` 훅은 에이전트 식별자를 전달하지 않는다(`settings.json:117-121` 실측 확인, Phase 8-3). 따라서 **`team-sentinel.sh`는 본 절차 구현 대상에서 제외한다** — 훅 기반 자동화가 불가능하다는 사실 확인이며, 향후 훅이 식별자를 전달하도록 개선되면 재검토한다(현재는 재검토 보류 상태를 명시적으로 남겨 향후 같은 조사를 반복하지 않도록 한다)

### 진행 신호(pane 콘텐츠 해시) — 시그널 #4의 거짓 양성 억제 게이트

> decision rev.2 §4.4 원문 — **한 글자도 바꾸지 않는다** (채택 조건 3):

```
진행 신호(pane 콘텐츠 해시)의 성격과 적용 범위:
  성격: 시그널 #4의 거짓 양성 억제 게이트 — 신규 좀비 감지 수단이 아니다
  ✅ inbox mtime stale + 화면 변화 있음 → SUSPECT 취소 (통신 없는 정상 작업 보호)
  ❌ 유휴 정지 좀비 감지 불가 — 정상 유휴 대기와 관측값이 동일(둘 다 고정, 실측)
  ❌ 턴 중 교착 감지 불가 — TUI 타이머로 해시가 계속 변함 (R-a, 2026-08-08 실측)
     이 영역은 결함 E 총 대기 상한 30분이 종결한다(자동 복구 아님)
전제: Claude Code TUI가 alternate screen(alternate_on=1)이며 유휴 시 갱신을 멈춘다는 실측
      (tmux 3.6a, 2026-08-08). TUI 버전 변경 시 재검증 필요
```

**게이트 조건**: `inbox mtime stale(>180s) AND pane 해시 변화 없음 → SUSPECT` / `stale BUT 해시 변화 있음 → OK(억제)`. **해시는 워처 프로세스 메모리에만 보관**한다(파일 금지 — A-1 유령 소켓과 동일 계열의 유령 마커 재발 방지, D-2). **상태 키는 `(agent_name, pane_id)` 쌍**이다 — respawn(`<name>` → `<name>_r1`)은 새 pane을 가지므로 이름만 키잉하면 낡은 pane 해시와 새 pane을 비교해 억제 게이트가 항상 SUSPECT를 취소하고 **respawn 직후 좀비를 영구히 놓친다**(§7 누락 A). `config.json` 부재로 `pane_id` 조회 자체가 불가하면(누락 B) 게이트는 unavailable이 되어 **기존 시그널 #4 판정을 그대로 유지**한다(억제 실패가 확정 판정으로 새지 않도록).

### 좀비 4종 커버리지 — 미커버를 명시한다 (과장 금지)

| 유형 | 수단 | 상태 |
|------|------|:----:|
| (a) 프로세스 사망 | 시그널 #1 | ✅ |
| (b) 세션 사망(shell prompt 복귀) | 시그널 #2(A-1 ppid 체인 복구) | ✅ |
| (c) 살아있으나 유휴 정지 | **미커버** — 시그널 #3(inbox unread) 필요, 검증 보류 | ❌ |
| (d) 턴 진행 중 교착 | **감지 불가** — 결함 E 총 대기 상한 30분이 종결(자동 복구 아님, BLOCKED + 사용자 보고) | ❌ |

LIFECYCLE-6이 좀비를 전부 잡는 것처럼 기술하지 않는다 — (c)·(d)는 본 스케줄러의 설계상 한계이며, (d)는 별도 백스톱(결함 E)이 담당한다.

**R2-5 한계(Phase 8-5, verifier 지적)**: ❌ 진단 행위 자체가 신호를 리셋 — wake-up 발송이 대상의 inbox mtime 을 갱신하므로 재확인 시 항상 OK 로 보인다. 해소 신호는 #5(last_send_at, 순수 송신)이나 미구현.
차선책은 zombie_watch.sh 가 자기 발신 이후 갱신을 SKIP(3)으로 처리하는 것이다 (Task 8-5-3).

### `--stop` 사용 조건 — 조건부 강등 (Phase 9-4, FB-01-5)

🔴 **`--stop`은 기본(`/tmp`) 상태 루트 구성에서만 허용한다.** `cmd_stop`의 실제 동작은 `rm -rf "${_ZW_STATE_ROOT:?}/${team}"`이며, `_ZW_STATE_ROOT`를 프로젝트 내부 경로로 오버라이드한 구성에서 그대로 실행하면 **프로젝트 디렉터리 자체가 삭제될 위험**이 있다 — 오버라이드 구성에서는 `--stop` 사용을 금지한다.

**표준 회수 절차**: `--stop` 대신 자식 프로세스 kill을 우선한다. bash 3.2 환경에서 `trap` 처리 지연이 실측됐다(TR-01) — 정리 신호가 즉시 반영되지 않을 수 있으므로, kill 후 arm 3단 판정(§arm/해제 절차)으로 실제 해제(미arm)를 확인한다.

### arm·회수 체크리스트 (Phase 9-4, FB-01-5)

**arm** (TEAM_SETUP 완료 직후, 팀원 ≥1일 때 즉시):
1. 팀 디렉토리명 확인 — `~/.claude/teams/<team>/config.json`이 실재하는 그 이름을 쓴다. **Phase ID(`phase-N-M`)를 넣지 않는다**(§arm 호출 규약 실사례 참조)
2. `zombie_watch.sh --arm <team>` 실행
3. `zombie_watch.sh --status <team>` = ARMED 확인 + 마커 PID의 실행 경로(명령줄)가 `zombie_watch.sh`인지 대조

**회수** (TEAM_SHUTDOWN 도달 또는 팀원 0):
1. 자식 프로세스 kill을 우선한다 — 기본(`/tmp`) 구성이 아니면 `--stop` 금지(위 §`--stop` 사용 조건)
2. `zombie_watch.sh --status <team>`로 재확인 — 미arm(해제 완료) 확인

---

