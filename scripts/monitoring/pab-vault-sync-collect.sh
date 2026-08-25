#!/bin/bash
# pab-vault-sync-collect.sh
# ─────────────────────────────────────────────────────────────────────────────
# 목적:
#   PAB vault 동기화 계층(CouchDB LiveSync · 미러 · 오프사이트 git 백업)에서
#   **기존 수집기가 구조적으로 잡을 수 없는 3가지 공백**만 5분 주기로 판정해
#   RPi5 Uptime Kuma 로 단일 Push heartbeat 를 보낸다.
#
# 배경 (docs/phases/phase-2-5-pre-analysis.md §1, observer-integration-prompt §2):
#   2026-08-21 재부팅 레이스로 pab-couchdb 가 Tailnet IP 바인딩에 실패해 3일간
#   LiveSync 가 전면 중단됐으나 08-24 까지 아무도 몰랐다.
#   그런데 UK 의 :5984 모니터는 **존재했고 정상 동작 중이었다**(CouchDB 로그에
#   RPi5 의 15초 주기 /_up 호출 기록). 감지는 됐으나 알림이 사람에게 닿지 않았다.
#   → 관측 자체보다 "도달"이 문제였다. 이 수집기는 도달 경로를 UK 로 일원화하고,
#     정상 시에는 heartbeat 존재만으로 침묵한다(무소음).
#
#   기존 수집기가 못 잡는 공백만 본다 (중복 감시 금지):
#     N-1 couch-net    : container-health-collect.sh 는 .State.Running/.RestartCount
#                        만 본다. 08-21 복구 중 CouchDB 가 running·healthy 인데
#                        네트워크 엔드포인트가 없어(Networks:{}, 포트매핑 공란)
#                        통신 불가한 위양성 상태가 실제로 발생했다.
#     N-2 git-gap      : 오프사이트 백업 공백. 컨테이너 관측 대상이 아니다.
#                        (조사 시점 실측 34일 공백)
#     N-3 mirror-fresh : bridge 가 running 이어도 CouchDB 연결이 끊기면 미러는
#                        갱신되지 않는다. 프로세스 생존 ≠ 기능 정상.
#   pab-livesync-bridge 컨테이너 자체는 container-health-collect.sh 가 이미
#   감시하므로 여기서 중복 감시하지 않는다.
#
# 선례 (반드시 승계):
#   상태파일 값은 반드시 printf %q 로 기록한다. quote 없이 쓰면 다음 주기 파싱이
#   깨진다 — vault-chain-collect.sh 가 정확히 그 버그로 46일간 침묵했다.
#   **감시자가 조용히 죽는 실패 모드는 감시자가 없는 것보다 나쁘다.**
#   bash 3.2 호환 유지(declare -A 금지) — 개발기에서도 드라이런 가능해야 한다.
#
# Push 규약 (기존 수집기와 동일):
#   GET {UK_PAB_VAULT_PUSH_URL}?status={up|down}&msg={요약}&ping={정상항목수}
#   URL 미설정 시 Push 생략하고 정상 종료.
#   msg 에 `_` 단독 토큰을 넣지 않는다 (Telegram parse-mode 충돌 회피).
#
# cron:
#   */5 * * * * /home/oceanui/observer/scripts/pab-vault-sync-collect.sh >> /tmp/obs-pab-vault-sync.log 2>&1
#
# 의존: docker, curl, jq, git, find
# ─────────────────────────────────────────────────────────────────────────────

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
STATE_DIR="${SCRIPT_DIR}/../state"
STATE_FILE="${STATE_DIR}/pab-vault-sync-state.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

PUSH_URL="${UK_PAB_VAULT_PUSH_URL:-}"

# ── 대상 ─────────────────────────────────────────────────────────────────────
COUCH_CONTAINER="${PAB_COUCHDB_CONTAINER:-pab-couchdb}"
TAILNET_IP="${PAB_TAILNET_IP:-100.109.251.86}"
COUCH_PORT="${PAB_COUCHDB_PORT:-5984}"
MIRROR_DIR="${PAB_MIRROR_DIR:-/home/oceanui/pab-vault-mirror}"
GIT_API="${PAB_GIT_API:-https://api.github.com/repos/ChoonghoRoh/PAB-obsidian/commits/main}"
GIT_REMOTE="${PAB_GIT_REMOTE:-git@github.com:ChoonghoRoh/PAB-obsidian.git}"
GIT_MAX_AGE_H="${PAB_GIT_MAX_AGE_HOURS:-24}"
GIT_THROTTLE="${PAB_GIT_CHECK_INTERVAL_SEC:-3600}"   # 원격 조회는 시간당 1회로 제한
MIRROR_DROP_PCT="${PAB_MIRROR_DROP_PCT:-80}"         # 직전 대비 80% 미만이면 급감
STAMP_FILE="${PAB_GIT_STAMP_FILE:-/home/oceanui/pab-vault-monitor/state/git-stamp.env}"
STAMP_MAX_AGE="${PAB_STAMP_MAX_AGE:-7200}"           # 2h — 맥북 stamp cron 은 매시 정각
CURL_T="${PAB_CURL_TIMEOUT:-10}"

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

