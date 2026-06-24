#!/bin/bash
# pab_wiki_worker.sh — headless /pab:wiki 래퍼
# 인자: $1=URL(필수), $2=--dry(선택)
# 보안: URL 정규식 검증, claude 인자 배열 구성, eval 절대 금지

set -euo pipefail

# ── 경로 설정 (report_to_telegram.sh 패턴) ──────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── .env 로드 (없어도 치명적 아님 — 환경에 이미 설정된 경우 대비) ──────────
if [ -f "$PROJECT_ROOT/.env" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$PROJECT_ROOT/.env"
  set +a
else
  echo "WARN: $PROJECT_ROOT/.env not found — relying on pre-set environment variables" >&2
fi

# ── WIKI_VAULT_ROOT 기본값 ──────────────────────────────────────────────────
export WIKI_VAULT_ROOT="${WIKI_VAULT_ROOT:-$PROJECT_ROOT/PAB-LLMDATA}"

# ── 인자 파싱 ───────────────────────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo "ERROR: URL argument required" >&2
  echo "Usage: $0 <url> [--dry]" >&2
  exit 1
fi

INPUT_URL="$1"
DRY_FLAG="${2:-}"

# ── URL 검증 (보안 필수 — 셸 인젝션 방지) ──────────────────────────────────
# eval 절대 금지. 배열 기반 인자 구성.
if ! [[ "$INPUT_URL" =~ ^https?://[^[:space:]]+$ ]]; then
  echo "ERROR: Invalid URL — must match ^https?://[^[:space:]]+$" >&2
  echo "Received: $INPUT_URL" >&2
  exit 2
fi

# 2차 방어심층(F-1): 셸 메타문자 거부 — case glob으로 안전하게(따옴표 escape 오류 방지)
# 금지: $ ` ' " ; | & ( ) < >
case "$INPUT_URL" in
  *'$'* | *'`'* | *"'"* | *'"'* | *';'* | *'|'* | *'&'* | *'('* | *')'* | *'<'* | *'>'* )
    echo "ERROR: URL contains forbidden shell metacharacter" >&2
    exit 2 ;;
esac

if [ -n "$DRY_FLAG" ] && [ "$DRY_FLAG" != "--dry" ]; then
  echo "ERROR: Second argument must be --dry or omitted" >&2
  exit 1
fi

# ── 로그 디렉토리 생성 ───────────────────────────────────────────────────────
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/pab-wiki-$(date +%Y%m%d-%H%M%S).log"

# ── claude 명령 배열 구성 ────────────────────────────────────────────────────
# --bare 절대 사용 금지: bare 모드는 skills/plugins를 스킵하여 /pab:wiki가 로드되지 않음
# URL은 검증된 변수로만 삽입 — 문자열 조립/eval 없음
PROMPT="/pab:wiki ${INPUT_URL}"
if [ "$DRY_FLAG" = "--dry" ]; then
  PROMPT="${PROMPT} --dry"
fi

CLAUDE_CMD=(
  claude
  -p "$PROMPT"
  --plugin-dir "$PROJECT_ROOT"
  --permission-mode dontAsk
  --allowedTools "Bash" "Read" "Write" "WebFetch"
  --output-format json
  --no-session-persistence
)

# ── 실행 ─────────────────────────────────────────────────────────────────────
echo "[pab_wiki_worker] START url=${INPUT_URL} dry=${DRY_FLAG:-false} log=${LOG_FILE}" >&2

cd "$PROJECT_ROOT"

CLAUDE_EXIT=0
CLAUDE_OUTPUT="$("${CLAUDE_CMD[@]}" 2>"${LOG_FILE}.err" | tee "$LOG_FILE")" || CLAUDE_EXIT=$?

# ── 출력 파싱 ─────────────────────────────────────────────────────────────────
if command -v jq &>/dev/null; then
  IS_ERROR="$(printf '%s' "$CLAUDE_OUTPUT" | jq -r '.is_error // false' 2>/dev/null || echo true)"
  RESULT="$(printf '%s' "$CLAUDE_OUTPUT" | jq -r '.result // empty' 2>/dev/null || true)"
  SESSION_ID="$(printf '%s' "$CLAUDE_OUTPUT" | jq -r '.session_id // empty' 2>/dev/null || true)"

  # 스킬 레벨 실패 판정: claude exit 0이어도 is_error/빈 result/Unknown command면 실패
  if [ "$CLAUDE_EXIT" -eq 0 ] && { [ "$IS_ERROR" = "true" ] || [ -z "$RESULT" ] || printf '%s' "$RESULT" | grep -qi "Unknown command"; }; then
    CLAUDE_EXIT=1
  fi
else
  # jq 없으면 raw 출력 그대로 (is_error 판정 생략)
  RESULT="$CLAUDE_OUTPUT"
  SESSION_ID=""
fi

# ── 한 줄 요약 출력 (호출자/리스너가 회신에 사용) ────────────────────────────
if [ "$CLAUDE_EXIT" -eq 0 ]; then
  if [ -n "$SESSION_ID" ]; then
    echo "[PAB-Wiki] SUCCESS session=${SESSION_ID} | ${RESULT:-노트 생성 완료}"
  else
    echo "[PAB-Wiki] SUCCESS | ${RESULT:-노트 생성 완료}"
  fi
else
  echo "[PAB-Wiki] FAILED exit=${CLAUDE_EXIT} | ${RESULT:-자세한 내용은 로그 참조: ${LOG_FILE}} stderr=${LOG_FILE}.err"
fi

exit "$CLAUDE_EXIT"
