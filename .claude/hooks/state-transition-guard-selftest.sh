#!/usr/bin/env bash
# 상태 전이 가드 회귀 검증 — 6-6 정책(무효 전이=경고+exit 0, 경고는 C-3 additionalContext)

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
GUARD_SRC="$HOOK_DIR/state-transition-guard.sh"

PASS=0
FAIL=0
case_count=0

# 격리 저장소 생성
mk_repo() {
  local initial="$1" dir
  dir="$(mktemp -d)"
  mkdir -p "$dir/.claude/hooks" "$dir/docs/phases/phase-x"
  cp "$GUARD_SRC" "$dir/.claude/hooks/state-transition-guard.sh"
  printf 'current_state: "%s"\n' "$initial" > "$dir/docs/phases/phase-x/phase-x-status.md"
  (
    cd "$dir" || exit 1
    git init -q
    git config user.email "t@t.com"
    git config user.name "t"
    git add -A
    git commit -qm init
  ) >/dev/null 2>&1
  printf '%s' "$dir"
}

payload() {
  printf '{"session_id":"stgselftest-%s","hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$$" "$1"
}

# 기존 케이스(구조적 오류 · 카운터 상한) — 차단 방식 그대로(exit 2 · stderr)
run_case() {
  local desc="$1" want="$2" repo="$3" relpath="$4" require="${5:-}" forbid="${6:-}"
  local out rc ok=true
  out=$(payload "$relpath" | bash "$repo/.claude/hooks/state-transition-guard.sh" 2>&1)
  rc=$?
  if [ "$rc" -ne "$want" ]; then
    ok=false
  fi
  if [ -n "$require" ] && ! grep -qF "$require" <<< "$out"; then
    ok=false
  fi
  if [ -n "$forbid" ] && grep -qF "$forbid" <<< "$out"; then
    ok=false
  fi
  if [ "$ok" = true ]; then
    printf '  [PASS] %s (exit %s)\n' "$desc" "$rc"
    PASS=$((PASS + 1))
  else
    printf '  [FAIL] %s — 기대 exit %s, 실제 %s\n' "$desc" "$want" "$rc"
    [ -n "$require" ] && printf '    (요구 문구 미검출: %s)\n' "$require"
    [ -n "$forbid" ] && printf '    (금지 문구 검출: %s)\n' "$forbid"
    [ -n "$out" ] && printf '    출력: %s\n' "$out"
    FAIL=$((FAIL + 1))
  fi
}

# 6-6 경고 케이스 — stdout · stderr를 분리해 C-3 채널을 따로 본다
run_case_warn() {
  local desc="$1" repo="$2" relpath="$3" require_out="${4:-}" forbid_out="${5:-}"
  local out err rc ok=true errf
  errf="$(mktemp)"
  out=$(payload "$relpath" | bash "$repo/.claude/hooks/state-transition-guard.sh" 2>"$errf")
  rc=$?
  err=$(cat "$errf"); rm -f "$errf"
  [ "$rc" -ne 0 ] && ok=false
  if [ -n "$require_out" ] && ! grep -qF "$require_out" <<< "$out"; then
    ok=false
  fi
  if [ -n "$forbid_out" ] && grep -qF "$forbid_out" <<< "$out"; then
    ok=false
  fi
  if [ "$ok" = true ]; then
    printf '  [PASS] %s (exit %s)\n' "$desc" "$rc"
    PASS=$((PASS + 1))
  else
    printf '  [FAIL] %s — 기대 exit 0 + stdout JSON, 실제 exit %s\n' "$desc" "$rc"
    printf '    stdout: %s\n' "${out:-(없음)}"
    printf '    stderr: %s\n' "${err:-(없음)}"
    FAIL=$((FAIL + 1))
  fi
}

echo "state-transition-guard-selftest.sh 시작"
echo ""

echo "=== [1] 격자① 무효 전이 — 6-6 정책: 경고 + exit 0 + additionalContext(C-3) ==="
case_count=$((case_count + 1))
REPO1="$(mk_repo IDLE)"
printf 'current_state: "DONE"\n' > "$REPO1/docs/phases/phase-x/phase-x-status.md"
run_case_warn "IDLE(커밋)→DONE(무효) → 경고(exit 0) + 모델 채널 전달" "$REPO1" "docs/phases/phase-x/phase-x-status.md" "additionalContext"

echo "=== [2] DEF-4 정상 전이 — 경고 없이 통과 ==="
case_count=$((case_count + 1))
printf 'current_state: "TEAM_SETUP"\n' > "$REPO1/docs/phases/phase-x/phase-x-status.md"
run_case_warn "IDLE(커밋)→TEAM_SETUP(정상) → 통과(경고 없음)" "$REPO1" "docs/phases/phase-x/phase-x-status.md" "" "additionalContext"
rm -rf "$REPO1"

