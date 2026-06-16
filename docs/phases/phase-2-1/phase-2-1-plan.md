# Phase 2-1 Plan — 다기기 동기화 + 백업 인프라

- **master_plan**: [phase-2-master-plan.md §4 Phase 2-1](../phase-2-master-plan.md)
- **exceptions**: [phase-2-exceptions.md](../phase-2-exceptions.md) (E-1~E-4)
- **status**: DONE (PoC → 정식 편입 완료)

## 1. 목표

Self-hosted Obsidian LiveSync(CouchDB Docker)를 3800X에 배포하고, 전 기기(맥북/레노버/모바일) 실시간 양방향 동기화 + GitHub 오프사이트 백업 역할 분리를 확립한다.

## 2. 도구 결정 (확정)

| 항목 | 결정 | 근거 |
|---|---|---|
| 동기화 엔진 | **obsidian-livesync + CouchDB 3.x** | 실시간·모바일 네이티브·Markdown 충돌처리·셀프호스팅(데이터 주권)·Obsidian Sync($4/월) 정확 대체 |
| 노출 (DP-4) | **raw :5984 (Tailnet 바인딩)** | nginx TLS 불요 — 전 트래픽 Tailscale 사설망 내 |
| 백업 작성자 (DP-1) | **데스크톱 git-authority** | 단순. 서버 cron 미러는 추후 |
| 백업 위치 | GitHub `ChoonghoRoh/PAB-obsidian` | 기존 오프사이트 백업 유지 |

## 3. 아키텍처

```
[맥북 Obsidian] ──┐                          ┌── GitHub (오프사이트 백업, git push)
                  │                          │
       LiveSync ──┼──▶ [CouchDB :5984] ──────┘ (데스크톱 git-authority)
                  │     pab-couchdb
[레노버 Obsidian]─┘     (3800X, Tailnet)
                  │
[모바일 Obsidian]─┘  (Tailscale 가입 시)

역할 분리: LiveSync = 실시간 동기화 / GitHub = 백업 (R-1 쓰기 경로 단일화)
```

## 4. Task 구성 (T-1 ~ T-6)

| Task | 내용 | 담당 | 상태 |
|---|---|---|---|
| task-2-1-1 | CouchDB 서비스 정의 (docker-compose, CORS, require_valid_user, Tailnet 바인딩) | backend-dev | ✅ |
| task-2-1-2 | deploy.sh 작성 + 서버 배포 (rsync+ssh+compose) | backend-dev | ✅ |
| task-2-1-3 | 맥북 LiveSync 플러그인 연결 + 초기 업로드 (74개) | 사용자 + Team Lead 검증 | ✅ |
| task-2-1-4 | 레노버 연동 + 양방향 동기화 검증 (77개 일치) | 사용자 + Team Lead 검증 | ✅ |
| task-2-1-5 | per-machine 제외 정책 (.gitignore 경로 정정) | backend-dev | ✅ |
| task-2-1-6 | 백업 경로 확정 (GitHub git-authority) | Team Lead | ✅ |

## 5. 검증 (G2_infra + G3_smoke)

**G2_infra (Team Lead 독립 검증, HR-6)**
1. CouchDB welcome (v3.5.2) ✅
2. `_up` status ok ✅
3. 시스템 DB 4종 + pab-llmdata ✅
4. CORS Obsidian 권장값 ✅
5. 무인증 `/_all_dbs` → 401 (인증 강제) ✅
6. 바인딩 100.109.251.86:5984 (공개 노출 0) ✅
7. healthcheck healthy (require_valid_user_except_for_up) ✅

**G3_smoke (다기기 양방향 E2E)**
- 맥북 → 서버 초기 업로드 74개 ✅
- 레노버 → 서버 deepseek 노트 2개 push ✅
- 서버 → 맥북 수신, .md 77개 3자 일치, del 0, 충돌 0 ✅

## 6. 리스크 대응 (master-plan §7)

| # | 리스크 | 본 Phase 대응 |
|---|---|---|
| R-1 | CouchDB↔git 이중쓰기 충돌 | 데스크톱 git-authority로 쓰기 경로 단일화 |
| R-2 | workspace.json 동기화 churn | .gitignore `PAB-LLMDATA/.obsidian/` 경로 정정 (task-2-1-5) |

## 7. 잔여/인계

- 자격증명 회전(보안), 모바일 연동(폰 online 시), 백업 cron 자동화(Phase 2-3) — status.md 잔여 사항 참조.
