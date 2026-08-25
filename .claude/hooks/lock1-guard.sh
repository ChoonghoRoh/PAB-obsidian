#!/usr/bin/env bash
# =============================================================================
# lock1-guard.sh — PreToolUse Hook: LOCK-1 Phase 실행 중 SSOT 수정 차단
# =============================================================================
# 트리거: Edit, Write 도구 사용 시 (PreToolUse)
# 목적: Phase가 실행 중(IDLE/DONE 아닌 상태)일 때 docs/SSOT/ 파일 수정 차단
#
# Exit codes:
#   0 — 통과 (SSOT 파일이 아니거나, Phase가 IDLE/DONE이거나, Phase 없음)
#   2 — 차단 (Phase 실행 중 SSOT 수정 시도)
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
# 1. SSOT 파일인지 확인
# ---------------------------------------------------------------------------
IS_SSOT=false
case "$FILE_PATH" in
  docs/SSOT/*|*/docs/SSOT/*) IS_SSOT=true ;;
esac

# SSOT 파일이 아니면 즉시 통과
if [ "$IS_SSOT" = false ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 2. 현재 Phase 상태 확인
# ---------------------------------------------------------------------------
PHASES_DIR="$PROJECT_ROOT/docs/phases"

# Phase 디렉토리 없으면 통과 (Phase 미생성)
if [ ! -d "$PHASES_DIR" ]; then
  exit 0
fi

LATEST_STATUS=$(find "$PHASES_DIR" -name "*status.md" -type f -print0 2>/dev/null \
  | xargs -0 ls -t 2>/dev/null \
  | head -n 1 || true)

# status.md 없으면 통과
if [ -z "$LATEST_STATUS" ]; then
  exit 0
fi

CURRENT_STATE=$(grep 'current_state:' "$LATEST_STATUS" 2>/dev/null \
  | head -n 1 \
  | sed 's/.*current_state:[[:space:]]*//' \
  | sed 's/[[:space:]]*$//' \
  | tr -d '"' || true)

# 상태를 읽지 못했으면 통과
if [ -z "$CURRENT_STATE" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 3. IDLE/DONE이면 통과, 그 외면 차단
# ---------------------------------------------------------------------------
case "$CURRENT_STATE" in
  IDLE|DONE)
    exit 0
    ;;
  *)
    PHASE_NAME=$(basename "$(dirname "$LATEST_STATUS")")
    cat <<JSONEOF
{
  "decision": "block",
  "reason": "LOCK-1: Phase 실행 중(${PHASE_NAME} / ${CURRENT_STATE}) SSOT 수정이 금지됩니다. Phase를 BLOCKED로 전이하거나, IDLE/DONE 상태에서 수정하세요."
}
JSONEOF
    exit 2
    ;;
esac
