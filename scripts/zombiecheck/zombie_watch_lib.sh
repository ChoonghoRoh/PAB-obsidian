#!/usr/bin/env bash
# =============================================================================
# zombie_watch_lib.sh — zombie_watch.sh 헬퍼 라이브러리 (Phase 9-1-2 분리, source 전용)
#
# 진행 신호(억제 게이트) D-1/D-2: inbox stale + pane 해시 변화 → SUSPECT 취소(억제).
# 해시는 프로세스 메모리에만 보관(파일 금지 — 유령 마커 재발 방지). 상태 키는
# (agent_name, pane_id) 쌍 — respawn 은 새 pane 을 가지므로 이름만 키잉하면 안 된다.
#
# 플랫폼 중립: bash 3.2.57(declare -A 미지원). 해시 저장소는 "key=value" 인덱스
# 배열로 구현하며, 빈 배열을 set -u 상태로 직접 참조하면 죽으므로(실측) 길이를
# 먼저 확인한다. 쉘 안전 옵션(errexit/nounset/pipefail)은 소싱하는 쪽에서 상속되므로
# 본 파일에서 재선언하지 않는다.
# =============================================================================

# -----------------------------------------------------------------------------
# 저수준 헬퍼 — zombie_check.sh 의 _zc_*_real 과 동일한 조회를 독립 구현한다(소싱 금지 원칙상
# 공유 불가). self-test 는 창(_zw_find_pid 등)만 재정의해 조합 로직을 검증한다.
# -----------------------------------------------------------------------------
_zw_find_pid_real() {
  local name="$1" team="$2" pid
  pid="$(ps -eo pid,command 2>/dev/null | grep -F "agent-id ${name}@${team}" 2>/dev/null | grep -v grep | awk '{print $1}' | head -n1)" || true
  printf '%s' "${pid:-}"
}

_zw_pane_id_real() {
  local name="$1" team="$2" config pane_id
  config="${HOME:-}/.claude/teams/${team}/config.json"
  command -v jq >/dev/null 2>&1 || { printf ''; return 0; }
  [[ -f "$config" ]] || { printf ''; return 0; }
  pane_id="$(jq -r --arg n "$name" '.members[]? | select(.name==$n) | .tmuxPaneId // empty' "$config" 2>/dev/null)" || true
  printf '%s' "${pane_id:-}"
}

