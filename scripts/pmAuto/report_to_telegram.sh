#!/usr/bin/env bash
# report_to_telegram.sh — NOTIFY-1 Telegram 알림 발송기
# 사용법:
#   bash scripts/pmAuto/report_to_telegram.sh "프로젝트라벨" "메시지"
#
# 토큰 설정 (우선순위 순 — 스크립트에 토큰 하드코딩 금지):
#   1. 환경변수:  export PAB_TELEGRAM_BOT_TOKEN=... PAB_TELEGRAM_CHAT_ID=...
#   2. .env 파일: 프로젝트 루트 .env 에 위 두 변수 정의 (git 커밋 금지)
#
# 호출 주체: /notify-telegram 스킬 (Phase DONE 시 의무 발송)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PROJECT_NAME="${1:?프로젝트명을 첫 번째 인자로 전달하세요}"
MESSAGE="${2:?메시지를 두 번째 인자로 전달하세요}"

# 파싱 모드 — 3번째 인자 > 환경변수 > 기본값(plain)
# ★ "plain" 지정 시 parse_mode 자체를 보내지 않는다.
#   Telegram legacy Markdown 은 `_`·`*`·`[` 를 엔티티로 해석하므로, 홀수 개가 섞이면
#   400 "can't find end of the entity" 로 발송이 통째로 실패한다. Phase 상태명
#   (TASK_SPEC·TEAM_SETUP·PLAN_REVIEW·E2E_REPORT·TEAM_SHUTDOWN)이 전부 `_` 를 포함해
#   상태 전이 알림에서 재발이 잦다 — 서식이 필요 없는 알림은 plain 을 쓸 것.
# 기본값은 plain — 호출부(notify-telegram)는 인자 2개만 넘기고 NOTIFY-2 양식에는 서식이 없다.
PARSE_MODE="${3:-${PAB_TELEGRAM_PARSE_MODE:-plain}}"

# 토큰 로드: 환경변수 → .env 폴백
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

# 발송
# NOTIFY-2 형식 보존 — 아래 두 가지는 함께 지켜야 한다. 하나만 되돌려도 형식이 깨진다.
#  1) --data-urlencode : -d 는 URL 인코딩을 하지 않아 '+' 가 수신 측에서 공백으로 바뀐다
#  2) parse_mode 기본값 plain : 위 파싱 모드 주석 참조 — 서식 파서를 기본으로 켜지 않는다
CURL_ARGS=(-s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"
  --data-urlencode "chat_id=${CHAT_ID}"
  --data-urlencode "text=[${PROJECT_NAME}]
${MESSAGE}")

if [ "$PARSE_MODE" != "plain" ]; then
  CURL_ARGS+=(-d parse_mode="${PARSE_MODE}")
fi

RESPONSE=$(curl "${CURL_ARGS[@]}")

if echo "$RESPONSE" | grep -q '"ok":true'; then
  echo "✅ Telegram 알림 발송 완료 [${PROJECT_NAME}]"
else
  echo "ERROR: Telegram 발송 실패 — 응답: $RESPONSE" >&2
  exit 1
fi
