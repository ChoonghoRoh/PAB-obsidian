#!/usr/bin/env bash
# zombie_check.sh — LIFECYCLE-5 좀비 감지 헬퍼
#
# 규칙: LIFECYCLE-5
#
# 사용법:
#   zombie_check.sh <agent_name> <team_name>   # 단건 진단
#   zombie_check.sh --self-test                # 내장 단위 테스트 실행 (zombie_check_selftest.sh 위임)
#
# 종료 코드 계약 (이 4값 외 반환 금지):
#   0 = 정상 (OK)
#   1 = 좀비 확정 (ZOMBIE-CONFIRMED)
#   2 = 추정 좀비 (ZOMBIE-SUSPECT — wake-up 권장)
#   3 = 판정 불가 (SKIP — 시그널 조회 자체 불가. 오탐 대신 미판정 반환)
#
# 부작용 없음: 본 스크립트는 진단만 수행한다.
#   kill / respawn / 파일 쓰기(설정·로그 등) 절대 금지 — 판정 결과 stdout 출력만.
#
# 플랫폼 중립: macOS(BSD)·Linux(GNU) 공통 문법만 사용한다 (uname 분기 없음).
#   ps -eo pid,command / date -r <file> +%s / ${HOME}

# 중복 로딩 방지: 같은 프로세스에서 두 번 source하면 readonly 재선언으로 죽는다.
# 표식 변수 대신 zombie_check 함수가 정의돼 있는지로 판정한다 — 함수는 set -a로
# export되지 않고 exec를 넘지 않아 환경 오염·이름 충돌에 영향받지 않는다.
# source 중일 때만 반환한다.
if declare -F zombie_check &>/dev/null && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  return 0 2>/dev/null || exit 3   # EXIT_SKIP(3) — 상수 선언 이전 지점이라 하드코딩. 이론상 도달 불가(방어적 폴백)
fi

set -euo pipefail

# 종료 코드 상수
readonly EXIT_OK=0
readonly EXIT_ZOMBIE=1
readonly EXIT_SUSPECT=2
readonly EXIT_SKIP=3

# idle TTL 판정 기준
readonly IDLE_TTL_SEC=180

# 저수준 조회 헬퍼 — 실제 구현(_real)과 진단 로직이 부르는 창(래퍼)을 분리한다.
# self-test 스텁 케이스는 래퍼(_zc_find_pid 등)만 재정의하므로 _real 구현은
# 항상 보존되어, 같은 세션 안에서도 "실헬퍼" 케이스가 스텁 여부와 무관하게
# 실제 시스템(ps/date/tmux) 위에서 곧바로 실행될 수 있다.
# 각 헬퍼는 조회 실패(대상 없음)를 "빈 문자열" 로 표현한다 (에러가 아닌 정상 결과).
# 단, _zc_find_pid는 "조회 자체 실패"를 "UNAVAILABLE" 로 구분 반환한다.

# 시그널 #1 용: claude.exe 프로세스 PID 조회.
# 반환: PID 문자열(FOUND) / ''(NOT_FOUND — 조회 성공·매칭 없음, 정상) / 'UNAVAILABLE'(조회 자체 실패)
_zc_find_pid_real() {
  local name="$1" team="$2"
  local ps_output
  if ! ps_output="$(ps -eo pid,command 2>/dev/null)"; then
    printf 'UNAVAILABLE'
    return 0
  fi
  local pid
  pid="$(printf '%s\n' "$ps_output" | grep -F "agent-id ${name}@${team}" 2>/dev/null | grep -v grep | awk '{print $1}' | head -n1)" || true
  printf '%s' "${pid:-}"
}

# 시그널 #2 용: team config.json 에서 대상 에이전트의 tmux paneId 조회. 없으면 빈 문자열.
_zc_pane_id_real() {
  local name="$1" config="$2"
  local pane_id
  if [[ ! -f "$config" ]]; then
    printf ''
    return 0
  fi
  pane_id="$(jq -r --arg n "$name" '.members[]? | select(.name==$n) | .tmuxPaneId // empty' "$config" 2>/dev/null)" || true
  printf '%s' "${pane_id:-}"
}

# 대상 에이전트 PID 의 ppid 체인을 최대 3단계까지 거슬러 올라가 tmux 서버 소켓명을 추출한다.
# 대상 프로세스의 "직계 부모가 곧 자신을 띄운 tmux 서버"라는 실측에 근거한다.
# 유령 소켓(소켓 파일만 남고 서버 프로세스가 죽은 경우)을 배제하기 위해
# list-sessions 로 생존까지 확인한 소켓만 반환한다.
# 반환: 소켓명(성공) / ''(3단계 내 tmux 서버 미발견 또는 발견한 소켓이 죽어 있음)
_zc_resolve_socket_real() {
  local target_pid="$1"
  local depth=0 cur="$target_pid" parent cmd sock
  while (( depth < 3 )); do
    parent="$(ps -o ppid= -p "$cur" 2>/dev/null | tr -d ' ')"
    [[ -z "$parent" || "$parent" == "1" ]] && break
    cmd="$(ps -o command= -p "$parent" 2>/dev/null)" || cmd=""
    if [[ "$cmd" =~ tmux\ -L\ ([^[:space:]]+) ]]; then
      sock="${BASH_REMATCH[1]}"
      if tmux -L "$sock" list-sessions >/dev/null 2>&1; then
        printf '%s' "$sock"
        return 0
      fi
    fi
    cur="$parent"
    depth=$((depth + 1))
  done
  printf ''
}

