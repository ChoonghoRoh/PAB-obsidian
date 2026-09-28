#!/usr/bin/env bash
#
# source 전용: zombie_watch_selftest.sh 의 _zw_self_test() 함수 본문 "안에서" `source` 로
#       로드된다. source 는 새 함수 스코프를 만들지 않으므로 case_count/fail_count 등
#       호출측 지역변수를 공유·갱신한다. 쉘 안전 옵션은 소싱하는 쪽에서 상속되므로 재선언하지 않는다.

  echo ""
  echo "=== D-2 / D-7 회귀 ==="

  # [20] D-2 — 팀명이 다른 zombie_watch.sh 루프 프로세스는 arm 으로 인정하지 않는다
  case_count=$((case_count + 1))
  local d2_dir; d2_dir="$(mktemp -d)"
  bash -c "exec -a 'zombie_watch.sh --_loop-internal otherteam' sleep 5" & local d2_pid=$!
  sleep 0.2
  _ZW_MARKER_DIR="$d2_dir"; echo "$d2_pid" > "$(_zw_marker_file "mytesteam")"
  if _zw_is_armed "mytesteam" >/dev/null 2>&1; then
    echo "  [FAIL] [20] 팀명 불일치 프로세스가 arm 으로 오판정됨(D-2 재발)"; fail_count=$((fail_count + 1))
  else
    echo "  [PASS] [20] D-2 — 팀명 불일치(otherteam ≠ mytesteam) 프로세스는 arm 미인정"
  fi
  kill "$d2_pid" 2>/dev/null || true; wait "$d2_pid" 2>/dev/null || true
  rm -rf "$d2_dir"; _ZW_MARKER_DIR="/tmp/zombie-watch-markers"

  # [21] D-7 — --stop 후 해당 팀 state 디렉토리는 정리하되 타 팀 디렉토리는 보존한다
  case_count=$((case_count + 1))
  local d7_dir; d7_dir="$(mktemp -d)"
  _ZW_STATE_ROOT="$d7_dir"
  mkdir -p "${d7_dir}/teamA" "${d7_dir}/teamB"
  printf 'x' > "${d7_dir}/teamA/agent1.state"; printf 'y' > "${d7_dir}/teamB/agent2.state"
  cmd_stop "teamA" >/dev/null
  if [[ ! -d "${d7_dir}/teamA" && -d "${d7_dir}/teamB" ]]; then
    echo "  [PASS] [21] D-7 — teamA state 디렉토리 제거 + teamB 보존 확인"
  else
    echo "  [FAIL] [21] teamA 잔존 또는 teamB 훼손"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$d7_dir"; _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"

  echo ""
  echo "=== R-14 회귀 — R2-5 는 단일 방향(OK→SKIP)인가 (Phase 8-6, 8-5 verifier §(d) 대조군 보강) ==="

  # [22] S3 — marker 존재 but inbox 가 marker 보다 더 오래됨(자기발신 아님) → OK 유지
  case_count=$((case_count + 1))
  local s3_dir; s3_dir="$(mktemp -d)"; _ZW_STATE_ROOT="$s3_dir"
  mkdir -p "${s3_dir}/s3team"; printf '2000' > "${s3_dir}/s3team/agentS3.wake"
  _zw_inbox_mtime() { printf '1000'; }
  _zw_invoke_zc() { echo "OK: stub"; return 0; }
  local outS3 rcS3=0; outS3="$(_zw_check_one "s3team" "agentS3" false)" || rcS3=$?
  if [[ "$rcS3" -eq 0 && "$outS3" == "OK: agentS3" ]]; then
    echo "  [PASS] [22] R-14 S3 — marker 존재 but inbox 가 더 오래됨 → OK 유지"
  else
    echo "  [FAIL] [22] 기대 rc=0 'OK: agentS3', 실제 rc=${rcS3} out='${outS3}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$s3_dir"; _zw_inbox_mtime() { _zw_inbox_mtime_real "$@"; }; _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"

  # [23] S4 — marker 존재 + raw SUSPECT → rc=2 유지(R2-5 는 OK 경로에만 개입)
  case_count=$((case_count + 1))
  local s4_dir; s4_dir="$(mktemp -d)"; _ZW_STATE_ROOT="$s4_dir"
  mkdir -p "${s4_dir}/s4team"; printf '1000' > "${s4_dir}/s4team/agentS4.wake"
  _zw_pane_id() { printf ''; }   # 억제 게이트 unavailable 강제 — 원 SUSPECT 판정 유지
  _zw_invoke_zc() { echo "ZOMBIE-SUSPECT: agentS4 (idle 200s >= 180s)"; return 2; }
  local outS4 rcS4=0; outS4="$(_zw_check_one "s4team" "agentS4" false)" || rcS4=$?
  if [[ "$rcS4" -eq 2 ]]; then
    echo "  [PASS] [23] R-14 S4 — marker 존재 + raw SUSPECT → rc=2 유지"
  else
    echo "  [FAIL] [23] 기대 rc=2, 실제 rc=${rcS4} out='${outS4}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$s4_dir"; _zw_pane_id() { _zw_pane_id_real "$@"; }; _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"

  # [24] S5 — marker 존재 + raw ZOMBIE → rc=1 유지 (최우선 — R2-5 가 ZOMBIE 를 절대 덮지 않음을 보증)
  case_count=$((case_count + 1))
  local s5_dir; s5_dir="$(mktemp -d)"; _ZW_STATE_ROOT="$s5_dir"
  mkdir -p "${s5_dir}/s5team"; printf '1000' > "${s5_dir}/s5team/agentS5.wake"
  _zw_invoke_zc() { echo "ZOMBIE-CONFIRMED: agentS5 (no claude.exe process)"; return 1; }
  local outS5 rcS5=0; outS5="$(_zw_check_one "s5team" "agentS5" false)" || rcS5=$?
  if [[ "$rcS5" -eq 1 && "$outS5" == *"ZOMBIE-CONFIRMED"* ]]; then
    echo "  [PASS] [24] R-14 S5 — marker 존재 + raw ZOMBIE → rc=1 유지(단일 방향 보증)"
  else
    echo "  [FAIL] [24] 기대 rc=1+ZOMBIE-CONFIRMED, 실제 rc=${rcS5} out='${outS5}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$s5_dir"; _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"

  # [25] S6 — marker 존재 + raw SKIP → rc=3 유지
  case_count=$((case_count + 1))
  local s6_dir; s6_dir="$(mktemp -d)"; _ZW_STATE_ROOT="$s6_dir"
  mkdir -p "${s6_dir}/s6team"; printf '1000' > "${s6_dir}/s6team/agentS6.wake"
  _zw_invoke_zc() { echo "SKIP: agentS6 (stub)"; return 3; }
  local outS6 rcS6=0; outS6="$(_zw_check_one "s6team" "agentS6" false)" || rcS6=$?
  if [[ "$rcS6" -eq 3 ]]; then
    echo "  [PASS] [25] R-14 S6 — marker 존재 + raw SKIP → rc=3 유지"
  else
    echo "  [FAIL] [25] 기대 rc=3, 실제 rc=${rcS6} out='${outS6}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$s6_dir"; _zw_invoke_zc() { _zw_invoke_zc_real "$@"; }; _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"

  echo ""
  echo "=== T-1 회귀 — /tmp 권한 거부 디렉터리 존재 시에도 완주하는가 (Linux systemd 재현) ==="

  # [26] T-1 — case[12] 와 동일한 find 패턴이 권한 거부 디렉터리 앞에서도 안전하게 완주 +
  #      유효한 카운트를 반환하는지 확인(중단 대신 부정확한 값이 나오는 것도 결함이므로 값도 단언)
  case_count=$((case_count + 1))
  local t1_dir t1_script t1_out t1_rc=0
  t1_dir="$(mktemp -d)"; mkdir -p "${t1_dir}/denied"; chmod 000 "${t1_dir}/denied"
  t1_script="$(mktemp)"
  cat > "$t1_script" <<EOF
