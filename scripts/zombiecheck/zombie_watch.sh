#!/usr/bin/env bash
# zombie_watch.sh — LIFECYCLE-6 체크 스케줄러
#
# 규칙: LIFECYCLE-6
#
# 목적: 3분 주기 폴링 루프를 실제로 돌려 zombie_check.sh 판정을 주기적으로 호출한다.
#
# 사용법:
#   zombie_watch.sh --arm <team>            # 폴링 루프 기동 (백그라운드 자기 detach)
#   zombie_watch.sh --stop <team>           # 해제 + 마커 정리
#   zombie_watch.sh --status <team>         # arm 여부 3단 판정 결과 출력
#   zombie_watch.sh --once <team> [agent]   # 1회 체크 (spawn+30초 별도 경로용)
#   zombie_watch.sh --self-test             # 내장 단위 테스트
#   zombie_watch.sh --help
#
# 호출 규약: zombie_check.sh는 subprocess로만 호출한다(source 금지 — readonly 재선언·
#   상수 이름 충돌·set -euo pipefail 전파). 인자 순서는 <agent_name> <team_name> 이다.
#   자체 상수는 _ZW_ 접두사를 쓰고 일반적 이름을 export 하지 않는다.

set -euo pipefail

_ZW_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
_ZW_SCRIPT_DIR="$(dirname "${_ZW_SCRIPT_PATH}")"
_ZW_ZC_SCRIPT="${_ZW_SCRIPT_DIR}/zombie_check.sh"

_ZW_STATE_ROOT="${_ZW_STATE_ROOT_OVERRIDE:-/tmp/zombie-watch-state}"     # self-test/진단 전용 오버라이드
_ZW_MARKER_DIR="${_ZW_MARKER_DIR_OVERRIDE:-/tmp/zombie-watch-markers}"   # self-test/진단 전용 오버라이드
_ZW_POLL_INTERVAL="${_ZW_POLL_INTERVAL_OVERRIDE:-180}"   # self-test 전용 오버라이드
_ZW_RESIDENT_AGENT="planner"
_ZW_INPROC_TTL_SEC="${_ZW_INPROC_TTL_SEC_OVERRIDE:-300}"   # in-process 무기록 임계값(초, 5분) — self-test 전용 오버라이드

# 모듈 로딩 — lib·poll은 source한다(zombie_check.sh 소싱 금지와 별개).
for _zw_mod in lib poll; do
  _zw_mod_f="${_ZW_SCRIPT_DIR}/zombie_watch_${_zw_mod}.sh"
  [[ -r "$_zw_mod_f" ]] || { echo "SKIP: 모듈 로딩 실패 — ${_zw_mod_f} 부재 또는 읽기 불가" >&2; exit 1; }
  # shellcheck source=/dev/null
  source "$_zw_mod_f"
done
unset _zw_mod _zw_mod_f

