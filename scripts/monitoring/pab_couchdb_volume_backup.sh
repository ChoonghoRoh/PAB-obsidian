#!/usr/bin/env bash
#
# pab_couchdb_volume_backup.sh — CouchDB named volume 덤프 + 7세대 보존
# Phase 2-5 / Task 2-5-3 (G-3) — backend-dev
# ─────────────────────────────────────────────────────────────────────────────
# 왜 별도로 필요한가 (기존 backup-datastores.sh 와 중복이 아니다):
#   Observer 의 backup-datastores.sh 는 이미 CouchDB 를 매일 03:17 에 받는다.
#   그러나 그것은 `_all_docs?include_docs=true` — **논리(문서) 덤프**다. 거기엔
#     · 리비전 트리(_revisions)      · `_local/` 복제 체크포인트
#     · 청크 내부 배치·샤드 구조
#   가 들어 있지 않다. LiveSync 는 `_local/` 체크포인트로 "각 기기가 어디까지
#   복제했는지"를 기억한다. 논리 덤프로 복원하면 문서는 살아나도 **그 기억이 사라져
#   전 기기가 full resync 를 하게 되고**, 그 과정에서 충돌·중복이 생긴다.
#   볼륨 덤프는 그 메타데이터까지 통째로 보존해 **사고 시점 그대로** 되돌린다.
#   ⇒ 논리 덤프 = 내용 보험 / 볼륨 덤프 = 동기화 상태 보험. 대체재가 아니라 보완재다.
#   (Task 2-5-3 §G-2와의 구분과 동일한 구분선이다)
#
# 왜 컨테이너를 세우지 않아도 되는가:
#   CouchDB 파일은 **append-only** 다. 쓰기 도중 복사되면 꼬리만 잘릴 뿐이고,
#   열 때 마지막 유효 헤더까지 되감아 연다. 그래서 무정지 복사본은 "조금 과거의,
#   그러나 일관된" 스냅샷이 된다. 정지 없이 뜨는 근거가 이것이다.
#   ⚠️ 다만 그 논리가 **이 볼륨에서 실제로 성립하는지는 복원해 봐야 안다** —
#      그래서 `--verify-restore` 가 이 스크립트의 핵심 산출물이다.
#      검증되지 않은 백업은 백업이 아니다.
#
# [중요] 저장 뿌리를 Observer 와 **분리**한다:
#   backup-datastores.sh 는 `/home/oceanui/backups` 안에서 `20*-*` 패턴 디렉토리를
#   `rm -rf` 로 회전시킨다. 같은 뿌리에 세대를 쌓으면 **서로의 백업을 지운다**.
#   그래서 BACKUP_ROOT 를 독립 경로로 둔다. 또한 배포 위치를
#   `/home/oceanui/pab-vault-cloud/` **밖**에 둔다 — 그 디렉토리는 deploy.sh 가
#   `rsync --delete` 로 통째로 맞추므로 안에 두면 다음 배포 때 조용히 사라진다.
#
# 무소음 원칙: 정상이면 로그만 남기고 알림 없음. 실패 시에만 발송(상태 전이 1회).
#   장기 방치는 상태파일을 T-1 헬스체크가 읽어 별도로 잡는다(감시자 독립).
#
# cron (서버, 매일 03:47 — Observer 백업 03:17 과 30분 어긋나게):
#   47 3 * * * /home/oceanui/pab-vault-monitor/pab_couchdb_volume_backup.sh >> /tmp/pab-couchdb-volbackup.log 2>&1  # PAB-COUCHDB-VOLBACKUP
#
# 사용: pab_couchdb_volume_backup.sh [--dry-run|--verify-restore|--status|--help]
#   --dry-run        : 실제 덤프·회전·상태기록 없이 판정만
#   --verify-restore : **복원 리허설**. 최신 덤프를 격리된 임시 컨테이너/볼륨에
#                      복원해 doc_count 를 대조한다. 가동 중인 pab-couchdb 는
#                      건드리지 않는다(이름·볼륨·포트 전부 분리, 127.0.0.1 바인딩).
#
# 의존: docker, tar(alpine 이미지), curl, python3
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH

