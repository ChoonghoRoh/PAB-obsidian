#!/bin/bash

BOT_TOKEN="8309366692:AAHeY1VdpQzFFvRx15v4kcSxH1UFr5dkIBQ"
CHAT_ID="8674620390"

PROJECT_NAME="${1:?프로젝트명을 첫 번째 인자로 전달하세요}"
MESSAGE="${2:?메시지를 두 번째 인자로 전달하세요}"

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d chat_id="${CHAT_ID}" \
  -d "text=[${PROJECT_NAME}]
${MESSAGE}" \
  -d parse_mode="Markdown"
