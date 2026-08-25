#!/usr/bin/env bash
#
# pab_sync_healthcheck.sh — PAB LiveSync 인프라 헬스체크 + Telegram 알림
# Phase 2-5 / Task 2-5-1 (G-1) — backend-dev
# ─────────────────────────────────────────────────────────────────────────────
# 배경 (docs/phases/phase-2-5-pre-analysis.md §1):
#   2026-08-21 서버 재부팅 → Docker 가 tailscaled 보다 선행 기동 → 100.109.251.86
#   미할당 상태에서 포트 바인딩 실패 → pab-couchdb Exited(128), bridge 크래시 루프.
#   **3일간 아무도 몰랐다.** 감시 수단 0건이 직접 원인(G-1)이다.
#
#   §1.3 위양성 함정: 네트워킹 셋업 실패 시 컨테이너가 **네트워크 엔드포인트 없는
#   상태**(`Networks: {}` / 포트 매핑 공란)로 남고, 이 때 `docker compose up -d` 는
#   재생성 없이 start 만 하므로 **healthy 로 뜨면서도 통신 불가**하다.
#   → running/healthy 만 보면 못 잡는다. 이 스크립트는 아래를 함께 본다:
#       (a) 네트워크 엔드포인트 개수 > 0
#       (b) 5984/tcp 호스트 포트 바인딩 실재
#       (c) Tailnet IP 로의 실제 HTTP 왕복(localhost 아님)
#
# 점검 항목:
#   couchdb-container : running + Networks>0 + 5984/tcp HostPort 바인딩 + 재시작폭주
#   couchdb-endpoint  : http://<TAILNET_IP>:5984/_up → 200 & status=ok
#   couchdb-db        : 인증 GET /<DB> → 200 & doc_count>0 (DB 자체 소실 검출)
#   bridge-container  : running + Networks>0 + 재시작폭주
#   github-backup     : origin/main tip 커밋 경과 > 24h → 오프사이트 백업 공백
#
# [역할 변경 2026-08-25] 1차 알림 경로는 Observer/UK 로 일원화됐다
#   (docs/phases/phase-2-5-observer-integration-prompt.md §3.1).
#   이 스크립트는 그 경로가 덮지 못하는 **보조 Telegram 경로**다:
#     · UK_PAB_VAULT_PUSH_URL 미발급 구간의 공백 메우기 (지금이 그 구간)
#     · 인증 DB 점검(couchdb-db)·bridge 컨테이너 등 UK 계약 밖 항목
#     · 맥북 역방향 watchdog 이 읽는 heartbeat 생성
#   observer/.env 에 UK_PAB_VAULT_PUSH_URL 이 등록되면 **Telegram 발송은 자동으로
#   멈춘다**(PAB_TELEGRAM_FALLBACK=auto 기본). 점검·heartbeat 는 계속 돈다.
#   강제 유지는 PAB_TELEGRAM_FALLBACK=force, 완전 차단은 =off.
#
# 알림 정책 (PR-2 플래핑 방지):
#   - 정상일 때 **완전 무소음**. 아무것도 보내지 않는다.
#   - 연속 FAIL_THRESHOLD(기본 3)회 실패한 항목이 생기면 **그 항목에 대해 1회만** 발송.
#   - 알림 상태는 항목별로 따로 관리한다 — 장기 실패 항목이 ALERT 를 점유해 새 장애를
#     묻어버리는(=알림이 있는 줄 아는) 상태를 만들지 않기 위해서다.
#   - 이상 지속 중에는 REMIND_SEC(기본 24h)마다 최대 1회 재알림.
#   - 각 항목이 정상 복귀하면 복구 알림 1회.
#
# 자격증명 (하드코딩 금지):
#   Telegram : PAB_MONITOR_ENV → <BASE>/monitor.env → /home/oceanui/observer/.env
#              → <repo>/.env  (먼저 발견되는 것 1개. 값은 로그·알림에 절대 미출력)
#   CouchDB  : COUCHDB_ENV_FILE (기본 /home/oceanui/pab-vault-cloud/.env)
#
# 사용:
#   pab_sync_healthcheck.sh              # cron 용 (정상 시 무소음)
#   pab_sync_healthcheck.sh --dry-run    # 점검만, 알림·상태기록 없음
#   pab_sync_healthcheck.sh --status     # 현재 상태파일/하트비트 출력
#   pab_sync_healthcheck.sh --test-notify # 전달 경로 확인용 테스트 메시지 1건
#
# cron (3800X):
#   */5 * * * * /home/oceanui/pab-vault-monitor/pab_sync_healthcheck.sh >> /tmp/pab-sync-health.log 2>&1  # PAB-SYNC-MONITOR
#
# 의존: bash4+, docker, curl, jq, git
# ─────────────────────────────────────────────────────────────────────────────

