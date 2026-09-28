#!/usr/bin/env bash
set -euo pipefail

SELFTEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="${SELFTEST_DIR}/token_usage.py"
WORK_DIR="$(mktemp -d)"
PROJ_DIR="${WORK_DIR}/proj"
mkdir -p "${PROJ_DIR}"

# shellcheck disable=SC2329
cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

FAIL_COUNT=0
CASE_COUNT=0

run_py() {
  PYTHONPYCACHEPREFIX="${WORK_DIR}/pycache" python3 "${SCRIPT_PATH}" "$@"
}

assert_rc() {
  local case_name="$1" expected_rc="$2" actual_rc="$3" output="$4"
  CASE_COUNT=$((CASE_COUNT + 1))
  if [[ "${actual_rc}" -eq "${expected_rc}" ]]; then
    echo "  [PASS] ${case_name} (exit=${actual_rc})"
  else
    echo "  [FAIL] ${case_name} (exit=${actual_rc}, expected=${expected_rc}) — ${output}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_contains() {
  local case_name="$1" needle="$2" haystack="$3"
  CASE_COUNT=$((CASE_COUNT + 1))
  if [[ "${haystack}" == *"${needle}"* ]]; then
    echo "  [PASS] ${case_name}"
  else
    echo "  [FAIL] ${case_name} — '${needle}' 없음"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

json_get() {
  local json="$1" field="$2"
  python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
print(data[sys.argv[1]])
' "${field}" <<< "${json}"
}

assert_eq() {
  local case_name="$1" expected="$2" actual="$3"
  CASE_COUNT=$((CASE_COUNT + 1))
  if [[ "${actual}" == "${expected}" ]]; then
    echo "  [PASS] ${case_name}"
  else
    echo "  [FAIL] ${case_name} (actual=${actual}, expected=${expected})"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

LEADER_ID="aaaaaaaa-selftest-leader"
TEAM_ID="bbbbbbbb-selftest-team"
SINCE="2026-01-01T00:00:00Z"

mkdir -p "${PROJ_DIR}/${LEADER_ID}/subagents"

cat > "${PROJ_DIR}/${LEADER_ID}.jsonl" <<'JSONL'
{"type":"assistant","timestamp":"2026-01-01T00:00:01Z","sessionId":"aaaaaaaa-selftest-leader","message":{"id":"msg-A","usage":{"input_tokens":10,"cache_creation_input_tokens":5,"cache_read_input_tokens":2,"output_tokens":3}}}
{"type":"assistant","timestamp":"2026-01-01T00:00:02Z","sessionId":"aaaaaaaa-selftest-leader","message":{"id":"msg-A","usage":{"input_tokens":999,"cache_creation_input_tokens":999,"cache_read_input_tokens":999,"output_tokens":999}}}
{"type":"assistant","timestamp":"2026-01-01T00:00:03Z","sessionId":"aaaaaaaa-selftest-leader","message":{"id":"msg-B","usage":{"input_tokens":20,"cache_creation_input_tokens":0,"cache_read_input_tokens":4,"output_tokens":6}}}
{"type":"assistant","timestamp":"2025-12-31T23:59:50Z","sessionId":"aaaaaaaa-selftest-leader","message":{"id":"msg-BEFORE","usage":{"input_tokens":1000,"cache_creation_input_tokens":1000,"cache_read_input_tokens":1000,"output_tokens":1000}}}
{"type":"user","timestamp":"2026-01-01T00:00:04Z","sessionId":"aaaaaaaa-selftest-leader","message":{"id":"msg-NOUSAGE"}}
{"broken json line
JSONL

cat > "${PROJ_DIR}/${LEADER_ID}/subagents/agent-x.meta.json" <<'META'
{"name":"verify-backend","agentType":"pab-verifier"}
META

cat > "${PROJ_DIR}/${LEADER_ID}/subagents/agent-x.jsonl" <<'JSONL'
{"type":"assistant","timestamp":"2026-01-01T00:00:05Z","message":{"id":"msg-SUB","usage":{"input_tokens":7,"cache_creation_input_tokens":1,"cache_read_input_tokens":0,"output_tokens":2}}}
JSONL

cat > "${PROJ_DIR}/${TEAM_ID}.jsonl" <<'JSONL'
{"type":"assistant","timestamp":"2026-01-01T00:00:06Z","sessionId":"bbbbbbbb-selftest-team","agentName":"backend-dev","teamName":"team-xyz","message":{"id":"msg-TEAM","usage":{"input_tokens":100,"cache_creation_input_tokens":50,"cache_read_input_tokens":25,"output_tokens":25}}}
JSONL

echo "=== 합성 입력 집계(리더 2메시지 + 중복 1 + 기준 시각 전 1 + subagent 1 + 팀원 세션 1) ==="

RC=0
OUT="$(run_py --since "${SINCE}" --project-dir "${PROJ_DIR}" --json)" || RC=$?
assert_rc "전체 집계 rc" 0 "${RC}" "${OUT}"
assert_eq "전체 집계 noncache=229" "229" "$(json_get "${OUT}" total_noncache)"
assert_eq "전체 집계 cache_read=31" "31" "$(json_get "${OUT}" total_cache_read)"
assert_eq "전체 집계 messages=4" "4" "$(json_get "${OUT}" total_messages)"
assert_eq "전체 집계 file_count=3" "3" "$(json_get "${OUT}" file_count)"
assert_eq "깨진 줄 unread=1" "1" "$(json_get "${OUT}" unread_lines)"
assert_eq "열지 못한 파일=0" "0" "$(json_get "${OUT}" unopened_files)"
assert_contains "팀원 세션 키(agentName·teamName)" 'bbbbbbbb-backend-dev(team-xyz)' "${OUT}"
assert_contains "subagent 이름 키(meta.json)" 'verify-backend' "${OUT}"

echo ""
echo "=== --session 필터 ==="

RC=0
OUT="$(run_py --since "${SINCE}" --project-dir "${PROJ_DIR}" --session "${TEAM_ID}" --json)" || RC=$?
assert_rc "세션 필터 rc" 0 "${RC}" "${OUT}"
assert_eq "세션 필터 noncache=175" "175" "$(json_get "${OUT}" total_noncache)"
assert_eq "세션 필터 file_count=1" "1" "$(json_get "${OUT}" file_count)"

echo ""
echo "=== 기준 시각 이후 상한(--until) ==="

RC=0
OUT="$(run_py --since "${SINCE}" --until "2026-01-01T00:00:03Z" --project-dir "${PROJ_DIR}" --session "${LEADER_ID}" --json)" || RC=$?
assert_rc "until 상한 rc" 0 "${RC}" "${OUT}"
assert_eq "until 상한 noncache=18(msg-A만)" "18" "$(json_get "${OUT}" total_noncache)"

echo ""
echo "=== 메타 없는 subagent(파일명 대체) ==="

NOMETA_DIR="${WORK_DIR}/proj_nometa"
mkdir -p "${NOMETA_DIR}/ccccccc-selftest-session/subagents"
cat > "${NOMETA_DIR}/ccccccc-selftest-session/subagents/orphan-agent.jsonl" <<'JSONL'
{"type":"assistant","timestamp":"2026-01-01T00:00:01Z","message":{"id":"msg-ORPHAN","usage":{"input_tokens":1,"cache_creation_input_tokens":2,"cache_read_input_tokens":4,"output_tokens":3}}}
JSONL

RC=0
OUT="$(run_py --since "${SINCE}" --project-dir "${NOMETA_DIR}" --json)" || RC=$?
assert_rc "메타 없는 subagent rc" 0 "${RC}" "${OUT}"
assert_eq "메타 없는 subagent noncache=6" "6" "$(json_get "${OUT}" total_noncache)"
assert_eq "메타 없는 subagent file_count=1" "1" "$(json_get "${OUT}" file_count)"
assert_contains "메타 없는 subagent 파일명 키" 'orphan-agent' "${OUT}"

echo ""
echo "=== 잘못된 UTF-8 · 멀티바이트 잘린 끝줄(전체 중단 없음) ==="

UTF8_DIR="${WORK_DIR}/proj_utf8"
mkdir -p "${UTF8_DIR}"
{
  printf '{"type":"assistant","timestamp":"2026-01-01T00:00:01Z","message":{"id":"msg-U1","usage":{"input_tokens":1,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":0}}}\n'
  printf '\xff\xfe broken utf8\n'
  printf '{"type":"assistant","timestamp":"2026-01-01T00:00:02Z","message":{"id":"msg-U2","usage":{"input_tokens":2,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":0}}}\n'
  printf '{"type":"assistant","timestamp":"2026-01-01T00:00:03Z","message":{"id":"msg-U3","usage":{"input_tokens":4,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":0}}}\n'
  printf '\xe2\x82'
} > "${UTF8_DIR}/dddddddd-selftest-utf8.jsonl"

RC=0
OUT="$(run_py --since "${SINCE}" --project-dir "${UTF8_DIR}" --json)" || RC=$?
assert_rc "UTF-8 파손 흡수 rc" 0 "${RC}" "${OUT}"
assert_eq "UTF-8 파손 흡수 noncache=7" "7" "$(json_get "${OUT}" total_noncache)"
assert_eq "UTF-8 파손 흡수 unread=2" "2" "$(json_get "${OUT}" unread_lines)"
assert_eq "UTF-8 파손 흡수 messages=3" "3" "$(json_get "${OUT}" total_messages)"

echo ""
echo "=== 형식 밖 JSON 값 흡수(객체 아님 · 숫자 timestamp · 문자열 usage) ==="

SHAPE_DIR="${WORK_DIR}/proj_shape"
mkdir -p "${SHAPE_DIR}"
cat > "${SHAPE_DIR}/eeeeeeee-selftest-shape.jsonl" <<'JSONL'
{"type":"assistant","timestamp":"2026-01-01T00:00:01Z","message":{"id":"msg-S1","usage":{"input_tokens":5,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":5}}}
[1,2,3]
"just-a-string"
{"timestamp":1735689600,"message":{"id":"msg-NUMTS","usage":{"input_tokens":999,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":0}}}
{"timestamp":"2026-01-01T00:00:02Z","message":{"id":"msg-STRUSAGE","usage":"not-an-object"}}
{"type":"assistant","timestamp":"2026-01-01T00:00:03Z","message":{"id":"msg-S2","usage":{"input_tokens":3,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":2}}}
JSONL

RC=0
OUT="$(run_py --since "${SINCE}" --project-dir "${SHAPE_DIR}" --json)" || RC=$?
assert_rc "형식 밖 값 흡수 rc" 0 "${RC}" "${OUT}"
assert_eq "형식 밖 값 흡수 noncache=15" "15" "$(json_get "${OUT}" total_noncache)"
assert_eq "형식 밖 값 흡수 unread=4" "4" "$(json_get "${OUT}" unread_lines)"
assert_eq "형식 밖 값 흡수 messages=2" "2" "$(json_get "${OUT}" total_messages)"

echo ""
echo "=== TD-105 — usage 값 검증 순서(전부 문자열·일부 문자열·깨진 첫 출현 뒤 정상 중복) ==="

USAGE_DIR="${WORK_DIR}/proj_usage"
mkdir -p "${USAGE_DIR}"
cat > "${USAGE_DIR}/99999998-selftest-usage.jsonl" <<'JSONL'
{"type":"assistant","timestamp":"2026-01-01T00:00:01Z","message":{"id":"msg-ALLSTR","usage":{"input_tokens":"10","cache_creation_input_tokens":"5","cache_read_input_tokens":"2","output_tokens":"3"}}}
{"type":"assistant","timestamp":"2026-01-01T00:00:02Z","message":{"id":"msg-PARTSTR","usage":{"input_tokens":10,"cache_creation_input_tokens":5,"cache_read_input_tokens":"2","output_tokens":3}}}
{"type":"assistant","timestamp":"2026-01-01T00:00:03Z","message":{"id":"msg-DUP","usage":{"input_tokens":"broken","cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":0}}}
{"type":"assistant","timestamp":"2026-01-01T00:00:04Z","message":{"id":"msg-DUP","usage":{"input_tokens":8,"cache_creation_input_tokens":1,"cache_read_input_tokens":0,"output_tokens":1}}}
JSONL

RC=0
OUT="$(run_py --since "${SINCE}" --project-dir "${USAGE_DIR}" --json)" || RC=$?
assert_rc "usage 검증 rc" 0 "${RC}" "${OUT}"
assert_eq "usage 검증 unread=3(전부 문자열·일부 문자열·깨진 첫 출현)" "3" "$(json_get "${OUT}" unread_lines)"
assert_eq "usage 검증 messages=1(깨진 첫 출현 뒤 정상 중복만 집계)" "1" "$(json_get "${OUT}" total_messages)"
assert_eq "usage 검증 noncache=10(msg-DUP 두 번째만)" "10" "$(json_get "${OUT}" total_noncache)"

echo ""
echo "=== 권한 000 파일 → 열지 못한 파일 집계(가능하면) ==="

if [[ "$(id -u)" -ne 0 ]]; then
  PERM_DIR="${WORK_DIR}/proj_perm"
  mkdir -p "${PERM_DIR}"
  cat > "${PERM_DIR}/ffffffff-selftest-perm.jsonl" <<'JSONL'
{"type":"assistant","timestamp":"2026-01-01T00:00:01Z","message":{"id":"msg-PERM-OK","usage":{"input_tokens":9,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":0}}}
JSONL
  cat > "${PERM_DIR}/99999999-selftest-perm-denied.jsonl" <<'JSONL'
{"type":"assistant","timestamp":"2026-01-01T00:00:01Z","message":{"id":"msg-PERM-DENIED","usage":{"input_tokens":500,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":0}}}
JSONL
  chmod 000 "${PERM_DIR}/99999999-selftest-perm-denied.jsonl"

  RC=0
  OUT="$(run_py --since "${SINCE}" --project-dir "${PERM_DIR}" --json)" || RC=$?
  assert_rc "권한 000 rc" 0 "${RC}" "${OUT}"
  assert_eq "권한 000 noncache=9(읽을 수 있는 파일만)" "9" "$(json_get "${OUT}" total_noncache)"
  assert_eq "권한 000 unopened_files=1" "1" "$(json_get "${OUT}" unopened_files)"
  assert_eq "권한 000 file_count=2" "2" "$(json_get "${OUT}" file_count)"

  chmod 644 "${PERM_DIR}/99999999-selftest-perm-denied.jsonl"
else
  echo "  [SKIP] root 실행 — 파일 권한이 강제되지 않는다"
fi

echo ""
echo "=== 빈 디렉터리 ==="

EMPTY_DIR="${WORK_DIR}/empty"
mkdir -p "${EMPTY_DIR}"
RC=0
OUT="$(run_py --since "${SINCE}" --project-dir "${EMPTY_DIR}")" || RC=$?
assert_rc "빈 디렉터리 rc=1" 1 "${RC}" "${OUT}"

echo ""
echo "=== 인자 오류 ==="

RC=0
OUT="$(run_py --project-dir "${PROJ_DIR}" 2>&1)" || RC=$?
assert_rc "since 누락 rc=2" 2 "${RC}" "${OUT}"

RC=0
OUT="$(run_py --since "이건-ISO8601-아님" --project-dir "${PROJ_DIR}" 2>&1)" || RC=$?
assert_rc "since 형식 오류 rc=2" 2 "${RC}" "${OUT}"

echo ""
if [[ "${FAIL_COUNT}" -eq 0 ]]; then
  echo "token_usage_selftest.sh 전건 PASS (${CASE_COUNT}건)"
  exit 0
fi
echo "token_usage_selftest.sh 실패 ${FAIL_COUNT}건 / 실행 ${CASE_COUNT}건"
exit 1
