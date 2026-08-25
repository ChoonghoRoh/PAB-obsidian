# Git Worktree 운영 가이드 — ver6-0

> **작성일**: 2026-04-18
> **대상 SSOT**: ver6-0 (v8.3-renewal-6th, Phase-J 신설)
> **저장소**: `PAB-SSOT-Nexus` (실제 리포지토리명, 경로 예시 전반에서 일관 사용)
> **위치**: `ver6-0/docs/infra/git-worktree-guide.md`
> **역할**: ver6-0의 **worktree 단일 정본 가이드(Hub)**. 상태 머신(`3-workflow.md §3, §6.6`),
>   병렬 처리 정책(`1-project.md §7.3`), 규칙 인덱스(`core/6-rules-index.md` WT 카테고리),
>   SUB-SSOT(TEAM-LEAD, DEV)는 모두 본 문서를 **참조 대상**으로 한다.
> **선행 근거**: `docs/phases/pre/git-worktree-integration-guide.md` (Pre-draft §3 신규 파일 뼈대)
>   / `docs/phases/pre/phase-J-pre-analysis.md` (CI 범위 Phase-K 분리 결정)

---

## 1. 개요

### 1.1 도입 배경

ver6-0의 병렬 처리 정책(`1-project.md §7.3`)은 "수정 파일 집합 교집합 ∅" 조건만으로 병렬을 허용한다.
이 조건은 **파일 경로 충돌**은 막아주지만, 다음 3가지 **공유 작업 디렉토리 부작용**은 막지 못한다.

1. **`git checkout` 경합** — 두 에이전트가 같은 작업 트리에서 서로 다른 브랜치를 체크아웃하며 상태를 덮어쓴다.
2. **빌드 산출물 오염** — `node_modules/`, `.venv/`, `__pycache__/`, `dist/`, `.next/` 등이 브랜치별로 다르게 빌드되어야 하지만 한 디렉토리에서 섞인다.
3. **`git stash` / index 오염** — 한 에이전트의 stash·staged 변경을 다른 에이전트가 의식하지 못한 채 commit 한다.

`git worktree` 는 동일 `.git` 저장소를 공유하면서 **브랜치별로 독립된 작업 디렉토리**를 만든다.
따라서 위 3가지를 동시에 해소한다. 이로써 ver6-0의 "병렬 트랙 ≥ 2" 조건이 **이론적 허용**에서 **실제 안전한 실행**으로 격상된다.

### 1.2 적용 범위

| 항목 | 적용 |
|------|------|
| 단일 트랙 Phase (N=1) | **선택** — 메인 clone에서 작업 가능. worktree 권장하지 않음 |
| 병렬 트랙 Phase (N≥2) | **필수** (WT-1) — worktree 없이 병렬 BUILDING 진입 금지 |
| A/B 분기 (`§3-workflow §6.4`) | **필수** — branch-A / branch-B 각각 worktree 격리 |
| REWINDING (`§3-workflow §6.3`) | **필수** — 실패 worktree 보존 + retry-N worktree 추가 생성 |
| `_backup/`, `ab-test/`, `ssot-template/`, `pab-ssot/` 영역 | **금지** — 감사 결정에 따라 worktree 운영 대상에서 제외 |

### 1.3 본 가이드의 위치

본 가이드는 **허브 문서**다. 다른 SSOT 파일은 본 문서를 **참조**하며, 동일 내용을 중복 기술하지 않는다.

- 상태 머신 본문: `docs/3-workflow.md §3 (BRANCH_CREATION → WORKTREE_SETUP), §6.6 (WT-1~5)` ← 본 가이드를 인용
- 병렬 정책: `docs/1-project.md §7.3` ← 본 가이드를 인용
- 규칙 인덱스: `docs/core/6-rules-index.md` WT 카테고리 ← 본 가이드를 인용
- Team Lead 절차: `docs/SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md` ← 본 가이드 §5를 인용
- DEV 절차: `docs/SUB-SSOT/DEV/0-dev-entrypoint.md` ← 본 가이드 §5의 CWD 주입 규칙을 인용

---

## 2. 디렉토리 규약 (`./../{repo}-wt-phase-{X}-{Y}-{track}/`)

### 2.1 위치 전략 — 저장소 옆 배치 (Pre-draft §2 결정 (b))

worktree 디렉토리는 **메인 저장소와 같은 부모 디렉토리, 형제 위치**에 배치한다.

