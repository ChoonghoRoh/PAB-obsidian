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
# 사용:
#   ./deploy_monitoring.sh                # 전부
#   ./deploy_monitoring.sh --server-only
#   ./deploy_monitoring.sh --local-only
#   ./deploy_monitoring.sh --uninstall    # cron 만 제거 (스크립트·상태 보존)
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

DO_SERVER=1; DO_LOCAL=1; UNINSTALL=0
case "${1:-}" in
  --server-only) DO_LOCAL=0 ;;
  --local-only)  DO_SERVER=0 ;;
  --uninstall)   UNINSTALL=1 ;;
  "") ;;
  *) echo "usage: $0 [--server-only|--local-only|--uninstall]" >&2; exit 64 ;;
esac

# crontab 멱등 갱신: 마커가 붙은 줄만 걷어내고 다시 넣는다(다른 항목은 보존).
set_local_cron() {   # $1=marker $2=line("" 면 제거만)
  local mark="$1" line="${2:-}" tmp
  tmp="$(mktemp)"
  crontab -l 2>/dev/null | grep -vF -- "$mark" > "$tmp" || true
  [ -n "$line" ] && printf '%s\n' "$line" >> "$tmp"
  crontab "$tmp"
  rm -f "$tmp"
}
set_remote_cron() {  # $1=marker $2=line("" 면 제거만)
  ssh "$SSH_HOST" "
    set -e
    tmp=\$(mktemp)
    crontab -l 2>/dev/null | grep -vF -- '$1' > \"\$tmp\" || true
    [ -n '$2' ] && printf '%s\n' '$2' >> \"\$tmp\" || true
    crontab \"\$tmp\"
    rm -f \"\$tmp\"
  "
}

if [ "$UNINSTALL" -eq 1 ]; then
  echo "==> 서버 cron 제거 (수집기 + 보조)"
  set_remote_cron "$COLLECT_MARK" ""
  set_remote_cron "$SERVER_MARK" ""
  echo "==> 맥북 cron 제거"
  set_local_cron "$LOCAL_MARK" ""
  set_local_cron "$STAMP_MARK" ""
  set_local_cron "$AUTOCOMMIT_MARK" ""
  echo "완료. 스크립트·상태파일은 남겨둔다."
  exit 0
fi

if [ "$DO_SERVER" -eq 1 ]; then
  echo "==> [1/5] Observer 수집기 배포 (1차 경로)"
  ssh "$SSH_HOST" "mkdir -p '${OBSERVER_DIR}/scripts' '${OBSERVER_DIR}/state'"
  # macOS 기본 rsync(openrsync)는 --chmod 미지원 → 전송 후 원격에서 실행권한 부여
  rsync -a "${LOCAL_DIR}/pab-vault-sync-collect.sh" "${SSH_HOST}:${OBSERVER_DIR}/scripts/"
  ssh "$SSH_HOST" "chmod 755 '${OBSERVER_DIR}/scripts/pab-vault-sync-collect.sh'"
  set_remote_cron "$COLLECT_MARK" "$COLLECT_CRON"

  echo "==> [2/5] 보조 Telegram 헬스체크 배포"
  ssh "$SSH_HOST" "mkdir -p '${MONITOR_DIR}/state' && chmod 700 '${MONITOR_DIR}/state'"
  rsync -a "${LOCAL_DIR}/pab_sync_healthcheck.sh" "${SSH_HOST}:${MONITOR_DIR}/"
  ssh "$SSH_HOST" "chmod 755 '${MONITOR_DIR}/pab_sync_healthcheck.sh'"
  set_remote_cron "$SERVER_MARK" "$SERVER_CRON"

  echo "==> [3/5] 서버 crontab 등록 결과"
  ssh "$SSH_HOST" "crontab -l | grep -E 'PAB-VAULT-SYNC|PAB-SYNC-MONITOR' | sed 's/^/      /'"

  echo "==> [4/5] 수집기 드라이런 (Push 생략)"
  ssh "$SSH_HOST" "${OBSERVER_DIR}/scripts/pab-vault-sync-collect.sh --dry-run" 2>&1 | sed 's/^/      /' || true

  echo "==> [5/5] 보조 헬스체크 드라이런 (알림·상태기록 없음)"
  ssh "$SSH_HOST" "${MONITOR_DIR}/pab_sync_healthcheck.sh --dry-run" 2>&1 | sed 's/^/      /' || true
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