# A-1 원칙 준용: 대상 PID 의 ppid 체인(최대 3단)에서 살아있는 tmux 소켓을 역추적한다.
_zw_resolve_socket_real() {
  local target_pid="$1" depth=0 cur="$target_pid" parent cmd sock
  command -v tmux >/dev/null 2>&1 || { printf ''; return 0; }
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

# 억제 게이트용: pane 전체 내용의 해시(마지막 줄이 아니라 화면 전체 — 변화 탐지가 목적).
# V-1(Phase 9-3-2, High): 종전엔 capture 실패를 `|| true` 로 삼켜 항상 shasum 을 태웠다 —
# 빈 content 의 해시(`e3b0c442…`)가 "멀쩡한 값"으로 나가 호출측(_zw_suppress_check L120
# `[[ -z "$cur_hash" ]]`)의 unavailable 가드가 한 번도 발동하지 않았다. 위험은 **간헐적**
# 실패다: 정상 해시 → e3b0… 로의 변화를 억제 게이트가 "화면이 변했다"로 오독해 조회 실패를
# 진행 신호로 위조한다(항상 실패라면 해시가 불변이라 오히려 안전). 여기서는 capture 성공
# 여부를 rc 로 분기하고, 실패 시 **빈 문자열을 반환**한다 — 반환값은 그대로 0으로 유지한다
# (형제 헬퍼 _zw_pane_id_real/_zw_find_pid_real/_zw_resolve_socket_real 과 동일 관례: "조회
# 불가"는 빈 문자열로만 신호하고 함수 자체의 exit code 는 실패시키지 않는다 — 호출측이
# 전부 `"$(...)"` 대입 뒤 `|| true` 없이 `[[ -z ]]` 만으로 판별하므로, 여기서 nonzero 를
# 반환하면 set -e 상속 하에서 스크립트 전체가 조용히 중단된다).
_zw_pane_hash_real() {
  local pane_id="$1" socket="$2" content rc=0
  content="$(tmux -L "$socket" capture-pane -t "$pane_id" -p 2>/dev/null)" || rc=$?
  if (( rc != 0 )); then
    printf ''
    return 0
  fi
  printf '%s' "$content" | shasum -a 256 2>/dev/null | awk '{print $1}'
}

_zw_find_pid() { _zw_find_pid_real "$@"; }
_zw_pane_id() { _zw_pane_id_real "$@"; }
_zw_resolve_socket() { _zw_resolve_socket_real "$@"; }
_zw_pane_hash() { _zw_pane_hash_real "$@"; }

# R2-5 용: inboxes/<name>.json 원본 mtime 독립 조회(zombie_check.sh L-2 경로와 동일 구성,
# 소싱 금지 원칙상 공유 불가 — 위 헬퍼들과 같은 이유). 조회 불가 시 0(=비교 시 항상 과거로 처리).
_zw_inbox_mtime_real() {
  local name="$1" team="$2" inbox
  inbox="${HOME:-}/.claude/teams/${team}/inboxes/${name}.json"
  [[ -f "$inbox" ]] || { printf '0'; return 0; }
  date -r "$inbox" +%s 2>/dev/null || printf '0'
}
_zw_inbox_mtime() { _zw_inbox_mtime_real "$@"; }

# -----------------------------------------------------------------------------
# 해시 저장소 — 프로세스 메모리 전용(D-2). "key=value" 원소의 인덱스 배열로 구현
# (연관 배열 미지원 bash 3.2 대응). 호출부(_zw_run_loop)가 선언한 로컬 배열을
# 동적 스코프로 그대로 참조·수정한다.
# -----------------------------------------------------------------------------
_zw_hash_get() {
  local key="$1" i
  if (( ${#_zw_hash_store[@]} > 0 )); then
    for i in "${!_zw_hash_store[@]}"; do
      if [[ "${_zw_hash_store[$i]}" == "${key}="* ]]; then
        printf '%s' "${_zw_hash_store[$i]#${key}=}"
        return 0
      fi
    done
  fi
  printf ''
  return 1
}

_zw_hash_set() {
  local key="$1" value="$2" i
  if (( ${#_zw_hash_store[@]} > 0 )); then
    for i in "${!_zw_hash_store[@]}"; do
      if [[ "${_zw_hash_store[$i]}" == "${key}="* ]]; then
        _zw_hash_store[$i]="${key}=${value}"
        return 0
      fi
    done
  fi
  _zw_hash_store+=("${key}=${value}")
}

# 억제 게이트 판정. 반환: 0=억제(SUSPECT 취소) / 1=미억제(게이트 불가용 포함 — §2.4 (f))
_zw_suppress_check() {
  local team="$1" agent="$2"
  local pane_id target_pid socket cur_hash key prev_hash
  pane_id="$(_zw_pane_id "$agent" "$team")"
  [[ -z "$pane_id" ]] && return 1                      # 누락 B: jq/config 불가
  target_pid="$(_zw_find_pid "$agent" "$team")"
  [[ -z "$target_pid" || "$target_pid" == "UNAVAILABLE" ]] && return 1
  socket="$(_zw_resolve_socket "$target_pid")"
  [[ -z "$socket" ]] && return 1
  cur_hash="$(_zw_pane_hash "$pane_id" "$socket")"
  [[ -z "$cur_hash" ]] && return 1
  key="${agent}:${pane_id}"
  prev_hash="$(_zw_hash_get "$key")" || true
  _zw_hash_set "$key" "$cur_hash"
  [[ -z "$prev_hash" ]] && return 1                    # 최초 관측(또는 respawn 직후 새 키) — 기준 없음
  [[ "$prev_hash" != "$cur_hash" ]] && return 0         # 해시 변화 → 억제
  return 1                                              # 해시 불변 → 미억제
}

# -----------------------------------------------------------------------------
# zombie_check.sh 호출 — subprocess 고정. self-test 는 이 창만 재정의한다.
# -----------------------------------------------------------------------------
_zw_invoke_zc_real() {
  local team="$1" agent="$2"
  bash "$_ZW_ZC_SCRIPT" "$agent" "$team"
}
_zw_invoke_zc() { _zw_invoke_zc_real "$@"; }

# -----------------------------------------------------------------------------
# emit — edge-triggered, ZOMBIE 상시, 기동 1회 (§2.3)
# -----------------------------------------------------------------------------
_zw_emit() {
  local agent="$1" status="$2" detail="$3" suppressed="$4"
  case "$status" in
    OK)
      if [[ "$suppressed" == true ]]; then
        echo "OK: ${agent} (억제 게이트 — 통신 정체이나 화면 변화로 SUSPECT 취소)"
      else
        echo "OK: ${agent}"
      fi
      ;;
    ZOMBIE)
      # zombie_check.sh 출력이 이미 "ZOMBIE-CONFIRMED: agent (...)" 형태라 그대로 전달한다
      # (이중 접두 방지). 출력이 비면(이례적) 최소 정보로 대체한다.
      echo "${detail:-ZOMBIE-CONFIRMED: ${agent}}"
      ;;
    SUSPECT)
      local n
      n="$(printf '%s' "$detail" | grep -oE 'idle [0-9]+s' | grep -oE '[0-9]+' | head -n1)"
      echo "확인 필요: ${agent} 통신 ${n:-?}초 무 (wake-up 1회 권장, respawn 아님)"
      ;;
    SKIP)
      echo "${detail:-SKIP: ${agent}}"
      ;;
    *)
      echo "UNKNOWN(${agent}): ${detail}"
      ;;
  esac
}

# R2-1(Medium, Phase 8-5): D-1 필터가 조용히 제외하던 것을 가시화한다. 제외 멤버가 있으면
# 문구를, 없으면 빈 문자열을 반환한다 — 대상 0명 판정은 호출부가 $agents 로 직접 한다.
_zw_excluded_notice() {
  local team="$1" config="$2" list
  list="$(jq -r '.members[]? | select((.tmuxPaneId // "" | test("^%[0-9]+$")) | not) | .name' "$config" 2>/dev/null)" || return 0
  [[ -n "$list" ]] || return 0
  printf 'SKIP: team=%s — 실 pane 미보유로 폴링 제외: %s (%s명)' "$team" "$(printf '%s' "$list" | paste -sd, -)" "$(printf '%s\n' "$list" | grep -c .)"
}

# spawn+30초 1차 체크 — 3분 루프와 다른 경로(§2.5). 억제 게이트는 baseline 이 없어
# 이번 호출에서는 자연히 미억제로 동작한다(설계상 정상 — D-2 메모리 소실=미판정 원칙과 동일).
# D-3: rc(0/1/2/3) → 심각도 순위. ZOMBIE(1)이 가장 심각 > SUSPECT(2) > SKIP(3) > OK(0).
# 종료코드 값 자체는 심각도 순서가 아니므로(3=SKIP이 1=ZOMBIE보다 크지만 덜 급함) 별도 매핑한다.
_zw_rc_severity() {
  case "$1" in
    1) printf '3' ;;  # ZOMBIE
    2) printf '2' ;;  # SUSPECT
    3) printf '1' ;;  # SKIP
    0) printf '0' ;;  # OK
    *) printf '4' ;;  # 예상 외 값 — 최우선으로 취급(숨기지 않음)
  esac
}
