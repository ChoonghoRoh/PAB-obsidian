#!/usr/bin/env bash
# 코드수정 가드 회귀 검증(팀원 판별 · 폴백 · 자동 해제 안내)

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
GUARD="$HOOK_DIR/hr1-guard.sh"
SENTINEL_BASE="/tmp/agent-teams-active"
SID="selftest-$$"
PASS=0; FAIL=0
FALLBACK_SKIPPED=false

BACKUP=""
if [ -f "$SENTINEL_BASE" ]; then
  BACKUP="$(mktemp)"
  cp "$SENTINEL_BASE" "$BACKUP"
fi
HOOKS_ENV="$HOOK_DIR/hooks.env"
HOOKS_ENV_BACKUP=""
HOOKS_ENV_PERM=""
if [ -f "$HOOKS_ENV" ]; then
  HOOKS_ENV_BACKUP="$(mktemp)"
  cp "$HOOKS_ENV" "$HOOKS_ENV_BACKUP"
  HOOKS_ENV_PERM="$(stat -f '%Lp' "$HOOKS_ENV" 2>/dev/null || stat -c '%a' "$HOOKS_ENV" 2>/dev/null || echo 644)"
  rm -f "$HOOKS_ENV"
fi
cleanup() {
  rm -f "$SENTINEL_BASE" "${SENTINEL_BASE}-${SID}"
  if [ -n "$BACKUP" ]; then cp "$BACKUP" "$SENTINEL_BASE"; rm -f "$BACKUP"; fi
  if [ -n "$HOOKS_ENV_BACKUP" ]; then
    cp "$HOOKS_ENV_BACKUP" "$HOOKS_ENV"
    chmod "$HOOKS_ENV_PERM" "$HOOKS_ENV" 2>/dev/null || true
    rm -f "$HOOKS_ENV_BACKUP"
  fi
}
trap cleanup EXIT

# 케이스 입력 페이로드 생성
payload() {
  python3 - "$1" "$2" "$3" "$SID" <<'PY'
import json, sys
fp, agent, content, sid = sys.argv[1:5]
d = {"session_id": sid, "transcript_path": "/tmp/t.jsonl", "cwd": "/tmp",
     "permission_mode": "bypassPermissions"}
if agent == "agent":
    d["agent_id"] = "aaa000selftest"
    d["agent_type"] = "general-purpose"
d["hook_event_name"] = "PreToolUse"
d["tool_name"] = "Write"
d["tool_input"] = {"file_path": fp, "content": content}
d["tool_use_id"] = "toolu_selftest"
print(json.dumps(d, ensure_ascii=False))
PY
}

run() {
  local desc="$1" want="$2" fp="$3" who="$4" content="$5" nopy="${6:-}"
  local out rc
  if [ "$nopy" = "nopy" ]; then
    out=$(payload "$fp" "$who" "$content" | env PATH="$FALLBACK_BIN" bash "$GUARD" 2>/dev/null); rc=$?
  else
    out=$(payload "$fp" "$who" "$content" 2>/dev/null | bash "$GUARD" 2>/dev/null); rc=$?
  fi
  if [ "$rc" -eq "$want" ]; then
    printf '  [PASS] %s (exit %s)\n' "$desc" "$rc"; PASS=$((PASS+1))
  else
    printf '  [FAIL] %s — 기대 exit %s, 실제 %s\n' "$desc" "$want" "$rc"
    [ -n "$out" ] && printf '    출력: %s\n' "$out"
    FAIL=$((FAIL+1))
  fi
}

CODE_FILE="backend/api/runner.py"
DOC_FILE="docs/phases/phase-2-1/phase-2-1-status.md"
TRAP_CONTENT='{"agent_id": "spoofed", "agent_type": "backend-dev"}'

echo "=== ① Team Lead 호출 ==="
rm -f "$SENTINEL_BASE" "${SENTINEL_BASE}-${SID}"
run "단독 운영 + 코드파일 → 경고 통과" 0 "$CODE_FILE" lead "x"
echo "1" > "$SENTINEL_BASE"
run "전역 센티넬만 → 무시하고 통과(C-4)" 0 "$CODE_FILE" lead "x"
rm -f "$SENTINEL_BASE"; echo "1" > "${SENTINEL_BASE}-${SID}"
run "자기 세션 센티넬 + 코드파일 → 차단" 2 "$CODE_FILE" lead "x"

