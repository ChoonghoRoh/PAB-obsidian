# Leader 연계 계약 — SUB-SSOT (TEAM-LEAD)

> **버전**: 1.0 | **생성일**: 2026-08-11 (Phase 9-2, Task 9-2-6)
> **적용 범위**: 본 문서는 **외부 인터페이스 계약**이다. PAB-Leader 저장소 구현자가 참조할 문서를 이 하나로 한정하기 위해 `2-lifecycle-procedure.md`(내부 절차)와 분리했다. 스키마 v2 전이 시 **파일 단위 버저닝**이 가능하다. **PAB-Leader 저장소 수정은 본 Phase 범위 밖이다.**
> **분리 근거**: REFACTOR-2(700줄)가 아니라 **REFACTOR-3 PLANNING**이다 — 단일 파일 설계안(523줄)은 계획 단계에서 500 초과를 설계하는 것이라 규정에 정면으로 걸리고 G2 지적 대상이 된다.
> **근거 실측**: `docs/phases/phase-9-2/reports/phase-9-2-spike-r9.md` (VAL-1~6, 2026-08-11)

---

## 1. CLI 시그니처

```
zombie_watch.sh --once <team> [<agent>] [--format=json] [--act={report|clean|none}]
```

| 인수 | 필수 | 의미 |
|------|:----:|------|
| `<team>` | ✅ | 대상 팀명 |
| `<agent>` | — | 생략 시 팀 전원 |
| `--format=json` | — | 생략 시 사람이 읽는 1행 요약 |
| `--act=` | — | 기본 `report` |

**출력 채널** *(9-3-3 CR-4a 사실 정정 — 계약과 코드가 어긋나 있었다: `zombie_watch.sh` L76 `mkdir -p` · L99 `date +%s > wake_marker` · L110 `printf > state_file`, 전부 기본(report) 경로. `--act`는 현행 코드에 존재조차 않는다)*: 스크립트는 **판정 결과·권고 이벤트를 파일이나 inbox 로 배달하지 않는다** — 수신자는 **호출자**이며 채널은 stdout + 종료코드다. 유효 호출자는 `2-lifecycle-procedure.md` §SPAWN_GATE가 정한 2가지(Team Lead `--once` / Leader 외부 폴링)뿐이다. **단 `_ZW_STATE_ROOT` 하위의 내부 상태 마커(`.state` edge-triggered 판정용 · `.wake` R2-5 자기발신 가드용)는 배달이 아니라 스크립트 자신의 기억이므로 이 금지의 대상이 아니다.** 외부로 나가는 유일한 쓰기는 `--act=clean` 의 wake-up 실발송(대상: 에이전트 inbox)뿐이다.
## 2. `--act` 3모드

| 모드 | 판정 | 권고 이벤트 | 잔해 정리 | wake-up 실발송 | 용도 |
|------|:----:|:-----------:|:---------:|:--------------:|------|
| `report` (기본) | ✅ | ✅ | ❌ | ❌ | Leader가 조치를 직접 통제 |
| `clean` | ✅ | ✅ | ✅ | ✅ **idle 한정** | 자립 운용 / Leader 위임 |
| `none` | ✅ | ❌ | ❌ | ❌ | 진단·디버깅 |

**기본값이 `report`라는 것이 계약의 핵심이다.** spike §5.4는 *"스크립트의 책임은 SUSPECT 판정과 권고 이벤트 발신에서 끝나고 실행 권한은 Team Lead에 귀속한다"* 고 권고했고, `report`가 그 권고를 그대로 구현한다. `clean` 은 **Leader가 명시적으로 위임을 선언했을 때만** 켜지는 opt-in 경로다.

### 2.1 `clean` 의 재시도 = **wake-up 실발송** (권고 이벤트 대체안 폐기)

9-2-2 spike 결론이 **`배달 경로 = 둘 다`** 로 나왔다 — 스크립트는 Team Lead를 거치지 않고 직접 배달할 수 있다(VAL-2 3/3 · VAL-4 단독 wake). 따라서 재시도를 "권고 이벤트만 발신"으로 두는 대체안은 **수단이 없어서가 아니라 있는데 안 쓰는 것**이 되므로 폐기한다.