```
~/WORKS/
├── PAB-SSOT-Nexus/                              ← 메인 clone (origin)
├── PAB-SSOT-Nexus-wt-phase-27-1/                ← 단일 Phase worktree
├── PAB-SSOT-Nexus-wt-phase-27-2-be/             ← 병렬 BE 트랙
├── PAB-SSOT-Nexus-wt-phase-27-2-fe/             ← 병렬 FE 트랙
├── PAB-SSOT-Nexus-wt-phase-27-3-ab-A/           ← A/B A안
├── PAB-SSOT-Nexus-wt-phase-27-3-ab-B/           ← A/B B안
└── PAB-SSOT-Nexus-wt-phase-27-1-retry-1/        ← REWINDING 1차
```

**선택지 비교 요약** (Pre-draft §2 표 참조):

| 후보 | 채택 여부 | 사유 |
|------|----------|------|
| (a) 저장소 내부 `./.worktrees/` | **불채택** | gitignore 누락 시 재귀 노출, IDE 인덱서가 메인 트리와 worktree를 같은 프로젝트로 오인 |
| (b) **저장소 옆 `../{repo}-wt-...`** | **채택** | 같은 파일시스템·같은 부모로 빌드 캐시 분리 강제, IDE에서 별도 프로젝트로 인식 |
| (c) 사용자 홈 `~/worktrees/` | **불채택** | Tailscale 다중 노드에서 절대 경로 불일치 |

### 2.2 네이밍 표준 (4 케이스)

| 상황 | 경로 템플릿 | 예시 (실제 repo `PAB-SSOT-Nexus`) |
|------|-------------|----------------------------------|
| 단일 Phase | `../PAB-SSOT-Nexus-wt-phase-{X}-{Y}/` | `../PAB-SSOT-Nexus-wt-phase-27-1/` |
| 병렬 BE/FE | `../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-{track}/` (track ∈ `be`,`fe`,`ver`) | `../PAB-SSOT-Nexus-wt-phase-27-2-be/` , `../PAB-SSOT-Nexus-wt-phase-27-2-fe/` |
| A/B 분기 | `../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-ab-{A,B}/` | `../PAB-SSOT-Nexus-wt-phase-27-3-ab-A/` , `../PAB-SSOT-Nexus-wt-phase-27-3-ab-B/` |
| REWINDING | `../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-retry-{N}/` | `../PAB-SSOT-Nexus-wt-phase-27-1-retry-1/` |

> **placeholder 규칙**: `{X}`(메이저), `{Y}`(서브), `{track}`(트랙명), `{N}`(retry 회차) 만 placeholder로 허용.
> repo 이름은 **항상 실제 값** `PAB-SSOT-Nexus` 로 적는다. `{repo}` 변수 사용은 본 §2 설명문 한정.

### 2.3 브랜치-worktree 매핑 원칙

- 1 worktree = 1 브랜치 (CK-1)
- 브랜치명과 디렉토리 suffix는 **일치**시킨다.
  - 브랜치 `phase-27-2-be` ↔ 디렉토리 `../PAB-SSOT-Nexus-wt-phase-27-2-be/`
  - A/B는 브랜치 `phase-27-3-branch-A` ↔ 디렉토리 `...-ab-A`(suffix 단축 허용, 단 status.md `worktree_paths` 매핑 명시)
- worktree 내부에서 `git checkout` 으로 브랜치를 변경하지 않는다. 브랜치 전환이 필요하면 worktree를 새로 만든다.

---

## 3. 생성·삭제 커맨드 (`add` / `remove` / `prune` / `list`)

### 3.1 핵심 커맨드 시트

```bash
# [add] 단일 Phase 생성 — Phase BRANCH_CREATION 상태 전이 시 실행
git worktree add ../PAB-SSOT-Nexus-wt-phase-27-1 phase-27-1

# [add] 병렬 BE/FE 트랙 생성 — WORKTREE_SETUP 진입 시
git worktree add ../PAB-SSOT-Nexus-wt-phase-27-2-be phase-27-2-be
git worktree add ../PAB-SSOT-Nexus-wt-phase-27-2-fe phase-27-2-fe

# [add] A/B 분기 — 3-workflow.md §6.4 와 연계
git worktree add ../PAB-SSOT-Nexus-wt-phase-27-3-ab-A phase-27-3-branch-A
git worktree add ../PAB-SSOT-Nexus-wt-phase-27-3-ab-B phase-27-3-branch-B

# [add] REWINDING — 실패 worktree 보존, retry-N 추가 (3-workflow.md §6.3)
git worktree add ../PAB-SSOT-Nexus-wt-phase-27-1-retry-1 phase-27-1-retry-1

# [list] 현황 확인 — Team Lead 컨텍스트 복구·orphan 점검 시 필수
git worktree list
git worktree list --porcelain    # 스크립트 처리용

# [remove] Phase Chain 완료 후 정리
git worktree remove ../PAB-SSOT-Nexus-wt-phase-27-1
git worktree remove ../PAB-SSOT-Nexus-wt-phase-27-2-be
git worktree remove ../PAB-SSOT-Nexus-wt-phase-27-2-fe

# [prune] 비정상 종료 후 메타데이터 정리
git worktree prune
git worktree prune --verbose --dry-run   # 사전 확인
```

