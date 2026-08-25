#!/usr/bin/env bash
# =============================================================================
# team-sentinel.sh — SubagentStart/SubagentStop Hook: 팀 활성 센티넬 관리
# =============================================================================
# 용도:
#   SubagentStart → /tmp/agent-teams-active 생성 (팀 활성 표시)
#   SubagentStop  → 남은 팀원이 없으면 센티넬 삭제
#
# 센티넬 파일 내용: 현재 활성 팀원 수 (참고용)
# HR-1 guard가 이 파일 존재 여부로 팀 운영 상태를 판단
#
# Exit codes:
#   0 — 항상 통과
# =============================================================================

set -euo pipefail

SENTINEL="/tmp/agent-teams-active"
ACTION="${1:-start}"

case "$ACTION" in
  start)
    # 카운터 증가
    if [ -f "$SENTINEL" ]; then
      COUNT=$(cat "$SENTINEL" 2>/dev/null || echo "0")
      COUNT=$((COUNT + 1))
    else
      COUNT=1
    fi
    echo "$COUNT" > "$SENTINEL"
    ;;
  stop)
    # 카운터 감소
    if [ -f "$SENTINEL" ]; then
      COUNT=$(cat "$SENTINEL" 2>/dev/null || echo "1")
      COUNT=$((COUNT - 1))
      if [ "$COUNT" -le 0 ]; then
        rm -f "$SENTINEL"
      else
        echo "$COUNT" > "$SENTINEL"
      fi
    fi
    ;;
esac

exit 0
