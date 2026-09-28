#!/usr/bin/env bash
# prompt-stack.sh -- UserPromptSubmit Hook: 프롬프트 원문 적재
# 트리거: 사용자 프롬프트 제출 시 (UserPromptSubmit)
# 목적: 매 프롬프트 원문을 docs/history/.pending/{YYMMDD}/ 에 자동 저장
#       (이후 log-prompt.sh log 가 work-log 로 회수). 시스템 주입 태그는 제외
#
# Exit codes:
#   0 -- 항상 (적재 성공·건너뜀 무관, 비치명적 훅)

set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HISTORY_DIR="$PROJECT_ROOT/docs/history"
PENDING_ROOT="$HISTORY_DIR/.pending"
TODAY=$(date +%y%m%d)
PENDING_DIR="$PENDING_ROOT/$TODAY"

trap 'exit 0' ERR

# 시스템 태그 제외 목록
readonly SYSTEM_TAGS=(
  "task-notification"
  "system-reminder"
  "command-message"
  "command-name"
  "local-command-stdout"
  "teammate-message"
)

# 시스템 메시지 출력
emit() {
  local msg=${1//\\/\\\\}
  msg=${msg//\"/\\\"}
  printf '{\n  "systemMessage": "%s"\n}\n' "$msg"
}

# 노출 방지 설정 (.gitignore + chmod 700)
ensure_pending_guard() {
  mkdir -p "$1"
  if [ ! -f "$PENDING_ROOT/.gitignore" ]; then
    printf '*\n' > "$PENDING_ROOT/.gitignore"
  fi
  chmod 700 "$PENDING_ROOT" 2>/dev/null || true
  if [ "$1" != "$PENDING_ROOT" ]; then
    chmod 700 "$1" 2>/dev/null || true
  fi
}

# jq 부재 시 적재 건너뜀 (1회 경고)
if ! command -v jq >/dev/null 2>&1; then
  ensure_pending_guard "$PENDING_ROOT"
  JQ_MARKER="$PENDING_ROOT/.jq-missing-${TODAY}"
  if [ ! -f "$JQ_MARKER" ]; then
    touch "$JQ_MARKER" 2>/dev/null || true
    emit "jq를 찾을 수 없어 프롬프트 적재를 건너뜁니다. jq(https://jqlang.org)를 설치하세요."
  fi
  exit 0
fi

INPUT=$(cat 2>/dev/null || true)
PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || true)

if [ -z "$PROMPT" ]; then
  exit 0
fi

# 시스템 주입 태그로 시작하면 건너뜀
TRIMMED="${PROMPT#"${PROMPT%%[![:space:]]*}"}"
for tag in "${SYSTEM_TAGS[@]}"; do
  case "$TRIMMED" in
    "<${tag} "*|"<${tag}>"*) exit 0 ;;
  esac
done

if [ "$(printf '%s' "$PROMPT" | wc -l)" -eq 0 ] && [ "${PROMPT:0:1}" = "/" ]; then
  exit 0
fi

# 적재 파일 기록 (프롬프트 1개당 파일 1개)
ensure_pending_guard "$PENDING_DIR"

FILE="$PENDING_DIR/$(date +%H%M%S)-$$.txt"

printf '%s\n' "$PROMPT" > "$FILE"

COUNT=$(find "$PENDING_DIR" -maxdepth 1 -name '*.txt' 2>/dev/null | wc -l | tr -d ' ')

emit "work-log 실행되었습니다 ${TODAY}-${COUNT}건"

exit 0
