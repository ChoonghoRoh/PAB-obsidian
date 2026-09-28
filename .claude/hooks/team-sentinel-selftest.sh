#!/usr/bin/env bash
# 센티넬 회귀 검증(세션 격리 · 등록 · 해제 · stale 정리 · spawn 기본)

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
SENTINEL_BASE="/tmp/agent-teams-active"
SH="$HOOK_DIR/team-sentinel.sh"
SID="selftest-ts-$$"
SFILE="${SENTINEL_BASE}-${SID}"
PASS=0; FAIL=0

# 실행 전 실사용 상태 백업(전역 센티넬 · hooks.env) — 종료 시 복원
BACKUP=""
if [ -f "$SENTINEL_BASE" ]; then BACKUP="$(mktemp)"; cp "$SENTINEL_BASE" "$BACKUP"; fi
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
  rm -rf "$SFILE" "${SFILE}.lock" "${SENTINEL_BASE}.lock"
  rm -rf "$F" "${F}.lock"
  [ -n "${STRAY:-}" ] && rm -f "/tmp/$STRAY"
  rm -f "$SENTINEL_BASE"
  if [ -n "$BACKUP" ]; then cp "$BACKUP" "$SENTINEL_BASE"; rm -f "$BACKUP"; fi
  if [ -n "$HOOKS_ENV_BACKUP" ]; then
    cp "$HOOKS_ENV_BACKUP" "$HOOKS_ENV"
    chmod "$HOOKS_ENV_PERM" "$HOOKS_ENV" 2>/dev/null || true
    rm -f "$HOOKS_ENV_BACKUP"
  fi
}
trap cleanup EXIT

# 센티넬 이벤트 한 건을 team-sentinel.sh에 전달한다
ev() {
  local action="$1" aid="$2" sid="${3-$SID}"
  python3 - "$aid" "$sid" "$action" <<'PY' | bash "$SH" "$1" >/dev/null 2>&1
import json, sys
aid, sid, action = sys.argv[1:4]
d = {}
if sid: d["session_id"] = sid
d["cwd"] = "/tmp"
if aid: d["agent_id"] = aid
d["agent_type"] = "general-purpose"
d["hook_event_name"] = "SubagentStart" if action == "start" else "SubagentStop"
print(json.dumps(d))
PY
}

check() {
  local desc="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    printf '  [PASS] %s (%s)\n' "$desc" "$got"; PASS=$((PASS+1))
  else
    printf '  [FAIL] %s — 기대 %s, 실제 %s\n' "$desc" "$want" "$got"; FAIL=$((FAIL+1))
  fi
}
lines() { [ -f "$1" ] && wc -l < "$1" | tr -d ' ' || echo "없음"; }

# spawn 판정 보조 도구
SIDA="selftest-a-$$"
F="${SENTINEL_BASE}-${SIDA}"
SP15_SKIPPED=false
raw() { OUT="$(printf '%s' "$2" | bash "$SH" "$1" 2>/dev/null)"; RC=$?; }
zf() { [ "$RC" -eq 0 ] && [ -z "$OUT" ]; }
ids() { [ -f "$1" ] && cut -f1 "$1" 2>/dev/null | sort | paste -sd, - || echo "없음"; }
tsv() { awk -F'\t' -v k="$2" '$1==k{print $2; exit}' "$1" 2>/dev/null; }
put() { local f="$1"; shift; if [ "$#" -eq 0 ]; then rm -f "$f"; else printf '%s\n' "$@" > "$f"; fi; }
row() {
  if [ "$3" = true ]; then printf '  [PASS] %s — %s (%s)\n' "$1" "$2" "$4"; PASS=$((PASS+1))
  else printf '  [FAIL] %s — %s — 실제: %s\n' "$1" "$2" "$4"; FAIL=$((FAIL+1)); fi
}

echo "=== ① 세션 격리 · ② 멱등 등록 ==="
rm -f "$SFILE" "$SENTINEL_BASE"
ev start agentA
check "start 1건 → 세션 파일 1줄" "1" "$(lines "$SFILE")"
check "전역 파일은 미생성" "없음" "$(lines "$SENTINEL_BASE")"
ev start agentA
check "동일 agent 재 start → 여전히 1줄" "1" "$(lines "$SFILE")"
ev start agentB
check "다른 agent start → 2줄" "2" "$(lines "$SFILE")"

