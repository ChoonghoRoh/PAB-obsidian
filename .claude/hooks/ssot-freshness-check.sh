#!/usr/bin/env bash
# ssot-freshness-check.sh -- SessionStart Hook: SSOT 상태 요약 + Lazy Load 안내
# 트리거: Claude Code SessionStart 이벤트
# 목적: 세션 시작 시 SSOT 버전·Phase 상태를 최소한으로 표시하고,
#        실제 작업 지시 시에만 SSOT를 로드하도록 안내한다.
#
# Exit codes:
#   0 -- 경고만, 차단 안함

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

SSOT_DIR="$PROJECT_ROOT/docs/SSOT"
PHASES_DIR="$PROJECT_ROOT/docs/phases"

# 0. PROJECT.md → hooks.env 신선도 확인 (변경 감지 시 자동 재동기화)
SYNC_SCRIPT="$PROJECT_ROOT/scripts/sync-project-config.sh"
if [ -x "$SYNC_SCRIPT" ]; then
  if ! "$SYNC_SCRIPT" check 2>/dev/null; then
    "$SYNC_SCRIPT" 2>&1 >/dev/null | head -n 1 >&2 || true
  fi
fi

# hooks.env에서 키 하나를 안전하게 읽는다(CRLF 제거 · 인용부호 벗김 · source하지 않음)
env_read() {
  local key="$1" f="$2" v
  v="$([ -f "$f" ] && sed -n "s/^${key}=//p" "$f" 2>/dev/null | tail -n 1)" || v=""
  v="${v%$'\r'}"
  v="${v#\"}"; v="${v%\"}"
  v="${v#\'}"; v="${v%\'}"
  v="$(printf '%s' "$v" | sed "s/'\\\\''/'/g")"
  printf '%s' "$v"
}

# 모델(additionalContext)에 전달할 경고를 모아둔다
WARNINGS=()

# 프로젝트 요약 1줄 (hooks.env에서)
HOOKS_ENV="$PROJECT_ROOT/.claude/hooks/hooks.env"
PAB_PROJECT_NAME=""
PAB_PROJECT_TYPE="unknown"
if [ -f "$HOOKS_ENV" ]; then
  _val="$(env_read PAB_PROJECT_NAME "$HOOKS_ENV")"
  case "$_val" in ''|*[!A-Za-z0-9._\ -]*) : ;; *) PAB_PROJECT_NAME="$_val" ;; esac
  _val="$(env_read PAB_PROJECT_TYPE "$HOOKS_ENV")"
  case "$_val" in ''|*[!A-Za-z0-9._\ -]*) : ;; *) PAB_PROJECT_TYPE="$_val" ;; esac
  if [ -n "$PAB_PROJECT_NAME" ]; then
    echo "Project: $PAB_PROJECT_NAME ($PAB_PROJECT_TYPE) — 설정: PROJECT.md" >&2
  fi
  # 번들 기본값 미변경 감지: 이식된 프로젝트인데 PROJECT.md가 소스 번들 설정 그대로면 경고
  if [ "$PAB_PROJECT_NAME" = "PAB-claude" ] && [ "$(basename "$PROJECT_ROOT")" != "PAB-claude" ]; then
    MSG="⚠ PROJECT.md가 번들 기본값(PAB-claude) 그대로입니다 — /project-config init 으로 이 프로젝트의 설정을 생성하세요."
    echo "$MSG" >&2
    WARNINGS+=("$MSG")
  fi
fi

# 1. SSOT 버전 (1줄)
ENTRYPOINT_FILE="$SSOT_DIR/entrypoint.md"
VERSION=""
if [ -f "$ENTRYPOINT_FILE" ]; then
  VERSION=$(head -n 10 "$ENTRYPOINT_FILE" | grep -E '^\*\*SSOT 버전\*\*:' | head -n 1 | sed 's/^\*\*SSOT 버전\*\*:[[:space:]]*//;s/[[:space:]]*$//' || true)
fi
if [ -n "$VERSION" ]; then
  echo "SSOT: $VERSION" >&2
else
  echo "SSOT: 버전 미확인" >&2
fi

# 2. 현재 Phase 상태 (1줄)
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

# 3. Lazy Load 지시
cat >&2 <<'INSTRUCTION'
---
[SSOT Lazy Load] 단순 질문·대화에는 SSOT 로드 불필요.
사용자가 코드 작성/수정, 문서·산출물 생성, Phase 진행 등 실제 작업을 지시하면
작업 착수 전 /ssot-reload 를 실행하여 SSOT를 로드한 뒤 진행하라.
INSTRUCTION

# 모아둔 경고를 모델(additionalContext)과 사용자(systemMessage) 양쪽에 전달한다
if [ "${#WARNINGS[@]}" -gt 0 ]; then
  JOINED="$(printf '%s\n' "${WARNINGS[@]}")"
  ESC="$(printf '%s' "$JOINED" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n' ' ')"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"},"systemMessage":"%s"}\n' "$ESC" "$ESC"
fi

exit 0
