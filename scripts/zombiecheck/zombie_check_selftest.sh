#!/usr/bin/env bash
# =============================================================================
# zombie_check_selftest.sh — zombie_check.sh 내장 단위 테스트 (Phase 8-4 분리)
#
# 배경: zombie_check.sh 본체 455줄 중 self-test부가 233줄(51%)을 차지해 500줄
#       한도를 위협했다(L-2/A-1/N-1 추가 시 초과 확정, Team Lead 사전 승인 분리).
#       본체는 `--self-test` 인자를 받으면 이 파일을 exec 로 위임한다 — 호출법
#       (`bash zombie_check.sh --self-test`)·stdout·exit code 는 분리 전과 동일하다.
#
# A-2 안전: 이 파일은 zombie_check.sh 를 source 해 함수·상수(readonly 포함)를
#       가져온다. 이 파일이 항상 "자신만의 새 프로세스"로 실행되므로(exec 위임
#       또는 직접 실행) source 는 프로세스당 정확히 1회만 일어나 readonly 재선언
#       충돌이 발생하지 않는다. zombie_check.sh 를 다시 source 하는 코드를 이
#       파일 안에 추가하지 말 것.
#
# 구성: tmux 無 — 스텁4 + 실헬퍼3(대체 케이스 1건) + 회귀12(8-2분4 + 8-4분 신호원3[A1 스킵]
#       + 분리견고성2 + F-1분2 + 8-3분 P-1 1) = 19케이스
#       tmux 有 — 스텁4 + 실헬퍼4(pane_id·pane_tail 2건) + 회귀13(신호원4[A1 포함]) = 21케이스
#   스텁: 래퍼(_zc_find_pid 등)를 재정의해 조합 로직만 검증 (정상/좀비/의심/SKIP)
#   실헬퍼: _real 구현을 직접 호출해 실제 시스템(ps/date/tmux) 위에서 헬퍼 자체를 검증 (KPI-03)
#   회귀: 스크립트 자신을 서브프로세스로 재호출해 과거 결함 재발을 방지
# 전건 PASS → exit 0 / 하나라도 실패 → exit 1
# =============================================================================

set -euo pipefail

SELFTEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=zombie_check.sh
source "${SELFTEST_DIR}/zombie_check.sh"

_zc_selftest_run_case() {
  local case_name="$1" expected="$2"
  local rc=0
  local output
  output="$(zombie_check "selftest-agent" "selftest-team" 2>&1)" || rc=$?
  if [[ "$rc" -eq "$expected" ]]; then
    echo "  [PASS] ${case_name} (exit=${rc}, expected=${expected}) — ${output}"
    return 0
  else
    echo "  [FAIL] ${case_name} (exit=${rc}, expected=${expected}) — ${output}"
    return 1
  fi
}