echo "=== ③ 정확한 해제 ==="
ev stop agentB
check "agentB stop → 1줄" "1" "$(lines "$SFILE")"
check "남은 항목이 agentA" "agentA" "$(cut -f1 "$SFILE" | tr -d '\n')"
ev stop agentA
check "전원 stop → 파일 삭제" "없음" "$(lines "$SFILE")"

echo "=== ④ 누락 내성(구판 카운터 결함 재현 방지) ==="
ev start agentX
ev start agentY
ev stop agentY
check "stop 누락 1건 있어도 정상 해제 반영" "1" "$(lines "$SFILE")"
check "남은 항목이 누락된 agentX" "agentX" "$(cut -f1 "$SFILE" | tr -d '\n')"

echo "=== ⑤ stale 정리 ==="
python3 - "$SFILE" <<'PY'
import sys, time, pathlib
p = pathlib.Path(sys.argv[1])
rows = [l.split('\t') for l in p.read_text().splitlines() if l]
p.write_text(''.join(f"{r[0]}\t{int(time.time())-172800}\t{r[2]}\n" for r in rows))
PY
ev start agentZ
check "TTL 초과 항목 제거 + 신규 1건만" "1" "$(lines "$SFILE")"
check "남은 항목이 agentZ" "agentZ" "$(cut -f1 "$SFILE" | tr -d '\n')"
ev stop agentZ
check "정리 후 전원 stop → 파일 삭제" "없음" "$(lines "$SFILE")"

echo "=== ⑥ session_id 부재 — 전역 폴백 없음(C-4) ==="
rm -f "$SENTINEL_BASE"
ev start agentF ""
check "session_id 없음 → 전역 파일 미생성(동작 없음)" "없음" "$(lines "$SENTINEL_BASE")"
ev stop agentF ""
check "session_id 없음 stop도 전역 파일 불변" "없음" "$(lines "$SENTINEL_BASE")"

echo "=== ⑦ hr1-guard 연동(세션 스코프 차단) ==="
ev start agentG
python3 - "$SID" <<'PY' > /tmp/.ts_selftest_payload.$$
import json, sys
print(json.dumps({"session_id": sys.argv[1], "cwd": "/tmp", "hook_event_name": "PreToolUse",
                  "tool_name": "Write",
                  "tool_input": {"file_path": "backend/api/runner.py", "content": "x"}}))
PY
bash "$HOOK_DIR/hr1-guard.sh" < /tmp/.ts_selftest_payload.$$ >/dev/null 2>&1; rc=$?
rm -f /tmp/.ts_selftest_payload.$$
check "팀원 활성 세션에서 TL 코드수정 차단" "2" "$rc"
ev stop agentG

echo "=== ⑧ spawn — SP1~SP16(task-10-8-3 §2.5.1) ==="
put "$F"; T0=$(date +%s)
raw spawn "$(printf '{"session_id":"%s","hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"d","prompt":"p","subagent_type":"general-purpose","name":"mate1"}}' "$SIDA")"
c=false; t=$(tsv "$F" tm:mate1); zf && [ "$(ids "$F")" = "tm:mate1" ] && [ -n "$t" ] && [ "$t" -ge "$T0" ] 2>/dev/null && c=true
row SP1 "기본 무장" "$c" "F=$(ids "$F") ts=${t:-∅} rc=$RC out=${OUT:-∅}"

T0=$(date +%s); TM100=$((T0-100)); put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")"
raw spawn "$(printf '{"session_id":"%s","hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"d","prompt":"p","subagent_type":"general-purpose","name":"mate1"}}' "$SIDA")"
c=false; t=$(tsv "$F" tm:mate1); zf && [ "$(ids "$F")" = "tm:mate1" ] && [ -n "$t" ] && [ "$t" -ge "$T0" ] 2>/dev/null && c=true
row SP2 "중복 없음·시각 갱신" "$c" "F=$(ids "$F") ts=${t:-∅}"

