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

### 미결 제안 1건

`git add -A`는 **`skip-worktree`/`assume-unchanged` 비트가 걸린 파일을 건너뛴다.**
vault 노트에 그 비트가 걸리면 **자동 백업이 그 파일만 조용히 누락**하는데 백업도 T-1도 정상이라 보고한다.
T-5에서 그 비트가 **실제로 존재했음이 확인**됐으므로 가설이 아니다.
→ 감지 시 **경고 로그 + 커밋 메시지 표기**(중단 없음) 추가를 제안. 판단 대기.
