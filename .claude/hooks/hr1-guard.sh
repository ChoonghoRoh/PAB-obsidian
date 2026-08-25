#!/usr/bin/env bash
# =============================================================================
# hr1-guard.sh -- PreToolUse Hook: HR-1 코드 직접 수정 제어
# =============================================================================
# 트리거: Edit, Write 도구 사용 시 (PreToolUse)
# 목적: 팀 운영 시 Team Lead가 코드 디렉토리의 코드 파일을 직접 수정하면 차단
#        단독 운영 시에는 경고만 표시
#
# 대상 디렉토리·확장자: hooks.env의 PAB_CODE_DIRS / PAB_CODE_EXTS
#   (다른 프로젝트 이식 시 hooks.env만 수정하면 됨)
#
# 팀 활성 감지: /tmp/agent-teams-active 센티넬 파일 존재 여부
#   - SubagentStart 훅에서 생성, SubagentStop 훅에서 팀원 0명 시 삭제
#
# Claude Code Hook 프로토콜:
#   stdin으로 JSON 입력: {"tool_name": "Edit", "tool_input": {"file_path": "..."}}
#
# Exit codes:
#   0 -- 통과 (단독 운영 시 경고만, 또는 비코드 파일)
#   2 -- 차단 (팀 운영 중 코드 수정 시도)
# =============================================================================

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
SENTINEL="/tmp/agent-teams-active"

# 프로젝트별 설정 로드 (없으면 기본값)
PAB_CODE_DIRS="backend web src app frontend e2e"
PAB_CODE_EXTS="py js ts tsx jsx vue html css"
[ -f "$HOOK_DIR/hooks.env" ] && . "$HOOK_DIR/hooks.env"

# stdin에서 JSON 입력 읽기
INPUT=$(cat)

# file_path 추출
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)

# file_path가 비어 있으면 통과
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 코드 디렉토리 하위의 코드 파일인지 확인
# ---------------------------------------------------------------------------
EXT="${FILE_PATH##*.}"

IS_CODE_DIR=false
for dir in $PAB_CODE_DIRS; do
  case "$FILE_PATH" in
    "$dir"/*|*/"$dir"/*) IS_CODE_DIR=true; break ;;
  esac
done

IS_CODE_EXT=false
for ext in $PAB_CODE_EXTS; do
  if [ "$EXT" = "$ext" ]; then
    IS_CODE_EXT=true
    break
  fi
done

# 코드 파일이 아니면 통과
if [ "$IS_CODE_DIR" = false ] || [ "$IS_CODE_EXT" = false ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 팀 활성 여부에 따라 차단 또는 경고
# ---------------------------------------------------------------------------
if [ -f "$SENTINEL" ]; then
  # 팀 운영 중 → 차단
  cat <<JSONEOF
{
  "decision": "block",
  "reason": "HR-1: 팀 운영 중에는 Team Lead가 코드를 직접 수정할 수 없습니다. backend-dev 또는 frontend-dev 팀원에게 위임하세요. 대상: ${FILE_PATH}"
}
JSONEOF
  exit 2
else
  # 단독 운영 → 경고만
  echo "" >&2
  echo "============================================" >&2
  echo " INFO: 코드 수정 감지 (단독 운영 — HR-1 경고)" >&2
  echo "  대상 파일: $FILE_PATH" >&2
  echo "============================================" >&2
  echo "" >&2
  exit 0
fi