T0=$(date +%s); TM100=$((T0-100)); put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")"
raw spawn "$(printf '{"session_id":"%s","hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"d","prompt":"p","subagent_type":"general-purpose","name":"mate2"}}' "$SIDA")"
c=false; t1=$(tsv "$F" tm:mate1); t2=$(tsv "$F" tm:mate2)
zf && [ "$(ids "$F")" = "tm:mate1,tm:mate2" ] && [ "$t1" = "$TM100" ] && [ -n "$t2" ] && [ "$t2" -ge "$T0" ] 2>/dev/null && c=true
row SP3 "다른 줄 보존" "$c" "F=$(ids "$F") t1=$t1 t2=${t2:-∅}"

put "$F"
raw spawn "$(printf '{"session_id":"%s","hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"d","prompt":"p","subagent_type":"general-purpose"}}' "$SIDA")"
c=false; zf && [ "$(ids "$F")" = "없음" ] && c=true
row SP4 "name 키 없음→동작 없음" "$c" "F=$(ids "$F")"

put "$F"
raw spawn "$(printf '{"session_id":"%s","hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"name":"","subagent_type":"general-purpose"}}' "$SIDA")"
c1=false; zf && [ "$(ids "$F")" = "없음" ] && c1=true
raw spawn "$(printf '{"session_id":"%s","hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"name":"   ","subagent_type":"general-purpose"}}' "$SIDA")"
c2=false; zf && [ "$(ids "$F")" = "없음" ] && c2=true
c=false; [ "$c1" = true ] && [ "$c2" = true ] && c=true
row SP5 "빈 이름(공백 포함)" "$c" "F=$(ids "$F") 1차=$c1 2차=$c2"

put "$F"
raw spawn "$(printf '{"session_id":"%s","agent_type":"general-purpose","hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"name":"x","subagent_type":"general-purpose"}}' "$SIDA")"
c=false; zf && [ "$(ids "$F")" = "없음" ] && c=true
row SP6 "팀원 문맥→동작 없음" "$c" "F=$(ids "$F")"

put "$F"
raw spawn "$(printf '{"session_id":"%s","agent_id":"a1","agent_type":"Explore","hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"name":"x","subagent_type":"general-purpose"}}' "$SIDA")"
c=false; zf && [ "$(ids "$F")" = "없음" ] && c=true
row SP7 "서브에이전트 문맥→동작 없음" "$c" "F=$(ids "$F")"

put "$F"
raw spawn "$(printf '{"session_id":"%s","hook_event_name":"PreToolUse","tool_name":"TaskStop","tool_input":{"task_id":"t1"}}' "$SIDA")"
c=false; zf && [ "$(ids "$F")" = "없음" ] && c=true
row SP8 "무관 도구 거름" "$c" "F=$(ids "$F")"

put "$F"; T0=$(date +%s)
raw spawn "$(printf '{"session_id":"%s","hook_event_name":"PreToolUse","tool_name":"Task","tool_input":{"description":"d","prompt":"p","subagent_type":"general-purpose","name":"mate3"}}' "$SIDA")"
c=false; t=$(tsv "$F" tm:mate3); zf && [ "$(ids "$F")" = "tm:mate3" ] && [ -n "$t" ] && [ "$t" -ge "$T0" ] 2>/dev/null && c=true
row SP9 "도구 이름 변형 Task" "$c" "F=$(ids "$F")"