# 시그널 #2 용: tmux pane 마지막 줄 캡처. 실패 시 빈 문자열.
# 소켓명은 호출부가 _zc_resolve_socket 로 해소해 전달한다(스크립트 자신 PPID 사용 금지).
_zc_pane_tail_real() {
  local pane_id="$1" socket="$2"
  local tail_line
  tail_line="$(tmux -L "$socket" capture-pane -t "$pane_id" -p 2>/dev/null | tail -1)" || true
  printf '%s' "${tail_line:-}"
}

# 시그널 #4/#5 용: 활동 신호원(inbox 또는 config.json) mtime (epoch 초). 조회 불가 시 0.
# 플랫폼 중립: `date -r <file> +%s` — macOS(BSD)·Linux(GNU) 공통 문법 (stat 미사용).
_zc_mtime_real() {
  local source_file="$1"
  local mtime
  mtime="$(date -r "$source_file" +%s 2>/dev/null)" || true
  printf '%s' "${mtime:-0}"
}

# 현재 시각 (epoch 초). date 명령 자체가 없어도 스크립트를 중단시키지 않고 빈 문자열 반환.
_zc_now_real() {
  date +%s 2>/dev/null || printf ''
}

# 진단 로직이 실제로 호출하는 창. self-test 스텁 케이스는 이 이름들만 재정의한다.
_zc_find_pid() { _zc_find_pid_real "$@"; }
_zc_pane_id() { _zc_pane_id_real "$@"; }
_zc_pane_tail() { _zc_pane_tail_real "$@"; }
_zc_resolve_socket() { _zc_resolve_socket_real "$@"; }
_zc_mtime() { _zc_mtime_real "$@"; }
_zc_now() { _zc_now_real; }

