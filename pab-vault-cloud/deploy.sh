#!/usr/bin/env bash
#
# pab-vault-cloud 배포 스크립트
#   - CouchDB (Obsidian Self-hosted LiveSync 백엔드)
#   - livesync-bridge (CouchDB pab-llmdata -> 호스트 파일시스템 단방향 .md 미러, 방법 A)
# Phase 2-1 — backend-dev
#
# 동작:
#   1) 로컬 pab-vault-cloud/ 를 서버로 rsync (.env / bridge.env 포함, config.json 렌더링)
#   2) 서버에서 livesync-bridge 공식 소스 클론(recursive, 멱등) → ./livesync-bridge/src
#   3) bridge config.json 렌더링 (template + bridge.env)
#   4) 미러 출력 디렉토리(/home/oceanui/pab-vault-mirror) 생성
#   5) CouchDB 단방향 강제 설정 (읽기전용 계정 + validate_doc_update)
#   6) docker compose up -d --build (멱등)
#   7) CouchDB _up + bridge 컨테이너 + 미러 파일 헬스 확인
#
# 사용: ./deploy.sh
#
# 주의:
#   - .env / bridge.env 는 서버 구동에 필요 → rsync 포함 (git 에는 .gitignore 로 제외).
#   - 동기화 데이터(named volume pab_couchdb_data)와 미러는 단방향만 — 절대 역방향 쓰기 없음.
set -euo pipefail

# --- 설정 ---
SSH_HOST="3800x"
REMOTE_DIR="/home/oceanui/pab-vault-cloud"
MIRROR_DIR="/home/oceanui/pab-vault-mirror"
COUCHDB_URL="http://100.109.251.86:5984"
DB_NAME="pab-llmdata"
BRIDGE_REPO="https://github.com/vrtmrz/livesync-bridge"
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> [1/7] rsync: ${LOCAL_DIR}/  ->  ${SSH_HOST}:${REMOTE_DIR}/"
ssh "${SSH_HOST}" "mkdir -p '${REMOTE_DIR}/local.d' '${REMOTE_DIR}/livesync-bridge'"
# --delete 로 멱등 일관성. 단 서버에서만 존재하는 산출물(클론 소스/렌더링 config)은 보존.
rsync -av --delete \
  --include='.env' \
  --exclude='livesync-bridge/src/' \
  --exclude='livesync-bridge/config.json' \
  "${LOCAL_DIR}/" "${SSH_HOST}:${REMOTE_DIR}/"

echo "==> [2/7] livesync-bridge 공식 소스 클론/갱신 (recursive, 멱등)"
ssh "${SSH_HOST}" "
  set -e
  cd '${REMOTE_DIR}/livesync-bridge'
  if [ -d src/.git ]; then
    # 단방향 패치(Hub.ts)로 working tree 가 dirty 하므로 reset 후 pull (멱등)
    cd src && git checkout -- . && git pull --recurse-submodules --ff-only && git submodule update --init --recursive
  else
    rm -rf src
    git clone --recursive '${BRIDGE_REPO}' src
  fi
"

echo "==> [3/7] 패치 적용(Dockerfile, Hub 단방향) + config.json 렌더링"
# (a) 업스트림 Dockerfile 의 deno install -A 버그 회피용 패치를 빌드 컨텍스트로 복사
ssh "${SSH_HOST}" "cp '${REMOTE_DIR}/livesync-bridge/Dockerfile.patched' '${REMOTE_DIR}/livesync-bridge/src/Dockerfile.patched'"
# (b) 단방향 강제 패치: storage->couchdb 역전파 차단 (Hub.ts 교체)
#     bridge 네이티브 one-way 옵션 부재 → 역전파 시 forbidden uncaught error 로 크래시.
#     dispatch 단계에서 차단해 엄격 단방향(CouchDB->파일) 보장 + 크래시 방지.
ssh "${SSH_HOST}" "cp '${REMOTE_DIR}/livesync-bridge/Hub.patched.ts' '${REMOTE_DIR}/livesync-bridge/src/Hub.ts'"
# config.json 렌더링 (template + bridge.env)
ssh "${SSH_HOST}" "
  set -euo pipefail
  cd '${REMOTE_DIR}/livesync-bridge'
  set -a; . ./bridge.env; set +a
  sed -e \"s|__BRIDGE_USER__|\${BRIDGE_USER}|g\" \
      -e \"s|__BRIDGE_PASSWORD__|\${BRIDGE_PASSWORD}|g\" \
      config.json.template > config.json
  echo '    config.json 렌더링 완료'
