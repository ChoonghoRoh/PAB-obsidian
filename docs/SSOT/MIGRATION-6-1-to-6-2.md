# 6-x → ver6-2 이행 가이드 — LIFECYCLE-6 체크 스케줄러 도입

> **버전**: 1.1 | **작성일**: 2026-08-09 | **갱신**: 2026-08-14 (Phase 9-4, FB-01-3ⓐ 보완 — 6-x 통합 확장: 출발점 판별 §0, 9-1~9-4 변경분, 훅 갱신 확인 §3.6, 라인 종료 선언 §8)
> **대상 독자**: `ver6-0`/구 v8.2 계열 · `ver6-1` PoC(LIFECYCLE-5, 2026-05-22) · `ver6-2` 구버전(9-x 이전)을 이미 이식해 사용 중인 프로젝트 — 아래 §0에서 자신의 출발점을 먼저 판별한다.
> **전제**: 본 문서는 [UPGRADE.md](UPGRADE.md) §3 일반 절차를 대체하지 않는다. **세대 이행 시 추가로 확인해야 할 것**만 다룬다. 이 저장소의 Phase 번호(8-1~9-4)를 근거로 인용하지만, 그 배경을 몰라도 이해되도록 썼다.

---

## §0. 출발점 판별 — 당신은 어디서 오는가

| 출발점 | 특징 | 본 문서 사용법 |
|:-:|------|----------------|
| ⓐ `ver6-0` / 구 v8.2 계열 | `scripts/zombiecheck/` 자체가 **처음 보는 개념** — LIFECYCLE-5·6 모두 미도입 | §1 ⓐ 문단부터 전체를 읽는다 |
| ⓑ `ver6-1` | LIFECYCLE-5(좀비 감지 + Respawn)만 있음, 체크 스케줄러(LIFECYCLE-6) 없음 | 본 문서 전체(원 제목 그대로의 대상) |
| ⓒ `ver6-2` 구버전(9-x 이전) | LIFECYCLE-5·6 모두 있으나 Phase 9(9-1~9-4) 변경분 미반영 | §3.0 안내대로 §3.6만 확인하면 충분한 경우가 많다 |

---

## 1. 왜 업그레이드해야 하는가 — 완곡하게 쓰지 않는다

> **ⓐ 출발점 독자에게**: 아래 "그대로 쓰면 감지가 사실상 동작하지 않는다"는 `ver6-1`을 전제로 한 문장이다. `ver6-0`/구 v8.2 계열에는 애초에 `scripts/zombiecheck/`가 없었으므로, 결함 A·G는 "재발"이 아니라 **처음 도입되는 기능**이다. §2 변경표는 `ver6-1`을 기준점으로 삼으므로 ⓐ 출발점은 표 전체를 "신규 추가 기능"으로 읽으면 된다 — 아래 §2 "6-0에서 오는 경우 추가분"도 함께 확인한다.

**`ver6-1`을 그대로 쓰면 좀비 감지가 사실상 동작하지 않는다.**

- **결함 A (실행체 부재)**: `ver6-1`의 LIFECYCLE-1·LIFECYCLE-5는 "spawn 후 30초에 1차 체크, 이후 3분마다 정기 체크"라는 **규칙만 있고, 그 규칙을 실제로 주기적으로 실행하는 프로세스(스케줄러)가 없었다.** Team Lead가 수동으로 `zombie_check.sh`를 호출하지 않는 한 체크는 **한 번도 발동하지 않는다.**
- **결함 G (플랫폼 전제 오류)**: macOS 환경에서 `zombie_check.sh`가 **정상 프로세스까지 전건 오탐**(ZOMBIE로 오판정)했다. 배포 대상이 macOS라면 이 결함 하나만으로도 업그레이드 사유가 충분하다.

이 두 가지가 해소된 것이 `ver6-2`다. 아래 §2가 무엇이 어떻게 바뀌었는지 정리한다.

---

## 2. 무엇이 바뀌었나 (Phase 8-1~8-6 전체)

