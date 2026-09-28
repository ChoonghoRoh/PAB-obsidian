#!/usr/bin/env bash
# zombie_watch_lib.sh — zombie_watch.sh 헬퍼 라이브러리 (source 전용)
#
# 진행 신호(억제 게이트): inbox stale + pane 해시 변화 → SUSPECT 취소(억제).
# 해시는 프로세스 메모리에만 보관(파일 금지 — 유령 마커 재발 방지). 상태 키는
# (agent_name, pane_id) 쌍 — respawn 은 새 pane 을 가지므로 이름만 키잉하면 안 된다.
#
# config.json 부재(pane_id 조회 불가) → 게이트 unavailable → 기존 zombie_check.sh 판정을
# 그대로 유지한다(억제 실패가 확정 판정으로 새지 않도록).
#
# 플랫폼 중립: bash 3.2.57(declare -A 미지원). 해시 저장소는 "key=value" 인덱스
# 배열로 구현하며, 빈 배열을 set -u 상태로 직접 참조하면 죽으므로(실측) 길이를
# 먼저 확인한다. 쉘 안전 옵션(errexit/nounset/pipefail)은 소싱하는 쪽에서 상속되므로
# 본 파일에서 재선언하지 않는다.

# 저수준 헬퍼 — zombie_check.sh 의 _zc_*_real 과 동일한 조회를 독립 구현한다(소싱 금지 원칙상
# 공유 불가). self-test 는 창(_zw_find_pid 등)만 재정의해 조합 로직을 검증한다.
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

# 대상 PID 의 ppid 체인(최대 3단)에서 살아있는 tmux 소켓을 역추적한다.
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
# capture가 실패하면 빈 문자열을 반환한다(rc 0).
# 빈 내용의 해시가 정상값처럼 나가면 간헐 실패가 "화면 변화"로 오독된다.
# 형제 헬퍼(_zw_pane_id_real/_zw_find_pid_real/_zw_resolve_socket_real)처럼
# "조회 불가"는 빈 문자열로만 알린다 — nonzero를 반환하면 set -e 상속으로 스크립트가 멈춘다.
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

# inboxes/<name>.json 원본 mtime 독립 조회(소싱 금지 원칙상 공유 불가 — 위 헬퍼들과 같은 이유).
# 조회 불가 시 0(=비교 시 항상 과거로 처리).
_zw_inbox_mtime_real() {
  local name="$1" team="$2" inbox
  inbox="${HOME:-}/.claude/teams/${team}/inboxes/${name}.json"
  [[ -f "$inbox" ]] || { printf '0'; return 0; }
  date -r "$inbox" +%s 2>/dev/null || printf '0'
}
_zw_inbox_mtime() { _zw_inbox_mtime_real "$@"; }

# 해시 저장소 — 프로세스 메모리 전용. "key=value" 원소의 인덱스 배열로 구현
# (연관 배열 미지원 bash 3.2 대응). 호출부(_zw_run_loop)가 선언한 로컬 배열을
# 동적 스코프로 그대로 참조·수정한다.
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

# 억제 게이트 판정. 반환: 0=억제(SUSPECT 취소) / 1=미억제(게이트 불가용 포함)
_zw_suppress_check() {
  local team="$1" agent="$2"
  local pane_id target_pid socket cur_hash key prev_hash
  pane_id="$(_zw_pane_id "$agent" "$team")"
  [[ -z "$pane_id" ]] && return 1                      # jq/config 불가
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

# zombie_check.sh 호출 — subprocess 고정. self-test 는 이 창만 재정의한다.
_zw_invoke_zc_real() {
  local team="$1" agent="$2"
  bash "$_ZW_ZC_SCRIPT" "$agent" "$team"
}
_zw_invoke_zc() { _zw_invoke_zc_real "$@"; }

# emit — edge-triggered, ZOMBIE 상시, 기동 1회
_zw_emit() {
  local agent="$1" status="$2" detail="$3" suppressed="$4"
  case "$status" in
    OK)
      case "$suppressed" in
        true) echo "OK: ${agent} (억제 게이트 — 통신 정체이나 화면 변화로 SUSPECT 취소)" ;;
        *) echo "OK: ${agent}" ;;
      esac
      ;;
    RESIDENT)
      echo "OK: ${agent} (상주 대기 — LIFECYCLE-1 예외)"
      ;;
    ZOMBIE)
      # zombie_check.sh 출력이 이미 "ZOMBIE-CONFIRMED: agent (...)" 형태라 그대로 전달한다
      # (이중 접두 방지). 출력이 비면(이례적) 최소 정보로 대체한다.
      echo "${detail:-ZOMBIE-CONFIRMED: ${agent}}"
      ;;
    SUSPECT)
      local n
      n="$(printf '%s' "$detail" | grep -oE 'idle [0-9]+s' | grep -oE '[0-9]+' | head -n1)"
      # in-process 판정(_zw_invoke_inproc_real)은 실제 신호가 통신이 아니라 transcript
      # 무기록이므로 문구를 구분한다.
      case "$detail" in
        *"in-process 무기록"*) echo "확인 필요: ${agent} transcript 무기록 ${n:-?}초 (wake-up 1회 권장, respawn 아님)" ;;
        *) echo "확인 필요: ${agent} 통신 ${n:-?}초 무 (wake-up 1회 권장, respawn 아님)" ;;
      esac
      ;;
    SKIP)
      echo "${detail:-SKIP: ${agent}}"
      ;;
    *)
      echo "UNKNOWN(${agent}): ${detail}"
      ;;
  esac
}

