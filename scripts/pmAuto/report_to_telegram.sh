#!/usr/bin/env bash
# =============================================================================
# report_to_telegram.sh — NOTIFY-1(구 HR-8) Telegram 알림 발송기
# =============================================================================
# 사용법:
#   bash scripts/pmAuto/report_to_telegram.sh "프로젝트라벨" "메시지"
#
# 토큰 설정 (우선순위 순 — 스크립트에 토큰 하드코딩 금지):
#   1. 환경변수:  export PAB_TELEGRAM_BOT_TOKEN=... PAB_TELEGRAM_CHAT_ID=...
#   2. .env 파일: 프로젝트 루트 .env 에 위 두 변수 정의 (git 커밋 금지)
#
# 호출 주체: /notify-telegram 스킬 (Phase DONE 시 의무 발송)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PROJECT_NAME="${1:?프로젝트명을 첫 번째 인자로 전달하세요}"
MESSAGE="${2:?메시지를 두 번째 인자로 전달하세요}"

# ---------------------------------------------------------------------------
# 토큰 로드: 환경변수 → .env 폴백
# ---------------------------------------------------------------------------
if [ -z "${PAB_TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${PAB_TELEGRAM_CHAT_ID:-}" ]; then
  if [ -f "$PROJECT_ROOT/.env" ]; then
    # .env에서 PAB_TELEGRAM_* 두 키만 안전하게 로드 (전체 source 금지)
    while IFS='=' read -r key val; do
      val="${val%\"}"; val="${val#\"}"
      case "$key" in
        PAB_TELEGRAM_BOT_TOKEN) PAB_TELEGRAM_BOT_TOKEN="$val" ;;
        PAB_TELEGRAM_CHAT_ID)   PAB_TELEGRAM_CHAT_ID="$val" ;;
      esac
    done < "$PROJECT_ROOT/.env"
  fi
fi

BOT_TOKEN="${PAB_TELEGRAM_BOT_TOKEN:-}"
CHAT_ID="${PAB_TELEGRAM_CHAT_ID:-}"

if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
  echo "ERROR: Telegram 토큰 미설정." >&2
  echo "  export PAB_TELEGRAM_BOT_TOKEN=\"...\" PAB_TELEGRAM_CHAT_ID=\"...\"" >&2
  echo "  또는 프로젝트 루트 .env 에 두 변수를 정의하세요 (커밋 금지)." >&2
  echo "  세팅 절차: docs/guide/index.html → 🗂 기록·알림 위치" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 발송
# ---------------------------------------------------------------------------
RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d chat_id="${CHAT_ID}" \
  -d "text=[${PROJECT_NAME}]
${MESSAGE}" \
  -d parse_mode="Markdown")

if echo "$RESPONSE" | grep -q '"ok":true'; then
  echo "✅ Telegram 알림 발송 완료 [${PROJECT_NAME}]"
else
  echo "ERROR: Telegram 발송 실패 — 응답: $RESPONSE" >&2
  exit 1
fi