### 3.2 안전 삭제 절차 (cleanup 전 안전장치)

```bash
# 1. 미커밋 변경 검사 (있으면 중단)
( cd ../PAB-SSOT-Nexus-wt-phase-27-1 && git status --porcelain )

# 2. unpushed 커밋 검사
( cd ../PAB-SSOT-Nexus-wt-phase-27-1 && git log @{u}..HEAD --oneline 2>/dev/null )

# 3. 둘 다 비어 있으면 remove
git worktree remove ../PAB-SSOT-Nexus-wt-phase-27-1

# 4. 메타데이터 prune
git worktree prune
```

> **금지**: `--force` 플래그는 미커밋 변경을 무시하고 삭제하므로 데이터 손실 위험. CK-4 위반.
> 강제 삭제가 정말 필요하면 사용자 승인 + 대상 변경 사항 별도 백업(`git diff > /tmp/wt-backup.patch`) 후 사용.

### 3.3 의존성 설치 (worktree별 독립)

각 worktree는 자체 `node_modules/`, `.venv/`, `__pycache__/` 를 가져야 한다 (CK-3).

```bash
# 신규 worktree 진입 직후
cd ../PAB-SSOT-Nexus-wt-phase-27-2-be
npm ci                  # Node 프로젝트
# 또는
python -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt
```

---

## 4. 수명 주기 (Phase BRANCH_CREATION → Chain 완료 → 일괄 제거)

### 4.1 상태 전이 다이어그램

```
TASK_SPEC
   ↓ (5th_mode.branch == true)
BRANCH_CREATION  ── git checkout -b phase-{X}-{Y}
   ↓ (병렬 트랙 N 판정)
   ├── N == 1 → BUILDING (메인 clone에서 작업, worktree 선택)
   └── N ≥ 2 → WORKTREE_SETUP (필수, WT-1)
                  ↓ git worktree add ... × N
                  ↓ 의존성 설치 × N
                  ↓ phase-{X}-{Y}-status.md  worktree_paths: [...]
                  ↓
              BUILDING (각 worktree에서 병렬 진행)
                  ↓
              TESTING / VERIFYING / DONE
                  ↓
        Phase Chain 완료 시점
                  ↓
        WORKTREE_CLEANUP — git worktree remove × N + git worktree prune
                  ↓
        phase-{X}-{Y}-status.md  cleanup_wt: done
                  ↓
        NOTIFY-1 (Telegram, "worktrees cleaned: N" 포함)
```

### 4.2 worktree 가 추가하는 상태 머신 단계 (요약)

| 단계 | 트리거 | 산출물 |
|------|--------|--------|
| WORKTREE_SETUP | BRANCH_CREATION 후 N≥2 | worktree 디렉토리 N개 + status.md `worktree_paths` |
| (BUILDING 중) CWD 주입 | Team Lead → 팀원 SendMessage | 본문 상단 `[CWD] ../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-{track}` |
| WORKTREE_CLEANUP | Chain 완료 (CHAIN-5 1줄 요약 후) | `worktree remove` + `prune` 로그 + status.md `cleanup_wt: done` |

> 상세 상태 머신 본문은 `docs/3-workflow.md §3` 의 WORKTREE_SETUP 절을 참조.

### 4.3 status.md 필수 필드 (WT-5)

`docs/phases/phase-{X}-{Y}/phase-{X}-{Y}-status.md` YAML 헤더에 다음 2개 필드를 **필수** 기록한다.

```yaml
worktree_paths:
  - ../PAB-SSOT-Nexus-wt-phase-27-2-be
  - ../PAB-SSOT-Nexus-wt-phase-27-2-fe
cleanup_wt: pending     # pending | done
```

Chain 완료 후 cleanup 완료 시 `cleanup_wt: done` 으로 갱신.

