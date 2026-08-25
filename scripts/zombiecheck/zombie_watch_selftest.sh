#!/usr/bin/env bash
# =============================================================================
# zombie_watch_selftest.sh — zombie_watch.sh 내장 단위 테스트 (Phase 8-3 분리)
#
# 배경: zombie_watch.sh 본체가 self-test 를 포함하면 570줄로 500줄 한도(REFACTOR-1)를
#       초과한다(self-test 부가 176줄, 본체의 31%). zombie_check.sh/zombie_check_selftest.sh
#       분리 선례(Phase 8-4, Team Lead 사전 승인)를 그대로 준용한다 — 본체는 `--self-test`
#       인자를 받으면 이 파일을 exec 로 위임한다. 호출법(`bash zombie_watch.sh --self-test`)·
#       stdout·exit code 는 분리 전과 동일하다.
#
# 이 파일은 zombie_watch.sh 를 source 해 함수를 가져온다. zombie_watch.sh 는 readonly
# 상수를 쓰지 않으므로(모든 _ZW_* 는 일반 대입) zombie_check.sh 의 A-2(readonly 재선언
# 충돌) 문제가 애초에 없다 — 그래도 이 파일은 항상 자신만의 새 프로세스로 실행되므로
# (exec 위임 또는 직접 실행) source 는 프로세스당 정확히 1회만 일어난다.
#
# 구성(Phase 8-6 갱신, expected_cases 로 정확 일치 검사): arm 3단 3종 + emit edge-triggered
#       4종 + 억제 게이트 3종 + respawn 무효화 1종 + 해시 메모리 보관 1종 + D-1 필터 1종
#       + D-3 rc 계약 5종 + R2-5 2종 + R2-1 2종 + D-2/D-7 회귀 2종 + R-14 대조군(S3~S6) 4종
#       + T-1 회귀 1종 = 29케이스. T-2(D8-2, Phase 8-6): 케이스[18]이 원함수를 stub 했다가
#       종료 시 반드시 복원한다 — 복원 누락 시 이후 케이스가 no-op 을 물려받아 무조건 통과한다.
#       전건 PASS → exit 0 / 하나라도 실패(케이스 수 불일치 포함) → exit 1
#
# 분리(Phase 9-3-1, 498/500 한도 여유 2): "D-2/D-7 회귀"·"R-14 회귀"·"T-1 회귀" 3개 절(원문
#       section 제목 자체가 "회귀") — 케이스 [20]~[26] 7종 — 을 zombie_watch_selftest_regression.sh
#       로 이관했다(source 전용, _zw_self_test() 본문 안에서 로드). source 는 새 함수 스코프를
#       만들지 않으므로 case_count/fail_count 등 이 함수의 지역변수가 인라인 배치와 완전히
#       동치로 공유·갱신된다. 이관 구간은 원본 L368~478 과 바이트 동일(diff exit 0 + md5 대조,
#       9-1 zombie_watch_lib.sh/poll.sh 분리 방식 준용). 케이스 추가·삭제 없음, expected_cases=29 불변.
# =============================================================================

set -euo pipefail

SELFTEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=zombie_watch.sh
source "${SELFTEST_DIR}/zombie_watch.sh"

