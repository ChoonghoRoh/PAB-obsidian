#!/usr/bin/env bash
# =============================================================================
# zombie_watch_selftest_regression.sh — 회귀 케이스 [20]~[26] (Phase 9-3-1 분리, source 전용)
#
# 배경: zombie_watch_selftest.sh 본체가 498줄로 500줄 한도(REFACTOR-1)에 근접했다(여유 2).
#       원문이 이미 "=== D-2 / D-7 회귀 ===" · "=== R-14 회귀 ===" · "=== T-1 회귀 ===" 로
#       스스로 명명한 3개 절(케이스 [20]~[26], 7종)을 이 파일로 이관해 기능 케이스
#       (arm/emit/억제 게이트/respawn/해시 메모리/D-1 필터/D-3 rc 계약/R2-5/R2-1)와
#       회귀 케이스를 파일 경계로 분리했다.
#
# source 전용: zombie_watch_selftest.sh 의 _zw_self_test() 함수 본문 "안에서" `source` 로
#       로드된다. source 는 새 함수 스코프를 만들지 않으므로(함수 호출이 아니라 같은
#       스코프에서 이어 실행) case_count/fail_count 등 호출측 지역변수가 원문(인라인 배치)과
#       완전히 동일하게 공유·갱신된다 — 이 파일은 그 자체로 독립 함수가 아니라
#       _zw_self_test() 본문의 연속(문자 그대로 이어붙인 것과 실행상 동치)이다.
#       쉘 안전 옵션(errexit/nounset/pipefail)은 소싱하는 쪽에서 상속되므로 재선언하지 않는다
#       (zombie_watch_lib.sh/zombie_watch_poll.sh, Phase 9-1 선례와 동일 원칙).
#
# 이관 방식(Phase 9-1 zombie_watch_lib.sh/poll.sh 분리 판정서 준용): 원본
#       zombie_watch_selftest.sh L368~478(111행)을 바이트 동일 이관했다
#       (diff exit 0 + md5 대조, docs/phases/phase-9-3/reports/ 참조). 케이스 추가·삭제
#       없음, expected_cases=29 값 불변.
# =============================================================================

  echo ""
  echo "=== D-2 / D-7 회귀 ==="

  # [20] D-2 — 팀명이 다른 zombie_watch.sh 루프 프로세스는 arm 으로 인정하지 않는다
  #      (부분일치였던 구버전은 zombie_watch.sh 문자열만 보고 오판정했다)
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
  rm -rf "$d7_dir"; _ZW_STATE_ROOT="/tmp/zombie-watch-state"

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
  rm -rf "$s3_dir"; _zw_inbox_mtime() { _zw_inbox_mtime_real "$@"; }; _ZW_STATE_ROOT="/tmp/zombie-watch-state"

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
  rm -rf "$s4_dir"; _zw_pane_id() { _zw_pane_id_real "$@"; }; _ZW_STATE_ROOT="/tmp/zombie-watch-state"

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
  rm -rf "$s5_dir"; _ZW_STATE_ROOT="/tmp/zombie-watch-state"

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
  rm -rf "$s6_dir"; _zw_invoke_zc() { _zw_invoke_zc_real "$@"; }; _ZW_STATE_ROOT="/tmp/zombie-watch-state"

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

