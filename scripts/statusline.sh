#!/usr/bin/env bash
# =============================================================================
# statusline.sh — Claude Code 터미널 하단 인포창(Status Line) 스크립트
# =============================================================================
# 설정 위치: .claude/settings.json
#   "statusLine": { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR/scripts/statusline.sh\"" }
#
# Claude Code가 stdin으로 세션 JSON을 전달하면, 첫 줄 stdout이 인포창에 표시된다.
# 표시 항목: 모델 | 폴더 | git 브랜치 | 프로젝트(PROJECT.md) | SSOT 버전 | Phase 상태
#
# 디버그: echo '{}' | ./scripts/statusline.sh  로 단독 실행 가능
# =============================================================================

INPUT=$(cat 2>/dev/null || true)

# JSON에서 "key": "value" 추출 (jq 없이 동작)
get_json() {
  echo "$INPUT" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -n 1 \
    | sed "s/.*:[[:space:]]*\"//;s/\"\$//"
}

# --- 1. 모델 · 디렉토리 (Claude Code 제공 JSON) ---
MODEL=$(get_json "display_name")
[ -z "$MODEL" ] && MODEL="Claude"

CUR_DIR=$(get_json "current_dir")
[ -z "$CUR_DIR" ] && CUR_DIR="$(pwd)"

PROJECT_DIR=$(get_json "project_dir")
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="$CUR_DIR"

DIR_NAME=$(basename "$CUR_DIR")

# --- 2. git 브랜치 ---
BRANCH=$(git -C "$CUR_DIR" branch --show-current 2>/dev/null || true)

# --- 3. PAB 프로젝트 설정 (PROJECT.md → hooks.env) ---
PAB_PROJECT_NAME=""
PAB_SSOT_VERSION=""
if [ -f "$PROJECT_DIR/.claude/hooks/hooks.env" ]; then
  . "$PROJECT_DIR/.claude/hooks/hooks.env" 2>/dev/null || true
fi

# --- 4. 현재 Phase 상태 (가장 최근 status.md) ---
PHASE_INFO=""
PHASES_DIR="$PROJECT_DIR/docs/phases"
if [ -d "$PHASES_DIR" ]; then
  LATEST=$(find "$PHASES_DIR" -name "*status.md" -type f -print0 2>/dev/null \
    | xargs -0 -r ls -t 2>/dev/null | head -n 1 || true)
  if [ -n "$LATEST" ]; then
    STATE=$(grep 'current_state:' "$LATEST" 2>/dev/null | head -n 1 \
      | sed 's/.*current_state:[[:space:]]*//;s/["'"'"'[:space:]]*$//' || true)
    PHASE_NAME=$(basename "$LATEST" | sed 's/-status\.md$//;s/\.md$//')
    [ -n "$STATE" ] && PHASE_INFO="${PHASE_NAME}:${STATE}"
  fi
fi

# --- 5. 조립 (ANSI 색상: dim 구분자) ---
SEP=$(printf '\033[2m|\033[0m')
LINE="🧠 ${MODEL} ${SEP} 📁 ${DIR_NAME}"
[ -n "$BRANCH" ]           && LINE="${LINE} ${SEP} 🌿 ${BRANCH}"
[ -n "$PAB_PROJECT_NAME" ] && LINE="${LINE} ${SEP} 📌 ${PAB_PROJECT_NAME}"
[ -n "$PAB_SSOT_VERSION" ] && LINE="${LINE} ${SEP} SSOT ${PAB_SSOT_VERSION}"
if [ -n "$PHASE_INFO" ]; then
  LINE="${LINE} ${SEP} ⚙ ${PHASE_INFO}"
else
  LINE="${LINE} ${SEP} ⚙ Phase:none"
fi

echo "$LINE"
