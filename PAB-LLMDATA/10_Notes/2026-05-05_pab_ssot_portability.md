---
title: "PAB SSOT — 다른 프로젝트 이식 가이드 (Portability)"
description: "PAB SSOT를 다른 프로젝트에 이식하는 절차 — 복사 대상 파일, plugin.json 등록, deploy.sh, dist/autocycle-v1.1-portable.zip, ver 버전 호환성, git subtree, vault 운영 모드 결정"
created: 2026-05-05 05:13
updated: 2026-05-05 05:13
type: "[[REFERENCE]]"
index: "[[KNOWLEDGE_MGMT]]"
topics: ["[[PAB_SSOT]]", "[[PORTABILITY]]", "[[DEPLOYMENT]]"]
tags: [reference, pab-ssot-nexus, portability, deployment, ssot-adaptation]
keywords: ["plugin.json", "deploy.sh", "rsync", "Docker compose", "AutoCycle portable", "ver5-0/5-1/6-0", "git subtree", "ssot-core", "PAB plugin", "WIKI_VAULT_ROOT", "$VAULT_ROOT", "FRESH-1 호환"]
sources:
  - "~/WORKS/PAB-SSOT-Nexus/.claude-plugin/plugin.json"
  - "~/WORKS/PAB-SSOT-Nexus/pab-ssot/deploy.sh"
  - "~/WORKS/PAB-SSOT-Nexus/dist/"
  - "~/WORKS/PAB-SSOT-Nexus/ver{5-0,5-1,6-0}/"
aliases: ["SSOT 이식", "Portability", "다른 프로젝트 적용"]
---

# PAB SSOT — 다른 프로젝트 이식 가이드

> SSOT 본체와 11 skill을 다른 프로젝트에 적용하는 절차. **3가지 이식 단위** + **버전 호환성** + **운영 모드 결정**.

## 이식 3가지 단위

| 단위 | 대상 | 결과 |
|---|---|---|
| **A. SSOT 본체만** | `docs/SSOT/` 디렉토리 | 다른 프로젝트가 동일한 워크플로우·게이트·역할 정의를 사용 |
| **B. SSOT + skills** | A + `.claude-plugin/` + `skills/` | PAB plugin 활성화로 자동화 skill 11종 사용 가능 |
| **C. SSOT + skills + 운영 인프라** | B + `scripts/` + `deploy.sh` | Telegram 알림·DB 마이그레이션·서버 배포 포함한 풀 패키지 |

대부분의 경우 **B 단위 (SSOT + skills)** 이식이 표준.

## A. SSOT 본체만 이식

### 복사 대상

```
docs/SSOT/                          # 정본 디렉토리
├── implementation_plan.md          # 6세대 도입 구현 계획 (선택)
└── docs/
    ├── 0-entrypoint.md
    ├── 1-project.md                # ⚠️ 프로젝트별 수정 필요
    ├── 2-architecture.md           # ⚠️ 프로젝트별 수정 필요
    ├── 3-workflow.md
    ├── 4-event-protocol.md
    ├── 5-automation.md
    ├── GUIDE.md / VERSION.md / STRUCTURE.md
    ├── core/{6-rules-index, 7-shared-definitions}.md
    ├── SUB-SSOT/                   # 6 SUB-SSOT
    ├── PERSONA/                    # 9 페르소나
    ├── ROLES/                      # 9 역할 정의
    ├── QUALITY/10-persona-qc.md    # 11명 Council
    ├── TEMPLATES/                  # 11 템플릿
    ├── tests/                      # 시나리오 A~I (⚠️ 프로젝트별 재작성)
    ├── refactoring/                # REFACTOR 규칙 + 레지스트리
    └── infra/, mcp-design/         # 보조 디렉토리
```

### 프로젝트별 필수 수정 파일

| 파일 | 수정 내용 |
|---|---|
| **`1-project.md`** | 프로젝트명·서비스명·팀 구성·Phase 번호 갱신 (예: "Personal AI Brain v3" → 다른 프로젝트명) |
| **`2-architecture.md`** | 인프라 (Docker 컨테이너 포트·이미지) + 백엔드/프론트엔드 디렉토리 구조 갱신 |
| **`tests/index.md`** | 시나리오 A~I 재정의 (대상 프로젝트의 테스트 분류로) |
| **`refactoring/refactoring-registry.md`** | 빈 상태에서 시작 (대상 프로젝트의 500+ 파일 등록) |

### CLAUDE.md 진입점 설정

대상 프로젝트의 `.claude/CLAUDE.md`에 다음 추가:

