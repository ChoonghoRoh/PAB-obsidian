#!/usr/bin/env bash
#
# pab_git_autocommit_local.sh — 맥북 로컬 vault 자동 커밋·푸시 (오프사이트 백업)
# Phase 2-5 / Task 2-5-2 (G-2) — backend-dev
# ─────────────────────────────────────────────────────────────────────────────
# 왜 필요한가:
#   LiveSync 는 **복제**이지 백업이 아니다. 삭제·손상이 전 기기로 즉시 전파되고
#   되돌릴 스냅샷이 남지 않는다. GitHub 커밋만이 되돌릴 수 있는 시점을 만든다.
#   그런데 그 커밋이 수동이면 사람의 주의력이 곧 백업 주기가 된다 — 실제로
#   2026-07-21 이후 34일 공백이 발생했다. 이 스크립트가 그 주기를 기계에 넘긴다.
#
# 무엇을 하지 않는가 (PR-3 — 가장 중요):
#   **병합을 하지 않는다.** merge / pull / rebase / cherry-pick 을 호출하지 않는다.
#   자동화가 병합을 시도하는 순간, 충돌 해소를 무인 판단에 맡기게 되고 그 결과가
#   그대로 전 기기로 전파된다. 이 스크립트는 오직 `add` → `commit` → `push` 만
#   수행하며, 병합이 필요한 상황(원격이 앞섬·충돌 잔존)은 **중단하고 사람을 부른다**.
#   증명:  grep -nE 'git[[:space:]]+(-C[^|]*)?(merge|pull|rebase|cherry-pick|reset)' \
#            scripts/monitoring/pab_git_autocommit_local.sh   →  0건
#
# 안전장치 (하나라도 걸리면 커밋하지 않고 중단 + 알림):
#   G1 lock         : .git/index.lock 존재 = 다른 git 작업 진행 중 → 조용히 양보
#   G2 in-progress  : MERGE_HEAD / rebase-merge / rebase-apply / CHERRY_PICK_HEAD /
#                     REVERT_HEAD / BISECT_LOG / sequencer 잔존 → 중단
#   G3 branch       : detached HEAD 이거나 현재 브랜치가 main 이 아니면 중단
#   G4 unmerged     : 인덱스에 미해결 경로(UU/AA/DU 등)가 있으면 중단
#   G5 conflict-mark: 스테이징 내용에 남은 충돌 마커(<<<<<<<)가 있으면 중단
#   G6 behind       : 원격이 로컬보다 앞서면 중단 (**강제 푸시 절대 없음**)
#   G7 secret       : PUBLIC 저장소 — 비밀 파일명·봇 토큰 형태가 섞이면 중단
#   G8 mass-delete  : 삭제 파일이 임계 초과면 중단 (복제로 전파된 대량 삭제 방어)
#   G9 skip-worktree: **경고만** — `git add -A` 가 건너뛰는 파일을 드러낸다(중단 없음)
#
# 무소음 원칙:
#   변경이 없으면 아무것도 하지 않고 종료한다(알림 없음). 알림은 **이상·실패에만**,
#   그것도 상태 전이 시 1회씩만 보낸다(같은 이상 반복 발송 금지). 장기 방치는
#   T-1 서버 감시(GitHub tip 경과 > 24h)가 독립적으로 잡는다 — 이 스크립트가
#   죽어도 공백은 드러난다(감시자가 감시대상에 의존하지 않는다).
#
# 오프라인 정책:
#   원격 조회 실패(비행기·네트워크 단절)는 이상이 아니다. **로컬 커밋은 수행**하고
#   (커밋 자체가 되돌릴 수 있는 스냅샷이다) 푸시만 미룬다. 푸시 실패가
#   PUSH-FAIL-STREAK 회 연속되면 그때 1회 알린다.
#
# cron (맥북, 2시간마다 17분):
#   17 */2 * * * /Users/map-rch/WORKS/PAB-obsidian/scripts/monitoring/pab_git_autocommit_local.sh >> /tmp/pab-git-autocommit.log 2>&1  # PAB-GIT-AUTOCOMMIT
#
# 사용: pab_git_autocommit_local.sh [--dry-run|--check|--status|--help]
#   --dry-run(=--check) : 실제 커밋·푸시·상태기록 없이 판정만 (검증자용 안전 모드)
#   --status            : 현재 상태파일·저장소 요약 출력
#
# 의존: git, ssh(GitHub 접속). 알림: scripts/pmAuto/report_to_telegram.sh
# 상태: $HOME/.pab-sync-monitor/ (저장소 밖 — per-machine 파일 추적 금지)
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail
PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${PAB_REPO_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
REPORT_SH="$REPO_DIR/scripts/pmAuto/report_to_telegram.sh"

BRANCH="${PAB_GIT_BRANCH:-main}"
REMOTE="${PAB_GIT_REMOTE:-origin}"
PROJECT_TAG="${PAB_PROJECT_TAG:-PAB-v3}"
STATE_DIR="${PAB_WATCHDOG_STATE:-$HOME/.pab-sync-monitor}"
STATE_FILE="$STATE_DIR/git-autocommit-state.env"
LOCK_DIR="$STATE_DIR/autocommit.lock"
LOCK_STALE="${PAB_LOCK_STALE:-1800}"              # 30분 넘은 락은 잔재로 간주
MAX_DELETE="${PAB_MAX_DELETE:-50}"                # 대량 삭제 중단 임계
PUSH_FAIL_LIMIT="${PAB_PUSH_FAIL_STREAK:-3}"      # 연속 푸시 실패 N회부터 알림
SKIP_CAP="${PAB_SKIP_LIST_CAP:-5}"                # G9 경고에 나열할 파일 수 상한
export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes -o ConnectTimeout=15}"
export GIT_TERMINAL_PROMPT=0