# set -e 는 쓰지 않는다 — 점검 실패는 정상 흐름이며 중단되면 안 된다.
set -uo pipefail

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH

# ── 튜너블 ───────────────────────────────────────────────────────────────────
BASE_DIR="${PAB_MONITOR_BASE:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
STATE_DIR="${PAB_MONITOR_STATE:-$BASE_DIR/state}"
STATE_FILE="$STATE_DIR/health-state.env"
HEARTBEAT_FILE="$STATE_DIR/heartbeat"
LOCK_FILE="$STATE_DIR/.lock"

PROJECT_TAG="${PAB_PROJECT_TAG:-PAB-v3}"
TAILNET_IP="${PAB_TAILNET_IP:-100.109.251.86}"
COUCHDB_PORT="${PAB_COUCHDB_PORT:-5984}"
COUCHDB_CONTAINER="${PAB_COUCHDB_CONTAINER:-pab-couchdb}"
BRIDGE_CONTAINER="${PAB_BRIDGE_CONTAINER:-pab-livesync-bridge}"
DB_NAME="${PAB_DB_NAME:-pab-llmdata}"
COUCHDB_ENV_FILE="${COUCHDB_ENV_FILE:-/home/oceanui/pab-vault-cloud/.env}"

GIT_REMOTE="${PAB_GIT_REMOTE:-git@github.com:ChoonghoRoh/PAB-obsidian.git}"
GIT_API="${PAB_GIT_API:-https://api.github.com/repos/ChoonghoRoh/PAB-obsidian/commits/main}"
GIT_MAX_AGE_HOURS="${PAB_GIT_MAX_AGE_HOURS:-24}"
GIT_CHECK_INTERVAL_SEC="${PAB_GIT_CHECK_INTERVAL_SEC:-3600}"   # ls-remote/API 호출 스로틀
CHECK_GIT_ENABLED="${PAB_CHECK_GIT_ENABLED:-1}"

# 연속 N회 — 근거: 점검주기 5분 × 3회 = 최소 10분 연속 실패라야 발송.
# compose healthcheck 최악 복구시간(start_period 20s + 15s×5)·재부팅(~3분)·
# deploy.sh 재빌드보다 길어 계획된 유지보수로는 울리지 않는다. 반면 08-21 사건의
# 3일 무인지 대비 최대 감지 지연 15분 = 288배 개선.
FAIL_THRESHOLD="${PAB_FAIL_THRESHOLD:-3}"
REMIND_SEC="${PAB_REMIND_SEC:-86400}"
CURL_TIMEOUT="${PAB_CURL_TIMEOUT:-10}"
RESTART_STORM_DELTA="${PAB_RESTART_STORM_DELTA:-3}"

# 볼륨 백업 감시 (T-3) — 36h = 일1회 주기의 1회 결번 + 12h 여유 / 10일 = 주1회 + 3일 여유
VOLBACKUP_STATE="${PAB_VOLBACKUP_STATE:-$STATE_DIR/couchdb-volbackup.env}"
VOLBACKUP_MAX_AGE_H="${PAB_VOLBACKUP_MAX_AGE_H:-36}"
VOLBACKUP_VERIFY_MAX_AGE_D="${PAB_VOLBACKUP_VERIFY_MAX_AGE_D:-10}"
VOLBACKUP_KEEP="${PAB_VOLBACKUP_KEEP:-7}"
CHECK_VOLBACKUP_ENABLED="${PAB_CHECK_VOLBACKUP_ENABLED:-auto}"
CHECK_KEYS="couchdb-container couchdb-endpoint couchdb-db bridge-container github-backup couchdb-volbackup"

