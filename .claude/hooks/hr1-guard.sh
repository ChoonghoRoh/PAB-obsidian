#!/usr/bin/env bash
# hr1-guard.sh -- PreToolUse Hook: HR-1 코드 직접 수정 제어
# 트리거: Edit, Write 도구 사용 시 (PreToolUse)
# 목적: 팀 운영 시 Team Lead가 코드 디렉토리의 코드 파일을 직접 수정하면 차단
#        단독 운영 시에는 경고만 표시
#
# 대상 디렉토리·확장자: hooks.env의 PAB_CODE_DIRS / PAB_CODE_EXTS
#   (PROJECT.md code_dirs/code_exts → hooks.env로 생성 — 직접 수정 금지)
#
# 팀 활성 감지: /tmp/agent-teams-active-<session_id> 센티넬 파일 존재 여부
#   - PreToolUse(Agent|Task) spawn · Stop reconcile로 생성·갱신, SessionEnd end로 삭제
#
# Claude Code Hook 프로토콜:
#   stdin으로 JSON 입력: {"tool_name": "Edit", "tool_input": {"file_path": "..."}}
#
# Exit codes:
#   0 -- 통과 (단독 운영 시 경고만, 또는 비코드 파일, 또는 팀원 위임 수정)
#   2 -- 차단 (팀 운영 중 Team Lead의 코드 수정 시도)

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
SENTINEL_BASE="/tmp/agent-teams-active"

PAB_CODE_DIRS="backend web src app frontend e2e"
PAB_CODE_EXTS="py js ts tsx jsx vue html css"

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

PAB_CODE_DIRS_IN="$(env_read PAB_CODE_DIRS "$HOOK_DIR/hooks.env")"
case "$PAB_CODE_DIRS_IN" in ''|*[!A-Za-z0-9._/\ -]*) : ;; *) PAB_CODE_DIRS="$PAB_CODE_DIRS_IN" ;; esac
PAB_CODE_EXTS_IN="$(env_read PAB_CODE_EXTS "$HOOK_DIR/hooks.env")"
case "$PAB_CODE_EXTS_IN" in ''|*[!A-Za-z0-9._\ -]*) : ;; *) PAB_CODE_EXTS="$PAB_CODE_EXTS_IN" ;; esac

INPUT=$(cat)

# 최상위 키 파싱(file_path · agent_id · agent_type)
FILE_PATH=""
AGENT_ID=""
AGENT_TYPE=""
PARSED=0

if command -v python3 >/dev/null 2>&1; then
  _EVAL=$(printf '%s' "$INPUT" | python3 -c '
import json, shlex, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(1)
if not isinstance(d, dict):
    sys.exit(1)
ti = d.get("tool_input")
fp = ti.get("file_path") if isinstance(ti, dict) else ""
def q(v):
    return shlex.quote("" if v is None else str(v))
print("FILE_PATH=" + q(fp))
print("AGENT_ID=" + q(d.get("agent_id")))
print("AGENT_TYPE=" + q(d.get("agent_type")))
print("PARSED=1")
' 2>/dev/null) || _EVAL=""
  if [ -n "$_EVAL" ]; then
    eval "$_EVAL"
  fi
fi

if [ "$PARSED" -eq 0 ]; then
  FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)
  PREFIX="${INPUT%%\"tool_input\"*}"
  AGENT_ID=$(printf '%s' "$PREFIX" | grep -o '"agent_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*"agent_id"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)
  AGENT_TYPE=$(printf '%s' "$PREFIX" | grep -o '"agent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*"agent_type"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)
fi

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# 코드 디렉토리 하위의 코드 파일인지 확인
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

if [ "$IS_CODE_DIR" = false ] || [ "$IS_CODE_EXT" = false ]; then
  exit 0
fi

# 호출자 판별 — agent_id가 있으면 팀원 본인의 위임 수정이므로 통과시킨다(C-5).
# agent_type만으로는 통과시키지 않는다(U-3) — tmux 팀원은 세션 분리로 아래 SessionCheck에서 걸러진다.
if [ -n "$AGENT_ID" ]; then
  echo "" >&2
  echo " INFO: HR-1 — 팀원 호출(agent_type=${AGENT_TYPE:-unknown}) 위임 수정 통과: $FILE_PATH" >&2
  echo "" >&2
  exit 0
fi

# 팀 활성 판정 — 자기 세션 센티넬만 본다. 전역 파일은 보지 않는다(C-4)
SESSION_ID=""
if [ "$PARSED" -eq 1 ] && command -v python3 >/dev/null 2>&1; then
  SESSION_ID=$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("session_id") or "")' 2>/dev/null || true)
fi
if [ -z "$SESSION_ID" ] && [ -n "$INPUT" ]; then
  SESSION_PREFIX="${INPUT%%\"tool_input\"*}"
  SESSION_ID=$(printf '%s' "$SESSION_PREFIX" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*"session_id"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)
fi

TEAM_ACTIVE=false
if [ -n "$SESSION_ID" ] && [ -f "${SENTINEL_BASE}-${SESSION_ID}" ]; then
  TEAM_ACTIVE=true
fi

if [ "$TEAM_ACTIVE" = true ]; then
  cat <<JSONEOF
{
  "decision": "block",
  "reason": "HR-1: 팀 운영 중 Team Lead는 코드를 직접 수정할 수 없습니다. backend-dev 또는 frontend-dev 팀원에게 위임하세요(팀원 본인의 수정은 차단되지 않습니다). 팀원이 모두 종료되면 다음 응답이 끝날 때 자동 해제됩니다. 대상: ${FILE_PATH}"
}
JSONEOF
  exit 2
else
  MSG="코드 수정 감지(단독 운영 — HR-1 경고): ${FILE_PATH}"
  echo "" >&2
  echo "============================================" >&2
  echo " INFO: 코드 수정 감지 (단독 운영 — HR-1 경고)" >&2
  echo "  대상 파일: $FILE_PATH" >&2
  echo "============================================" >&2
  echo "" >&2
  ESC="$(printf '%s' "$MSG" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"},"systemMessage":"%s"}\n' "$ESC" "$ESC"
  exit 0
fi
