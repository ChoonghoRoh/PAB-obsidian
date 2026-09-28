#!/usr/bin/env bash
# on-task-completed.sh — TaskCompleted Hook: 자동 품질 검사
# 트리거: Claude Code TaskCompleted 이벤트
# 목적: Task 완료 시 경량 정적 검사를 자동 실행하여 Critical 이슈 차단
#
# Exit codes:
#   0 — 검사 통과 (또는 검사 대상 파일 없음)
#   2 — Critical 이슈 발견 → Task 완료 차단

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

# 프로젝트별 설정 로드 (없으면 기본값) — hooks.env는 source하지 않고 값만 읽는다
PAB_LINE_WARN=500
PAB_LINE_CRIT=700

# hooks.env에서 키 하나를 안전하게 읽는다(CRLF 제거 · 인용부호 벗김)
env_read() {
  local key="$1" f="$2" v
  v="$([ -f "$f" ] && sed -n "s/^${key}=//p" "$f" 2>/dev/null | tail -n 1)" || v=""
  v="${v%$'\r'}"
  v="${v#\"}"; v="${v%\"}"
  v="${v#\'}"; v="${v%\'}"
  v="$(printf '%s' "$v" | sed "s/'\\\\''/'/g")"
  printf '%s' "$v"
}

_val="$(env_read PAB_LINE_WARN "$PROJECT_ROOT/.claude/hooks/hooks.env")"
case "$_val" in ''|*[!0-9]*) : ;; *) PAB_LINE_WARN="$_val" ;; esac
_val="$(env_read PAB_LINE_CRIT "$PROJECT_ROOT/.claude/hooks/hooks.env")"
case "$_val" in ''|*[!0-9]*) : ;; *) PAB_LINE_CRIT="$_val" ;; esac

# 변경된 파일 목록 수집 (staged + unstaged) — 한글 등 비아스키 파일명이 이스케이프되지 않게 quotePath 끔
CHANGED_FILES=$(git -c core.quotePath=false diff --name-only HEAD 2>/dev/null || true)
if [ -z "$CHANGED_FILES" ]; then
  CHANGED_FILES=$(git -c core.quotePath=false diff --name-only --cached 2>/dev/null || true)
fi

if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

CRITICAL_ISSUES=()

# 검사 1: 외부 CDN 참조 검출 (HTML, JS 파일)
CDN_PATTERNS=(
  "cdn.jsdelivr.net"
  "cdnjs.cloudflare.com"
  "unpkg.com"
  "cdn.bootcdn.net"
  "ajax.googleapis.com/ajax/libs"
)

while IFS= read -r file; do
  if [[ "$file" == *.html || "$file" == *.js ]] && [ -f "$file" ]; then
    for pattern in "${CDN_PATTERNS[@]}"; do
      if grep -q "$pattern" "$file" 2>/dev/null; then
        CRITICAL_ISSUES+=("[CDN] 외부 CDN 참조 발견: $file ($pattern)")
      fi
    done
  fi
done <<< "$CHANGED_FILES"

# 검사 2: HR-5 줄수 검사 (변경된 코드 파일)
while IFS= read -r file; do
  if [[ "$file" == *.html || "$file" == *.js || "$file" == *.css ]] && [ -f "$file" ]; then
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -gt "$PAB_LINE_CRIT" ]; then
      CRITICAL_ISSUES+=("[HR-5] ${PAB_LINE_CRIT}줄 초과 -- 리팩토링 필요: $file (${lines}줄)")
    elif [ "$lines" -gt "$PAB_LINE_WARN" ]; then
      echo "  WARNING: [HR-5] ${PAB_LINE_WARN}줄 초과 -- 레지스트리 등록 대상: $file (${lines}줄)" >&2
    fi
  fi
done <<< "$CHANGED_FILES"

# 결과 출력
if [ ${#CRITICAL_ISSUES[@]} -gt 0 ]; then
  echo "============================================" >&2
  echo " Task 완료 품질 검사 FAIL — Critical 이슈 발견" >&2
  echo "============================================" >&2
  echo "" >&2
  for issue in "${CRITICAL_ISSUES[@]}"; do
    echo "  - $issue" >&2
  done
  echo "" >&2
  echo "위 이슈를 수정한 후 다시 Task를 완료해 주세요." >&2
  exit 2
fi

# 알림: work-log 기록 리마인더
WORKLOG="$PROJECT_ROOT/docs/history/$(date +%y%m%d)-work-log.md"
if [ -f "$WORKLOG" ]; then
  echo "[REMINDER] 작업 완료 — log-prompt.sh log 로 work-log 기록 필요" >&2
fi

exit 0