---

## 5. 병렬 실행 시나리오 (backend-dev / frontend-dev 동시 스폰)

### 5.1 시나리오 — Phase 27-2 BE/FE 병렬

**전제**: Master Plan에서 27-2가 `[BE]` Task 3건 + `[FE]` Task 2건으로 구성. 트랙 수 N=2.

```
Step 1. Team Lead — BRANCH_CREATION
  $ git checkout main
  $ git checkout -b phase-27-2-be
  $ git checkout main
  $ git checkout -b phase-27-2-fe

Step 2. Team Lead — WORKTREE_SETUP (병렬 N≥2 트리거)
  $ git worktree add ../PAB-SSOT-Nexus-wt-phase-27-2-be phase-27-2-be
  $ git worktree add ../PAB-SSOT-Nexus-wt-phase-27-2-fe phase-27-2-fe
  $ ( cd ../PAB-SSOT-Nexus-wt-phase-27-2-be && npm ci )
  $ ( cd ../PAB-SSOT-Nexus-wt-phase-27-2-fe && npm ci )

Step 3. Team Lead — status.md 갱신
  worktree_paths:
    - ../PAB-SSOT-Nexus-wt-phase-27-2-be
    - ../PAB-SSOT-Nexus-wt-phase-27-2-fe
  cleanup_wt: pending

Step 4. Team Lead — TeamCreate + 팀원 스폰 (CWD 주입)
  · backend-dev 스폰 SendMessage 본문 첫 줄:
      [CWD] ../PAB-SSOT-Nexus-wt-phase-27-2-be
  · frontend-dev 스폰 SendMessage 본문 첫 줄:
      [CWD] ../PAB-SSOT-Nexus-wt-phase-27-2-fe

Step 5. 팀원 — DEV FRESH 체크리스트 FRESH-1.5
  · pwd 결과가 [CWD] 와 일치하는지 검증
  · 불일치 시 즉시 [BLOCKER] 보고 (WT-3 위반)

Step 6. BUILDING — 각 worktree에서 병렬 편집·빌드·테스트
  · BE: ../PAB-SSOT-Nexus-wt-phase-27-2-be 내부에서만 작업
  · FE: ../PAB-SSOT-Nexus-wt-phase-27-2-fe 내부에서만 작업

Step 7. DONE 후 Chain 완료 → WORKTREE_CLEANUP (§4.1 수명 주기 다이어그램)
```

### 5.2 CWD 주입 흐름 — Team Lead → 팀원

```
Team Lead 메시지 텍스트 예시 (SendMessage 본문):

  [CWD] ../PAB-SSOT-Nexus-wt-phase-27-2-be
  [Phase] 27-2
  [Role] backend-dev
  [Task] 27-2-1, 27-2-2, 27-2-3

  ## 작업 지시
  ...
```

팀원은 첫 줄의 `[CWD]` 를 읽고 모든 bash 명령에 절대 경로를 사용하거나 `cd` 로 진입 후 작업한다.
**메인 저장소(`PAB-SSOT-Nexus/`) 경로에서의 편집은 WT-3 위반.**

### 5.3 트랙별 status.md 단편화 금지

병렬 트랙은 worktree만 분리되고 **status.md 본문은 단일**(메인 저장소의 `phase-27-2-status.md`)을 공유한다.
각 worktree에서 동일 status.md를 동시에 편집하지 않도록, **status.md 갱신은 Team Lead가 메인 clone에서 수행**한다.
팀원은 status.md를 **읽기만** 하고, 진행 보고는 SendMessage로 Team Lead에 전달한다.

---

## 6. A/B 분기 + worktree (§3-workflow §6.4 확장)

### 6.1 A/B 분기 절차에 worktree 통합

`docs/3-workflow.md §6.4` 의 기존 A/B 분기 절차에 worktree 단계를 삽입한다.

```
A/B 분기 시작
  ↓
git tag phase-{X}-{Y}-ab-start
git checkout -b phase-{X}-{Y}-branch-A
git checkout main
git checkout -b phase-{X}-{Y}-branch-B
  ↓ [WORKTREE 단계 — WT-1 필수]
git worktree add ../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-ab-A phase-{X}-{Y}-branch-A
git worktree add ../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-ab-B phase-{X}-{Y}-branch-B
  ↓
A안 팀 / B안 팀 동시 스폰 — 각 worktree CWD 주입
  ↓
독립 빌드·테스트 (CK-3 의존성 격리, 빌드 산출물 교차 오염 방지)
  ↓
ab-comparison-template.md 작성 — A vs B 정량 비교
  ↓
사용자 선택 → 선택된 브랜치 main에 merge
  ↓
[정리]
  · 선택 worktree: git worktree remove ../...-ab-{선택안}
  · 비선택 worktree: 보존 정책 (3-workflow.md §6.5 아카이브) → 아카이브 후 remove
git worktree prune
```

