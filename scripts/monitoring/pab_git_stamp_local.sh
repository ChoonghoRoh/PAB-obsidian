#!/usr/bin/env bash
#
# pab_git_stamp_local.sh — 맥북 git 상태를 3800X 로 남기는 stamp 기록기
# Phase 2-5 / Task 2-5-1 (git-gap 보조) — backend-dev
# ─────────────────────────────────────────────────────────────────────────────
# 목적:
#   서버 수집기(pab-vault-sync-collect.sh)의 `git-gap` 판정이 **왜** 실패했는지
#   구분할 수 있도록, 맥북 로컬 저장소의 상태를 주기적으로 서버에 남긴다.
#
# 왜 필요한가:
#   git-gap 의 1차 측정은 GitHub origin/main tip 경과다(맥북이 꺼져 있어도 서버가
#   독립적으로 잰다). 그런데 그것만으로는 아래 세 가지가 구분되지 않는다:
#     (a) 맥북이 꺼져 있어 커밋·푸시 자체가 멈춤       → stamp 가 오래됨
#     (b) 맥북은 살아 있는데 푸시가 안 되고 있음        → stamp 신선 + UNPUSHED>0
#     (c) 맥북도 살아 있고 푸시할 것도 없음(진짜 공백)  → stamp 신선 + UNPUSHED=0
#   이 stamp 가 그 구분을 제공한다. **판정 자체는 stamp 에 의존하지 않는다** —
#   맥북이 죽으면 stamp 도 멈추므로, stamp 만으로 판정하면 "백업 공백"과
#   "stamp 공백"을 영영 구분할 수 없다(감시자가 감시대상에 의존하는 안티패턴).
#
# 동작:
#   로컬 마지막 커밋 시각 / HEAD SHA / 미푸시 커밋 수를 서버 상태파일에 기록.
#   알림은 절대 보내지 않는다(순수 데이터 피드). 서버 도달 실패 시 조용히 종료 —
#   stamp 가 낡는 것 자체가 신호이므로 여기서 시끄럽게 굴 이유가 없다.
#
# cron (맥북, 매시 정각):
#   0 * * * * /Users/map-rch/WORKS/PAB-obsidian/scripts/monitoring/pab_git_stamp_local.sh >> /tmp/pab-git-stamp.log 2>&1  # PAB-GIT-STAMP
#
# 의존: git, ssh
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail
PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${PAB_REPO_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
SSH_HOST="${PAB_SSH_HOST:-3800x}"
REMOTE_STAMP="${PAB_REMOTE_STAMP:-/home/oceanui/pab-vault-monitor/state/git-stamp.env}"
BRANCH="${PAB_GIT_BRANCH:-main}"

log() { printf '%s [git-stamp] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*"; }

[ -d "$REPO_DIR/.git" ] || { log "ERROR git 저장소 아님: $REPO_DIR"; exit 1; }

TS_NOW="$(date +%s)"
LOCAL_COMMIT_TS="$(git -C "$REPO_DIR" log -1 --format=%ct 2>/dev/null || echo '')"
LOCAL_SHA="$(git -C "$REPO_DIR" rev-parse --short=12 HEAD 2>/dev/null || echo '')"

# 미푸시 커밋 수 — 원격을 조회하지 않고 로컬의 remote-tracking ref 로만 센다.
# (네트워크 없이도 동작해야 하고, 원격 조회는 서버 수집기가 이미 한다)
UNPUSHED="$(git -C "$REPO_DIR" rev-list --count "origin/${BRANCH}..HEAD" 2>/dev/null || echo 0)"
[ -n "$UNPUSHED" ] || UNPUSHED=0

# 미커밋 변경 파일 수 (추세 정보 — 판정에는 쓰지 않는다)
DIRTY="$(git -C "$REPO_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
[ -n "$DIRTY" ] || DIRTY=0

if [ -z "$LOCAL_COMMIT_TS" ]; then log "ERROR 로컬 커밋 시각 조회 실패"; exit 1; fi

PAYLOAD="STAMP_TS=${TS_NOW}
LOCAL_COMMIT_TS=${LOCAL_COMMIT_TS}
LOCAL_SHA=${LOCAL_SHA}
UNPUSHED=${UNPUSHED}
DIRTY=${DIRTY}"

# 원자적 기록. 서버 미도달은 오류가 아니다 — stamp 가 낡는 것이 곧 신호다.
if printf '%s\n' "$PAYLOAD" | ssh -o BatchMode=yes -o ConnectTimeout=15 \
     -o StrictHostKeyChecking=accept-new "$SSH_HOST" \
     "mkdir -p \"\$(dirname '${REMOTE_STAMP}')\" && cat > '${REMOTE_STAMP}.tmp' && mv '${REMOTE_STAMP}.tmp' '${REMOTE_STAMP}'" 2>/dev/null
then
  log "stamp 기록 완료 (sha=${LOCAL_SHA} unpushed=${UNPUSHED} dirty=${DIRTY})"
else
  log "WARN 서버 도달 실패 — stamp 미갱신 (다음 주기 재시도)"
fi
exit 0
