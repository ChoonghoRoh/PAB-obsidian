#!/usr/bin/env bash
# =============================================================================
# zombie_watch.sh — LIFECYCLE-6 체크 스케줄러 (ver6-2 PoC, Phase 8-3)
#
# 근거: docs/phases/phase-8-3/phase-8-3-plan.md
#       docs/phases/pre/phase-8-progress-signal-decision.md (rev.2)
# 규칙: docs/SSOT/SUB-SSOT/TEAM-LEAD/2-lifecycle-procedure.md §LIFECYCLE-6 SCHEDULER
#
# 목적: LIFECYCLE-1~5 는 규칙만 있고 실행체가 없었다(결함 A). 본 스크립트가
#       3분 주기 폴링 루프를 실제로 돌려 zombie_check.sh 판정을 주기적으로 호출한다.
#
# 사용법:
#   zombie_watch.sh --arm <team>            # 폴링 루프 기동 (백그라운드 자기 detach)
#   zombie_watch.sh --stop <team>           # 해제 + 마커 정리
#   zombie_watch.sh --status <team>         # arm 여부 3단 판정 결과 출력
#   zombie_watch.sh --once <team> [agent]   # 1회 체크 (spawn+30초 별도 경로용)
#   zombie_watch.sh --self-test             # 내장 단위 테스트
#   zombie_watch.sh --help
#
# 호출 규약 — subprocess 고정 (plan §3): zombie_check.sh 는 반드시 `bash <script> <agent> <team>`
#   형태의 서브프로세스로만 호출한다. source 절대 금지 (A-2 readonly 충돌 · P-1 이름 충돌 ·
#   P-3 set -euo pipefail 전파 — 세 결함 모두 소싱에서 나온다). 자체 상수는 _ZW_ 접두사를
#   쓰고 EXIT_OK/EXIT_SKIP 등 일반적 이름을 export 하지 않는다(본 파일은 export 자체를 쓰지 않음).
#   ※ zombie_check.sh 실제 시그니처는 `<agent_name> <team_name>` 순서다(스크립트 자체
#   CLI/함수 정의 실측 확인). plan/task 예시 스니펫의 `"${team}" "${agent}"` 표기는 인자
#   순서가 실제 스크립트와 반대로 적혀 있어(오기로 판단), 본 구현은 실제 시그니처를 따른다.
#   상세: report-backend-dev.md §비고.
#
# 진행 신호(억제 게이트) — decision rev.2 D-1/D-2/§7 누락 A/B:
#   inbox stale + pane 해시 변화  → SUSPECT 취소(억제). 해시는 본 프로세스 메모리에만 보관
#   (파일 금지 — 유령 마커 재발 방지, D-2). 상태 키는 (agent_name, pane_id) 쌍 — respawn 은
#   새 pane 을 가지므로 이름만 키잉하면 낡은 해시와 새 pane 을 비교해 좀비를 영구히 놓친다.
#   config.json 부재(pane_id 조회 불가, 누락 B) → 게이트 unavailable → 기존 zombie_check.sh
#   판정을 그대로 유지한다(억제 실패가 확정 판정으로 새지 않도록).
#
# 플랫폼 중립: 이 머신의 /bin/bash 는 3.2.57(연관 문서: zombie_check.sh Darwin 25.3.0 arm64)이며
#   연관 배열(declare -A)을 지원하지 않는다(실측: `declare -A` → invalid option). 해시 저장소는
#   "key=value" 형태 원소를 담는 일반 인덱스 배열로 구현한다. 빈 배열에서 `"${arr[@]}"` 를
#   set -u 상태로 직접 참조하면 unbound variable 로 죽으므로(실측 확인), 모든 배열 순회는
#   `${#arr[@]}` 로 길이를 먼저 확인한 뒤에만 수행한다.
# =============================================================================

set -euo pipefail

_ZW_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
_ZW_SCRIPT_DIR="$(dirname "${_ZW_SCRIPT_PATH}")"
_ZW_ZC_SCRIPT="${_ZW_SCRIPT_DIR}/zombie_check.sh"

_ZW_STATE_ROOT="${_ZW_STATE_ROOT_OVERRIDE:-/tmp/zombie-watch-state}"     # D8-9(Phase 9-3-2): _ZW_POLL_INTERVAL_OVERRIDE 선례 준용, self-test/진단 전용 오버라이드 허용.
_ZW_MARKER_DIR="${_ZW_MARKER_DIR_OVERRIDE:-/tmp/zombie-watch-markers}"   # D8-9(Phase 9-3-2): 위와 동일 패턴.
_ZW_POLL_INTERVAL="${_ZW_POLL_INTERVAL_OVERRIDE:-180}"   # D2=3분=180초. self-test 전용 오버라이드 허용.

# 모듈 로딩 — source 적용 범위는 SUB-SSOT TEAM-LEAD/2-lifecycle-procedure.md
# §LIFECYCLE-6 호출 규약 행 참조. zombie_check.sh 소싱 금지와 별개다.
for _zw_mod in lib poll; do
  _zw_mod_f="${_ZW_SCRIPT_DIR}/zombie_watch_${_zw_mod}.sh"
  [[ -r "$_zw_mod_f" ]] || { echo "SKIP: 모듈 로딩 실패 — ${_zw_mod_f} 부재 또는 읽기 불가" >&2; exit 1; }
  # shellcheck source=/dev/null
  source "$_zw_mod_f"
done
unset _zw_mod _zw_mod_f