### 6.2 A/B 워크트리 격리가 보장하는 것

| 보장 항목 | 메커니즘 |
|----------|----------|
| 빌드 산출물 비교 신뢰성 | A/B 각각 독립 `node_modules`, `.next/`, `dist/` (CK-3) |
| 환경 변수 충돌 차단 | 각 worktree의 `.env.local` 독립 |
| 측정값 교차 오염 방지 | 벤치마크 결과 파일이 worktree별 분리 저장 |
| 동시 실행 가능 | 두 dev 서버를 다른 포트로 동시 기동 (포트는 worktree별 `.env`에서 분리) |

### 6.3 비선택 브랜치 아카이브 패턴

```bash
# B안이 비선택된 경우
git tag archive/phase-27-3-branch-B phase-27-3-branch-B
git worktree remove ../PAB-SSOT-Nexus-wt-phase-27-3-ab-B
# 브랜치 자체는 삭제하지 않음 (롤백 가능성 보존). 태그로 추적
```

---

## 7. REWINDING과 worktree (§3-workflow §6.3 확장)

### 7.1 REWINDING 시 worktree 전략

`docs/3-workflow.md §6.3` REWINDING 발생 시, 실패한 worktree를 **보존**하고 **retry-N worktree 를 추가 생성**한다.

```
phase-27-1 BUILDING 실패 (G2 FAIL)
  ↓
원인 분석 (verifier 리포트)
  ↓
[보존] ../PAB-SSOT-Nexus-wt-phase-27-1/  ← 그대로 둠 (포렌식 용)
git tag phase-27-1-retry-0-fail            ← 실패 시점 태깅
  ↓
git checkout -b phase-27-1-retry-1
git worktree add ../PAB-SSOT-Nexus-wt-phase-27-1-retry-1 phase-27-1-retry-1
  ↓
retry-1 worktree에서 수정 작업 → 다시 BUILDING
  ↓
성공 시: retry-1 worktree를 정본으로 채택, 원본 worktree는 §6.5 아카이브 후 제거
실패 시: retry-2 worktree 추가 생성 (반복)
```

### 7.2 retry 회차별 디렉토리 누적

```
../PAB-SSOT-Nexus-wt-phase-27-1/          (retry-0, 실패 보존)
../PAB-SSOT-Nexus-wt-phase-27-1-retry-1/  (재시도 1차, 실패 시 보존)
../PAB-SSOT-Nexus-wt-phase-27-1-retry-2/  (재시도 2차, 성공 시 정본)
```

성공 worktree만 main에 merge되고, 나머지는 Chain 완료 시점에 §3-workflow.md §6.5 아카이브 규칙에 따라 정리한다.

### 7.3 REWINDING 중 status.md 처리

```yaml
worktree_paths:
  - ../PAB-SSOT-Nexus-wt-phase-27-1               # 실패 (보존)
  - ../PAB-SSOT-Nexus-wt-phase-27-1-retry-1       # 진행 중 또는 실패
  - ../PAB-SSOT-Nexus-wt-phase-27-1-retry-2       # 진행 중
cleanup_wt: pending
rewinding_history:
  - retry-0: failed (G2_be FAIL — DB transaction race)
  - retry-1: failed (G3 FAIL — flaky e2e)
  - retry-2: in_progress
```

---

## 8. 충돌·누수 방지 체크리스트 (CK-1 ~ CK-5)

Pre-draft §3.4 표를 그대로 채택하고, 각 항목에 부가 설명을 덧붙인다.

| # | 항목 | 측정 |
|---|------|------|
| **CK-1** | 같은 브랜치를 2개 worktree가 체크아웃하지 않음 | `git worktree list` 출력에서 브랜치 컬럼 중복 0건 |
| **CK-2** | worktree 내부에 메인 저장소 경로 역참조 금지 | `readlink .git` 결과가 `gitdir: <메인경로>/.git/worktrees/...` 패턴 |
| **CK-3** | 빌드 산출물 공유 금지 | 각 worktree가 독립 `node_modules` / `.venv` / `__pycache__` 보유 |
| **CK-4** | Phase DONE 시 worktree 정리 스케줄 등록 | `phase-{X}-{Y}-status.md` 의 `cleanup_wt: pending\|done` 필드 |
| **CK-5** | `git worktree prune` 주기 실행 | Chain 종료 시 최소 1회, NOTIFY-1과 동시 |