# 보조 경로 활성 판정 — UK Push URL 이 발급되면 Telegram 직접 발송을 자동으로 멈춘다.
PAB_UK_ENV_FILE="${PAB_UK_ENV_FILE:-/home/oceanui/observer/.env}"
TELEGRAM_FALLBACK="${PAB_TELEGRAM_FALLBACK:-auto}"
FALLBACK_ON=1
case "$TELEGRAM_FALLBACK" in
  force) FALLBACK_ON=1 ;;
  off)   FALLBACK_ON=0 ;;
  *)     grep -qs '^UK_PAB_VAULT_PUSH_URL=..*' "$PAB_UK_ENV_FILE" && FALLBACK_ON=0 || FALLBACK_ON=1 ;;
esac

DRY_RUN=0; SHOW_STATUS=0; TEST_NOTIFY=0
case "${1:-}" in
  --dry-run) DRY_RUN=1 ;;
  --status)  SHOW_STATUS=1 ;;
  --test-notify) TEST_NOTIFY=1 ;;
  "") ;;
  *) echo "usage: $0 [--dry-run|--status|--test-notify]" >&2; exit 64 ;;
esac

mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR" 2>/dev/null || true

ts_now="$(date +%s)"
iso_now="$(date '+%Y-%m-%d %H:%M:%S %Z')"

