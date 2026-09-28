#!/bin/bash
# 프롬프트 작업 기록 스크립트
# 사용법:
#   ./scripts/log-prompt.sh init
#   ./scripts/log-prompt.sh log "프롬프트 원문" "결과 설명"
#   ./scripts/log-prompt.sh log "프롬프트 원문" "결과 설명" "채팅 출력 내용"
#   ./scripts/log-prompt.sh check

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HISTORY_DIR="$PROJECT_ROOT/docs/history"
OUTPUT_DIR="$HISTORY_DIR/output"
PENDING_ROOT="$HISTORY_DIR/.pending"
TODAY=$(date +%y%m%d)
TODAY_FULL=$(date +%Y-%m-%d)
WORKLOG="$HISTORY_DIR/${TODAY}-work-log.md"

# 마지막 순번 읽기
get_last_seq() {
  if [ ! -f "$WORKLOG" ]; then
    echo 0
    return
  fi
  local last
  last=$(grep -E '^\| [0-9]{4} \|' "$WORKLOG" | tail -1 | sed 's/^| \([0-9]*\) .*/\1/')
  if [ -z "$last" ]; then
    echo 0
  else
    echo "$((10#$last))"
  fi
}

# 슬러그 생성 (자동 fallback)
# 1순위: perl \p{Hangul} (GNU cut -c는 이 환경에서 멀티바이트를 바이트 단위로
#        잘라 UTF-8을 깨뜨리므로 sed+cut보다 우선한다)
# 2순위: sed (perl 부재 시. cut -c 대신 bash 문자 단위 슬라이스 사용)
# 3순위: tr 안전망 (영숫자만 보존, 한글 손실)
# 환경변수 LOG_PROMPT_SLUG_ENGINE=sed|perl|auto (기본 auto)
make_slug() {
  local input="$1"
  local engine="${LOG_PROMPT_SLUG_ENGINE:-auto}"

  if [ "$engine" = "perl" ] || [ "$engine" = "auto" ]; then
    if command -v perl >/dev/null 2>&1; then
      printf '%s' "$input" | perl -CS -pe 's/[^a-zA-Z0-9\p{Hangul}_-]/-/g; $_ = substr($_, 0, 30)'
      return 0
    fi
    [ "$engine" = "perl" ] && return 0
  fi

  if [ "$engine" = "sed" ] || [ "$engine" = "auto" ]; then
    local out
    out=$(printf '%s' "$input" | sed 's/[^a-zA-Z0-9가-힣_-]/-/g' 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$out" ]; then
      printf '%s' "${out:0:30}"
      return 0
    fi
    [ "$engine" = "sed" ] && return 0
  fi

  printf '%s' "$input" | tr -c 'a-zA-Z0-9_-' '-' | cut -c1-30
}

# init: 오늘자 work-log 생성
cmd_init() {
  mkdir -p "$OUTPUT_DIR"
  if [ -f "$WORKLOG" ]; then
    local seq
    seq=$(get_last_seq)
    echo "[OK] ${TODAY}-work-log.md 이미 존재 (마지막 순번: $(printf '%04d' $seq))"
  else
    cat > "$WORKLOG" <<EOF
# ${TODAY_FULL} 프롬프트 기록

| # | 프롬프트 (원문) | 결과 |
|---|----------------|------|
EOF
    echo "[OK] ${TODAY}-work-log.md 생성 완료"
  fi
}

# pending: .pending/ 전 날짜의 미회수 프롬프트 원문 열람
cmd_pending() {
  if [ ! -d "$PENDING_ROOT" ]; then
    echo "[OK] 대기 중인 프롬프트가 없습니다."
    return
  fi

  local any_found=0
  local dir date_dir f day_found
  for dir in "$PENDING_ROOT"/*/; do
    [ -d "$dir" ] || continue
    date_dir=$(basename "$dir")
    case "$date_dir" in
      [0-9][0-9][0-9][0-9][0-9][0-9]) : ;;
      *) continue ;;
    esac
    day_found=0
    while IFS= read -r f; do
      if [ "$day_found" -eq 0 ]; then
        echo "=== ${date_dir} ==="
        day_found=1
        any_found=1
      fi
      echo "  $(basename "$f")"
    done < <(find "$dir" -maxdepth 1 -name '*.txt' 2>/dev/null | sort)
  done

  if [ "$any_found" -eq 0 ]; then
    echo "[OK] 대기 중인 프롬프트가 없습니다."
  fi
}

# 지정 날짜의 pending 파일을 회수(삭제)하고 회수 건수를 반환한다 — log가 실제로 pending을 지운다
recover_pending() {
  local date_dir="$1"
  local dir="$PENDING_ROOT/$date_dir"
  local cnt
  cnt=0
  if [ -d "$dir" ]; then
    cnt=$(find "$dir" -maxdepth 1 -name '*.txt' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$cnt" -gt 0 ]; then
      rm -f "$dir"/*.txt
    fi
  fi
  echo "$cnt"
}

# log: 프롬프트 기록
cmd_log() {
  local prompt="$1"
  local result="$2"
  local output_content="$3"

  if [ -z "$prompt" ]; then
    echo "[ERROR] 프롬프트 원문이 필요합니다."
    echo "사용법: ./scripts/log-prompt.sh log \"프롬프트 원문\" \"결과 설명\" [\"출력 내용\"]"
    exit 1
  fi

  if [ ! -f "$WORKLOG" ]; then
    cmd_init
  fi

  local last_seq
  last_seq=$(get_last_seq)
  local next_seq=$((last_seq + 1))
  local seq_str
  seq_str=$(printf '%04d' $next_seq)

  # output 파일 항상 생성
  local summary
  summary=$(make_slug "$result")
  local output_file="${TODAY}-${seq_str}-${summary}.md"
  local output_path="$OUTPUT_DIR/$output_file"

  if [ -n "$output_content" ]; then
    echo "$output_content" > "$output_path"
  else
    printf "# %s\n\n%s\n" "$prompt" "$result" > "$output_path"
  fi
  result="[output/${output_file}](output/${output_file})"
  echo "[OK] output 파일 생성: $output_file"

  # 프롬프트 내 파이프 문자 이스케이프
  prompt=$(echo "$prompt" | sed 's/|/\\|/g')
  result=$(echo "$result" | sed 's/|/\\|/g')

  echo "| ${seq_str} | ${prompt} | ${result} |" >> "$WORKLOG"
  echo "[OK] #${seq_str} 기록 완료"

  local yesterday recovered_today recovered_yesterday recovered_total
  recovered_today=$(recover_pending "$TODAY")
  yesterday=$(date -v-1d +%y%m%d 2>/dev/null || date -d "yesterday" +%y%m%d 2>/dev/null || echo "")
  recovered_yesterday=0
  if [ -n "$yesterday" ]; then
    recovered_yesterday=$(recover_pending "$yesterday")
  fi
  recovered_total=$((recovered_today + recovered_yesterday))
  if [ "$recovered_total" -gt 0 ]; then
    echo "[OK] pending ${recovered_total}건 회수(오늘 ${recovered_today}건 + 전일 ${recovered_yesterday}건)"
  fi
}

# check: 누락 검증
cmd_check() {
  # 가장 최근 work-log 찾기
  local latest
  latest=$(ls -t "$HISTORY_DIR"/*-work-log.md 2>/dev/null | head -1)

  if [ -z "$latest" ]; then
    echo "[WARN] work-log 파일이 없습니다."
    return
  fi

  local filename
  filename=$(basename "$latest")
  echo "=== 검증: $filename ==="

  # 빈 결과 컬럼 검출
  local empty_results
  empty_results=$(grep -nE '^\| [0-9]{4} \|.*\|[[:space:]]*\|$' "$latest" 2>/dev/null)
  if [ -n "$empty_results" ]; then
    echo "[WARN] 결과 컬럼 비어있는 행:"
    echo "$empty_results"
  else
    echo "[OK] 결과 컬럼 모두 채워짐"
  fi

  # output 링크 파일 존재 확인
  local missing=0
  while IFS= read -r link; do
    local filepath="$HISTORY_DIR/$link"
    if [ ! -f "$filepath" ]; then
      echo "[WARN] 파일 없음: $link"
      missing=$((missing + 1))
    fi
  done < <(grep -oE 'output/[^)\]]+\.md' "$latest" 2>/dev/null | sort -u)

  if [ "$missing" -eq 0 ]; then
    echo "[OK] output 파일 정합성 통과"
  else
    echo "[WARN] 누락 파일 ${missing}건"
  fi

  local total
  total=$(grep -cE '^\| [0-9]{4} \|' "$latest" 2>/dev/null)
  echo "=== 총 ${total}건 기록 ==="
}

case "${1:-}" in
  init)
    cmd_init
    ;;
  log)
    cmd_log "$2" "$3" "${4:-}"
    ;;
  check)
    cmd_check
    ;;
  pending)
    cmd_pending
    ;;
  *)
    echo "프롬프트 작업 기록 스크립트"
    echo ""
    echo "사용법:"
    echo "  $0 init                              오늘자 work-log 생성"
    echo "  $0 log \"프롬프트\" \"결과\"              프롬프트 기록"
    echo "  $0 log \"프롬프트\" \"결과\" \"출력내용\"   프롬프트 기록 + output 파일 생성"
    echo "  $0 check                             누락 검증"
    echo "  $0 pending                           .pending/ 전 날짜 미기록 프롬프트 열람"
    ;;
esac