### 8.1 항목별 부가 설명

- **CK-1 (브랜치 중복 금지)** — Git은 동일 브랜치를 두 worktree에 동시 체크아웃하는 것을 거부한다. `git worktree add ... <이미체크아웃된브랜치>` 는 에러로 차단되지만, 실수로 retry worktree에서 원본 브랜치를 `git checkout` 하면 우회 가능하므로 주의. `git worktree list` 의 브랜치 컬럼을 세션 시작 시 점검.
- **CK-2 (역참조 무결성)** — worktree 내부 `.git` 은 파일이며 메인 저장소의 `.git/worktrees/<name>/` 를 가리킨다. 이 링크가 깨지면 worktree가 좀비 상태가 된다. `readlink .git` 으로 검증하거나 `git rev-parse --git-dir` 결과가 메인 저장소 경로를 포함하는지 확인.
- **CK-3 (빌드 산출물 격리)** — worktree는 작업 트리만 격리하므로 패키지 매니저 레벨에서 별도 install이 필수. 메인의 `node_modules` 를 심볼릭 링크로 공유하면 의존성 버전 충돌 시 한쪽이 깨진다. **반드시 worktree별 `npm ci`** 실행.
- **CK-4 (정리 스케줄링)** — Phase DONE 시점에 worktree를 즉시 제거하면 REWINDING이 필요할 때 복원 비용이 크다. 따라서 `cleanup_wt: pending` 으로 표시만 하고 **Chain 완료 시 일괄 제거** 한다. `phase-{X}-{Y}-status.md` 에 필드를 강제하여 누수 방지.
- **CK-5 (prune 주기)** — `git worktree remove` 가 정상 종료해도 메타데이터(`.git/worktrees/<name>/`)가 일부 남는 경우가 있다. `git worktree prune` 을 Chain 종료 시 최소 1회, NOTIFY-1 발송 직전에 실행하여 metadata orphan을 청소한다. CI 자동화는 §9에서 다룬다.

### 8.2 위반 검출 명령 모음

```bash
# CK-1: 브랜치 중복 검출
git worktree list --porcelain | awk '/^branch/ {print $2}' | sort | uniq -d

# CK-2: 역참조 무결성
( cd ../PAB-SSOT-Nexus-wt-phase-27-2-be && readlink .git || cat .git )

# CK-3: 빌드 산출물 격리 — node_modules가 심볼릭 링크로 공유되지 않았는지
( cd ../PAB-SSOT-Nexus-wt-phase-27-2-be && [ -L node_modules ] && echo "VIOLATION: symlink" )

# CK-4: status.md 정리 필드 존재
grep -E "cleanup_wt:" ver6-0/docs/phases/phase-27-2/phase-27-2-status.md

# CK-5: prune 결과 검증
git worktree prune --verbose --dry-run
```

---

## 9. CI / 자동화 훅 (수동 운영 커맨드 시트)

> **중요 (Phase 범위 주석)**: **본 §9 자동화 훅의 본문 구현은 Phase-K (`scripts/pmAuto/worktree_setup.sh`,
> `worktree_cleanup.sh`, `worktree_audit.sh` 3종)에서 확장 예정이다. Phase-K 미완 상태에서는
> Team Lead가 본 시트의 커맨드를 수동으로 실행한다.** Phase-K 범위·옵션 비교는
> [`docs/phases/pre/phase-J-pre-analysis.md`](../phases/pre/phase-J-pre-analysis.md) §3~§5
> (옵션 C "pmAuto 통합" 권장안) 참조.

### 9.1 수동 운영 — Phase 라이프사이클 단계별 커맨드 시트

Team Lead가 Phase 상태 전이마다 직접 실행할 명령. Phase-K가 자동화하기 전까지의 **운영 매뉴얼**.

#### 9.1.1 BRANCH_CREATION → WORKTREE_SETUP (병렬 N≥2)