log() { printf '%s [health] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*"; }

# ── PR-4: parse_mode=Markdown entity 파싱 회피 ───────────────────────────────
# `_` 단독 토큰이 Telegram 400 (can't parse entities) 을 유발한다 → 하이픈 치환.
# 나머지 마크다운 제어문자도 무해한 글자로 바꾼다(escape 보다 오탐이 없다).
md_safe() {
  local s="${1-}" bt sq
  bt='`'; sq="'"
  s="${s//_/-}"; s="${s//\*/•}"; s="${s//$bt/$sq}"
  s="${s//\[/(}"; s="${s//\]/)}"
  printf '%s' "$s"
}

# ── 자격증명 로드 (하드코딩 금지 · 값 미출력) ────────────────────────────────
load_telegram_env() {
  local f
  for f in "${PAB_MONITOR_ENV:-}" "$BASE_DIR/monitor.env" \
           "/home/oceanui/observer/.env" \
           "$BASE_DIR/../.env" "$BASE_DIR/../../.env"; do
    [ -n "$f" ] && [ -f "$f" ] || continue
    set -a; # shellcheck disable=SC1090
    . "$f" >/dev/null 2>&1; set +a
    if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
      TELEGRAM_ENV_SRC="$f"; return 0
    fi
  done
  return 1
}

# report_to_telegram.sh 와 동일한 계약([TAG]\n본문 + parse_mode=Markdown).
# 서버에는 그 스크립트가 요구하는 <repo>/.env 레이아웃이 없어 자격증명을 서버로
# 복제하는 대신 동일 채널로 직접 발신한다(비밀 중복 0). PAB_REPORT_SCRIPT 가
# 지정되면 원본 스크립트를 그대로 재사용한다.
notify() {
  local body; body="$(md_safe "${1-}")"
  if [ "$FALLBACK_ON" -eq 0 ] && [ "$TEST_NOTIFY" -eq 0 ]; then
    log "보조 Telegram 경로 비활성 (UK Push 경로 가동 중) — 발송 생략"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY-RUN 발송 억제. 본문:"; printf '%s\n' "$body"; return 0
  fi
  if [ -n "${PAB_REPORT_SCRIPT:-}" ] && [ -x "${PAB_REPORT_SCRIPT}" ]; then
    "${PAB_REPORT_SCRIPT}" "$PROJECT_TAG" "$body" >/dev/null 2>&1 && return 0
    log "WARN report_to_telegram.sh 실패 — 내장 발신으로 폴백"
  fi
  if ! load_telegram_env; then
    log "ERROR Telegram 자격증명 없음 (PAB-MONITOR-ENV/monitor.env/observer/.env 확인)"; return 1
  fi
  local code
  code="$(curl -s -m 20 -o /dev/null -w '%{http_code}' \
    -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=[${PROJECT_TAG}]
${body}" \
    --data-urlencode "parse_mode=Markdown")"
  if [ "$code" = "200" ]; then log "notify sent (HTTP 200)"; return 0; fi
  log "ERROR Telegram 발송 실패 HTTP ${code}"; return 1
}

# ── 상태파일 I/O (값은 %q 로 quote — 공백 파싱 붕괴 방지) ────────────────────
st_get() {
  local k="$1" v
  [ -f "$STATE_FILE" ] || { printf '%s' "${2-}"; return 0; }
  v="$(grep -m1 "^${k}=" "$STATE_FILE" 2>/dev/null | cut -d= -f2-)"
  [ -n "$v" ] || { printf '%s' "${2-}"; return 0; }
  v="${v%\'}"; v="${v#\'}"
  printf '%s' "$v"
}
NEW_STATE=""
st_set() { NEW_STATE="${NEW_STATE}${1}=$(printf '%q' "${2-}")"$'\n'; }
st_flush() {
  [ "$DRY_RUN" -eq 1 ] && return 0
  printf '%s' "$NEW_STATE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
  chmod 600 "$STATE_FILE" 2>/dev/null || true
}
key_var() { printf '%s' "${1//-/_}"; }

# ── 개별 점검 ────────────────────────────────────────────────────────────────
# 각 check_* 는 전역 DETAIL 에 사람이 읽을 사유를 넣고 0(OK)/1(FAIL) 반환.
DETAIL=""

inspect_field() { docker inspect -f "$2" "$1" 2>/dev/null; }

check_container_common() {   # $1=name $2=require_port(0|1)
  local name="$1" want_port="$2" info running nets rc prev delta ports hostport
  if ! info="$(inspect_field "$name" '{{.State.Running}} {{.RestartCount}} {{.State.Status}} {{len .NetworkSettings.Networks}}')"; then
    DETAIL="컨테이너 없음 (docker inspect 실패)"; return 1
  fi
  running="$(echo "$info" | awk '{print $1}')"
  rc="$(echo "$info" | awk '{print $2}')"
  local status; status="$(echo "$info" | awk '{print $3}')"
  nets="$(echo "$info" | awk '{print $4}')"

  prev="$(st_get "RC_$(key_var "$name")" "")"
  st_set "RC_$(key_var "$name")" "$rc"
  if [ -n "$prev" ] && [ "$rc" -gt 0 ] 2>/dev/null; then
    delta=$(( rc - prev ))
    if [ "$delta" -ge "$RESTART_STORM_DELTA" ]; then
      DETAIL="재시작 폭주 (RestartCount +${delta}/주기, status=${status})"; return 1
    fi
  fi
  if [ "$running" != "true" ]; then
    DETAIL="미기동 (status=${status}, RestartCount=${rc})"; return 1
  fi
  # §1.3 위양성 검출 — running/healthy 여도 네트워크 엔드포인트가 비어 있을 수 있다.
  if [ "${nets:-0}" -eq 0 ] 2>/dev/null; then
    DETAIL="네트워크 엔드포인트 소실 (Networks 비어 있음 — 통신 불가. force-recreate 필요)"
    return 1
  fi
  if [ "$want_port" -eq 1 ]; then
    ports="$(inspect_field "$name" '{{json .NetworkSettings.Ports}}')"
    hostport="$(printf '%s' "$ports" | jq -r --arg p "${COUCHDB_PORT}/tcp" '.[$p][0].HostPort // empty' 2>/dev/null)"
    if [ -z "$hostport" ]; then
      DETAIL="포트 매핑 공란 (${COUCHDB_PORT}/tcp 미바인딩 — force-recreate 필요)"; return 1
    fi
  fi
  DETAIL="running, Networks=${nets}, RestartCount=${rc}"
  return 0
}

check_couchdb_container() { check_container_common "$COUCHDB_CONTAINER" 1; }
check_bridge_container()  { check_container_common "$BRIDGE_CONTAINER" 0; }

check_couchdb_endpoint() {
  local url="http://${TAILNET_IP}:${COUCHDB_PORT}/_up" body code
  body="$(curl -s -m "$CURL_TIMEOUT" -w $'\n%{http_code}' "$url" 2>/dev/null)"
  code="$(printf '%s' "$body" | tail -n1)"
  body="$(printf '%s' "$body" | sed '$d')"
  if [ "$code" != "200" ]; then
    DETAIL="HTTP ${code:-000} — Tailnet 엔드포인트 응답 없음 (${TAILNET_IP}:${COUCHDB_PORT})"; return 1
  fi
  if ! printf '%s' "$body" | jq -e '.status == "ok"' >/dev/null 2>&1; then
    DETAIL="HTTP 200 이나 status != ok"; return 1
  fi
  DETAIL="HTTP 200, status=ok"; return 0
}

check_couchdb_db() {
  if [ ! -f "$COUCHDB_ENV_FILE" ]; then
    DETAIL="자격증명 파일 없음 (${COUCHDB_ENV_FILE}) — 점검 불가"; return 1
  fi
  local u p out code docs
  # 서브셸에 가둬 자격증명이 전역/로그로 새지 않게 한다.
  u="$(grep -m1 '^COUCHDB_USER=' "$COUCHDB_ENV_FILE" | cut -d= -f2-)"
  p="$(grep -m1 '^COUCHDB_PASSWORD=' "$COUCHDB_ENV_FILE" | cut -d= -f2-)"
  if [ -z "$u" ] || [ -z "$p" ]; then DETAIL="자격증명 키 누락"; return 1; fi
  out="$(curl -s -m "$CURL_TIMEOUT" -w $'\n%{http_code}' -u "${u}:${p}" \
        "http://${TAILNET_IP}:${COUCHDB_PORT}/${DB_NAME}" 2>/dev/null)"
  unset u p
  code="$(printf '%s' "$out" | tail -n1)"
  if [ "$code" != "200" ]; then DETAIL="DB ${DB_NAME} HTTP ${code:-000}"; return 1; fi
  docs="$(printf '%s' "$out" | sed '$d' | jq -r '.doc_count // 0' 2>/dev/null)"
  if [ "${docs:-0}" -le 0 ] 2>/dev/null; then DETAIL="DB ${DB_NAME} doc-count=0 (데이터 소실 의심)"; return 1; fi
  DETAIL="DB ${DB_NAME} doc-count=${docs}"; return 0
}

iso_to_epoch() {
  date -u -d "${1}" +%s 2>/dev/null || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "${1}" +%s 2>/dev/null || printf ''
}

# origin/main tip 을 본다 — 로컬 저장소가 아니라 **GitHub 에 실제로 올라간 것**이
# 오프사이트 백업이기 때문이다. 맥북이 꺼져 있어도(=DP-2-5-2 잔여 위험) 이 검사가
# 서버에서 독립적으로 공백을 잡는다. API(공개 repo, 커밋시각 정확) → 실패 시
# ls-remote SHA 최초관측시각 휴리스틱으로 폴백. 호출은 시간당 1회로 스로틀.
check_github_backup() {
  local last_ck sha prev_sha first_seen commit_ts age_h
  if [ "$CHECK_GIT_ENABLED" != "1" ]; then DETAIL="비활성화됨"; return 0; fi
  last_ck="$(st_get GIT_LAST_CHECK_TS 0)"
  prev_sha="$(st_get GIT_TIP_SHA "")"
  first_seen="$(st_get GIT_TIP_FIRST_SEEN "$ts_now")"
  commit_ts="$(st_get GIT_COMMIT_TS "")"

  if [ $(( ts_now - last_ck )) -ge "$GIT_CHECK_INTERVAL_SEC" ] || [ -z "$prev_sha" ]; then
    local api_sha api_date
    api_sha=""; api_date=""
    local api_out
    api_out="$(curl -s -m "$CURL_TIMEOUT" "$GIT_API" 2>/dev/null)"
    api_sha="$(printf '%s' "$api_out" | jq -r '.sha // empty' 2>/dev/null)"
    api_date="$(printf '%s' "$api_out" | jq -r '.commit.committer.date // empty' 2>/dev/null)"
    if [ -n "$api_sha" ]; then
      sha="$api_sha"
      [ -n "$api_date" ] && commit_ts="$(iso_to_epoch "$api_date")"
    else
      sha="$(GIT_TERMINAL_PROMPT=0 timeout 25 git ls-remote "$GIT_REMOTE" refs/heads/main 2>/dev/null | awk '{print $1}')"
    fi
    if [ -z "$sha" ]; then
      st_set GIT_LAST_CHECK_TS "$last_ck"; st_set GIT_TIP_SHA "$prev_sha"
      st_set GIT_TIP_FIRST_SEEN "$first_seen"; st_set GIT_COMMIT_TS "$commit_ts"
      local prev_res; prev_res="$(st_get GIT_LAST_RESULT 0)"
      st_set GIT_LAST_RESULT "$prev_res"
      DETAIL="원격 조회 실패 (네트워크) — 직전 결과 유지"
      return "$prev_res"
    fi
    if [ "$sha" != "$prev_sha" ]; then first_seen="$ts_now"; fi
    last_ck="$ts_now"
  else
    sha="$prev_sha"
  fi

  [ -n "$commit_ts" ] || commit_ts="$first_seen"
  age_h=$(( (ts_now - commit_ts) / 3600 ))
  st_set GIT_LAST_CHECK_TS "$last_ck"; st_set GIT_TIP_SHA "$sha"
  st_set GIT_TIP_FIRST_SEEN "$first_seen"; st_set GIT_COMMIT_TS "$commit_ts"
  if [ "$age_h" -gt "$GIT_MAX_AGE_HOURS" ]; then
    DETAIL="GitHub 백업 정체 ${age_h}시간 (tip ${sha:0:7}, 임계 ${GIT_MAX_AGE_HOURS}h)"
    st_set GIT_LAST_RESULT 1; return 1
  fi
  DETAIL="tip ${sha:0:7}, 경과 ${age_h}시간"
  st_set GIT_LAST_RESULT 0; return 0
}

# 백업은 죽어도 아무 일이 안 일어난다 — "있는 줄 알았는데 없는" 08-21 실패 모드 그대로다.
# auto 는 **cron 등록 뒤에만** 감시한다: 미리 켜면 36h 뒤 위양성이고, 별도 플래그로 켜게
# 하면 "등록했는데 감시는 안 켠" 어긋남이 난다 — 마커를 직접 봐 둘을 한 몸으로 묶는다.
vb_get() { local v; v="$(grep -m1 "^${1}=" "$VOLBACKUP_STATE" 2>/dev/null | cut -d= -f2-)"
  v="${v%\'}"; v="${v#\'}"; printf '%s' "$v"; }
vb_num() { case "${1-}" in ''|*[!0-9]*) printf 0 ;; *) printf '%s' "$1" ;; esac; }
check_couchdb_volbackup() {
  local en="$CHECK_VOLBACKUP_ENABLED" ok_ts vf_ts gens sz age_h vage_d
  if [ "$en" = "auto" ]; then
    crontab -l 2>/dev/null | grep -q 'PAB-COUCHDB-VOLBACKUP' && en=1 || en=0
  fi
  [ "$en" = "1" ] || { DETAIL="cron 미등록 — 감시 대기(위양성 방지)"; return 0; }
  [ -f "$VOLBACKUP_STATE" ] || { DETAIL="상태파일 없음 — 백업이 한 번도 돌지 않았다"; return 1; }
  ok_ts="$(vb_num "$(vb_get LAST_OK_TS)")"; vf_ts="$(vb_num "$(vb_get LAST_VERIFY_TS)")"
  gens="$(vb_num "$(vb_get GENERATIONS)")"; sz="$(vb_num "$(vb_get TOTAL_SIZE)")"
  age_h=$(( (ts_now - ok_ts) / 3600 )); vage_d=$(( (ts_now - vf_ts) / 86400 ))
  if [ "$ok_ts" -eq 0 ] || [ "$age_h" -gt "$VOLBACKUP_MAX_AGE_H" ]; then
    DETAIL="볼륨 백업 정체 ${age_h}시간 (임계 ${VOLBACKUP_MAX_AGE_H}h, 세대 ${gens})"; return 1
  fi
  # 백업만 돌고 리허설이 멈춤 = "복구 보증 만료된 채 백업만 쌓임". 가장 위험한 조합.
  if [ "$vf_ts" -eq 0 ] || [ "$vage_d" -gt "$VOLBACKUP_VERIFY_MAX_AGE_D" ]; then
    DETAIL="복원 리허설 ${vage_d}일 경과 (임계 ${VOLBACKUP_VERIFY_MAX_AGE_D}일) — 복구 보증 만료"; return 1
  fi
  DETAIL="경과 ${age_h}h, 세대 ${gens}/${VOLBACKUP_KEEP}, 총 ${sz}B, 리허설 ${vage_d}일 전"
  # 세대 미달은 알림이 아니다 — 초기 7일간은 정상적으로 모자란다(정보 표시).
  [ "$gens" -lt "$VOLBACKUP_KEEP" ] && DETAIL="${DETAIL} [세대 축적 중]"
  return 0
}

