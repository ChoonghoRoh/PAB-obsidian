#!/usr/bin/env bash
# =============================================================================
# on-task-completed.sh — TaskCompleted Hook: 자동 품질 검사
# =============================================================================
# 트리거: Claude Code TaskCompleted 이벤트
# 목적: Task 완료 시 경량 정적 검사를 자동 실행하여 Critical 이슈 차단
#
# Exit codes:
#   0 — 검사 통과 (또는 검사 대상 파일 없음)
#   2 — Critical 이슈 발견 → Task 완료 차단
# =============================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

# 변경된 파일 목록 수집 (staged + unstaged)
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || true)
if [ -z "$CHANGED_FILES" ]; then
  CHANGED_FILES=$(git diff --name-only --cached 2>/dev/null || true)
fi

# 변경 파일 없으면 통과
if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

CRITICAL_ISSUES=()

# ---------------------------------------------------------------------------
# 검사 1: Python 구문 오류 (*.py 파일)
# ---------------------------------------------------------------------------
while IFS= read -r file; do
  if [[ "$file" == *.py ]] && [ -f "$file" ]; then
    if ! python3 -m py_compile "$file" 2>/dev/null; then
      CRITICAL_ISSUES+=("[SYNTAX] Python 구문 오류: $file")
    fi
  fi
done <<< "$CHANGED_FILES"

# ---------------------------------------------------------------------------
# 검사 2: 외부 CDN 참조 검출 (HTML, JS 파일)
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# 검사 3: ESM 미사용 검출 (HTML 내 <script> without type="module")
# ---------------------------------------------------------------------------
while IFS= read -r file; do
  if [[ "$file" == *.html ]] && [ -f "$file" ]; then
    # <script src="..."> 태그 중 type="module"이 없는 것을 검출
    # 인라인 스크립트와 외부 스크립트 모두 검사
    if grep -Pq '<script\b(?![^>]*type=["\x27]module["\x27])(?![^>]*type=["\x27]application/json["\x27])(?![^>]*type=["\x27]text/template["\x27])[^>]*src=' "$file" 2>/dev/null; then
      CRITICAL_ISSUES+=("[ESM] type=\"module\" 미사용 script 태그 발견: $file")
    fi
  fi
done <<< "$CHANGED_FILES"

# ---------------------------------------------------------------------------
# 검사 4: HR-5 줄수 검사 (변경된 코드 파일)
# ---------------------------------------------------------------------------
while IFS= read -r file; do
  if [[ "$file" == *.py || "$file" == *.ts || "$file" == *.js || "$file" == *.tsx || "$file" == *.jsx ]] && [ -f "$file" ]; then
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -gt 700 ]; then
      CRITICAL_ISSUES+=("[HR-5] 700줄 초과 -- 리팩토링 필요: $file (${lines}줄)")
    elif [ "$lines" -gt 500 ]; then
      echo "  WARNING: [HR-5] 500줄 초과 -- 레지스트리 등록 대상: $file (${lines}줄)" >&2
    fi
  fi
done <<< "$CHANGED_FILES"

# ---------------------------------------------------------------------------
# 결과 출력
# ---------------------------------------------------------------------------
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

exit 0