TS_NOW="$(date +%s)"

# ── 상태파일 I/O (printf %q 필수 — §선례) ────────────────────────────────────
st_get() {
  local v
  [ -f "$STATE_FILE" ] || { printf '%s' "${2:-}"; return 0; }
  v="$(grep -m1 "^${1}=" "$STATE_FILE" 2>/dev/null | cut -d= -f2- || true)"
  [ -n "$v" ] || { printf '%s' "${2:-}"; return 0; }
  v="${v%\'}"; v="${v#\'}"
  printf '%s' "$v"
}
NEW_STATE=""
st_set() { NEW_STATE="${NEW_STATE}${1}=$(printf '%q' "${2:-}")
"; }
write_state() {
  [ "$DRY_RUN" -eq 1 ] && return 0
  mkdir -p "$STATE_DIR"
  printf '%s' "$NEW_STATE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# ── 조용한 죽음 방지 (§1.4) ──────────────────────────────────────────────────
# 수집기가 예기치 못한 오류로 죽으면 아무 신호도 남지 않아 "덮여 있다"는 착각만
# 남는다 — vault-chain-collect.sh 가 그 버그로 46일 침묵했다. 오류 시 down 을
# 밀어 올려 최소한 사람이 알게 한다(Push 실패해도 heartbeat 유실로 UK 가 잡는다).
on_err() {
  local rc=$? line="${1:-?}"
  echo "[pab-vault-sync] ERROR rc=${rc} line=${line} — 수집기 자체 오류" >&2
  if [ -n "${PUSH_URL:-}" ]; then
    curl -fsS --max-time 10 -G "$PUSH_URL" \
      --data-urlencode "status=down" \
      --data-urlencode "msg=collector-error rc-${rc} line-${line}" \
      --data-urlencode "ping=0" >/dev/null 2>&1 || true
  fi
  exit "$rc"
}
trap 'on_err $LINENO' ERR

[ -f "$STATE_FILE" ] || echo "[pab-vault-sync] state 부재 — 첫 실행" >&2

FAIL_LIST=""
OK_COUNT=0
INFO=""
add_fail() { FAIL_LIST="${FAIL_LIST}${1},"; }
add_ok()   { OK_COUNT=$(( OK_COUNT + 1 )); }

# ── N-1 couch-net : 네트워크 엔드포인트 + 포트 매핑 실재 ─────────────────────
# running/healthy 만 보면 08-21 위양성 상태를 그대로 up 으로 오인한다.
nets=""; hostport=""
if ! nets="$(docker inspect -f '{{len .NetworkSettings.Networks}}' "$COUCH_CONTAINER" 2>/dev/null)"; then
  nets=""
fi
if [ -n "$nets" ] && [ "$nets" -gt 0 ] 2>/dev/null; then
  ports_json="$(docker inspect -f '{{json .NetworkSettings.Ports}}' "$COUCH_CONTAINER" 2>/dev/null || echo '{}')"
  hostport="$(printf '%s' "$ports_json" | jq -r --arg p "${COUCH_PORT}/tcp" '.[$p][0].HostPort // empty' 2>/dev/null || true)"
fi
if [ -z "$nets" ]; then
  add_fail "couch-net"; INFO="${INFO} couch-net:컨테이너없음"
elif [ "$nets" -eq 0 ] 2>/dev/null; then
  add_fail "couch-net"; INFO="${INFO} couch-net:엔드포인트소실"
elif [ -z "$hostport" ]; then
  add_fail "couch-net"; INFO="${INFO} couch-net:포트매핑공란"
else
  add_ok
fi

# ── couch-up : Tailnet IP 경유 /_up (localhost 로 하면 N-1 을 놓친다) ────────
# curl 은 실패해도 %{http_code} 로 000 을 출력한다 → `|| echo 000` 을 붙이면
# 000000 이 되어 msg 가 오염된다. 종료코드만 무시하고 출력은 그대로 쓴다.
up_code="$(curl -s -m "$CURL_T" -o /dev/null -w '%{http_code}' \
           "http://${TAILNET_IP}:${COUCH_PORT}/_up" 2>/dev/null || true)"
[ -n "$up_code" ] || up_code=000
if [ "$up_code" = "200" ]; then add_ok; else
  add_fail "couch-up"; INFO="${INFO} couch-up:HTTP${up_code}"
fi

# ── N-3 mirror-fresh : 파일 수 0 또는 급감 ───────────────────────────────────
# mtime 은 실패 조건이 아니다 — 사용자가 며칠 노트를 안 쓰면 정상적으로 오래된다.
# 추세 관측용 정보로만 싣는다.
# [주의] 미러 디렉토리가 없으면 find 는 1 을 반환하고 pipefail 이 걸려 assignment 가
# 실패한다 → set -e 로 수집기가 **즉사**한다. 하필 N-3 이 감지해야 할 바로 그 상황에서
# 아무 신호 없이 죽는 최악의 실패였다(2026-08-25 구현 중 실측·수정).
if [ -d "$MIRROR_DIR" ]; then
  md_count="$(find "$MIRROR_DIR" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ' || true)"
  newest="$(find "$MIRROR_DIR" -type f -printf '%T@\n' 2>/dev/null | sort -rn | head -1 | cut -d. -f1 || true)"
else
  md_count=0; newest=""
fi
[ -n "$md_count" ] || md_count=0
prev_count="$(st_get MIRROR_MD_COUNT "")"
mirror_age_h=0
if [ -n "$newest" ]; then mirror_age_h=$(( (TS_NOW - newest) / 3600 )); fi
st_set MIRROR_MD_COUNT "$md_count"
if [ ! -d "$MIRROR_DIR" ]; then
  add_fail "mirror-fresh"; INFO="${INFO} mirror:디렉토리없음"
elif [ "${md_count:-0}" -eq 0 ]; then
  add_fail "mirror-fresh"; INFO="${INFO} mirror:0건"
elif [ -n "$prev_count" ] && [ "$prev_count" -gt 0 ] 2>/dev/null \
     && [ $(( md_count * 100 )) -lt $(( prev_count * MIRROR_DROP_PCT )) ]; then
  add_fail "mirror-fresh"; INFO="${INFO} mirror:급감${prev_count}->${md_count}"
else
  add_ok
fi

# ── N-2 git-gap : 오프사이트 백업 공백 ───────────────────────────────────────
# 판정 대상은 **GitHub origin/main tip** 이다. 맥북 로컬 저장소가 아니라 실제로 올라간
# 커밋이 오프사이트 백업이며, 맥북이 꺼져 있어도(DP-2-5-2 잔여 위험) 서버가 독립적으로
# 공백을 잴 수 있다. stamp 만으로 판정하면 맥북이 죽는 순간 stamp 도 멈춰
# "백업 공백"과 "stamp 공백"을 영영 구분할 수 없다(감시자가 감시대상에 의존하는 안티패턴).
#
# 맥북 stamp(pab-git-stamp-local.sh, 매시)는 **판정이 아니라 원인 구분**에 쓴다:
#   stamp 낡음        → mac-silent-Nh   (맥북 꺼짐/침묵 — 값이 갱신되지 않는 상황)
#   stamp 신선+미푸시 → unpushed-N      (맥북은 살아 있는데 푸시가 안 됨)
#   stamp 신선+푸시완 → no-new-commit   (진짜 커밋 공백)
#   stamp 없음        → stamp-none
git_last_ck="$(st_get GIT_LAST_CHECK_TS 0)"
git_sha="$(st_get GIT_TIP_SHA "")"
git_first_seen="$(st_get GIT_TIP_FIRST_SEEN "$TS_NOW")"
git_commit_ts="$(st_get GIT_COMMIT_TS "")"
if [ $(( TS_NOW - git_last_ck )) -ge "$GIT_THROTTLE" ] || [ -z "$git_sha" ]; then
  api_out="$(curl -s -m "$CURL_T" "$GIT_API" 2>/dev/null || true)"
  api_sha="$(printf '%s' "$api_out" | jq -r '.sha // empty' 2>/dev/null || true)"
  api_date="$(printf '%s' "$api_out" | jq -r '.commit.committer.date // empty' 2>/dev/null || true)"
  new_sha=""
  if [ -n "$api_sha" ]; then
    new_sha="$api_sha"
    [ -n "$api_date" ] && git_commit_ts="$(date -u -d "$api_date" +%s 2>/dev/null || true)"
  else
    new_sha="$(GIT_TERMINAL_PROMPT=0 timeout 25 git ls-remote "$GIT_REMOTE" refs/heads/main 2>/dev/null | awk '{print $1}' || true)"
  fi
  if [ -n "$new_sha" ]; then
    [ "$new_sha" != "$git_sha" ] && git_first_seen="$TS_NOW"
    git_sha="$new_sha"
    git_last_ck="$TS_NOW"
  fi
  # 조회 실패 시에는 직전 값을 유지한다 — 네트워크 문제로 백업 공백을 오보하지 않는다.
fi
[ -n "$git_commit_ts" ] || git_commit_ts="$git_first_seen"
git_age_h=$(( (TS_NOW - git_commit_ts) / 3600 ))
st_set GIT_LAST_CHECK_TS "$git_last_ck"
st_set GIT_TIP_SHA "$git_sha"
st_set GIT_TIP_FIRST_SEEN "$git_first_seen"
st_set GIT_COMMIT_TS "$git_commit_ts"
if [ -z "$git_sha" ]; then
  INFO="${INFO} git-gap:조회불가"
  add_ok        # 원격 조회 실패는 백업 공백의 증거가 아니다 (오보 방지)
elif [ "$git_age_h" -gt "$GIT_MAX_AGE_H" ]; then
  # 원인 구분 — 판정은 이미 끝났고, 여기서는 사람이 바로 손댈 수 있게 사유만 붙인다.
  git_cause="stamp-none"
  if [ -f "$STAMP_FILE" ]; then
    s_ts="$(grep -m1 '^STAMP_TS=' "$STAMP_FILE" 2>/dev/null | cut -d= -f2- || true)"
    s_unp="$(grep -m1 '^UNPUSHED=' "$STAMP_FILE" 2>/dev/null | cut -d= -f2- || true)"
    case "${s_ts:-}" in ''|*[!0-9]*) s_ts="" ;; esac
    case "${s_unp:-}" in ''|*[!0-9]*) s_unp=0 ;; esac
    if [ -z "$s_ts" ]; then
      git_cause="stamp-broken"
    elif [ $(( TS_NOW - s_ts )) -gt "$STAMP_MAX_AGE" ]; then
      git_cause="mac-silent-$(( (TS_NOW - s_ts) / 3600 ))h"
    elif [ "$s_unp" -gt 0 ]; then
      git_cause="unpushed-${s_unp}"
    else
      git_cause="no-new-commit"
    fi
  fi
  add_fail "git-gap"; INFO="${INFO} git-gap:${git_age_h}h/${git_cause}"