run_check() {   # $1=key → echo "0|1<TAB>detail"
  DETAIL=""
  case "$1" in
    couchdb-container) check_couchdb_container ;;
    couchdb-endpoint)  check_couchdb_endpoint ;;
    couchdb-db)        check_couchdb_db ;;
    bridge-container)  check_bridge_container ;;
    github-backup)     check_github_backup ;;
    couchdb-volbackup) check_couchdb_volbackup ;;
    *) DETAIL="unknown check"; false ;;
  esac
}

# ── --status ────────────────────────────────────────────────────────────────
if [ "$SHOW_STATUS" -eq 1 ]; then
  echo "== state: $STATE_FILE"; [ -f "$STATE_FILE" ] && grep -v -i 'token\|password' "$STATE_FILE" || echo "(없음)"
  echo "== heartbeat: $HEARTBEAT_FILE"; [ -f "$HEARTBEAT_FILE" ] && cat "$HEARTBEAT_FILE" || echo "(없음)"
  exit 0
fi

# ── --test-notify (G2-infra 전달경로 확인용) ─────────────────────────────────
if [ "$TEST_NOTIFY" -eq 1 ]; then
  notify "🔔 헬스 모니터 전달 경로 테스트
서버: 3800X / 시각: ${iso_now}
이 메시지는 장애가 아니라 Telegram 도달 확인용입니다."
  exit $?