zombie_check_self_test() {
  local fail_count=0
  # G-1(verifier 8-4 G2 재검증 지적): fail_count==0 만으로는 "실패 없음"만 보장하고
  # "충분히 실행했음"은 보장하지 않는다 — F-1이 케이스 블록을 통째로 건너뛰면서도
  # fail_count=0인 채 "전건 PASS"를 위조할 수 있었던 근본 원인이다. 각 케이스가
  # 실제로 도달했는지를 case_count 로 별도 집계해 하한 미달을 자동 FAIL 처리한다.
  local case_count=0
  # 기대 케이스 수는 tmux 미설치 19(8-4 실측 18 + Phase 8-3 회귀-P1 1) / tmux 설치 21
  # (8-4 실측 20 + 1)이며, 하한이 아니라 **정확 일치**로 끝부분(§G-1 재확인부)에서 검증한다
  # — 회귀-P1의 nested 오염 시나리오(정확히 1건만 누락)를 하한 방식이 못 잡기 때문
  # (8-4 verifier P-2와 동일 구조, 상세는 §G-1 재확인부 주석).
  # 회귀 케이스가 본체를 서브프로세스로 재호출할 때 쓸 절대경로 (CWD 무관하게 안전)
  local self_path="${SELFTEST_DIR}/zombie_check.sh"

  echo "zombie_check.sh --self-test 시작"
  echo ""
  echo "=== 스텁 케이스 (조합 로직 검증) ==="

  # 케이스 1/3은 mtime_unavailable(=신호원 실존 여부)이 실제 파일시스템을 보므로
  # (H-1 수정으로 mtime_unavailable=true면 SUSPECT 판정 자체를 건너뜀), _zc_mtime/_zc_now
  # 스텁이 의미를 가지려면 신호원이 실제로 존재해야 한다 — 더미 HOME에 inbox+config 둘 다 만든다
  # (L-2: inbox 우선 순위 검증 겸용).
  local combo_home
  combo_home="$(mktemp -d)"
  mkdir -p "$combo_home/.claude/teams/selftest-team/inboxes"
  printf '{}' > "$combo_home/.claude/teams/selftest-team/config.json"
  printf '[]' > "$combo_home/.claude/teams/selftest-team/inboxes/selftest-agent.json"

  # --- 케이스 1: 정상 (프로세스 존재 + pane 정상 + idle 짧음) ---
  case_count=$((case_count + 1))
  _zc_find_pid() { printf '12345'; }
  _zc_pane_id() { printf 'pane-1'; }
  _zc_resolve_socket() { printf 'stub-socket'; }
  _zc_pane_tail() { printf '작업 진행 중...'; }
  _zc_mtime() { printf '1000'; }
  _zc_now() { printf '1050'; }   # diff=50s < 180s
  HOME="$combo_home" _zc_selftest_run_case "[스텁] 정상 케이스 (OK)" "$EXIT_OK" || fail_count=$((fail_count + 1))

  # --- 케이스 2: 좀비 확정 (프로세스 부재 — 시그널 #1 단독) ---
  case_count=$((case_count + 1))
  _zc_find_pid() { printf ''; }
  _zc_pane_id() { printf ''; }
  _zc_pane_tail() { printf ''; }
  _zc_mtime() { printf '1000'; }
  _zc_now() { printf '1010'; }
  _zc_selftest_run_case "[스텁] 좀비 케이스 (프로세스 부재)" "$EXIT_ZOMBIE" || fail_count=$((fail_count + 1))

  # --- 케이스 3: 추정 좀비 (프로세스 존재 + pane 조회 불가 + idle 초과, D2=180초) ---
  case_count=$((case_count + 1))
  _zc_find_pid() { printf '54321'; }
  _zc_pane_id() { printf ''; }
  _zc_pane_tail() { printf ''; }
  _zc_mtime() { printf '1000'; }
  _zc_now() { printf '1300'; }   # diff=300s > 180s
  HOME="$combo_home" _zc_selftest_run_case "[스텁] 의심 케이스 (idle TTL 초과)" "$EXIT_SUSPECT" || fail_count=$((fail_count + 1))
  rm -rf "$combo_home"

  # --- 케이스 4: SKIP (시그널 #1 UNAVAILABLE + tmux/config 전부 조회 불가) ---
  case_count=$((case_count + 1))
  _zc_find_pid() { printf 'UNAVAILABLE'; }
  _zc_pane_id() { printf ''; }
  _zc_pane_tail() { printf ''; }
  _zc_mtime() { printf '0'; }
  _zc_now() { printf '1010'; }
  local fake_home
  fake_home="$(mktemp -d)"
  HOME="$fake_home" PATH="/nonexistent-selftest-path" _zc_selftest_run_case "[스텁] SKIP 케이스 (전 시그널 unavailable)" "$EXIT_SKIP" || fail_count=$((fail_count + 1))
  rmdir "$fake_home" 2>/dev/null || true

  echo ""
  echo "=== 실헬퍼 케이스 (_real 구현 직접 호출 — 실제 시스템 위에서 실행, KPI-03) ==="

  # --- 실헬퍼 1: _zc_mtime_real — 실제 임시파일 mtime을 date -r 로 실측, ±2초 이내 일치 검증 ---
  case_count=$((case_count + 1))
  local rh1_tmp rh1_expected rh1_actual rh1_diff
  rh1_tmp="$(mktemp)"
  rh1_expected="$(date +%s)"
  rh1_actual="$(_zc_mtime_real "$rh1_tmp")"
  rm -f "$rh1_tmp"
  rh1_diff=$(( rh1_expected - rh1_actual ))
  if (( rh1_diff < 0 )); then rh1_diff=$(( -rh1_diff )); fi
  if (( rh1_diff <= 2 )); then
    echo "  [PASS] [실헬퍼] _zc_mtime_real 실제 파일 조회 (diff=${rh1_diff}s)"
  else
    echo "  [FAIL] [실헬퍼] _zc_mtime_real 실제 파일 조회 (diff=${rh1_diff}s, 기대 <=2s)"
    fail_count=$((fail_count + 1))
  fi

  # --- 실헬퍼 2: _zc_find_pid_real — 실제 백그라운드 프로세스를 ps로 실측 검출 ---
  case_count=$((case_count + 1))
  local rh2_marker="agent-id selftest-real@selftest-team"
  bash -c "exec -a '${rh2_marker}' sleep 5" &
  local rh2_bgpid=$!
  sleep 0.3
  local rh2_found
  rh2_found="$(_zc_find_pid_real "selftest-real" "selftest-team")"
  kill "$rh2_bgpid" 2>/dev/null || true
  wait "$rh2_bgpid" 2>/dev/null || true
  if [[ "$rh2_found" =~ ^[0-9]+$ ]]; then
    echo "  [PASS] [실헬퍼] _zc_find_pid_real 실제 프로세스 검출 (pid=${rh2_found})"
  else
    echo "  [FAIL] [실헬퍼] _zc_find_pid_real 실제 프로세스 검출 (got='${rh2_found}')"
    fail_count=$((fail_count + 1))
  fi

  # --- 실헬퍼 3/4: _zc_pane_id_real / _zc_pane_tail_real — tmux 있으면 실세션, 없으면 SKIP 정상 처리로 대체 ---
  if command -v tmux >/dev/null 2>&1; then
    case_count=$((case_count + 2))   # 이 분기는 PASS/FAIL 판정이 2건(pane_id, pane_tail)
    local rh34_sess="zc-selftest-$$"
    local rh34_sock="claude-swarm-selftest-$$"
    local rh34_cfg rh34_paneid
    rh34_cfg="$(mktemp)"
    tmux -L "$rh34_sock" new-session -d -s "$rh34_sess" 2>/dev/null || true
    rh34_paneid="$(tmux -L "$rh34_sock" list-panes -t "$rh34_sess" -F '#{pane_id}' 2>/dev/null | head -n1)" || true
    printf '{"members":[{"name":"selftest-real","tmuxPaneId":"%s"}]}' "$rh34_paneid" > "$rh34_cfg"

    local rh34_lookup
    rh34_lookup="$(_zc_pane_id_real "selftest-real" "$rh34_cfg")"
    if [[ -n "$rh34_lookup" && "$rh34_lookup" == "$rh34_paneid" ]]; then
      echo "  [PASS] [실헬퍼] _zc_pane_id_real 실 tmux 세션 조회 (pane=${rh34_lookup})"
    else
      echo "  [FAIL] [실헬퍼] _zc_pane_id_real 실 tmux 세션 조회 (got='${rh34_lookup}', expected='${rh34_paneid}')"
      fail_count=$((fail_count + 1))
    fi

    local rh34_direct rh34_rc=0
    rh34_direct="$(tmux -L "$rh34_sock" capture-pane -t "$rh34_paneid" -p 2>/dev/null | tail -1)" || rh34_rc=$?
    if [[ "$rh34_rc" -eq 0 ]]; then
      echo "  [PASS] [실헬퍼] _zc_pane_tail_real 계열 capture-pane 실행 확인 (line='${rh34_direct}')"
    else
      echo "  [FAIL] [실헬퍼] _zc_pane_tail_real 계열 capture-pane 실행 실패"
      fail_count=$((fail_count + 1))
    fi

    tmux -L "$rh34_sock" kill-server 2>/dev/null || true
    rm -f "$rh34_cfg"
    rm -f "/tmp/tmux-$(id -u)/${rh34_sock}" 2>/dev/null || true
  else
    case_count=$((case_count + 1))   # 대체 케이스는 1건([실헬퍼 대체])
    _zc_find_pid() { printf 'UNAVAILABLE'; }
    _zc_pane_id() { printf ''; }
    _zc_pane_tail() { printf ''; }
    _zc_mtime() { printf '0'; }
    _zc_now() { printf '1010'; }
    local rh34_fakehome
    rh34_fakehome="$(mktemp -d)"
    HOME="$rh34_fakehome" _zc_selftest_run_case "[실헬퍼 대체] tmux 미설치 → SKIP 정상 처리" "$EXIT_SKIP" || fail_count=$((fail_count + 1))
    rmdir "$rh34_fakehome" 2>/dev/null || true
    echo "  [INFO] tmux 미설치 환경 — _zc_pane_id_real/_zc_pane_tail_real 실헬퍼는 SKIP 정상 처리 케이스로 대체됨"
  fi

  echo ""
  echo "=== 회귀 케이스 (Phase 8-2 AUTO_FIX — C-1/H-1/H-2/A-3 재발 방지) ==="

  # --- 회귀-C1: HOME 미설정 → unbound variable로 인한 오탐(exit 1) 재발 방지. 기대: exit 0 또는 3 ---
  case_count=$((case_count + 1))
  local c1_marker="agent-id selftest-reg-c1@selftest-team"
  bash -c "exec -a '${c1_marker}' sleep 5" &
  local c1_bgpid=$!
  sleep 0.3
  local c1_rc=0 c1_out
  c1_out="$(env -u HOME bash "$self_path" selftest-reg-c1 selftest-team 2>&1)" || c1_rc=$?
  kill "$c1_bgpid" 2>/dev/null || true
  wait "$c1_bgpid" 2>/dev/null || true
  if [[ "$c1_rc" -eq "$EXIT_OK" || "$c1_rc" -eq "$EXIT_SKIP" ]]; then
    echo "  [PASS] [회귀-C1] HOME 미설정 → exit=${c1_rc} (1 아님) — ${c1_out}"
  else
    echo "  [FAIL] [회귀-C1] HOME 미설정 → exit=${c1_rc} (기대: 0 또는 3) — ${c1_out}"
    fail_count=$((fail_count + 1))
  fi

  # --- 회귀-H1: config 부재 + 실 프로세스 존재 → 무조건 SUSPECT(2) 재발 방지. 기대: exit 0 ---
  case_count=$((case_count + 1))
  local h1_marker="agent-id selftest-reg-h1@selftest-team"
  bash -c "exec -a '${h1_marker}' sleep 5" &
  local h1_bgpid=$!
  sleep 0.3
  local h1_fakehome h1_rc=0 h1_out
  h1_fakehome="$(mktemp -d)"
  h1_out="$(HOME="$h1_fakehome" bash "$self_path" selftest-reg-h1 selftest-team 2>&1)" || h1_rc=$?
  kill "$h1_bgpid" 2>/dev/null || true
  wait "$h1_bgpid" 2>/dev/null || true
  rmdir "$h1_fakehome" 2>/dev/null || true
  if [[ "$h1_rc" -eq "$EXIT_OK" ]]; then
    echo "  [PASS] [회귀-H1] config 부재 + 실프로세스 → exit=0 (OK) — ${h1_out}"
  else
    echo "  [FAIL] [회귀-H1] config 부재 + 실프로세스 → exit=${h1_rc} (기대: 0) — ${h1_out}"
    fail_count=$((fail_count + 1))
  fi

  # --- 회귀-H2: date 명령 부재 → command-not-found(exit 127) 재발 방지. 기대: 0~3 범위 (127 아님) ---
  case_count=$((case_count + 1))
  local h2_marker="agent-id selftest-reg-h2@selftest-team"
  bash -c "exec -a '${h2_marker}' sleep 5" &
  local h2_bgpid=$!
  sleep 0.3
  local h2_home h2_bin h2_rc=0 h2_out
  h2_home="$(mktemp -d)"
  mkdir -p "$h2_home/.claude/teams/selftest-team"
  printf '{"members":[]}' > "$h2_home/.claude/teams/selftest-team/config.json"
  h2_bin="$(mktemp -d)"
  local tool tool_src h2_bash
  h2_bash="$(command -v bash)"
  for tool in ps grep awk head jq tmux; do
    tool_src="$(command -v "$tool" 2>/dev/null)" || continue
    ln -sf "$tool_src" "$h2_bin/$tool"
  done
  h2_out="$(HOME="$h2_home" PATH="$h2_bin" "$h2_bash" "$self_path" selftest-reg-h2 selftest-team 2>&1)" || h2_rc=$?
  kill "$h2_bgpid" 2>/dev/null || true
  wait "$h2_bgpid" 2>/dev/null || true
  rm -rf "$h2_home" "$h2_bin"
  if [[ "$h2_rc" -ge "$EXIT_OK" && "$h2_rc" -le "$EXIT_SKIP" ]]; then
    echo "  [PASS] [회귀-H2] date 부재 → exit=${h2_rc} (127 아님, 0~3 범위) — ${h2_out}"
  else
    echo "  [FAIL] [회귀-H2] date 부재 → exit=${h2_rc} (기대: 0~3) — ${h2_out}"
    fail_count=$((fail_count + 1))
  fi

  # --- 회귀-A3: 함수를 인자 없이 소싱-직접호출 시 unbound variable(exit 1) 재발 방지. 기대: exit 3 ---
  case_count=$((case_count + 1))
  local a3_rc=0 a3_out
  a3_out="$(bash -c "set -euo pipefail; source '${self_path}'; zombie_check" 2>&1)" || a3_rc=$?
  if [[ "$a3_rc" -eq "$EXIT_SKIP" ]]; then
    echo "  [PASS] [회귀-A3] 인자 없이 함수 직접 호출 → exit=3 (SKIP) — ${a3_out}"
  else
    echo "  [FAIL] [회귀-A3] 인자 없이 함수 직접 호출 → exit=${a3_rc} (기대: 3) — ${a3_out}"
    fail_count=$((fail_count + 1))
  fi

  echo ""
  echo "=== 회귀 케이스 (Phase 8-4 — L-2/A-1/N-1 재발 방지) ==="

  # --- 회귀-L2: config.json은 오래됐고 inbox만 신선 → inbox 우선 신호원으로 OK. 기대: exit 0 ---
  case_count=$((case_count + 1))
  local l2_marker="agent-id selftest-reg-l2@selftest-team"
  bash -c "exec -a '${l2_marker}' sleep 5" &
  local l2_bgpid=$!
  sleep 0.3
  local l2_home l2_rc=0 l2_out
  l2_home="$(mktemp -d)"
  mkdir -p "$l2_home/.claude/teams/selftest-team/inboxes"
  printf '{"members":[]}' > "$l2_home/.claude/teams/selftest-team/config.json"
  touch -t 202601010000 "$l2_home/.claude/teams/selftest-team/config.json"
  printf '[]' > "$l2_home/.claude/teams/selftest-team/inboxes/selftest-reg-l2.json"
  l2_out="$(HOME="$l2_home" bash "$self_path" selftest-reg-l2 selftest-team 2>&1)" || l2_rc=$?
  kill "$l2_bgpid" 2>/dev/null || true
  wait "$l2_bgpid" 2>/dev/null || true
  rm -rf "$l2_home"
  if [[ "$l2_rc" -eq "$EXIT_OK" ]]; then
    echo "  [PASS] [회귀-L2] config 오래됨 + inbox 신선 → exit=0 (inbox 우선 신호원) — ${l2_out}"
  else
    echo "  [FAIL] [회귀-L2] config 오래됨 + inbox 신선 → exit=${l2_rc} (기대: 0) — ${l2_out}"
    fail_count=$((fail_count + 1))
  fi

  # --- 회귀-A1: ppid 체인 소켓 해소 실증 — 실제 tmux 세션 안에서 기동한 프로세스로 검증 ---
  if command -v tmux >/dev/null 2>&1; then
    case_count=$((case_count + 1))
    local a1_sock="claude-swarm-selftest-a1-$$"
    local a1_sess="zc-a1-$$"
    tmux -L "$a1_sock" new-session -d -s "$a1_sess" -- sleep 10 2>/dev/null || true
    sleep 0.3
    local a1_target_pid
    a1_target_pid="$(tmux -L "$a1_sock" list-panes -t "$a1_sess" -F '#{pane_pid}' 2>/dev/null | head -n1)"
    local a1_resolved
    a1_resolved="$(_zc_resolve_socket_real "$a1_target_pid")"
    if [[ "$a1_resolved" == "$a1_sock" ]]; then
      echo "  [PASS] [회귀-A1] ppid 체인 소켓 해소 (pid=${a1_target_pid} → socket=${a1_resolved})"
    else
      echo "  [FAIL] [회귀-A1] ppid 체인 소켓 해소 (pid=${a1_target_pid} → got='${a1_resolved}', expected='${a1_sock}')"
      fail_count=$((fail_count + 1))
    fi
    tmux -L "$a1_sock" kill-server 2>/dev/null || true
    rm -f "/tmp/tmux-$(id -u)/${a1_sock}" 2>/dev/null || true
  else
    echo "  [INFO] tmux 미설치 환경 — 회귀-A1(소켓 해소) 스킵, N-1 SKIP 경로로 흡수됨"
  fi

  # --- 회귀-A1b: 유령 소켓(파일만 있고 서버 없음) 생존 오판정 방지 ---
  case_count=$((case_count + 1))
  local a1b_ghost_sock="claude-swarm-selftest-ghost-$$"
  : > "/tmp/tmux-$(id -u)/${a1b_ghost_sock}" 2>/dev/null || true
  if tmux -L "$a1b_ghost_sock" list-sessions >/dev/null 2>&1; then
    echo "  [FAIL] [회귀-A1b] 유령 소켓이 생존으로 오판정됨"
    fail_count=$((fail_count + 1))
  else
    echo "  [PASS] [회귀-A1b] 유령 소켓 생존 확인 거부 정상 (list-sessions 실패)"
  fi
  rm -f "/tmp/tmux-$(id -u)/${a1b_ghost_sock}" 2>/dev/null || true

  # --- 회귀-N1: 신호원 파일 존재하나 읽기 실패(date 부재) + ps/tmux 도 불가 → SKIP(3) 재발 방지 ---
  case_count=$((case_count + 1))
  local n1_home n1_bin n1_bash n1_rc=0 n1_out
  n1_home="$(mktemp -d)"
  mkdir -p "$n1_home/.claude/teams/selftest-team"
  printf '{"members":[]}' > "$n1_home/.claude/teams/selftest-team/config.json"
  n1_bin="$(mktemp -d)"
  n1_bash="$(command -v bash)"
  local n1_tool n1_src
  for n1_tool in grep awk head; do
    n1_src="$(command -v "$n1_tool" 2>/dev/null)" || continue
    ln -sf "$n1_src" "$n1_bin/$n1_tool"
  done
  n1_out="$(HOME="$n1_home" PATH="$n1_bin" "$n1_bash" "$self_path" selftest-reg-n1 selftest-team 2>&1)" || n1_rc=$?
  rm -rf "$n1_home" "$n1_bin"
  if [[ "$n1_rc" -eq "$EXIT_SKIP" ]]; then
    echo "  [PASS] [회귀-N1] 파일 존재+읽기 실패 전 시그널 불가 → exit=3 (SKIP) — ${n1_out}"
  else
    echo "  [FAIL] [회귀-N1] 파일 존재+읽기 실패 전 시그널 불가 → exit=${n1_rc} (기대: 3) — ${n1_out}"
    fail_count=$((fail_count + 1))
  fi

  echo ""
  echo "=== 회귀 케이스 (Phase 8-4 — self-test 파일 분리 자체의 견고성) ==="

  # --- 회귀-A2: 동일 프로세스에서 zombie_check.sh 를 2회 source 해도 readonly 재선언 충돌 없음 ---
  case_count=$((case_count + 1))
  local a2_rc=0 a2_out
  a2_out="$(bash -c "set -euo pipefail; source '${self_path}'; source '${self_path}'; echo OK" 2>&1)" || a2_rc=$?
  if [[ "$a2_rc" -eq 0 && "$a2_out" == "OK" ]]; then
    echo "  [PASS] [회귀-A2] zombie_check.sh 2회 source → readonly 충돌 없음"
  else
    echo "  [FAIL] [회귀-A2] zombie_check.sh 2회 source → rc=${a2_rc}, out='${a2_out}' (기대: rc=0, out=OK)"
    fail_count=$((fail_count + 1))
  fi

  # --- 회귀-분리파일부재: zombie_check_selftest.sh 없이 --self-test 실행 → exit 3 (126/127 아님) ---
  case_count=$((case_count + 1))
  local missing_dir missing_rc=0 missing_out
  missing_dir="$(mktemp -d)"
  cp "$self_path" "$missing_dir/"
  missing_out="$(bash "$missing_dir/zombie_check.sh" --self-test 2>&1)" || missing_rc=$?
  rm -rf "$missing_dir"
  if [[ "$missing_rc" -eq "$EXIT_SKIP" ]]; then
    echo "  [PASS] [회귀-분리파일부재] zombie_check_selftest.sh 없음 → exit=3 (SKIP, 126/127 아님)"
  else
    echo "  [FAIL] [회귀-분리파일부재] zombie_check_selftest.sh 없음 → exit=${missing_rc} (기대: 3) — ${missing_out}"
    fail_count=$((fail_count + 1))
  fi

  echo ""
  echo "=== 회귀 케이스 (F-1 — A-2 가드 오염으로 인한 exit 0 위조 재발 방지) ==="

  # --- 회귀-F1a: _ZC_SOURCED류 환경변수 오염 + 직접 실행(죽은 에이전트) → exit 1 (0 아님) ---
  # 실제 마커는 declare -p EXIT_OK 로 대체됐지만, 과거 마커 이름을 주입해도 더 이상
  # 영향을 주지 않아야 한다는 것 자체가 회귀 방지 포인트다.
  case_count=$((case_count + 1))
  local f1a_rc=0 f1a_out
  f1a_out="$(_ZC_SOURCED=1 bash "$self_path" nonexistent-f1a-agent nonexistent-f1a-team 2>&1)" || f1a_rc=$?
  if [[ "$f1a_rc" -eq "$EXIT_ZOMBIE" ]]; then
    echo "  [PASS] [회귀-F1a] 환경변수 오염 + 직접실행(죽은 에이전트) → exit=1 (0 아님) — ${f1a_out}"
  else
    echo "  [FAIL] [회귀-F1a] 환경변수 오염 + 직접실행(죽은 에이전트) → exit=${f1a_rc} (기대: 1) — ${f1a_out}"
    fail_count=$((fail_count + 1))
  fi

  # --- 회귀-F1c: `set -a; source` 로 오염이 자식 프로세스까지 전파돼도 정상 진단 → exit 1 ---
  case_count=$((case_count + 1))
  local f1c_rc=0 f1c_out
  f1c_out="$(bash -c "set -a; source '${self_path}'; bash '${self_path}' nonexistent-f1c-agent nonexistent-f1c-team" 2>&1)" || f1c_rc=$?
  if [[ "$f1c_rc" -eq "$EXIT_ZOMBIE" ]]; then
    echo "  [PASS] [회귀-F1c] set -a 오염 전파 후 자식 프로세스(죽은 에이전트) → exit=1 (0 아님) — ${f1c_out}"
  else
    echo "  [FAIL] [회귀-F1c] set -a 오염 전파 후 자식 프로세스(죽은 에이전트) → exit=${f1c_rc} (기대: 1) — ${f1c_out}"
    fail_count=$((fail_count + 1))
  fi

  # 회귀-F1b(오염 상태에서 --self-test 가 실제로 전건 실행되는지)는 이 self-test 자신이
  # 그 --self-test 이므로, 자동화 케이스로 넣으면 각 레벨마다 다시 자기 자신을 서브
  # 프로세스로 호출해 무한 재귀·프로세스 폭발이 된다. 수동 실증으로만 검증했다
  # (report-backend-dev.md 참조) — self-test 안에 넣지 않은 것은 누락이 아니라 의도.

  echo ""
  echo "=== 회귀 케이스 (P-1 — declare -F 가드 교체, EXIT_OK 이름 충돌 면역 확인, Phase 8-3) ==="

  # --- 회귀-P1: EXIT_OK 사전 export(이름 충돌) 상태에서 --self-test 정상 실행 (P-1 해소) ---
  # F1b 와 같은 무한재귀 함정을 피하려 _ZC_SELFTEST_P1_NESTED 로 재귀 1단만 허용했으나
  # (env 로 readonly 충돌 우회, 상세: report-backend-dev.md §P-1), 마커만 신뢰하면
  # leak 시(예: 마커를 직접 export 하고 --self-test 실행) 검증 없이 [PASS] 위조가
  # 가능했다(F-1과 동일 계열, Team Lead 8-3 지적). case_count 미증가 + 하한 완화만으로는
  # legitimate nested 와 오염을 구분 못 함을 실측 확인(둘 다 case_count 동일) → **마커가
  # 아니라 사실(부모 프로세스가 실제 zombie_check_selftest.sh 인지 ps 로 확인, A-1과 같은
  # 원칙)로 판정**한다. 사실 확인된 nested 만 재호출 생략(case_count 미증가), 마커뿐이면
  # case_count 증가 + 명시적 FAIL(오염이 조용히 지나가지 않게).
  local _p1_nested_verified=false
  if [[ -n "${_ZC_SELFTEST_P1_NESTED:-}" ]]; then
    local _p1_parent_cmd
    _p1_parent_cmd="$(ps -o command= -p "${PPID:-0}" 2>/dev/null)" || _p1_parent_cmd=""
    if [[ "$_p1_parent_cmd" == *zombie_check_selftest.sh* ]]; then
      _p1_nested_verified=true
    fi
  fi

  if [[ "$_p1_nested_verified" == true ]]; then
    echo "  [SKIP] [회귀-P1] (nested — 부모 프로세스가 zombie_check_selftest.sh 임을 ps 로 사실 확인, 무한재귀 방지로 재호출 생략, case_count 미증가)"
  else
    case_count=$((case_count + 1))
    if [[ -n "${_ZC_SELFTEST_P1_NESTED:-}" ]]; then
      # 마커는 있으나 부모 프로세스가 가짜 — 마커를 신뢰하지 않고 명시적으로 실패 처리
      echo "  [FAIL] [회귀-P1] _ZC_SELFTEST_P1_NESTED 마커 존재하나 부모 프로세스가 zombie_check_selftest.sh 아님(got='${_p1_parent_cmd}') — 마커 위조/leak 의심, 검증 거부"
      fail_count=$((fail_count + 1))
    else
      local p1_rc=0 p1_out
      p1_out="$(env EXIT_OK=0 _ZC_SELFTEST_P1_NESTED=1 bash "$self_path" --self-test 2>&1)" || p1_rc=$?
      if [[ "$p1_rc" -eq 0 ]]; then
        echo "  [PASS] [회귀-P1] EXIT_OK 사전 export(이름 충돌) + --self-test → exit=0 정상 실행 (구가드였다면 exit=1)"
      else
        echo "  [FAIL] [회귀-P1] EXIT_OK 사전 export 상태에서 --self-test 실패 → exit=${p1_rc} (기대: 0) — ${p1_out}"
        fail_count=$((fail_count + 1))
      fi
    fi
  fi

  # nested(사실 확인됨) 자식은 case_count 가 정상치보다 1 적은 것이 의도된 정상 동작이므로
  # 기대치도 그만큼 낮춘다. 오염(마커뿐, 부모 가짜)은 이미 case_count 를 정상 증가시켰으므로 제외.
  local _p1_expected_adjust=0
  [[ "$_p1_nested_verified" == true ]] && _p1_expected_adjust=1

  # G-1: "실패 없음"만으로는 부족 — "충분히 실행했음"도 확인한다. 하한(≥) 대신 **정확
  # 일치**를 쓰는 이유: tmux 유무로 정상 케이스 수가 갈리므로(19/21), 하한만으로는
  # "정확히 1건 누락"을 못 잡는다(8-4 verifier P-2 와 동일 구조 — 본 교체가 조기 해소).
  local expected_cases=19
  command -v tmux >/dev/null 2>&1 && expected_cases=21
  expected_cases=$((expected_cases - _p1_expected_adjust))
  if (( case_count != expected_cases )); then
    local _p1_note=""
    [[ "$_p1_nested_verified" == true ]] && _p1_note=", nested 확인됨 -1 반영"
    echo "  [FAIL] 실행 케이스 ${case_count}건 ≠ 기대 ${expected_cases}건(tmux $(command -v tmux >/dev/null 2>&1 && echo 있음 || echo 없음)${_p1_note}) — 케이스 누락/추가 의심"
    fail_count=$((fail_count + 1))
  fi

  echo ""
  if [[ "$fail_count" -eq 0 ]]; then
    echo "zombie_check.sh --self-test 전건 PASS (${case_count}/${case_count})"
    return "$EXIT_OK"
  else
    echo "zombie_check.sh --self-test 실패 (${fail_count}건, 실행 ${case_count}건)"
    return 1
  fi
}

zombie_check_self_test
exit $?
