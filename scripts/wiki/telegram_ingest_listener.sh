#!/bin/bash
# telegram_ingest_listener.sh — 텔레그램 getUpdates 롱폴링 → /wiki 합성 or 99_Inbox 캡처
# 모드: 기본=무한 루프, --once=현재 배치만 처리(테스트/cron용 — 비-ok 응답 시 즉시 종료)
# 토큰: 전용 봇 WIKI_TELEGRAM_BOT_TOKEN 사용(알림용 TELEGRAM_BOT_TOKEN과 공유 시 409 충돌)
# 보안: chat_id 인가, URL 검증, eval 금지, 사용자 입력은 변수로만 처리

set -euo pipefail

# ── 경로 설정 ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── .env 로드 (필수 — 없으면 종료) ──────────────────────────────────────────
if [ -f "$PROJECT_ROOT/.env" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$PROJECT_ROOT/.env"
  set +a
else
  echo "ERROR: $PROJECT_ROOT/.env not found" >&2
  exit 1
fi

# ── 필수 환경변수 검증 ────────────────────────────────────────────────────────
# 리스너는 전용 봇 토큰(WIKI_TELEGRAM_BOT_TOKEN)을 사용한다.
# Telegram은 토큰당 getUpdates 폴러를 1개만 허용하므로, 알림용
# TELEGRAM_BOT_TOKEN(report_to_telegram.sh)과 공유하면 409 Conflict가 발생한다.
# 폴백으로 TELEGRAM_BOT_TOKEN을 쓰지 않는다(409 무한충돌 방지).
: "${WIKI_TELEGRAM_BOT_TOKEN:?WIKI_TELEGRAM_BOT_TOKEN not set in .env — @BotFather로 전용 봇을 만들고 토큰을 .env에 추가하세요 (알림용 TELEGRAM_BOT_TOKEN과 공유 시 409 충돌)}"
: "${TELEGRAM_CHAT_ID:?TELEGRAM_CHAT_ID not set in .env}"

# ── WIKI_VAULT_ROOT 기본값 ───────────────────────────────────────────────────
export WIKI_VAULT_ROOT="${WIKI_VAULT_ROOT:-$PROJECT_ROOT/PAB-LLMDATA}"

# ── 인자 파싱 ────────────────────────────────────────────────────────────────
ONCE_MODE=false
if [ "${1:-}" = "--once" ]; then
  ONCE_MODE=true
fi

# ── offset 영속화 경로 ────────────────────────────────────────────────────────
OFFSET_FILE="$SCRIPT_DIR/.telegram_offset"
INBOX_DIR="$WIKI_VAULT_ROOT/99_Inbox"

# ── 워커 경로 ─────────────────────────────────────────────────────────────────
WORKER_SCRIPT="$SCRIPT_DIR/pab_wiki_worker.sh"

# ── offset 로드/초기화 ────────────────────────────────────────────────────────
if [ -f "$OFFSET_FILE" ]; then
  OFFSET="$(cat "$OFFSET_FILE")"
else
  OFFSET="0"
fi

# ── Telegram sendMessage 헬퍼 (secret 비로깅 — -K -로 URL argv 노출 방지) ──
# 전용 봇 토큰(WIKI_TELEGRAM_BOT_TOKEN)으로 회신한다.
# 알림용 TELEGRAM_BOT_TOKEN(report_to_telegram.sh)과는 분리된 별도 봇이다.
send_telegram() {
  local chat_id="$1"
  local text="$2"
  # BOT_TOKEN이 포함된 URL을 -K - (stdin)으로 전달해 argv/ps 노출 방지
  curl -s -K - \
    -d "parse_mode=Markdown" \
    --data-urlencode "chat_id=${chat_id}" \
    --data-urlencode "text=${text}" \
    -o /dev/null <<EOF
url = "https://api.telegram.org/bot${WIKI_TELEGRAM_BOT_TOKEN}/sendMessage"
EOF
}

# ── 99_Inbox append 헬퍼 (셸 인젝션 방지: printf '%s' 사용) ─────────────────
append_inbox() {
  local text="$1"
  local today
  today="$(date +%Y-%m-%d)"
  local now_hhmm
  now_hhmm="$(date +%H:%M)"
  local inbox_file="$INBOX_DIR/${today}.md"

  mkdir -p "$INBOX_DIR"

  if [ ! -f "$inbox_file" ]; then
    # 신규 daily inbox: 옵시디언 규격 frontmatter(Critical 필드 포함) 생성
    local now_datetime
    now_datetime="$(date +'%Y-%m-%d %H:%M')"
    # printf '%s'로 안전하게 — eval/변수 확장 없음. 그룹 리다이렉트로 SC2129 방지
    {
      printf '%s\n' "---"
      printf '%s\n' "title: \"Inbox ${today}\""
      printf '%s\n' "description: \"Telegram inbox ${today}\""
      printf '%s\n' "created: ${now_datetime}"
      printf '%s\n' "updated: ${now_datetime}"
      printf '%s\n' "type: \"[[DAILY]]\""
      printf '%s\n' "index: \"[[MISC]]\""
      printf '%s\n' "topics: []"
      printf '%s\n' "tags: [daily, inbox]"
      printf '%s\n' "keywords: []"
      printf '%s\n' "sources: []"
      printf '%s\n' "aliases: [\"Inbox ${today}\"]"
      printf '%s\n' "---"
      printf '\n%s\n\n' "# Inbox ${today}"
    } > "$inbox_file"
  fi

  # 멀티라인 텍스트를 한 줄로 정리(F-16) — 개행 → 공백 치환 후 append
  local text_oneline
  text_oneline="$(printf '%s' "$text" | tr '\n' ' ')"
  printf '- %s %s\n' "$now_hhmm" "$text_oneline" >> "$inbox_file"
}

# ── SIGINT 클린 종료 ──────────────────────────────────────────────────────────
_cleanup() {
  echo "" >&2
  echo "[listener] SIGINT received — saving offset and exiting cleanly" >&2
  printf '%s' "$OFFSET" > "$OFFSET_FILE"
  exit 0
}
trap '_cleanup' INT TERM

# ── 메인 루프 ─────────────────────────────────────────────────────────────────
echo "[listener] START vault=${WIKI_VAULT_ROOT} once=${ONCE_MODE} offset=${OFFSET}" >&2

while true; do
  # ── getUpdates (롱폴, timeout=30s) ──────────────────────────────────────────
  # curl verbose/로그에 body가 남지 않도록 -s 사용
  RESPONSE=""
  # 전용 봇 토큰(WIKI_TELEGRAM_BOT_TOKEN)이 포함된 URL을 -K - (stdin)으로
  # 전달해 argv/ps 노출 방지. 알림용 TELEGRAM_BOT_TOKEN과 분리된 봇이다.
  CURL_FAILED=0
  RESPONSE="$(curl -s --max-time 60 -K - <<EOF
url = "https://api.telegram.org/bot${WIKI_TELEGRAM_BOT_TOKEN}/getUpdates?offset=${OFFSET}&timeout=30"
EOF
)" || CURL_FAILED=1
  if [ "$CURL_FAILED" -ne 0 ]; then
    echo "[listener] WARN: curl failed — retrying" >&2
    # --once: 1회 시도가 실패하면 즉시 종료(다회 재시도 금지)
    if [ "$ONCE_MODE" = "true" ]; then
      echo "[listener] --once mode: getUpdates curl failed — exiting" >&2
      exit 1
    fi
    sleep 2
    continue
  fi

  # ── 응답 유효성 검사 ─────────────────────────────────────────────────────────
  if [ -z "$RESPONSE" ]; then
    echo "[listener] WARN: empty response — retrying" >&2
    # --once: 빈 응답이면 즉시 종료(다회 재시도 금지)
    if [ "$ONCE_MODE" = "true" ]; then
      echo "[listener] --once mode: empty response — exiting" >&2
      exit 1
    fi
    sleep 2
    continue
  fi

  OK="$(printf '%s' "$RESPONSE" | jq -r '.ok // false' 2>/dev/null || echo "false")"
  if [ "$OK" != "true" ]; then
    # ── 409 Conflict 명확 탐지: 같은 토큰으로 다른 getUpdates 폴러가 실행 중 ──
    ERROR_CODE="$(printf '%s' "$RESPONSE" | jq -r '.error_code // empty' 2>/dev/null || echo "")"
    if [ "$ERROR_CODE" = "409" ]; then
      echo "[listener] FATAL 409: 이 봇 토큰으로 다른 getUpdates 폴러가 이미 실행 중입니다. WIKI_TELEGRAM_BOT_TOKEN 전용 봇을 쓰거나 기존 폴러를 중지하세요." >&2
      exit 3
    fi
    echo "[listener] WARN: getUpdates not ok — response: ${RESPONSE:0:200}" >&2
    # --once: 비-ok(409 외)면 즉시 종료(다회 재시도 금지)
    if [ "$ONCE_MODE" = "true" ]; then
      echo "[listener] --once mode: getUpdates not ok — exiting" >&2
      exit 1
    fi
    sleep 5
    continue
  fi

  # ── update 처리 ──────────────────────────────────────────────────────────────
  UPDATE_COUNT="$(printf '%s' "$RESPONSE" | jq '.result | length' 2>/dev/null || echo "0")"

  if [ "$UPDATE_COUNT" -gt 0 ]; then
    for i in $(seq 0 $((UPDATE_COUNT - 1))); do
      UPDATE="$(printf '%s' "$RESPONSE" | jq ".result[$i]")"

      UPDATE_ID="$(printf '%s' "$UPDATE" | jq -r '.update_id')"
      MSG_CHAT_ID="$(printf '%s' "$UPDATE" | jq -r '.message.chat.id // empty')"
      MSG_TEXT="$(printf '%s' "$UPDATE" | jq -r '.message.text // empty')"

      # ── 인가: chat_id 불일치 시 무시 ───────────────────────────────────────
      if [ -z "$MSG_CHAT_ID" ] || [ "$MSG_CHAT_ID" != "$TELEGRAM_CHAT_ID" ]; then
        echo "[listener] SKIP update_id=${UPDATE_ID} — unauthorized chat_id: ${MSG_CHAT_ID:-none}" >&2
        OFFSET=$((UPDATE_ID + 1))
        printf '%s' "$OFFSET" > "$OFFSET_FILE"
        continue
      fi

      # ── 빈 텍스트(파일·스티커 등) 무시 ───────────────────────────────────
      if [ -z "$MSG_TEXT" ]; then
        echo "[listener] SKIP update_id=${UPDATE_ID} — no text content" >&2
        OFFSET=$((UPDATE_ID + 1))
        printf '%s' "$OFFSET" > "$OFFSET_FILE"
        continue
      fi

      echo "[listener] RECV update_id=${UPDATE_ID} text_prefix=${MSG_TEXT:0:60}" >&2

      # ── 라우팅 ────────────────────────────────────────────────────────────
      if [[ "$MSG_TEXT" == /wiki\ * ]]; then
        # /wiki <url> 명령 → 워커로 합성
        # 첫 단어(/wiki) 제거, 나머지 추출 — eval 없음
        RAW_URL="${MSG_TEXT#/wiki }"
        # URL 앞뒤 공백 제거
        URL="${RAW_URL%%[[:space:]]*}"
        URL="${URL#"${URL%%[^ ]*}"}"

        # URL 검증 (워커와 동일 정규식)
        if ! [[ "$URL" =~ ^https?://[^[:space:]]+$ ]]; then
          echo "[listener] INVALID URL from /wiki command: ${URL}" >&2
          send_telegram "$MSG_CHAT_ID" "[PAB-Wiki] ERROR: 유효하지 않은 URL입니다.
입력: ${URL}
형식: https:// 또는 http:// 로 시작해야 합니다."
          OFFSET=$((UPDATE_ID + 1))
          printf '%s' "$OFFSET" > "$OFFSET_FILE"
          continue
        fi

        send_telegram "$MSG_CHAT_ID" "[PAB-Wiki] wiki 노트 합성 중... (URL: ${URL})"

        # 워커 호출 — 배열 방식, URL은 검증된 변수로만 전달
        WORKER_EXIT=0
        WORKER_OUT="$("$WORKER_SCRIPT" "$URL" 2>&1)" || WORKER_EXIT=$?

        if [ "$WORKER_EXIT" -eq 0 ]; then
          send_telegram "$MSG_CHAT_ID" "${WORKER_OUT:-[PAB-Wiki] SUCCESS | 노트 생성 완료}"
        else
          send_telegram "$MSG_CHAT_ID" "[PAB-Wiki] ERROR: 합성 실패 — 재시도하려면 /wiki ${URL} 재전송
${WORKER_OUT:-자세한 내용은 서버 로그를 확인하세요.}"
        fi

      else
        # 일반 텍스트/URL → 99_Inbox 캡처만
        # 사용자 입력을 append_inbox 함수에 변수로만 전달 — eval 없음
        append_inbox "$MSG_TEXT"

        send_telegram "$MSG_CHAT_ID" "[PAB-Wiki] 캡처됨 (99_Inbox/$(date +%Y-%m-%d).md)"
      fi

      # ── offset 갱신 및 저장 ──────────────────────────────────────────────
      OFFSET=$((UPDATE_ID + 1))
      printf '%s' "$OFFSET" > "$OFFSET_FILE"

    done
  fi

  # --once 모드: 배치 처리 후 종료
  if [ "$ONCE_MODE" = "true" ]; then
    echo "[listener] --once mode: processed ${UPDATE_COUNT} updates — exiting" >&2
    exit 0
  fi

done
