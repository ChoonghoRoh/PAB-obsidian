#!/usr/bin/env bash
#
# deploy_monitoring.sh — 관측 계층 배포 + cron 등록 (멱등)
# Phase 2-5 / Task 2-5-1 — backend-dev
# ─────────────────────────────────────────────────────────────────────────────
# 배포 대상 3종:
#
#   [1] pab-vault-sync-collect.sh  → 3800X /home/oceanui/observer/scripts/  (*/5)
#       **1차 경로**. Observer/UK Push heartbeat. 정상 시 무소음이고, 수집기가
#       아예 죽으면 heartbeat 유실로 UK 가 알린다(감시자의 죽음까지 덮인다).
#       observer-integration-prompt.md §3.1 계약 준수. 기존 observer 스크립트는
#       건드리지 않고 신규 파일만 추가한다.
#
#   [2] pab_sync_healthcheck.sh    → 3800X /home/oceanui/pab-vault-monitor/ (2-57/5)
#       **보조 Telegram 경로**. UK_PAB_VAULT_PUSH_URL 미발급 구간의 공백을 메우고,
#       UK 계약 밖 항목(인증 DB 점검·bridge)과 맥북 watchdog 용 heartbeat 를 담당.
#       URL 이 발급되면 Telegram 발송은 자동으로 멈춘다. 1차와 2분 어긋나게 돌려
#       같은 순간에 몰리지 않게 한다.
#
#   [3] pab_sync_watchdog_local.sh → 맥북 crontab (주 1회 월 09:00)
#       서버·UK 가 동시에 침묵하는 경우를 클라이언트 관점에서 확인.
#
#   [4] pab_git_stamp_local.sh      → 맥북 crontab (매시 정각)
#       git-gap 실패 **원인 구분**용 데이터 피드(맥북 침묵 / 미푸시 / 진짜 공백).
#       판정 자체는 서버가 GitHub tip 으로 독립 수행하므로 이 stamp 에 의존하지 않는다.
#
#   [6] pab_couchdb_volume_backup.sh → 3800X /home/oceanui/pab-vault-monitor/   ← Task 2-5-3
#       CouchDB 볼륨 물리 덤프(일 1회 04:17 · 7세대) + **복원 리허설**(일요일 04:42).
#       Observer #32(논리 백업, 03:17)와 1시간 분리한다 — 같은 CouchDB 를 동시에
#       읽지 않게 하고, 장애 시 로그 시각만으로 어느 쪽인지 갈린다. **이 간격을
#       바꾸지 말 것**(Observer OB2-C §8.4 로 정식 수용된 값이다).
#       2줄째(리허설)를 cron 에 넣는 이유: "백업했다"가 아니라 "복구된다"를 계속
#       증명해야 하기 때문이다. 한 번 성공한 복원은 다음 주의 보증이 아니다.
#
#   [5] pab_git_autocommit_local.sh → 맥북 crontab (2시간마다 :17)  ← Task 2-5-2
#       오프사이트 백업(GitHub)의 **커밋·푸시 자동화**. [4]가 공백을 *관측*한다면
#       이것은 공백을 *만들지 않는다*. 커밋·푸시만 하고 병합은 절대 하지 않는다(PR-3).
#       :17 오프셋은 [4](매시 :00)와 같은 저장소를 동시에 건드리지 않게 하려는 것 —
#       .git/index.lock 경합을 피하고, stamp 가 커밋 **이후** 상태를 보고하게 만든다.
#
# [중요] [2]의 배포 위치를 /home/oceanui/pab-vault-cloud/ **밖**에 둔다.
#   pab-vault-cloud/deploy.sh 는 `rsync --delete` 로 그 디렉토리를 통째로 맞추므로,
#   아래에 감시 스크립트를 두면 다음 배포 때 **조용히 삭제**된다. 감시자가 배포
#   한 번에 사라지는 구조는 그 자체가 08-21 사건의 재현이다.
#
# 주기·임계 근거:
#   5분 — Observer 계약값(§3.1). 기존 수집기 1분(containers)과 10분(vault-chain)
#     사이이며, CouchDB down 은 즉시성이 필요하나 매분은 UK 부하 대비 이득이 적다.
#   보조 경로 연속 3회 — 5분×3 = 최소 10분 연속 실패라야 발송.
#     · 하한: compose healthcheck 최악 복구(start-period 20s + 15s×5)·호스트 재부팅
#       (~3분)·deploy.sh 재빌드보다 길어야 계획된 유지보수로 울리지 않는다.
#     · 상한: 08-21 사건은 3일(4,320분) 무인지였다. 최대 15분이면 288배 개선이고,
#       LiveSync 는 실시간 복제이므로 15분 지연은 데이터 관점에서 무해하다.
#   맥북 2시간 (:17) — Task 2-5-2. KPI "커밋 공백 <= 24h" 대비 하루 12회로 12배 여유.
#     macOS cron 은 슬립 중 놓친 실행을 보충하지 않으므로, 여유분은 그대로 "맥북이
#     깨어 있는 창을 몇 번 만나는가"의 확률이 된다. 2시간이면 하루 22시간을 자도
#     KPI 를 지킨다. 변경 없으면 no-op 이라 실행 비용은 사실상 0.
#   맥북 주 1회 (월 09:00) — DP-2-5-1 확정값. 1차 감지는 UK·서버 cron 이 맡고,
#     이것은 저확률·고영향(서버+UK 동시 침묵)의 2차 안전망이다.
#
# ⚠️ [6] 등록은 **감시 스위치를 켜는 행위**다:
#   pab_sync_healthcheck.sh 의 check_couchdb_volbackup 은 `PAB_CHECK_VOLBACKUP_ENABLED=auto`
#   기본값에서 **crontab 의 `PAB-COUCHDB-VOLBACKUP` 마커를 직접 grep** 해 감시 여부를
#   정한다(위양성 방지). 즉 cron 을 등록하는 순간 T-1 감시가 함께 켜진다.
#   그런데 상태파일이 낡아 있으면(마지막 백업 > 36h, 마지막 리허설 > 10일) **켜자마자
#   즉시 FAIL** 이 되어 연속 3회(=15분) 뒤 Telegram 이 울린다. 진짜 장애가 아니라
#   "아직 한 번도 안 돌았을 뿐"인데 첫인상이 오탐이 되면 다음 알림의 신뢰가 깎인다.
#   ⇒ 그래서 **등록 전에 프라이밍**한다(백업 1회 + 필요 시 리허설 1회). --no-prime 로 끌 수 있다.
#
# 사용:
#   ./deploy_monitoring.sh                # 전부
#   ./deploy_monitoring.sh --server-only
#   ./deploy_monitoring.sh --local-only
#   ./deploy_monitoring.sh --volbackup-only  # [6]만 — 다른 스크립트·마커 무접촉
#   ./deploy_monitoring.sh --dry-run      # 아무것도 쓰지 않고 crontab before/after diff 만 산출
#   ./deploy_monitoring.sh --no-prime     # 프라이밍(백업·리허설 선행 실행) 생략
#   ./deploy_monitoring.sh --uninstall    # cron 만 제거 (스크립트·상태 보존)
#   (조합 가능: ./deploy_monitoring.sh --volbackup-only --dry-run)
#
# T-3 등록 권장 절차: --volbackup-only --dry-run 으로 diff 확인 → --volbackup-only 로 등록.
#   --server-only 을 쓰면 [1][2] 마커도 재등록되어 **내용은 같고 줄 위치만 바뀐 diff** 가
#   생긴다. 기능상 무해하지만 "기존 엔트리 무변경"을 눈으로 확인하기 어려워진다.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SSH_HOST="${PAB_SSH_HOST:-3800x}"
MONITOR_DIR="${PAB_MONITOR_REMOTE_DIR:-/home/oceanui/pab-vault-monitor}"
OBSERVER_DIR="${PAB_OBSERVER_DIR:-/home/oceanui/observer}"
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

