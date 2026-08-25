#!/usr/bin/env bash
# =============================================================================
# line-count-monitor.sh -- PostToolUse Hook: HR-5 줄수 모니터링
# =============================================================================
# 트리거: Edit, Write 도구 사용 후 (PostToolUse)
# 목적: 수정된 파일의 줄수를 검사하여 500줄/700줄 초과 경고
#
# Claude Code Hook 프로토콜:
#   stdin으로 JSON 입력: {"tool_name": "Edit", "tool_input": {"file_path": "..."}}
#
# Exit codes:
#   0 -- 경고만, 차단 안함
# =============================================================================

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"

# 프로젝트별 설정 로드 (없으면 기본값)
PAB_CODE_EXTS="py js ts tsx jsx vue html css"
PAB_LINE_WARN=500
PAB_LINE_CRIT=700
[ -f "$HOOK_DIR/hooks.env" ] && . "$HOOK_DIR/hooks.env"

# stdin에서 JSON 입력 읽기
INPUT=$(cat)

# file_path 추출
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')

# file_path가 비어 있으면 통과
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# 파일이 존재하지 않으면 통과
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 코드 파일만 대상 (HR-5는 코드 파일 규칙 — 문서/SSOT 편집 시 노이즈 방지)
# ---------------------------------------------------------------------------
EXT="${FILE_PATH##*.}"
IS_CODE_EXT=false
for ext in $PAB_CODE_EXTS; do
  if [ "$EXT" = "$ext" ]; then
    IS_CODE_EXT=true
    break
  fi
done
if [ "$IS_CODE_EXT" = false ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 줄수 확인
# ---------------------------------------------------------------------------
LINE_COUNT=$(wc -l < "$FILE_PATH" | tr -d ' ')

if [ "$LINE_COUNT" -gt "$PAB_LINE_CRIT" ]; then
  echo "" >&2
  echo "============================================" >&2
  echo " CRITICAL: [HR-5] $FILE_PATH" >&2
  echo "   ${LINE_COUNT}줄 (${PAB_LINE_CRIT}줄 초과, 리팩토링 검토 필요)" >&2
  echo "============================================" >&2
  echo "" >&2
elif [ "$LINE_COUNT" -gt "$PAB_LINE_WARN" ]; then
  echo "" >&2
  echo "============================================" >&2
  echo " WARNING: [HR-5] $FILE_PATH" >&2
  echo "   ${LINE_COUNT}줄 (${PAB_LINE_WARN}줄 초과, 레지스트리 등록 대상)" >&2
  echo "============================================" >&2
  echo "" >&2
fi

exit 0
