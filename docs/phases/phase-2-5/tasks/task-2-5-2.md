---
task: "2-5-2"
title: "GitHub 오프사이트 백업 정상화 + 자동 커밋·푸시"
domain: "[INFRA]"
gap: "G-2 (🔴)"
assignee: backend-dev
status: running    # 커밋·푸시 실체 충족(2efb00e). ⚠️ cron 활성화만 BL-3(사용자)로 잔여
depends_on: []
---

# Task 2-5-2: GitHub 오프사이트 백업 정상화

## 목표
34일 정체된 오프사이트 백업 공백을 해소하고 자동 커밋·푸시를 확립한다. master-plan §3 KPI "GitHub 백업 자동 커밋·푸시 도달" 달성.

## 배경
마지막 커밋 `ce4533f`(2026-07-21) 이후 공백. **LiveSync는 복제이지 백업이 아니다** — 삭제·손상이 전 기기로 전파되며 되돌릴 스냅샷이 없다.

## 작업
- 미커밋 잔여 해소 — 노트 8종(10_Notes 4 + 15_Sources 4), `_INDEX.md` 수정, `무제.canvas` 삭제
- 자동 커밋·푸시 스크립트 작성
  - **커밋·푸시만 수행. 병합(merge/pull --rebase 등) 금지** (PR-3)
  - 충돌·비정상 상태 감지 시 커밋 중단 + 알림
  - 커밋 메시지에 자동 생성 표식 + 변경 파일 수
- **맥북 로컬 cron 등록** (DP-2-5-2) — DP-1 데스크톱 git-authority 정책 무변경

## 산출물
- 자동 커밋·푸시 스크립트 + 맥북 cron 엔트리

## 검증 (G2_infra)
- 미커밋 0 상태 도달, GitHub 원격 반영 확인
- 커밋 공백 ≤ 24h (KPI)
- 자동 커밋이 병합을 수행하지 않음을 스크립트 리뷰로 확인

## 비고
- T-1의 "마지막 커밋 경과 > 24h" 감시가 이 Task의 안전망

---

## 검증 결과 (2026-08-26, backend-dev / Team Lead 독립 검증 HR-6)

**G2_infra 조건부 PASS** — cron 활성화만 잔여(BL-3, owner 사용자).

**산출물**: `scripts/monitoring/pab_git_autocommit_local.sh` (**350줄**, HR-5 통과) + `deploy_monitoring.sh` 연계(145→166줄)

### PR-3 준수 — 병합 미수행 증명

```
grep -nE 'git[[:space:]]+(-C[^|]*)?(merge|pull|rebase|cherry-pick)' \
  scripts/monitoring/pab_git_autocommit_local.sh   →  0건
```
호출 서브커맨드 전수: `add`·`commit`·`push` + 읽기전용 8종(`rev-parse`/`status`/`diff`/`rev-list`/`ls-remote`/`cat-file`/`symbolic-ref`).
`reset`/`checkout`/`clean` **0건**, `push --force` 경로 **없음**.

### 안전장치 8종 — 전용 테스트 저장소에서 각 이상 상태를 실제로 발생시켜 검증

| 게이트 | 검출 대상 | 시험 |
|---|---|---|
| G1 lock | `.git/index.lock` → 조용히 양보(이상 아님) + `mkdir` 락으로 중복 실행 차단 | ✅ |
| G2 in-progress | `MERGE_HEAD`/`rebase-merge`/`rebase-apply`/`CHERRY_PICK_HEAD`/`REVERT_HEAD`/`BISECT_LOG`/`sequencer` | ✅ |
| G3 branch | detached HEAD / 브랜치 ≠ main | ✅ 둘 다 |
| G4 unmerged | `diff --diff-filter=U` | ✅ |
| G5 conflict-mark | `diff --cached --check` 에서 **`conflict marker`만 추출** — 옵시디언의 의도적 trailing space 오탐 배제 | ✅ 검출·오탐없음 둘 다 |
| G6 behind | `ls-remote`로만 조회(**fetch·pull 없음**, 로컬 ref 무변조). **커밋 전에** 차단해 분기 자체를 안 만든다 | ✅ 2경우 |
| G7 secret | 파일명(`.md` 제외 — 제목에 `password`가 든 정상 노트 오탐 방지) + 봇 토큰 형태 | ✅ 둘 다 |
| G8 mass-delete | 삭제 > `PAB_MAX_DELETE`(50) — 복제로 전파된 사고 삭제를 백업에 굳히지 않는다 | ✅ |

9종 중단 사유가 **각각 정확히 1회씩만** 알림 발송(엣지 트리거, 중복 억제 확인).
PR-4: 전 알림 본문 `_` 잔존 **0건**(`MERGE_HEAD`→`MERGE-HEAD`).

