#!/usr/bin/env bash
# =============================================================================
# zombie_watch_poll.sh — zombie_watch.sh 폴링 루프 + arm 판정 라이브러리
# (Phase 9-1-3 분리, source 전용)
#
# 폴링 루프(_zw_run_loop)는 --arm 이 백그라운드로 기동한다. arm 판정 3단(§2.2)은
# 마커 존재 + PID 생존 + 명령줄(본체 파일명 포함) 대조로 판단하며 이 판정이
# 유일한 근거다 — status.md 필드는 가시성용일 뿐이다.
#
# 쉘 안전 옵션(errexit/nounset/pipefail)은 소싱하는 쪽에서 상속되므로 본 파일
# 에서 재선언하지 않는다.
# =============================================================================

# -----------------------------------------------------------------------------
# 폴링 루프 — --arm 이 백그라운드로 기동한다. jq/config.json 부재 시 목록 획득을
# 포기하고 SKIP 하되 기동 1회는 반드시 emit 한다(§2.5).
# -----------------------------------------------------------------------------
_zw_run_loop() {
  local team="$1"
  local marker
  marker="$(_zw_marker_file "$team")"
  trap 'rm -f "'"$marker"'"; exit 0' EXIT TERM INT

  local -a _zw_hash_store=()
  local first_cycle=true
  local list_warned=false
  local excl_warned=false   # R2-1: 제외 멤버 존재 — 기동 1회만 emit(§2.3 edge-triggered, R-15)
  local zero_warned=false   # R2-1: 대상 0명 — 상태 변화 시에만 emit

  while true; do
    local config="${HOME:-}/.claude/teams/${team}/config.json"
    if ! command -v jq >/dev/null 2>&1 || [[ ! -f "$config" ]]; then
      if [[ "$list_warned" == false ]]; then
        echo "SKIP: team=${team} — jq 또는 config.json 불가로 팀원 목록 조회 불가 (기동 1회 알림, 이후 무출력)"
        list_warned=true
      fi
      sleep "$_ZW_POLL_INTERVAL"
      continue
    fi
    local agents agent notice
    # D-1(AUTO_FIX): tmuxPaneId `%숫자` 형식(실 pane 보유) 멤버만 폴링 대상 — 근거는 D-1 조사 참조.
    agents="$(jq -r '.members[]? | select(.tmuxPaneId // "" | test("^%[0-9]+$")) | .name' "$config" 2>/dev/null)" || agents=""
    if [[ "$excl_warned" == false ]]; then
      notice="$(_zw_excluded_notice "$team" "$config")"
      [[ -n "$notice" ]] && echo "$notice"
      excl_warned=true
    fi
    if [[ -z "$agents" ]]; then
      [[ "$zero_warned" == false ]] && echo "SKIP: team=${team} — 폴링 대상 0명 (전원 실 pane 미보유)"
      zero_warned=true
    else
      zero_warned=false
    fi
    for agent in $agents; do
      _zw_check_one "$team" "$agent" "$first_cycle" || true
    done
    first_cycle=false
    sleep "$_ZW_POLL_INTERVAL"
  done
}

# -----------------------------------------------------------------------------
# arm 판정 3단 (§2.2) — 마커 존재 + PID 생존 + 명령줄 대조. status.md 필드는 가시성용이며
# 이 함수가 유일한 판정 근거다.
# -----------------------------------------------------------------------------
_zw_marker_file() { printf '%s/%s.pid' "$_ZW_MARKER_DIR" "$1"; }

_zw_is_armed() {
  local team="$1" marker pid cmd
  marker="$(_zw_marker_file "$team")"
  [[ -f "$marker" ]] || return 1                       # 1단: 마커 존재
  pid="$(cat "$marker" 2>/dev/null)" || return 1
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1               # 2단: PID 생존
  cmd="$(ps -o command= -p "$pid" 2>/dev/null)" || return 1
  [[ "$cmd" == *zombie_watch.sh*--_loop-internal* && "$cmd" =~ (^|[[:space:]])${team}($|[[:space:]]) ]] || return 1   # 3단: 명령줄+팀명 단어경계 대조(D-2/D8-5, foo가 foobar에 매칭되던 부분일치 오판정 방지)
  printf '%s' "$pid"
  return 0
}

cmd_arm() {
  local team="$1" existing_pid pid
  if existing_pid="$(_zw_is_armed "$team")"; then
    echo "이미 arm됨: team=${team} pid=${existing_pid}"
    return 0
  fi
  # DEF-9-3-001③/CR-2(Phase 9-3-4): 종전엔 자식 프로세스 기동만 확인해 잘못된 팀명도
  # rc=0("arm 완료")이 됐다 — 대상 없는 폴링 루프가 조용히 무한 SKIP 되는 원인이었다
  # (PAB-Leader가 <team> 자리에 Phase ID를 넣어 arm한 실사례, 2-lifecycle-procedure.md
  # §LIFECYCLE-6 SCHEDULER "arm 호출 규약" 참조). R-7(모르면 SKIP, 시끄럽게)에 따라
  # 기동 전에 팀 디렉토리 존재를 검증한다 — <team>은 팀 디렉토리명(=세션 디렉토리명)이다.
  local team_dir="${HOME:-}/.claude/teams/${team}"
  if [[ ! -d "$team_dir" ]]; then
    echo "SKIP: team=${team} — 팀 디렉토리 없음(${team_dir}). <team>은 팀 디렉토리명(=세션 디렉토리명)이어야 한다(Phase ID 금지)" >&2
    return 3
  fi
  mkdir -p "$_ZW_MARKER_DIR" "${_ZW_STATE_ROOT}/${team}"
  local logfile="${_ZW_MARKER_DIR}/${team}.log"
  "$_ZW_SCRIPT_PATH" --_loop-internal "$team" >"$logfile" 2>&1 &
  pid=$!
  disown "$pid" 2>/dev/null || true
  echo "$pid" > "$(_zw_marker_file "$team")"
  sleep 0.3
  if kill -0 "$pid" 2>/dev/null; then
    echo "arm 완료: team=${team} pid=${pid} (로그: ${logfile})"
  else
    echo "arm 실패: team=${team} — 백그라운드 프로세스가 즉시 종료됨 (${logfile} 확인)" >&2
    return 1
  fi
}

cmd_stop() {
  local team="$1" pid
  if pid="$(_zw_is_armed "$team")"; then
    kill -TERM "$pid" 2>/dev/null || true
    sleep 0.3
    kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
    echo "해제 완료: team=${team} (pid=${pid})"
  else
    echo "이미 미arm 상태: team=${team}"
  fi
  rm -f "$(_zw_marker_file "$team")"
  rm -rf "${_ZW_STATE_ROOT:?}/${team}" 2>/dev/null || true   # D-7: 해당 팀 state 만 정리(타 팀 보존)
}

cmd_status() {
  local team="$1" pid
  if pid="$(_zw_is_armed "$team")"; then
    echo "ARMED: team=${team} pid=${pid}"
    return 0
  fi
  echo "NOT-ARMED: team=${team}"
  return 1
}
