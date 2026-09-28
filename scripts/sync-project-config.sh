#!/usr/bin/env bash
# sync-project-config.sh — PROJECT.md frontmatter → .claude/hooks/hooks.env 생성
# 사용법:
#   ./scripts/sync-project-config.sh          # 동기화 실행
#   ./scripts/sync-project-config.sh check    # 신선도만 검사 (0=최신, 3=재동기화 필요)
#
# PROJECT.md가 프로젝트 설정의 단일 소스(single source)이며,
# hooks.env는 본 스크립트가 생성하는 파생 산출물이다 (직접 수정 금지).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_MD="$PROJECT_ROOT/PROJECT.md"
HOOKS_ENV="$PROJECT_ROOT/.claude/hooks/hooks.env"
ACTION="${1:-sync}"

# 값을 작은따옴표로 감싼다 — 안의 작은따옴표는 '\''로 이스케이프
shq() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

if [ ! -f "$PROJECT_MD" ]; then
  echo "[project-config] PROJECT.md 없음 — hooks.env 기본값 유지" >&2
  exit 0
fi

guard_ok() {
  case "$1:$2" in
    dirs:|exts:) return 1 ;;
    dirs:*[!A-Za-z0-9._/\ -]*) return 1 ;;
    exts:*[!A-Za-z0-9._\ -]*) return 1 ;;
  esac
  return 0
}

env_value() {
  local v
  v="$(sed -n "s/^$1=//p" "$HOOKS_ENV" 2>/dev/null | tail -n 1)" || v=""
  v="${v%$'\r'}"
  v="${v#\"}"; v="${v%\"}"
  v="${v#\'}"; v="${v%\'}"
  printf '%s' "$v" | sed "s/'\\\\''/'/g"
}

# check 모드: PROJECT.md가 hooks.env보다 새로우면 3 반환
if [ "$ACTION" = "check" ]; then
  if [ -f "$HOOKS_ENV" ]; then
    for pair in dirs:PAB_CODE_DIRS exts:PAB_CODE_EXTS; do
      v="$(env_value "${pair#*:}")"
      [ -n "$v" ] || continue
      guard_ok "${pair%%:*}" "$v" || echo "[project-config] WARN: hooks.env ${pair#*:}='$v' — hr1-guard 허용 문자 밖이라 가드가 기본값으로 동작합니다" >&2
    done
  fi
  if [ ! -f "$HOOKS_ENV" ] || [ "$PROJECT_MD" -nt "$HOOKS_ENV" ]; then
    exit 3
  fi
  exit 0
fi

# frontmatter 추출 (첫 번째 --- ~ 두 번째 --- 사이)
FRONTMATTER=$(awk '/^---[[:space:]]*$/{n++; next} n==1{print} n>=2{exit}' "$PROJECT_MD")

# key 값 조회: 끝 \r(계약 C-2 — CRLF PROJECT.md 대비) · 주석 · 인용부호 제거, 없으면 기본값
get_key() {
  local key="$1" default="$2" val
  val=$(echo "$FRONTMATTER" \
    | grep -E "^${key}:" | head -n 1 \
    | tr -d '\r' \
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

normalize_list() {
  local kind="$1" key="$2" val="$3" out
  out="$(printf '%s' "$val" | tr ',' ' ' | tr -s ' ' | sed 's/^ //;s/ $//')"
  if [ "$out" != "$val" ] && printf '%s' "$val" | grep -q ','; then
    echo "[project-config] WARN: $key 쉼표를 공백 구분으로 바꿨습니다: '$val' → '$out' (PROJECT.md도 공백 구분으로 고치세요)" >&2
  fi
  guard_ok "$kind" "$out" || echo "[project-config] WARN: $key='$out' — hr1-guard 허용 문자 밖이라 가드가 기본값으로 동작합니다" >&2
  printf '%s' "$out"
}
CODE_DIRS=$(normalize_list dirs code_dirs "$CODE_DIRS")
CODE_EXTS=$(normalize_list exts code_exts "$CODE_EXTS")

# 숫자 검증 (비정상 값은 기본값으로)
case "$LINE_WARN" in ''|*[!0-9]*) LINE_WARN=500 ;; esac
case "$LINE_CRIT" in ''|*[!0-9]*) LINE_CRIT=700 ;; esac
case "$COVERAGE"  in ''|*[!0-9]*) COVERAGE=80  ;; esac

# hooks.env 생성 — 값은 작은따옴표로 감싼다(소비자가 source하지 않고 한 줄씩 읽는다)
mkdir -p "$(dirname "$HOOKS_ENV")"
cat > "$HOOKS_ENV" <<ENVEOF
# =============================================================================
# hooks.env — 자동 생성 파일 (직접 수정 금지)
# 소스: PROJECT.md frontmatter
# 재생성: ./scripts/sync-project-config.sh  (또는 /project-config sync)
# 생성 시각: $(date '+%Y-%m-%d %H:%M:%S')
# =============================================================================
ENVEOF

{
  printf 'PAB_PROJECT_NAME=%s\n' "$(shq "$PROJECT_NAME")"
  printf 'PAB_PROJECT_TYPE=%s\n' "$(shq "$PROJECT_TYPE")"
  printf 'PAB_CODE_DIRS=%s\n' "$(shq "$CODE_DIRS")"
  printf 'PAB_CODE_EXTS=%s\n' "$(shq "$CODE_EXTS")"
  printf 'PAB_LINE_WARN=%s\n' "$(shq "$LINE_WARN")"
  printf 'PAB_LINE_CRIT=%s\n' "$(shq "$LINE_CRIT")"
  printf 'PAB_COVERAGE_TARGET=%s\n' "$(shq "$COVERAGE")"
  printf 'PAB_NOTIFY_CHANNEL=%s\n' "$(shq "$NOTIFY_CHANNEL")"
  printf 'PAB_NOTIFY_LABEL=%s\n' "$(shq "$NOTIFY_LABEL")"
  printf 'PAB_BUILD_CMD=%s\n' "$(shq "$BUILD_CMD")"
  printf 'PAB_RUN_CMD=%s\n' "$(shq "$RUN_CMD")"
  printf 'PAB_TEST_CMD=%s\n' "$(shq "$TEST_CMD")"
  printf 'PAB_LINT_CMD=%s\n' "$(shq "$LINT_CMD")"
  printf 'PAB_SSOT_VERSION=%s\n' "$(shq "$SSOT_VERSION")"
  printf 'PAB_SSOT_PATH=%s\n' "$(shq "$SSOT_PATH")"
} >> "$HOOKS_ENV"

echo "[project-config] hooks.env 재생성 완료 — project=$PROJECT_NAME, code_dirs=[$CODE_DIRS], HR-5=$LINE_WARN/$LINE_CRIT" >&2
exit 0