"

echo "==> [4/7] 미러 출력 디렉토리 생성: ${MIRROR_DIR}"
ssh "${SSH_HOST}" "mkdir -p '${MIRROR_DIR}'"

echo "==> [5/7] CouchDB 단방향 강제 설정 (읽기전용 계정 + 쓰기차단)"
# CouchDB 가 떠 있어야 하므로, 먼저 couchdb 만 기동/확인
ssh "${SSH_HOST}" "cd '${REMOTE_DIR}' && docker compose up -d couchdb"
ok=0
for i in $(seq 1 12); do
  if ssh "${SSH_HOST}" "curl -sf '${COUCHDB_URL}/_up'" >/dev/null 2>&1; then ok=1; break; fi
  echo "    (${i}/12) CouchDB _up 대기 — 5초 후 재시도"; sleep 5
done
[ "${ok}" -eq 1 ] || { echo "ERROR: CouchDB 미기동" >&2; exit 1; }
ssh "${SSH_HOST}" "
  set -euo pipefail
  cd '${REMOTE_DIR}'
  set -a; . ./.env; . ./livesync-bridge/bridge.env; set +a
  COUCHDB_URL='${COUCHDB_URL}' DB_NAME='${DB_NAME}' \
  COUCHDB_ADMIN_USER=\"\${COUCHDB_USER}\" COUCHDB_ADMIN_PASSWORD=\"\${COUCHDB_PASSWORD}\" \
  BRIDGE_USER=\"\${BRIDGE_USER}\" BRIDGE_PASSWORD=\"\${BRIDGE_PASSWORD}\" \
  bash ./livesync-bridge/setup-readonly-account.sh
"

echo "==> [6/7] docker compose up -d --build (couchdb + livesync-bridge)"
ssh "${SSH_HOST}" "cd '${REMOTE_DIR}' && docker compose up -d --build"

echo "==> [7/7] 헬스 확인"
# CouchDB
resp="$(ssh "${SSH_HOST}" "curl -sf '${COUCHDB_URL}/_up'" 2>/dev/null || true)"
echo "    CouchDB _up: ${resp:-<no response>}"
# bridge 컨테이너
echo "    bridge 컨테이너:"
ssh "${SSH_HOST}" "docker ps --filter name=pab-livesync-bridge --format '      {{.Names}} | {{.Status}}'"
# 미러 파일 (최대 60초 대기 — 초기 풀 동기화)
echo "    미러 .md 파일 대기 (최대 60초)..."
mirror_ok=0
for i in $(seq 1 12); do
  cnt="$(ssh "${SSH_HOST}" "find '${MIRROR_DIR}' -name '*.md' -type f 2>/dev/null | wc -l" | tr -d ' ')"
  if [ "${cnt:-0}" -gt 0 ]; then
    echo "      미러 .md 파일 수: ${cnt}"
    mirror_ok=1
    break
  fi
  echo "      (${i}/12) 아직 0개 — 5초 후 재확인"; sleep 5
done
if [ "${mirror_ok}" -ne 1 ]; then
  echo "WARN: 미러에 .md 파일이 아직 없음. bridge 로그 확인:" >&2
  ssh "${SSH_HOST}" "docker logs --tail 40 pab-livesync-bridge" >&2 || true
  exit 1
fi

echo "==> 배포 완료. CouchDB + livesync-bridge 단방향 미러 정상 (${MIRROR_DIR})"
