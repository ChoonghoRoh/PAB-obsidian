#!/usr/bin/env bash
# =============================================================================
# state-transition-guard.sh — PostToolUse Hook: 상태 전이 유효성 검증
# =============================================================================
# 트리거: Edit, Write 도구 사용 후 (PostToolUse)
# 목적: status.md의 current_state 변경 시 유효한 전이인지 검증
#        + 재시도·반복 카운터 상한 초과 기록 차단 (AutoCycle 안전장치)
#
# 전이 규칙: SSOT 3-workflow.md §1.1 상태 머신 (20개 상태) 기반
# BLOCKED, REWINDING은 모든 상태에서 진입 가능
# 카운터 상한: retry_count 3 / auto_fix_count 3 /
#              pre_build_iteration_counter 3 (ITER-PRE) / replan_counter 2 (ITER-POST)
# 파싱 계약: YAML 값(카운터·current_state)은 `#` 이후를 주석으로 절단한 뒤 파싱한다
#
# Exit codes:
#   0 — 통과 (status.md 아니거나, 정상 전이이거나, 상태 변경 없음)
#   2 — 카운터 상한 초과 (PostToolUse 특성상 편집 롤백은 아니며, 위반 내용을
#       에이전트에 강제 피드백 — 원복 + 사용자 에스컬레이션을 지시)
# =============================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# stdin에서 JSON 입력 읽기
INPUT=$(cat)

# file_path 추출
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)

# file_path가 비어 있으면 통과
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 1. status.md 파일인지 확인
# ---------------------------------------------------------------------------
BASENAME=$(basename "$FILE_PATH")
case "$BASENAME" in
  *-status.md) ;;
  *) exit 0 ;;
esac

