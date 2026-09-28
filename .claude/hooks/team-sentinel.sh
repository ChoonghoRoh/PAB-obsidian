#!/usr/bin/env bash
# =============================================================================
# team-sentinel.sh — 팀 활성 센티넬 관리
# =============================================================================

set -uo pipefail

SENTINEL_BASE="/tmp/agent-teams-active"
STALE_TTL="${PAB_TEAM_SENTINEL_TTL:-86400}"
ACTION="${1:-start}"

# 명시 해제(release) — Team Lead가 Bash로 직접 호출
if [ "$ACTION" = "release" ]; then
  shift
  ARG_SESSION=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --session)
        if [ $# -ge 2 ]; then
          ARG_SESSION="$2"
          shift 2
        else
          shift 1
        fi
        ;;
      *)
        shift
        ;;
    esac
  done

  if [ -n "$ARG_SESSION" ]; then
    REL_SESSION="$ARG_SESSION"
  else
    REL_SESSION="${CLAUDE_CODE_SESSION_ID:-}"
  fi

  case "$REL_SESSION" in
    '')
      echo "team-sentinel release: 세션 ID를 알 수 없습니다(--session 또는 CLAUDE_CODE_SESSION_ID 필요)" >&2
      exit 0
      ;;
    *[!A-Za-z0-9_-]*)
      echo "team-sentinel release: 세션 ID 형식이 올바르지 않습니다: $REL_SESSION" >&2
      exit 0
      ;;
  esac
  if [ "${#REL_SESSION}" -gt 128 ]; then
    echo "team-sentinel release: 세션 ID 형식이 올바르지 않습니다: $REL_SESSION" >&2
    exit 0
  fi

  REL_SENTINEL="${SENTINEL_BASE}-${REL_SESSION}"
  if [ ! -f "$REL_SENTINEL" ]; then
    echo "team-sentinel release: 해제할 팀원 없음(세션 ${REL_SESSION})" >&2
    exit 0
  fi

  REL_COUNT=0
  REL_TMP="${REL_SENTINEL}.tmp.$$"
  : > "$REL_TMP" 2>/dev/null || { echo "team-sentinel release: 임시 파일 생성 실패" >&2; exit 0; }
  while IFS=$'\t' read -r r_id r_ts r_type || [ -n "${r_id:-}" ]; do
    [ -z "${r_id:-}" ] && continue
    case "$r_id" in
      tm:*)
        REL_COUNT=$((REL_COUNT + 1))
        continue
        ;;
    esac
    printf '%s\t%s\t%s\n' "$r_id" "$r_ts" "${r_type:-unknown}" >> "$REL_TMP"
  done < "$REL_SENTINEL"

  if [ -s "$REL_TMP" ]; then
    mv -f "$REL_TMP" "$REL_SENTINEL" 2>/dev/null || rm -f "$REL_TMP"
  else
    rm -f "$REL_TMP" "$REL_SENTINEL"
  fi

  echo "team-sentinel release: 팀원 센티넬 해제 완료(세션 ${REL_SESSION} · 해제 줄 수 ${REL_COUNT})" >&2
  exit 0
fi

INPUT=$(cat 2>/dev/null || true)

# 팀원 무장(spawn) · 대조(reconcile) — 리더 문맥에서만 동작
if [ "$ACTION" = "spawn" ] || [ "$ACTION" = "reconcile" ]; then
  if [ -n "$INPUT" ] && command -v python3 >/dev/null 2>&1; then
    printf '%s' "$INPUT" | SENTINEL_BASE="$SENTINEL_BASE" STALE_TTL="$STALE_TTL" PAB_ACTION="$ACTION" python3 -c '
import json, os, re, sys, time

TERMINAL = {"completed", "failed", "killed", "stopped", "cancelled", "error"}


def leader_context(d):
    a_id = d.get("agent_id")
    a_type = d.get("agent_type")
    return a_id in (None, "") and a_type in (None, "")


