#!/usr/bin/env bash
# =============================================================================
# hr1-guard.sh -- PreToolUse Hook: HR-1 Team Lead 코드 수정 경고
# =============================================================================
# 트리거: Edit, Write 도구 사용 시 (PreToolUse)
# 목적: Team Lead가 코드 파일을 직접 수정하려 할 때 경고
#
# Claude Code Hook 프로토콜:
#   stdin으로 JSON 입력: {"tool_name": "Edit", "tool_input": {"file_path": "..."}}
#
# Exit codes:
#   0 -- 경고만, 차단 안함
# =============================================================================

set -euo pipefail

# stdin에서 JSON 입력 읽기
INPUT=$(cat)

# file_path 추출
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')

# file_path가 비어 있으면 통과
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 코드 파일 확장자 목록
# ---------------------------------------------------------------------------
CODE_EXTENSIONS="py ts js tsx jsx"

# 파일 확장자 추출
EXT="${FILE_PATH##*.}"

# ---------------------------------------------------------------------------
# 코드 디렉토리 하위의 코드 파일인지 확인
# ---------------------------------------------------------------------------
IS_CODE_DIR=false
case "$FILE_PATH" in
  backend/*|web/*|tests/*|scripts/*) IS_CODE_DIR=true ;;
  */backend/*|*/web/*|*/tests/*|*/scripts/*) IS_CODE_DIR=true ;;
esac

IS_CODE_EXT=false
for ext in $CODE_EXTENSIONS; do
  if [ "$EXT" = "$ext" ]; then
    IS_CODE_EXT=true
    break
  fi
done

# 코드 디렉토리의 코드 파일이면 경고
if [ "$IS_CODE_DIR" = true ] && [ "$IS_CODE_EXT" = true ]; then
  echo "" >&2
  echo "============================================" >&2
  echo " WARNING: HR-1 위반 가능" >&2
  echo "============================================" >&2
  echo "" >&2
  echo "  Team Lead는 코드 파일을 직접 수정할 수 없습니다." >&2
  echo "  팀원(backend-dev, frontend-dev)을 통해 수정하세요." >&2
  echo "" >&2
  echo "  대상 파일: $FILE_PATH" >&2
  echo "============================================" >&2
  echo "" >&2
fi

exit 0