```markdown
# SSOT 진입점

SSOT 버전: **v8.2-renewal-6th**
SSOT 경로: `docs/SSOT/docs/`

- **진입점**: `docs/SSOT/docs/0-entrypoint.md`
- **워크플로우**: `docs/SSOT/docs/3-workflow.md`
- **규칙 인덱스**: `docs/SSOT/docs/core/6-rules-index.md`
- **SUB-SSOT 인덱스**: `docs/SSOT/docs/SUB-SSOT/0-sub-ssot-index.md`

해당 파일들을 참조하여 Team Lead 역할로 동작한다. 코드 수정은 backend-dev/frontend-dev 팀원에게 위임한다 (HR-1).

# 절대 위반 금지 (HR-1~8)
[CLAUDE.md HR 5~8 규칙 복사 — 본 SSOT-Nexus의 CLAUDE.md 참조]
```

### 예외 등록 (E-1~E-N)

대상 프로젝트가 SSOT 일부 규칙을 비적용해야 한다면 **`docs/phases/phase-{N}-exceptions.md`** 작성. 본 SSOT 본체는 무수정 — 예외만 프로젝트 측에서 관리.

PAB-obsidian 사례 (Phase 1):
- E-1: G2_be/G2_fe → G2_wiki (코드 검증 → wiki 검증)
- E-2: HR-5 노트 400줄 한도
- E-3: NOTIFY prefix `[PAB-Wiki]`
- E-4: G3 pytest → wiki-validation, tester 비스폰
- E-5: 도메인 태그 `[WIKI-CONTENT]/[WIKI-INFRA]/[WIKI-CLI]/[WIKI-META]` 4종

## B. SSOT + skills 이식

### 복사 대상 (4개 + α)

```
1. .claude-plugin/plugin.json       # PAB plugin 등록 매니페스트
2. skills/                          # 11 skill 디렉토리
   ├── menu/
   ├── context-handoff/
   ├── ssot-reload/
   ├── phase-init/
   ├── plan/
   ├── notify-telegram/
   ├── worktree/
   ├── refactor-scan/
   ├── worklog/
   ├── report/
   └── wiki/                        # PAB-obsidian 정본 - vault 환경 필수
3. (A의 SSOT 본체 일체)
4. scripts/pmAuto/report_to_telegram.sh   # notify-telegram 의존
```

### plugin.json 예시

```json
{
  "name": "pab",
  "version": "0.1.0-poc",
  "description": "PAB-SSOT-Nexus operational harness — skills, validators, orchestrators",
  "author": {
    "name": "chroh",
    "email": "chroh1984@gmail.com"
  }
}
```

대상 프로젝트별로 `name`/`version`/`author` 수정 가능. PAB plugin 활성화 후 `/pab:menu`로 11 skill 확인.

### skill 의존성 점검

| skill | 외부 의존 | 대응 |
|---|---|---|
| `notify-telegram` | `scripts/pmAuto/report_to_telegram.sh` + `.env` (BOT_TOKEN/CHAT_ID) | scripts/ 함께 복사 + .env 별도 설정 |
| `worktree` | `git worktree` 명령 + (선택) `gh` CLI | git 1.5+ 필수, gh 설치 (`--gh-pr` 시) |
| `phase-init` | 대상 프로젝트의 `docs/phases/` 디렉토리 | 미생성 시 자동 생성 |
| `wiki` | **`$WIKI_VAULT_ROOT`** 환경변수 또는 `./wiki/` | vault 운영 모드 결정 (아래) |
| `ssot-reload` | `docs/SSOT/docs/0-entrypoint.md` 등 SSOT 본체 | A 이식 완료 후 동작 |
| 나머지 | Claude Code 내장 도구만 | — |

## C. SSOT + skills + 운영 인프라 이식

### deploy.sh 활용 (서버 배포)

PAB-SSOT-Nexus는 **3800x Tailscale 서버**에 Next.js 웹앱(`pab-ssot/`)을 배포하는 `deploy.sh`를 보유:

```bash
#!/bin/bash
SERVER="oceanui@100.109.251.86"
REMOTE_DIR="~/pab-ssot"

# 1. rsync 소스 전송 (.env 제외)
rsync -avz \
  --exclude='node_modules' --exclude='.next' --exclude='.DS_Store' \
  --exclude='.env' --exclude='.env.local' \
  ./ $SERVER:$REMOTE_DIR/

# 2. Docker compose 빌드 + 재시작
ssh $SERVER "cd $REMOTE_DIR && docker compose down && docker compose build --no-cache && docker compose up -d"

# 3. 헬스체크
ssh $SERVER "curl -s http://localhost:3100/api/health"
```

