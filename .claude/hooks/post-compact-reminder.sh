#!/usr/bin/env bash
# =============================================================================
# post-compact-reminder.sh — PostCompact Hook: SSOT 컨텍스트 복구 리마인더
# =============================================================================
# 트리거: Claude Code PostCompact 이벤트 (auto/manual)
# 목적: 컨텍스트 압축 후 SSOT 버전·Phase 상태·핵심 규칙을 모델에 재주입
#        (FRESH-7: 컨텍스트 복구 시 SSOT 리로드 필수)
#
# 출력: JSON — hookSpecificOutput.additionalContext 로 모델 컨텍스트에 주입
#
# Exit codes:
#   0 — 항상 통과 (정보 주입 전용, 차단하지 않음)
# =============================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# ---------------------------------------------------------------------------
# 1. SSOT 버전 수집
# ---------------------------------------------------------------------------
SSOT_VERSION="unknown"
VERSION_FILE="$PROJECT_ROOT/docs/SSOT/VERSION.md"
if [ -f "$VERSION_FILE" ]; then
  SSOT_VERSION=$(grep -oP 'v[0-9]+\.[0-9]+-[a-zA-Z0-9-]+' "$VERSION_FILE" | head -n 1 || echo "unknown")
fi

# ---------------------------------------------------------------------------
# 2. 현재 Phase 상태 수집
# ---------------------------------------------------------------------------
PHASE_INFO="없음 (활성 Phase 없음)"
PHASES_DIR="$PROJECT_ROOT/docs/phases"
if [ -d "$PHASES_DIR" ]; then
  LATEST_STATUS=$(find "$PHASES_DIR" -name "*status.md" -type f -print0 2>/dev/null \
    | xargs -0 ls -t 2>/dev/null \
    | head -n 1 || true)

  if [ -n "$LATEST_STATUS" ]; then
    PHASE_NAME=$(basename "$(dirname "$LATEST_STATUS")")
    CURRENT_STATE=$(grep 'current_state:' "$LATEST_STATUS" 2>/dev/null \
      | head -n 1 \
      | sed 's/.*current_state:[[:space:]]*//' \
      | sed 's/[[:space:]]*$//' \
      | tr -d '"' || true)
    BLOCKERS=$(grep -c 'blocker' "$LATEST_STATUS" 2>/dev/null || echo "0")
    PHASE_INFO="${PHASE_NAME} / ${CURRENT_STATE:-unknown} / blockers: ${BLOCKERS}"
  fi
fi

# ---------------------------------------------------------------------------
# 3. additionalContext 구성
# ---------------------------------------------------------------------------
CONTEXT=$(cat <<CTXEOF
[FRESH-7 컨텍스트 복구] 컨텍스트 압축이 발생했습니다. 아래 정보를 참고하세요.

■ SSOT 버전: ${SSOT_VERSION}
■ 활성 Phase: ${PHASE_INFO}

■ 핵심 운영 규칙 (압축으로 유실 가능):
  - HR-1: 팀 운영 시 Team Lead는 코드 직접 수정 금지 (팀원에게 위임)
  - LOCK-1: Phase 실행 중(IDLE/DONE 제외) SSOT 문서 수정 금지
  - ENTRY-1: Phase 작업은 반드시 status.md를 먼저 읽고 시작
  - FRESH-7: 컨텍스트 복구 후 /ssot-reload 실행 권장

■ 실제 작업 착수 전 /ssot-reload 를 실행하여 SSOT를 완전히 로드하세요.
CTXEOF
)

# ---------------------------------------------------------------------------
# 4. JSON 출력 (hookSpecificOutput.additionalContext)
# ---------------------------------------------------------------------------
# jq가 있으면 안전하게 이스케이프, 없으면 수동 이스케이프
if command -v jq &>/dev/null; then
  ESCAPED=$(echo "$CONTEXT" | jq -Rs .)
  cat <<JSONEOF
{
  "systemMessage": "[FRESH-7] 컨텍스트 압축 감지 — SSOT: ${SSOT_VERSION}, Phase: ${PHASE_INFO}",
  "hookSpecificOutput": {
    "hookEventName": "PostCompact",
    "additionalContext": ${ESCAPED}
  }
}
JSONEOF
else
  # jq 미설치 시 최소 출력
  cat <<JSONEOF
{
  "systemMessage": "[FRESH-7] 컨텍스트 압축 감지 — /ssot-reload 실행 권장. SSOT: ${SSOT_VERSION}"
}
JSONEOF
fi

exit 0
