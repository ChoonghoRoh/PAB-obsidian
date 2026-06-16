---
task: "2-1-2"
title: "deploy.sh 작성 + 서버 배포"
domain: "[INFRA]"
assignee: backend-dev
status: completed
---

# Task 2-1-2: deploy.sh + 서버 배포

## 목표
재현 가능한 배포 스크립트로 pab-vault-cloud 스택을 3800X에 배포한다.

## 작업
- `pab-vault-cloud/deploy.sh` 신규 (`set -euo pipefail`, 실행권한)
- [1/3] rsync `-av --delete --include='.env'` → `3800x:/home/oceanui/pab-vault-cloud/`
- [2/3] `ssh 3800x 'cd ... && docker compose up -d'` (멱등)
- [3/3] `curl -sf /_up` 5초×12회 재시도 헬스 확인, 실패 시 비0 종료
- `.env`는 rsync 포함(서버 구동 필요), git은 `.gitignore`로 제외

## 산출물
- `pab-vault-cloud/deploy.sh`

## 검증 (G2_infra)
- `bash -n` 구문검사 통과, 서버 pab-couchdb Up(healthy), `/_up` ok