COLLECT_MARK="# PAB-VAULT-SYNC"
SERVER_MARK="# PAB-SYNC-MONITOR"
LOCAL_MARK="# PAB-SYNC-WATCHDOG"
STAMP_MARK="# PAB-GIT-STAMP"
AUTOCOMMIT_MARK="# PAB-GIT-AUTOCOMMIT"

COLLECT_CRON="*/5 * * * * ${OBSERVER_DIR}/scripts/pab-vault-sync-collect.sh >> /tmp/obs-pab-vault-sync.log 2>&1  ${COLLECT_MARK}"
SERVER_CRON="2-57/5 * * * * ${MONITOR_DIR}/pab_sync_healthcheck.sh >> /tmp/pab-sync-health.log 2>&1  ${SERVER_MARK}"
LOCAL_CRON="0 9 * * 1 ${LOCAL_DIR}/pab_sync_watchdog_local.sh >> /tmp/pab-sync-watchdog.log 2>&1  ${LOCAL_MARK}"
STAMP_CRON="0 * * * * ${LOCAL_DIR}/pab_git_stamp_local.sh >> /tmp/pab-git-stamp.log 2>&1  ${STAMP_MARK}"
AUTOCOMMIT_CRON="17 */2 * * * ${LOCAL_DIR}/pab_git_autocommit_local.sh >> /tmp/pab-git-autocommit.log 2>&1  ${AUTOCOMMIT_MARK}"

