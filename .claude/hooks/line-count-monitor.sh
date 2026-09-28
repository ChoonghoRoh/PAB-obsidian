#!/usr/bin/env bash
# line-count-monitor.sh -- PostToolUse Hook: HR-5 줄수 모니터링
# 트리거: Edit, Write 도구 사용 후 (PostToolUse)
# 목적: 수정된 파일의 줄수를 검사하여 500줄/700줄 초과 경고
#
# Claude Code Hook 프로토콜:
#   stdin으로 JSON 입력: {"tool_name": "Edit", "tool_input": {"file_path": "..."}}
#
# Exit codes:
#   0 -- 경고만, 차단 안함

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"

# 프로젝트별 설정 로드 (없으면 기본값) — hooks.env는 source하지 않고 값만 읽는다
PAB_CODE_EXTS="py js ts tsx jsx vue html css"
PAB_LINE_WARN=500
PAB_LINE_CRIT=700

# hooks.env에서 키 하나를 안전하게 읽는다(CRLF 제거 · 인용부호 벗김)
env_read() {
  local key="$1" f="$2" v
  v="$([ -f "$f" ] && sed -n "s/^${key}=//p" "$f" 2>/dev/null | tail -n 1)" || v=""
  v="${v%$'\r'}"
  v="${v#\"}"; v="${v%\"}"
  v="${v#\'}"; v="${v%\'}"
  v="$(printf '%s' "$v" | sed "s/'\\\\''/'/g")"
  printf '%s' "$v"
}

_val="$(env_read PAB_CODE_EXTS "$HOOK_DIR/hooks.env")"
case "$_val" in ''|*[!A-Za-z0-9._\ -]*) : ;; *) PAB_CODE_EXTS="$_val" ;; esac
_val="$(env_read PAB_LINE_WARN "$HOOK_DIR/hooks.env")"
case "$_val" in ''|*[!0-9]*) : ;; *) PAB_LINE_WARN="$_val" ;; esac
_val="$(env_read PAB_LINE_CRIT "$HOOK_DIR/hooks.env")"
case "$_val" in ''|*[!0-9]*) : ;; *) PAB_LINE_CRIT="$_val" ;; esac

INPUT=$(cat)

# file_path 추출
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# 코드 파일만 대상 (HR-5는 코드 파일 규칙 — 문서/SSOT 편집 시 노이즈 방지)
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

# 줄수 확인
LINE_COUNT=$(wc -l < "$FILE_PATH" | tr -d ' ')

# JSON 문자열 안에 넣을 수 있게 이스케이프한다
json_esc() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

MSG=""
if [ "$LINE_COUNT" -gt "$PAB_LINE_CRIT" ]; then
  echo "" >&2
  echo "============================================" >&2
  echo " CRITICAL: [HR-5] $FILE_PATH" >&2
  echo "   ${LINE_COUNT}줄 (${PAB_LINE_CRIT}줄 초과, 리팩토링 검토 필요)" >&2
  echo "============================================" >&2
  echo "" >&2
  MSG="CRITICAL: [HR-5] ${FILE_PATH} — ${LINE_COUNT}줄(${PAB_LINE_CRIT}줄 초과, 리팩토링 검토 필요)"
elif [ "$LINE_COUNT" -gt "$PAB_LINE_WARN" ]; then
  echo "" >&2
  echo "============================================" >&2
  echo " WARNING: [HR-5] $FILE_PATH" >&2
  echo "   ${LINE_COUNT}줄 (${PAB_LINE_WARN}줄 초과, 레지스트리 등록 대상)" >&2
  echo "============================================" >&2
  echo "" >&2
  MSG="WARNING: [HR-5] ${FILE_PATH} — ${LINE_COUNT}줄(${PAB_LINE_WARN}줄 초과, 레지스트리 등록 대상)"
fi

# 경고를 모델(additionalContext)과 사용자(systemMessage) 양쪽에 전달한다
if [ -n "$MSG" ]; then
  ESC="$(json_esc "$MSG")"
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"},"systemMessage":"%s"}\n' "$ESC" "$ESC"
fi

exit 0
