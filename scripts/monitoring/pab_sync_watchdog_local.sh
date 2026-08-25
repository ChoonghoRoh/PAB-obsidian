#!/usr/bin/env bash
#
# pab_sync_watchdog_local.sh — 맥북발 역방향 확인 (서버 침묵 감지)
# Phase 2-5 / Task 2-5-1 (G-1) — backend-dev
# ─────────────────────────────────────────────────────────────────────────────
# 왜 필요한가 (DP-2-5-1 잔여 위험):
#   서버 감시는 3800X crontab 이 돈다. 그런데 **서버 자체가 죽으면 그 cron 도 같이
#   죽으므로 아무 알림도 오지 않는다**(= 침묵). 08-21 사건과 동일한 무인지 구조다.
#   이 스크립트는 클라이언트(맥북)에서 서버를 거꾸로 확인해 그 사각을 덮는다.
#   상호 감시: 서버 cron → git 백업 공백 감시 / 맥북 cron → 서버 침묵 감시.
#
# 점검:
#   ssh-reachable  : 3800X SSH 접속 (BatchMode, agent 없이도 성립하는 키)
#   heartbeat-fresh: 서버 헬스체크가 남긴 하트비트가 HB-MAX-AGE(기본 30분) 이내인가
#                    → cron 정지·스크립트 파손 등 "돌지 않는 감시" 검출
#   server-status  : 하트비트의 STATUS 가 OK 인가 (FAIL 이면 주간 리마인드)
#   endpoint-direct: 맥북에서 직접 http://<IP>:5984/_up (LiveSync 클라이언트 관점 왕복)
#
# 위양성 억제:
#   - 인터넷 자체가 없으면(비행기·오프라인) 판정하지 않고 조용히 종료한다.
#   - 각 점검은 RETRY-COUNT(기본 3)회 × RETRY-DELAY(기본 60초) 재시도 후에야 실패로
#     확정한다. 주 1회 실행이라 "연속 N회 실행"으로는 플래핑을 못 거른다 —
#     대신 같은 실행 안에서 재시도해 순간적 네트워크 흔들림을 걸러낸다(PR-2 동일 취지).
#   - 정상이면 **완전 무소음**. 실패 전이 시 1회, 복구 시 1회만 보낸다.
#
# 알림: scripts/pmAuto/report_to_telegram.sh 재사용 (맥북에는 <repo>/.env 가 있다)
# 상태: $HOME/.pab-sync-monitor/ (git 저장소 밖 — per-machine 파일 추적 금지, R-2)
#
# cron (맥북, 주 1회 — DP-2-5-1):
#   0 9 * * 1 /Users/map-rch/WORKS/PAB-obsidian/scripts/monitoring/pab_sync_watchdog_local.sh >> /tmp/pab-sync-watchdog.log 2>&1  # PAB-SYNC-WATCHDOG
#
# 사용: pab_sync_watchdog_local.sh [--dry-run|--status]
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail
PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORT_SH="$PROJECT_ROOT/scripts/pmAuto/report_to_telegram.sh"

STATE_DIR="${PAB_WATCHDOG_STATE:-$HOME/.pab-sync-monitor}"
STATE_FILE="$STATE_DIR/watchdog-state.env"

PROJECT_TAG="${PAB_PROJECT_TAG:-PAB-v3}"
SSH_HOST="${PAB_SSH_HOST:-3800x}"
TAILNET_IP="${PAB_TAILNET_IP:-100.109.251.86}"
COUCHDB_PORT="${PAB_COUCHDB_PORT:-5984}"
REMOTE_HEARTBEAT="${PAB_REMOTE_HEARTBEAT:-/home/oceanui/pab-vault-monitor/state/heartbeat}"
HB_MAX_AGE="${PAB_HB_MAX_AGE:-1800}"      # 30분 = 5분 주기 6회 연속 결번
RETRY_COUNT="${PAB_RETRY_COUNT:-3}"
RETRY_DELAY="${PAB_RETRY_DELAY:-60}"
SSH_TIMEOUT="${PAB_SSH_TIMEOUT:-15}"
CURL_TIMEOUT="${PAB_CURL_TIMEOUT:-10}"

DRY_RUN=0; SHOW_STATUS=0
case "${1:-}" in
  --dry-run) DRY_RUN=1 ;;
  --status)  SHOW_STATUS=1 ;;
  "") ;;
  *) echo "usage: $0 [--dry-run|--status]" >&2; exit 64 ;;
esac

mkdir -p "$STATE_DIR"; chmod 700 "$STATE_DIR" 2>/dev/null || true
ts_now="$(date +%s)"
iso_now="$(date '+%Y-%m-%d %H:%M:%S %Z')"
log() { printf '%s [watchdog] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*"; }

# PR-4: Markdown entity 파싱 실패 회피 (`_` 단독 토큰 등)
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
  if [ ! -x "$REPORT_SH" ]; then log "ERROR report-to-telegram.sh 없음: $REPORT_SH"; return 1; fi
  "$REPORT_SH" "$PROJECT_TAG" "$body" >/dev/null 2>&1 \
    && { log "notify sent"; return 0; } || { log "ERROR 발송 실패"; return 1; }
}

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

