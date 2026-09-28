#!/usr/bin/env bash
# zombie_watch_poll.sh — zombie_watch.sh 폴링 루프 + arm 판정 라이브러리 (source 전용)
#
# 폴링 루프(_zw_run_loop)는 --arm 이 백그라운드로 기동한다. arm 판정 3단은
# 마커 존재 + PID 생존 + 명령줄(본체 파일명 포함) 대조로 판단하며 이 판정이
# 유일한 근거다 — status.md 필드는 가시성용일 뿐이다.
#
# 쉘 안전 옵션(errexit/nounset/pipefail)은 소싱하는 쪽에서 상속되므로 본 파일
# 에서 재선언하지 않는다.

# 폴링 루프 — --arm 이 백그라운드로 기동한다. jq/config.json 부재 시 목록 획득을
# 포기하고 SKIP 하되 기동 1회는 반드시 emit 한다.
_zw_run_loop() {
  local team="$1"
  local marker
  marker="$(_zw_marker_file "$team")"
  trap 'rm -f "'"$marker"'"; exit 0' EXIT TERM INT

  local -a _zw_hash_store=()
  local first_cycle=true
  local list_warned=false
  local excl_warned=false   # 기동 1회만 emit
  local zero_warned=false   # 상태 변화 시에만 emit

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
    local agents inproc_agents agent notice
    # 실 pane(%N) 보유 멤버는 그대로 폴링. pane 없는 멤버는 in-process 감시 대상
    # (team-lead 아닌 멤버, 대기 포함)만 폴링한다.
    agents="$(jq -r '.members[]? | select(.tmuxPaneId // "" | test("^%[0-9]+$")) | .name' "$config" 2>/dev/null)" || agents=""
    inproc_agents="$(_zw_inproc_target_names "$config")" || inproc_agents=""
    if [[ "$excl_warned" == false ]]; then
      notice="$(_zw_excluded_notice "$team" "$config")"
      [[ -n "$notice" ]] && echo "$notice"
      excl_warned=true
    fi
    if [[ -z "$agents" && -z "$inproc_agents" ]]; then
      [[ "$zero_warned" == false ]] && echo "SKIP: team=${team} — 폴링 대상 0명 (전원 실 pane 미보유이며 in-process 대상도 없음)"
      zero_warned=true
    else
      zero_warned=false
    fi
    for agent in $agents; do
      _zw_check_one "$team" "$agent" "$first_cycle" "pane" || true
    done
    for agent in $inproc_agents; do
      _zw_check_one "$team" "$agent" "$first_cycle" "inproc" || true
    done
    first_cycle=false
    sleep "$_ZW_POLL_INTERVAL"
  done
}

# arm 판정 3단
_zw_marker_file() { printf '%s/%s.pid' "$_ZW_MARKER_DIR" "$1"; }

_zw_is_armed() {
  local team="$1" marker pid cmd
  marker="$(_zw_marker_file "$team")"
  [[ -f "$marker" ]] || return 1                       # 1단: 마커 존재
  pid="$(cat "$marker" 2>/dev/null)" || return 1
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1               # 2단: PID 생존
  cmd="$(ps -o command= -p "$pid" 2>/dev/null)" || return 1
  [[ "$cmd" == *zombie_watch.sh*--_loop-internal* && "$cmd" =~ (^|[[:space:]])${team}($|[[:space:]]) ]] || return 1   # 3단: 명령줄+팀명 단어경계 대조(단어 경계 — foo가 foobar에 걸리지 않게)
  printf '%s' "$pid"
  return 0
}

cmd_arm() {
  local team="$1" existing_pid pid
  if existing_pid="$(_zw_is_armed "$team")"; then
    echo "이미 arm됨: team=${team} pid=${existing_pid}"
    return 0
  fi
  # 기동 전에 팀 디렉토리를 확인한다 — <team>은 팀 디렉토리명이다(Phase ID 아님).
  # 없으면 SKIP(3).
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
  rm -rf "${_ZW_STATE_ROOT:?}/${team}" 2>/dev/null || true   # 해당 팀 state 만 정리(타 팀 보존)
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