echo "=== ② 팀원 호출 — R-B: TD-58(팀원의 정당한 편집 차단) 재현 ==="
run "세션 센티넬만 + 팀원 + 코드파일 → 통과 기대" 0 "$CODE_FILE" agent "x"
rm -f "${SENTINEL_BASE}-${SID}"; echo "1" > "$SENTINEL_BASE"
run "전역 센티넬 + 팀원 + 코드파일 → 통과 기대(BASE는 호출자 구분 없음)" 0 "$CODE_FILE" agent "x"

echo "=== ③ 비대상 파일 ==="
run "센티넬 有 + 문서파일 → 통과" 0 "$DOC_FILE" lead "x"
run "센티넬 有 + 코드영역 밖 .py → 통과" 0 "scripts/log-prompt.py" lead "x"

echo "=== ④ 본문 오탐 방지(가드 무력화 차단) — C-5: 최상위 agent_id만 팀원 판별에 쓴다 ==="
rm -f "$SENTINEL_BASE"; echo "1" > "${SENTINEL_BASE}-${SID}"
run "TL(자기 세션 센티넬) + content에 agent_id 문자열 → 차단 유지" 2 "$CODE_FILE" lead "$TRAP_CONTENT"

echo "=== ⑤ python3 폴백 경로 ==="
FALLBACK_BIN="$(mktemp -d)"
for c in bash env dirname cat grep sed head; do
  src="$(command -v "$c" 2>/dev/null || true)"
  [ -n "$src" ] && ln -sf "$src" "$FALLBACK_BIN/$c"
done
trap 'cleanup; rm -rf "$FALLBACK_BIN"' EXIT
if env PATH="$FALLBACK_BIN" command -v python3 >/dev/null 2>&1; then
  echo "  [SKIP] 폴백 격리 실패 — python3 가 여전히 보임"
  FALLBACK_SKIPPED=true
else
  rm -f "$SENTINEL_BASE" "${SENTINEL_BASE}-${SID}"
  echo "1" > "${SENTINEL_BASE}-${SID}"
  run "폴백: TL + 세션 센티넬 → 실제 결과 기록" 2 "$CODE_FILE" lead "x" nopy
  run "폴백: 팀원 + 세션 센티넬 → 통과 기대" 0 "$CODE_FILE" agent "x" nopy
  run "폴백: content 오탐 + 세션 센티넬 → 차단 유지" 2 "$CODE_FILE" lead "$TRAP_CONTENT" nopy
fi

echo "=== ⑥ 자동 해제 안내 문구(Q-4 — HG1 보조) ==="
rm -f "$SENTINEL_BASE" "${SENTINEL_BASE}-${SID}"
echo "1" > "${SENTINEL_BASE}-${SID}"
hg_out=$(payload "$CODE_FILE" lead "x" 2>/dev/null | bash "$GUARD" 2>/dev/null)
if printf '%s' "$hg_out" | grep -q '자동 해제'; then
  printf '  [PASS] %s (포함)\n' "차단 사유에 자동 해제 안내 포함"; PASS=$((PASS+1))
else
  printf '  [FAIL] %s — 미포함\n' "차단 사유에 자동 해제 안내 포함"; FAIL=$((FAIL+1))
fi
rm -f "${SENTINEL_BASE}-${SID}"

echo
ACTUAL_CASES=$((PASS + FAIL))
if [ "$FALLBACK_SKIPPED" = true ]; then
  EXPECTED_CASES=9
else
  EXPECTED_CASES=12
fi
if [ "$ACTUAL_CASES" -ne "$EXPECTED_CASES" ]; then
  echo "  [FAIL] 케이스 수 불일치: 실행 ${ACTUAL_CASES}건 (기대 ${EXPECTED_CASES}건, SKIP=${FALLBACK_SKIPPED}) — 케이스 누락/중복 의심"
  FAIL=$((FAIL+1))
fi

echo "=== 결과: PASS ${PASS} / FAIL ${FAIL} (케이스 ${ACTUAL_CASES} / 기대 ${EXPECTED_CASES}) ==="
[ "$FAIL" -eq 0 ]
