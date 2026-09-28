#!/usr/bin/env bash
# 팀 모드 실발화 스모크 — 사본 리더 세션에서 스폰·차단·해제를 실측한다

set -uo pipefail

REPO=""; SHA=""; OUT=""; EXPECT_BASE=false
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --sha) SHA="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --expect-base) EXPECT_BASE=true; shift ;;
    *) echo "알 수 없는 인자: $1" >&2; exit 1 ;;
  esac
done
if [ -z "$REPO" ] || [ -z "$SHA" ] || [ -z "$OUT" ]; then
  echo "사용법: $0 --repo <경로> --sha <SHA> --out <디렉터리> [--expect-base]" >&2
  exit 1
fi

mkdir -p "$OUT"
COPY="$OUT/repo"
rm -rf "$COPY"; mkdir -p "$COPY"
git -C "$REPO" archive "$SHA" .claude scripts docs/SSOT PROJECT.md | tar -x -C "$COPY"
git -C "$COPY" init -q
git -C "$COPY" add -A
git -C "$COPY" -c user.email=smoke@local -c user.name=smoke commit -qm smoke >/dev/null

SID=$(uuidgen | tr '[:upper:]' '[:lower:]')
SENTINEL="/tmp/agent-teams-active-$SID"
SESSION="smk108-${SID:0:8}"
STEPS_JSON="$OUT/.steps.jsonl"
: > "$STEPS_JSON"

# 판정 보조
sentinel_ids() { [ -f "$SENTINEL" ] && cut -f1 "$SENTINEL" 2>/dev/null | sort | tr '\n' ',' || echo "없음"; }
has_id() { [ -f "$SENTINEL" ] && cut -f1 "$SENTINEL" 2>/dev/null | grep -qx "$1"; }
live_snapshot() {
  local f
  for f in /tmp/agent-teams-active*; do
    [ -e "$f" ] || continue
    [ "$f" = "$SENTINEL" ] && continue
    printf '%s:%s\n' "$f" "$(md5 -q "$f" 2>/dev/null)"
  done | sort
}
transcript_file() {
  local esc; esc=$(printf '%s' "$COPY" | sed 's/[^A-Za-z0-9]/-/g')
  find "$HOME/.claude/projects" -maxdepth 1 -type d -name "*${esc}*" 2>/dev/null | head -1
}
# shellcheck disable=SC2329
has_block_string() {
  local d; d=$(transcript_file); [ -z "$d" ] && return 1
  grep -rq 'HR-1: 팀 운영 중' "$d/${SID}.jsonl" 2>/dev/null
}
poll_until() {
  local cond="$1" timeout="$2" poll="${3:-2}" elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    if eval "$cond"; then return 0; fi
    sleep "$poll"; elapsed=$((elapsed+poll))
  done
  return 1
}
send() { tmux send-keys -t "$SESSION" -l "$1"; sleep 0.3; tmux send-keys -t "$SESSION" Enter; }
record() {
  local id="$1" verdict="$2" evidence="$3" attempts="$4" fallback="${5:-false}"
  python3 -c 'import json,sys
print(json.dumps({"id":sys.argv[1],"verdict":sys.argv[2],"evidence":sys.argv[3],"attempts":int(sys.argv[4]),"fallback_used":sys.argv[5]=="true"}))' \
    "$id" "$verdict" "$evidence" "$attempts" "$fallback" >> "$STEPS_JSON"
  printf '  [%s] %s — %s\n' "$verdict" "$id" "$evidence"
}

# 지시 재전송 포함 실행
stage() {
  local id="$1" instr="$2" cond="$3" timeout="${4:-180}" maxretry="${5:-2}"
  local sends=1 verdict="FAIL"
  send "$instr"
  while true; do
    if poll_until "$cond" "$timeout" 2; then verdict="PASS"; break; fi
    [ "$sends" -gt "$maxretry" ] && break
    sends=$((sends+1))
    send "$instr"
  done
  record "$id" "$verdict" "F=$(sentinel_ids)" "$sends"
}

LIVE_BEFORE="$(live_snapshot)"

tmux new-session -d -s "$SESSION" -x 220 -y 60 -c "$COPY"
tmux send-keys -t "$SESSION" "env -u PAB_TELEGRAM_BOT_TOKEN -u PAB_TELEGRAM_CHAT_ID claude --session-id \"$SID\" --setting-sources project --permission-mode acceptEdits --allowedTools Write Agent Task SendMessage" Enter
if poll_until "tmux capture-pane -p -t \"$SESSION\" | grep -qi trust" 15 1; then
  tmux send-keys -t "$SESSION" Down
  sleep 0.5
  tmux send-keys -t "$SESSION" Enter
fi
poll_until "tmux capture-pane -p -t \"$SESSION\" | grep -qiE 'accept edits|bypass|❯'" 30 1 || true

stage C4 "Write 도구만 써서 scripts/zombiecheck/smk_c4.sh(내용 x)를 만들어라. 막히면 다른 도구로 다시 하지 말고 BLOCKED라고만 답하라" \
  "[ -f \"$COPY/scripts/zombiecheck/smk_c4.sh\" ]" 180 1

if [ "$EXPECT_BASE" = true ]; then
  SPAWN_RETRY=0
else
  SPAWN_RETRY=1