# 대상 1인 체크 + 억제 게이트 적용 + edge-triggered emit 판단 + 상태 파일 갱신
# mode: "pane"(기본 — zombie_check.sh 시그널 #1/#2/#4) · "inproc"(transcript 무기록 감시)
_zw_check_one() {
  local team="$1" agent="$2" is_first="$3" mode="${4:-pane}"
  local rc=0 output status suppressed=false
  if [[ "$mode" == "inproc" ]]; then
    output="$(_zw_invoke_inproc "$team" "$agent" 2>&1)" || rc=$?
  else
    output="$(_zw_invoke_zc "$team" "$agent" 2>&1)" || rc=$?
  fi
  case "$rc" in
    0) status="OK" ;; 1) status="ZOMBIE" ;; 2) status="SUSPECT" ;; 3) status="SKIP" ;;
    *) status="UNKNOWN" ;;
  esac

  local state_dir="${_ZW_STATE_ROOT}/${team}"
  local state_file="${state_dir}/${agent}.state"
  local wake_marker="${state_dir}/${agent}.wake"
  mkdir -p "$state_dir" 2>/dev/null || true

  # 직전 SUSPECT 가 wake-up 을 권장한 이후 inbox 가 갱신됐다면 그
  # 갱신은 "내가 일으킨 갱신"(wake-up 발신·회신)일 수 있어 OK 를 확정 판정으로 신뢰하지
  # 않는다 — SKIP(3, 판정 불가) 로 낮춘다. wake_marker 가 없는 경로(직전이 SUSPECT 가 아니었던
  # 정상 OK)는 그대로 통과해 감지력이 유지된다. 마커는 1회 관측으로 소비한다.
  if [[ "$status" == "OK" && -f "$wake_marker" ]]; then
    local wake_at inbox_mt
    wake_at="$(cat "$wake_marker" 2>/dev/null)" || wake_at=0
    inbox_mt="$(_zw_inbox_mtime "$agent" "$team")"
    if [[ "$wake_at" =~ ^[0-9]+$ && "$inbox_mt" =~ ^[0-9]+$ && "$inbox_mt" -gt "$wake_at" ]]; then
      status="SKIP"
      output="SKIP: ${agent} (R2-5: 직전 SUSPECT 이후 inbox 갱신 — wake-up 자기발신 리셋 의심, 판정 보류)"
    fi
    rm -f "$wake_marker" 2>/dev/null || true
  fi

  if [[ "$status" == "SUSPECT" ]]; then
    if [[ "$agent" == "$_ZW_RESIDENT_AGENT" || "$agent" =~ ^planner_r[1-5]$ ]]; then
      status="RESIDENT"
    elif [[ "$mode" != "inproc" ]] && _zw_suppress_check "$team" "$agent"; then
      status="OK"
      suppressed=true
    fi
  fi
  [[ "$status" == "SUSPECT" ]] && { date +%s > "$wake_marker" 2>/dev/null || true; }

  local prev_status=""
  [[ -f "$state_file" ]] && prev_status="$(cat "$state_file" 2>/dev/null)" || true

  local should_emit=false
  [[ "$is_first" == true ]] && should_emit=true
  [[ "$status" == "ZOMBIE" ]] && should_emit=true
  [[ "$status" != "$prev_status" ]] && should_emit=true

  [[ "$should_emit" == true ]] && _zw_emit "$agent" "$status" "$output" "$suppressed"
  printf '%s' "$status" > "$state_file" 2>/dev/null || true

  # 최종 status를 종료 코드(0/1/2/3)로 반환한다 — --once 호출자는 종료 코드만 본다.
  # 폴링 루프(_zw_run_loop)는 `|| true`로 감싸여 있어 이 반환값 도입에 영향받지 않는다.
  case "$status" in
    OK) return 0 ;;
    RESIDENT) return 0 ;;
    ZOMBIE) return 1 ;;
    SUSPECT) return 2 ;;
    SKIP) return 3 ;;
    *) return "$rc" ;;
  esac
}