put "$F"
NAME10=$(printf 'a b\tc/../d*')
raw spawn "$(python3 -c 'import json,sys
print(json.dumps({"session_id":sys.argv[1],"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"name":sys.argv[2],"subagent_type":"general-purpose"}}))' "$SIDA" "$NAME10")"
c=false; zf && [ "$(ids "$F")" = "tm:a_b_c_.._d_" ] && c=true
row SP10 "정규화 [A-Za-z0-9._-] 밖→_" "$c" "F=$(ids "$F")"

put "$F"
NAME11=$(printf 'm%.0s' $(seq 1 100))
raw spawn "$(python3 -c 'import json,sys
print(json.dumps({"session_id":sys.argv[1],"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"name":sys.argv[2],"subagent_type":"general-purpose"}}))' "$SIDA" "$NAME11")"
EXPECT11="tm:$(printf 'm%.0s' $(seq 1 64))"
c=false; zf && [ "$(ids "$F")" = "$EXPECT11" ] && c=true
row SP11 "64자 절단" "$c" "F=$(ids "$F")"

put "$F"; rm -f "$SENTINEL_BASE"
raw spawn '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"name":"mate1","subagent_type":"general-purpose"}}'
c=false; zf && [ ! -e "$F" ] && [ ! -e "$SENTINEL_BASE" ] && c=true
row SP12 "session_id 없음→전역 파일 금지" "$c" "F=$([ -e "$F" ] && echo 있음 || echo 없음) G=$([ -e "$SENTINEL_BASE" ] && echo 있음 || echo 없음)"

put "$F"; STRAY="sp13-$$-$RANDOM"; rm -f "/tmp/$STRAY"
raw spawn "{\"session_id\":\"../../tmp/$STRAY\",\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"Agent\",\"tool_input\":{\"name\":\"mate1\",\"subagent_type\":\"general-purpose\"}}"
c=false; zf && [ ! -e "${SENTINEL_BASE}-../../tmp/$STRAY" ] && [ ! -e "/tmp/$STRAY" ] && c=true
row SP13 "허용 문자 밖 session_id" "$c" "stray=$([ -e "/tmp/$STRAY" ] && echo 있음 || echo 없음)"
rm -f "/tmp/$STRAY"

put "$F"
raw spawn 'not json'
c=false; zf && [ "$(ids "$F")" = "없음" ] && c=true
row SP14 "JSON 파싱 실패" "$c" "F=$(ids "$F")"

put "$F"
FALLBACK_BIN2="$(mktemp -d)"
for c15 in bash env dirname cat grep sed head cut sort date mkdir rmdir rm mv tr sleep paste awk; do
  src="$(command -v "$c15" 2>/dev/null || true)"; [ -n "$src" ] && ln -sf "$src" "$FALLBACK_BIN2/$c15"
done
if env PATH="$FALLBACK_BIN2" command -v python3 >/dev/null 2>&1; then
  echo "  [SKIP] SP15 — 폴백 격리 실패(python3 여전히 보임)"
  SP15_SKIPPED=true
else
  OUT="$(printf '%s' "$(printf '{"session_id":"%s","hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"name":"mate1","subagent_type":"general-purpose"}}' "$SIDA")" | env PATH="$FALLBACK_BIN2" bash "$SH" spawn 2>/dev/null)"; RC=$?
  c=false; zf && [ "$(ids "$F")" = "없음" ] && c=true
  row SP15 "python3 없으면 동작 없음" "$c" "F=$(ids "$F")"
fi
rm -rf "$FALLBACK_BIN2"

put "$F"
raw spawn "$(python3 -c 'import json,sys
print(json.dumps({"session_id":sys.argv[1],"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"subagent_type":"general-purpose","prompt":"...\"name\": \"evil\"..."}}))' "$SIDA")"
c=false; zf && [ "$(ids "$F")" = "없음" ] && c=true
row SP16 "본문 문자열 오탐 금지" "$c" "F=$(ids "$F")"

echo
ACTUAL_CASES=$((PASS + FAIL))
if [ "$SP15_SKIPPED" = true ]; then EXPECTED_CASES=30; else EXPECTED_CASES=31; fi
if [ "$ACTUAL_CASES" -ne "$EXPECTED_CASES" ]; then
  echo "  [FAIL] 케이스 수 불일치: 실행 ${ACTUAL_CASES}건 (기대 ${EXPECTED_CASES}건, SKIP=${SP15_SKIPPED}) — 케이스 누락/중복 의심"
  FAIL=$((FAIL+1))
fi

echo "=== 결과: PASS ${PASS} / FAIL ${FAIL} (케이스 ${ACTUAL_CASES} / 기대 ${EXPECTED_CASES}) ==="
[ "$FAIL" -eq 0 ]
