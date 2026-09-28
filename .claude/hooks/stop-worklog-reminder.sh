#!/usr/bin/env bash
# stop-worklog-reminder.sh — Stop Hook: 세션 종료 시 work-log 미기록 감지
# 트리거: Claude Code Stop 이벤트
# 목적: 세션 중 파일 수정이 있었는데 work-log에 기록이 없으면 리마인더 표시
#
# Exit codes:
#   0 — 항상 통과 (정보성 리마인더, 차단하지 않음)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HISTORY_DIR="$PROJECT_ROOT/docs/history"
PENDING_ROOT="$HISTORY_DIR/.pending"

emit() {
  # $1 — systemMessage 본문. 임의 텍스트 보간에 대비해 이스케이프한다.
  # 순서 필수 — 백슬래시를 큰따옴표보다 먼저 치환한다(순서가 뒤집히면 이중 이스케이프로 깨진다).
  local msg=${1//\\/\\\\}
  msg=${msg//\"/\\\"}
  printf '{\n  "systemMessage": "%s"\n}\n' "$msg"
}

add_part() {
  if [ -n "$MSG_PARTS" ]; then
    MSG_PARTS="${MSG_PARTS} · $1"
  else
    MSG_PARTS="$1"
  fi
}
MSG_PARTS=""

# .pending/<날짜> 아래 미회수 프롬프트 개수
count_pending() {
  local dir="$PENDING_ROOT/$1"
  local n
  if [ ! -d "$dir" ]; then
    echo 0
    return
  fi
  set +e +o pipefail
  n=$(find "$dir" -maxdepth 1 -name '*.txt' 2>/dev/null | wc -l | tr -d ' ')
  set -e -o pipefail
  : "${n:=0}"
  echo "$n"
}

# 7일 넘게 회수되지 않은 날짜 디렉터리 · 파일 수 집계
count_old_pending() {
  if [ ! -d "$PENDING_ROOT" ]; then
    printf '0\n0\n'
    return
  fi
  set +e +o pipefail
  local dirs
  dirs=$(find "$PENDING_ROOT" -maxdepth 1 -type d -name '[0-9]*' -mtime +7 2>/dev/null)
  set -e -o pipefail
  local day_count=0 file_total=0 d n
  if [ -n "$dirs" ]; then
    while IFS= read -r d; do
      day_count=$((day_count + 1))
      set +e +o pipefail
      n=$(find "$d" -maxdepth 1 -name '*.txt' 2>/dev/null | wc -l | tr -d ' ')
      set -e -o pipefail
      : "${n:=0}"
      file_total=$((file_total + n))
    done <<< "$dirs"
  fi
  printf '%s\n%s\n' "$file_total" "$day_count"
}

# work-log를 쓰지 않는 프로젝트에서는 이 훅이 매 Stop마다 안내를 반복하고 끌 방법이 없다.
# docs/history/ 부재를 "work-log 미사용" 신호로 보고 조용히 종료한다.
if [ ! -d "$HISTORY_DIR" ]; then
  exit 0
fi

# 1. 대상 work-log 결정 (오늘자 → 없으면 전일자, 자정 통과 세션 구제)
TODAY=$(date +%y%m%d)
WORKLOG="$HISTORY_DIR/${TODAY}-work-log.md"
CARRYOVER=""
YESTERDAY=""

if [ ! -f "$WORKLOG" ]; then
  # BSD(date -v) / GNU(date -d) 양쪽 지원
  if YESTERDAY=$(date -v-1d +%y%m%d 2>/dev/null); then
    :
  else
    YESTERDAY=$(date -d "yesterday" +%y%m%d 2>/dev/null || echo "")
  fi

  PREV="$HISTORY_DIR/${YESTERDAY}-work-log.md"
  # 전일자가 최근 12시간 이내에 갱신됐다면 = 자정을 넘긴 같은 세션으로 본다.
  # 하루 지난 뒤 새로 여는 세션까지 구제하면 미기록을 놓치므로 시한을 둔다.
  if [ -n "$YESTERDAY" ] && [ -f "$PREV" ] && [ -z "$(find "$PREV" -mmin +720 2>/dev/null)" ]; then
    WORKLOG="$PREV"
    CARRYOVER="${YESTERDAY}-work-log.md (자정 통과 세션)"
  else
    PENDING_TODAY_ABS=$(count_pending "$TODAY")
    PENDING_YEST_ABS=0
    [ -n "$YESTERDAY" ] && PENDING_YEST_ABS=$(count_pending "$YESTERDAY")
    PENDING_BOTH=$((PENDING_TODAY_ABS + PENDING_YEST_ABS))
    MSG="[work-log] 오늘자 작업 기록(${TODAY}-work-log.md)이 없습니다."
    [ "$PENDING_BOTH" -gt 0 ] && MSG="${MSG} 안 옮긴 지시 ${PENDING_BOTH}건이 있습니다."
    emit "${MSG} ./scripts/log-prompt.sh log 실행을 권장합니다."
    exit 0
  fi
fi

# 신호 ① · ② — 대기 프롬프트(.pending) 경과 신호
PENDING_TODAY=$(count_pending "$TODAY")
PENDING_YESTERDAY=0
if [ -n "$CARRYOVER" ] && [ -n "$YESTERDAY" ]; then
  PENDING_YESTERDAY=$(count_pending "$YESTERDAY")
fi
PENDING_COUNT=$((PENDING_TODAY + PENDING_YESTERDAY))

OLD_COUNT=0
OLD_DAYS=0
{ read -r OLD_COUNT; read -r OLD_DAYS; } < <(count_old_pending)

# 2. 작업 트리 변경 집계 — tracked 수정 + staged + untracked 전부
#    git 저장소가 아니면 변경 감지 불가 → 리마인더 생략.
if ! git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ "$PENDING_COUNT" -gt 0 ] || [ "$OLD_COUNT" -gt 0 ]; then
    [ "$PENDING_COUNT" -gt 0 ] && add_part "안 옮긴 지시 ${PENDING_COUNT}건"
    [ "$OLD_COUNT" -gt 0 ] && add_part "오래된 미기록 ${OLD_COUNT}건(${OLD_DAYS}일치)"
    emit "[work-log] ${MSG_PARTS} — 아직 기록에 없습니다. ./scripts/log-prompt.sh log 로 기록하세요."
  fi
  exit 0
fi

set +e +o pipefail
TOTAL_CHANGES=$(git -C "$PROJECT_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
set -e -o pipefail
: "${TOTAL_CHANGES:=0}"

# 신호 ③ — 마지막 기록 이후 커밋 수
set +e +o pipefail
WL_EPOCH=$(stat -f '%m' "$WORKLOG" 2>/dev/null) || WL_EPOCH=$(stat -c '%Y' "$WORKLOG" 2>/dev/null) || WL_EPOCH=0
COMMIT_COUNT=$(git -C "$PROJECT_ROOT" log --format=%ct 2>/dev/null | awk -v t="$WL_EPOCH" '$1>t' | wc -l | tr -d ' ')
set -e -o pipefail
: "${COMMIT_COUNT:=0}"

# 무변경 조기 종료 — 파일 변경도 없고 대기·경과 신호도 없고 커밋도 없으면 알릴 것이 없다
if [ "$TOTAL_CHANGES" -eq 0 ] && [ "$PENDING_COUNT" -eq 0 ] && [ "$OLD_COUNT" -eq 0 ] && [ "$COMMIT_COUNT" -eq 0 ]; then
  exit 0
fi

# 3. 기록 유무 확인
#    테이블 형식: | 0001 | ... 또는 헤더 형식: #### 0001
set +e +o pipefail
RECORD_COUNT=$(grep -cE '^\| [0-9]{4} \||^#### [0-9]{4}' "$WORKLOG" 2>/dev/null)
set -e -o pipefail
: "${RECORD_COUNT:=0}"

if [ "$RECORD_COUNT" -eq 0 ]; then
  if [ "$TOTAL_CHANGES" -gt 0 ]; then
    MSG="[work-log] 파일 변경(${TOTAL_CHANGES}건)이 있지만 work-log에 기록이 없습니다."
  else
    MSG="[work-log] work-log에 기록이 없습니다."
  fi
  [ "$PENDING_COUNT" -gt 0 ] && MSG="${MSG} 안 옮긴 지시 ${PENDING_COUNT}건 포함."
  [ "$COMMIT_COUNT" -gt 0 ] && MSG="${MSG} 마지막 기록 뒤 커밋 ${COMMIT_COUNT}건."
  [ "$OLD_COUNT" -gt 0 ] && MSG="${MSG} 오래된 미기록 ${OLD_COUNT}건(${OLD_DAYS}일치)."
  RC0_SUFFIX=""
  [ -n "$CARRYOVER" ] && RC0_SUFFIX=" 대상: ${CARRYOVER}"
  emit "${MSG} ./scripts/log-prompt.sh log 실행을 권장합니다.${RC0_SUFFIX}"
  exit 0
fi

# 4. ★ 마지막 기록 이후에 작업이 더 있었는지 확인(신호 ④)
#    work-log 파일보다 나중에 수정된 산출물이 있으면 그만큼 미기록으로 본다.
#    history/ 자신·VCS 내부(.git, worktree/submodule 하위 포함)·툴 캐시·빌드 산출물은 제외한다.
set +e +o pipefail
# .git 는 이름 매칭(-name)이라 하위 worktree/submodule의 .git도 함께 걸러진다.
# docs/history 는 경로 매칭(-path)으로 그 한 곳만 제외한다 — -name으로 바꾸면
# 저장소 안의 다른 모든 history/ 디렉토리까지 잘려나간다. 두 방식을 통일하지 않는다.
# prune 대상은 기계가 재생성하는 것으로 한정한다 — 사람이 쓴 것이 들어갈 수 있는
# 디렉토리(예: 라인 작업 디렉토리)는 절대 넣지 않는다.
NEWER_COUNT=$(find "$PROJECT_ROOT" \
  \( -name ".git" \
     -o -path "$HISTORY_DIR" \
     -o -name "node_modules" \
     -o -name "__pycache__" \
     -o -name ".pytest_cache" \
     -o -name "_archive" \
     -o -name ".venv" \
     -o -name ".mypy_cache" \
     -o -name ".ruff_cache" \
     -o -name ".tox" \
     -o -name ".gradle" \
     -o -name "dist" \
     -o -name "build" \
     -o -name ".next" \
     -o -name "out" \
     -o -name "target" \) -prune \
  -o -type f -newer "$WORKLOG" -print 2>/dev/null | head -101 | wc -l | tr -d ' ')
set -e -o pipefail
: "${NEWER_COUNT:=0}"
NEWER_LABEL="$NEWER_COUNT"
[ "$NEWER_COUNT" -gt 100 ] && NEWER_LABEL="100+"

[ "$PENDING_COUNT" -gt 0 ] && add_part "안 옮긴 지시 ${PENDING_COUNT}건"
[ "$COMMIT_COUNT" -gt 0 ] && add_part "마지막 기록 뒤 커밋 ${COMMIT_COUNT}건"
[ "$NEWER_COUNT" -gt 0 ] && add_part "기록 뒤 손댄 파일 ${NEWER_LABEL}건"
[ "$OLD_COUNT" -gt 0 ] && add_part "오래된 미기록 ${OLD_COUNT}건(${OLD_DAYS}일치)"

if [ -n "$MSG_PARTS" ]; then
  SUFFIX=""
  [ -n "$CARRYOVER" ] && SUFFIX=" 대상: ${CARRYOVER}"
  OLD_HINT=""
  [ "$OLD_COUNT" -gt 0 ] && OLD_HINT=" (오래된 원문: ./scripts/log-prompt.sh pending)"
  emit "[work-log] ${MSG_PARTS} — 아직 기록에 없습니다. ./scripts/log-prompt.sh log 로 기록하세요.${OLD_HINT}${SUFFIX}"
fi

exit 0
