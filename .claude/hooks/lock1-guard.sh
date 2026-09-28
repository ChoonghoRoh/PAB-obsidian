#!/usr/bin/env bash
# lock1-guard.sh — PreToolUse Hook: LOCK-1 Phase 실행 중 SSOT 수정 차단
# 트리거: Edit, Write 도구 사용 시 (PreToolUse)
# 목적: Phase가 실행 중(IDLE/DONE 아닌 상태)일 때 docs/SSOT/ 파일 수정 차단
# 판정 재료를 못 읽으면 통과(fail-open)
#
# Exit codes:
#   0 — 통과 (SSOT 파일이 아니거나, Phase가 IDLE/DONE이거나, Phase 없음)
#   2 — 차단 (Phase 실행 중 SSOT 수정 시도)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# 보호 대상 경로(hooks.env의 PAB_SSOT_PATH — 없으면 기본값 docs/SSOT)
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
PAB_SSOT_PATH="$([ -f "$HOOK_DIR/hooks.env" ] && sed -n 's/^PAB_SSOT_PATH=//p' "$HOOK_DIR/hooks.env" 2>/dev/null | tail -n 1)" || PAB_SSOT_PATH=""
PAB_SSOT_PATH="${PAB_SSOT_PATH%$'\r'}"
PAB_SSOT_PATH="${PAB_SSOT_PATH#\"}"; PAB_SSOT_PATH="${PAB_SSOT_PATH%\"}"
PAB_SSOT_PATH="${PAB_SSOT_PATH#\'}"; PAB_SSOT_PATH="${PAB_SSOT_PATH%\'}"
case "$PAB_SSOT_PATH" in ''|*[!A-Za-z0-9._/\ -]*) PAB_SSOT_PATH="docs/SSOT" ;; esac
case "$PAB_SSOT_PATH" in /*) SSOT_DIR="$PAB_SSOT_PATH" ;; *) SSOT_DIR="$PROJECT_ROOT/$PAB_SSOT_PATH" ;; esac

# 경로 정규화(".."·"." 처리 — 문자열 패턴만으로는 상대경로 우회를 못 잡는다)
norm_path() {
  local rest="${1#/}" out="" comp
  while [ -n "$rest" ]; do
    comp="${rest%%/*}"
    if [ "$comp" = "$rest" ]; then rest=""; else rest="${rest#*/}"; fi
    case "$comp" in
      ''|.) ;;
      ..) out="${out%/*}" ;;
      *) out="$out/$comp" ;;
    esac
  done
  printf '%s\n' "${out:-/}"
}

# 물리 경로(심볼릭 링크 해소) 기준으로 SSOT 루트 하위인지 판정
under_ssot() {
  local d="$1" parent phys
  while [ ! -d "$d" ]; do
    parent="${d%/*}"; [ -n "$parent" ] || parent="/"
    [ "$parent" = "$d" ] && return 1
    d="$parent"
  done
  phys="$(cd -P "$d" 2>/dev/null && pwd -P)" || phys="$d"
  d="$phys"
  while :; do
    [ "$d" -ef "$SSOT_DIR" ] && return 0
    parent="${d%/*}"; [ -n "$parent" ] || parent="/"
    [ "$parent" = "$d" ] && return 1
    d="$parent"
  done
}

# 원형과 정규화한 경로 둘 다로 판정(우회 방지)
check_path() {
  under_ssot "$1" || under_ssot "$(norm_path "$1")"
}

# SSOT 대상 판정 — 1024자 초과 경로는 안전측으로 SSOT 취급, 그 외는 물리 경로 대조
IS_SSOT=false
if [ "${#FILE_PATH}" -gt 1024 ]; then
  IS_SSOT=true
elif [ -d "$SSOT_DIR" ]; then
  case "$FILE_PATH" in
    /*) check_path "$FILE_PATH" && IS_SSOT=true ;;
    "~"|"~"/*) if [ -n "${HOME:-}" ]; then check_path "$HOME${FILE_PATH#"~"}" && IS_SSOT=true; else IS_SSOT=true; fi ;;
    "~"*/"$PAB_SSOT_PATH"/*) IS_SSOT=true ;;
    *) { check_path "$PROJECT_ROOT/$FILE_PATH" || check_path "$PWD/$FILE_PATH"; } && IS_SSOT=true ;;
  esac
else
  case "$FILE_PATH" in
    "$PAB_SSOT_PATH"/*|*/"$PAB_SSOT_PATH"/*) IS_SSOT=true ;;
  esac
fi

if [ "$IS_SSOT" = false ]; then
  exit 0
fi

# 현재 Phase 상태 확인
PHASES_DIR="$PROJECT_ROOT/docs/phases"

if [ ! -d "$PHASES_DIR" ]; then
  exit 0
fi

LATEST_STATUS=$(find "$PHASES_DIR" -name "*status.md" -type f -print0 2>/dev/null \
  | xargs -0 ls -t 2>/dev/null \
  | head -n 1 || true)

if [ -z "$LATEST_STATUS" ]; then
  exit 0
fi

CURRENT_STATE=$(grep 'current_state:' "$LATEST_STATUS" 2>/dev/null \
  | head -n 1 \
  | sed 's/#.*$//' \
  | sed 's/.*current_state:[[:space:]]*//' \
  | sed 's/[[:space:]]*$//' \
  | tr -d '"' || true)

if [ -z "$CURRENT_STATE" ]; then
  exit 0
fi

# IDLE/DONE이면 통과, 그 외면 차단
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