**채택 경로 = H1(`inboxes/{agent}.json` 직접 쓰기) + `from: "zombie-watch"` 고정 표기.**

| 경로 | 시행/배달 | 수신 형태 | 실행 중 인터럽트 | 발신자 표기 | 판정 |
|------|:--------:|-----------|:----------------:|-------------|:----:|
| 대조군 `SendMessage` | 5/5 | `teammate-message` | ❌ idle-gated | 실제 에이전트명 | 기준선 |
| **H1** inbox 직접 쓰기 | **3/3** | `teammate-message` | ❌ idle-gated | `from` 값 그대로 | ✅ **채택** |
| H2 `tmux send-keys` | 2/2 | `queued_command` | ✅ 턴 중간 즉시 | 없음 — `origin.kind=human` | ❌ **기각** |

**H2 기각**: 실행 중 인터럽트라는 강점이 그대로 결함이다. `origin.kind=human` 으로 주입되어 에이전트가 **사람 지시로 오인**하고 실행 중 강제 중단된다 — 프로토콜 우회다. tmux 의존이라 미설치 환경에서 동작하지 않는 것도 계약 문서로서 결격이다.

**H1 채택**: teammate 의미 보존 · tmux 비의존 · `from` 이 자동 발신임을 수신자에게 드러냄. 그리고 **idle-gated가 여기서는 장점**이다 — 대상이 실행 중이면 주입되지 않고 대기하다 idle 전환 시 플러시되므로, **SUSPECT가 오탐이어도 정상 작업을 중단시키지 않고 진짜 idle이면 깨운다.**

### 2.2 🔴 도달성 — 칸마다 실측/미실측을 표기한다

| SUSPECT의 실제 상태 | `SendMessage`·H1 | H2 `tmux send-keys` |
|---------------------|:----------------:|:-------------------:|
| **idle** | **도달 O — 실측** (VAL-4 C3·H1c 단독 wake) | 도달 O — **미실측** |
| **busy** | **도달 X — 실측** (6건 대기 후 일괄, VAL-5) | **도달 O — 실측** (VAL-3) |
| **hung** | **미실측** | **미실측** |

**hung 칸이 빈 것은 누락이 아니라 판정 거부다.** H2가 hung을 깨운다는 근거는 없다 — H2는 pane 입력 **버퍼에 문자를 넣을 뿐**이고 그 버퍼를 읽는 것은 **대상 프로세스 자신**이다. 정말 멈췄다면 큐에 쌓인 키 입력도 처리되지 않는다. spike VAL-3의 `Press up to edit queued messages` 관측은 **대상이 살아서 큐를 관리 중이었다는 증거**이지 hung 도달의 증거가 아니다.

**위험 범위는 억제 게이트가 이미 좁혀 놓았다.** `zombie_watch_lib.sh:110 _zw_suppress_check()` 가 *inbox stale + pane 해시 변화* 시 SUSPECT를 취소하므로 **busy 에이전트는 애초에 wake 대상이 아니다.**

```
SUSPECT 모집단 = pane 정지 = idle 또는 hung
  idle → 실측 도달          hung → 두 경로 모두 미검증
```

남는 미지는 **hung 한 칸뿐이고, 그 칸은 두 경로 다 미검증이므로 H2 채택의 근거가 되지 못한다.**

> **계약 문구**: 자동 발송은 **idle 대상 재시도로 한정**한다. hung 판정 시에는 Team Lead 판단(respawn 포함)으로 전환하며, **스크립트가 hung을 깨울 수 있다고 가정하지 않는다.**

⚠ **9-3 필수 시험 항목**: H1의 쓰기 대상 `inboxes/{agent}.json` 은 **정체 판정에 쓰이는 바로 그 파일**이다(`_zw_inbox_mtime_real`). wake-up 발신이 mtime을 갱신하고 런타임 drain이 한 번 더 갱신한다 — R2-5(`wake_marker` → `SKIP`)가 이 자기발신 리셋을 처리하고 있으므로, **H1 채택 시 R2-5 경로를 반드시 함께 시험**해야 한다 (spike §4.5).

