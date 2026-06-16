---
task: "2-1-1"
title: "CouchDB 서비스 정의 (docker-compose)"
domain: "[INFRA]"
assignee: backend-dev
status: completed
---

# Task 2-1-1: CouchDB 서비스 정의

## 목표
Obsidian LiveSync용 CouchDB 컨테이너를 docker-compose로 선언한다.

## 작업
- `pab-vault-cloud/docker-compose.yml` — `couchdb:3` single-node
- 포트 바인딩 `100.109.251.86:5984:5984` (Tailnet 전용, 공개 노출 금지)
- `.env` 분리: `COUCHDB_USER=pabadmin`, `COUCHDB_PASSWORD=<랜덤 32자>`
- `local.d/livesync.ini` 마운트(RW): `enable_cors=true`, cors origins `app://obsidian.md,capacitor://localhost,http://localhost`, `max_http_request_size=4294967296`, `max_document_size=50000000`, `require_valid_user=true`
- named volume으로 데이터 영속화
- healthcheck: `curl -f /_up` (+ require_valid_user_except_for_up=true 로 인증 면제 통과)

## 산출물
- `pab-vault-cloud/docker-compose.yml`, `.env`, `local.d/livesync.ini`

## 검증 (G2_infra)
- 컨테이너 healthy, welcome v3.5.2, 시스템 DB + pab-llmdata 생성

## 비고
- `:ro` 마운트 시 entrypoint chown 실패로 silent crash → ini는 RW 마운트 필수
- `[admins]`는 ini에 직접 넣지 않음(.env 주입), `_global_changes`는 수동 PUT