VOLUME="${PAB_COUCHDB_VOLUME:-pab_couchdb_data}"
BACKUP_ROOT="${PAB_VOLBACKUP_ROOT:-/home/oceanui/pab-vault-backups/couchdb-volume}"
KEEP="${PAB_VOLBACKUP_KEEP:-7}"                   # DP-2-5-3: 일 1회 × 7세대
MIN_SIZE="${PAB_VOLBACKUP_MIN_SIZE:-51200}"       # 50KB 미만이면 덤프 실패로 본다
MONITOR_DIR="${PAB_MONITOR_DIR:-/home/oceanui/pab-vault-monitor}"
STATE_DIR="${PAB_MONITOR_STATE:-$MONITOR_DIR/state}"
STATE_FILE="$STATE_DIR/couchdb-volbackup.env"
LOCK_DIR="$STATE_DIR/.volbackup.lock"
LOCK_STALE="${PAB_LOCK_STALE:-3600}"
HELPER_IMAGE="${PAB_HELPER_IMAGE:-alpine:latest}"
COUCHDB_IMAGE="${PAB_COUCHDB_IMAGE:-couchdb:3}"
LIVE_URL="${PAB_COUCHDB_URL:-http://100.109.251.86:5984}"
NETRC="${PAB_NETRC:-/home/oceanui/observer/.netrc}"
MAIN_DB="${PAB_MAIN_DB:-pab-llmdata}"
PROJECT_TAG="${PAB_PROJECT_TAG:-PAB-v3}"
REPORT_SH="${PAB_REPORT_SCRIPT:-}"
PREFIX="${VOLUME}"

MODE=run
case "${1:-}" in
  --dry-run|--check) MODE=dry ;;
  --verify-restore)  MODE=verify ;;
  --status)          MODE=status ;;
  --help|-h) sed -n '3,58p' "${BASH_SOURCE[0]}"; exit 0 ;;
  "") ;;
  *) echo "usage: $0 [--dry-run|--verify-restore|--status|--help]" >&2; exit 64 ;;
esac