cmd_once() {
  local team="$1" agent="${2:-}"
  local -a _zw_hash_store=()
  if [[ -n "$agent" ]]; then
    # 실 pane(%N)이면 그대로 판정. 없으면 in-process 대상인지 확인한다(다건 agent 미지정
    # 경로와 같은 기준) — 대상이면 in-process 로, 아니면(team-lead 등) SKIP(3).
    local pane; pane="$(_zw_pane_id "$agent" "$team")"
    if [[ "$pane" =~ ^%[0-9]+$ ]]; then
      local rc=0
      _zw_check_one "$team" "$agent" true "pane" || rc=$?
      return "$rc"
    fi
    command -v jq >/dev/null 2>&1 || { echo "SKIP: ${agent} — jq 불가로 in-process 판정 불가 (team=${team})" >&2; return 3; }
    local config; config="${HOME:-}/.claude/teams/${team}/config.json"
    [[ -f "$config" ]] || { echo "SKIP: ${agent} — config.json 없음 (team=${team})" >&2; return 3; }
    if _zw_inproc_target_names "$config" 2>/dev/null | grep -Fxq "$agent"; then
      local rc=0
      _zw_check_one "$team" "$agent" true "inproc" || rc=$?
      return "$rc"
    fi
    echo "SKIP: ${agent} — 실 pane 미보유로 폴링 제외 (team=${team})" >&2
    return 3
  fi
  command -v jq >/dev/null 2>&1 || { echo "SKIP: jq 불가 — --once 에 agent 를 직접 지정하십시오" >&2; return 3; }
  local config="${HOME:-}/.claude/teams/${team}/config.json"
  [[ -f "$config" ]] || { echo "SKIP: config.json 없음 (team=${team})" >&2; return 3; }
  local agents inproc_agents a notice
  # 실 pane 보유 멤버 + in-process 멤버(pane 없고 team-lead 아닌 멤버, 대기 포함) 대상.
  # 그 밖(team-lead)은 제외·가시화한다(SKIP + rc=3, 대상 0명일 때).
  agents="$(jq -r '.members[]? | select(.tmuxPaneId // "" | test("^%[0-9]+$")) | .name' "$config" 2>/dev/null)" || agents=""
  inproc_agents="$(_zw_inproc_target_names "$config")" || inproc_agents=""
  notice="$(_zw_excluded_notice "$team" "$config")"; [[ -n "$notice" ]] && echo "$notice" >&2
  [[ -z "$agents" && -z "$inproc_agents" ]] && { echo "SKIP: team=${team} — 폴링 대상 0명 (전원 실 pane 미보유이며 in-process 대상도 없음)" >&2; return 3; }
  # 다건은 가장 심각한(worst) 판정을 대표값으로 반환한다 — 전원 조용히 0 하나로
  # 뭉개지 않도록. 우선순위는 _zw_rc_severity(lib).
  local worst_rc=0 worst_sev=0
  for a in $agents; do
    local rc=0
    _zw_check_one "$team" "$a" true "pane" || rc=$?
    local sev
    sev="$(_zw_rc_severity "$rc")"
    if (( sev > worst_sev )); then
      worst_sev=$sev
      worst_rc=$rc
    fi
  done
  for a in $inproc_agents; do
    local rc=0
    _zw_check_one "$team" "$a" true "inproc" || rc=$?
    local sev
    sev="$(_zw_rc_severity "$rc")"
    if (( sev > worst_sev )); then
      worst_sev=$sev
      worst_rc=$rc
    fi
  done
  return "$worst_rc"
}

_zw_print_help() {
  cat <<'EOF'
zombie_watch.sh — LIFECYCLE-6 체크 스케줄러

사용법:
  zombie_watch.sh --arm <team>            폴링 루프 기동 (백그라운드)
  zombie_watch.sh --stop <team>           해제 + 마커 정리
  zombie_watch.sh --status <team>         arm 여부 3단 판정 출력
  zombie_watch.sh --once <team> [agent]   1회 체크 (spawn+30초 경로용)
  zombie_watch.sh --self-test             내장 단위 테스트
  zombie_watch.sh --help                  이 도움말

zombie_check.sh 를 subprocess 로만 호출한다(source 금지). 상세는
docs/SSOT/ROLES/SUB-SSOT/TEAM-LEAD/lifecycle-procedure.md §LIFECYCLE-6 SCHEDULER 참조.
EOF
}

# CLI 진입점
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    --arm)
      [[ -n "${2:-}" ]] || { echo "사용법: $0 --arm <team>" >&2; exit 1; }
      cmd_arm "$2"; exit $? ;;
    --stop)
      [[ -n "${2:-}" ]] || { echo "사용법: $0 --stop <team>" >&2; exit 1; }
      cmd_stop "$2"; exit $? ;;
    --status)
      [[ -n "${2:-}" ]] || { echo "사용법: $0 --status <team>" >&2; exit 1; }
      cmd_status "$2"; exit $? ;;
    --once)
      [[ -n "${2:-}" ]] || { echo "사용법: $0 --once <team> [agent]" >&2; exit 1; }
      cmd_once "$2" "${3:-}"; exit $? ;;
    --_loop-internal)
      [[ -n "${2:-}" ]] || exit 1
      _zw_run_loop "$2" ;;
    --self-test)
      _zw_selftest_file="${_ZW_SCRIPT_DIR}/zombie_watch_selftest.sh"
      if [[ ! -r "$_zw_selftest_file" ]]; then
        echo "SKIP: --self-test 실행 불가 — zombie_watch_selftest.sh 부재 또는 읽기 불가 (${_zw_selftest_file})" >&2
        exit 1
      fi
      exec bash "$_zw_selftest_file" ;;
    --help|"")
      _zw_print_help; exit 0 ;;
    *)
      echo "알 수 없는 옵션: ${1}" >&2
      _zw_print_help >&2
      exit 1 ;;
  esac
fi