## 3. JSON 스키마 `zombie-watch/1`

```json
{
  "schema": "zombie-watch/1",
  "team": "phase-9-2",
  "generated_at": "2026-08-11T09:13:36+09:00",
  "agents": [
    { "name": "backend-dev", "status": "SUSPECT", "action_taken": "wake_sent",
      "signals": { "process": "present", "pane": "unchanged", "inbox_mtime_age_s": 214 },
      "detail": "inbox 정체 + pane 해시 불변 — 억제 게이트 미발동" }
  ],
  "summary": { "OK": 2, "IDLE_REPORTED": 0, "SUSPECT": 1, "ZOMBIE": 0, "SKIP": 0 },
  "rc": 2
}
```

### 3.1 `status` enum — 9-2-4 상태 기계와 동일 어휘

`OK` · `IDLE_REPORTED` · `SUSPECT` · `ZOMBIE` · `SKIP` — **5종 외 값 금지.**

| JSON `status` | `2-lifecycle-procedure.md` 상태 기계 | 비고 |
|---------------|--------------------------------------|------|
| `OK` | `WORKING` 정상 판정 결과 | — |
| `IDLE_REPORTED` | `IDLE_REPORTED` | 시그널 #6 수신. nudge 1회, respawn 금지 |
| `SUSPECT` | `SUSPECT` | TTL 2분 |
| `ZOMBIE` | `ZOMBIE-CONFIRMED` | **전선(wire) 표기.** 동일 상태의 축약형이며 별개 상태가 아니다 |
| `SKIP` | — | **생애주기 상태가 아니라 판정 불가 신호**(rc=3). 상태 기계에 대응 상태를 두지 않는다 |

⚠ **어휘를 새로 만들지 않는다.** 계약과 상태 기계가 갈리면 9-3이 두 벌을 구현하게 되므로, 위 대응표를 벗어난 표기는 계약 위반으로 다룬다.

## 4. 종료코드

| rc | 의미 | 심각도 |
|:--:|------|:------:|
| `0` | 정상 (OK) | 0 |
| `1` | ZOMBIE 확정 | 3 |
| `2` | SUSPECT 추정 | 2 |
| `3` | 판정 불가 (SKIP) | 1 |

**다건 판정 시 rc는 `최심각도`를 따른다** — `ZOMBIE > SUSPECT > SKIP > OK` (`_zw_rc_severity`). 예상 외 값은 최우선으로 취급해 숨기지 않는다. **"한 명이라도 ZOMBIE면 rc=1"** 이며, 평균이나 다수결이 아니다.

## 5. `jq` 제약 (R-6)

- **출력 생성에 `jq`를 쓰지 않는다** — `printf` 조립. `jq` 미설치 환경에서도 `--format=json` 이 동작해야 한다
- `jq` 는 **입력 파싱에만** 사용하며, **부재 시 `SKIP`(rc=3)** 으로 종결한다. 파싱 불가를 OK로 위장하지 않는다

## 6. 버전·폴백 정책 (R-3)

- `schema` 필드로 버전을 고정한다. 필드 추가는 minor, 의미 변경·삭제는 **`zombie-watch/2`** 로 올린다
- Leader는 **모르는 필드를 무시**하고, **모르는 `schema` 값은 처리 거부**한다
- 🔴 **ver6-2는 본 계약이 충족되지 않아도 자립 동작한다** — Leader 연계가 없거나 스키마가 맞지 않으면 기존 폴백 폴링(3분 주기)을 유지한다. 계약은 **연계 시의 인터페이스**를 정할 뿐, ver6-2의 동작 조건이 아니다

---

**문서 관리**: v1.0 · Phase 9-2 Task 9-2-6 · 근거 `phase-9-2-spike-r9.md`(21,930 bytes / VAL 6건)
