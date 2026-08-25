#!/usr/bin/env bash
# =============================================================================
# sync-project-config.sh — PROJECT.md frontmatter → .claude/hooks/hooks.env 생성
# =============================================================================
# 사용법:
#   ./scripts/sync-project-config.sh          # 동기화 실행
#   ./scripts/sync-project-config.sh check    # 신선도만 검사 (0=최신, 3=재동기화 필요)
#
# PROJECT.md가 프로젝트 설정의 단일 소스(single source)이며,
# hooks.env는 본 스크립트가 생성하는 파생 산출물이다 (직접 수정 금지).
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_MD="$PROJECT_ROOT/PROJECT.md"
HOOKS_ENV="$PROJECT_ROOT/.claude/hooks/hooks.env"
ACTION="${1:-sync}"

if [ ! -f "$PROJECT_MD" ]; then
  echo "[project-config] PROJECT.md 없음 — hooks.env 기본값 유지" >&2
  exit 0
fi

# ---------------------------------------------------------------------------
# check 모드: PROJECT.md가 hooks.env보다 새로우면 3 반환
# ---------------------------------------------------------------------------
if [ "$ACTION" = "check" ]; then
  if [ ! -f "$HOOKS_ENV" ] || [ "$PROJECT_MD" -nt "$HOOKS_ENV" ]; then
    exit 3
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# frontmatter 추출 (첫 번째 --- ~ 두 번째 --- 사이)
# ---------------------------------------------------------------------------
FRONTMATTER=$(awk '/^---[[:space:]]*$/{n++; next} n==1{print} n>=2{exit}' "$PROJECT_MD")

# key 값 조회: 주석·인용부호 제거, 없으면 기본값
get_key() {
  local key="$1" default="$2" val
  val=$(echo "$FRONTMATTER" \
    | grep -E "^${key}:" | head -n 1 \
    | sed "s/^${key}:[[:space:]]*//" \
    | sed 's/[[:space:]]*#.*$//' \
    | sed 's/^"//;s/"$//' \
    | sed "s/^'//;s/'\$//" || true)
  if [ -z "$val" ]; then
    echo "$default"
  else
    echo "$val"
  fi
}

PROJECT_NAME=$(get_key "project_name" "unnamed-project")
PROJECT_TYPE=$(get_key "project_type" "unknown")
CODE_DIRS=$(get_key "code_dirs" "backend web src app frontend e2e")
CODE_EXTS=$(get_key "code_exts" "py js ts tsx jsx vue html css")
LINE_WARN=$(get_key "line_warn" "500")
LINE_CRIT=$(get_key "line_crit" "700")
COVERAGE=$(get_key "coverage_target" "80")
NOTIFY_CHANNEL=$(get_key "notify_channel" "none")
NOTIFY_LABEL=$(get_key "notify_project_label" "$PROJECT_NAME")
BUILD_CMD=$(get_key "build_cmd" "none")
RUN_CMD=$(get_key "run_cmd" "none")
TEST_CMD=$(get_key "test_cmd" "none")
LINT_CMD=$(get_key "lint_cmd" "none")
SSOT_VERSION=$(get_key "ssot_version" "unknown")
SSOT_PATH=$(get_key "ssot_path" "docs/SSOT")

# 숫자 검증 (비정상 값은 기본값으로)
case "$LINE_WARN" in ''|*[!0-9]*) LINE_WARN=500 ;; esac
case "$LINE_CRIT" in ''|*[!0-9]*) LINE_CRIT=700 ;; esac
case "$COVERAGE"  in ''|*[!0-9]*) COVERAGE=80  ;; esac

# ---------------------------------------------------------------------------
# hooks.env 생성
# ---------------------------------------------------------------------------
mkdir -p "$(dirname "$HOOKS_ENV")"
cat > "$HOOKS_ENV" <<ENVEOF
# =============================================================================
# hooks.env — 자동 생성 파일 (직접 수정 금지)
# 소스: PROJECT.md frontmatter
# 재생성: ./scripts/sync-project-config.sh  (또는 /project-config sync)
# 생성 시각: $(date '+%Y-%m-%d %H:%M:%S')
# =============================================================================

PAB_PROJECT_NAME="$PROJECT_NAME"
PAB_PROJECT_TYPE="$PROJECT_TYPE"
PAB_CODE_DIRS="$CODE_DIRS"
PAB_CODE_EXTS="$CODE_EXTS"
PAB_LINE_WARN=$LINE_WARN
PAB_LINE_CRIT=$LINE_CRIT
PAB_COVERAGE_TARGET=$COVERAGE
PAB_NOTIFY_CHANNEL="$NOTIFY_CHANNEL"
PAB_NOTIFY_LABEL="$NOTIFY_LABEL"
PAB_BUILD_CMD="$BUILD_CMD"
PAB_RUN_CMD="$RUN_CMD"
PAB_TEST_CMD="$TEST_CMD"
PAB_LINT_CMD="$LINT_CMD"
PAB_SSOT_VERSION="$SSOT_VERSION"
PAB_SSOT_PATH="$SSOT_PATH"
ENVEOF

echo "[project-config] hooks.env 재생성 완료 — project=$PROJECT_NAME, code_dirs=[$CODE_DIRS], HR-5=$LINE_WARN/$LINE_CRIT" >&2
exit 0
