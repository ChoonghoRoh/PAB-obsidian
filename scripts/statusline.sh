#!/usr/bin/env bash
# statusline.sh — Claude Code 터미널 하단 인포창(Status Line) 스크립트
# 설정 위치: .claude/settings.json
#   "statusLine": { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR/scripts/statusline.sh\"" }
#
# Claude Code가 stdin으로 세션 JSON을 전달하면, stdout이 인포창에 표시된다.
# 여러 줄 출력 가능 — 2번째 줄부터는 Claude Code가 자동 들여쓴다.
#
#   1줄: 모델 · 사고수준 | 브랜치 · 작업트리 변경 | 최근 Skill | 여유 메모리 | 계정
#   2줄: 사용량 | Ctx 게이지 | 5시간·1주 사용률 게이지
#   3줄: 폴더 | SSOT 버전 | Phase 상태
#
# 팀원(서브에이전트) 패인에서는 아무것도 출력하지 않는다 — is_teammate 참조.
#
# 성능 — 이 스크립트는 렌더마다 실행된다. fork 가 곧 비용이다.
#
#   09-21 11:46 실측 (WSL2): bash 기동 2.1ms · fork 1회 0.31ms
#   같은 시각 재작성 전 42.6ms → 재작성 후 아래 원칙으로 줄였다.
#
#   ① 명령치환 $(...) 을 쓰지 않는다. 색·게이지·숫자 포맷은 전부 변수 대입이다
#      — $(c ...) 14회, $(bar ...) 3회, awk 2회가 그대로 fork 였다.
#   ② /proc 은 tr·awk 없이 bash 내장 read 로 읽는다
#      — is_teammate 가 조상 5대에 tr+awk 를 띄워 혼자 14.6ms 를 썼다.
#   ③ 느린 외부 명령(git·transcript·find·grep)은 TTL 캐시를 거친다.
#   ④ transcript 는 전체를 읽지 않는다. tac 은 파일을 통째로 뒤집으므로
#      세션이 길어질수록 선형으로 나빠진다 — 끝 2MB 만 본다.
#
# 디버그: echo '{}' | ./scripts/statusline.sh  로 단독 실행 가능

INPUT=$(cat 2>/dev/null || true)

# 팀원(서브에이전트) 패인에서는 출력하지 않는다
# 팀원은 `claude --agent-id <id> --agent-name <name> …` 로 뜨고 tmux 창 이름이
# teammate-* 다 (2.1.278 바이너리 실측 · 09-21 10:51).
#
# ⚠️ stdin 은 먼저 비운다. 읽지 않고 빠지면 Claude Code 쪽 쓰기가 EPIPE 로 깨진다.
# ⚠️ 메인 세션 조상 체인 (09-21 10:51 실측):
#      statusline.sh → /bin/sh -c "…/statusline.sh" → claude --dangerously-skip-permissions
#    팀원 조상 체인 (09-21 11:19 · 실제 팀원 안에서 실측):
#      bash → claude --agent-id sl-probe@… → tmux -L claude-swarm-<pid> new-session
#    래퍼가 한 겹 끼므로 조부모까지 봐야 한다. 여유를 둬 5대까지 훑는다.
# ⚠️ argv 를 NUL 로 쪼개 "요소 전체"와 비교한다. 이어 붙여 부분문자열로 찾으면
#    명령문 안에 --agent-id 라는 글자가 들어간 것만으로 걸린다(09-21 11:02 오탐).

is_teammate() {
  local pid="$PPID" depth=0 arg line
  [ -r /proc/self/stat ] || depth=5
  while [ "$depth" -lt 5 ] && [ -n "$pid" ] && [ "$pid" -gt 1 ] 2>/dev/null; do
    while IFS= read -r -d '' arg; do
      case "$arg" in --agent-id|--agent-id=*) return 0 ;; esac
    done < "/proc/$pid/cmdline" 2>/dev/null
    # /proc/<pid>/stat 은 `pid (comm) state ppid …` — comm 에 공백·괄호가 있을 수
    # 있어 마지막 ') ' 뒤부터 센다.
    read -r line < "/proc/$pid/stat" 2>/dev/null || return 1
    line=${line#*') '}
    line=${line#* }
    pid=${line%% *}
    depth=$((depth + 1))
  done
  # /proc 이 없는 환경(macOS 등) 폴백 — tmux 창 이름으로 판별
  if [ ! -r /proc/self/cmdline ] && [ -n "$TMUX" ]; then
    case "$(tmux display-message -p '#{window_name}' 2>/dev/null)" in
      teammate-*) return 0 ;;
    esac
  fi
  return 1
}

is_teammate && exit 0