# [6] Task 2-5-3 — 서버 cron 2줄. Observer OB2-C §8.4 로 정식 수용된 값이다.
#   04:17 : Observer #32(03:17)와 **1시간 분리**. 같은 CouchDB 를 동시에 읽지 않게 하고,
#           장애가 나면 로그 시각만으로 어느 쪽 백업인지 갈린다. **이 간격을 바꾸지 말 것.**
#   04:42 일요일 : 복원 리허설 상설화. 한 번 성공한 복원은 다음 주의 보증이 아니다.
VOLBACKUP_MARK="# PAB-COUCHDB-VOLBACKUP"
VOLVERIFY_MARK="# PAB-COUCHDB-VOLVERIFY"
VOLBACKUP_CRON="17 4 * * * ${MONITOR_DIR}/pab_couchdb_volume_backup.sh >> /tmp/pab-couchdb-volbackup.log 2>&1  ${VOLBACKUP_MARK}"
VOLVERIFY_CRON="42 4 * * 0 ${MONITOR_DIR}/pab_couchdb_volume_backup.sh --verify-restore >> /tmp/pab-couchdb-volbackup.log 2>&1  ${VOLVERIFY_MARK}"

DO_SERVER=1; DO_LOCAL=1; UNINSTALL=0; DRY=0; PRIME=1; VOLBACKUP_ONLY=0
USAGE="usage: $0 [--server-only|--local-only|--volbackup-only] [--uninstall] [--dry-run] [--no-prime]"
for arg in "$@"; do
  case "$arg" in
    --server-only) DO_LOCAL=0 ;;
    # [6]만 건드린다: 다른 스크립트 rsync 도, 다른 마커 재등록도 하지 않는다.
    # 마커 재등록은 내용이 같아도 crontab 안에서 줄 위치를 옮긴다 — 기능상 무해하나
    # "기존 엔트리 무변경"을 글자 그대로 지키려면 애초에 건드리지 않는 편이 낫다.
    --volbackup-only) VOLBACKUP_ONLY=1; DO_LOCAL=0 ;;
    --local-only)  DO_SERVER=0 ;;
    --uninstall)   UNINSTALL=1 ;;
    --dry-run)     DRY=1 ;;
    --no-prime)    PRIME=0 ;;
    -h|--help)     echo "$USAGE"; exit 0 ;;
    *) echo "$USAGE" >&2; exit 64 ;;
  esac
done

# crontab 멱등 갱신: 마커가 붙은 줄만 걷어내고 다시 넣는다(다른 항목은 보존).
set_local_cron() {   # $1=marker $2=line("" 면 제거만)
  local mark="$1" line="${2:-}" tmp
  [ "$DRY" -eq 1 ] && { echo "      [dry-run] 맥북 crontab 쓰기 생략: $mark"; return 0; }
  tmp="$(mktemp)"
  crontab -l 2>/dev/null | grep -vF -- "$mark" > "$tmp" || true
  [ -n "$line" ] && printf '%s\n' "$line" >> "$tmp"
  crontab "$tmp"
  rm -f "$tmp"
}
set_remote_cron() {  # $1=marker $2=line("" 면 제거만)
  # 이중 안전장치: --dry-run 이 어떤 경로로든 여기 닿으면 쓰지 않는다.
  [ "$DRY" -eq 1 ] && { echo "      [dry-run] 서버 crontab 쓰기 생략: $1"; return 0; }
  ssh "$SSH_HOST" "
    set -e
    tmp=\$(mktemp)
    crontab -l 2>/dev/null | grep -vF -- '$1' > \"\$tmp\" || true
    [ -n '$2' ] && printf '%s\n' '$2' >> \"\$tmp\" || true
    crontab \"\$tmp\"
    rm -f \"\$tmp\"
  "
}