# 대상 1인 체크 + 억제 게이트 적용 + edge-triggered emit 판단 + 상태 파일 갱신
_zw_check_one() {
  local team="$1" agent="$2" is_first="$3"
  local rc=0 output status suppressed=false
  output="$(_zw_invoke_zc "$team" "$agent" 2>&1)" || rc=$?
  case "$rc" in
    0) status="OK" ;; 1) status="ZOMBIE" ;; 2) status="SUSPECT" ;; 3) status="SKIP" ;;
    *) status="UNKNOWN" ;;
  esac

  local state_dir="${_ZW_STATE_ROOT}/${team}"
  local state_file="${state_dir}/${agent}.state"
  local wake_marker="${state_dir}/${agent}.wake"
  mkdir -p "$state_dir" 2>/dev/null || true

  # R2-5(High, Phase 8-5): 직전 SUSPECT 가 wake-up 을 권장한 이후 inbox 가 갱신됐다면 그
  # 갱신은 "내가 일으킨 갱신"(wake-up 발신·회신)일 수 있어 OK 를 확정 판정으로 신뢰하지
  # 않는다 — SKIP(3, 판정 불가) 로 낮춘다. wake_marker 가 없는 경로(직전이 SUSPECT 가 아니었던
  # 정상 OK)는 그대로 통과해 감지력이 유지된다(R-14). 마커는 1회 관측으로 소비한다.
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
    if _zw_suppress_check "$team" "$agent"; then
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

  # D-3(AUTO_FIX, High): 이 함수의 마지막 문장이 `... || true` 라 항상 exit 0 이었다 —
  # --once 를 run_in_background 로 자동화하는 호출자(§2.5)는 stdout 을 읽지 않고 종료코드만
  # 보므로, SUSPECT/ZOMBIE 여도 rc=0("정상")을 받아 이상 상태가 조용히 사라졌다(F-1과 같은
  # 실패 방향). 억제 게이트 반영 후 최종 status 를 종료코드 계약(0/1/2/3)으로 명시 반환한다.
  # 폴링 루프(_zw_run_loop) 호출부는 이미 `|| true` 로 감싸여 있어 이 반환값 도입에 영향받지 않는다.
  case "$status" in
    OK) return 0 ;;
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
    # D-1/V-2(AUTO_FIX, High): 단건 경로도 다건(L422)과 동일하게 실 pane 미보유 멤버는 제외한다
    # — 종전엔 이 필터가 다건에만 있어 `--once <team> team-lead` 가 시그널#1 단독으로
    # ZOMBIE-CONFIRMED(rc=1, respawn 직결)를 확정했다(verifier 4/4 재현). D-3 rc 그대로 전파.
    local pane; pane="$(_zw_pane_id "$agent" "$team")"
    # V-6(Phase 9-3-2, High): 종전엔 `-n "$pane" && ! =~` 라 빈 pane(config.json/jq 조회
    # 불가 포함)이면 `-n ""`이 거짓이 되어 필터가 통째로 열렸다 — 실 pane 없는 대상이
    # 그대로 _zw_check_one 까지 들어가 오판정됐다(예: `--once <team> team-lead`가 시그널#1
    # 단독으로 ZOMBIE-CONFIRMED 확정). 화이트리스트로 교체: `%N` 형식일 때만 통과, 그 외
    # 전부(빈 값 포함) SKIP.
    [[ "$pane" =~ ^%[0-9]+$ ]] || { echo "SKIP: ${agent} — 실 pane 미보유로 폴링 제외 (team=${team})" >&2; return 3; }
    local rc=0
    _zw_check_one "$team" "$agent" true || rc=$?
    return "$rc"
  fi
  command -v jq >/dev/null 2>&1 || { echo "SKIP: jq 불가 — --once 에 agent 를 직접 지정하십시오" >&2; return 3; }
  local config="${HOME:-}/.claude/teams/${team}/config.json"
  [[ -f "$config" ]] || { echo "SKIP: config.json 없음 (team=${team})" >&2; return 3; }
  local agents a notice
  # D-1/R2-1(Phase 8-5): 실 pane 보유 멤버만 대상 — 제외·0명은 가시화한다(SKIP + rc=3).
  agents="$(jq -r '.members[]? | select(.tmuxPaneId // "" | test("^%[0-9]+$")) | .name' "$config" 2>/dev/null)" || agents=""
  notice="$(_zw_excluded_notice "$team" "$config")"; [[ -n "$notice" ]] && echo "$notice" >&2
  [[ -z "$agents" ]] && { echo "SKIP: team=${team} — 폴링 대상 0명 (전원 실 pane 미보유)" >&2; return 3; }
  # D-3: 다건은 가장 심각한(worst) 판정을 대표값으로 반환한다 — 전원 조용히 0 하나로
  # 뭉개지 않도록. 우선순위는 위 _zw_rc_severity 참조.
  local worst_rc=0 worst_sev=0
  for a in $agents; do
    local rc=0
    _zw_check_one "$team" "$a" true || rc=$?
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

zombie_check.sh 를 subprocess 로만 호출한다(source 금지). 상세는 SUB-SSOT
TEAM-LEAD/2-lifecycle-procedure.md §LIFECYCLE-6 SCHEDULER 참조.
EOF
}

# =============================================================================
# self-test — 본체 500줄 한도(REFACTOR-1) 초과로 zombie_watch_selftest.sh 로 분리했다
# (Phase 8-4 zombie_check.sh/zombie_check_selftest.sh 분리 선례 준용). `--self-test` 는
# 그 파일을 exec 로 위임한다. 호출법·stdout·exit code 는 분리와 무관하게 동일하다.
# =============================================================================

# -----------------------------------------------------------------------------
# CLI 진입점
# -----------------------------------------------------------------------------
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
