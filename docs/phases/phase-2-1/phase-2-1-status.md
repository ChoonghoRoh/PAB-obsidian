---
phase: "2-1"
title: "다기기 동기화 + 백업 인프라 (CouchDB LiveSync)"
team_name: "phase-2-1"
ssot_version: 8.0-renewal-6th
created: 2026-06-16
updated: 2026-06-16
current_state: DONE
exceptions: [E-1, E-2, E-3, E-4]
exceptions_ref: docs/phases/phase-2-exceptions.md
master_plan_ref: docs/phases/phase-2-master-plan.md
notify_prefix: "[PAB-LLMDATA]"
gate_results:
  G0: SKIP       # research = false (도구 선택은 master-plan §4에서 확정: LiveSync+CouchDB)
  G1: PASS       # master-plan §4 Phase 2-1 정의가 G1 역할 수행
  G2_infra: PASS # Team Lead 독립 검증 7항목 PASS (E-1)
  G3_smoke: PASS # 다기기 양방향 동기화 E2E 확인 (E-3)
  G4: PASS       # G2_infra PASS + G3_smoke PASS 조합으로 PASS
blockers: []
domain_tags_in_use: [INFRA]
roles:
  team_lead: main
  backend_dev: completed   # T-1~T-6 구현·배포, deploy.sh + .gitignore 정정
  verifier: not_spawned    # Team Lead 직접 독립 검증 (HR-6 독립성 유지)
  tester: not_spawned      # E-3 (G3_smoke 대체)
  frontend_dev: not_spawned
sub_phase_artifacts:
  status: docs/phases/phase-2-1/phase-2-1-status.md
  plan: docs/phases/phase-2-1/phase-2-1-plan.md
  todo_list: docs/phases/phase-2-1/phase-2-1-todo-list.md
  tasks_dir: docs/phases/phase-2-1/tasks/
  tasks:
    - tasks/task-2-1-1.md  # CouchDB 서비스 정의 (docker-compose)
    - tasks/task-2-1-2.md  # deploy.sh 타겟 + 서버 배포
    - tasks/task-2-1-3.md  # 데스크톱(맥북) LiveSync 플러그인 연결
    - tasks/task-2-1-4.md  # 다기기(레노버) 연동 + 양방향 검증
    - tasks/task-2-1-5.md  # per-machine 제외 정책 (.gitignore 정정)
    - tasks/task-2-1-6.md  # 백업 경로 확정 (GitHub 오프사이트)
5th_mode:
  research: false
  event: true
  automation: true
  branch: false            # PoC → 정식 편입, main에서 진행 (인프라 신규 디렉토리, 충돌 위험 낮음)
  multi_perspective: false
ssot_loaded_at: 2026-06-16T00:00:00
deployment:
  server: "3800x (100.109.251.86, Tailnet)"
  container: "pab-couchdb (couchdb:3.5.2, healthy)"
  endpoint: "http://100.109.251.86:5984"
  database: "pab-llmdata"
  data_volume: "named volume (sync data)"
  exposure: "Tailnet 전용 (100.109.251.86:5984 바인딩, 공개 0.0.0.0 노출 없음)"
verification_summary:
  couchdb_health: "healthy (require_valid_user_except_for_up=true 로 /_up 헬스체크 통과)"
  auth_enforced: "무인증 /_all_dbs → HTTP 401 (보안 OK)"
  two_way_sync: "맥북↔서버↔레노버 .md 77개 일치, del 0, 충돌 0"
  per_machine_excluded: ".gitignore PAB-LLMDATA/.obsidian/ 경로 정정 → workspace/plugins/community-plugins 비추적"
  github_backup: "ChoonghoRoh/PAB-obsidian — 데스크톱 git-authority (DP-1)"
next_prompt_suggestion: |
  Phase 2-2 (쿼리 가능한 RAG / MCP 지식베이스)을 시작한다. 이전 Phase 산출물:
  - pab-vault-cloud/docker-compose.yml (couchdb 서비스, healthy)
  - pab-vault-cloud/deploy.sh (rsync+ssh+compose 배포 스크립트)
  - pab-vault-cloud/local.d/livesync.ini (CORS + LiveSync 튜닝 + require_valid_user_except_for_up)
  - 다기기 LiveSync 동기화 가동 (맥북/레노버), GitHub 백업 유지
  - .gitignore per-machine 제외 정책 정정 완료

  진입 절차:
  1. FRESH-1: SSOT 0~3 리로드
  2. ENTRY-1: docs/phases/phase-2-2/phase-2-2-status.md 읽기 (없으면 phase-init)
  3. 컨텍스트: master-plan §4 Phase 2-2, exceptions E-1~E-4 로드
  4. TEAM_SETUP: backend-dev(인프라/MCP) + verifier 스폰
  5. T-1~T-6: Qdrant+pab-kb-mcp, 인덱서, MCP 도구 3종, stateless 엔드포인트, bge-m3, .mcp.json
last_phase_completed_at: 2026-06-16
---

# Phase 2-1 Status — 다기기 동기화 + 백업 인프라

본 파일이 **단일 진입점**(ENTRY-1). `current_state` = **DONE**.

## 현재 상태: DONE

Self-hosted Obsidian LiveSync(CouchDB 3.5.2)를 3800X에 배포하고, 맥북·레노버 간 실시간 양방향 동기화 + GitHub 오프사이트 백업 역할 분리를 확립했다. PoC로 시작하여 정식 편입(deploy.sh, Phase 산출물, .gitignore 정비)까지 완료.

## 게이트 판정

- **G0 SKIP** — research 불요(도구 master-plan에서 확정)
- **G1 PASS** — master-plan §4 Phase 2-1 정의
- **G2_infra PASS** — Team Lead 독립 검증 7항목(헬스/welcome/_up/_all_dbs/CORS/401/바인딩) 전부 PASS
- **G3_smoke PASS** — 다기기 양방향 동기화 E2E(.md 77개 3자 일치, deepseek 노트 레노버→서버→맥북 전파 확인)
- **G4 PASS** — G2_infra + G3_smoke 조합

## 종료 조건 (충족)

- [x] T-1 ~ T-6 completed
- [x] G2_infra PASS (인프라·보안 검증)
- [x] G3_smoke PASS (양방향 동기화 E2E)
- [x] deploy.sh + Phase 산출물 4종 작성
- [x] NOTIFY 발송 (`[PAB-LLMDATA] ✅ Phase 2-1 완료`)
- [x] next_prompt_suggestion 갱신 → Phase 2-2 진입

## 잔여/인계 사항

- **보안**: PoC용 CouchDB 비밀번호가 세션 대화에 평문 노출됨 → 정식 운영 전 **자격증명 회전 권장**.
- **모바일(T-4 폰)**: iPhone Tailscale offline 상태로 연동 미검증. 폰 온라인 시 동일 접속정보로 연동.
- **백업 자동화(DP-1)**: 현재 데스크톱 git-authority(수동 커밋). 무인 cron 미러는 Phase 2-3 자동화와 함께 검토.