else
  add_ok
fi

# ── 판정 + Push ──────────────────────────────────────────────────────────────
TOTAL=4
STATUS="up"
# msg 에 `_` 단독 토큰 금지 (Telegram parse-mode entity 충돌)
MSG="vault-sync-${OK_COUNT}/${TOTAL}ok mirror-${md_count}md git-${git_age_h}h"
if [ -n "$FAIL_LIST" ]; then
  STATUS="down"
  MSG="DOWN:${FAIL_LIST%,} ok-${OK_COUNT}/${TOTAL}${INFO}"
fi
MSG="${MSG//_/-}"

st_set LAST_RUN_TS "$TS_NOW"
st_set LAST_STATUS "$STATUS"
write_state

echo "[pab-vault-sync] status=${STATUS} ${MSG}" >&2

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[pab-vault-sync] DRY-RUN — Push 생략" >&2
  exit 0
fi
if [ -z "$PUSH_URL" ]; then
  echo "[warn] UK-PAB-VAULT-PUSH-URL 미설정 — Push 생략" >&2
  exit 0
fi

# Push 실패가 수집기를 죽이면 안 된다(다음 주기 재시도). heartbeat 유실은 UK 가 잡는다.
curl -fsS --max-time 10 -G "$PUSH_URL" \
  --data-urlencode "status=${STATUS}" \
  --data-urlencode "msg=${MSG}" \
  --data-urlencode "ping=${OK_COUNT}" >/dev/null || echo "[warn] Push 실패 — 다음 주기 재시도" >&2