ts_now="$(date +%s)"
iso_now="$(date '+%Y-%m-%d %H:%M:%S %Z')"
log() { printf '%s [couchdb-volbackup] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*"; }

# PR-4: Telegram parse-mode=Markdown 회피
md_safe() {
  local s="${1-}" bt sq; bt='`'; sq="'"
  s="${s//_/-}"; s="${s//\*/•}"; s="${s//$bt/$sq}"; s="${s//\[/(}"; s="${s//\]/)}"
  printf '%s' "$s"
}
notify() {
  local body; body="$(md_safe "${1-}")"
  if [ "$MODE" = dry ]; then log "DRY-RUN 발송 억제. 본문:"; printf '%s\n' "$body"; return 0; fi
  if [ -n "$REPORT_SH" ] && [ -x "$REPORT_SH" ]; then
    "$REPORT_SH" "$PROJECT_TAG" "$body" >/dev/null 2>&1 && { log "notify sent"; return 0; }
  fi
  log "WARN 알림 경로 없음 — 로그로만 남긴다"; return 1
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
  [ "$MODE" = dry ] && return 0
  printf '%s' "$NEW_STATE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
  chmod 644 "$STATE_FILE" 2>/dev/null || true      # T-1 헬스체크가 읽는다
}

mkdir -p "$STATE_DIR" 2>/dev/null || true
PREV_KIND="$(st_get ALERT_KIND '')"

gens_list() { ls -1t "$BACKUP_ROOT"/${PREFIX}-*.tar.gz 2>/dev/null; }

# 백업 실행분과 리허설분은 **서로의 기록을 지우지 않는다**. 상태파일은 T-1 헬스체크가
# 읽는 단일 창구라, 리허설 한 번이 "마지막 백업이 언제 무엇이었는지"를 지워 버리면
# 감시자가 백업 공백을 못 본다. 그래서 자기 담당 키 외에는 전부 이어 쓴다.
carry() { local k; for k in "$@"; do st_set "$k" "$(st_get "$k" '')"; done; }

if [ "$MODE" = status ]; then
  echo "== state: $STATE_FILE"; [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "(없음)"
  echo "== 세대: $BACKUP_ROOT"
  gens_list | while read -r f; do printf '   %s  %s\n' "$(du -h "$f" 2>/dev/null | cut -f1)" "$(basename "$f")"; done
  echo "   총 $(gens_list | wc -l | tr -d ' ')세대 / $(du -sh "$BACKUP_ROOT" 2>/dev/null | cut -f1)"
  exit 0
fi

fail() {                                    # $1=kind $2=사유 $3=대응
  log "FAIL [$1] $2"
  if [ "$PREV_KIND" != "$1" ]; then
    notify "🚨 CouchDB 볼륨 백업 실패 — $1
시각: ${iso_now}
볼륨: ${VOLUME}
사유: $2
${3:-}"
  else log "동일 실패 지속 — 중복 발송 억제"; fi
  st_set ALERT_KIND "$1"; st_set LAST_RUN_TS "$ts_now"
  st_set LAST_OK_TS "$(st_get LAST_OK_TS 0)"; st_set GENERATIONS "$(gens_list | wc -l | tr -d ' ')"
  carry LAST_STATUS LAST_FILE LAST_SIZE TOTAL_SIZE LAST_VERIFY_TS LAST_VERIFY_DOCS LAST_VERIFY_FILE
  st_flush; exit 1
}

command -v docker >/dev/null 2>&1 || fail "docker-missing" "docker 명령을 찾을 수 없다" "대응: PATH 확인"
docker volume inspect "$VOLUME" >/dev/null 2>&1 \
  || fail "volume-missing" "볼륨 ${VOLUME} 이 없다" "대응: docker volume ls 로 확인"

# ── 중복 실행 방지 ───────────────────────────────────────────────────────────
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  lock_ts="$(stat -c %Y "$LOCK_DIR" 2>/dev/null || echo 0)"
  if [ "$(( ts_now - lock_ts ))" -gt "$LOCK_STALE" ]; then
    log "WARN 잔재 락 제거"; rmdir "$LOCK_DIR" 2>/dev/null
    mkdir "$LOCK_DIR" 2>/dev/null || { log "락 획득 실패 — 종료"; exit 0; }
  else log "이전 실행 진행 중 — 종료"; exit 0; fi
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

live_doc_count() {
  curl -fsS --netrc-file "$NETRC" --max-time 15 "${LIVE_URL}/${MAIN_DB}" 2>/dev/null \
    | python3 -c 'import sys,json;print(json.load(sys.stdin).get("doc_count",""))' 2>/dev/null
}

# ═══ 복원 리허설 ═════════════════════════════════════════════════════════════
# 가동 중인 pab-couchdb 는 절대 건드리지 않는다: 이름·볼륨·포트를 전부 분리하고
# 127.0.0.1 에만 바인딩한다(DP-4 — 외부 노출 0). 실패하든 성공하든 반드시 치운다.
if [ "$MODE" = verify ]; then
  LATEST="$(gens_list | head -1)"
  [ -n "$LATEST" ] || fail "no-backup" "복원할 덤프가 없다" "대응: 먼저 백업을 1회 실행하라"
  SUF="verify$$"
  TMP_VOL="pab_couchdb_restoretest_${SUF}"
  TMP_CT="pab-couchdb-restoretest-${SUF}"
  PORT=""
  for p in $(seq 15984 16050); do
    ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":${p}\$" || { PORT="$p"; break; }
  done
  [ -n "$PORT" ] || fail "no-port" "임시 포트를 찾지 못했다" ""
  PW="$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24)"   # 로그 금지

  cleanup_verify() {
    docker rm -f "$TMP_CT" >/dev/null 2>&1
    docker volume rm "$TMP_VOL" >/dev/null 2>&1
    rmdir "$LOCK_DIR" 2>/dev/null || true
  }
  trap cleanup_verify EXIT

  log "복원 리허설 시작: $(basename "$LATEST") → ${TMP_CT} (127.0.0.1:${PORT})"
  docker volume create "$TMP_VOL" >/dev/null 2>&1 \
    || fail "verify-volume" "임시 볼륨 생성 실패" ""
  docker run --rm -v "$TMP_VOL":/dst -v "$(dirname "$LATEST")":/src:ro "$HELPER_IMAGE" \
    tar xzf "/src/$(basename "$LATEST")" -C /dst >/dev/null 2>&1 \
    || fail "verify-extract" "덤프 전개 실패 — 아카이브가 깨졌을 수 있다" "대응: tar tzf 로 직접 확인"

  docker run -d --name "$TMP_CT" \
    -e COUCHDB_USER=verifyadmin -e COUCHDB_PASSWORD="$PW" \
    -v "$TMP_VOL":/opt/couchdb/data \
    -p "127.0.0.1:${PORT}:5984" "$COUCHDB_IMAGE" >/dev/null 2>&1 \
    || fail "verify-run" "임시 컨테이너 기동 실패" ""

  UP=0
  for _ in $(seq 1 60); do
    code="$(curl -s -m 3 -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}/_up" 2>/dev/null)"
    [ "$code" = "200" ] && { UP=1; break; }
    sleep 1
  done
  [ "$UP" -eq 1 ] || fail "verify-noboot" "복원본 CouchDB 가 60초 내에 기동하지 않았다" \
    "대응: docker logs ${TMP_CT}"

  RESTORED="$(curl -fsS -u "verifyadmin:${PW}" --max-time 15 \
    "http://127.0.0.1:${PORT}/${MAIN_DB}" 2>/dev/null \
    | python3 -c 'import sys,json;print(json.load(sys.stdin).get("doc_count",""))' 2>/dev/null)"
  DBS="$(curl -fsS -u "verifyadmin:${PW}" --max-time 15 \
    "http://127.0.0.1:${PORT}/_all_dbs" 2>/dev/null)"
  LIVE="$(live_doc_count)"

  log "복원본 ${MAIN_DB} doc_count=${RESTORED:-?} / 가동본=${LIVE:-?}"
  log "복원본 DB 목록: ${DBS:-?}"
  [ -n "$RESTORED" ] || fail "verify-nodocs" "복원본에서 ${MAIN_DB} 를 읽지 못했다" \
    "대응: 덤프 시점의 append-only tail 손상 가능성 — 다른 세대로 재시도"
  # 가동본은 덤프 이후에도 계속 늘어난다. 복원본이 더 적은 것은 정상,
  # **더 많으면** 무언가 잘못된 것이다(대조 방향을 이렇게 잡는 이유).
  if [ -n "$LIVE" ] && [ "$RESTORED" -gt "$LIVE" ]; then
    fail "verify-mismatch" "복원본 doc_count(${RESTORED}) > 가동본(${LIVE}) — 대조 실패" ""
  fi
  log "✅ 복원 리허설 PASS — 덤프에서 실제로 DB 가 살아난다"
  st_set ALERT_KIND ""; st_set LAST_RUN_TS "$ts_now"
  st_set LAST_OK_TS "$(st_get LAST_OK_TS 0)"
  st_set LAST_VERIFY_TS "$ts_now"; st_set LAST_VERIFY_DOCS "${RESTORED}"
  st_set LAST_VERIFY_FILE "$(basename "$LATEST")"
  st_set GENERATIONS "$(gens_list | wc -l | tr -d ' ')"
  carry LAST_STATUS LAST_FILE LAST_SIZE TOTAL_SIZE
  st_flush
  exit 0
