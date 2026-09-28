#!/usr/bin/env bash
# 센티넬 회귀 검증(reconcile · end · release · hr1-guard 연동 · 중첩 session_id)

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
SENTINEL_BASE="/tmp/agent-teams-active"
SH="$HOOK_DIR/team-sentinel.sh"
PASS=0; FAIL=0

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
  rm -rf "$F" "${F}.lock" "$F2" "${F2}.lock" "$VF" "$VF2"
  rm -f "$SENTINEL_BASE"
  if [ -n "$BACKUP" ]; then cp "$BACKUP" "$SENTINEL_BASE"; rm -f "$BACKUP"; fi
  if [ -n "$HOOKS_ENV_BACKUP" ]; then
    cp "$HOOKS_ENV_BACKUP" "$HOOKS_ENV"
    chmod "$HOOKS_ENV_PERM" "$HOOKS_ENV" 2>/dev/null || true
    rm -f "$HOOKS_ENV_BACKUP"
  fi
}
trap cleanup EXIT

SIDA="selftest-a-$$"; SIDB="selftest-b-$$"
F="${SENTINEL_BASE}-${SIDA}"; F2="${SENTINEL_BASE}-${SIDB}"; G="$SENTINEL_BASE"
VF=""; VF2=""
raw() { OUT="$(printf '%s' "$2" | bash "$SH" "$1" 2>/dev/null)"; RC=$?; }
zf() { [ "$RC" -eq 0 ] && [ -z "$OUT" ]; }
ids() { [ -f "$1" ] && cut -f1 "$1" 2>/dev/null | sort | paste -sd, - || echo "없음"; }
tsv() { awk -F'\t' -v k="$2" '$1==k{print $2; exit}' "$1" 2>/dev/null; }
put() { local f="$1"; shift; if [ "$#" -eq 0 ]; then rm -f "$f"; else printf '%s\n' "$@" > "$f"; fi; }
row() {
  if [ "$3" = true ]; then printf '  [PASS] %s — %s (%s)\n' "$1" "$2" "$4"; PASS=$((PASS+1))
  else printf '  [FAIL] %s — %s — 실제: %s\n' "$1" "$2" "$4"; FAIL=$((FAIL+1)); fi
}

echo "=== ⑨ reconcile — RC1~RC13(task-10-8-3 §2.5.2) ==="
T0=$(date +%s); TM100=$((T0-100))
put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")" "$(printf 'agX\t%s\tExplore' "$TM100")"
raw reconcile "$(printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false,"background_tasks":[]}' "$SIDA")"
c=false; zf && [ "$(ids "$F")" = "agX" ] && c=true
row RC1 "팀원 0→tm: 삭제·서브에이전트 보존" "$c" "F=$(ids "$F")"

T0=$(date +%s); TM100=$((T0-100)); put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")"
raw reconcile "$(printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false,"background_tasks":[{"id":"t1","type":"teammate","status":"running"}]}' "$SIDA")"
c=false; t=$(tsv "$F" tm:mate1); zf && [ "$(ids "$F")" = "tm:mate1" ] && [ -n "$t" ] && [ "$t" -ge "$T0" ] 2>/dev/null && c=true
row RC2 "살아 있음→시각 갱신" "$c" "F=$(ids "$F") ts=${t:-∅}"

put "$F"; T0=$(date +%s)
raw reconcile "$(printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false,"background_tasks":[{"id":"t1","type":"teammate","status":"running"}]}' "$SIDA")"
c=false; t=$(tsv "$F" 'tm:*'); zf && [ "$(ids "$F")" = 'tm:*' ] && [ -n "$t" ] && [ "$t" -ge "$T0" ] 2>/dev/null && c=true
row RC3 "재무장(등록 전 스폰)" "$c" "F=$(ids "$F")"

T0=$(date +%s); TM100=$((T0-100)); put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")"
raw reconcile "$(printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false,"background_tasks":[{"id":"s1","type":"subagent","status":"running"}]}' "$SIDA")"
c=false; zf && [ ! -e "$F" ] && c=true
row RC4 "서브에이전트는 팀원이 아니다" "$c" "F=$([ -e "$F" ] && echo 있음 || echo 없음)"

T0=$(date +%s); TM100=$((T0-100)); put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")"
raw reconcile "$(printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false,"background_tasks":[{"type":"teammate","status":"completed"}]}' "$SIDA")"
c=false; zf && [ ! -e "$F" ] && c=true
row RC5 "종료 집합→삭제" "$c" "F=$([ -e "$F" ] && echo 있음 || echo 없음)"