**시크릿 관리** (중요):
- `.env` 파일은 rsync에서 제외 (시크릿 노출 방지)
- 서버의 `~/pab-ssot/.env`는 별도 관리
- 시크릿 로테이션 시: 로컬 갱신 → `scp ./.env oceanui@100.109.251.86:~/pab-ssot/.env` → `./deploy.sh`

### dist/autocycle-v1.1-portable.zip

`dist/autocycle-v1.1-portable.zip` — AutoCycle v1.1 (Step 0 Pre-draft 포함) 포터블 배포 패키지. 다른 프로젝트가 SSOT 본체 없이도 AutoCycle만 빠르게 도입 가능.

### scripts/migrations/ (선택)

DB 마이그레이션 SQL/Python 스크립트. 대상 프로젝트의 DB 스키마와 무관하면 생략.

```
scripts/
├── pmAuto/report_to_telegram.sh        # B 이식 시 필수
└── migrations/                         # 선택 (DB 의존)
    ├── 001_add_gin_indexes.sql
    ├── 002_create_page_access_log.sql
    ├── 003_create_system_settings.sql
    ├── 004_create_users_table.sql
    └── _applied/                       # 1회성 백필 Python
```

## 버전 호환성 — ver5-0 / ver5-1 / ver6-0

PAB-SSOT-Nexus는 SSOT 자체의 진화 이력을 **버전 디렉토리**로 보존:

```
PAB-SSOT-Nexus/
├── ver5-0/   # 5세대 초기 (G0 + Research Team + Multi-perspective + Event/Automation)
├── ver5-1/   # 5세대 안정화
├── ver6-0/   # 6세대 (SUB-SSOT 모듈형 로딩 + AutoCycle v1.1) ← **현재 정본**
└── docs/SSOT/   # 작업 공간 (현행 버전, 보통 ver6-0 동기화)
```

| 버전 | ssot_version | 핵심 변경 |
|---|---|---|
| ver5-0 | 7.0-renewal-5th | 5세대 — RESEARCH·G0·Research Team·Multi-perspective·Event·Automation |
| ver5-1 | 7.0-renewal-5th | 5세대 안정화 |
| ver6-0 | **8.2-renewal-6th** | 6세대 — SUB-SSOT 모듈형 로딩 + AutoCycle v1.1 (Step 0 Pre-draft + ITER-PRE/POST + ITERATION-BUDGET 500K) |

**원칙**: 과거 버전 디렉토리는 **삭제하지 않고 보존** (롤백·히스토리 참조 가능). 새 프로젝트 이식 시 가장 최신 버전(`ver6-0/`)을 복사 권장.

### 5th → 6th 마이그레이션 (점진)

| 단계 | 작업 | 명령/방법 |
|---|---|---|
| 1 | ver6-0 폴더 배치 | `cp -r ver6-0/ {target}/docs/SSOT/` |
| 2 | 기존 phase-status.md ssot_version 갱신 | `sed -i 's/7.0-renewal-5th/8.2-renewal-6th/' docs/phases/*/phase-*-status.md` |
| 3 | CLAUDE.md SSOT 진입점 갱신 | ver6-0 경로로 변경 |
| 4 | 팀원 스폰 시 SUB-SSOT 경로 지시 추가 (선택) | 즉시 토큰 절감 |
| 5 | ssot-reload skill에 SUB-SSOT 옵션 추가 (선택) | 자동화 |

**하위 호환**: FRESH-1~9 기존 로딩 경로 그대로 동작. SUB-SSOT 로딩은 **opt-in** (기존 방식 대체 X). 20개 상태 머신·G0~G4·5th_mode 모두 동일.

## git subtree로 core 분리 (선택, 고급)

이식성 극대화를 위해 SSOT의 **`core/`만** 별도 리포지토리로 분리:

```
ssot-core/  (별도 리포지토리)
├── 6-rules-index.md
├── 7-shared-definitions.md
├── 3-workflow.md  (향후 이동)
├── 4-event-protocol.md  (향후 이동)
├── 5-automation.md  (향후 이동)
├── QUALITY/
└── TEMPLATES/
```

대상 프로젝트는:
```bash
git subtree add --prefix=docs/SSOT/core ssot-core main
git subtree pull --prefix=docs/SSOT/core ssot-core main      # 업데이트
```

상세는 [[2026-05-05_pab_ssot_subssot_misc|SUB-SSOT·기타 노트 §4]] 참조 (`infra/git-subtree-guide.md`).

## vault 운영 모드 결정 — wiki skill 한정

`/pab:wiki` skill은 두 가지 vault 운영 모드를 지원:

### 모드 A — 공통 vault (Karpathy 본래 의도, **권장**)