```bash
# 변수
PHASE_X=27 ; PHASE_Y=2
REPO_DIR=$HOME/WORKS/PAB-SSOT-Nexus

cd $REPO_DIR

# BE/FE 트랙 worktree 생성
for TRACK in be fe; do
  git checkout main
  git checkout -b phase-${PHASE_X}-${PHASE_Y}-${TRACK}
  git worktree add ../PAB-SSOT-Nexus-wt-phase-${PHASE_X}-${PHASE_Y}-${TRACK} phase-${PHASE_X}-${PHASE_Y}-${TRACK}
done

# 의존성 설치
for TRACK in be fe; do
  ( cd ../PAB-SSOT-Nexus-wt-phase-${PHASE_X}-${PHASE_Y}-${TRACK} && npm ci )
done

# status.md 갱신 (사용자가 직접 편집 또는 yq 사용)
echo "worktree_paths:"
for TRACK in be fe; do
  echo "  - ../PAB-SSOT-Nexus-wt-phase-${PHASE_X}-${PHASE_Y}-${TRACK}"
done
echo "cleanup_wt: pending"
```

#### 9.1.2 세션 시작 시 — Orphan worktree 점검

```bash
cd $HOME/WORKS/PAB-SSOT-Nexus

# 1. 활성 worktree 목록
git worktree list

# 2. status.md의 worktree_paths와 비교 (수동 또는 grep)
grep -h "worktree_paths" -A 10 ver6-0/docs/phases/phase-*/phase-*-status.md | grep "^  -" | sort -u

# 3. 활성 worktree 중 status.md에 없는 항목 = orphan 후보
# → 사용자 확인 후 제거
```

#### 9.1.3 Chain 완료 시 — WORKTREE_CLEANUP

```bash
# 1. 미커밋 변경 검사 (전 worktree)
for WT in $(git worktree list --porcelain | awk '/^worktree/ {print $2}'); do
  if [ "$WT" = "$REPO_DIR" ]; then continue; fi
  ( cd "$WT" && git status --porcelain ) | grep -q . && echo "DIRTY: $WT"
done

# 2. 전부 clean 확인 후 제거
git worktree remove ../PAB-SSOT-Nexus-wt-phase-27-2-be
git worktree remove ../PAB-SSOT-Nexus-wt-phase-27-2-fe

# 3. 메타데이터 정리
git worktree prune

# 4. status.md cleanup_wt: done 갱신

# 5. Telegram 알림 (NOTIFY-1)
bash scripts/pmAuto/report_to_telegram.sh \
  "[PAB-SSOT-Nexus] Phase 27-2 완료 / worktrees cleaned: 2"
```

### 9.2 Phase-K 자동화 예정 범위 (요약)

| 스크립트 (Phase-K) | 대체할 §9.1 단계 | 트리거 |
|--------------------|-------------------|--------|
| `scripts/pmAuto/worktree_setup.sh` | §9.1.1 (생성 + 의존성 설치 + status.md 갱신) | BRANCH_CREATION → WORKTREE_SETUP 전이 시 Team Lead가 호출 |
| `scripts/pmAuto/worktree_audit.sh` | §9.1.2 (orphan 점검) | 세션 시작 / Chain 착수 시 |
| `scripts/pmAuto/worktree_cleanup.sh` | §9.1.3 (cleanup + prune + status.md + NOTIFY) | Chain 완료 직후, NOTIFY-1 직전 |

> **금지 (Phase-J 범위 가드)**: Phase-J에서는 위 스크립트 파일을 작성하지 않는다.
> 본 §9는 **수동 운영 시트** + **Phase-K 예고**로만 기능한다. 자동화 본문은 Phase-K pre-analysis
> ([`phase-J-pre-analysis.md`](../phases/pre/phase-J-pre-analysis.md) §4 권장안 + §6 후속 Phase 로드맵)
> 에서 옵션 C(pmAuto 통합)로 확장된다.

### 9.3 (선택) GitHub Actions 보조 — Phase-L 예정

Phase-L에서 GitHub Actions의 matrix strategy로 PR 단위 worktree 검증을 보조 추가할 수 있다.
역할 분담 상세는 `phase-J-pre-analysis.md` §4.1 (계층별 옵션 매핑) 참조.

---

## 10. FAQ — worktree 공통 실수 5가지

#### Q1. 경로를 헷갈려서 메인 저장소에서 편집했는데 어떻게 되나요? (경로 오인)

**A**. WT-3 위반이다. Team Lead의 SendMessage `[CWD]` 와 `pwd` 결과가 다르면 즉시 작업 중단·재할당 대상이다.
DEV FRESH-1.5 체크리스트가 이를 검출한다. 실수로 메인에서 commit까지 했다면:

1. 해당 commit을 `git format-patch -1` 로 추출
2. 메인 브랜치에서 `git reset HEAD~1` 로 되돌리고
3. 올바른 worktree로 이동 후 `git am` 으로 재적용
4. `[BLOCKER] WT-3 위반` 보고서 작성 (재발 방지)

#### Q2. `.gitignore` 에 worktree 디렉토리를 안 넣어도 되나요? (gitignore 누락)

**A**. **저장소 옆 배치(§2.1 (b))** 를 채택했으므로 worktree는 메인 저장소의 부모 디렉토리에 위치한다.
즉 메인 저장소의 `git status` 가 worktree 파일을 인식하지 않으므로 `.gitignore` 등록이 **불필요**하다.
만약 (a) 저장소 내부 `.worktrees/` 전략을 썼다면 `.gitignore` 에 `/.worktrees/` 를 반드시 추가해야 한다.
**본 가이드는 (b) 채택이므로 이 항목은 함정 회피 차원에서 명시한다.**

#### Q3. 두 worktree에서 `node_modules` 를 공유하면 디스크가 절약되지 않나요? (의존성 중복)

**A**. CK-3 위반이다. 디스크 절약 효과는 일시적이고, **의존성 버전 충돌·빌드 캐시 오염**으로 더 큰 비용이 발생한다.
디스크가 부족하면 `pnpm` 의 content-addressable store나 `npm` 의 `--prefer-offline` 캐시를 사용하라.
이는 패키지 매니저 레벨에서 안전하게 공유되며 worktree 격리 원칙을 위반하지 않는다.

#### Q4. A/B 분기에서 같은 dev 서버 포트를 쓰면 어떻게 되나요? (A/B 교차 오염)

**A**. **포트 충돌 + 측정값 신뢰도 붕괴**가 동시에 발생한다. A/B worktree는 `.env.local` 을 각각 분리하여
포트(예: A=3000, B=3001), DB schema(예: `pab_test_a`, `pab_test_b`), Redis namespace(`ab:A:`, `ab:B:`) 를
분리해야 한다. 동일 포트로 운영하면 한쪽 서버를 죽이고 다른 쪽을 띄우는 직렬 측정이 되어 worktree 격리 의미가 사라진다.

#### Q5. 에이전트가 비정상 종료되어 worktree가 좀비 상태입니다. 어떻게 복구하나요? (비정상 종료 복구)

**A**. 다음 절차를 따른다.

1. **활성/좀비 분류** — `git worktree list` 출력의 `prunable` 표시(또는 디렉토리 부재) 확인
2. **메타데이터 prune** — `git worktree prune --verbose` 로 좀비 메타 제거
3. **잔존 디렉토리 처리** — 디렉토리가 남아있으면 `git status` 로 미커밋 변경 확인
   - 변경 있음 → patch로 백업 후 사용자 승인하에 `git worktree remove --force`
   - 변경 없음 → `git worktree remove` 정상 제거
4. **brokenLink 재연결** — 메인 저장소의 `.git/worktrees/<name>/gitdir` 파일이 가리키는 경로가
   실제와 다르면 직접 수정하거나 `git worktree repair <path>` 실행
5. **status.md 동기화** — `worktree_paths` 에서 제거된 항목 삭제, `cleanup_wt: done` 갱신

복구 후 반드시 `[INCIDENT] worktree orphan` 보고서를 작성하여 NOTIFY-1에 포함시킨다.

---

## 부록 A. 빠른 참조 치트시트

| 질문 | 답 |
|------|---|
| 신규 worktree 생성? | `git worktree add ../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-{track} phase-{X}-{Y}-{track}` |
| worktree 목록? | `git worktree list` |
| worktree 제거? | `git worktree remove ../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-{track}` |
| 메타 정리? | `git worktree prune` |
| 언제 필수? | 병렬 BUILDING 트랙 ≥ 2 (WT-1) |
| 경로 위치? | 저장소 옆 (`../PAB-SSOT-Nexus-wt-...`) |
| 정리 시점? | Phase Chain 완료 직후, NOTIFY-1 직전 |
| 자동화? | Phase-K 예정 (`scripts/pmAuto/worktree_*.sh` 3종) |
| 상위 규정 본문? | `3-workflow.md §3, §6.6` / `1-project.md §7.3` / `core/6-rules-index.md` WT 카테고리 |

---

**문서 끝.**
변경 이력은 `docs/VERSION.md` v8.3-renewal-6th 항목 참조.
본 가이드 갱신 시 §1.3에 명시된 참조 SSOT 파일들과의 정합성을 유지한다.