fi

# ── 동시 실행 방지 ───────────────────────────────────────────────────────────
if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then log "이전 실행 진행 중 — skip"; exit 0; fi
else
  log "WARN flock 없음 (개발기 드라이런 등) — 중복실행 방지 생략"
fi

# ── 로그 비대 방지 ───────────────────────────────────────────────────────────
LOG_SELF="${PAB_MONITOR_LOG:-/tmp/pab-sync-health.log}"
if [ -f "$LOG_SELF" ] && [ "$(wc -c < "$LOG_SELF" 2>/dev/null || echo 0)" -gt 1048576 ]; then
  tail -n 500 "$LOG_SELF" > "$LOG_SELF.tmp" && mv "$LOG_SELF.tmp" "$LOG_SELF"
fi

# ── 실행 ────────────────────────────────────────────────────────────────────
# 알림 상태는 **항목별**로 관리한다. 전역 1개로 묶으면, 장기 실패 항목(예: 아직
# 해소 전인 github-backup)이 ALERT 를 계속 점유해 그 뒤에 새로 죽은 컨테이너가
# 알림 없이 묻힌다 — 관측 부재보다 나쁜 "알림이 있는 줄 아는" 상태가 된다.
NEW_LINES=""; STILL_LINES=""; RECOVERED=""; OK_LIST=""; FAILING=""
any_alerted=0; any_fail=0

