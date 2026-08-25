---
task: "2-5-1"
title: "헬스 모니터링 + Telegram 알림"
domain: "[INFRA]"
gap: "G-1 (🔴)"
assignee: backend-dev
status: completed    # T-1 헬스 모니터링 + volbackup 감시 연계 (2026-08-26) — G2_infra PASS
depends_on: []
integration_ref: docs/interop/pab-observer/260825-OB2-vault이원화-회신-및-승격사전통지.md
blocked_on: "UK_PAB_VAULT_PUSH_URL 발급 (Observer 측) — 미설정 시 Push 생략 동작으로 선배포 가능"
---

# Task 2-5-1: 헬스 모니터링 + Telegram 알림

## 목표
CouchDB·bridge 상태를 주기 점검하고 이상 시에만 Telegram으로 알린다. 2026-08-21 3일 장애 미인지의 직접 원인(G-1) 해소.

## 설계 변경 (2026-08-25, 사용자 지시)

**1차 알림 경로를 Observer/UK로 일원화한다.** 정상 시 무소음을 Telegram 침묵으로 구현하는 게 아니라, **Observer heartbeat의 존재 자체**를 정상 신호로 삼는다. heartbeat가 끊기면 UK가 알린다 — 수집기 자체가 죽는 경우까지 덮인다.

**정본**: [OB2 §7.1](../../interop/pab-observer/260825-OB2-vault이원화-회신-및-승격사전통지.md) — 수집기 규격·판정 4종·중복 조정 의견

- 파일: `pab-vault-sync-collect.sh` → `/home/oceanui/observer/scripts/`, cron 5분
- Push: `GET {UK_PAB_VAULT_PUSH_URL}?status={up|down}&msg={요약}&ping={정상항목수}`
- 판정 4종: `couch-net`(N-1 위양성) / `couch-up`(Tailnet IP 경유) / `mirror-fresh`(N-3) / `git-gap`(N-2)
- 기존 수집기 중복 감시 금지 — `pab-livesync-bridge`는 `container-health-collect.sh`가 이미 감시 중

## 작업
- 헬스체크 스크립트 작성 — 점검 항목:
  - CouchDB `/_up` (HTTP 200)
  - `pab-couchdb` 컨테이너 running + **네트워크 엔드포인트 존재** (§1.3 위양성 방지: `Networks: {}` 상태 검출)
  - `pab-livesync-bridge` 컨테이너 상태
  - 마지막 git 커밋 경과 시간 > 24h (DP-2-5-2 잔여 위험 커버)
- 알림 정책 — **연속 N회 실패 시에만** 발송 + **복구 시 1회** 발송 (PR-2 플래핑 방지)
- `scripts/pmAuto/report_to_telegram.sh` 재사용. `_` 단독 토큰 하이픈 치환·escape (PR-4)
- **3800X crontab 등록** (DP-2-5-1)
- **맥북발 주 1회 역방향 확인** 보조 장치 — 서버 자체 다운 시 침묵 감지

## 산출물
- 헬스체크 스크립트 + crontab 엔트리 (서버)
- 맥북 역방향 확인 스크립트 + cron 엔트리

## 검증 (G2_infra / G3_smoke)
- G2_infra: cron 등록 확인, 정상 상태에서 **알림 미발송**(무소음) 확인
- G3_smoke(tester): 컨테이너 강제 정지 → 알림 수신 → 복구 → 복구 알림 수신 E2E

## 비고
- 정상일 때 조용해야 한다 — 매 실행 발송은 알림 피로를 유발해 실제 장애를 묻는다
- HR-5 적용 대상 (신규 bash 스크립트, E-2 예외 아님)

---

## 검증 결과 — 볼륨 백업 감시 연계분 (2026-08-26, backend-dev)

> ⚠️ **범위 한정**: 본 절은 T-3 연계로 **추가된 `couchdb-volbackup` 점검 1건**의 검증 기록이다.
> 최초 T-1 산출물(헬스체크·watchdog·git-stamp·deploy) 자체의 검증은 별건이며 여기서 갱신하지 않는다.