fi
stage SPAWN "Agent 도구로 이름 mate1인 general-purpose 팀원을 띄워라. 과업: 메시지를 받으면 그대로 수행" \
  "has_id tm:mate1" 180 "$SPAWN_RETRY"

if [ "$EXPECT_BASE" = true ]; then
  send "Write 도구만 써서 scripts/zombiecheck/smk_c1.sh(내용 x)를 만들어라. 막히면 다른 도구로 다시 하지 말고 BLOCKED라고만 답하라"
  poll_until "[ -f \"$COPY/scripts/zombiecheck/smk_c1.sh\" ] || has_block_string" 180 2 || true
  if [ -f "$COPY/scripts/zombiecheck/smk_c1.sh" ]; then
    record C1 FAIL "파일 생성됨(A-1 재현) F=$(sentinel_ids)" 1
  else
    record C1 PASS "차단됨 F=$(sentinel_ids)" 1
  fi
else
  stage C1 "Write 도구만 써서 scripts/zombiecheck/smk_c1.sh(내용 x)를 만들어라. 막히면 다른 도구로 다시 하지 말고 BLOCKED라고만 답하라" \
    "[ ! -f \"$COPY/scripts/zombiecheck/smk_c1.sh\" ] && has_block_string && has_id tm:mate1" 180 1
fi

stage C2 "SendMessage로 mate1에게: Write 도구로 scripts/zombiecheck/smk_c2.sh(내용 x)를 만들고 끝나면 알려 달라" \
  "[ -f \"$COPY/scripts/zombiecheck/smk_c2.sh\" ]" 180 1

stage C3 "이름 없이 Agent 도구(general-purpose)로 서브에이전트를 띄워 Write 도구로 scripts/zombiecheck/smk_c3.sh를 만들게 하라" \
  "[ -f \"$COPY/scripts/zombiecheck/smk_c3.sh\" ]" 180 1

if [ "$EXPECT_BASE" = true ]; then
  record K3b N/A "BASE — spawn 미구현이라 해당 없음" 0
  record K3a N/A "BASE — spawn 미구현이라 해당 없음" 0
  record K3d N/A "BASE — spawn 미구현이라 해당 없음" 0
else
  BEFORE_IDS=$(sentinel_ids)
  printf '{"session_id":"%s","hook_event_name":"SubagentStop","agent_id":"smkfake01","agent_type":""}' "$SID" \
    | bash "$COPY/.claude/hooks/team-sentinel.sh" stop >/dev/null 2>&1
  AFTER_IDS=$(sentinel_ids)
  if [ "$BEFORE_IDS" = "$AFTER_IDS" ]; then V=PASS; else V=FAIL; fi
  record K3b "$V" "전=$BEFORE_IDS 후=$AFTER_IDS" 1

  K3A_FALLBACK=false
  send "mate1에게 shutdown_request를 보내고 승인한 뒤 결과를 한 줄로 답하라"
  if ! poll_until "! has_id tm:mate1" 120 2; then
    K3A_FALLBACK=true
    bash "$COPY/.claude/hooks/team-sentinel.sh" release --session "$SID" </dev/null >/dev/null 2>&1 || true
  fi
  if has_id tm:mate1; then V=FAIL; else V=PASS; fi
  record K3a "$V" "F=$(sentinel_ids)" 1 "$K3A_FALLBACK"

  stage K3d "Write 도구만 써서 scripts/zombiecheck/smk_c4b.sh(내용 x)를 만들어라" \
    "[ -f \"$COPY/scripts/zombiecheck/smk_c4b.sh\" ]" 180 1
fi

tmux send-keys -t "$SESSION" "/exit" Enter
if [ "$EXPECT_BASE" = true ]; then
  record K3c N/A "BASE — spawn 미구현이라 해당 없음" 0
  sleep 5
else
  if poll_until "[ ! -e \"$SENTINEL\" ]" 60 2; then V=PASS; else V=FAIL; fi
  record K3c "$V" "F=$([ -e "$SENTINEL" ] && echo 있음 || echo 없음)" 1
fi

tmux kill-session -t "$SESSION" 2>/dev/null || true

LIVE_AFTER="$(live_snapshot)"
[ "$LIVE_BEFORE" = "$LIVE_AFTER" ] && LIVE_UNTOUCHED=true || LIVE_UNTOUCHED=false
printf '%s' "$LIVE_BEFORE" > "$OUT/.live_before.txt"
printf '%s' "$LIVE_AFTER" > "$OUT/.live_after.txt"

python3 -c 'import json,sys
steps=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
lb=open(sys.argv[3]).read().splitlines()
la=open(sys.argv[4]).read().splitlines()
json.dump({"steps":steps,"live_untouched":sys.argv[5]=="true","live_before":lb,"live_after":la},
          open(sys.argv[2],"w"), ensure_ascii=False, indent=2)' \
  "$STEPS_JSON" "$OUT/result.json" "$OUT/.live_before.txt" "$OUT/.live_after.txt" "$LIVE_UNTOUCHED"
rm -f "$STEPS_JSON" "$OUT/.live_before.txt" "$OUT/.live_after.txt"

echo "결과: $OUT/result.json"
echo "잔존 확인 필요(삭제는 Team Lead 확인 뒤): ~/.claude/teams/session-${SID:0:8} · $(transcript_file)"
exit 0