# ── --dry-run: 아무것도 쓰지 않고 crontab before/after diff 만 산출 ──────────
# set_remote_cron 과 **같은 변형**(마커 줄 제거 → 재추가)을 로컬에서 재현한다.
# 다른 구현으로 흉내내면 diff 가 실제 등록 결과와 어긋날 수 있으므로 로직을 맞춘다.
plan_cron() {   # $1=before파일 $2=after파일, 이후 marker/line 쌍 나열
  local before="$1" after="$2"; shift 2
  cp "$before" "$after"
  local mark line t
  while [ "$#" -ge 2 ]; do
    mark="$1"; line="$2"; shift 2
    t="$(mktemp)"
    grep -vF -- "$mark" "$after" > "$t" || true
    [ -n "$line" ] && printf '%s\n' "$line" >> "$t"
    mv "$t" "$after"
  done
}

if [ "$DRY" -eq 1 ]; then
  WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
  if [ "$DO_SERVER" -eq 1 ]; then
    echo "==> [dry-run] 서버(${SSH_HOST}) crontab before/after"
    ssh -o ConnectTimeout=10 "$SSH_HOST" 'crontab -l 2>/dev/null' > "$WORK/crontab.before" || true
    if [ "$VOLBACKUP_ONLY" -eq 1 ]; then
      plan_cron "$WORK/crontab.before" "$WORK/crontab.after" \
        "$VOLBACKUP_MARK" "$VOLBACKUP_CRON" \
        "$VOLVERIFY_MARK" "$VOLVERIFY_CRON"
    else
      plan_cron "$WORK/crontab.before" "$WORK/crontab.after" \
        "$COLLECT_MARK"   "$COLLECT_CRON" \
        "$SERVER_MARK"    "$SERVER_CRON" \
        "$VOLBACKUP_MARK" "$VOLBACKUP_CRON" \
        "$VOLVERIFY_MARK" "$VOLVERIFY_CRON"
    fi
    diff -u "$WORK/crontab.before" "$WORK/crontab.after" | sed 's/^/    /' || true
    echo "    (기존 $(wc -l < "$WORK/crontab.before" | tr -d ' ')줄 → $(wc -l < "$WORK/crontab.after" | tr -d ' ')줄)"

    echo "==> [dry-run] 등록 시 T-1 감시가 함께 켜진다 — 상태파일 신선도 확인"
    ssh -o ConnectTimeout=10 "$SSH_HOST" "${MONITOR_DIR}/pab_couchdb_volume_backup.sh --status" 2>&1 | sed 's/^/      /' || true
  fi
  if [ "$DO_LOCAL" -eq 1 ]; then
    echo "==> [dry-run] 맥북 crontab before/after"
    crontab -l 2>/dev/null > "$WORK/local.before" || true
    plan_cron "$WORK/local.before" "$WORK/local.after" \
      "$LOCAL_MARK" "$LOCAL_CRON" "$STAMP_MARK" "$STAMP_CRON" "$AUTOCOMMIT_MARK" "$AUTOCOMMIT_CRON"
    diff -u "$WORK/local.before" "$WORK/local.after" | sed 's/^/    /' || true
  fi
  echo "==> [dry-run] 종료 — 원격·로컬 어디에도 쓰지 않았다."
  exit 0
fi