def valid_session(sid):
    return isinstance(sid, str) and re.fullmatch(r"[A-Za-z0-9_-]{1,128}", sid) is not None


def read_lines(path, ttl, now):
    out = []
    if not os.path.exists(path):
        return out
    try:
        with open(path) as f:
            for line in f:
                parts = line.rstrip("\n").split("\t")
                if len(parts) < 3 or not parts[0]:
                    continue
                a_id, a_ts, a_type = parts[0], parts[1], parts[2]
                try:
                    ts = int(a_ts)
                except Exception:
                    ts = now
                if now - ts >= ttl:
                    continue
                out.append([a_id, ts, a_type])
    except Exception:
        pass
    return out


def write_lines(path, lines):
    if not lines:
        try:
            os.remove(path)
        except Exception:
            pass
        return
    tmp = path + ".tmp." + str(os.getpid())
    try:
        with open(tmp, "w") as f:
            for a_id, ts, a_type in lines:
                f.write(a_id + "\t" + str(ts) + "\t" + a_type + "\n")
        os.replace(tmp, path)
    except Exception:
        try:
            os.remove(tmp)
        except Exception:
            pass


def do_spawn(d, sentinel, ttl, now):
    if d.get("tool_name") not in ("Agent", "Task"):
        return
    tool_input = d.get("tool_input")
    name = tool_input.get("name") if isinstance(tool_input, dict) else None
    if not isinstance(name, str) or name.strip() == "":
        return
    norm = re.sub(r"[^A-Za-z0-9._-]", "_", name)[:64]
    tm_id = "tm:" + norm
    lines = [row for row in read_lines(sentinel, ttl, now) if row[0] != tm_id]
    lines.append([tm_id, now, "teammate"])
    write_lines(sentinel, lines)


def alive(item):
    if not isinstance(item, dict) or item.get("type") != "teammate":
        return False
    return item.get("status") not in TERMINAL


def do_reconcile(d, sentinel, ttl, now):
    if "background_tasks" not in d:
        return
    tasks = d.get("background_tasks")
    if not isinstance(tasks, list):
        return
    lines = read_lines(sentinel, ttl, now)
    if sum(1 for t in tasks if alive(t)) == 0:
        lines = [row for row in lines if not row[0].startswith("tm:")]
    else:
        has_tm = False
        for row in lines:
            if row[0].startswith("tm:"):
                row[1] = now
                has_tm = True
        if not has_tm:
            lines.append(["tm:*", now, "teammate"])
    write_lines(sentinel, lines)


def main():
    try:
        d = json.load(sys.stdin)
    except Exception:
        return
    if not isinstance(d, dict) or not leader_context(d):
        return
    session_id = d.get("session_id")
    if not valid_session(session_id):
        return
    base = os.environ.get("SENTINEL_BASE", "/tmp/agent-teams-active")
    try:
        ttl = int(os.environ.get("STALE_TTL", "86400") or "86400")
    except Exception:
        ttl = 86400
    sentinel = base + "-" + session_id
    now = int(time.time())
    action = os.environ.get("PAB_ACTION", "")
    if action == "spawn":
        do_spawn(d, sentinel, ttl, now)
    elif action == "reconcile":
        do_reconcile(d, sentinel, ttl, now)


try:
    main()
except Exception:
    pass
'
  fi
  exit 0
fi

# 세션 종료 정리(end)
if [ "$ACTION" = "end" ]; then
  END_SESSION=""
  END_PY_TRIED=0
  if [ -n "$INPUT" ] && command -v python3 >/dev/null 2>&1; then
    END_PY_TRIED=1
    END_SESSION=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    sid = d.get("session_id") if isinstance(d, dict) else None
except Exception:
    sid = None