if [ "$SHOW_STATUS" -eq 1 ]; then
  echo "== state: $STATE_FILE"; [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "(없음)"
  exit 0
fi

# ── 사전 관문: 인터넷 없으면 판정 자체를 하지 않는다 ─────────────────────────
# 오프라인 상태에서 "서버가 죽었다"고 단정하면 순수 위양성이고, 애초에 알림도
# 나가지 않는다. 조용히 종료하고 다음 주기에 다시 본다.
net_code="$(curl -s -m 8 -o /dev/null -w '%{http_code}' https://api.telegram.org 2>/dev/null)"
if [ "${net_code:-000}" = "000" ]; then
  log "인터넷 도달 불가 — 판정 보류(위양성 방지), 종료"; exit 0
fi

# ── 점검 (재시도 포함) ───────────────────────────────────────────────────────
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout="$SSH_TIMEOUT" -o StrictHostKeyChecking=accept-new)
HB_RAW=""

probe_once() {
  HB_RAW=""
  HB_RAW="$(ssh "${SSH_OPTS[@]}" "$SSH_HOST" "cat '$REMOTE_HEARTBEAT' 2>/dev/null" 2>/dev/null)"
  local ssh_rc=$?
  SSH_OK=0; HB_TS=""; HB_STATUS=""; HB_FAILING=""
  [ $ssh_rc -eq 0 ] && SSH_OK=1
  if [ -n "$HB_RAW" ]; then
    HB_TS="$(printf '%s' "$HB_RAW"      | grep -m1 '^TS='      | cut -d= -f2-)"
    HB_STATUS="$(printf '%s' "$HB_RAW"  | grep -m1 '^STATUS='  | cut -d= -f2-)"
    HB_FAILING="$(printf '%s' "$HB_RAW" | grep -m1 '^FAILING=' | cut -d= -f2-)"
  fi
  UP_CODE="$(curl -s -m "$CURL_TIMEOUT" -o /dev/null -w '%{http_code}' \
             "http://${TAILNET_IP}:${COUCHDB_PORT}/_up" 2>/dev/null)"
  [ "$SSH_OK" -eq 1 ] && [ "${UP_CODE:-000}" = "200" ] \
    && [ -n "$HB_TS" ] && [ $(( ts_now - HB_TS )) -le "$HB_MAX_AGE" ] \
    && [ "$HB_STATUS" = "OK" ]
}

attempt=1
while true; do
  if probe_once; then break; fi
  [ "$attempt" -ge "$RETRY_COUNT" ] && break
  log "시도 ${attempt}/${RETRY_COUNT} 실패 — ${RETRY_DELAY}초 후 재시도"
  sleep "$RETRY_DELAY"; attempt=$(( attempt + 1 )); ts_now="$(date +%s)"
done

FAIL_LINES=""
[ "${SSH_OK:-0}" -eq 1 ] || FAIL_LINES="${FAIL_LINES} - ssh-reachable: 3800X SSH 접속 불가 (서버 다운·Tailnet 단절 의심)"$'\n'
if [ -z "${HB_TS:-}" ]; then
  [ "${SSH_OK:-0}" -eq 1 ] && FAIL_LINES="${FAIL_LINES} - heartbeat-fresh: 하트비트 파일 없음 (서버 cron 미등록·스크립트 파손)"$'\n'
else
  hb_age=$(( ts_now - HB_TS ))
  if [ "$hb_age" -gt "$HB_MAX_AGE" ]; then
    FAIL_LINES="${FAIL_LINES} - heartbeat-fresh: 하트비트 ${hb_age}초 경과 (임계 ${HB_MAX_AGE}초) — 서버 감시가 멈췄다"$'\n'
  elif [ "${HB_STATUS:-}" != "OK" ]; then
    FAIL_LINES="${FAIL_LINES} - server-status: 서버 자체 점검 FAIL (${HB_FAILING:-unknown})"$'\n'
  fi
fi
[ "${UP_CODE:-000}" = "200" ] || FAIL_LINES="${FAIL_LINES} - endpoint-direct: 맥북에서 CouchDB /-up 응답 HTTP ${UP_CODE:-000}"$'\n'

prev_state="$(st_get WATCHDOG_ALERT 0)"
if [ -n "$FAIL_LINES" ]; then
  log "FAIL (${attempt}회 시도 후 확정)"
  printf '%s' "$FAIL_LINES"
  if [ "$prev_state" != "1" ]; then
    notify "🚨 서버 침묵·이상 감지 (맥북 역방향 점검)
점검: ${iso_now} / 재시도 ${attempt}회 모두 실패
대상: 3800X (${TAILNET_IP})
${FAIL_LINES}대응: ssh 3800x → docker ps / cd /home/oceanui/pab-vault-cloud
      docker compose up -d --force-recreate
      crontab -l | grep PAB-SYNC-MONITOR   (감시 cron 생존 확인)"
  else
    log "이미 알림 상태 — 중복 발송 억제"
  fi
  st_set WATCHDOG_ALERT 1
  [ "$prev_state" = "1" ] && st_set ALERT_SINCE "$(st_get ALERT_SINCE "$ts_now")" || st_set ALERT_SINCE "$ts_now"
  st_set LAST_RUN_TS "$ts_now"; st_flush
  exit 1
fi

log "OK — ssh/heartbeat/endpoint 정상 (무소음)"
if [ "$prev_state" = "1" ]; then
  since="$(st_get ALERT_SINCE "$ts_now")"
  notify "✅ 서버 정상 복귀 확인 (맥북 역방향 점검)
점검: ${iso_now} / 이상 지속 약 $(( (ts_now - since) / 60 ))분
ssh·하트비트·CouchDB 엔드포인트 모두 정상"
fi
st_set WATCHDOG_ALERT 0; st_set ALERT_SINCE 0; st_set LAST_RUN_TS "$ts_now"; st_flush
exit 0