set -euo pipefail
hash_files="\$(find "$t1_dir" -maxdepth 3 -iname '*hash*' -newer "$t1_dir" 2>/dev/null | wc -l | tr -d ' ' || true)"
printf '%s' "\$hash_files"
EOF
  t1_out="$(bash "$t1_script" 2>&1)" || t1_rc=$?
  chmod 755 "${t1_dir}/denied"; rm -f "$t1_script"; rm -rf "$t1_dir"
  if [[ "$t1_rc" -eq 0 && "$t1_out" =~ ^[0-9]+$ ]]; then
    echo "  [PASS] [26] T-1 — 권한 거부 디렉터리 존재 시에도 완주 + 유효 카운트('${t1_out}') 확인"
  else
    echo "  [FAIL] [26] 기대 rc=0+숫자, 실제 rc=${t1_rc} out='${t1_out}'"; fail_count=$((fail_count + 1))
  fi

  echo ""
  echo "=== T1b — 상주 역할(planner) idle TTL 예외(D-5, Q-5 정확 일치) ==="

  case_count=$((case_count + 1))
  local r1_dir; r1_dir="$(mktemp -d)"; _ZW_STATE_ROOT="$r1_dir"
  _zw_invoke_zc() { echo "ZOMBIE-SUSPECT: planner (idle 200s >= 180s, wake-up 권장)"; return 2; }
  local outR1 rcR1=0; outR1="$(_zw_check_one "r1team" "planner" false)" || rcR1=$?
  if [[ "$rcR1" -eq 0 && "$outR1" == "OK: planner (상주 대기 — LIFECYCLE-1 예외)" ]]; then
    echo "  [PASS] [27] T1b — 상주(planner) idle → OK(상주 대기 — LIFECYCLE-1 예외)"
  else
    echo "  [FAIL] [27] 기대 rc=0 'OK: planner (상주 대기 — LIFECYCLE-1 예외)', 실제 rc=${rcR1} out='${outR1}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$r1_dir"; _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"

  case_count=$((case_count + 1))
  local r2_dir; r2_dir="$(mktemp -d)"; _ZW_STATE_ROOT="$r2_dir"
  _zw_invoke_zc() { echo "ZOMBIE-CONFIRMED: planner (no claude.exe process)"; return 1; }
  local outR2 rcR2=0; outR2="$(_zw_check_one "r2team" "planner" false)" || rcR2=$?
  if [[ "$rcR2" -eq 1 && "$outR2" == *"ZOMBIE-CONFIRMED"* ]]; then
    echo "  [PASS] [28] T1b — 상주(planner) 프로세스 없음 → ZOMBIE-CONFIRMED 그대로(예외 미적용)"
  else
    echo "  [FAIL] [28] 기대 rc=1+ZOMBIE-CONFIRMED, 실제 rc=${rcR2} out='${outR2}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$r2_dir"; _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"

  case_count=$((case_count + 1))
  local r3_dir; r3_dir="$(mktemp -d)"; _ZW_STATE_ROOT="$r3_dir"
  _zw_pane_id() { printf ''; }
  _zw_invoke_zc() { echo "ZOMBIE-SUSPECT: backend-dev (idle 200s >= 180s, wake-up 권장)"; return 2; }
  local outR3 rcR3=0; outR3="$(_zw_check_one "r3team" "backend-dev" false)" || rcR3=$?
  if [[ "$rcR3" -eq 2 ]]; then
    echo "  [PASS] [29] T1b — 비상주(backend-dev) idle → SUSPECT 그대로(예외 미적용)"
  else
    echo "  [FAIL] [29] 기대 rc=2, 실제 rc=${rcR3} out='${outR3}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$r3_dir"; _zw_pane_id() { _zw_pane_id_real "$@"; }; _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"

  case_count=$((case_count + 1))
  local r4_dir; r4_dir="$(mktemp -d)"; _ZW_STATE_ROOT="$r4_dir"
  _zw_pane_id() { printf ''; }
  _zw_invoke_zc() { echo "ZOMBIE-SUSPECT: planner-a1 (idle 200s >= 180s, wake-up 권장)"; return 2; }
  local outR4 rcR4=0; outR4="$(_zw_check_one "r4team" "planner-a1" false)" || rcR4=$?
  if [[ "$rcR4" -eq 2 ]]; then
    echo "  [PASS] [30] T1b — planner-a1(정확 일치 아님) idle → SUSPECT 그대로(Q-5)"
  else
    echo "  [FAIL] [30] 기대 rc=2, 실제 rc=${rcR4} out='${outR4}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$r4_dir"; _zw_pane_id() { _zw_pane_id_real "$@"; }; _zw_invoke_zc() { _zw_invoke_zc_real "$@"; }; _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"

  echo ""
  echo "=== T1b r2 — A안(edge-trigger RESIDENT) 전이 3종(TD-28 실측 경로 고정) ==="

  local r5_dir; r5_dir="$(mktemp -d)"; _ZW_STATE_ROOT="$r5_dir"
  mkdir -p "${r5_dir}/r5team"; printf 'OK' > "${r5_dir}/r5team/planner.state"

  case_count=$((case_count + 1))
  _zw_invoke_zc() { echo "ZOMBIE-SUSPECT: planner (idle 200s >= 180s, wake-up 권장)"; return 2; }
  local outR5 rcR5=0; outR5="$(_zw_check_one "r5team" "planner" false)" || rcR5=$?
  if [[ "$rcR5" -eq 0 && "$outR5" == "OK: planner (상주 대기 — LIFECYCLE-1 예외)" ]]; then
    echo "  [PASS] [31] T1b r2 — 앞 상태 OK → planner idle 진입 시 상주 문구 1회 emit"
  else
    echo "  [FAIL] [31] 기대 rc=0 'OK: planner (상주 대기 — LIFECYCLE-1 예외)', 실제 rc=${rcR5} out='${outR5}'"; fail_count=$((fail_count + 1))
  fi

  case_count=$((case_count + 1))
  local outR6 rcR6=0; outR6="$(_zw_check_one "r5team" "planner" false)" || rcR6=$?
  if [[ "$rcR6" -eq 0 && -z "$outR6" ]]; then
    echo "  [PASS] [32] T1b r2 — 상주 대기 지속(같은 조건 재폴링) → 무출력(중복 없음)"
  else
    echo "  [FAIL] [32] 기대 rc=0 무출력, 실제 rc=${rcR6} out='${outR6}'"; fail_count=$((fail_count + 1))
  fi

  case_count=$((case_count + 1))
  _zw_invoke_zc() { echo "OK: planner (pid=1)"; return 0; }
  local outR7 rcR7=0; outR7="$(_zw_check_one "r5team" "planner" false)" || rcR7=$?
  if [[ "$rcR7" -eq 0 && "$outR7" == "OK: planner" ]]; then
    echo "  [PASS] [33] T1b r2 — 상주 대기 → 활동 복귀 → 기존 규칙대로 OK 전이 emit"
  else
    echo "  [FAIL] [33] 기대 rc=0 'OK: planner', 실제 rc=${rcR7} out='${outR7}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$r5_dir"; _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"; _zw_invoke_zc() { _zw_invoke_zc_real "$@"; }

  echo ""
  echo "=== T4 K-7 7b — respawn 상주 이름 판정(D4 suffix planner_r[1-5]) ==="

  local r8_dir; r8_dir="$(mktemp -d)"; _ZW_STATE_ROOT="$r8_dir"
  mkdir -p "${r8_dir}/r8team"; printf 'OK' > "${r8_dir}/r8team/planner_r1.state"

  case_count=$((case_count + 1))
  _zw_invoke_zc() { echo "ZOMBIE-SUSPECT: planner_r1 (idle 200s >= 180s, wake-up 권장)"; return 2; }
  local outR8 rcR8=0; outR8="$(_zw_check_one "r8team" "planner_r1" false)" || rcR8=$?
  if [[ "$rcR8" -eq 0 && "$outR8" == "OK: planner_r1 (상주 대기 — LIFECYCLE-1 예외)" ]]; then
    echo "  [PASS] [34] T4 7b — planner_r1(D3 상한 내 respawn) idle → RESIDENT(OK) 전이"
  else
    echo "  [FAIL] [34] 기대 rc=0 'OK: planner_r1 (상주 대기 — LIFECYCLE-1 예외)', 실제 rc=${rcR8} out='${outR8}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$r8_dir"; _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"

  case_count=$((case_count + 1))
  local r9_dir; r9_dir="$(mktemp -d)"; _ZW_STATE_ROOT="$r9_dir"
  _zw_invoke_zc() { echo "ZOMBIE-SUSPECT: planner-a1 (idle 200s >= 180s, wake-up 권장)"; return 2; }
  local outR9 rcR9=0; outR9="$(_zw_check_one "r9team" "planner-a1" false)" || rcR9=$?
  if [[ "$rcR9" -eq 2 ]]; then
    echo "  [PASS] [35] T4 7b — planner-a1(초안, 하이픈 이름) idle → RESIDENT 미적용(SUSPECT 유지)"
  else
    echo "  [FAIL] [35] 기대 rc=2, 실제 rc=${rcR9} out='${outR9}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$r9_dir"; _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"

  case_count=$((case_count + 1))
  local r10_dir; r10_dir="$(mktemp -d)"; _ZW_STATE_ROOT="$r10_dir"
  _zw_invoke_zc() { echo "ZOMBIE-SUSPECT: planner_r6 (idle 200s >= 180s, wake-up 권장)"; return 2; }
  local outR10 rcR10=0; outR10="$(_zw_check_one "r10team" "planner_r6" false)" || rcR10=$?
  if [[ "$rcR10" -eq 2 ]]; then
    echo "  [PASS] [36] T4 7b — planner_r6(D3 상한 밖) idle → RESIDENT 미적용(SUSPECT 유지)"
  else
    echo "  [FAIL] [36] 기대 rc=2, 실제 rc=${rcR10} out='${outR10}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$r10_dir"; _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"; _zw_invoke_zc() { _zw_invoke_zc_real "$@"; }

  echo ""
  echo "=== TD-109 — in-process 팀원(pane 없음) transcript 무기록 감시 ==="

  # [37] 정체 — 마지막 기록이 도구 결과(tool_result)로 끝나고 무기록 ≥ 임계 → SUSPECT
  case_count=$((case_count + 1))
  local i1_home i1_cwd i1_dir; i1_home="$(mktemp -d)"; i1_cwd="/Users/t109/WORKS/proj-a"
  i1_dir="$(HOME="$i1_home" _zw_inproc_project_dir "$i1_cwd")"
  mkdir -p "$i1_dir" "${i1_home}/.claude/teams/t109teamA"
  printf '{"members":[{"name":"agentP","cwd":"%s","isActive":true}]}' "$i1_cwd" > "${i1_home}/.claude/teams/t109teamA/config.json"
  printf '{"agentName":"agentP","teamName":"t109teamA","timestamp":"2026-01-01T00:00:00Z","type":"user","message":{"content":[{"type":"tool_result"}]}}\n' > "${i1_dir}/sess.jsonl"
  local outI1 rcI1=0
  outI1="$(HOME="$i1_home" _ZW_INPROC_ASOF_OVERRIDE="2026-01-01T00:10:00Z" _zw_invoke_inproc_real "t109teamA" "agentP")" || rcI1=$?
  if [[ "$rcI1" -eq 2 && "$outI1" == *"SUSPECT"* ]]; then
    echo "  [PASS] [37] TD-109 — 정체(마지막 기록 tool_result · idle 600s ≥ 300s) → SUSPECT"
  else
    echo "  [FAIL] [37] 기대 rc=2, 실제 rc=${rcI1} out='${outI1}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$i1_home"

  # [38] 최근 기록 — 같은 마지막 기록이라도 무기록 시간 < 임계면 OK
  case_count=$((case_count + 1))
  local i2_home i2_cwd i2_dir; i2_home="$(mktemp -d)"; i2_cwd="/Users/t109/WORKS/proj-b"
  i2_dir="$(HOME="$i2_home" _zw_inproc_project_dir "$i2_cwd")"
  mkdir -p "$i2_dir" "${i2_home}/.claude/teams/t109teamB"
  printf '{"members":[{"name":"agentQ","cwd":"%s","isActive":true}]}' "$i2_cwd" > "${i2_home}/.claude/teams/t109teamB/config.json"
  printf '{"agentName":"agentQ","teamName":"t109teamB","timestamp":"2026-01-01T00:00:00Z","type":"assistant","message":{"stop_reason":"tool_use"}}\n' > "${i2_dir}/sess.jsonl"
  local outI2 rcI2=0
  outI2="$(HOME="$i2_home" _ZW_INPROC_ASOF_OVERRIDE="2026-01-01T00:00:05Z" _zw_invoke_inproc_real "t109teamB" "agentQ")" || rcI2=$?
  if [[ "$rcI2" -eq 0 ]]; then
    echo "  [PASS] [38] TD-109 — 최근 기록(idle 5s < 300s) → OK"
  else
    echo "  [FAIL] [38] 기대 rc=0, 실제 rc=${rcI2} out='${outI2}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$i2_home"

  # [39] 턴 끝 대기 — 실 transcript 형식(end_turn 뒤 attachment 2줄 · system 2줄이 더 붙는다)에서도
  #      무기록 시간과 무관하게 OK여야 한다. attachment·system 을 "마지막 기록"으로 잘못 집으면
  #      그 줄은 assistant·end_turn 이 아니라서 SUSPECT 로 샌다.
  case_count=$((case_count + 1))
  local i3_home i3_cwd i3_dir; i3_home="$(mktemp -d)"; i3_cwd="/Users/t109/WORKS/proj-c"
  i3_dir="$(HOME="$i3_home" _zw_inproc_project_dir "$i3_cwd")"
  mkdir -p "$i3_dir" "${i3_home}/.claude/teams/t109teamC"
  printf '{"members":[{"name":"agentR","cwd":"%s","isActive":true}]}' "$i3_cwd" > "${i3_home}/.claude/teams/t109teamC/config.json"
  {
    printf '{"agentName":"agentR","teamName":"t109teamC","timestamp":"2026-01-01T00:00:00.100Z","type":"assistant","message":{"stop_reason":"end_turn"}}\n'
    printf '{"agentName":"agentR","teamName":"t109teamC","timestamp":"2026-01-01T00:00:00.400Z","type":"attachment"}\n'
    printf '{"agentName":"agentR","teamName":"t109teamC","timestamp":"2026-01-01T00:00:00.400Z","type":"attachment"}\n'
    printf '{"agentName":"agentR","teamName":"t109teamC","timestamp":"2026-01-01T00:00:00.401Z","type":"system","subtype":"stop_hook_summary"}\n'
    printf '{"agentName":"agentR","teamName":"t109teamC","timestamp":"2026-01-01T00:00:00.420Z","type":"system","subtype":"turn_duration"}\n'
  } > "${i3_dir}/sess.jsonl"
  local outI3 rcI3=0
  outI3="$(HOME="$i3_home" _ZW_INPROC_ASOF_OVERRIDE="2026-06-01T00:00:00Z" _zw_invoke_inproc_real "t109teamC" "agentR")" || rcI3=$?
  if [[ "$rcI3" -eq 0 && "$outI3" == *"턴 끝 대기"* ]]; then
    echo "  [PASS] [39] F-1 — 턴 끝 대기(end_turn 뒤 attachment·system 부산물) → 무기록 시간과 무관하게 OK"
  else
    echo "  [FAIL] [39] 기대 rc=0+턴 끝 대기, 실제 rc=${rcI3} out='${outI3}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$i3_home"

  # [39b] 대조군 — 마지막 실기록(assistant/user)이 tool_result(턴 도중)이고 그 뒤에도
  #       attachment 가 붙는 실 형식이면, attachment 를 걸러도 여전히 SUSPECT 여야 한다
  #       (attachment 를 건너뛰는 수정이 "무조건 OK" 로 새지 않았는지 확인).
  case_count=$((case_count + 1))
  local i3b_home i3b_cwd i3b_dir; i3b_home="$(mktemp -d)"; i3b_cwd="/Users/t109/WORKS/proj-cb"
  i3b_dir="$(HOME="$i3b_home" _zw_inproc_project_dir "$i3b_cwd")"
  mkdir -p "$i3b_dir" "${i3b_home}/.claude/teams/t109teamCb"
  printf '{"members":[{"name":"agentRb","cwd":"%s","isActive":true}]}' "$i3b_cwd" > "${i3b_home}/.claude/teams/t109teamCb/config.json"
  {
    printf '{"agentName":"agentRb","teamName":"t109teamCb","timestamp":"2026-01-01T00:00:00.100Z","type":"user","message":{"content":[{"type":"tool_result"}]}}\n'
    printf '{"agentName":"agentRb","teamName":"t109teamCb","timestamp":"2026-01-01T00:00:00.101Z","type":"attachment"}\n'
  } > "${i3b_dir}/sess.jsonl"
  local outI3b rcI3b=0
  outI3b="$(HOME="$i3b_home" _ZW_INPROC_ASOF_OVERRIDE="2026-01-01T00:10:00Z" _zw_invoke_inproc_real "t109teamCb" "agentRb")" || rcI3b=$?
  if [[ "$rcI3b" -eq 2 && "$outI3b" == *"SUSPECT"* ]]; then
    echo "  [PASS] [39b] F-1 — tool_result 뒤 attachment → SUSPECT 유지(attachment 는 건너뛸 뿐 OK로 새지 않음)"
  else
    echo "  [FAIL] [39b] 기대 rc=2+SUSPECT, 실제 rc=${rcI3b} out='${outI3b}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$i3b_home"

  # [40] transcript 없음 — 프로젝트 디렉터리가 없으면 SKIP(오탐 대신 판정 보류)
  case_count=$((case_count + 1))
  local i4_home i4_cwd; i4_home="$(mktemp -d)"; i4_cwd="/Users/t109/WORKS/proj-d"
  mkdir -p "${i4_home}/.claude/teams/t109teamD"
  printf '{"members":[{"name":"agentS","cwd":"%s","isActive":true}]}' "$i4_cwd" > "${i4_home}/.claude/teams/t109teamD/config.json"
  local outI4 rcI4=0
  outI4="$(HOME="$i4_home" _zw_invoke_inproc_real "t109teamD" "agentS")" || rcI4=$?
  if [[ "$rcI4" -eq 3 && "$outI4" == *"SKIP"* ]]; then
    echo "  [PASS] [40] TD-109 — transcript 프로젝트 디렉터리 없음 → SKIP(오탐 대신 판정 보류)"
  else
    echo "  [FAIL] [40] 기대 rc=3, 실제 rc=${rcI4} out='${outI4}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$i4_home"

  # [41] 같은 이름의 옛 세션이 여럿 — "전체 마지막 기록"이 가장 늦은 파일(현재 세션)로 판정한다
  case_count=$((case_count + 1))
  local i5_home i5_cwd i5_dir; i5_home="$(mktemp -d)"; i5_cwd="/Users/t109/WORKS/proj-e"
  i5_dir="$(HOME="$i5_home" _zw_inproc_project_dir "$i5_cwd")"
  mkdir -p "$i5_dir" "${i5_home}/.claude/teams/t109teamE"
  printf '{"members":[{"name":"agentT","cwd":"%s","isActive":true}]}' "$i5_cwd" > "${i5_home}/.claude/teams/t109teamE/config.json"
  printf '{"agentName":"agentT","teamName":"t109teamE","timestamp":"2025-01-01T00:00:00Z","type":"assistant","message":{"stop_reason":"end_turn"}}\n' > "${i5_dir}/old.jsonl"
  printf '{"agentName":"agentT","teamName":"t109teamE","timestamp":"2026-01-01T00:00:00Z","type":"assistant","message":{"stop_reason":"tool_use"}}\n' > "${i5_dir}/new.jsonl"
  local outI5 rcI5=0
  outI5="$(HOME="$i5_home" _ZW_INPROC_ASOF_OVERRIDE="2026-01-01T00:10:00Z" _zw_invoke_inproc_real "t109teamE" "agentT")" || rcI5=$?
  if [[ "$rcI5" -eq 2 ]]; then
    echo "  [PASS] [41] TD-109 — 같은 이름 옛 세션 2개 중 현재 세션(new.jsonl) 기준으로 SUSPECT 판정"
  else
    echo "  [FAIL] [41] 기대 rc=2(new.jsonl 기준), 실제 rc=${rcI5} out='${outI5}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$i5_home"

  echo ""
  echo "=== F-2 — 워처 대상은 isActive 를 쓰지 않는다(context-handoff SKILL.md:86 「활성」과 짝) ==="

  # [42] 대상 목록에서 team-lead·실 pane 보유(agentX)만 제외. isActive 값(false·true·미기재)은
  #      대상 판정에 영향을 주지 않는다 — isActive 는 작업 중/대기 표지일 뿐이다.
  case_count=$((case_count + 1))
  local i6_cfg i6_dir i6_names
  i6_dir="$(mktemp -d)"; i6_cfg="${i6_dir}/config.json"
  printf '{"members":[{"name":"team-lead","tmuxPaneId":"leader"},{"name":"agentU","tmuxPaneId":"","isActive":false},{"name":"agentV","tmuxPaneId":""},{"name":"agentW","tmuxPaneId":"","isActive":true},{"name":"agentX","tmuxPaneId":"%%8"}]}' > "$i6_cfg"
  i6_names="$(_zw_inproc_target_names "$i6_cfg")"
  rm -rf "$i6_dir"
  if [[ "$i6_names" != *"team-lead"* && "$i6_names" != *"agentX"* && "$i6_names" == *"agentU"* && "$i6_names" == *"agentV"* && "$i6_names" == *"agentW"* ]]; then
    echo "  [PASS] [42] F-2 — team-lead·실 pane 보유(agentX) 제외 + isActive 무관 agentU·agentV·agentW 포함"
  else
    echo "  [FAIL] [42] 기대 team-lead/agentX 제외 + agentU/agentV/agentW 포함, 실제='${i6_names}'"; fail_count=$((fail_count + 1))
  fi

  echo ""
  echo "=== TD-109 — _zw_check_one mode=inproc 통합(억제 게이트는 pane 전용) ==="

  # [43] mode=inproc이면 pane 해시 억제 게이트(_zw_suppress_check)를 타지 않는다 —
  #      스텁이 항상 억제(0)를 반환해도 SUSPECT가 그대로 유지되어야 한다
  case_count=$((case_count + 1))
  local i7_dir _zw_suppress_check_orig; i7_dir="$(mktemp -d)"; _ZW_STATE_ROOT="$i7_dir"
  _zw_suppress_check_orig="$(declare -f _zw_suppress_check)"
  _zw_invoke_inproc() { echo "ZOMBIE-SUSPECT: agentY (idle 600s >= 300s, in-process 무기록, wake-up 권장)"; return 2; }
  _zw_suppress_check() { return 0; }
  local outI7 rcI7=0; outI7="$(_zw_check_one "i7team" "agentY" false "inproc")" || rcI7=$?
  if [[ "$rcI7" -eq 2 ]]; then
    echo "  [PASS] [43] mode=inproc — pane 억제 게이트 미적용, SUSPECT 유지(rc=2)"
  else
    echo "  [FAIL] [43] 기대 rc=2, 실제 rc=${rcI7} out='${outI7}'"; fail_count=$((fail_count + 1))
  fi
  rm -rf "$i7_dir"; _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"
  _zw_invoke_inproc() { _zw_invoke_inproc_real "$@"; }
  eval "$_zw_suppress_check_orig"   # 원함수 복원 — 이 줄 없이는 이후 케이스의 억제 게이트가 무력화된다

  echo ""
  echo "=== F-10 — --once 단건(agent 지정)도 pane 없으면 in-process 로 판정한다 ==="

  # [44] 단건 --once <team> <agent> — pane 없고 in-process 대상(team-lead 아님)이면
  #      SKIP 이 아니라 in-process 판정을 거친다(다건 agent 미지정 경로와 같은 기준).
  case_count=$((case_count + 1))
  local f10_home f10_out f10_rc=0; f10_home="$(mktemp -d)"
  mkdir -p "${f10_home}/.claude/teams/f10team"
  printf '{"members":[{"name":"agentF10","tmuxPaneId":"","isActive":true}]}' > "${f10_home}/.claude/teams/f10team/config.json"
  _zw_invoke_inproc() { echo "ZOMBIE-SUSPECT: agentF10 (idle 600s >= 300s, in-process 무기록, wake-up 권장)"; return 2; }
  f10_out="$(HOME="$f10_home" cmd_once "f10team" "agentF10" 2>&1)" || f10_rc=$?
  rm -rf "$f10_home"
  _zw_invoke_inproc() { _zw_invoke_inproc_real "$@"; }
  if [[ "$f10_rc" -eq 2 && "$f10_out" == *"agentF10"* ]]; then
    echo "  [PASS] [44] F-10 — 단건 pane 없음 + in-process 대상 → in-process 판정(rc=2, 이름 포함)"
  else
    echo "  [FAIL] [44] 기대 rc=2 + agentF10 포함, 실제 rc=${f10_rc} out='${f10_out}'"; fail_count=$((fail_count + 1))
  fi

  # [44b] 대조군 — 단건이라도 제외 대상(team-lead)은 여전히 SKIP(3)이다.
  case_count=$((case_count + 1))
  local f10b_home f10b_out f10b_rc=0; f10b_home="$(mktemp -d)"
  mkdir -p "${f10b_home}/.claude/teams/f10bteam"
  printf '{"members":[{"name":"team-lead","tmuxPaneId":"leader"}]}' > "${f10b_home}/.claude/teams/f10bteam/config.json"
  f10b_out="$(HOME="$f10b_home" cmd_once "f10bteam" "team-lead" 2>&1)" || f10b_rc=$?
  rm -rf "$f10b_home"
  if [[ "$f10b_rc" -eq 3 && "$f10b_out" == *"SKIP"* ]]; then
    echo "  [PASS] [44b] F-10 대조군 — 단건 pane 없음 + 제외 대상(team-lead) → 여전히 SKIP(3)"
  else
    echo "  [FAIL] [44b] 기대 rc=3+SKIP, 실제 rc=${f10b_rc} out='${f10b_out}'"; fail_count=$((fail_count + 1))
  fi

  echo ""
  echo "=== F-4 — TD-109 연결부 회귀 방지(cmd_once·폴링 루프가 in-process 목록을 실제로 도는가) ==="

  # [45] cmd_once(다건, agent 미지정) — in-process 전용 팀(pane 멤버 0명)에서 in-process 목록을
  #      실제로 순회해 SUSPECT(rc=2)를 낸다. 이 순회를 지우는 변이가 이 케이스 없이는 통과했다.
  case_count=$((case_count + 1))
  local m6_home m6_out m6_rc=0; m6_home="$(mktemp -d)"
  mkdir -p "${m6_home}/.claude/teams/m6team"
  printf '{"members":[{"name":"agentM6","tmuxPaneId":"","isActive":true}]}' > "${m6_home}/.claude/teams/m6team/config.json"
  _zw_invoke_inproc() { echo "ZOMBIE-SUSPECT: agentM6 (idle 600s >= 300s, in-process 무기록, wake-up 권장)"; return 2; }
  m6_out="$(HOME="$m6_home" cmd_once "m6team" 2>&1)" || m6_rc=$?
  rm -rf "$m6_home"
  _zw_invoke_inproc() { _zw_invoke_inproc_real "$@"; }
  if [[ "$m6_rc" -eq 2 && "$m6_out" == *"agentM6"* ]]; then
    echo "  [PASS] [45] F-4 — cmd_once 다건이 in-process 전용 팀을 순회해 SUSPECT(rc=2) + 이름 출력"
  else
    echo "  [FAIL] [45] 기대 rc=2 + agentM6 포함, 실제 rc=${m6_rc} out='${m6_out}'"; fail_count=$((fail_count + 1))
  fi

  # [46] 폴링 루프(_zw_run_loop) 1주기 — in-process 목록을 실제로 순회해 체크를 호출한다.
  #      이 순회를 지우는 변이가 이 케이스 없이는 통과했다.
  case_count=$((case_count + 1))
  local m7_home m7_log m7_dir; m7_home="$(mktemp -d)"; m7_log="$(mktemp)"; m7_dir="$(mktemp -d)"
  _ZW_STATE_ROOT="$m7_dir"
  mkdir -p "${m7_home}/.claude/teams/m7team"
  printf '{"members":[{"name":"agentM7","tmuxPaneId":"","isActive":true}]}' > "${m7_home}/.claude/teams/m7team/config.json"
  _zw_invoke_inproc() { echo "ZOMBIE-SUSPECT: agentM7 (idle 600s >= 300s, in-process 무기록, wake-up 권장)"; return 2; }
  ( local _ZW_POLL_INTERVAL=1; HOME="$m7_home" _zw_run_loop "m7team" >"$m7_log" 2>&1 ) & local m7_pid=$!
  sleep 1.2
  kill -TERM "$m7_pid" 2>/dev/null || true; wait "$m7_pid" 2>/dev/null || true
  local m7_hits=0
  grep -q "agentM7" "$m7_log" 2>/dev/null && m7_hits=1
  rm -rf "$m7_home" "$m7_dir"; rm -f "$m7_log"
  _ZW_STATE_ROOT="$_ZW_SELFTEST_STATE_ROOT"
  _zw_invoke_inproc() { _zw_invoke_inproc_real "$@"; }
  if [[ "$m7_hits" -eq 1 ]]; then
    echo "  [PASS] [46] F-4 — 폴링 루프 1주기가 in-process 목록을 순회해 agentM7 을 체크함"
  else
    echo "  [FAIL] [46] 기대 agentM7 관측, 실제 무관측(log에 없음)"; fail_count=$((fail_count + 1))
  fi