T0=$(date +%s); TM100=$((T0-100)); put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")"
BMD5=$(md5 -q "$F")
raw reconcile "$(printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false}' "$SIDA")"
c=false; zf && [ -f "$F" ] && [ "$(md5 -q "$F")" = "$BMD5" ] && c=true
row RC6 "필드 없음→불변" "$c" "F=$(ids "$F")"

T0=$(date +%s); TM100=$((T0-100)); put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")"
BMD5=$(md5 -q "$F")
raw reconcile "$(printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false,"background_tasks":"x"}' "$SIDA")"
c=false; zf && [ -f "$F" ] && [ "$(md5 -q "$F")" = "$BMD5" ] && c=true
row RC7 "형식 이상→불변" "$c" "F=$(ids "$F")"

T0=$(date +%s); TM100=$((T0-100)); put "$F2" "$(printf 'agY\t%s\tExplore' "$TM100")"
BMD5=$(md5 -q "$F2")
raw reconcile "$(printf '{"session_id":"%s","agent_type":"general-purpose","hook_event_name":"Stop","stop_hook_active":false,"background_tasks":[]}' "$SIDB")"
c=false; zf && [ -f "$F2" ] && [ "$(md5 -q "$F2")" = "$BMD5" ] && c=true
row RC8 "리더 문맥 아님→불변" "$c" "F′=$(ids "$F2")"

TOLD=$(( $(date +%s) - 90000 ))
put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TOLD")" "$(printf 'agZ\t%s\tExplore' "$TOLD")"
T0=$(date +%s)
raw reconcile "$(printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false,"background_tasks":[{"id":"t1","type":"teammate","status":"running"}]}' "$SIDA")"
c=false; t=$(tsv "$F" 'tm:*'); zf && [ "$(ids "$F")" = 'tm:*' ] && [ -n "$t" ] && [ "$t" -ge "$T0" ] 2>/dev/null && c=true
row RC9 "TTL 먼저→재무장" "$c" "F=$(ids "$F")"

T0=$(date +%s); TM100=$((T0-100)); put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")"
raw reconcile "$(printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false,"background_tasks":[{"type":"teammate","status":"idle"}]}' "$SIDA")"
c=false; t=$(tsv "$F" tm:mate1); zf && [ "$(ids "$F")" = "tm:mate1" ] && [ -n "$t" ] && [ "$t" -ge "$T0" ] 2>/dev/null && c=true
row RC10 "모르는 상태=살아 있음" "$c" "F=$(ids "$F") ts=${t:-∅}"

put "$F"; T0=$(date +%s)
raw reconcile "$(printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false,"background_tasks":["s",3,{"type":"teammate"}]}' "$SIDA")"
c=false; t=$(tsv "$F" 'tm:*'); zf && [ "$(ids "$F")" = 'tm:*' ] && [ -n "$t" ] && [ "$t" -ge "$T0" ] 2>/dev/null && c=true
row RC11 "dict 아닌 항목 무시·status 없음" "$c" "F=$(ids "$F")"

T0=$(date +%s); TM100=$((T0-100)); put "$G" "$(printf 'x\t%s\ty' "$TM100")"
BMD5=$(md5 -q "$G")
raw reconcile '{"hook_event_name":"Stop","stop_hook_active":false,"background_tasks":[]}'
c=false; zf && [ -f "$G" ] && [ "$(md5 -q "$G")" = "$BMD5" ] && c=true
row RC12 "session_id 없음→전역 파일 불변" "$c" "G=$(ids "$G")"
rm -f "$G"

put "$F"
raw reconcile "$(printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false,"background_tasks":[]}' "$SIDA")"
c=false; zf && [ ! -e "$F" ] && c=true
row RC13 "빈 대조로 파일 생성 안 함" "$c" "F=$([ -e "$F" ] && echo 있음 || echo 없음)"

echo "=== ⑩ end — EN1~EN5(task-10-8-3 §2.5.3) ==="
T0=$(date +%s); TM100=$((T0-100))
put "$F" "$(printf 'a\t%s\tx' "$TM100")" "$(printf 'b\t%s\ty' "$TM100")" "$(printf 'c\t%s\tz' "$TM100")"
mkdir -p "${F}.lock"
raw end "$(printf '{"session_id":"%s","hook_event_name":"SessionEnd","reason":"clear"}' "$SIDA")"
c=false; zf && [ ! -e "$F" ] && [ ! -e "${F}.lock" ] && c=true
row EN1 "세션 파일·lock 정리" "$c" "F=$([ -e "$F" ] && echo 있음 || echo 없음) lock=$([ -e "${F}.lock" ] && echo 있음 || echo 없음)"
rm -rf "${F}.lock"

