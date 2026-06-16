#!/usr/bin/env bash
#
# pab-vault-cloud 배포 스크립트 — Obsidian Self-hosted LiveSync용 CouchDB
# Phase 2-1 — backend-dev
#
# 동작:
#   1) 로컬 pab-vault-cloud/ (docker-compose.yml + local.d/ + .env) 를
#      서버 3800x:/home/oceanui/pab-vault-cloud/ 로 rsync 전송
#   2) 서버에서 docker compose up -d (멱등 — 재실행 안전)
#   3) curl -sf http://100.109.251.86:5984/_up 헬스 확인
#
# 사용: ./deploy.sh
#
# 주의:
#   - .env 는 서버 구동에 필요하므로 rsync에 포함한다 (git 에는 .gitignore 로 제외됨).
#   - 동기화 데이터(named volume pab_couchdb_data)는 건드리지 않는다.
set -euo pipefail

# --- 설정 ---
SSH_HOST="3800x"
REMOTE_DIR="/home/oceanui/pab-vault-cloud"
COUCHDB_URL="http://100.109.251.86:5984"
# 스크립트 위치 = 로컬 소스 디렉토리 (어디서 실행해도 동일하게 동작)
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> [1/3] rsync: ${LOCAL_DIR}/  ->  ${SSH_HOST}:${REMOTE_DIR}/"
ssh "${SSH_HOST}" "mkdir -p '${REMOTE_DIR}/local.d'"
# --delete: 로컬에서 제거된 설정파일을 서버에서도 정리 (멱등 일관성)
# 단, deploy.sh 자체는 서버에 굳이 둘 필요 없으나 전송돼도 무해. .git 류는 없음.
rsync -av --delete \
  --include='.env' \
  "${LOCAL_DIR}/" "${SSH_HOST}:${REMOTE_DIR}/"

echo "==> [2/3] docker compose up -d (멱등)"
ssh "${SSH_HOST}" "cd '${REMOTE_DIR}' && docker compose up -d"

echo "==> [3/3] 헬스 확인: ${COUCHDB_URL}/_up"
# CouchDB 기동/헬스체크 안정화까지 잠시 대기하며 재시도
ok=0
for i in $(seq 1 12); do
  if resp="$(ssh "${SSH_HOST}" "curl -sf '${COUCHDB_URL}/_up'" 2>/dev/null)"; then
    echo "    OK: ${resp}"
    ok=1
    break
  fi
  echo "    (${i}/12) _up 아직 미응답 — 5초 후 재시도"
  sleep 5
done

if [ "${ok}" -ne 1 ]; then
  echo "ERROR: ${COUCHDB_URL}/_up 헬스 확인 실패" >&2
  ssh "${SSH_HOST}" "docker ps --filter name=pab-couchdb --format '{{.Names}} | {{.Status}}'" >&2 || true
  exit 1
fi

echo "==> 배포 완료. CouchDB 정상 (${COUCHDB_URL})"