fi

# ═══ 백업 ════════════════════════════════════════════════════════════════════
mkdir -p "$BACKUP_ROOT" 2>/dev/null || fail "mkdir" "백업 디렉토리 생성 실패: $BACKUP_ROOT" ""
chmod 700 "$BACKUP_ROOT" 2>/dev/null || true
STAMP="$(date +%Y%m%d-%H%M%S)"
FINAL="${BACKUP_ROOT}/${PREFIX}-${STAMP}.tar.gz"
TMPF="${BACKUP_ROOT}/.${PREFIX}-${STAMP}.tar.gz.part"

if [ "$MODE" = dry ]; then
  log "DRY-RUN 덤프 억제. 대상 볼륨=${VOLUME} → ${FINAL}"
  log "  현재 세대 $(gens_list | wc -l | tr -d ' ')개 (보존 ${KEEP})"
  gens_list | head -"$KEEP" | while read -r f; do log "    $(du -h "$f" 2>/dev/null | cut -f1) $(basename "$f")"; done
  log "  회전 예정(삭제): $(gens_list | tail -n +"$((KEEP + 1))" | wc -l | tr -d ' ')개"
  exit 0
fi

# 읽기 전용 마운트로 뜬다 — R-1(단일 writer) 위반 여지 자체를 없앤다.
# tar 는 "읽는 중 파일이 변했다"로 1을 반환할 수 있다(append-only 라 정상 상황).
# 그래서 종료코드가 아니라 **아카이브 자체의 무결성**으로 판정한다.
docker run --rm -v "${VOLUME}":/src:ro -v "${BACKUP_ROOT}":/out "$HELPER_IMAGE" \
  tar czf "/out/$(basename "$TMPF")" -C /src . >/dev/null 2>&1