```bash
export WIKI_VAULT_ROOT="$HOME/Obsidian/PersonalKB"
```

→ 모든 프로젝트의 wiki 노트가 한 vault에 누적. 검색·연결 통합. 본 PAB-obsidian의 PAB-LLMDATA가 이 역할.

### 모드 B — 자기완결 모드 (예외 케이스)

환경변수 미설정 → 호출 프로젝트의 `./wiki/` 사용. PAB-obsidian dogfooding 등.

## CLAUDE.md HR-6/7/8 추가 (사용자 정의)

PAB-SSOT-Nexus의 SSOT는 HR-1~5만 정의. CLAUDE.md(프로젝트별)에서 다음 3 HR을 추가 정의 (PAB-obsidian 본 프로젝트 사례):

```markdown
## HR-6: Task 도메인-역할 할당 검증 (ASSIGN-1~5)
- 검증 작업은 반드시 tester·verifier·QC에게만 위임
- Team Lead가 3단계 통제 (스폰·할당·진행 중)

## HR-7: 에이전트 라이프사이클 엄격 관리 (LIFECYCLE-1~4)
- 5분 무보고 idle → 즉시 점검·종료
- 미사용 에이전트 즉시 shutdown_request

## HR-8: Phase 완료 시 Telegram 알림 필수 (NOTIFY-1~3)
- DONE 전이 시 scripts/pmAuto/report_to_telegram.sh 실행
- 알림 없이 DONE 전이는 무효
- 메시지 형식: [PROJECT-NAME] ✅ Phase {N}-{M} 완료: {요약}
```

## 이식 체크리스트

### A 단위 (SSOT 본체만)
- [ ] `docs/SSOT/` 복사
- [ ] `1-project.md` 프로젝트별 수정
- [ ] `2-architecture.md` 인프라 갱신
- [ ] `tests/index.md` 시나리오 재작성
- [ ] `CLAUDE.md`에 SSOT 진입점 등록
- [ ] (선택) `phase-{N}-exceptions.md` 작성

### B 단위 (SSOT + skills)
- [ ] A 완료
- [ ] `.claude-plugin/plugin.json` 복사 + name 수정
- [ ] `skills/` 11 디렉토리 복사
- [ ] `scripts/pmAuto/report_to_telegram.sh` 복사
- [ ] `.env`에 `BOT_TOKEN`/`CHAT_ID` 설정 (notify-telegram용)
- [ ] (wiki 사용 시) `WIKI_VAULT_ROOT` 환경변수 설정
- [ ] `/pab:menu` 호출하여 11 skill 활성 확인

### C 단위 (+ 운영 인프라)
- [ ] B 완료
- [ ] `deploy.sh` 복사 + SERVER/REMOTE_DIR 수정
- [ ] (DB 사용 시) `scripts/migrations/` 복사
- [ ] (Docker 사용 시) `docker-compose.yml` + `Dockerfile` 복사
- [ ] (포터블) `dist/autocycle-v1.1-portable.zip` 추출

## CLAUDE.md HR-6/7/8 등록 주의사항

| HR | 등록 시 검증 |
|---|---|
| HR-6 | ASSIGN-1~5 모두 status.md 진입 시 자동 검증 |
| HR-7 | LIFECYCLE-1 (5분 idle) 강제는 Team Lead 수동 점검 |
| HR-8 | NOTIFY-1 메시지 prefix를 대상 프로젝트명으로 변경 (`[PAB-SSOT-Nexus]` → `[다른 프로젝트]`) |

## 다음 노트

- [[2026-05-05_pab_ssot_intro|진입점·6세대]] — SSOT 본체 진입
- [[2026-05-05_pab_ssot_subssot_misc|SUB-SSOT·기타]] — git subtree 상세
- [[2026-05-05_pab_ssot_skills_catalog|skill 카탈로그]] — 이식 후 사용 가능한 11 skill
- [[2026-05-04_pab_ssot_nexus_overview|PAB-SSOT-Nexus 프로젝트 overview]] — 본 SSOT의 호스트
- [[PAB_SSOT_overview|MOC]]

## 참고

- `/PAB-SSOT-Nexus/.claude-plugin/plugin.json` — PAB plugin 매니페스트
- `/PAB-SSOT-Nexus/pab-ssot/deploy.sh` — 3800x 서버 배포 스크립트
- `/PAB-SSOT-Nexus/dist/autocycle-v1.1-portable.zip` — AutoCycle 포터블 패키지
- `/PAB-SSOT-Nexus/ver{5-0,5-1,6-0}/` — 버전 스냅샷
- `/PAB-SSOT-Nexus/docs/SSOT/docs/infra/git-subtree-guide.md` — Core 분리 가이드
