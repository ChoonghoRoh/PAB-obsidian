#!/usr/bin/env bash
# =============================================================================
# ssot-freshness-check.sh -- SessionStart Hook: SSOT 진입점 안내
# =============================================================================
# 트리거: Claude Code SessionStart 이벤트
# 목적: 세션 시작 시 SSOT 버전과 현재 Phase 상태를 표시
#
# Exit codes:
#   0 -- 경고만, 차단 안함
# =============================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

SSOT_DIR="$PROJECT_ROOT/SSOT"
PHASES_DIR="$PROJECT_ROOT/docs/phases"

# ---------------------------------------------------------------------------
# 1. SSOT 진입점 첫 10줄 출력
# ---------------------------------------------------------------------------
ENTRYPOINT="$SSOT_DIR/0-entrypoint.md"
if [ -f "$ENTRYPOINT" ]; then
  echo "=== SSOT Entrypoint (first 10 lines) ===" >&2
  head -n 10 "$ENTRYPOINT" >&2
  echo "=========================================" >&2
else
  echo "WARNING: SSOT entrypoint not found: $ENTRYPOINT" >&2
fi

# ---------------------------------------------------------------------------
# 2. VERSION.md 버전 표시
# ---------------------------------------------------------------------------
VERSION_FILE="$SSOT_DIR/VERSION.md"
if [ -f "$VERSION_FILE" ]; then
  VERSION=$(head -n 5 "$VERSION_FILE" | grep -Ei '(version|v[0-9])' | head -n 1 || head -n 1 "$VERSION_FILE")
  echo "SSOT Version: $VERSION" >&2
else
  echo "WARNING: VERSION.md not found: $VERSION_FILE" >&2
fi

# ---------------------------------------------------------------------------
# 3. 가장 최근 수정된 status.md의 current_state 표시
# ---------------------------------------------------------------------------
if [ -d "$PHASES_DIR" ]; then
  LATEST_STATUS=$(find "$PHASES_DIR" -name "*status.md" -type f -print0 2>/dev/null \
    | xargs -0 ls -t 2>/dev/null \
    | head -n 1 || true)

  if [ -n "$LATEST_STATUS" ]; then
    CURRENT_STATE=$(grep -i 'current_state' "$LATEST_STATUS" 2>/dev/null | head -n 1 || true)
    echo "Latest status file: $LATEST_STATUS" >&2
    if [ -n "$CURRENT_STATE" ]; then
      echo "  $CURRENT_STATE" >&2
    else
      echo "  (current_state not found in status file)" >&2
    fi
  else
    echo "WARNING: No status.md found under $PHASES_DIR" >&2
  fi
else
  echo "WARNING: Phases directory not found: $PHASES_DIR" >&2
fi

exit 0