if [ "$UNINSTALL" -eq 1 ]; then
  echo "==> 서버 cron 제거 (수집기 + 보조 + 볼륨백업 2줄)"
  set_remote_cron "$COLLECT_MARK" ""
  set_remote_cron "$SERVER_MARK" ""
  set_remote_cron "$VOLBACKUP_MARK" ""
  set_remote_cron "$VOLVERIFY_MARK" ""
  echo "==> 맥북 cron 제거"
  set_local_cron "$LOCAL_MARK" ""
  set_local_cron "$STAMP_MARK" ""
  set_local_cron "$AUTOCOMMIT_MARK" ""
  echo "완료. 스크립트·상태파일은 남겨둔다."
  exit 0
fi

if [ "$DO_SERVER" -eq 1 ]; then
  if [ "$VOLBACKUP_ONLY" -eq 0 ]; then
  echo "==> [1/8] Observer 수집기 배포 (1차 경로)"
  ssh "$SSH_HOST" "mkdir -p '${OBSERVER_DIR}/scripts' '${OBSERVER_DIR}/state'"
  # macOS 기본 rsync(openrsync)는 --chmod 미지원 → 전송 후 원격에서 실행권한 부여
  rsync -a "${LOCAL_DIR}/pab-vault-sync-collect.sh" "${SSH_HOST}:${OBSERVER_DIR}/scripts/"
  ssh "$SSH_HOST" "chmod 755 '${OBSERVER_DIR}/scripts/pab-vault-sync-collect.sh'"
  set_remote_cron "$COLLECT_MARK" "$COLLECT_CRON"

  echo "==> [2/8] 보조 Telegram 헬스체크 배포"
  ssh "$SSH_HOST" "mkdir -p '${MONITOR_DIR}/state' && chmod 700 '${MONITOR_DIR}/state'"
  rsync -a "${LOCAL_DIR}/pab_sync_healthcheck.sh" "${SSH_HOST}:${MONITOR_DIR}/"
  ssh "$SSH_HOST" "chmod 755 '${MONITOR_DIR}/pab_sync_healthcheck.sh'"
  set_remote_cron "$SERVER_MARK" "$SERVER_CRON"
  fi

  echo "==> [3/8] CouchDB 볼륨 백업 스크립트 배포 (Task 2-5-3)"
  # pab-vault-cloud/ **밖**이라 deploy.sh 의 rsync --delete 사정권이 아니다.
  rsync -a "${LOCAL_DIR}/pab_couchdb_volume_backup.sh" "${SSH_HOST}:${MONITOR_DIR}/"
  ssh "$SSH_HOST" "chmod 755 '${MONITOR_DIR}/pab_couchdb_volume_backup.sh'"

  echo "==> [4/8] 프라이밍 — 등록 전에 상태파일을 신선하게 만든다"
  # cron 을 먼저 걸면 T-1 감시가 즉시 켜지는데, 상태파일이 낡아 있으면 "아직 안 돌았을
  # 뿐"인 것이 장애로 보고된다. 오탐을 첫인상으로 주면 다음 알림의 신뢰가 깎인다.
  # 순서가 곧 안전장치다 — 프라이밍 → 등록.
  if [ "$PRIME" -eq 1 ]; then
    echo "      백업 1회 (수 초)"
    ssh "$SSH_HOST" "${MONITOR_DIR}/pab_couchdb_volume_backup.sh" 2>&1 | sed 's/^/        /'
    echo "      복원 리허설 1회 (임시 컨테이너 기동 — 수 분 소요)"
    ssh "$SSH_HOST" "${MONITOR_DIR}/pab_couchdb_volume_backup.sh --verify-restore" 2>&1 | sed 's/^/        /'
  else
    echo "      --no-prime 지정 — 생략. ⚠️ 상태파일이 낡았으면 등록 직후 T-1 이 FAIL 을 낸다."
  fi

  echo "==> [5/8] 서버 cron 등록 — 볼륨 백업 04:17 + 복원 리허설 일 04:42"
  # 쓰기 직전 crontab 원본을 파일로 남긴다. 롤백은 이 파일 하나로 끝난다
  # (`crontab <백업파일>`). 마커 제거(--uninstall)보다 확실한 이유는, 등록 이전
  # 상태를 **그대로** 되돌리기 때문이다 — 마커 방식은 우리 줄만 지울 뿐이다.
  CRON_BAK="${MONITOR_DIR}/state/crontab.bak-$(date +%Y%m%d-%H%M%S)"
  ssh "$SSH_HOST" "crontab -l > '${CRON_BAK}' 2>/dev/null || true; chmod 600 '${CRON_BAK}'; wc -l < '${CRON_BAK}'" \
    | sed "s|^|      백업: ${CRON_BAK} (|; s|$| 줄)|"
  set_remote_cron "$VOLBACKUP_MARK" "$VOLBACKUP_CRON"
  set_remote_cron "$VOLVERIFY_MARK" "$VOLVERIFY_CRON"

  echo "==> [6/8] 서버 crontab 등록 결과"
  ssh "$SSH_HOST" "crontab -l | grep -E 'PAB-VAULT-SYNC|PAB-SYNC-MONITOR|PAB-COUCHDB-VOL' | sed 's/^/      /'"

  if [ "$VOLBACKUP_ONLY" -eq 0 ]; then
  echo "==> [7/8] 수집기 드라이런 (Push 생략)"
  ssh "$SSH_HOST" "${OBSERVER_DIR}/scripts/pab-vault-sync-collect.sh --dry-run" 2>&1 | sed 's/^/      /' || true

  echo "==> [8/8] 보조 헬스체크 드라이런 (알림·상태기록 없음)"
  ssh "$SSH_HOST" "${MONITOR_DIR}/pab_sync_healthcheck.sh --dry-run" 2>&1 | sed 's/^/      /' || true
  fi