# 실 pane도 in-process 감시도 못 받는 멤버(team-lead)를 알린다. isActive는 작업 중/대기 표지일
# 뿐이라 이 판정에 쓰지 않는다 — 팀 config에 남아 있으면(대기 포함) 감시 대상이다.
# 있으면 문구를, 없으면 빈 문자열을 반환한다 — 대상 0명 판정은 호출부가 $agents · $inproc_agents 두 목록으로 직접 한다.
_zw_excluded_notice() {
  local team="$1" config="$2" list
  list="$(jq -r '.members[]? | select((.tmuxPaneId // "" | test("^%[0-9]+$")) | not) | select(.name == "team-lead") | .name' "$config" 2>/dev/null)" || return 0
  [[ -n "$list" ]] || return 0
  printf 'SKIP: team=%s — 실 pane 미보유로 폴링 제외: %s (%s명)' "$team" "$(printf '%s' "$list" | paste -sd, -)" "$(printf '%s\n' "$list" | grep -c .)"
}

# in-process 감시 대상 이름 목록 — pane 없고 team-lead가 아닌 멤버(대기 포함, isActive 미사용).
_zw_inproc_target_names() {
  local config="$1"
  jq -r '.members[]? | select((.tmuxPaneId // "" | test("^%[0-9]+$")) | not) | select(.name != "team-lead") | .name' "$config" 2>/dev/null
}

# in-process 감시용: 멤버 cwd 조회(config.json). 조회 불가 시 빈 문자열.
_zw_inproc_cwd_real() {
  local name="$1" team="$2" config cwd
  config="${HOME:-}/.claude/teams/${team}/config.json"
  command -v jq >/dev/null 2>&1 || { printf ''; return 0; }
  [[ -f "$config" ]] || { printf ''; return 0; }
  cwd="$(jq -r --arg n "$name" '.members[]? | select(.name==$n) | .cwd // empty' "$config" 2>/dev/null)" || true
  printf '%s' "${cwd:-}"
}
_zw_inproc_cwd() { _zw_inproc_cwd_real "$@"; }

# cwd → 프로젝트 transcript 디렉터리(~/.claude/projects/<영숫자·'-' 밖 문자를 '-'로>).
_zw_inproc_project_dir() {
  printf '%s/.claude/projects/%s' "${HOME:-}" "$(printf '%s' "$1" | sed -E 's/[^A-Za-z0-9-]/-/g')"
}

# 판정 기준 시각(epoch 초). 시험 전용 오버라이드(ISO8601)가 있으면 그 값, 없으면 현재 시각.
_zw_inproc_cutoff_epoch() {
  local override="${_ZW_INPROC_ASOF_OVERRIDE:-}"
  if [[ -n "$override" ]]; then
    printf '%s' "$override" | jq -R -r 'try (. | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) catch empty' 2>/dev/null
  else
    date +%s
  fi
}

