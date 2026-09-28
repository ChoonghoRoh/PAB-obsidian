#!/usr/bin/env bash
# hooks.env 소비자 안전성 회귀 검증 — R-A(설정값 안 명령 실행 · TD-70)

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
STATUSLINE_SRC="$HOOK_DIR/../../scripts/statusline.sh"
PASS=0; FAIL=0

MARK="$(mktemp -d)"
WS_ATTACK="$(mktemp -d)"
WS_CRLF="$(mktemp -d)"
cleanup() { rm -rf "$MARK" "$WS_ATTACK" "$WS_CRLF"; }
trap cleanup EXIT

# 소비자 5종 복사 + 격리 git 저장소 구성
mk_ws() {
  local ws="$1"
  mkdir -p "$ws/.claude/hooks" "$ws/scripts" "$ws/docs/SSOT" "$ws/docs/phases"
  cp "$HOOK_DIR/hr1-guard.sh" "$HOOK_DIR/line-count-monitor.sh" "$HOOK_DIR/on-task-completed.sh" "$HOOK_DIR/ssot-freshness-check.sh" "$HOOK_DIR/lock1-guard.sh" "$ws/.claude/hooks/"
  cp "$STATUSLINE_SRC" "$ws/scripts/"
  (cd "$ws" && git init -q && git config user.email t@t.com && git config user.name t && git add -A && git commit -qm init) >/dev/null 2>&1
}
mk_ws "$WS_ATTACK"
mk_ws "$WS_CRLF"

# 공격 fixture — 백틱 · $() · 큰따옴표 이탈 · 작은따옴표 이탈 4종을 심는다
cat > "$WS_ATTACK/.claude/hooks/hooks.env.tmpl" <<'EOF'
PAB_PROJECT_NAME="PAB-claude"
PAB_CODE_DIRS="backend web src app frontend e2e"
PAB_CODE_EXTS="py js ts tsx jsx vue html css"
PAB_LINE_WARN=500
PAB_LINE_CRIT=700
PAB_NOTIFY_LABEL="`touch __MARK__/backtick`"
PAB_BUILD_CMD="$(touch __MARK__/dollar)"
PAB_RUN_CMD="x"; touch __MARK__/dquote; UNUSED="y"
PAB_TEST_CMD='x'; touch __MARK__/squote; UNUSED='y'
PAB_SSOT_VERSION="ver6-6"
PAB_SSOT_PATH="docs/SSOT"
EOF
sed "s#__MARK__#$MARK#g" "$WS_ATTACK/.claude/hooks/hooks.env.tmpl" > "$WS_ATTACK/.claude/hooks/hooks.env"

# CRLF fixture — code_dirs 마지막 토큰(e2e)·ssot_path 값에 캐리지리턴을 심는다
printf 'PAB_PROJECT_NAME="PAB-claude"\nPAB_CODE_DIRS="backend web src app frontend e2e"\r\nPAB_CODE_EXTS="py js ts tsx jsx vue html css"\nPAB_LINE_WARN=500\nPAB_LINE_CRIT=700\nPAB_SSOT_PATH="custom-ssot"\r\n' > "$WS_CRLF/.claude/hooks/hooks.env"

# RA6용 — 기본값과 다른 SSOT 경로 + 활성 Phase(LOCK-1이 걸려야 CRLF 오염 시 안 걸리는 걸 구분)
mkdir -p "$WS_CRLF/custom-ssot" "$WS_CRLF/docs/phases/phase-ra6"
echo "dummy" > "$WS_CRLF/custom-ssot/dummy.md"
echo "current_state: BUILDING" > "$WS_CRLF/docs/phases/phase-ra6/status.md"

run5() {
  local ws="$1"
  local rc127=0
  echo '{}' | bash "$ws/.claude/hooks/hr1-guard.sh" >/dev/null 2>/tmp/.he_hr1.$$; [ $? -eq 127 ] && rc127=$((rc127+1)); rm -f /tmp/.he_hr1.$$
  echo '{}' | bash "$ws/.claude/hooks/line-count-monitor.sh" >/dev/null 2>&1; [ $? -eq 127 ] && rc127=$((rc127+1))
  bash "$ws/.claude/hooks/on-task-completed.sh" </dev/null >/dev/null 2>&1; [ $? -eq 127 ] && rc127=$((rc127+1))
  echo '{}' | bash "$ws/.claude/hooks/ssot-freshness-check.sh" >/dev/null 2>&1; [ $? -eq 127 ] && rc127=$((rc127+1))
  printf '{"workspace":{"project_dir":"%s"}}' "$ws" | bash "$ws/scripts/statusline.sh" >/dev/null 2>&1; [ $? -eq 127 ] && rc127=$((rc127+1))
  printf '%s' "$rc127"
}