_zw_self_test() {
  local case_count=0 fail_count=0

  echo "zombie_watch.sh --self-test 시작"
  echo ""
  echo "=== arm 판정 3단 ==="

  # [1] 유령 마커 (PID 사망) → 미arm
  case_count=$((case_count + 1))
  ( sleep 0.1 ) & local ghost_pid=$!
  wait "$ghost_pid" 2>/dev/null || true
  local t1_dir; t1_dir="$(mktemp -d)"
  _ZW_MARKER_DIR="$t1_dir"; echo "$ghost_pid" > "$(_zw_marker_file "ghost-team")"
  if _zw_is_armed "ghost-team" >/dev/null 2>&1; then
    echo "  [FAIL] [1] 유령 마커(PID 사망)가 arm 으로 오판정됨"; fail_count=$((fail_count + 1))
  else
    echo "  [PASS] [1] 유령 마커(PID 사망) → 미arm"
  fi
  rm -rf "$t1_dir"

  # [2] PID 재사용(명령줄 불일치) → 미arm
  case_count=$((case_count + 1))
  local t2_dir; t2_dir="$(mktemp -d)"
  ( sleep 5 ) & local other_pid=$!
  _ZW_MARKER_DIR="$t2_dir"; echo "$other_pid" > "$(_zw_marker_file "reuse-team")"
  if _zw_is_armed "reuse-team" >/dev/null 2>&1; then
    echo "  [FAIL] [2] 명령줄이 다른 PID 가 arm 으로 오판정됨"; fail_count=$((fail_count + 1))
  else
    echo "  [PASS] [2] PID 재사용(명령줄 불일치) → 미arm"
  fi
  kill "$other_pid" 2>/dev/null || true; wait "$other_pid" 2>/dev/null || true
  rm -rf "$t2_dir"

  # [3] 정상 마커(3단 전부 통과, 팀명 일치) → arm 확인 (양성 대조. D-2: 팀명까지 대조하므로
  #     exec -a 인자의 팀명은 마커의 팀명("ok-team")과 일치해야 한다)
  case_count=$((case_count + 1))
  local t3_dir; t3_dir="$(mktemp -d)"
  bash -c "exec -a 'zombie_watch.sh --_loop-internal ok-team' sleep 5" & local ok_pid=$!
  sleep 0.2
  _ZW_MARKER_DIR="$t3_dir"; echo "$ok_pid" > "$(_zw_marker_file "ok-team")"
  local armed_pid
  if armed_pid="$(_zw_is_armed "ok-team")" && [[ "$armed_pid" == "$ok_pid" ]]; then
    echo "  [PASS] [3] 정상 마커(3단 통과) → arm 확인 (pid=${armed_pid})"
  else
    echo "  [FAIL] [3] 정상 마커가 arm 으로 판정되지 않음"; fail_count=$((fail_count + 1))
  fi
  kill "$ok_pid" 2>/dev/null || true; wait "$ok_pid" 2>/dev/null || true
  rm -rf "$t3_dir"
  _ZW_MARKER_DIR="/tmp/zombie-watch-markers"

  echo ""
  echo "=== emit edge-triggered (§2.3) ==="
  local st_dir; st_dir="$(mktemp -d)"
  _ZW_STATE_ROOT="$st_dir"

  # [4] 기동 시 1회 무조건 emit (OK 여도)
  case_count=$((case_count + 1))
  _zw_invoke_zc() { echo "OK: stub (pid=1)"; return 0; }
  local out4; out4="$(_zw_check_one "emit-team" "agentA" true)" || true
  if [[ -n "$out4" ]]; then
    echo "  [PASS] [4] 기동 시 1회 emit — '${out4}'"
  else
    echo "  [FAIL] [4] 기동 시 emit 누락"; fail_count=$((fail_count + 1))
  fi

  # [5] OK → OK 연속 → 무출력 + rc=0 동시 확인 (R2-4: 무출력만으로는 정상 억제와 중도 사망을
  #     구분할 수 없다 — 정상 종료(rc=0)까지 함께 단언해야 맹점이 닫힌다)
  case_count=$((case_count + 1))
  local out5 rc5=0; out5="$(_zw_check_one "emit-team" "agentA" false)" || rc5=$?
  if [[ -z "$out5" && "$rc5" -eq 0 ]]; then
    echo "  [PASS] [5] OK 연속 2회차 무출력 + rc=0(정상 종료, 중도 사망 아님)"
  else
    echo "  [FAIL] [5] 기대 무출력+rc=0, 실제 출력='${out5}' rc=${rc5}"; fail_count=$((fail_count + 1))
  fi

  # [6] 상태 변화(OK→SUSPECT) → 1줄 emit + SUSPECT 문구 정확히 일치
  case_count=$((case_count + 1))
  _zw_invoke_zc() { echo "ZOMBIE-SUSPECT: agentA (idle 245s >= 180s, wake-up 권장)"; return 2; }
  _zw_pane_id() { printf ''; }   # 억제 게이트 unavailable 강제 → 원 판정(SUSPECT) 유지
  local out6; out6="$(_zw_check_one "emit-team" "agentA" false)" || true
  local expect6="확인 필요: agentA 통신 245초 무 (wake-up 1회 권장, respawn 아님)"
  if [[ "$out6" == "$expect6" ]]; then
    echo "  [PASS] [6] 상태 변화 emit + SUSPECT 문구 정확 일치 — '${out6}'"
  else
    echo "  [FAIL] [6] 기대='${expect6}' 실제='${out6}'"; fail_count=$((fail_count + 1))
  fi

  # [7] ZOMBIE 는 상태 불변이어도 매 사이클 emit
  case_count=$((case_count + 1))
  _zw_invoke_zc() { echo "ZOMBIE-CONFIRMED: agentB (no claude.exe process)"; return 1; }
  _zw_check_one "zteam" "agentB" true >/dev/null || true
  local out7; out7="$(_zw_check_one "zteam" "agentB" false)" || true
  if [[ -n "$out7" ]]; then
    echo "  [PASS] [7] ZOMBIE 상시 emit(2회차도 출력) — '${out7}'"
  else
    echo "  [FAIL] [7] ZOMBIE 2회차 무출력(상시 emit 위반)"; fail_count=$((fail_count + 1))
  fi

  echo ""
  echo "=== 억제 게이트 — 진행 신호 (decision rev.2 §3, 채택 조건 1) ==="

  # [8] inbox stale + 해시 변화 → SUSPECT 취소 (조건 1 실증)
  case_count=$((case_count + 1))
  local -a _zw_hash_store=()
  _zw_pane_id() { printf 'pane-X'; }
  _zw_find_pid() { printf '12345'; }
  _zw_resolve_socket() { printf 'sock-X'; }
  local _t8_hash="hashA"
  _zw_pane_hash() { printf '%s' "$_t8_hash"; }
  _zw_suppress_check "team1" "agentX" && { echo "  [FAIL] [8-사전] 최초 관측인데 억제됨(기준 없음이어야 함)"; fail_count=$((fail_count + 1)); }
  _t8_hash="hashB"
  if _zw_suppress_check "team1" "agentX"; then
    echo "  [PASS] [8] 해시 변화 → 억제(SUSPECT 취소) 확인 (조건 1)"
  else
    echo "  [FAIL] [8] 해시 변화했는데 억제되지 않음"; fail_count=$((fail_count + 1))
  fi

  # [9] 대조군 — 해시 불변 → 미억제(SUSPECT 유지)
  case_count=$((case_count + 1))
  _t8_hash="hashC"
  _zw_suppress_check "team1" "agentY" || true   # 최초 관측, 기준 저장
  _t8_hash="hashC"
  if _zw_suppress_check "team1" "agentY"; then
    echo "  [FAIL] [9] 해시 불변인데 억제됨(오탐 위험)"; fail_count=$((fail_count + 1))
  else
    echo "  [PASS] [9] 해시 불변 → 미억제(SUSPECT 유지) 확인 (대조군)"
  fi

  # [10] config/jq 불가 → 게이트 unavailable → 원 판정 유지 (§2.4 (f))
  case_count=$((case_count + 1))
  _zw_pane_id() { printf ''; }
  if _zw_suppress_check "team1" "agentW"; then
    echo "  [FAIL] [10] pane_id 조회 불가인데 억제됨"; fail_count=$((fail_count + 1))
  else
    echo "  [PASS] [10] config/jq 불가 → 게이트 unavailable, 원 판정 유지"
  fi

  echo ""
  echo "=== respawn 시 해시 무효화 (채택 조건 4) ==="

  # [11] pane_id 변경(respawn 모사) → 낡은 해시가 새 pane 과 비교되지 않음
  case_count=$((case_count + 1))
  _zw_pane_id() { printf 'pane-OLD'; }
  _t8_hash="OLD-CONTENT-HASH"
  _zw_suppress_check "team1" "agentZ" || true         # (agentZ,pane-OLD) 기준 저장
  _zw_pane_id() { printf 'pane-NEW'; }                # respawn: 새 pane_id
  _t8_hash="NEW-CONTENT-HASH"                          # 새 pane 의 실제 내용(당연히 다름)
  if _zw_suppress_check "team1" "agentZ"; then
    echo "  [FAIL] [11] respawn 직후 낡은 해시로 오억제됨 — 좀비 영구 미탐 위험(누락 A 재발)"
    fail_count=$((fail_count + 1))
  else
    echo "  [PASS] [11] respawn 후 새 pane_id → 낡은 해시 무효(비교 기준 없음) 확인 (조건 4)"
  fi

  echo ""
  echo "=== 해시 메모리 보관 (채택 조건 2) ==="

  # [12] 억제 게이트 동작 중 /tmp 에 해시 파일이 생성되지 않았는지 확인
  case_count=$((case_count + 1))
  local hash_files
  # T-1(High, Phase 8-6, tester 8-6 발견): Linux systemd 는 /tmp 에 권한 거부 디렉터리
  # (systemd-private-*, snap-private-tmp 등)를 둔다. find 가 그런 디렉터리를 만나면 stderr는
  # 2>/dev/null 로 삼켜지지만 find 자신의 종료코드는 1이 되고, set -o pipefail(zombie_watch.sh
  # 상속)로 파이프라인 전체가 실패해 set -e 가 self-test 를 무설명 중단시킨다(macOS 에는 이런
  # 보호 디렉터리가 없어 재현되지 않았다). 매치된 파일 수(stdout)는 오류와 무관하게 정확하므로
  # `|| true` 로 종료코드만 무시한다 — 값 정확성은 실측으로 확인됨(권한 거부 디렉터리 존재 시에도
  # 실 매치 카운트가 그대로 나옴).
  hash_files="$(find /tmp -maxdepth 3 -iname '*hash*' -newer "$st_dir" 2>/dev/null | wc -l | tr -d ' ' || true)"
  if [[ "$hash_files" == "0" ]]; then
    echo "  [PASS] [12] 해시 파일 쓰기 0건(메모리 전용 보관 확인)"
  else
    echo "  [FAIL] [12] 해시로 추정되는 파일 ${hash_files}건 발견"; fail_count=$((fail_count + 1))
  fi

  rm -rf "$st_dir"
  _ZW_STATE_ROOT="/tmp/zombie-watch-state"

  echo ""
  echo "=== 팀원 목록 필터 (D-1 AUTO_FIX — team-lead 상시 ZOMBIE 오탐 방지) ==="

  # [13] team-lead(비-%N pane) 는 폴링 대상에서 제외, 실 pane 보유 멤버만 포함
  case_count=$((case_count + 1))
  local d1_cfg d1_dir d1_agents
  d1_dir="$(mktemp -d)"
  d1_cfg="${d1_dir}/config.json"
  printf '{"members":[{"name":"team-lead","tmuxPaneId":"leader"},{"name":"backend-dev-8-3","tmuxPaneId":"%%6"},{"name":"verifier-8-3","tmuxPaneId":"%%7"}]}' > "$d1_cfg"
  d1_agents="$(jq -r '.members[]? | select(.tmuxPaneId // "" | test("^%[0-9]+$")) | .name' "$d1_cfg" 2>/dev/null)"
  rm -rf "$d1_dir"
  if [[ "$d1_agents" == *"team-lead"* ]]; then
    echo "  [FAIL] [13] team-lead(비-pane 멤버)가 목록에 포함됨 — D-1 재발"
    fail_count=$((fail_count + 1))
  elif [[ "$d1_agents" == *"backend-dev-8-3"* && "$d1_agents" == *"verifier-8-3"* ]]; then
    echo "  [PASS] [13] team-lead 제외 + 실 pane 보유 멤버(backend-dev-8-3, verifier-8-3) 포함 확인"
  else
    echo "  [FAIL] [13] 실 pane 보유 멤버가 누락됨(got='${d1_agents}')"
    fail_count=$((fail_count + 1))
  fi

  echo ""
  echo "=== --once 종료코드 계약 (D-3 AUTO_FIX — 자동화 호출자는 stdout 을 안 읽는다) ==="

  # [14] --once <team> <agent> 단건 — 판정 rc 가 그대로 전파되는지 (SKIP/SUSPECT/ZOMBIE/OK)
  # run_in_background 로 거는 자동화 호출자(§2.5)는 종료코드만 본다 — 무조건 0 이면
  # ZOMBIE/SUSPECT 가 "정상"으로 조용히 사라진다(F-1과 같은 실패 방향).
  local d3_rc
  _zw_pane_id() { printf '%s' '%1'; }   # V-6(9-3-2): cmd_once 화이트리스트 통과용 유효 pane. 억제 게이트는 미존재 프로세스(d3agent@d3team)로 별도 미억제 — SUSPECT 유지 불변

  case_count=$((case_count + 1))
  _zw_invoke_zc() { echo "SKIP: stub"; return 3; }
  d3_rc=0; cmd_once "d3team" "d3agent" >/dev/null || d3_rc=$?
  if [[ "$d3_rc" -eq 3 ]]; then
    echo "  [PASS] [14a] --once 단건 SKIP → exit=3 전파"
  else
    echo "  [FAIL] [14a] --once 단건 SKIP → exit=${d3_rc} (기대 3)"; fail_count=$((fail_count + 1))
  fi

  case_count=$((case_count + 1))
  _zw_invoke_zc() { echo "ZOMBIE-CONFIRMED: stub"; return 1; }
  d3_rc=0; cmd_once "d3team" "d3agent" >/dev/null || d3_rc=$?
  if [[ "$d3_rc" -eq 1 ]]; then
    echo "  [PASS] [14b] --once 단건 ZOMBIE → exit=1 전파"
  else
    echo "  [FAIL] [14b] --once 단건 ZOMBIE → exit=${d3_rc} (기대 1, 구버전은 0 위조)"; fail_count=$((fail_count + 1))
  fi

  case_count=$((case_count + 1))
  _zw_invoke_zc() { echo "ZOMBIE-SUSPECT: stub (idle 200s >= 180s)"; return 2; }
  d3_rc=0; cmd_once "d3team" "d3agent" >/dev/null || d3_rc=$?
  if [[ "$d3_rc" -eq 2 ]]; then
    echo "  [PASS] [14c] --once 단건 SUSPECT → exit=2 전파"
  else
    echo "  [FAIL] [14c] --once 단건 SUSPECT → exit=${d3_rc} (기대 2, 구버전은 0 위조)"; fail_count=$((fail_count + 1))
  fi

  case_count=$((case_count + 1))
  _zw_invoke_zc() { echo "OK: stub"; return 0; }
  d3_rc=0; cmd_once "d3team" "d3agent" >/dev/null || d3_rc=$?
  if [[ "$d3_rc" -eq 0 ]]; then
    echo "  [PASS] [14d] --once 단건 OK → exit=0 전파"
  else
    echo "  [FAIL] [14d] --once 단건 OK → exit=${d3_rc} (기대 0)"; fail_count=$((fail_count + 1))
  fi

  # [15] --once <team> (다건, agent 미지정) — 최악값 반환. ZOMBIE(1) 이 SKIP(3) 보다
  # 종료코드 숫자는 작지만 더 심각하므로, 다건 중 하나라도 ZOMBIE 면 전체가 1을 반환해야 한다.
  case_count=$((case_count + 1))
  local d3m_home d3m_rc
  d3m_home="$(mktemp -d)"
  mkdir -p "${d3m_home}/.claude/teams/d3mteam"
  printf '{"members":[{"name":"okagent","tmuxPaneId":"%%1"},{"name":"zombieagent","tmuxPaneId":"%%2"}]}' > "${d3m_home}/.claude/teams/d3mteam/config.json"
  _zw_invoke_zc() {
    if [[ "$2" == "zombieagent" ]]; then echo "ZOMBIE-CONFIRMED: stub"; return 1
    else echo "OK: stub"; return 0
    fi
  }
  d3m_rc=0
  HOME="$d3m_home" cmd_once "d3mteam" >/dev/null || d3m_rc=$?
  rm -rf "$d3m_home"
  if [[ "$d3m_rc" -eq 1 ]]; then
    echo "  [PASS] [15] --once 다건(OK+ZOMBIE 혼재) → 최악값 exit=1(ZOMBIE) 반환"
  else
    echo "  [FAIL] [15] --once 다건(OK+ZOMBIE 혼재) → exit=${d3m_rc} (기대 1)"; fail_count=$((fail_count + 1))
  fi

  echo ""
  echo "=== R2-5 — 진단(wake-up) 이후 inbox 갱신은 OK 를 확정하지 않는다 ==="

  # [16] R2-5 — 직전 SUSPECT 가 wake_marker 를 남긴 뒤, 그 시각 이후 inbox 가 갱신되면
  #      OK 가 아니라 SKIP(3) 을 반환해야 한다(자기발신 리셋 의심 — 판정 보류)
  case_count=$((case_count + 1))
  local r25_dir; r25_dir="$(mktemp -d)"
  _ZW_STATE_ROOT="$r25_dir"
  mkdir -p "${r25_dir}/r25team"
  printf '1000' > "${r25_dir}/r25team/agentR25.wake"   # 직전 SUSPECT 시각(epoch 1000)
  _zw_inbox_mtime() { printf '2000'; }                 # inbox 는 그 이후(epoch 2000)에 갱신됨
  _zw_invoke_zc() { echo "OK: stub"; return 0; }
  local out16 rc16=0; out16="$(_zw_check_one "r25team" "agentR25" false)" || rc16=$?
  if [[ "$rc16" -eq 3 && "$out16" == *"R2-5"* ]]; then
    echo "  [PASS] [16] R2-5 — wake-up 이후 inbox 갱신 → OK 대신 SKIP(3) — '${out16}'"
  else
    echo "  [FAIL] [16] 기대 rc=3+R2-5 문구, 실제 rc=${rc16} out='${out16}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$r25_dir"; _zw_inbox_mtime() { _zw_inbox_mtime_real "$@"; }

  # [17] R2-5 대조군 — wake_marker 가 없는(직전이 SUSPECT 아니었던) 정상 OK 는 그대로
  #      확정된다 — 감지력이 저하되지 않았음을 확인(R-14)
  case_count=$((case_count + 1))
  local r25b_dir; r25b_dir="$(mktemp -d)"
  _ZW_STATE_ROOT="$r25b_dir"
  _zw_invoke_zc() { echo "OK: stub"; return 0; }
  local out17 rc17=0; out17="$(_zw_check_one "r25team" "agentR25b" true)" || rc17=$?
  if [[ "$rc17" -eq 0 && "$out17" == "OK: agentR25b" ]]; then
    echo "  [PASS] [17] R2-5 대조군 — wake_marker 없는 정상 OK 는 그대로 확정(R-14, 감지력 미저하)"
  else
    echo "  [FAIL] [17] 기대 rc=0 'OK: agentR25b', 실제 rc=${rc17} out='${out17}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$r25b_dir"; _ZW_STATE_ROOT="/tmp/zombie-watch-state"

  echo ""
  echo "=== R2-1 — D-1 필터 제외 가시화 ==="

  # [18] R2-1 — 제외 멤버(team-lead) 존재 시 기동 1회만 emit, 2사이클 이상 지나도 무출력
  #      (실 루프 실행, 1초 간격으로 2.2초 관측 — §2.3 edge-triggered)
  case_count=$((case_count + 1))
  local r21_home r21_log; r21_home="$(mktemp -d)"; r21_log="$(mktemp)"
  mkdir -p "${r21_home}/.claude/teams/r21team"
  printf '{"members":[{"name":"team-lead","tmuxPaneId":"leader"},{"name":"agentX","tmuxPaneId":"%%3"}]}' > "${r21_home}/.claude/teams/r21team/config.json"
  # D8-2(T-2, High, Phase 8-6): 이 스텁은 실 루프가 zombie_check.sh 서브프로세스를 매 사이클
  # 띄우지 않도록 막는 용도일 뿐이다 — 원함수를 저장해 두었다가 케이스 종료 직후 반드시
  # 복원한다. 복원하지 않으면 [18] 이후 전 케이스가 이 no-op 을 영구히 물려받아
  # "실제 ZOMBIE 도 rc=0/무출력으로 통과"하는 상태가 된다(8-5 verifier D8-2, tester 8-6 T-2 재확인).
  local _zw_check_one_orig; _zw_check_one_orig="$(declare -f _zw_check_one)"
  _zw_check_one() { :; }
  ( local _ZW_POLL_INTERVAL=1; HOME="$r21_home" _zw_run_loop "r21team" >"$r21_log" 2>&1 ) & local r21_pid=$!
  sleep 2.2
  kill -TERM "$r21_pid" 2>/dev/null || true; wait "$r21_pid" 2>/dev/null || true
  local r21_hits; r21_hits="$(grep -c "실 pane 미보유로 폴링 제외" "$r21_log" 2>/dev/null || echo 0)"
  rm -rf "$r21_home"; rm -f "$r21_log"
  eval "$_zw_check_one_orig"   # D8-2/T-2: 원함수 복원 — 이 줄 없이는 이후 전 케이스가 무력화된다
  if [[ "$r21_hits" -eq 1 ]]; then
    echo "  [PASS] [18] R2-1 — 제외 멤버 알림 기동 1회만 emit(2+ 사이클 관측, 이후 무출력)"
  else
    echo "  [FAIL] [18] 기대 1회, 실제 ${r21_hits}회"; fail_count=$((fail_count + 1))
  fi

  # [19] R2-1 — 대상 0명(전원 실 pane 미보유) → cmd_once 가 emit 하고 rc=3(SKIP) 반환
  case_count=$((case_count + 1))
  local r21b_home r21b_out r21b_rc=0; r21b_home="$(mktemp -d)"
  mkdir -p "${r21b_home}/.claude/teams/r21bteam"
  printf '{"members":[{"name":"team-lead","tmuxPaneId":"leader"}]}' > "${r21b_home}/.claude/teams/r21bteam/config.json"
  r21b_out="$(HOME="$r21b_home" cmd_once "r21bteam" 2>&1)" || r21b_rc=$?
  rm -rf "$r21b_home"
  if [[ "$r21b_rc" -eq 3 && "$r21b_out" == *"폴링 대상 0명"* ]]; then
    echo "  [PASS] [19] R2-1 — 대상 0명 → SKIP emit + rc=3"
  else
    echo "  [FAIL] [19] 기대 rc=3+0명 문구, 실제 rc=${r21b_rc} out='${r21b_out}'"; fail_count=$((fail_count + 1))
  fi

  # Phase 9-3-1(498/500 분할): 회귀 케이스 [20]~[26](D-2/D-7·R-14·T-1)을
  # zombie_watch_selftest_regression.sh 로 이관했다. source 는 새 함수 스코프를 만들지
  # 않으므로 case_count/fail_count 등 이 함수(_zw_self_test)의 지역변수가 원문(인라인
  # 배치)과 완전히 동일하게 공유·갱신된다. 이관 구간은 원본 L368~478 과 바이트 동일
  # (diff exit 0 + md5 대조 — 9-1 zombie_watch_lib.sh/poll.sh 분리 방식 준용).
  source "${SELFTEST_DIR}/zombie_watch_selftest_regression.sh"

  # R2-2(Medium, Phase 8-5): 케이스 수 정확 일치 — 하한이 아니라 정확 일치라 케이스가
  # 조용히 사라져도(누락) 조용히 늘어도(중복) 잡힌다. 총계 표기 자기 자신을 나눈 값이라
  # 이 검사 없이는 항상 참이었다(P-2 계열 재발, R2-2).
  readonly expected_cases=29
  if (( case_count != expected_cases )); then
    echo "  [FAIL] 케이스 수 불일치: 실행 ${case_count}건 (기대 ${expected_cases}건) — 케이스 누락/중복 의심"
    fail_count=$((fail_count + 1))
  fi

  echo ""
  if [[ "$fail_count" -eq 0 ]]; then
    echo "zombie_watch.sh --self-test 전건 PASS (${case_count}/${expected_cases})"
    return 0
  fi
  echo "zombie_watch.sh --self-test 실패 (${fail_count}건, 실행 ${case_count}건, 기대 ${expected_cases}건)"
  return 1
}

_zw_self_test
exit $?