fi

if [ "$DO_LOCAL" -eq 1 ]; then
  echo "==> 맥북 crontab 등록 (멱등: watchdog 주1회 + git-stamp 매시 + 자동커밋 2시간)"
  chmod +x "${LOCAL_DIR}/pab_sync_watchdog_local.sh" "${LOCAL_DIR}/pab_git_stamp_local.sh" \
           "${LOCAL_DIR}/pab_git_autocommit_local.sh"
  set_local_cron "$LOCAL_MARK" "$LOCAL_CRON"
  set_local_cron "$STAMP_MARK" "$STAMP_CRON"
  set_local_cron "$AUTOCOMMIT_MARK" "$AUTOCOMMIT_CRON"
  echo "    등록 결과:"
  crontab -l | grep -E 'PAB-SYNC-WATCHDOG|PAB-GIT-STAMP|PAB-GIT-AUTOCOMMIT' | sed 's/^/      /'
  echo "    stamp 초기 1회 기록:"
  "${LOCAL_DIR}/pab_git_stamp_local.sh" | sed 's/^/      /' || true
  # 배포 확인은 **드라이런까지만** 한다. 배포 스크립트가 커밋을 만들어 버리면
  # "무엇을 백업했는지" 결정 주체가 사람에서 배포 도구로 옮겨간다(PR-3 취지 훼손).
  echo "    자동커밋 드라이런 (실제 커밋·푸시 없음):"
  "${LOCAL_DIR}/pab_git_autocommit_local.sh" --dry-run 2>&1 | head -12 | sed 's/^/      /' || true
fi

echo "==> 배포 완료"
echo "    수집기 로그 : ssh ${SSH_HOST} 'tail -f /tmp/obs-pab-vault-sync.log'"
echo "    보조 로그   : ssh ${SSH_HOST} 'tail -f /tmp/pab-sync-health.log'"
echo "    상태 확인   : ssh ${SSH_HOST} '${MONITOR_DIR}/pab_sync_healthcheck.sh --status'"
echo "    전달 확인   : ssh ${SSH_HOST} '${MONITOR_DIR}/pab_sync_healthcheck.sh --test-notify'"
echo "    자동커밋 로그: tail -f /tmp/pab-git-autocommit.log"
echo "    자동커밋 상태: ${LOCAL_DIR}/pab_git_autocommit_local.sh --status"
echo "    볼륨백업 로그: ssh ${SSH_HOST} 'tail -f /tmp/pab-couchdb-volbackup.log'"
echo "    볼륨백업 상태: ssh ${SSH_HOST} '${MONITOR_DIR}/pab_couchdb_volume_backup.sh --status'"
if [ "$DO_SERVER" -eq 1 ] && [ -n "${CRON_BAK:-}" ]; then
  echo "    ⏪ 롤백      : ssh ${SSH_HOST} 'crontab ${CRON_BAK}'   (또는 $0 --uninstall)"
fi