c=true
for r in prompt_input_exit logout other; do
  put "$F" "$(printf 'a\t%s\tx' "$TM100")"
  raw end "$(printf '{"session_id":"%s","hook_event_name":"SessionEnd","reason":"%s"}' "$SIDA" "$r")"
  { zf && [ ! -e "$F" ]; } || c=false
done
row EN2 "reason과 무관하게 정리" "$c" "마지막 F=$([ -e "$F" ] && echo 있음 || echo 없음)"

T0=$(date +%s); TM100=$((T0-100)); put "$G" "$(printf 'x\t%s\ty' "$TM100")"
BMD5=$(md5 -q "$G")
raw end '{"hook_event_name":"SessionEnd","reason":"other"}'
c=false; zf && [ -f "$G" ] && [ "$(md5 -q "$G")" = "$BMD5" ] && c=true
row EN3 "session_id 없음→전역 파일 불변" "$c" "G=$(ids "$G")"
rm -f "$G"

T0=$(date +%s); put "$F" "$(printf 'a\t%s\tx' "$T0")"
raw end "$(printf '{"session_id":"%s/../%s","hook_event_name":"SessionEnd","reason":"other"}' "$SIDA" "$SIDA")"
c=false; zf && [ -e "$F" ] && c=true
row EN4 "허용 문자 밖→무삭제" "$c" "F=$([ -e "$F" ] && echo 있음 || echo 없음)"

rm -f "$F"
raw end "$(printf '{"session_id":"%s","hook_event_name":"SessionEnd","reason":"other"}' "$SIDA")"
c=false; zf && [ ! -e "$F" ] && c=true
row EN5 "없는 파일도 오류 없이" "$c" "F=$([ -e "$F" ] && echo 있음 || echo 없음)"

echo "=== ⑪ release — RL1~RL5(task-10-8-3 §2.5.4) ==="
T0=$(date +%s); TM100=$((T0-100))
put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")" "$(printf 'tm:*\t%s\tteammate' "$TM100")" "$(printf 'agX\t%s\tExplore' "$TM100")"
put "$F2" "$(printf 'tm:m9\t%s\tteammate' "$TM100")"
BF2=$(md5 -q "$F2")
OUT="$(CLAUDE_CODE_SESSION_ID="$SIDB" bash "$SH" release --session "$SIDA" </dev/null 2>/tmp/.rl1.$$)"; RC=$?
ERRLN=$(wc -l < /tmp/.rl1.$$ | tr -d ' '); rm -f /tmp/.rl1.$$
c=false; [ "$RC" -eq 0 ] && [ -z "$OUT" ] && [ "$(ids "$F")" = "agX" ] && [ "$(md5 -q "$F2")" = "$BF2" ] && [ "$ERRLN" -eq 1 ] && c=true
row RL1 "인자가 환경보다 앞선다" "$c" "F=$(ids "$F") F′불변=$([ "$(md5 -q "$F2")" = "$BF2" ] && echo Y || echo N) err줄=$ERRLN"

put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")" "$(printf 'tm:*\t%s\tteammate' "$TM100")" "$(printf 'agX\t%s\tExplore' "$TM100")"
OUT="$(CLAUDE_CODE_SESSION_ID="$SIDA" bash "$SH" release </dev/null 2>/tmp/.rl2.$$)"; RC=$?
ERRLN=$(wc -l < /tmp/.rl2.$$ | tr -d ' '); rm -f /tmp/.rl2.$$
c=false; [ "$RC" -eq 0 ] && [ -z "$OUT" ] && [ "$(ids "$F")" = "agX" ] && [ "$ERRLN" -eq 1 ] && c=true
row RL2 "환경값 사용" "$c" "F=$(ids "$F") err줄=$ERRLN"

put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")"
put "$F2" "$(printf 'tm:m9\t%s\tteammate' "$TM100")"
BF=$(md5 -q "$F"); BF2=$(md5 -q "$F2")
OUT="$(env -u CLAUDE_CODE_SESSION_ID bash "$SH" release </dev/null 2>/tmp/.rl3.$$)"; RC=$?
ERRLN=$(wc -l < /tmp/.rl3.$$ | tr -d ' '); rm -f /tmp/.rl3.$$
c=false; [ "$RC" -eq 0 ] && [ -z "$OUT" ] && [ "$(md5 -q "$F")" = "$BF" ] && [ "$(md5 -q "$F2")" = "$BF2" ] && [ "$ERRLN" -eq 1 ] && c=true
row RL3 "세션 불명→아무것도 안 함" "$c" "F불변=$([ "$(md5 -q "$F")" = "$BF" ] && echo Y || echo N) err줄=$ERRLN"