# 좀비 감지 핵심 로직 (진단 전용)
# 사용: zombie_check <agent_name> <team_name>
# 시그널 우선순위: #1(프로세스 부재, 단독 확정) → #2(shell prompt, 단독 확정)
#                → #4/#5(idle TTL ≥ IDLE_TTL_SEC → 추정)
# SKIP(3): 시그널 #1(ps)·#2(tmux 소켓)·mtime(inbox/config) 근거가 전부 조회 불가일 때만 발동.
#          하나라도 정상 조회되면 기존 0/1/2 로직을 그대로 적용한다.
#          "조회 불가"는 어떤 신호에서도 확정 판정으로 새지 않는다.
zombie_check() {
  # 함수를 인자 없이(또는 1개만) 직접 호출해도 set -u로 죽지 않도록 안전 대입.
  #      CLI 진입점의 `$# -lt 2` 가드는 이 함수를 소싱 후 직접 호출하는 경로엔 적용되지 않는다.
  local name="${1:-}"
  local team="${2:-}"
  if [[ -z "$name" || -z "$team" ]]; then
    echo "SKIP: (agent_name/team_name 인자 누락)"
    return "$EXIT_SKIP"
  fi

  # set -u 환경에서 HOME 미설정 시 unbound variable로 죽지 않도록 안전 대입.
  #      HOME이 비어 있으면 경로 자체를 구성하지 않고 sig2/mtime를 조회 불가로 둔다.
  # config.json(팀 전체, 합류·이탈 시에만 갱신) 대신 inboxes/{agent}.json(에이전트별,
  #      실제 메시지 송수신 시 갱신)을 활동 신호원으로 우선한다. inboxes/가 없으면
  #      config.json으로 폴백한다.
  local home_dir="${HOME:-}"
  local config="" inbox=""
  if [[ -n "$home_dir" ]]; then
    config="${home_dir}/.claude/teams/${team}/config.json"
    inbox="${home_dir}/.claude/teams/${team}/inboxes/${name}.json"
  fi
  local mtime_source=""
  if [[ -n "$inbox" && -f "$inbox" ]]; then
    mtime_source="$inbox"
  elif [[ -n "$config" && -f "$config" ]]; then
    mtime_source="$config"
  fi

  local sig1_unavailable=false
  local sig2_unavailable=false
  local mtime_unavailable=false

  # 시그널 #1: claude.exe 프로세스 부재 → 단독 확정 (조회 자체 실패는 확정 금지)
  local pid
  pid="$(_zc_find_pid "$name" "$team")"
  if [[ "$pid" == "UNAVAILABLE" ]]; then
    sig1_unavailable=true
    pid=""
  elif [[ -z "$pid" ]]; then
    echo "ZOMBIE-CONFIRMED: ${name} (no claude.exe process)"
    return "$EXIT_ZOMBIE"
  fi

  # 시그널 #2: tmux pane 이 shell prompt 로 복귀 → 단독 확정
  # 소켓명은 대상 PID(pid)의 ppid 체인에서 역추적한다. pid 를 모르면(UNAVAILABLE)
  #      소켓도 해소할 수 없으므로 시그널 #2 전체를 조회 불가로 둔다.
  if ! command -v tmux >/dev/null 2>&1; then
    sig2_unavailable=true
  elif [[ -z "$pid" ]]; then
    sig2_unavailable=true
  elif [[ -z "$config" ]] || [[ ! -f "$config" ]]; then
    sig2_unavailable=true
  else
    local pane_id
    pane_id="$(_zc_pane_id "$name" "$config")"
    if [[ -n "$pane_id" ]]; then
      local socket
      socket="$(_zc_resolve_socket "$pid")"
      if [[ -n "$socket" ]]; then
        local pane_tail
        pane_tail="$(_zc_pane_tail "$pane_id" "$socket")"
        if [[ "$pane_tail" =~ \$[[:space:]]*$ ]]; then
          echo "ZOMBIE-CONFIRMED: ${name} (shell prompt visible)"
          return "$EXIT_ZOMBIE"
        fi
      else
        sig2_unavailable=true
      fi
    else
      sig2_unavailable=true
    fi
  fi

  # mtime 근거: 활동 신호원(inbox 우선, config 폴백)이 전혀 없으면 조회 불가
  if [[ -z "$mtime_source" ]]; then
    mtime_unavailable=true
  fi

  # 전 시그널 조회 불가 → SKIP (오탐 대신 미판정 반환)
  if [[ "$sig1_unavailable" == true && "$sig2_unavailable" == true && "$mtime_unavailable" == true ]]; then
    echo "SKIP: ${name} (판정 근거 조회 불가 — ps/tmux/inbox 전부 unavailable)"
    return "$EXIT_SKIP"
  fi

  # 시그널 #4(파일 mtime 정체, TTL 초과). #5는 미구현이라 조합에서 제외된다.
  # mtime_unavailable(=신호원 조회 불가)일 때는 이 판정 자체를 건너뛴다.
  # _zc_now가 date 부재 등으로 빈 문자열을 반환할 수 있으므로 숫자 여부까지 확인한다.
  # 신호원 파일이 존재해도 실제 읽기(mtime 파싱)에 실패하면(예: date 명령 부재로
  #      기본값 0이 반환된 경우) 뒤늦게 조회 불가로 재분류하고, 그 결과 세 시그널이
  #      전부 unavailable이 되면 여기서도 SKIP을 재판정한다.
  if [[ "$mtime_unavailable" == false ]]; then
    local last_activity now diff
    last_activity="$(_zc_mtime "$mtime_source")"
    now="$(_zc_now)"
    if [[ "$last_activity" =~ ^[0-9]+$ ]] && (( last_activity > 0 )) && [[ "$now" =~ ^[0-9]+$ ]]; then
      diff=$(( now - last_activity ))
      if (( diff > IDLE_TTL_SEC )); then
        echo "ZOMBIE-SUSPECT: ${name} (idle ${diff}s >= ${IDLE_TTL_SEC}s, wake-up 권장)"
        return "$EXIT_SUSPECT"
      fi
    else
      mtime_unavailable=true
    fi
  fi

  if [[ "$sig1_unavailable" == true && "$sig2_unavailable" == true && "$mtime_unavailable" == true ]]; then
    echo "SKIP: ${name} (판정 근거 조회 불가 — ps/tmux/inbox 읽기 전부 실패)"
    return "$EXIT_SKIP"
  fi

  if [[ -n "$pid" ]]; then
    echo "OK: ${name} (pid=${pid})"
  else
    echo "OK: ${name} (pid 조회 불가 — 기타 시그널 정상)"
  fi
  return "$EXIT_OK"
}

# CLI 진입점
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ "${1:-}" == "--self-test" ]]; then
    # self-test는 zombie_check_selftest.sh에 exec로 위임한다.
    # 부분 설치·배포 누락 등으로 분리 파일이 없으면 exec 자체가 126/127로 실패해
    # 종료 코드 4값 계약을 어길 수 있으므로, exec 전에 존재·읽기 가능 여부를 먼저 확인한다.
    _zc_selftest_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/zombie_check_selftest.sh"
    if [[ ! -r "$_zc_selftest_file" ]]; then
      echo "SKIP: --self-test 실행 불가 — zombie_check_selftest.sh 부재 또는 읽기 불가 (${_zc_selftest_file})" >&2
      exit "$EXIT_SKIP"
    fi
    exec bash "$_zc_selftest_file"
  fi

  if [[ $# -lt 2 ]]; then
    echo "사용법: $0 <agent_name> <team_name>  |  $0 --self-test" >&2
    exit "$EXIT_SKIP"
  fi

  zombie_check "$1" "$2"
  exit $?
fi