`docs/SSOT/VERSION.md` 변경 이력이 정본이다. 아래는 요약이며, **8-3만이 아니라 8-2·8-4까지 포함해야 완결된 그림**이 된다 — 8-3(스케줄러)은 8-2(플랫폼 중립화)·8-4(신호원 정밀화)가 먼저 고쳐놓은 `zombie_check.sh` 위에서 동작하기 때문이다.

| Phase | 무엇을 고쳤나 | 핵심 |
|-------|------|------|
| **8-1** | `ver6-1` → `ver6-2` 라인 신설(148파일 전량 복제). `ver6-1/`은 이 시점부터 **동결**(수정 금지) | 작업 라인 분리만, 코드 변경 없음 |
| **8-2** | `zombie_check.sh` **플랫폼 중립화** — `uname` 분기 없는 공통 문법(`ps -eo pid,command` / `date -r <file> +%s` / `${HOME}`)으로 전환, macOS 전건 오탐(결함 G) 해소 | **종료 코드 4값 계약 확립**: `0`=정상 / `1`=좀비 확정 / `2`=추정 좀비 / `3`=판정 불가(SKIP, 신규) |
| **8-4** | 신호원 정밀화 — 활동 신호원을 `config.json`(팀 전체, 합류·이탈 시에만 갱신)에서 `inboxes/{agent}.json`(에이전트별, 메시지 송수신 시 갱신)로 교체. 시그널 #2(shell prompt 감지)의 소켓명 해소를 대상 프로세스의 **ppid 체인 역추적**(최대 3단계 + 생존 확인)으로 복구(이전엔 사문화 상태였다) | **폴링 계약** 확정: 최소 판정 유예 5분 · 확인 메시지 TTL 2분 · respawn 이전 최소 7분 · 총 대기 상한 30분 |
| **8-3** | **LIFECYCLE-6 체크 스케줄러**(`zombie_watch.sh`) 신설 — 결함 A를 실제로 해소하는 실행체. 3분 폴링 루프 + spawn+30초 1차 체크(별도 경로) + arm 판정 3단(마커 존재+PID 생존+명령줄 대조) + edge-triggered emit + 억제 게이트(pane 콘텐츠 해시 변화 → SUSPECT 취소) | **BUILDING 진입 전 워처 arm 강제**(차단 게이트 신설) |
| **8-5** | 신호원 정비 — `inboxes/{agent}.json`가 **수신 시에도 갱신**되므로 "무응답→wake-up→재확인" 절차가 wake-up 발신 자체로 판정 근거를 리셋하는 결함(R2-5)을 발견, `SKIP(3)` 반환으로 완화. D-1 필터(실 pane 미보유 멤버 제외) 가시화 | status.md `agents:` 블록 신설(스케줄러 연계 추적) |
| **8-6** | 검증 매트릭스 — macOS·Linux 2개 플랫폼 self-test, 실 3분 주기 ≥2회 감지 실증, tester 적발 결함 수정(단건 조회 경로의 필터 우회 등) | **KPI-01(오탐률 0%) 미충족을 구조적 한계로 확정** — §4 참조 |
| **9-1** | `zombie_watch.sh`·`zombie_watch_selftest.sh` 500줄 한도 근접 해소 — 헬퍼/폴링 로직을 `zombie_watch_lib.sh`·`zombie_watch_poll.sh`(source 전용)로 분리 | REFACTOR-1 Lv1 파일 분할, 동작 변화 없음(회귀 0) — §7 참조 |
| **9-2** | 에이전트 생애주기 상태 기계(10상태) + 주체 경계 정의 신설. `2-lifecycle-procedure.md`를 `1-orchestration-procedure.md`에서 Lv1 분리 | LIFECYCLE-1~6 공통 어휘 확립 |
| **9-3** | 판정 정확도 실측 3건(V-1 억제 게이트 진위 판별·V-6·D8-9) 해소 확인 + **시운전(TR-01) 1회 완주** | 안정화 판정 기준 4건 첫 충족 |
| **9-4** | TR-01 피드백 4건 반영 — 훅 파서 3지점(FB-01-3ⓑ) + 카운터 인라인 주석 금지 수칙(FB-01-3ⓐ) + 모델 전환 조건부 승격(FB-01-1) + arm 시점 재정의·체크리스트(FB-01-5) + 이식 문서(`INSTALL.md` 신설·본 문서 확장) | `ver6-2` 라인 마감 — §8 참조 |