C0=$'\033[0m'      # reset
CD=$'\033[2m'      # dim
C_CYAN=$'\033[96m'
C_GREEN=$'\033[92m'
C_YELLOW=$'\033[93m'
C_RED=$'\033[91m'
C_BLUE=$'\033[94m'
C_WHITE=$'\033[97m'
C_MAGENTA=$'\033[95m'
SEP="${CD}|${C0}"

# 10칸 게이지 — 채움 0~10 을 미리 깔아둔다. 매번 문자열을 만들면 그만큼 fork 다.
BARS=(
  '░░░░░░░░░░' '▓░░░░░░░░░' '▓▓░░░░░░░░' '▓▓▓░░░░░░░' '▓▓▓▓░░░░░░' '▓▓▓▓▓░░░░░'
  '▓▓▓▓▓▓░░░░' '▓▓▓▓▓▓▓░░░' '▓▓▓▓▓▓▓▓░░' '▓▓▓▓▓▓▓▓▓░' '▓▓▓▓▓▓▓▓▓▓'
)

# 게이지 + 색을 $GAUGE 에 담는다. 채움은 내림(45% → 4칸).
set_gauge() {
  local pct=${1:-0} idx
  [ "$pct" -lt 0 ] 2>/dev/null && pct=0
  [ "$pct" -gt 100 ] 2>/dev/null && pct=100
  idx=$((pct / 10))
  if   [ "$pct" -ge 80 ]; then GAUGE="${C_RED}${BARS[idx]}${C0}"
  elif [ "$pct" -ge 50 ]; then GAUGE="${C_YELLOW}${BARS[idx]}${C0}"
  else                         GAUGE="${C_GREEN}${BARS[idx]}${C0}"
  fi
}

# 토큰 수 축약을 $FMT 에 담는다 — 81900 → 81.9k · 1000000 → 1.0M
set_fmt() {
  local n=${1:-0}
  if   [ "$n" -ge 1000000 ] 2>/dev/null; then FMT="$((n / 1000000)).$(((n % 1000000) / 100000))M"
  elif [ "$n" -ge 1000 ] 2>/dev/null;    then FMT="$((n / 1000)).$(((n % 1000) / 100))k"
  else                                        FMT="$n"
  fi
}

# ⚠️ 09-21 11:12 — 필드를 탭이 아니라 "한 줄에 하나"로 받는다.
#    bash 의 IFS 공백 규칙이 연속 탭을 하나로 합쳐, 빈 필드가 있으면 값이 밀렸다.