### dry-run 안전성

`--dry-run`(=`--check`)은 **임시 인덱스 사본**에 스테이징해 판정한다 →
실행 전후 `.git/index` SHA 동일(`6095fbf5…`), HEAD 동일, 작업트리 불변, 상태파일 미생성.

### 실증 커밋

| 커밋 | 내용 |
|---|---|
| `2efb00e` | 27파일(수정 19/추가 8). **자동화가 자기 자신을 커밋** — 그 자체가 G2_infra 증거 |
| — | `git ls-remote` 실측 원격 tip = 로컬 HEAD → **오프사이트 반영 확인**, 미커밋 0 / 미푸시 0 |

`docs/history/`는 추적 여부 미결이라 `.gitignore`로 제외(사용자 결정 대기).

### cron (미등록 — BL-3)

```
17 */2 * * * .../pab_git_autocommit_local.sh >> /tmp/pab-git-autocommit.log 2>&1  # PAB-GIT-AUTOCOMMIT
```
- **2시간 주기 근거**: KPI(공백 ≤24h) 대비 하루 12회 = 12배 여유. macOS cron은 슬립 중 놓친 실행을 보충하지 않으므로 여유분이 곧 "깨어 있는 창을 만날 확률"이 된다 — 2시간이면 **하루 22시간을 자도 KPI를 지킨다**. 변경 없으면 no-op이라 비용 ~0
- **`:17` 오프셋**: `PAB-GIT-STAMP`(매시 :00)와 같은 저장소를 동시에 건드리지 않게 함 → `.git/index.lock` 경합 회피 + stamp가 **커밋 이후** 상태를 보고
- 등록 로직은 `deploy_monitoring.sh --local-only`에 통합(멱등, 기존 2종 보존 확인)

> ### 🔴 BL-3 — 맥북 crontab **쓰기 차단** (owner: 사용자)
> `crontab -l`(읽기)은 정상인데 **`crontab <파일>`(쓰기)이 무한 대기**한다. 프로세스 `SN` sleep, 열린 fd 0, 디스크 여유 550G, 잔류 프로세스·락 없음. 샌드박스 우회로도 동일. **04:25에는 같은 명령이 정상 동작**했으므로 스크립트 결함이 아니라 **맥OS 환경 권한 문제**다(Team Lead 독립 재현 완료). 4회 시도 후 중단, crontab 무결성은 보존(기존 2종 그대로, 백업본과 `diff` 일치).
> **해소**: 사용자 터미널에서 `bash scripts/monitoring/deploy_monitoring.sh --local-only` 1회.
> 복구용 백업: `/tmp/crontab-backup-20260826-042459.txt`

### G9 — `skip-worktree`/`assume-unchanged` 감지 (2026-08-26 승인·구현, 커밋 `beac193`)

`git add -A`는 이 비트가 걸린 파일을 **건너뛴다.** vault 노트에 걸리면 **자동 백업이 그 파일만 조용히 누락**하는데,
백업은 *"매일 성공"* 이라 하고 T-1도 *"정상"* 이라 한다 — **2026-08-21과 같은 구조**다(지표는 전부 정상인데 실체가 죽어 있다).

**가설이 아니다**: T-5에서 `PAB-LLMDATA/.obsidian/workspace.json`에 이 비트가 **실제로 걸려 있었다.**

| 설계 | 내용 |
|---|---|
| 판정 | `git ls-files -v \| grep -E '^[Sh]'` 가 비어 있지 않으면 감지 |
| 동작 | **경고 로그 + 커밋 메시지 표기 + 해제 명령 안내.** ⚠️ **중단하지 않는다** |
| 왜 중단 안 하나 | G7·G8과 달리 **정당한 용도가 있을 수 있고**(로컬 전용 설정 등) 백업 자체를 막을 사안이 아니다. 목적은 차단이 아니라 **보이게 만드는 것** — 보이지 않으면 확인할 동기조차 생기지 않는다. 주석에 명시해 다음 사람이 *"왜 이건 안 막지?"* 라고 묻지 않게 했다 |
| 목록 상한 | `PAB_SKIP_LIST_CAP`(기본 **5**)건까지 나열 + `… 외 M건` — 수십 건이면 커밋 메시지가 터진다 |
| PR-4 | **Telegram 경로에는 싣지 않는다**(로그 + 커밋 메시지 전용). 나중에 알림에 실을 때는 경로에 `_`가 흔하므로 `md_safe()` 경유 필수임을 주석에 남겼다 |

### 🔴 필수 요건 — **no-op 경로에서도 발화해야 한다** (초판 결함, 커밋 `e7da951`로 수정)

