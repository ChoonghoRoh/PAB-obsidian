#!/usr/bin/env bash
# =============================================================================
# ssot-freshness-check.sh -- SessionStart Hook: SSOT 상태 요약 + Lazy Load 안내
# =============================================================================
# 트리거: Claude Code SessionStart 이벤트
# 목적: 세션 시작 시 SSOT 버전·Phase 상태를 최소한으로 표시하고,
#        실제 작업 지시 시에만 SSOT를 로드하도록 안내한다.
#
# Exit codes:
#   0 -- 경고만, 차단 안함
# =============================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

SSOT_DIR="$PROJECT_ROOT/docs/SSOT"
PHASES_DIR="$PROJECT_ROOT/docs/phases"

# ---------------------------------------------------------------------------
# 0. PROJECT.md → hooks.env 신선도 확인 (변경 감지 시 자동 재동기화)
# ---------------------------------------------------------------------------
SYNC_SCRIPT="$PROJECT_ROOT/scripts/sync-project-config.sh"
if [ -x "$SYNC_SCRIPT" ]; then
  if ! "$SYNC_SCRIPT" check 2>/dev/null; then
    "$SYNC_SCRIPT" 2>&1 >/dev/null | head -n 1 >&2 || true
  fi
fi

# 프로젝트 요약 1줄 (hooks.env에서)
HOOKS_ENV="$PROJECT_ROOT/.claude/hooks/hooks.env"
if [ -f "$HOOKS_ENV" ]; then
  . "$HOOKS_ENV" 2>/dev/null || true
  if [ -n "${PAB_PROJECT_NAME:-}" ]; then
    echo "Project: $PAB_PROJECT_NAME (${PAB_PROJECT_TYPE:-unknown}) — 설정: PROJECT.md" >&2
  fi
  # 번들 기본값 미변경 감지: 이식된 프로젝트인데 PROJECT.md가 소스 번들 설정 그대로면 경고
  if [ "${PAB_PROJECT_NAME:-}" = "PAB-claude" ] && [ "$(basename "$PROJECT_ROOT")" != "PAB-claude" ]; then
    echo "⚠ PROJECT.md가 번들 기본값(PAB-claude) 그대로입니다 — /project-config init 으로 이 프로젝트의 설정을 생성하세요." >&2
  fi
fi

# ---------------------------------------------------------------------------
# 1. SSOT 버전 (1줄)
# ---------------------------------------------------------------------------
VERSION_FILE="$SSOT_DIR/VERSION.md"
if [ -f "$VERSION_FILE" ]; then
  # 버전 문자열만 추출 (마크다운 원문 노출 방지), 실패 시 기존 방식 폴백
  VERSION=$(head -n 5 "$VERSION_FILE" | grep -oE 'v[0-9][A-Za-z0-9._-]*' | head -n 1 || true)
  if [ -z "$VERSION" ]; then
    VERSION=$(head -n 5 "$VERSION_FILE" | grep -Ei '(version|v[0-9])' | head -n 1 || head -n 1 "$VERSION_FILE")
  fi
  echo "SSOT: $VERSION" >&2
else
  echo "SSOT: VERSION.md not found" >&2
fi

# ---------------------------------------------------------------------------
# 2. 현재 Phase 상태 (1줄)
# ---------------------------------------------------------------------------
if [ -d "$PHASES_DIR" ]; then
  LATEST_STATUS=$(find "$PHASES_DIR" -name "*status.md" -type f -print0 2>/dev/null \
    | xargs -0 -r ls -t 2>/dev/null \
    | head -n 1 || true)

  if [ -n "$LATEST_STATUS" ]; then
    PHASE_NAME=$(basename "$(dirname "$LATEST_STATUS")")
    CURRENT_STATE=$(grep 'current_state:' "$LATEST_STATUS" 2>/dev/null | head -n 1 | sed 's/.*current_state:[[:space:]]*//' | sed 's/[[:space:]]*$//' || true)
    echo "Phase: $PHASE_NAME ($CURRENT_STATE)" >&2
  else
    echo "Phase: none" >&2
  fi
else
  echo "Phase: none" >&2
fi

# ---------------------------------------------------------------------------
# 3. Lazy Load 지시
# ---------------------------------------------------------------------------
cat >&2 <<'INSTRUCTION'
---
[SSOT Lazy Load] 단순 질문·대화에는 SSOT 로드 불필요.
사용자가 코드 작성/수정, 문서·산출물 생성, Phase 진행 등 실제 작업을 지시하면
작업 착수 전 /ssot-reload 를 실행하여 SSOT를 로드한 뒤 진행하라.
INSTRUCTION

exit 0