**커밋** `eb1875b` — `scripts/monitoring/pab_sync_healthcheck.sh`

### 변경 범위 — 기존 판정 로직 무접촉

| 항목 | 결과 |
|---|---|
| 삭제된 기존 줄 | **0줄** — `CHECK_KEYS` 1줄 확장 외 **순수 추가** |
| 기존 5개 점검 | 코드 무변경 → 재검증 범위가 신규 1항목으로 한정된다 |
| PR-2(연속 3회)·PR-4(`md_safe`) | **기존 루프에서 상속** — 별도 구현하지 않았다. 알림 규율이 두 벌이 되는 것을 피한다 |
| HR-5 | 463 → **499줄** (임계 500 **아래**, 여유 1줄) |
| shellcheck | SC2034 2건 — **변경 이전부터 존재**(백업본 대조). 신규 경고 0 |

### 판정 규칙

| 조건 | 동작 | 근거 |
|---|---|---|
| `LAST_OK_TS` 경과 > **36h** | FAIL | 일 1회 주기의 1회 결번 + 12h 여유 |
| `LAST_VERIFY_TS` 경과 > **10일** | FAIL | 주 1회 + 3일 여유 — 한 주를 통째로 건너뛰어야 운다 |
| `GENERATIONS < 7` | **정보 표시만** | 초기 7일은 정상적으로 미달 → 알림 아님 |
| `TOTAL_SIZE` | 정보 표시 | 용량 추이 |

### ⭐ `auto` 게이트 — 위양성 방지

cron 등록 **전에** 감시를 켜면 36h 뒤 위양성이 뜬다. 그렇다고 별도 플래그로 켜게 하면
*"등록했는데 감시는 안 켠"* 어긋남이 생긴다 — **감시 대상과 감시 스위치가 따로 놀면 아무도 모르게 눈이 먼다.**

⇒ crontab의 `PAB-COUCHDB-VOLBACKUP` **마커를 직접 읽어** 등록된 뒤에만 감시한다.
등록과 감시가 한 몸이라 **수동 동기화 지점이 없다.** OB2-C 후 cron 등록만으로 감시가 함께 살아난다 — **추가 조치 불요.**

### 6분기 전수 시험 (합성 상태파일로 각 판정을 실제 발생)

```
[정상(신선·7세대)  ] OK   — 경과 1h, 세대 7/7, 총 10485760B, 리허설 1일 전
[백업정체 38h      ] FAIL (1/3) — 볼륨 백업 정체 38시간 (임계 36h, 세대 7)
[리허설 11일 경과  ] FAIL (1/3) — 복원 리허설 11일 경과 (임계 10일) — 복구 보증 만료
[세대 3/7 축적중   ] OK   — … [세대 축적 중]         ← 알림 아님
[상태파일 없음     ] FAIL (1/3) — 백업이 한 번도 돌지 않았다
[cron 마커 없음    ] OK   — cron 미등록 — 감시 대기(위양성 방지)
```
`(1/3)` 표기가 **PR-2 연속실패 규칙에 정상으로 얹혔음**을 보인다 — 상속했다는 주장이 아니라 상속된 결과다.

### 배포 절차

가동 중 감시자를 시험 대상으로 삼지 않기 위해 `/tmp/health-test.sh`에 **먼저 배포해 시험**하고,
통과 후에만 실경로에 올렸다. (감시자가 시험 중에 눈멀면 그 구간이 사각지대가 된다)
서버 원본 백업: `/tmp/health-live-backup-20260826-050040.sh`

배포 후 6개 점검 전부 OK, exit 0, **heartbeat 정상 갱신**(`STATUS=OK FAILING=`) — 맥북 watchdog 의존 경로라 별도 확인.

### HR-5 후속 (합의)

**499줄 = 임계 1줄 전.** 다음에 이 파일을 확장할 때 **분할을 함께** 한다.
방향: `check_*` 함수만 별도 파일로 분리하고 **디스패처·상태관리·알림 규율은 본체 유지** → PR-2/PR-4 상속 구조 보존.
알림까지 함께 빼는 분할은 금지.
