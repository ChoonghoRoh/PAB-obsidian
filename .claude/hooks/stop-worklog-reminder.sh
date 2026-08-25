#!/usr/bin/env bash
# =============================================================================
# stop-worklog-reminder.sh — Stop Hook: 세션 종료 시 work-log 미기록 감지
# =============================================================================
# 트리거: Claude Code Stop 이벤트
# 목적: 세션 중 파일 수정이 있었는데 work-log에 기록이 없으면 리마인더 표시
#
# Exit codes:
#   0 — 항상 통과 (정보성 리마인더, 차단하지 않음)
# =============================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# ---------------------------------------------------------------------------
# 1. 오늘자 work-log 파일 확인
# ---------------------------------------------------------------------------
TODAY=$(date +%y%m%d)
WORKLOG="$PROJECT_ROOT/docs/history/${TODAY}-work-log.md"

# work-log 파일이 없으면 리마인더
if [ ! -f "$WORKLOG" ]; then
  cat <<JSONEOF
{
  "systemMessage": "[work-log] 오늘자 작업 기록(${TODAY}-work-log.md)이 없습니다. ./scripts/log-prompt.sh log 실행을 권장합니다."
}
JSONEOF
  exit 0
fi

# ---------------------------------------------------------------------------
# 2. git에서 이번 세션 중 변경된 파일이 있는지 확인
#    git 저장소가 아니면(예: 초기 프로젝트) 변경 감지 불가 → 리마인더 생략.
#    카운트 구간에서만 errexit/pipefail을 꺼서 git 실패 시 이중 출력("0\n0") 방지.
# ---------------------------------------------------------------------------
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

set +e +o pipefail
MODIFIED_COUNT=$(git diff --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')
STAGED_COUNT=$(git diff --name-only --cached 2>/dev/null | wc -l | tr -d ' ')
set -e -o pipefail
: "${MODIFIED_COUNT:=0}" "${STAGED_COUNT:=0}"
TOTAL_CHANGES=$((MODIFIED_COUNT + STAGED_COUNT))

# 변경 파일이 없으면 리마인더 불필요
if [ "$TOTAL_CHANGES" -eq 0 ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 3. work-log에 오늘 기록이 있는지 확인
#    테이블 형식: | 0001 | ... 또는 헤더 형식: #### 0001
# ---------------------------------------------------------------------------
RECORD_COUNT="$(grep -cE '^\| [0-9]{4} \||^#### [0-9]{4}' "$WORKLOG" 2>/dev/null)" || RECORD_COUNT=0

if [ "$RECORD_COUNT" -eq 0 ]; then
  cat <<JSONEOF
{
  "systemMessage": "[work-log] 파일 변경(${TOTAL_CHANGES}건)이 있지만 work-log에 기록이 없습니다. ./scripts/log-prompt.sh log 실행을 권장합니다."
}
JSONEOF
fi

exit 0