> ⚠️ **이 절을 읽지 않고 `detect_skip()` 호출을 커밋 직전으로 되돌리면, 가드가 조용히 무력화된다.**

초판(`beac193`)은 G9를 **커밋 직전**에 두었다. 자연스러운 위치로 보였고 시험 4종도 통과했다.
그런데 **가드가 자기 시나리오에서만 침묵**하고 있었다:

```
vault 노트에 비트가 걸린다
  → 사용자가 그 노트를 편집한다
  → git add -A 가 건너뛴다
  → 다른 변경이 없으면 CHANGED_N = 0
  → "변경 없음 — 무소음 종료" → exit 0
  → G9 미실행 ❌
```

**누락이 일어난 바로 그 순간에 침묵한다.** 다른 파일이 우연히 함께 바뀌었을 때만 경고가 떴다 —
즉 **경고가 덜 필요한 경우에만 뜨고, 가장 필요한 경우에 안 떴다.**

초판 시험 4종이 이 분기를 **우연히 비켜갔다**: 네 케이스가 전부 *"커밋할 변경이 있는"* 경로였다.
시험 중 *"`note1.md` 수정분이 누락되고 `추가 1`만 기록"* 되는 것을 관측하고도 그 의미를 놓쳤다 —
**거기서 `추가 1`이 없었다면 경고도 없었다.**

> **시험이 통과했다는 사실이 그 시험이 옳은 것을 봤다는 사실은 아니다.**
> `tar exit 0` · `HTTP 400` · 조용한 `git status` · `git check-ignore` 0건과 같은 계열이며,
> 이번엔 **초록 불이 켜진 시험** 자체가 그 계기였다.
> (Team Lead가 실제로 비트를 걸어보고 발견 — 코드 리뷰로는 잡히지 않았다)

**수정**: `detect_skip()` 으로 분리해 **락 획득 직후** 호출한다(`g add -A` 이전).
비트 감지는 **스테이징 결과와 무관**하므로(`git ls-files -v` 만 보면 된다) 앞으로 옮겨도 정확도가 같고,
**no-op · abort · 커밋 모든 경로에서 발화**한다. `--status` 에도 노출해 검증자가 볼 수 있게 했다.

| 요건 | 이유 |
|---|---|
| **no-op 경로에서 발화** | 그때가 **핵심**이다 — 커밋할 게 없어 보이는 이유가 바로 그 비트일 수 있다 |
| `--dry-run` 에서 발화 | 검증자가 실제 커밋 없이 확인할 수 있어야 한다 |
| **Telegram 알림 금지** (`log`만) | *"변경 없음"* 은 정상 상태이고 비트 감지는 **경고이지 이상이 아니다** — 무소음 원칙과 충돌시키지 않는다 |
| `SKIP_NOTE` 는 커밋이 생길 때만 메시지에 부착 | 커밋이 없으면 붙일 곳도 없다 |

### 시험

**초판 4종** (전용 저장소 — 전부 *"커밋할 변경이 있는"* 경로였다):

| 케이스 | 결과 |
|---|---|
| 비트 0건 | 경고 없음, 커밋 메시지 `주의:` **0건** ✅ |
| 비트 1건 | `WARN … 건너뛴다: note2.md` + 커밋 메시지 표기·해제법 ✅ |
| 비트 6건 | 5건 나열 + `… 외 1건` (상한 동작) ✅ |
| 중단 안 함 | 3케이스 모두 커밋 성공, 작업트리 clean ✅ |

**수정 후 추가 — 결함 경로 재현** (⭐ 이것이 회귀 시험의 본체다):

```
# 비트 걸린 노트 1개만 편집 → add -A 가 건너뜀 → CHANGED_N=0
git status: []          ← 비트 때문에 비어 보인다 (사용자는 편집했는데)

WARN skip-worktree/assume-unchanged 1건 — 자동 백업이 건너뛴다: note1.md
변경 없음 — 무소음 종료(no-op)
```

**실 저장소 재시험** (⚠️ **반드시 작업트리 clean 상태에서**):
```
git status --short | wc -l                 → 0
git update-index --skip-worktree Makefile  → S Makefile
pab_git_autocommit_local.sh --dry-run      → WARN … 건너뛴다: Makefile   ✅ 발화
                                              변경 없음 — 무소음 종료(no-op)
git update-index --no-skip-worktree Makefile → H Makefile
git ls-files -v | grep -cE '^[Sh]'         → 0   (잔재 없음)
```
> ⚠️ 작업트리가 dirty하면 `CHANGED_N > 0` 이라 **초판 코드도 통과한다.** 회귀 시험은 **clean 상태**라야 의미가 있다.

HR-5 350 → 376 → **390줄**. PR-3 병합 명령 **0건** 유지 재확인.