print(sid if isinstance(sid, str) else "")
' 2>/dev/null) || END_SESSION=""
  fi
  if [ "$END_PY_TRIED" -eq 0 ] && [ -n "$INPUT" ]; then
    END_SESSION=$(printf '%s' "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*:[[:space:]]*"//;s/"$//' || true)
  fi

  case "$END_SESSION" in
    '')
      exit 0
      ;;
    *[!A-Za-z0-9_-]*)
      exit 0
      ;;
  esac
  if [ "${#END_SESSION}" -gt 128 ]; then
    exit 0
  fi

  END_SENTINEL="${SENTINEL_BASE}-${END_SESSION}"
  rm -f "$END_SENTINEL"
  rm -rf "${END_SENTINEL}.lock"
  exit 0
fi

# 세션 · 에이전트 식별자 추출(start · stop 공용)
SESSION_ID=""; AGENT_ID=""; AGENT_TYPE=""
if [ -n "$INPUT" ] && command -v python3 >/dev/null 2>&1; then
  _EVAL=$(printf '%s' "$INPUT" | python3 -c '
import json, shlex, sys
try:
    d = json.load(sys.stdin)
    assert isinstance(d, dict)
except Exception:
    sys.exit(1)
def q(v):
    return shlex.quote("" if v is None else str(v))
print("SESSION_ID=" + q(d.get("session_id")))
print("AGENT_ID="   + q(d.get("agent_id")))
print("AGENT_TYPE=" + q(d.get("agent_type")))
' 2>/dev/null) || _EVAL=""
  [ -n "$_EVAL" ] && eval "$_EVAL"
fi

# python3가 없거나 파싱에 실패했을 때만 폴백한다 — 탐색 범위는 최상위 부분으로 제한(TD-80)
if [ -z "$SESSION_ID" ] && [ -n "$INPUT" ]; then
  SESSION_ID=$(printf '%s' "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*:[[:space:]]*"//;s/"$//' || true)
fi
if [ -z "$AGENT_ID" ] && [ -n "$INPUT" ]; then
  AGENT_ID=$(printf '%s' "$INPUT" | grep -o '"agent_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*:[[:space:]]*"//;s/"$//' || true)
fi

# session_id가 없으면 아무것도 하지 않는다 — 전역 파일에 쓰지 않는다(C-4)
if [ -z "$SESSION_ID" ]; then
  exit 0
fi
SENTINEL="${SENTINEL_BASE}-${SESSION_ID}"
[ -z "$AGENT_ID" ] && AGENT_ID="unknown"

# 동시 스폰 락 처리
LOCK="${SENTINEL}.lock"
LOCKED=false
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if mkdir "$LOCK" 2>/dev/null; then LOCKED=true; break; fi
  sleep 0.05
done
cleanup() { [ "$LOCKED" = true ] && rmdir "$LOCK" 2>/dev/null; return 0; }
trap cleanup EXIT

NOW=$(date +%s)
TMP="${SENTINEL}.tmp.$$"
: > "$TMP" 2>/dev/null || exit 0

# 기존 항목 승계
if [ -f "$SENTINEL" ]; then
  while IFS=$'\t' read -r a_id a_ts a_type || [ -n "${a_id:-}" ]; do
    [ -z "${a_id:-}" ] && continue
    [ "$a_id" = "$AGENT_ID" ] && continue
    case "${a_ts:-}" in ''|*[!0-9]*) a_ts=$NOW ;; esac
    [ $((NOW - a_ts)) -ge "$STALE_TTL" ] && continue
    printf '%s\t%s\t%s\n' "$a_id" "$a_ts" "${a_type:-unknown}" >> "$TMP"
  done < "$SENTINEL"
fi

if [ "$ACTION" = "start" ]; then
  printf '%s\t%s\t%s\n' "$AGENT_ID" "$NOW" "${AGENT_TYPE:-unknown}" >> "$TMP"
fi

if [ -s "$TMP" ]; then
  mv -f "$TMP" "$SENTINEL" 2>/dev/null || rm -f "$TMP"
else
  rm -f "$TMP" "$SENTINEL"
fi

exit 0