put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")"
BF=$(md5 -q "$F")
OUT="$(bash "$SH" release --session "${SIDA}/x" </dev/null 2>/tmp/.rl4.$$)"; RC=$?
ERRLN=$(wc -l < /tmp/.rl4.$$ | tr -d ' '); rm -f /tmp/.rl4.$$
c=false; [ "$RC" -eq 0 ] && [ -z "$OUT" ] && [ "$(md5 -q "$F")" = "$BF" ] && [ "$ERRLN" -eq 1 ] && c=true
row RL4 "허용 문자 밖 세션" "$c" "F불변=$([ "$(md5 -q "$F")" = "$BF" ] && echo Y || echo N) err줄=$ERRLN"

put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")" "$(printf 'tm:*\t%s\tteammate' "$TM100")" "$(printf 'agX\t%s\tExplore' "$TM100")"
RL5FIFO="$(mktemp -u /tmp/rl5fifo.XXXXXX)"
mkfifo "$RL5FIFO"
sleep 5 > "$RL5FIFO" &
RL5HOLDER=$!
exec 3< "$RL5FIFO"
RL5T0=$(date +%s)
OUT="$(CLAUDE_CODE_SESSION_ID="$SIDA" bash "$SH" release <&3 2>/tmp/.rl5.$$)"; RC=$?
RL5T1=$(date +%s); RL5EL=$((RL5T1-RL5T0))
exec 3<&-
kill "$RL5HOLDER" 2>/dev/null; wait "$RL5HOLDER" 2>/dev/null
rm -f "$RL5FIFO"
ERRLN=$(wc -l < /tmp/.rl5.$$ | tr -d ' '); rm -f /tmp/.rl5.$$
c=false; [ "$RC" -eq 0 ] && [ -z "$OUT" ] && [ "$(ids "$F")" = "agX" ] && [ "$ERRLN" -eq 1 ] && [ "$RL5EL" -le 1 ] && c=true
row RL5 "stdin 무시(1초 안 종료)" "$c" "경과=${RL5EL}s F=$(ids "$F") err줄=$ERRLN"

echo "=== ⑫ 기존 동작 보존 — NS1(task-10-8-3 §2.5.5) ==="
T0=$(date +%s); TM100=$((T0-100)); put "$F" "$(printf 'tm:mate1\t%s\tteammate' "$TM100")"
BMD5=$(md5 -q "$F")
raw stop "$(printf '{"session_id":"%s","hook_event_name":"SubagentStop","agent_id":"a266ed2c","agent_type":""}' "$SIDA")"
c=false; zf && [ "$(md5 -q "$F")" = "$BMD5" ] && c=true
row NS1 "N-2 재현—팀원 줄 불변" "$c" "F=$(ids "$F")"

echo "=== ⑬ hr1-guard 연동(spawn 경로) — HG1~HG5(task-10-8-3 §2.5.6 · R-B) ==="
rm -f "$F" "$F2"
raw spawn "$(printf '{"session_id":"%s","hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"name":"mate1","subagent_type":"general-purpose"}}' "$SIDA")"
HGPAY=$(printf '{"session_id":"%s","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"backend/api/runner.py","content":"x"}}' "$SIDA")
HGOUT=$(printf '%s' "$HGPAY" | bash "$HOOK_DIR/hr1-guard.sh" 2>/dev/null); HGRC=$?
c=false; [ "$HGRC" -eq 2 ] && printf '%s' "$HGOUT" | grep -q 'HR-1: 팀 운영 중' && printf '%s' "$HGOUT" | grep -q '자동 해제' && c=true
row HG1 "팀 활성→차단·자동 해제 안내" "$c" "rc=$HGRC out=${HGOUT:0:80}"

raw reconcile "$(printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false,"background_tasks":[]}' "$SIDA")"
HGOUT=$(printf '%s' "$HGPAY" | bash "$HOOK_DIR/hr1-guard.sh" 2>/dev/null); HGRC=$?
c=false; [ "$HGRC" -eq 0 ] && c=true
row HG2 "해제 뒤→통과" "$c" "rc=$HGRC"

rm -f "$F" "$F2"
raw spawn "$(printf '{"session_id":"%s","hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"name":"mate1","subagent_type":"general-purpose"}}' "$SIDA")"
HGPAY3=$(printf '{"session_id":"%s","agent_type":"general-purpose","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"backend/api/runner.py","content":"x"}}' "$SIDB")
HGOUT=$(printf '%s' "$HGPAY3" | bash "$HOOK_DIR/hr1-guard.sh" 2>/dev/null); HGRC=$?
c=false; [ "$HGRC" -eq 0 ] && c=true
row HG3 "팀원 문맥(다른 세션)→통과" "$c" "rc=$HGRC"