DRY_RUN=0; SHOW_STATUS=0
case "${1:-}" in
  --dry-run|--check) DRY_RUN=1 ;;
  --status)          SHOW_STATUS=1 ;;
  --help|-h) sed -n '3,60p' "${BASH_SOURCE[0]}"; exit 0 ;;
  "") ;;
  *) echo "usage: $0 [--dry-run|--check|--status|--help]" >&2; exit 64 ;;
esac

ts_now="$(date +%s)"
iso_now="$(date '+%Y-%m-%d %H:%M:%S %Z')"
log() { printf '%s [git-autocommit] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*"; }
g() { git -C "$REPO_DIR" "$@"; }

# ── PR-4: Telegram parse-mode=Markdown 회피 (`_` 단독 토큰이 entity 를 깨뜨린다) ──
md_safe() {
  local s="${1-}" bt sq
  bt='`'; sq="'"
  s="${s//_/-}"; s="${s//\*/•}"; s="${s//$bt/$sq}"
  s="${s//\[/(}"; s="${s//\]/)}"
  printf '%s' "$s"
}
notify() {
  local body; body="$(md_safe "${1-}")"
  if [ "$DRY_RUN" -eq 1 ]; then log "DRY-RUN 발송 억제. 본문:"; printf '%s\n' "$body"; return 0; fi
  [ -x "$REPORT_SH" ] || { log "ERROR report-to-telegram.sh 없음: $REPORT_SH"; return 1; }
  "$REPORT_SH" "$PROJECT_TAG" "$body" >/dev/null 2>&1 \
    && { log "notify sent"; return 0; } || { log "ERROR 발송 실패"; return 1; }
}

# ── 상태파일 (기존 스크립트 관례: 쓰기는 printf %q, 읽기는 작은따옴표 제거) ──
st_get() {
  local v
  [ -f "$STATE_FILE" ] || { printf '%s' "${2-}"; return 0; }
  v="$(grep -m1 "^${1}=" "$STATE_FILE" 2>/dev/null | cut -d= -f2-)"
  [ -n "$v" ] || { printf '%s' "${2-}"; return 0; }
  v="${v%\'}"; v="${v#\'}"; printf '%s' "$v"
}
NEW_STATE=""
st_set() { NEW_STATE="${NEW_STATE}${1}=$(printf '%q' "${2-}")"$'\n'; }
st_flush() {
  [ "$DRY_RUN" -eq 1 ] && return 0
  printf '%s' "$NEW_STATE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
  chmod 600 "$STATE_FILE" 2>/dev/null || true
}

# ── G9 (경고 전용 — 중단하지 않는다): skip-worktree / assume-unchanged ───────
# `git add -A` 는 이 비트가 걸린 파일을 **건너뛴다**. vault 노트에 걸리면 자동
# 백업이 그 파일만 조용히 누락하는데, 백업은 "매일 성공"이라 하고 T-1 도 "정상"이라
# 한다 — 2026-08-21 과 같은 구조다(지표는 전부 정상인데 실체가 죽어 있다).
# 실제로 2026-08-26 `PAB-LLMDATA/.obsidian/workspace.json` 에서 이 비트가 발견됐다.
#
# ⚠️ **반드시 스테이징·no-op 판정보다 먼저 호출한다.** 초판은 이 검사를 커밋 직전에
#    두었는데, 그러면 **가드가 자기 시나리오에서만 침묵**했다: 비트가 걸린 노트를
#    편집 → `add -A` 가 건너뜀 → CHANGED_N=0 → "변경 없음" no-op exit → G9 미도달.
#    누락이 일어난 바로 그 순간에 경고가 안 나오고, 다른 파일이 우연히 함께 바뀐
#    때에만 떴다 — 가장 필요할 때 침묵하는 가드였다. (2026-08-26 Team Lead 실측 지적)
#    비트 감지는 스테이징 결과와 무관하다 — `git ls-files -v` 만 보면 된다.
#
# ⚠️ G7·G8 과 달리 **중단시키지 않는다.** 정당한 용도가 있을 수 있고(로컬 전용 설정
#    파일 등), 백업 자체를 막을 사안이 아니다. 목적은 차단이 아니라 **보이게 만드는
#    것**이다 — 보이지 않으면 확인할 동기조차 생기지 않는다.
# ※ 알림은 보내지 않는다(로그 + 커밋 메시지 전용). "변경 없음"은 정상 상태이고 비트
#   감지는 경고이지 이상이 아니다 — 무소음 원칙과 충돌시키지 않는다. 나중에 알림
#   경로에 싣게 되면 그때는 md-safe() 를 반드시 경유할 것(경로에 `_` 가 흔하다, PR-4).
SKIP_NOTE=""
detect_skip() {
  local list n shown
  list="$(g ls-files -v 2>/dev/null | grep -E '^[Sh]' | awk '{ $1=""; sub(/^ /,""); print }')"
  n="$(printf '%s' "$list" | grep -c . || true)"
  [ "${n:-0}" -gt 0 ] || return 0
  shown="$(printf '%s' "$list" | head -"$SKIP_CAP" | tr '\n' ' ')"
  [ "$n" -gt "$SKIP_CAP" ] && shown="${shown}… 외 $(( n - SKIP_CAP ))건"
  log "WARN skip-worktree/assume-unchanged ${n}건 — 자동 백업이 건너뛴다: ${shown}"
  SKIP_NOTE="
주의: skip-worktree/assume-unchanged ${n}건 감지 — 아래는 자동 백업에서 누락된다.
      ${shown}
      해제: git update-index --no-skip-worktree <경로>"
}

mkdir -p "$STATE_DIR"; chmod 700 "$STATE_DIR" 2>/dev/null || true
PREV_KIND="$(st_get ALERT_KIND '')"
PREV_STREAK="$(st_get PUSH_FAIL_STREAK 0)"; [ -n "$PREV_STREAK" ] || PREV_STREAK=0

if [ "$SHOW_STATUS" -eq 1 ]; then
  echo "== state: $STATE_FILE"; [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "(없음)"
  echo "== repo : $REPO_DIR"
  echo "   branch=$(g rev-parse --abbrev-ref HEAD 2>/dev/null) head=$(g rev-parse --short=12 HEAD 2>/dev/null)"
  echo "   dirty=$(g status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  detect_skip
  exit 0
fi

# ── 이상 중단: 상태 전이 시에만 1회 알린다 (같은 이상 반복 발송 금지) ────────
abort() {                                   # $1=kind $2=사람이 읽을 사유 $3=대응안내
  local kind="$1" why="$2" howto="${3:-}"
  log "ABORT [$kind] $why"
  if [ "$PREV_KIND" != "$kind" ]; then
    notify "🚨 vault 자동 백업 중단 — ${kind}
시각: ${iso_now}
저장소: ${REPO_DIR}
사유: ${why}
${howto}
※ 해소 전까지 자동 커밋은 계속 중단된다(백업 공백 누적)."
  else
    log "동일 이상 지속 — 중복 발송 억제"
  fi
  st_set ALERT_KIND "$kind"
  if [ "$PREV_KIND" = "$kind" ]; then st_set ALERT_SINCE "$(st_get ALERT_SINCE "$ts_now")"
  else st_set ALERT_SINCE "$ts_now"; fi
  st_set PUSH_FAIL_STREAK "$PREV_STREAK"
  st_set LAST_COMMIT_SHA "$(st_get LAST_COMMIT_SHA '')"
  st_set LAST_RUN_TS "$ts_now"
  st_flush
  exit 1
}

# ── 저장소 확인 ──────────────────────────────────────────────────────────────
[ -d "$REPO_DIR/.git" ] || { log "ERROR git 저장소 아님: $REPO_DIR"; exit 1; }
GIT_DIR_ABS="$(g rev-parse --absolute-git-dir 2>/dev/null)"
[ -n "$GIT_DIR_ABS" ] || { log "ERROR git-dir 조회 실패"; exit 1; }

# ── G1: 다른 git 작업 진행 중이면 조용히 양보 (이상이 아니다) ────────────────
if [ -e "$GIT_DIR_ABS/index.lock" ]; then
  log "index.lock 존재 — 다른 git 작업 진행 중. 이번 주기 건너뜀"; exit 0
fi

# ── 중복 실행 방지 (네트워크 지연으로 이전 실행이 남아 있을 수 있다) ─────────
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  lock_ts="$(stat -f %m "$LOCK_DIR" 2>/dev/null || stat -c %Y "$LOCK_DIR" 2>/dev/null || echo 0)"
  if [ "$(( ts_now - lock_ts ))" -gt "$LOCK_STALE" ]; then
    log "WARN 잔재 락 제거 (${LOCK_STALE}초 초과)"; rmdir "$LOCK_DIR" 2>/dev/null
    mkdir "$LOCK_DIR" 2>/dev/null || { log "락 획득 실패 — 종료"; exit 0; }
  else
    log "이전 실행이 아직 진행 중 — 종료"; exit 0
  fi
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

# G9 는 여기서 부른다 — 스테이징·no-op 판정보다 앞이라 **모든 경로에서 발화**한다.
detect_skip

# ── G2: 진행 중인 병합·리베이스·체리픽 잔존 ──────────────────────────────────
INPROG=""
for f in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_LOG rebase-merge rebase-apply sequencer; do
  [ -e "$GIT_DIR_ABS/$f" ] && INPROG="${INPROG}${f} "
done
[ -n "$INPROG" ] && abort "in-progress-op" \
  "진행 중인 git 작업 잔존: ${INPROG}— 불완전 상태를 커밋하면 그대로 전 기기로 전파된다" \
  "대응: cd ${REPO_DIR} → git status 로 진행 중 작업을 사람이 마무리(또는 중단)하라"

# ── G3: detached HEAD / 브랜치 불일치 ────────────────────────────────────────
CUR_BRANCH="$(g symbolic-ref --quiet --short HEAD 2>/dev/null || echo '')"
[ -n "$CUR_BRANCH" ] || abort "detached-head" \
  "detached HEAD 상태 — 커밋해도 어느 브랜치에도 남지 않는다" \
  "대응: cd ${REPO_DIR} → git switch ${BRANCH}"
[ "$CUR_BRANCH" = "$BRANCH" ] || abort "wrong-branch" \
  "현재 브랜치가 ${CUR_BRANCH} (기대: ${BRANCH}) — 백업 대상 브랜치가 아니다" \
  "대응: 작업을 마치고 git switch ${BRANCH}"

# ── G4: 미해결 경로 ──────────────────────────────────────────────────────────
UNMERGED="$(g diff --name-only --diff-filter=U 2>/dev/null | head -20)"
[ -n "$UNMERGED" ] && abort "unresolved-paths" \
  "미해결 경로 존재: $(printf '%s' "$UNMERGED" | tr '\n' ' ')" \
  "대응: 충돌을 사람이 해소한 뒤 git add → git commit"

# ── G6: 원격이 앞서는지 (fetch·pull 없이 ls-remote 로만 확인) ────────────────
# ls-remote 는 로컬 ref 를 건드리지 않는 순수 조회다. 원격 tip 객체가 로컬에
# 없다면 = 우리가 모르는 커밋이 원격에 있다 = behind. 이때 커밋하면 분기가
# 생기고 해소에 병합이 필요해진다(PR-3 위반) — 그래서 커밋 전에 막는다.
REMOTE_TIP="$(g ls-remote --heads "$REMOTE" "$BRANCH" 2>/dev/null | awk 'NR==1{print $1}')"
REMOTE_KNOWN=0
if [ -n "$REMOTE_TIP" ]; then
  REMOTE_KNOWN=1
  if ! g cat-file -e "${REMOTE_TIP}^{commit}" 2>/dev/null; then
    abort "remote-ahead" \
      "원격 ${REMOTE}/${BRANCH} 에 로컬에 없는 커밋이 있다 (원격 tip ${REMOTE_TIP:0:12})" \
      "대응: 사람이 직접 확인·통합하라. 이 스크립트는 병합도 강제 푸시도 하지 않는다"
  fi
  BEHIND="$(g rev-list --count "HEAD..${REMOTE_TIP}" 2>/dev/null || echo 0)"
  [ "${BEHIND:-0}" -gt 0 ] && abort "remote-ahead" \
    "원격이 로컬보다 ${BEHIND}개 커밋 앞섬" \
    "대응: 사람이 직접 확인·통합하라. 강제 푸시는 하지 않는다"
else
  log "WARN 원격 조회 실패(오프라인 추정) — 로컬 커밋은 진행, 푸시는 보류"
fi

# ── 스테이징 후 내용 검사 ────────────────────────────────────────────────────
DIRTY_N="$(g status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
if [ "${DIRTY_N:-0}" -gt 0 ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    # 인덱스를 건드리지 않고 판정하기 위해 임시 인덱스 사본을 쓴다.
    TMP_INDEX="$(mktemp "${TMPDIR:-/tmp}/pab-autocommit-index.XXXXXX")"
    cp "$GIT_DIR_ABS/index" "$TMP_INDEX" 2>/dev/null || : > "$TMP_INDEX"
    export GIT_INDEX_FILE="$TMP_INDEX"
    trap 'rm -f "$TMP_INDEX"; rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
  fi
  g add -A || abort "stage-failed" "git add 실패" "대응: 수동 확인 필요"
fi

STAGED="$(g diff --cached --name-status 2>/dev/null)"
CHANGED_N="$(printf '%s' "$STAGED" | grep -c . || true)"
if [ "${CHANGED_N:-0}" -eq 0 ]; then
  UNPUSHED="$(g rev-list --count "${REMOTE_TIP:-${REMOTE}/${BRANCH}}..HEAD" 2>/dev/null || echo 0)"
  if [ "${UNPUSHED:-0}" -gt 0 ] && [ "$REMOTE_KNOWN" -eq 0 ]; then
    # 오프라인 + 미푸시 잔여: 할 수 있는 일이 없다. 상태를 "정상"으로 덮지 않고 보류한다.
    log "오프라인 — 미푸시 ${UNPUSHED}건 보류(상태 유지)"
    st_set ALERT_KIND "$PREV_KIND"; st_set ALERT_SINCE "$(st_get ALERT_SINCE 0)"
    st_set PUSH_FAIL_STREAK "$PREV_STREAK"
    st_set LAST_COMMIT_SHA "$(g rev-parse --short=12 HEAD)"
    st_set LAST_OK_TS "$(st_get LAST_OK_TS 0)"; st_set LAST_RUN_TS "$ts_now"; st_flush
    exit 0
  fi
  if [ "${UNPUSHED:-0}" -eq 0 ]; then
    log "변경 없음 — 무소음 종료(no-op)"
    [ -n "$PREV_KIND" ] && { notify "✅ vault 자동 백업 정상 복귀 (이전 이상: ${PREV_KIND})
시각: ${iso_now}"; }
    st_set ALERT_KIND ""; st_set ALERT_SINCE 0; st_set PUSH_FAIL_STREAK 0
    st_set LAST_COMMIT_SHA "$(g rev-parse --short=12 HEAD)"; st_set LAST_OK_TS "$ts_now"
    st_set LAST_RUN_TS "$ts_now"; st_flush
    exit 0
  fi
  log "커밋할 변경은 없으나 미푸시 ${UNPUSHED}건 — 푸시만 시도"
fi

# ── G5: 충돌 마커 (스테이징 내용 기준 — 신규 파일까지 덮는다) ────────────────
# `git diff --check` 는 공백 오류도 보고한다. 마크다운의 의도적 trailing space 를
# 이상으로 오판하지 않도록 'conflict marker' 만 골라낸다.
CONFLICT_HITS="$(g diff --cached --check 2>/dev/null | grep -c 'conflict marker' || true)"
[ "${CONFLICT_HITS:-0}" -gt 0 ] && abort "conflict-marker" \
  "충돌 마커가 남은 파일 ${CONFLICT_HITS}건 — 반쯤 해소된 상태를 백업할 수 없다" \
  "대응: git diff --cached --check | grep 'conflict marker' 로 확인 후 사람이 정리"

# ── G7: PUBLIC 저장소 비밀 유출 방어 ─────────────────────────────────────────
# (a) 파일명 기반 — 문서(.md)는 제외한다(제목에 'token' 이 들어간 노트가 정상 존재)
SECRET_FILES="$(printf '%s' "$STAGED" | awk '{ $1=""; sub(/^ /,""); print }' \
  | grep -Ev '\.md$' \
  | grep -Ei '(^|/)\.env($|\.)|(^|/)id_(rsa|ed25519|dsa)($|\.)|\.(pem|p12|pfx|key|keystore)$|(^|/)[^/]*(secret|credential|password)[^/]*$' \
  | head -10 || true)"
[ -n "$SECRET_FILES" ] && abort "secret-file" \
  "비밀로 보이는 파일이 스테이징됨: $(printf '%s' "$SECRET_FILES" | tr '\n' ' ')" \
  "대응: 본 저장소는 PUBLIC 이다. .gitignore 에 추가하거나 .env 로 옮겨라"
# (b) 내용 기반 — Telegram 봇 토큰 형태(숫자:35자)만 좁게 본다(오탐 최소)
if g diff --cached -U0 2>/dev/null | grep -Eq '[0-9]{8,10}:[A-Za-z0-9_-]{35}'; then
  abort "secret-content" \
    "봇 토큰 형태의 문자열이 변경 내용에 포함됨" \
    "대응: 해당 값을 .env(무시됨) 또는 환경변수로 옮기고 문서에는 예시 형식만 남겨라"
fi

# ── G8: 대량 삭제 방어 (복제로 전파된 사고 삭제를 백업에 굳히지 않는다) ──────
DEL_N="$(printf '%s' "$STAGED" | grep -c '^D' || true)"
[ "${DEL_N:-0}" -gt "$MAX_DELETE" ] && abort "mass-delete" \
  "삭제 ${DEL_N}건이 임계(${MAX_DELETE})를 넘었다 — 사고 삭제가 복제로 전파됐을 수 있다" \
  "대응: git diff --cached --diff-filter=D --name-only 로 확인. 의도된 정리면 사람이 직접 커밋하라"

# ── 커밋 ─────────────────────────────────────────────────────────────────────
MOD_N="$(printf '%s' "$STAGED" | grep -c '^M' || true)"
ADD_N="$(printf '%s' "$STAGED" | grep -c '^A' || true)"
REN_N="$(printf '%s' "$STAGED" | grep -c '^R' || true)"
SUBJECT="chore(auto): vault 자동 백업 — ${CHANGED_N}개 파일 변경"
BODY="자동 생성: pab_git_autocommit_local.sh (맥북 로컬 cron, Task 2-5-2)
시각: ${iso_now}
내역: 수정 ${MOD_N} / 추가 ${ADD_N} / 삭제 ${DEL_N} / 이름변경 ${REN_N}${SKIP_NOTE}"

if [ "${CHANGED_N:-0}" -gt 0 ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY-RUN 커밋 억제. 제목: ${SUBJECT}"
    printf '%s\n' "$BODY" | sed 's/^/    /'
    printf '%s\n' "$STAGED" | head -30 | sed 's/^/    /'
    [ "$CHANGED_N" -gt 30 ] && log "    … 외 $(( CHANGED_N - 30 ))건"
  else
    g commit -q -m "$SUBJECT" -m "$BODY" \
      || abort "commit-failed" "git commit 실패 (${CHANGED_N}개 파일)" \
               "대응: cd ${REPO_DIR} → git status / git commit 수동 확인"
    log "커밋 완료: $(g rev-parse --short=12 HEAD) (${CHANGED_N}개 파일)"
  fi
fi

# ── 푸시 (강제 푸시 없음 — 실패하면 알릴 뿐) ─────────────────────────────────
PUSH_OK=1; PUSH_ERR=""
if [ "$DRY_RUN" -eq 1 ]; then
  log "DRY-RUN 푸시 억제 (원격 조회 가능=${REMOTE_KNOWN})"
elif [ "$REMOTE_KNOWN" -eq 0 ]; then
  PUSH_OK=0; PUSH_ERR="원격 조회 불가(오프라인 추정) — 푸시 보류"
  log "$PUSH_ERR"
else
  PUSH_ERR="$(g push "$REMOTE" "$BRANCH" 2>&1)" || PUSH_OK=0
  if [ "$PUSH_OK" -eq 1 ]; then log "푸시 완료 → ${REMOTE}/${BRANCH}"
  else log "ERROR 푸시 실패: $(printf '%s' "$PUSH_ERR" | tail -3 | tr '\n' ' ')"; fi
fi

# ── 상태 기록 + 알림 판정 ────────────────────────────────────────────────────
HEAD_SHA="$(g rev-parse --short=12 HEAD 2>/dev/null)"
if [ "$PUSH_OK" -eq 0 ]; then
  STREAK=$(( PREV_STREAK + 1 ))
  if [ "$STREAK" -ge "$PUSH_FAIL_LIMIT" ] && [ "$PREV_KIND" != "push-failed" ]; then
    notify "🚨 vault 백업 푸시 실패 ${STREAK}회 연속
시각: ${iso_now}
로컬 커밋은 남아 있으나 GitHub 오프사이트 반영이 안 되고 있다.
사유: $(printf '%s' "$PUSH_ERR" | tail -2 | tr '\n' ' ')
대응: cd ${REPO_DIR} → git push ${REMOTE} ${BRANCH} 수동 확인 (강제 푸시 금지)"
    st_set ALERT_KIND "push-failed"; st_set ALERT_SINCE "$ts_now"
  else
    st_set ALERT_KIND "$PREV_KIND"; st_set ALERT_SINCE "$(st_get ALERT_SINCE "$ts_now")"
  fi
  st_set PUSH_FAIL_STREAK "$STREAK"
  st_set LAST_COMMIT_SHA "$HEAD_SHA"; st_set LAST_RUN_TS "$ts_now"; st_flush
  exit 2
fi

[ -n "$PREV_KIND" ] && notify "✅ vault 자동 백업 정상 복귀 (이전 이상: ${PREV_KIND})
시각: ${iso_now} / HEAD ${HEAD_SHA}"
st_set ALERT_KIND ""; st_set ALERT_SINCE 0; st_set PUSH_FAIL_STREAK 0
st_set LAST_COMMIT_SHA "$HEAD_SHA"; st_set LAST_OK_TS "$ts_now"; st_set LAST_RUN_TS "$ts_now"
st_flush
log "OK (head=${HEAD_SHA})"
exit 0