# 절대 경로로 변환
if [[ "$FILE_PATH" != /* ]]; then
  FILE_PATH="$PROJECT_ROOT/$FILE_PATH"
fi

# 파일이 존재하지 않으면 통과
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 1.5 재시도·반복 카운터 상한 검사 (상태 전이와 무관하게 항상 수행)
# ---------------------------------------------------------------------------
# YAML 정수 필드 추출 (없으면 빈 값)
read_counter() {
  grep -E "^${1}:" "$FILE_PATH" 2>/dev/null \
    | head -n 1 \
    | sed 's/#.*$//' \
    | sed "s/^${1}:[[:space:]]*//" \
    | tr -d "\"'" \
    | sed 's/^+//' \
    | sed 's/^\([0-9]*\).*/\1/' || true
}

check_limit() {
  local name="$1" value="$2" limit="$3" rule="$4"
  if [ -n "$value" ] && [ "$value" -gt "$limit" ] 2>/dev/null; then
    echo "" >&2
    echo "============================================" >&2
    echo " BLOCKED: ${name} 상한 초과 (${value} > ${limit})" >&2
    echo "" >&2
    echo "  ${rule}" >&2
    echo "  이 값을 status.md에 기록할 수 없습니다." >&2
    echo "  → 카운터를 ${limit} 이하로 원복하고," >&2
    echo "    HUMAN_ESCALATION_REQUEST로 사용자 판단을 받으세요." >&2
    echo "============================================" >&2
    echo "" >&2
    exit 2
  fi
}

check_limit "retry_count"                "$(read_counter retry_count)"                3 "retry_count ≥ 3 → 접근방식 폐기 + 사용자 판단 대기 (3-workflow.md §6.1)"
check_limit "auto_fix_count"             "$(read_counter auto_fix_count)"             3 "AUTO_FIX 3회 초과 → 에스컬레이션 (5-automation.md AUTO-2)"
check_limit "pre_build_iteration_counter" "$(read_counter pre_build_iteration_counter)" 3 "ITER-PRE 4회차 절대 금지 (orchestration-procedure §ITER-PRE)"
check_limit "replan_counter"             "$(read_counter replan_counter)"             2 "ITER-POST 2회 초과 → Tech Debt 전이 (orchestration-procedure §ITER-POST)"

# ---------------------------------------------------------------------------
# 2. 현재 상태 읽기 (변경 후)
# ---------------------------------------------------------------------------
NEW_STATE=$(grep 'current_state:' "$FILE_PATH" 2>/dev/null \
  | head -n 1 \
  | sed 's/.*current_state:[[:space:]]*//' \
  | sed 's/#.*$//' \
  | sed 's/[[:space:]]*$//' \
  | tr -d '"' || true)

if [ -z "$NEW_STATE" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 2.5 REWINDING 재진입 차단 — retry_count 소진(≥3) 후 4회차 재시도 금지
#     (git 이력 유무와 무관하게 항상 검사)
# ---------------------------------------------------------------------------
if [ "$NEW_STATE" = "REWINDING" ]; then
  RETRY_NOW="$(read_counter retry_count)"
  if [ -n "$RETRY_NOW" ] && [ "$RETRY_NOW" -ge 3 ] 2>/dev/null; then
    echo "" >&2
    echo "============================================" >&2
    echo " BLOCKED: retry_count 소진(${RETRY_NOW}) 상태에서 REWINDING 재진입" >&2
    echo "" >&2
    echo "  4회차 재시도는 금지입니다 (3-workflow.md §6.1)." >&2
    echo "  → 접근방식을 폐기하고 에러 로그와 함께" >&2
    echo "    사용자 판단(HUMAN_ESCALATION_REQUEST)을 받으세요." >&2
    echo "============================================" >&2
    echo "" >&2
    exit 2
  fi
fi

# ---------------------------------------------------------------------------
# 3. 이전 상태 읽기 (git에서)
# ---------------------------------------------------------------------------
OLD_STATE=$(cd "$PROJECT_ROOT" && git show HEAD:"${FILE_PATH#$PROJECT_ROOT/}" 2>/dev/null \
  | grep 'current_state:' \
  | head -n 1 \
  | sed 's/.*current_state:[[:space:]]*//' \
  | sed 's/#.*$//' \
  | sed 's/[[:space:]]*$//' \
  | tr -d '"' || true)

# 이전 상태를 못 읽으면 (신규 파일 등) 통과
if [ -z "$OLD_STATE" ]; then
  exit 0
fi

# 상태 변경이 없으면 통과
if [ "$OLD_STATE" = "$NEW_STATE" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 4. BLOCKED, REWINDING은 모든 상태에서 진입 가능 (REWINDING 상한은 §2.5에서 검사)
# ---------------------------------------------------------------------------
case "$NEW_STATE" in
  BLOCKED|REWINDING)
    exit 0
    ;;
esac

# ---------------------------------------------------------------------------
# 5. 유효 전이 테이블
# ---------------------------------------------------------------------------
is_valid_transition() {
  local from="$1"
  local to="$2"

  case "$from" in
    IDLE)              [[ "$to" == "TEAM_SETUP" ]] ;;
    TEAM_SETUP)        [[ "$to" =~ ^(RESEARCH|PLANNING)$ ]] ;;
    RESEARCH)          [[ "$to" == "RESEARCH_REVIEW" ]] ;;
    RESEARCH_REVIEW)   [[ "$to" =~ ^(PLANNING|RESEARCH)$ ]] ;;
    PLANNING)          [[ "$to" == "PLAN_REVIEW" ]] ;;
    PLAN_REVIEW)       [[ "$to" =~ ^(DESIGN_REVIEW|TASK_SPEC|PLANNING)$ ]] ;;
    DESIGN_REVIEW)     [[ "$to" =~ ^(TASK_SPEC|PLANNING)$ ]] ;;
    TASK_SPEC)         [[ "$to" =~ ^(BRANCH_CREATION|BUILDING)$ ]] ;;
    BRANCH_CREATION)   [[ "$to" == "BUILDING" ]] ;;
    BUILDING)          [[ "$to" =~ ^(VERIFYING|AUTO_FIX)$ ]] ;;
    AUTO_FIX)          [[ "$to" =~ ^(VERIFYING|BUILDING)$ ]] ;;
    VERIFYING)         [[ "$to" =~ ^(TESTING|BUILDING)$ ]] ;;
    TESTING)           [[ "$to" =~ ^(AB_COMPARISON|INTEGRATION|BUILDING)$ ]] ;;
    AB_COMPARISON)     [[ "$to" =~ ^(INTEGRATION|BUILDING)$ ]] ;;
    INTEGRATION)       [[ "$to" =~ ^(E2E|BUILDING)$ ]] ;;
    E2E)               [[ "$to" =~ ^(E2E_REPORT|BUILDING)$ ]] ;;
    E2E_REPORT)        [[ "$to" == "TEAM_SHUTDOWN" ]] ;;
    TEAM_SHUTDOWN)     [[ "$to" == "DONE" ]] ;;
    BLOCKED)           return 0 ;;  # BLOCKED에서는 모든 상태로 복귀 가능
    REWINDING)         return 0 ;;  # REWINDING에서는 모든 상태로 복귀 가능
    DONE)              return 1 ;;  # DONE에서는 전이 불가
    *)                 return 1 ;;
  esac
}

if ! is_valid_transition "$OLD_STATE" "$NEW_STATE"; then
  echo "" >&2
  echo "============================================" >&2
  echo " WARNING: 비정상 상태 전이 감지" >&2
  echo "   ${OLD_STATE} → ${NEW_STATE}" >&2
  echo "" >&2
  echo "  허용되지 않는 전이입니다." >&2
  echo "  3-workflow.md 상태 머신 규칙을 확인하세요." >&2
  echo "============================================" >&2
  echo "" >&2
fi

exit 0