echo "=== RA1 — 공격 fixture: 소비자 5종 실행 후 표지 파일 개수(기대 0) ==="
RA1_RC127="$(run5 "$WS_ATTACK")"
RA1_MARKS="$(ls "$MARK" 2>/dev/null | wc -l | tr -d ' ')"
if [ "$RA1_MARKS" -eq 0 ]; then
  printf '  [PASS] 표지 파일 0개\n'; PASS=$((PASS+1))
else
  printf '  [FAIL] 표지 파일 %s개 생성됨(명령 실행 확인) — %s\n' "$RA1_MARKS" "$(ls "$MARK" | tr '\n' ',')"; FAIL=$((FAIL+1))
fi

echo "=== RA2 — 공격 fixture: rc 127(명령 없음) 발생 0건 ==="
if [ "$RA1_RC127" -eq 0 ]; then
  printf '  [PASS] rc 127 발생 0건\n'; PASS=$((PASS+1))
else
  printf '  [FAIL] rc 127 발생 %s건\n' "$RA1_RC127"; FAIL=$((FAIL+1))
fi

echo "=== RA3 — CRLF fixture: 소비자 5종 rc 127 발생 0건 ==="
RA3_RC127="$(run5 "$WS_CRLF" crlf)"
if [ "$RA3_RC127" -eq 0 ]; then
  printf '  [PASS] rc 127 발생 0건\n'; PASS=$((PASS+1))
else
  printf '  [FAIL] rc 127 발생 %s건\n' "$RA3_RC127"; FAIL=$((FAIL+1))
fi

echo "=== RA4 — hr1-guard: 공격 fixture와 무관하게 backend/*.py 인식 ==="
RA4_OUT=$(printf '{"session_id":"ra4","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"backend/api/x.py","content":"x"}}' | bash "$WS_ATTACK/.claude/hooks/hr1-guard.sh" 2>&1)
if printf '%s' "$RA4_OUT" | grep -q '코드 수정 감지'; then
  printf '  [PASS] backend 코드파일 인식됨\n'; PASS=$((PASS+1))
else
  printf '  [FAIL] backend 코드파일 인식 실패\n'; FAIL=$((FAIL+1))
fi

echo "=== RA5 — hr1-guard: CRLF로 오염된 마지막 dir(e2e) 인식 ==="
RA5_OUT=$(printf '{"session_id":"ra5","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"e2e/spec/x.py","content":"x"}}' | bash "$WS_CRLF/.claude/hooks/hr1-guard.sh" 2>&1)
if printf '%s' "$RA5_OUT" | grep -q '코드 수정 감지'; then
  printf '  [PASS] e2e 코드파일 인식됨(CRLF 무관)\n'; PASS=$((PASS+1))
else
  printf '  [FAIL] e2e 코드파일 인식 실패(CRLF로 마지막 토큰 오염)\n'; FAIL=$((FAIL+1))
fi

echo "=== RA6 — lock1-guard: CRLF로 오염된 PAB_SSOT_PATH 인식(커스텀 경로 + 활성 Phase → 차단) ==="
RA6_OUT=$(printf '{"session_id":"ra6","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"custom-ssot/dummy2.md","content":"x"}}' | bash "$WS_CRLF/.claude/hooks/lock1-guard.sh" 2>&1)
RA6_RC=$?
if [ "$RA6_RC" -eq 2 ] && printf '%s' "$RA6_OUT" | grep -q '"decision": "block"'; then
  printf '  [PASS] 커스텀 SSOT 경로 인식되어 차단됨(CRLF 무관)\n'; PASS=$((PASS+1))
else
  printf '  [FAIL] 차단되지 않음(rc=%s) — PAB_SSOT_PATH가 CRLF로 오염돼 기본값(docs/SSOT)으로 대체됐을 가능성\n' "$RA6_RC"; FAIL=$((FAIL+1))
fi

echo
ACTUAL_CASES=$((PASS + FAIL))
EXPECTED_CASES=6
if [ "$ACTUAL_CASES" -ne "$EXPECTED_CASES" ]; then
  echo "  [FAIL] 케이스 수 불일치: 실행 ${ACTUAL_CASES}건 (기대 ${EXPECTED_CASES}건)"
  FAIL=$((FAIL+1))
fi

echo "=== 결과: PASS ${PASS} / FAIL ${FAIL} (케이스 ${ACTUAL_CASES} / 기대 ${EXPECTED_CASES}) ==="
[ "$FAIL" -eq 0 ]