### 6-0에서 오는 경우 추가분

ⓐ 출발점은 위 표(8-1~9-4) 전체가 신규 도입분이다. 추가로 확인할 것:

- `settings.json` 훅 배선에 `state-transition-guard.sh`·`line-count-monitor.sh` 등 9종이 전부 등록돼 있는지 — `ver6-0`에 없던 훅을 포함할 수 있다
- LIFECYCLE-1~4(에이전트 관리 절차)는 `ver6-0`에도 있었으나, LIFECYCLE-5·6(본 문서 대상)은 전무했다 — 개념부터 SUB-SSOT `2-lifecycle-procedure.md` 정독을 권장한다

**결함 A~G 최종 해소 상태** (`ver6-1` 대비, 8-6 tester/verifier 독립 재현 확인):

| # | 결함 | 상태 |
|:-:|------|:---:|
| A | 시간 기반 실행체 부재 | ✅ 해소 (8-3, `zombie_watch.sh` polling loop) |
| B | 감시자-대기자 역설 | ✅ 해소 (8-3, arm이 BUILDING 진입 차단 게이트) |
| C | 호출 경로 없음 | ✅ 해소 (8-3, subprocess 실 호출) |
| D | LIFECYCLE-1 절차 미세화 | ✅ 해소 (8-4, 폴링 계약 명문화) |
| E | 종결 endpoint 부재 | ✅ 해소 (8-4, 총 대기 30분 상한) |
| F | tmux 환경 전제 | ✅ 해소 (8-4, tmux 없어도 시그널 #1 단독으로 오탐 없음) |
| G | 플랫폼 전건 오탐 | ✅ 해소 (8-2, 플랫폼 중립화) |

---

## 3. 업그레이드 절차

기본 절차는 [UPGRADE.md §3](UPGRADE.md#3-업그레이드-절차-이식된-프로젝트에서)를 그대로 따른다:

```
bash <번들경로>/install.sh <대상프로젝트> --upgrade
```

`scripts/zombiecheck/`는 이미 UPGRADE.md §1.1 프레임워크 파일 표에 등록돼 있으므로 6개 파일(`zombie_check.sh`·`zombie_check_selftest.sh`·`zombie_watch.sh`·`zombie_watch_selftest.sh`·`zombie_watch_lib.sh`·`zombie_watch_poll.sh`)이 자동으로 갱신된다. 뒤의 두 개(`zombie_watch_lib.sh`·`zombie_watch_poll.sh`, Phase 9-1 신설)는 `zombie_watch.sh`가 `source`하는 **헬퍼/폴링 분리 모듈**이며 단독 실행 대상이 아니다 — §3.1에서 실행 권한을 별도로 다룬다. **세대 이행 시 이것만으로는 부족하다** — 아래를 추가로 확인한다.

### 3.0 출발점별 확인 (§0 대응)

- **ⓐ(`ver6-0`) / ⓑ(`ver6-1`)**: 아래 §3.1~§3.6을 전부 확인한다.
- **ⓒ(`ver6-2` 구버전, 9-x 이전)**: 실행 비트·self-test는 이미 정상일 가능성이 높다 — **§3.6(훅 갱신 확인)만 확인해도 충분한 경우가 많다.** 단, 9-1 파일 분할(§2) 이후 처음 `--upgrade`하는 경우는 §3.1 실행 권한도 함께 재확인한다.

### 3.1 실행 권한

`zombie_watch.sh`는 **자기 자신을 서브프로세스로 재실행**한다(`--_loop-internal` 루프 기동). `install.sh`가 배포 시 `chmod +x`를 수행하지만, 수동으로 파일만 복사했다면 반드시 확인한다. **단, 대상은 6개 전부가 아니라 실행형 4개뿐이다** — `zombie_watch_lib.sh`·`zombie_watch_poll.sh`는 `source` 전용 모듈이라 실행 비트가 필요 없으며, `install.sh`의 `EXEC_FILES` 목록에서도 의도적으로 제외돼 있다(설치본 실측: `644`로 배포, 동작 정상). 이 둘까지 `-rwxr-xr-x`를 기대하고 확인하면 "설치 실패"로 오독해 불필요한 `chmod +x`를 하게 되니 주의한다.

```bash
ls -la scripts/zombiecheck/*.sh
# 실행형 4개 — zombie_check.sh / zombie_check_selftest.sh / zombie_watch.sh / zombie_watch_selftest.sh
#   → -rwxr-xr-x 확인, 아니라면 직접 부여:
chmod +x scripts/zombiecheck/zombie_check.sh scripts/zombiecheck/zombie_check_selftest.sh \
         scripts/zombiecheck/zombie_watch.sh scripts/zombiecheck/zombie_watch_selftest.sh

# source 전용 2개 — zombie_watch_lib.sh / zombie_watch_poll.sh
#   → -rw-r--r--(644)가 정상. 실행 비트 없다고 chmod +x 하지 않는다.
```

### 3.2 `--self-test`로 이식 검증

업그레이드 직후 반드시 두 self-test를 실행해 이식 환경에서 정상 동작하는지 확인한다:

```bash
bash scripts/zombiecheck/zombie_check.sh --self-test    # 기대: 21/21 PASS
bash scripts/zombiecheck/zombie_watch.sh --self-test    # 기대: 29/29 PASS
```

macOS(bash 3.2.57)·Linux(bash 5.1.16)에서 실측 확인됐다(8-6, 각 3회 반복 flaky 0). 다른 bash 버전이라면 이 두 명령의 결과부터 확인하고 진행한다.

### 3.3 `jq` 의존성 — 반드시 사전 확인

`zombie_watch.sh`는 팀원 목록 조회(누가 폴링 대상인지 판단)에 `jq`를 사용한다. **`jq`가 없으면 폴링 대상 목록 자체를 못 얻어 SKIP으로 빠진다** — 감지가 조용히 멈춘다.

```bash
command -v jq                       # 존재 확인
jq -n '"x"|test("x")'               # 정규식 필터 지원 확인 — 반드시 true 가 나와야 한다
```

두 번째 명령이 실패하거나 예외를 내면 `test()` 정규식을 지원하지 않는(oniguruma 미포함) `jq` 빌드다. 이 경우 팀원 필터링 로직(D-1 제외 필터 포함)이 **조용히 전부 죽어 감시 전체가 무력화**될 수 있다(8-6 verifier 지목, 이 저장소 환경에서는 재현되지 않았으나 배포 대상 환경마다 재확인이 필요한 일반적 리스크다).

### 3.4 TEAM_SETUP 완료 직후 워처 arm (Phase 9-4 FB-01-5 재정의)

`ver6-2`는 워처(`zombie_watch.sh --arm <team>`)가 **TEAM_SETUP 완료 직후**(팀원 ≥1) 켜져 있을 것을 요구한다. `BRANCH_CREATION → BUILDING` 전이 시점의 차단 게이트(`docs/SSOT/3-workflow.md` §AGENT-LIFECYCLE LIFECYCLE-6 행)는 arm의 정상 시점이 아니라 그 이행을 재확인하는 **2차 방어선**이다 — 미arm 상태로 그 시점까지 온 경우에 한해 진입을 차단한다. Team Lead 절차에 TEAM_SETUP 직후 `--arm` 호출이 포함돼 있는지 확인한다.

### 3.5 지원 환경

| 항목 | 확인됨 |
|------|------|
| macOS | bash 3.2.57 (arm64) — `declare -A` 연관 배열 미지원 전제로 작성됨 |
| Linux | bash 5.1.16 (x86_64, procps-ng, systemd) |
| tmux | 있으면 시그널 #2(shell prompt 감지) 활성, 없으면 시그널 #1 단독으로 SKIP 없이 정상 동작(오탐 없음 확인) |

### 3.6 훅 갱신 확인 (Phase 9-4 신설)

`--upgrade`는 `.claude/hooks/*.sh` 전체를 프레임워크 파일로 덮어쓴다(UPGRADE.md §1.1). Phase 9-4는 `state-transition-guard.sh`의 YAML 파싱 3지점을 보강했다 — 카운터 행(`retry_count` 등)·`current_state` 행의 인라인 주석을 오파싱해 조용히 오차단·오우회하던 결함 해소(FB-01-3ⓑ). md5로 갱신 여부를 대조한다:

```bash
grep -c '파싱 계약' .claude/hooks/state-transition-guard.sh   # 1 이상이면 9-4 이후 버전
wc -l .claude/hooks/state-transition-guard.sh                  # 9-4 이후 199줄 (9-4 이전 193줄)
```

🔴 **카운터 행 인라인 주석 금지 수칙**(FB-01-3ⓐ, SSOT `3-workflow.md` §2.2): status.md frontmatter의 `retry_count`·`auto_fix_count`·`pre_build_iteration_counter`·`replan_counter`·`current_state` 행에는 `#` 인라인 주석을 달지 않는다.

**기존 status.md 주석 제거 안내**: 훅 갱신 이전에 인라인 주석을 회피 수칙으로 써 온 프로젝트라면(9-4 이전 `ver6-2` 이식본, TR-01 BookKeep API 실사례가 이런 식으로 회피했다), 훅 갱신 후에는 그 주석이 더 이상 필요하지 않다. 제거는 선택이다 — 남겨 둬도 새 파서는 정상 처리하지만, 다음 사람이 «옛 함정 회피 흔적»으로 오인하지 않도록 정리를 권장한다.

---

## 4. ★ 알려진 한계 — 과장하지 않는다

이 절이 이 가이드의 신뢰를 만든다. `ver6-2`가 스스로 지켜온 원칙("좀비를 전부 잡는 것처럼 기술하지 않는다")을 그대로 옮긴다.

### 4.1 KPI-01(오탐률 0%) 미충족 — 표본 부족이 아니라 구조적 한계

8-6 verifier가 프로세스 생존·활동을 완전히 고정한 채 inbox mtime만 변화시키는 통제 실험으로 확정했다:

> 시그널 #4는 `inboxes/{agent}.json`의 mtime, 즉 **"마지막 수신 시각"**을 측정하며 이는 **"에이전트가 작업 중인가"의 대리 신호가 아니다.** 동일 프로세스·동일 활동 상태에서 inbox mtime만 179초→181초로 바꾸면 판정이 `OK`→`SUSPECT`로 뒤집히는 것이 실측으로 확인됐다(계단 함수).

즉 표본을 3건이든 100건이든 늘려도 해결되지 않는다. **그 순간 메시지를 받지 않은 에이전트는 예외 없이 SUSPECT가 된다.** Hub-and-Spoke 구조에서 Team Lead가 Task를 위임하고 결과를 기다리는 정상 구간이 곧 임계(180초) 초과 구간이다.

### 4.2 ⚠ 반드시 지킬 운영 규칙

> **SUSPECT를 respawn 트리거로 승격시키지 마십시오. wake-up 권고로만 취급해야 합니다.**

이걸 모르고 SUSPECT를 자동 respawn 조건으로 쓰면, **도입한 쪽이 정상 작업 중인 에이전트를 계속 죽이게 된다.** `zombie_watch.sh`가 emit하는 `확인 필요: ... (wake-up 1회 권장, respawn 아님)` 문구가 이 원칙을 코드 레벨에서도 강제하지만, 이걸 소비하는 자동화를 직접 구현한다면 이 경계를 반드시 지켜야 한다.

### 4.3 나머지 한계

- **좀비 유형 (c) 살아있으나 유휴 정지 · (d) 턴 진행 중 교착 — 미커버.** (d)는 결함 E의 총 대기 상한 30분이 별도로 종결하지만, 이것은 감지가 아니라 **타임아웃에 의한 강제 종결**이다.
- **`--arm` 폴링 루프의 전달 경로 미비(D8-1, `ver7-0` 이관)** — 루프가 ZOMBIE를 감지해도 결과는 **로그 파일에만** 남고 종료 코드는 버려진다(`|| true`). **"감지 가능"까지만 사실이며 "자동 복구"라고 쓰지 않는다.** 로그를 자동으로 읽는 주체를 별도로 두지 않는 한, 사람이 로그 파일을 열기 전까지 아무 일도 일어나지 않는다. `--once <team> <agent>`(spawn+30초 경로)는 종료 코드를 그대로 전파하므로 이 문제가 없다. `ver6-2`에서는 해소하지 않으며 조치 계층 설계와 함께 `ver7-0`으로 이관됐다(phase-10-pre-analysis §5.1).
- **시그널 #2(shell prompt 감지) 회귀 검증 수단 부재(T-5, `ver7-0` 조건부 이관)** — 판정에 쓰이는 정규식이 자동 테스트에서 실제로 한 번도 실행되지 않는다(`_zc_pane_tail_real` 실행 0회, 8-6 verifier 계측). 알려진 오탐 패턴(`총액: $`처럼 `$`로 끝나는 일반 문장)이 있으나, 회귀 하네스 없이 정규식을 바꾸면 거짓음성을 검증 없이 배포하는 것과 같아 **의도적으로 현행을 유지**했다. 판정식 변경은 **회귀 하네스 확보 후에만** 착수한다(Phase 8 결정 #4, 순서 역전 금지) — `ver7-0`에서 회귀 하네스가 갖춰진 뒤의 후속 과제다.
- **`cmd_once` 단건 조회 경로의 회귀 케이스 미편입(V-2, `ver7-0` 이관)** — §7에서 지목한 「회귀 방어가 없는 항목 1건」이 아직 남아 있다. 회귀 하네스 확보(T-5와 같은 전제)와 함께 `ver7-0`에서 편입한다.
- **macOS bash 3.2 제약 회피 코드 포함** — 연관 배열(`declare -A`) 대신 `key=value` 인덱스 배열을 쓰는 등, bash 3.2 대상 회피 코드가 섞여 있다. bash 4+ 전용 구문으로 임의 교체하지 않는다(전방 호환은 확인됐으나 macOS 대상 배포라면 원본 유지를 권고).

---

## 5. 롤백

git 커밋 후 업그레이드를 권장한다. 문제가 있으면:

```bash
git checkout -- docs/SSOT .claude scripts
```

(UPGRADE.md §3.2와 동일 — `scripts/`가 추가된 것은 이번 이행이 `scripts/zombiecheck/`를 갱신하기 때문이다.)

---

## 6. 번들 포터빌리티 주의 — 인용된 근거 문서는 번들에 포함되지 않는다

`zombie_check.sh` 상단 주석과 `SUB-SSOT/TEAM-LEAD/2-lifecycle-procedure.md` §LIFECYCLE-5가 다음 두 문서를 근거로 인용한다:

```
docs/analysis/260522-zombie-detection-proposal.md
docs/handoff/260522-ver6-1-fork-checkpoint.md §5
```

이 두 문서는 **번들에 포함되지 않는다**(원 저장소 전용, 이식 시 미배포). 이식받은 프로젝트에서 링크를 열어도 존재하지 않으니, **원 저장소 참조용 표기**로 이해하면 된다. 핵심 결정값은 이미 SUB-SSOT 본문에 요약돼 있다:

- 좀비 감지 시그널 5종 + 조합 규칙 (1차 확정 → 시그널 표 참조)
- 폴링 계약: 최소 판정 유예 5분 / 확인 메시지 TTL 2분 / respawn 이전 최소 7분 / 총 대기 상한 30분
- respawn 상한 5회, suffix `_r1`~`_r5`

원문을 꼭 봐야 하는 경우가 아니라면 본문 요약만으로 충분하다.

---

## 7. 파일 규모 현황 — 줄수 현행화 (Phase 9-1 분리 반영)

8-6 시점에는 `zombie_watch.sh`·`zombie_watch_selftest.sh`가 500줄 한도에 근접해 증설 여유가 없었다. **Phase 9-1에서 헬퍼/폴링 로직을 `zombie_watch_lib.sh`·`zombie_watch_poll.sh`(source 전용, §3.1)로 분리**하면서 이 압박이 해소됐다(실측 2026-08-14, 고정 커밋 `932b2fc`):

```
zombie_watch.sh                        225/500줄   여유 275
zombie_watch_selftest.sh               401/500줄   여유  99
zombie_watch_lib.sh                    205/500줄   여유 295
zombie_watch_poll.sh                   134/500줄   여유 366
zombie_watch_selftest_regression.sh    135줄        (Phase 9-1 회귀 스위트 신설)
```

옛 §7이 경고했던 "코드를 고치기 전에 구조 결정(헬퍼 lib 분리)부터"는 이미 실행됐다 — 9-1 분리 이후에는 대부분의 확장이 기존 파일 안에서 가능하다. 분리 근거·절단선 상세는 9-1 Phase 산출물(`docs/phases/phase-9-1/`, 원 저장소 전용)을 참조한다.

여전히 남아 있는 것은 `zombie_watch_selftest.sh`의 **회귀 방어가 없는 항목 1건**이다 — `cmd_once` 단건 조회 경로의 D-1 필터 적용(V-2, `ver7-0` 이관 — §4 참조). 8-6에서 실측 검증은 완료했으나 예산 부족으로 자동 회귀 케이스는 추가하지 못한 채 남아 있다.

---

## 8. `ver6-2` 라인 종료 선언 + 계보

`ver6-2`는 Phase 9(9-1~9-4)로 마감되는 PoC 라인이다. Phase 9-4를 끝으로 이 라인에 대한 신규 기능 개발은 계획되지 않는다 — 다음 세대는 `ver7-0`이다(2026-08-12 사용자 재편성, `phase-10-pre-analysis` §5.1). **«종료»는 신규 기능 개발의 종료이며 기존 배포본의 폐기가 아니다** — `ver6-2`를 그대로 유지·이식해 쓰는 것은 계속 가능하다.

**계보**:

```
ver6-0 (구 v8.2 계열, scripts/zombiecheck/ 부재)
  → ver6-1 (Phase 8-1, LIFECYCLE-5 PoC 신설 — 좀비 감지 + Respawn)
  → ver6-2 (Phase 8-2~8-6, LIFECYCLE-6 체크 스케줄러 도입)
      → 9-1 (파일 분할, REFACTOR-1 Lv1)
      → 9-2 (생애주기 상태 기계 10상태 + 주체 경계)
      → 9-3 (판정 정확도 실측 3건 해소 + 시운전 TR-01 1회 완주)
      → 9-4 (TR-01 피드백 4건 반영 + 이식 문서 세트 — 본 문서 포함)
  → [라인 종료] — 다음은 ver7-0
```

**미해소 이관 항목** (`ver7-0` / Phase 10, §4 상세):

| 항목 | 내용 |
|------|------|
| D8-1 | `--arm` 폴링 루프 전달 경로 미비 — 감지는 되나 자동 복구로 이어지지 않음 |
| DEF-1③④ | `core/6-rules-index.md` L180·L466 LIFECYCLE-6 arm 문구(구 «BUILDING 진입 전 arm») — 본 Phase는 무변경 계약(규칙 104건 불변)으로 미수정. `ver7-0` 규칙 정본 동기화 시 §3.4 신 정의(TEAM_SETUP 직후 arm)로 함께 갱신 (G2 verifier DEF-1, 2026-08-14) |
| T-5 | 시그널 #2(shell prompt) 판정 정규식 — 회귀 하네스 확보 후에만 착수 |
| V-2 | `cmd_once` 단건 조회 경로 회귀 케이스 미편입 |
| V-5 | self-test 스텁 3종 미복원 |
| KPI K-5~7 | 측정 대상인 조치 계층이 `ver7-0`에 있어 `ver6-2`에서는 미측정 |

---

**문서 관리**: v1.1, 2026-08-09 신설(Phase 8-6 최종 작업) · 2026-08-14 갱신(Phase 9-4, FB-01-3ⓐ — 6-x 통합 확장). `docs/SSOT/VERSION.md`가 상세 변경 이력의 정본이며, 본 문서는 세대 이행 관점의 요약·절차·경고를 제공한다. SSOT 버전 갱신 시 본 문서의 §2~§4 정합성도 함께 확인한다.