# transcript 한 파일에서 agentName·teamName이 일치하는 assistant·user 기록 중 timestamp <= cutoff(초)인
# 마지막 한 줄을 "epoch<TAB>type<TAB>stop_reason" 로 반환(파일은 append-only 시간순 가정). attachment·system
# 기록(턴 종료 직후 hook 이 뒤이어 남기는 줄)은 판정 대상에서 제외한다 — 실제 턴 경계가 아니다.
# cutoff 생략 시 무제한(전체 마지막 기록 — 같은 이름 옛 세션 중 최신 파일 고르기용).
_zw_inproc_last_row() {
  local file="$1" name="$2" team="$3" cutoff="${4:-99999999999}"
  [[ "$cutoff" =~ ^[0-9]+$ ]] || cutoff=99999999999
  jq -R -r --arg n "$name" --arg t "$team" --argjson cutoff "$cutoff" '
    (fromjson?) as $r
    | select($r != null)
    | ($r.timestamp // empty) as $ts
    | select($r.agentName == $n and $r.teamName == $t and $ts != null and $ts != ""
        and ($r.type == "assistant" or $r.type == "user"))
    | ($ts | try (sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) catch null) as $epoch
    | select($epoch != null and $epoch <= $cutoff)
    | [$epoch, ($r.type // ""), ($r.message.stop_reason // "")]
    | @tsv
  ' "$file" 2>/dev/null | tail -1
}

# in-process 팀원 판정 — zombie_check.sh 대신 세션 transcript 무기록으로 SUSPECT/OK/SKIP을 낸다.
# ZOMBIE(1)는 내지 않는다(프로세스 생사를 이 경로로 확인할 수 없음 — 판정 불가는 SKIP으로 낮춘다).
_zw_invoke_inproc_real() {
  local team="$1" agent="$2"
  local cwd dir cutoff
  command -v jq >/dev/null 2>&1 || { echo "SKIP: ${agent} (jq 불가 — in-process 판정 불가)"; return 3; }
  cwd="$(_zw_inproc_cwd "$agent" "$team")"
  [[ -z "$cwd" ]] && { echo "SKIP: ${agent} (in-process cwd 조회 불가 — config.json 부재 또는 필드 없음)"; return 3; }
  dir="$(_zw_inproc_project_dir "$cwd")"
  [[ -d "$dir" ]] || { echo "SKIP: ${agent} (프로젝트 디렉터리 없음 — ${dir})"; return 3; }
  cutoff="$(_zw_inproc_cutoff_epoch)"
  [[ "$cutoff" =~ ^[0-9]+$ ]] || { echo "SKIP: ${agent} (기준 시각 계산 불가)"; return 3; }

  local -a files=()
  local f
  while IFS= read -r f; do [[ -n "$f" ]] && files+=("$f"); done < <(find "$dir" -maxdepth 1 -type f -name '*.jsonl' 2>/dev/null)
  (( ${#files[@]} == 0 )) && { echo "SKIP: ${agent} (transcript 파일 없음 — ${dir})"; return 3; }

  # 같은 이름의 옛 세션이 여럿이면 "전체 마지막 기록"이 가장 늦은 파일을 고른다.
  local best_file="" best_epoch=-1 g_row g_epoch
  for f in "${files[@]}"; do
    [[ -r "$f" ]] || continue
    g_row="$(_zw_inproc_last_row "$f" "$agent" "$team")"
    [[ -z "$g_row" ]] && continue
    g_epoch="${g_row%%$'\t'*}"
    [[ "$g_epoch" =~ ^[0-9]+$ ]] || continue
    if (( g_epoch > best_epoch )); then best_epoch=$g_epoch; best_file="$f"; fi
  done
  [[ -z "$best_file" ]] && { echo "SKIP: ${agent} (transcript에서 agentName·teamName 일치 기록 없음 — ${dir})"; return 3; }

  local row epoch rtype stop_reason idle
  row="$(_zw_inproc_last_row "$best_file" "$agent" "$team" "$cutoff")"
  [[ -z "$row" ]] && { echo "SKIP: ${agent} (기준 시각 이전 기록 없음 — ${best_file})"; return 3; }
  IFS=$'\t' read -r epoch rtype stop_reason <<< "$row"
  [[ "$epoch" =~ ^[0-9]+$ ]] || { echo "SKIP: ${agent} (기록 시각 파싱 실패)"; return 3; }
  idle=$(( cutoff - epoch ))

  # 마지막 기록이 응답 종료(assistant + end_turn)면 턴 끝 대기 — 무기록 시간과 무관하게 OK.
  if [[ "$rtype" == "assistant" && "$stop_reason" == "end_turn" ]]; then
    echo "OK: ${agent} (in-process 턴 끝 대기)"
    return 0
  fi
  if (( idle >= _ZW_INPROC_TTL_SEC )); then
    echo "ZOMBIE-SUSPECT: ${agent} (idle ${idle}s >= ${_ZW_INPROC_TTL_SEC}s, in-process 무기록, wake-up 권장)"
    return 2
  fi
  echo "OK: ${agent} (in-process 최근 기록)"
  return 0
}
_zw_invoke_inproc() { _zw_invoke_inproc_real "$@"; }

# rc(0/1/2/3) → 심각도 순위. ZOMBIE(1)이 가장 심각 > SUSPECT(2) > SKIP(3) > OK(0).
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
