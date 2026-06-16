# Phase 2-1 Todo List — 다기기 동기화 + 백업 인프라

상태: **DONE** (전 항목 완료)

## T-1: CouchDB 서비스 정의
- [x] `pab-vault-cloud/docker-compose.yml` 작성 (couchdb:3 single-node)
- [x] 포트 `100.109.251.86:5984` Tailnet 바인딩 (0.0.0.0 금지)
- [x] `.env`로 관리자 자격증명 분리 (COUCHDB_USER/PASSWORD)
- [x] `local.d/livesync.ini` — CORS + max sizes + require_valid_user
- [x] named volume 데이터 영속화

## T-2: deploy.sh + 서버 배포
- [x] `pab-vault-cloud/deploy.sh` 작성 (rsync + ssh + docker compose up -d)
- [x] 배포 후 `_up` 헬스 재시도 확인 로직
- [x] 3800X 서버 배포 (pab-couchdb healthy)
- [x] 시스템 DB(_users/_replicator/_global_changes) + pab-llmdata 생성

## T-3: 맥북 LiveSync 연결
- [x] Self-hosted LiveSync 플러그인 설치·설정
- [x] 접속정보 입력 + Test Connection 통과
- [x] 초기 업로드 (vault → CouchDB, .md 74개)
- [x] Team Lead 독립 검증 (서버 doc_count 일치)

## T-4: 레노버 연동 + 양방향 검증
- [x] 레노버 LiveSync 동일 접속정보 설정
- [x] Sync Method = LiveSync(실시간) 통일
- [x] 레노버 별도 노트(deepseek ×2) → 서버 push 확인
- [x] 서버 → 맥북 수신, .md 77개 3자 일치 (del 0, 충돌 0)

## T-5: per-machine 제외 정책
- [x] `.gitignore` Obsidian 패턴 `PAB-LLMDATA/.obsidian/` 경로 정정
- [x] community-plugins.json, plugins/ 무시 확인
- [x] 중복 항목 통합

## T-6: 백업 경로 확정
- [x] 데스크톱 git-authority 채택 (DP-1)
- [x] GitHub `ChoonghoRoh/PAB-obsidian` 오프사이트 백업 유지
- [x] LiveSync(동기화) vs GitHub(백업) 역할 분리 (R-1)

## 게이트
- [x] G2_infra PASS (7항목)
- [x] G3_smoke PASS (양방향 E2E)
- [x] G4 PASS
- [x] NOTIFY 발송 (`[PAB-LLMDATA]`)

## 잔여 (다음 세션/Phase)
- [ ] 자격증명 회전 (보안)
- [ ] 모바일(iPhone) 연동 (폰 online 시)
- [ ] graph.json/workspace.json git 추적 중단 검토 (현재 tracked, R-2 churn 가능성)
- [ ] 백업 cron 자동화 (Phase 2-3)