for k in $CHECK_KEYS; do
  kv="$(key_var "$k")"
  was_alerted="$(st_get "ALERTED_${kv}" 0)"
  if run_check "$k"; then
    st_set "FAIL_${kv}" 0
    st_set "ALERTED_${kv}" 0
    OK_LIST="${OK_LIST}${k} "
    log "OK   ${k} — ${DETAIL}"
    if [ "$was_alerted" = "1" ]; then
      since="$(st_get "SINCE_${kv}" "$ts_now")"
      RECOVERED="${RECOVERED} - ${k}: 약 $(( (ts_now - since) / 60 ))분 만에 정상화"$'\n'
    fi
    st_set "SINCE_${kv}" 0
  else
    any_fail=1
    n="$(st_get "FAIL_${kv}" 0)"; n=$(( n + 1 ))
    st_set "FAIL_${kv}" "$n"
    log "FAIL ${k} (${n}/${FAIL_THRESHOLD}) — ${DETAIL}"
    if [ "$n" -ge "$FAIL_THRESHOLD" ]; then
      any_alerted=1
      FAILING="${FAILING}${k},"
      st_set "ALERTED_${kv}" 1
      if [ "$was_alerted" = "1" ]; then
        st_set "SINCE_${kv}" "$(st_get "SINCE_${kv}" "$ts_now")"
        STILL_LINES="${STILL_LINES} - ${k}: ${DETAIL}"$'\n'
      else
        st_set "SINCE_${kv}" "$ts_now"
        NEW_LINES="${NEW_LINES} - ${k}: ${DETAIL}"$'\n'
      fi
    else
      st_set "ALERTED_${kv}" 0
      st_set "SINCE_${kv}" 0
    fi
  fi