echo "=== [3] 격자② 부재(신규 파일) ==="
case_count=$((case_count + 1))
REPO2="$(mk_repo IDLE)"
mkdir -p "$REPO2/docs/phases/phase-y"
printf 'current_state: "DONE"\n' > "$REPO2/docs/phases/phase-y/phase-y-status.md"
run_case "미커밋 신규 status.md → 조용히 통과" 0 "$REPO2" "docs/phases/phase-y/phase-y-status.md" "" "BLOCKED"
rm -rf "$REPO2"

echo "=== [N/A] 격자③ — rc≠0 ∧ 출력 있음은 구조적으로 불가능(문서화만, 케이스 미포함) ==="

echo "=== [4] 격자④ ls-tree 실패(트리 객체 손상) — 6-6 정책: exit 0(차단 복원은 10-10 정책 결정 대상) ==="
case_count=$((case_count + 1))
REPO4="$(mk_repo BUILDING)"
(
  cd "$REPO4" || exit 1
  head_sha="$(git rev-parse HEAD)"
  tree_sha="$(git cat-file -p "$head_sha" | awk '/^tree/{print $2}')"
  tree_obj=".git/objects/${tree_sha:0:2}/${tree_sha:2}"
  rm -f "$tree_obj"
) >/dev/null 2>&1
printf 'current_state: "VERIFYING"\n' > "$REPO4/docs/phases/phase-x/phase-x-status.md"
run_case "HEAD 트리 객체 손상 → ls-tree 실패 → 과잉 차단 없이 통과" 0 "$REPO4" "docs/phases/phase-x/phase-x-status.md"
rm -rf "$REPO4"

echo "=== [5] H-2 회귀 — cat-file 실패(블롭 객체 손상) — 6-6 정책: exit 0(차단 복원은 10-10 정책 결정 대상) ==="
case_count=$((case_count + 1))
REPO5="$(mk_repo BUILDING)"
(
  cd "$REPO5" || exit 1
  blob_sha="$(git ls-tree HEAD -- docs/phases/phase-x/phase-x-status.md | awk '{print $3}')"
  blob_obj=".git/objects/${blob_sha:0:2}/${blob_sha:2}"
  rm -f "$blob_obj"
) >/dev/null 2>&1
printf 'current_state: "VERIFYING"\n' > "$REPO5/docs/phases/phase-x/phase-x-status.md"
run_case "이전 블롭 객체 손상 → cat-file 실패 → 과잉 차단 없이 통과" 0 "$REPO5" "docs/phases/phase-x/phase-x-status.md"
rm -rf "$REPO5"

echo "=== [6] H-3 회귀 — 비-git 디렉토리 ==="
case_count=$((case_count + 1))
REPO6="$(mktemp -d)"
mkdir -p "$REPO6/.claude/hooks" "$REPO6/docs/phases/phase-x"
cp "$GUARD_SRC" "$REPO6/.claude/hooks/state-transition-guard.sh"
printf 'current_state: "DONE"\n' > "$REPO6/docs/phases/phase-x/phase-x-status.md"
run_case "비-git 디렉토리 → 과잉 차단 없이 통과" 0 "$REPO6" "docs/phases/phase-x/phase-x-status.md"
rm -rf "$REPO6"

echo "=== [7] H-3 회귀 — 커밋 0개 저장소 ==="
case_count=$((case_count + 1))
REPO7="$(mktemp -d)"
mkdir -p "$REPO7/.claude/hooks" "$REPO7/docs/phases/phase-x"
cp "$GUARD_SRC" "$REPO7/.claude/hooks/state-transition-guard.sh"
(cd "$REPO7" && git init -q) >/dev/null 2>&1
printf 'current_state: "DONE"\n' > "$REPO7/docs/phases/phase-x/phase-x-status.md"
run_case "커밋 0개 저장소 → 과잉 차단 없이 통과" 0 "$REPO7" "docs/phases/phase-x/phase-x-status.md"
rm -rf "$REPO7"

echo "=== [8] TD-91 — VERIFYING → INTEGRATION(병렬 재검증 PASS) 정상 전이 ==="
case_count=$((case_count + 1))
REPO8="$(mk_repo VERIFYING)"
printf 'current_state: "INTEGRATION"\n' > "$REPO8/docs/phases/phase-x/phase-x-status.md"
run_case_warn "VERIFYING(커밋)→INTEGRATION(정상) → 통과(경고 없음)" "$REPO8" "docs/phases/phase-x/phase-x-status.md" "" "additionalContext"
rm -rf "$REPO8"

readonly expected_cases=8
ACTUAL_CASES=$((PASS + FAIL))
if (( ACTUAL_CASES != expected_cases )); then
  echo "  [FAIL] 실행 케이스 수 불일치: PASS+FAIL=${ACTUAL_CASES}건 (기대 ${expected_cases}건) — run_case 누락/중복 의심"
  FAIL=$((FAIL + 1))
fi
if (( case_count != expected_cases )); then
  echo "  [FAIL] 선언 케이스 수 불일치: case_count=${case_count}건 (기대 ${expected_cases}건) — 카운터 증가줄 누락/중복 의심"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== 결과: PASS ${PASS} / FAIL ${FAIL} (케이스 ${case_count} / 기대 ${expected_cases}) ==="
[ "$FAIL" -eq 0 ]