rc=$?
[ -f "$TMPF" ] || fail "dump-missing" "덤프 파일이 생성되지 않았다 (tar rc=${rc})" \
  "대응: docker run 권한·디스크 여유 확인"

SIZE="$(stat -c %s "$TMPF" 2>/dev/null || echo 0)"
[ "$SIZE" -ge "$MIN_SIZE" ] || { rm -f "$TMPF"; fail "dump-too-small" \
  "덤프가 너무 작다(${SIZE}B < ${MIN_SIZE}B) — 빈 아카이브 의심" "대응: 볼륨 내용 확인"; }

# 무결성: 아카이브를 실제로 훑고, CouchDB 핵심 구성요소가 들어 있는지 본다.
LISTING="$(docker run --rm -v "${BACKUP_ROOT}":/out:ro "$HELPER_IMAGE" \
  tar tzf "/out/$(basename "$TMPF")" 2>/dev/null)"
[ -n "$LISTING" ] || { rm -f "$TMPF"; fail "archive-corrupt" "아카이브를 읽을 수 없다" ""; }
for need in "_dbs.couch" "_nodes.couch" "shards/"; do
  printf '%s' "$LISTING" | grep -q -- "$need" \
    || { rm -f "$TMPF"; fail "archive-incomplete" "아카이브에 ${need} 가 없다" \
         "대응: 볼륨 마운트 경로 확인"; }
done
ENTRIES="$(printf '%s' "$LISTING" | grep -c . )"

mv "$TMPF" "$FINAL" || fail "rename" "덤프 확정(rename) 실패" ""
log "덤프 완료: $(basename "$FINAL") (${SIZE}B, ${ENTRIES} entries, tar rc=${rc})"

# ── 세대 회전 ────────────────────────────────────────────────────────────────
# 우리 접두사에 맞는 파일만 건드린다. 다른 백업 체계와 뿌리를 공유하지 않으므로
# 여기서 남의 세대를 지울 여지는 없다.
ROTATED=0
gens_list | tail -n +"$((KEEP + 1))" | while read -r old; do
  rm -f "$old" && log "회전 삭제: $(basename "$old")"
done
ROTATED="$(gens_list | wc -l | tr -d ' ')"
TOTAL="$(du -sb "$BACKUP_ROOT" 2>/dev/null | cut -f1)"

[ -n "$PREV_KIND" ] && notify "✅ CouchDB 볼륨 백업 정상 복귀 (이전 실패: ${PREV_KIND})
시각: ${iso_now} / ${SIZE}B / ${ROTATED}세대"

st_set ALERT_KIND ""; st_set LAST_STATUS "ok"
st_set LAST_OK_TS "$ts_now"; st_set LAST_RUN_TS "$ts_now"
st_set LAST_FILE "$(basename "$FINAL")"; st_set LAST_SIZE "$SIZE"
st_set GENERATIONS "$ROTATED"; st_set TOTAL_SIZE "${TOTAL:-0}"
carry LAST_VERIFY_TS LAST_VERIFY_DOCS LAST_VERIFY_FILE
st_flush
log "OK (세대=${ROTATED}/${KEEP}, 총 ${TOTAL:-0}B)"
exit 0