JQ_FILTER='[
  (.model.display_name // "Claude"),
  (.effort.level // ""),
  (.workspace.current_dir // .cwd // ""),
  (.workspace.project_dir // .cwd // ""),
  (.transcript_path // ""),
  (.context_window.total_input_tokens // 0),
  (.context_window.context_window_size // 0),
  (.context_window.used_percentage // 0),
  (.rate_limits.five_hour.used_percentage // -1),
  (.rate_limits.seven_day.used_percentage // -1)
] | .[] | tostring | gsub("[\n\r\t]"; " ")'

FIELDS=()
if command -v jq >/dev/null 2>&1; then
  while IFS= read -r _f; do FIELDS+=("$_f"); done < <(printf '%s' "$INPUT" | jq -r "$JQ_FILTER" 2>/dev/null)
fi
if [ "${#FIELDS[@]}" -lt 10 ] && command -v python3 >/dev/null 2>&1; then
  FIELDS=()
  while IFS= read -r _f; do FIELDS+=("$_f"); done < <(printf '%s' "$INPUT" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
cw = d.get("context_window") or {}
rl = d.get("rate_limits") or {}
for x in [
    (d.get("model") or {}).get("display_name") or "Claude",
    (d.get("effort") or {}).get("level") or "",
    (d.get("workspace") or {}).get("current_dir") or d.get("cwd") or "",
    (d.get("workspace") or {}).get("project_dir") or d.get("cwd") or "",
    d.get("transcript_path") or "",
    cw.get("total_input_tokens") or 0,
    cw.get("context_window_size") or 0,
    cw.get("used_percentage") or 0,
    (rl.get("five_hour") or {}).get("used_percentage", -1),
    (rl.get("seven_day") or {}).get("used_percentage", -1),
]:
    print(str(x).replace("\n", " ").replace("\t", " "))' 2>/dev/null)
fi
while [ "${#FIELDS[@]}" -lt 10 ]; do FIELDS+=(''); done

MODEL="${FIELDS[0]}";    EFFORT="${FIELDS[1]}"
CUR_DIR="${FIELDS[2]}";  PROJECT_DIR="${FIELDS[3]}"
TRANSCRIPT="${FIELDS[4]}"
CTX_USED="${FIELDS[5]}"; CTX_SIZE="${FIELDS[6]}"; CTX_PCT="${FIELDS[7]}"
RL_5H="${FIELDS[8]}";    RL_7D="${FIELDS[9]}"

[ -z "$MODEL" ]       && MODEL="Claude"
[ -z "$CUR_DIR" ]     && CUR_DIR="$PWD"
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="$CUR_DIR"
DIR_NAME="${CUR_DIR##*/}"

# git · transcript · find · grep 이 합쳐 11ms 다. 렌더마다 낼 값이 아니다.
# 5초면 브랜치·증감·Skill·Phase 가 그만큼 늦게 보일 뿐, 판단에 지장이 없다.

CACHE_TTL=5
CACHE_KEY="${CUR_DIR//\//_}"
CACHE_FILE="${TMPDIR:-/tmp}/.claude-statusline-${UID:-0}-${CACHE_KEY}"

BRANCH=''; GIT_DIFF=''; SKILL=''; PHASE_INFO=''; ACCOUNT=''
CACHE_END=''; CACHE_TS=0; CACHE_SRC=''

# shellcheck source=/dev/null
[ -r "$CACHE_FILE" ] && . "$CACHE_FILE" 2>/dev/null

if [ "$CACHE_END" != "1" ] || [ "$CACHE_SRC" != "$CUR_DIR" ] \
   || [ $(( ${EPOCHSECONDS:-0} - CACHE_TS )) -ge "$CACHE_TTL" ] 2>/dev/null; then

  # 2-1. git 브랜치 · 작업트리 증감 (staged + unstaged, 바이너리는 0)
  BRANCH=$(git -C "$CUR_DIR" branch --show-current 2>/dev/null)
  GIT_DIFF=''
  if [ -n "$BRANCH" ]; then
    GIT_DIFF=$(git -C "$CUR_DIR" diff HEAD --numstat 2>/dev/null \
      | awk '{ a += ($1 == "-" ? 0 : $1); d += ($2 == "-" ? 0 : $2) }
             END { printf "(+%d,-%d)", a + 0, d + 0 }')
  fi

  # 2-2. 최근 호출 Skill — transcript 끝 2MB 만 역순 탐색
  # ⚠️ transcript 안의 "도구 입력 문자열"에서는 따옴표가 \" 로 이스케이프되므로
  #    아래 패턴은 실제 tool_use 블록에만 걸린다.
  SKILL=''
  if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    SKILL=$(tail -c 2000000 "$TRANSCRIPT" 2>/dev/null | tac \
      | grep -m1 -- '"name":"Skill","input"' \
      | grep -o '"skill":"[^"]*"' | tail -n 1)
    SKILL="${SKILL#\"skill\":\"}"
    SKILL="${SKILL%\"}"
  fi

  # 2-3. 현재 Phase 상태 (가장 최근 status.md)
  PHASE_INFO=''
  if [ -d "$PROJECT_DIR/docs/phases" ]; then
    _latest=$(find "$PROJECT_DIR/docs/phases" -name '*status.md' -type f -print0 2>/dev/null \
      | xargs -0 -r ls -t 2>/dev/null | head -n 1)
    if [ -n "$_latest" ]; then
      _state=$(grep 'current_state:' "$_latest" 2>/dev/null | head -n 1 \
        | sed 's/.*current_state:[[:space:]]*//;s/["'"'"'[:space:]]*$//')
      _state=${_state#\"}; _state=${_state%\"}   # 값 감싼 따옴표 제거 · PAB status.md
      _name="${_latest##*/}"; _name="${_name%-status.md}"; _name="${_name%.md}"
      [ -n "$_state" ] && PHASE_INFO="${_name}:${_state}"
    fi
  fi

  # 2-4. 계정
  ACCOUNT=''
  if [ -r "$HOME/.claude.json" ]; then
    ACCOUNT=$(grep -m1 -o '"emailAddress"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.claude.json" 2>/dev/null)
    ACCOUNT="${ACCOUNT%\"}"        # 끝 따옴표 제거
    ACCOUNT="${ACCOUNT##*\"}"      # 마지막 따옴표까지 버리면 값만 남는다
  fi

  # 2-5. 캐시 기록. 작은 한 덩이를 한 번에 써서 찢어질 틈을 줄이고,
  #      CACHE_END 를 마지막에 둬 부분 기록을 걸러낸다.
  _q() { local v=${1//\'/\'\\\'\'}; QUOTED="'$v'"; }
  _q "$BRANCH";     _b=$QUOTED
  _q "$GIT_DIFF";   _g=$QUOTED
  _q "$SKILL";      _s=$QUOTED
  _q "$PHASE_INFO"; _p=$QUOTED
  _q "$ACCOUNT";    _a=$QUOTED
  _q "$CUR_DIR";    _c=$QUOTED
  # 캐시에 계정 이메일이 들어간다 — /tmp 에 남으므로 본인만 읽게 만든다.
  _um=$(umask); umask 077
  printf 'CACHE_TS=%s\nCACHE_SRC=%s\nBRANCH=%s\nGIT_DIFF=%s\nSKILL=%s\nPHASE_INFO=%s\nACCOUNT=%s\nCACHE_END=1\n' \
    "${EPOCHSECONDS:-0}" "$_c" "$_b" "$_g" "$_s" "$_p" "$_a" > "$CACHE_FILE" 2>/dev/null
  umask "$_um"
fi

# hooks.env — source하지 않고 값 하나만 안전하게 읽는다

PAB_SSOT_VERSION=''
_hooks_env="$PROJECT_DIR/.claude/hooks/hooks.env"
if [ -f "$_hooks_env" ]; then
  _ssot_ver="$(sed -n 's/^PAB_SSOT_VERSION=//p' "$_hooks_env" 2>/dev/null | tail -n 1)"
  _ssot_ver="${_ssot_ver%$'\r'}"
  _ssot_ver="${_ssot_ver#\"}"; _ssot_ver="${_ssot_ver%\"}"
  _ssot_ver="${_ssot_ver#\'}"; _ssot_ver="${_ssot_ver%\'}"
  _ssot_ver="$(printf '%s' "$_ssot_ver" | sed "s/'\\\\''/'/g")"
  case "$_ssot_ver" in ''|*[!A-Za-z0-9._\ -]*) : ;; *) PAB_SSOT_VERSION="$_ssot_ver" ;; esac
fi

# /proc 직독 — awk 를 띄우지 않는다

MEM=''
if [ -r /proc/meminfo ]; then
  while read -r _k _v _; do
    if [ "$_k" = "MemAvailable:" ]; then
      MEM="$((_v / 1048576)).$(((_v % 1048576) * 10 / 1048576))G"
      break
    fi
  done < /proc/meminfo
fi

# 1줄 — 모델 · 브랜치 · Skill · 메모리 · 계정
L1="🧠 ${C_CYAN}${MODEL}${C0}"
[ -n "$EFFORT" ] && L1="${L1} ${CD}${EFFORT}${C0}"
if [ -n "$BRANCH" ]; then
  L1="${L1} ${SEP} 🌿 ${C_GREEN}${BRANCH}${C0}"
  [ -n "$GIT_DIFF" ] && L1="${L1} ${CD}${GIT_DIFF}${C0}"
fi
[ -n "$SKILL" ]   && L1="${L1} ${SEP} 🔧 ${C_YELLOW}${SKILL}${C0}"
[ -n "$MEM" ]     && L1="${L1} ${SEP} RAM ${C_GREEN}${MEM}${C0}"
[ -n "$ACCOUNT" ] && L1="${L1} ${SEP} 👤 ${CD}${ACCOUNT}${C0}"

# 2줄 — 컨텍스트 · 사용률
L2=''
if [ "${CTX_SIZE:-0}" -gt 0 ] 2>/dev/null; then
  set_gauge "$CTX_PCT"; _bar="${C_BLUE}${BARS[$((CTX_PCT / 10))]}${C0}"
  set_fmt "$CTX_USED";  _used=$FMT
  set_fmt "$CTX_SIZE";  _size=$FMT
  L2="Ctx ${_bar} ${_used}/${_size} ${CD}(${CTX_PCT}%)${C0}"
fi
if [ "${RL_5H:--1}" -ge 0 ] 2>/dev/null; then
  set_gauge "$RL_5H"
  [ -n "$L2" ] && L2="${L2} ${SEP}"
  L2="${L2} 5시간 ${GAUGE} ${RL_5H}%"
fi
if [ "${RL_7D:--1}" -ge 0 ] 2>/dev/null; then
  set_gauge "$RL_7D"
  [ -n "$L2" ] && L2="${L2} ${SEP}"
  L2="${L2} 1주 ${GAUGE} ${RL_7D}%"
fi
# 줄머리 타이틀 — 세그먼트가 하나도 없으면 타이틀도 달지 않는다
[ -n "$L2" ] && L2="📊 ${C_WHITE}사용량${C0} ${SEP} ${L2# }"

# 3줄 — 프로젝트 좌표 (PAB)
L3="📁 ${C_BLUE}${DIR_NAME}${C0}"
[ -n "$PAB_SSOT_VERSION" ] && L3="${L3} ${SEP} ${CD}SSOT ${PAB_SSOT_VERSION}${C0}"
if [ -n "$PHASE_INFO" ]; then
  L3="${L3} ${SEP} ⚙ ${C_MAGENTA}${PHASE_INFO}${C0}"
else
  L3="${L3} ${SEP} ⚙ ${CD}Phase:none${C0}"
fi

printf '%s\n' "$L1"
[ -n "$L2" ] && printf '%s\n' "$L2"
printf '%s\n' "$L3"
exit 0