HGPAY4=$(printf '{"session_id":"%s","agent_id":"a1","agent_type":"Explore","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"backend/api/runner.py","content":"x"}}' "$SIDA")
HGOUT=$(printf '%s' "$HGPAY4" | bash "$HOOK_DIR/hr1-guard.sh" 2>/dev/null); HGRC=$?
c=false; [ "$HGRC" -eq 0 ] && c=true
row HG4 "서브에이전트 문맥→통과" "$c" "rc=$HGRC"

echo "1" > "$SENTINEL_BASE"
HGOUT=$(printf '%s' "$HGPAY3" | bash "$HOOK_DIR/hr1-guard.sh" 2>/dev/null); HGRC=$?
c=false; [ "$HGRC" -eq 0 ] && c=true
row HG5 "전역 파일을 남긴 변형도 팀원 exit 0(C-4)" "$c" "rc=$HGRC"
rm -f "$SENTINEL_BASE" "$F" "$F2"

echo "=== ⑭ end 중첩 session_id 취약점 — EN6·EN7(verifier T3 r1 결함 #1) ==="
VSID="ts-victim-$$"; VF="${SENTINEL_BASE}-${VSID}"
put "$VF" "$(printf 'x\t%s\ty' "$(date +%s)")"
BVF=$(md5 -q "$VF")
raw end "$(printf '{"hook_event_name":"SessionEnd","reason":"other","extra":{"session_id":"%s"}}' "$VSID")"
c=false; zf && [ -f "$VF" ] && [ "$(md5 -q "$VF")" = "$BVF" ] && c=true
row EN6 "최상위 session_id 없음+중첩→피해 파일 불변" "$c" "VF=$([ -f "$VF" ] && echo 있음 || echo 없음)"

put "$VF" "$(printf 'x\t%s\ty' "$(date +%s)")"
BVF=$(md5 -q "$VF")
raw end "$(printf '{"session_id":null,"hook_event_name":"SessionEnd","reason":"other","extra":{"session_id":"%s"}}' "$VSID")"
c=false; zf && [ -f "$VF" ] && [ "$(md5 -q "$VF")" = "$BVF" ] && c=true
row EN7 "최상위 session_id=null+중첩→피해 파일 불변" "$c" "VF=$([ -f "$VF" ] && echo 있음 || echo 없음)"
rm -f "$VF"

echo "=== ⑮ spawn·reconcile 중첩 session_id 대조(verifier P3 대응) — SP17·RC14 ==="
VSID2="ts-victim2-$$"; VF2="${SENTINEL_BASE}-${VSID2}"
put "$VF2" "$(printf 'x\t%s\ty' "$(date +%s)")"
BVF2=$(md5 -q "$VF2")
raw spawn "$(printf '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"name":"mate1","subagent_type":"general-purpose","extra":{"session_id":"%s"}}}' "$VSID2")"
c=false; zf && [ -f "$VF2" ] && [ "$(md5 -q "$VF2")" = "$BVF2" ] && c=true
row SP17 "중첩 session_id 대조(spawn 무동작)" "$c" "VF=$([ -f "$VF2" ] && echo 있음 || echo 없음)"

put "$VF2" "$(printf 'x\t%s\ty' "$(date +%s)")"
BVF2=$(md5 -q "$VF2")
raw reconcile "$(printf '{"hook_event_name":"Stop","stop_hook_active":false,"background_tasks":[],"extra":{"session_id":"%s"}}' "$VSID2")"
c=false; zf && [ -f "$VF2" ] && [ "$(md5 -q "$VF2")" = "$BVF2" ] && c=true
row RC14 "중첩 session_id 대조(reconcile 무동작)" "$c" "VF=$([ -f "$VF2" ] && echo 있음 || echo 없음)"
rm -f "$VF2"

echo
ACTUAL_CASES=$((PASS + FAIL))
EXPECTED_CASES=33
if [ "$ACTUAL_CASES" -ne "$EXPECTED_CASES" ]; then
  echo "  [FAIL] 케이스 수 불일치: 실행 ${ACTUAL_CASES}건 (기대 ${EXPECTED_CASES}건) — 케이스 누락/중복 의심"
  FAIL=$((FAIL+1))
fi

echo "=== 결과: PASS ${PASS} / FAIL ${FAIL} (케이스 ${ACTUAL_CASES} / 기대 ${EXPECTED_CASES}) ==="
[ "$FAIL" -eq 0 ]