done
FAILING="${FAILING%,}"

last_alert="$(st_get LAST_ALERT_TS 0)"
sent=0

if [ -n "$NEW_LINES" ]; then
  msg="🚨 LiveSync 인프라 이상 감지
서버: 3800X (${TAILNET_IP})
감지: ${iso_now} — 연속 ${FAIL_THRESHOLD}회 실패 (점검주기 5분)
새로 발생:
${NEW_LINES}"
  [ -n "$STILL_LINES" ] && msg="${msg}지속 중:
${STILL_LINES}"
  msg="${msg}대응: ssh 3800x → cd /home/oceanui/pab-vault-cloud
      docker compose up -d --force-recreate   (엔드포인트 소실 대비 force 필수)"
  notify "$msg"; sent=1
elif [ "$any_alerted" -eq 1 ] && [ $(( ts_now - last_alert )) -ge "$REMIND_SEC" ]; then
  notify "⏰ LiveSync 인프라 이상 지속
확인: ${iso_now}
${STILL_LINES}"
  sent=1
fi

if [ -n "$RECOVERED" ]; then
  notify "✅ LiveSync 인프라 복구
서버: 3800X (${TAILNET_IP})
복구: ${iso_now}
${RECOVERED}정상 항목: ${OK_LIST}"
fi

if [ "$sent" -eq 1 ]; then st_set LAST_ALERT_TS "$ts_now"; else st_set LAST_ALERT_TS "$last_alert"; fi
st_set LAST_RUN_TS "$ts_now"
st_flush

HB_STATUS=OK; [ "$any_fail" -eq 1 ] && HB_STATUS=FAIL
if [ "$DRY_RUN" -eq 0 ]; then
  {
    echo "TS=${ts_now}"
    echo "ISO=${iso_now}"
    echo "STATUS=${HB_STATUS}"
    echo "FAILING=${FAILING}"
  } > "$HEARTBEAT_FILE.tmp" && mv "$HEARTBEAT_FILE.tmp" "$HEARTBEAT_FILE"
fi

[ "$HB_STATUS" = "OK" ] && exit 0 || exit 1
