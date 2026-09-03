#!/usr/bin/env bash
#
# CouchDB 단방향(CouchDB->파일) 강제 — bridge 전용 읽기전용 계정 + 쓰기차단 검증함수
# Phase 2-1 방법 A 외부연계 — backend-dev
#
# livesync-bridge 는 네이티브 one-way 옵션이 없다(소스 확인: Hub.dispatch 가 같은 group
# 의 모든 peer 에 put/delete 를 전파, storage watcher 도 끌 수 없음).
# 따라서 CouchDB 권한 계층에서 역방향(storage->CouchDB)을 차단한다:
#   1) bridge 전용 비관리자 계정 'pabbridge' 생성 (_users)
#   2) pab-llmdata._security.members 에 pabbridge 추가 → 읽기 허용(_changes/문서/청크)
#   3) _design/zz_bridge_readonly 의 validate_doc_update 로 'pabbridge' 의 쓰기만 forbidden
#      (관리자 pabadmin = Obsidian LiveSync 쓰기 주체, 그리고 그 외 모든 사용자는 그대로 허용)
#
# 멱등: 재실행해도 안전(이미 존재 시 갱신/스킵). 동기화 데이터는 건드리지 않음.
#
# 필요 env:
#   COUCHDB_ADMIN_USER, COUCHDB_ADMIN_PASSWORD  (관리자)
#   BRIDGE_USER, BRIDGE_PASSWORD                 (생성할 읽기전용 계정)
#   COUCHDB_URL  (기본 http://100.109.251.86:5984), DB_NAME (기본 pab-llmdata)
set -euo pipefail

COUCHDB_URL="${COUCHDB_URL:-http://100.109.251.86:5984}"
DB_NAME="${DB_NAME:-pab-llmdata}"
: "${COUCHDB_ADMIN_USER:?need COUCHDB_ADMIN_USER}"
: "${COUCHDB_ADMIN_PASSWORD:?need COUCHDB_ADMIN_PASSWORD}"
: "${BRIDGE_USER:?need BRIDGE_USER}"
: "${BRIDGE_PASSWORD:?need BRIDGE_PASSWORD}"

A="${COUCHDB_URL/:\/\//://${COUCHDB_ADMIN_USER}:${COUCHDB_ADMIN_PASSWORD}@}"

echo "==> [1/3] bridge 읽기전용 계정 생성/갱신: ${BRIDGE_USER}"
curl -sf -X PUT "${A}/_users/org.couchdb.user:${BRIDGE_USER}" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"${BRIDGE_USER}\",\"password\":\"${BRIDGE_PASSWORD}\",\"roles\":[\"bridge_ro\"],\"type\":\"user\"}" \
  >/dev/null 2>&1 || {
    # 이미 존재하면 비밀번호 갱신 (rev 필요)
    REV=$(curl -sf "${A}/_users/org.couchdb.user:${BRIDGE_USER}" | sed -n 's/.*"_rev":"\([^"]*\)".*/\1/p')
    curl -sf -X PUT "${A}/_users/org.couchdb.user:${BRIDGE_USER}" \
      -H "Content-Type: application/json" -H "If-Match: ${REV}" \
      -d "{\"name\":\"${BRIDGE_USER}\",\"password\":\"${BRIDGE_PASSWORD}\",\"roles\":[\"bridge_ro\"],\"type\":\"user\"}" >/dev/null
  }
echo "    OK"

echo "==> [2/3] ${DB_NAME}._security 에 ${BRIDGE_USER} 읽기 권한 부여 (기존 멤버 보존)"
# ⚠️ 여기는 **병합**이다. 통째로 PUT 하면 안 된다 — `_security` 에는 `_rev` 가 없어
#   PUT 이 곧 전체 교체이고, 기존 members.names 가 그대로 사라진다.
#   구 판본이 정확히 그랬다: `"names":["${BRIDGE_USER}"]` 를 통째로 넣어, 나중에 추가된
#   계정(pabprove 등)을 **조용히 축출**했다. 에러도 안 나고 멱등해 보였다.
#   그리고 이 자리의 옛 주석은 "기존 정책 유지 + 추가"라고 **코드와 반대로** 적혀 있어,
#   주석을 믿고 읽으면 결함이 보이지 않았다. 병합 로직은 시험이 붙은 merge_security.py 에 있다.
CUR_SEC="$(curl -sf "${A}/${DB_NAME}/_security" 2>/dev/null || true)"
NEW_SEC="$(printf '%s' "${CUR_SEC}" | BRIDGE_USER="${BRIDGE_USER}" python3 "$(dirname "${BASH_SOURCE[0]}")/merge_security.py")" || {
  echo "ERROR: _security 병합 실패 — 기존 멤버를 잃을 수 있으므로 쓰지 않고 중단한다" >&2
  exit 1
}
curl -sf -X PUT "${A}/${DB_NAME}/_security" \
  -H "Content-Type: application/json" -d "${NEW_SEC}" >/dev/null
echo "    OK (members.names = $(printf '%s' "${NEW_SEC}" | python3 -c 'import json,sys;print(",".join(json.load(sys.stdin)["members"]["names"]))'))"

echo "==> [3/3] 쓰기차단 검증함수 design doc 설치 (_design/zz_bridge_readonly)"
# validate_doc_update: pabbridge 의 쓰기만 forbidden. 관리자/기타 사용자/LiveSync 는 그대로 허용.
# 최대한 보수적 — 정확히 BRIDGE_USER 이름일 때만 throw, 그 외엔 no-op(허용).
VFUN="function(newDoc, oldDoc, userCtx, secObj){ if (userCtx && userCtx.name === '${BRIDGE_USER}') { throw({forbidden: 'pab-vault-mirror is one-way (CouchDB->file). The bridge account is read-only.'}); } }"
DDOC_URL="${A}/${DB_NAME}/_design/zz_bridge_readonly"
EXIST_REV=$(curl -sf "${DDOC_URL}" 2>/dev/null | sed -n 's/.*"_rev":"\([^"]*\)".*/\1/p' || true)
if [ -n "${EXIST_REV}" ]; then
  curl -sf -X PUT "${DDOC_URL}" -H "Content-Type: application/json" -H "If-Match: ${EXIST_REV}" \
    -d "{\"_id\":\"_design/zz_bridge_readonly\",\"language\":\"javascript\",\"validate_doc_update\":\"${VFUN//\"/\\\"}\"}" >/dev/null
else
  curl -sf -X PUT "${DDOC_URL}" -H "Content-Type: application/json" \
    -d "{\"_id\":\"_design/zz_bridge_readonly\",\"language\":\"javascript\",\"validate_doc_update\":\"${VFUN//\"/\\\"}\"}" >/dev/null
fi
echo "    OK"

echo "==> 단방향 강제 설정 완료. (${BRIDGE_USER}=읽기전용, 쓰기 forbidden)"
