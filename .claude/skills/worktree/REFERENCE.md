# Git Worktree 운영 참조 가이드 (skill REFERENCE)

> 이 가이드는 `worktree` skill의 상세 참조 문서입니다.
> `SKILL.md`는 호출 형식과 옵션을 정의하고, 본 REFERENCE는 워크플로우·모범 사례·트러블슈팅을 다룹니다.

---

## §1 개요

### 1.1 도입 배경

같은 git 저장소에서 여러 브랜치를 동시에 작업할 때 **공유 작업 디렉토리 3가지 부작용**이 발생한다.

| # | 부작용 | 현상 |
|---|--------|------|
| 1 | **`git checkout` 경합** | 두 작업이 같은 디렉토리에서 서로 다른 브랜치를 체크아웃하며 상태를 덮어씀 |
| 2 | **빌드 산출물 오염** | `node_modules/`, `.venv/`, `dist/`, `.next/` 등이 브랜치별로 섞임 |
| 3 | **`git stash` / index 오염** | 한 작업의 stash·staged 변경을 다른 작업이 의식하지 못한 채 commit |

`git worktree`는 동일 `.git` 저장소를 공유하면서 **브랜치별로 독립된 작업 디렉토리**를 제공한다.
위 3가지를 동시에 해소하여 병렬 브랜치 작업을 안전하게 수행할 수 있다.

### 1.2 적용 범위

| 상황 | worktree 사용 |
|------|--------------|
| 단일 브랜치 작업 | **선택** — 메인 clone에서 직접 작업 가능 |
| 병렬 브랜치 작업 (≥2) | **권장** — worktree 없이 진행 시 빌드 산출물 오염 위험 |
| A/B 분기 비교 | **권장** — 각 안을 독립 worktree에서 빌드·측정 |
| 실패 후 재시도 | **권장** — 실패 작업 디렉토리 보존 + 재시도 디렉토리 추가 |

---

## §2 디렉토리 규약

### 2.1 위치 전략 — 저장소 옆 배치

worktree 디렉토리는 **메인 저장소와 같은 부모 디렉토리에 형제로** 배치한다.

```
~/projects/
├── myproject/                        ← 메인 clone (origin)
├── myproject-wt-feature-x/           ← 단일 브랜치 worktree
├── myproject-wt-feature-y-be/        ← 병렬 BE 트랙
├── myproject-wt-feature-y-fe/        ← 병렬 FE 트랙
└── myproject-wt-feature-z-retry-1/   ← 재시도 worktree
```

**선택지 비교**:

| 후보 | 채택 여부 | 사유 |
|------|----------|------|
| 저장소 내부 `./.worktrees/` | **불채택** | gitignore 누락 시 재귀 노출; IDE가 메인 트리와 혼동 |
| **저장소 옆 `../<repo>-wt-...`** | **채택** | 빌드 캐시 분리 강제; IDE에서 별도 프로젝트로 인식 |
| 홈 디렉토리 `~/worktrees/` | **불채택** | 다른 머신·컨테이너 환경에서 절대 경로 불일치 |

### 2.2 네이밍 패턴

| 상황 | 경로 패턴 | 예시 |
|------|----------|------|
| 단일 브랜치 | `../<REPO_NAME>-wt-<branch>` | `../myproject-wt-feature-x` |
| 병렬 트랙 | `../<REPO_NAME>-wt-<branch>-<track>` | `../myproject-wt-sprint3-be` |
| A/B 분기 | `../<REPO_NAME>-wt-<branch>-ab-<A\|B>` | `../myproject-wt-refactor-ab-A` |
| 재시도 | `../<REPO_NAME>-wt-<branch>-retry-<N>` | `../myproject-wt-feature-x-retry-1` |

`<REPO_NAME>`은 `$(basename "$(git rev-parse --show-toplevel)")` 로 동적 추출한다.

### 2.3 브랜치-worktree 매핑 원칙

- **1 worktree = 1 브랜치** (같은 브랜치를 2개 worktree에 동시 체크아웃 불가)
- 브랜치명과 디렉토리 suffix를 **일치**시킨다.
  - 브랜치 `feature-x` ↔ 디렉토리 `../myproject-wt-feature-x`
- worktree 내부에서 `git checkout`으로 브랜치를 변경하지 않는다.
  브랜치 전환이 필요하면 새 worktree를 만든다.

---

## §3 커맨드 시트

### 3.1 핵심 명령

```bash
# ── SETUP ─────────────────────────────────────────────
# 신규 브랜치 생성 + worktree 추가
git worktree add -b feature-x ../myproject-wt-feature-x

# 기존 브랜치에 worktree 추가
git worktree add ../myproject-wt-feature-x feature-x

# 병렬 트랙 (BE / FE)
git worktree add -b sprint3-be ../myproject-wt-sprint3-be
git worktree add -b sprint3-fe ../myproject-wt-sprint3-fe

# A/B 분기
git worktree add -b refactor-branch-A ../myproject-wt-refactor-ab-A
git worktree add -b refactor-branch-B ../myproject-wt-refactor-ab-B

# ── LIST ──────────────────────────────────────────────
git worktree list                    # 현황 확인
git worktree list --porcelain        # 스크립트 처리용

# ── CLEANUP ───────────────────────────────────────────
# 정상 제거
git worktree remove ../myproject-wt-feature-x

# 메타데이터 정리 (remove 후 또는 비정상 종료 후)
git worktree prune
git worktree prune --verbose --dry-run   # 사전 확인
```

### 3.2 안전 삭제 절차 (제거 전 필수)

```bash
WT_PATH="../myproject-wt-feature-x"

# 1. 미커밋 변경 검사 (출력 있으면 중단)
( cd "$WT_PATH" && git status --porcelain )

# 2. unpushed 커밋 검사 (출력 있으면 중단)
( cd "$WT_PATH" && git log "@{u}..HEAD" --oneline 2>/dev/null )

# 3. 둘 다 비어 있으면 제거
git worktree remove "$WT_PATH"

# 4. 메타데이터 정리
git worktree prune
```

> **주의**: `--force` 플래그는 미커밋 변경을 무시하고 강제 삭제한다. 꼭 필요하다면
> 사전에 `git diff > /tmp/wt-backup.patch` 로 변경 사항을 백업한 후 사용하라.

### 3.3 의존성 설치 (worktree별 독립)

worktree는 작업 트리만 격리한다. **패키지 매니저 의존성은 각 worktree에서 별도 설치**해야 한다.

```bash
cd ../myproject-wt-feature-x

# Node.js 프로젝트
npm ci

# Python 프로젝트
python -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt
```

---

## §4 워크플로우

### 4.1 단일 브랜치 작업 (worktree 선택 적용)

```
1. git checkout -b feature-x
2. (선택) git worktree add -b feature-x ../myproject-wt-feature-x
3. 작업 + commit + push
4. PR merge 후 git worktree remove ../myproject-wt-feature-x
5. git worktree prune
```

단일 작업이면 메인 clone에서 직접 작업해도 무방하다.

### 4.2 병렬 브랜치 작업 (worktree 권장)

```
1. 브랜치 생성
   git checkout main && git checkout -b sprint3-be
   git checkout main && git checkout -b sprint3-fe

2. worktree 생성
   git worktree add ../myproject-wt-sprint3-be sprint3-be
   git worktree add ../myproject-wt-sprint3-fe sprint3-fe

3. 의존성 설치 (각 worktree)
   ( cd ../myproject-wt-sprint3-be && npm ci )
   ( cd ../myproject-wt-sprint3-fe && npm ci )

4. 병렬 작업
   · BE: ../myproject-wt-sprint3-be 내부에서만 편집·빌드
   · FE: ../myproject-wt-sprint3-fe 내부에서만 편집·빌드

5. 작업 완료 후 정리
   git worktree remove ../myproject-wt-sprint3-be
   git worktree remove ../myproject-wt-sprint3-fe
   git worktree prune
```

### 4.3 A/B 분기 비교

각 안(案)을 독립 worktree에서 빌드·측정하여 측정값 교차 오염을 방지한다.

```
1. 분기 태깅 + 브랜치 생성
   git tag ab-start
   git checkout -b refactor-branch-A
   git checkout main && git checkout -b refactor-branch-B

2. worktree 생성
   git worktree add ../myproject-wt-refactor-ab-A refactor-branch-A
   git worktree add ../myproject-wt-refactor-ab-B refactor-branch-B

3. 각 worktree에서 독립 빌드·측정 (포트 분리 권장: A=3000, B=3001)

4. 비교 후 선택된 안을 main에 merge
5. 비선택 안은 태그 보존 후 worktree 제거
   git tag archive/refactor-branch-B refactor-branch-B
   git worktree remove ../myproject-wt-refactor-ab-B
```

### 4.4 실패 후 재시도

실패한 worktree는 포렌식을 위해 보존하고 새 worktree에서 재시도한다.

```
1. 실패 시점 태깅
   git tag feature-x-retry-0-fail

2. 재시도 브랜치 + worktree 생성
   git checkout -b feature-x-retry-1
   git worktree add ../myproject-wt-feature-x-retry-1 feature-x-retry-1

3. 재시도 성공 시: retry-1 worktree를 정본으로 채택
4. 원본 worktree는 태그 보존 후 제거
   git worktree remove ../myproject-wt-feature-x
```

### 4.5 옵션 비교 시나리오 (compare 명령 전용)

`/worktree compare` 명령을 이용해 3가지 구현 옵션을 병렬 개발하고 최적안을 선택하는 전체 흐름.

#### 4.5.1 시나리오 개요

```
목표: "Task X에 대해 옵션 A(간단), B(고성능), C(재사용성) 세 가지 구현을 비교"

1단계 — worktree 생성
  /worktree compare A B C --criteria=lines,test-pass,readability

  → 생성 결과:
     ../myproject-wt-compare-A  (branch: compare-A)
     ../myproject-wt-compare-B  (branch: compare-B)
     ../myproject-wt-compare-C  (branch: compare-C)

2단계 — 각 worktree에서 독립 구현
  cd ../myproject-wt-compare-A && <옵션 A 구현>
  cd ../myproject-wt-compare-B && <옵션 B 구현>
  cd ../myproject-wt-compare-C && <옵션 C 구현>

3단계 — 결과 비교 (compare 재호출)
  /worktree compare A B C --criteria=lines,test-pass,readability

  → 비교 표 출력 (이미 worktree 존재 → Step 3 자동 진입):
     | 옵션 | 변경 줄 수 | 테스트 | 커밋 수 |
     | A    | 120줄      | PASS   | 3       |
     | B    | 340줄      | PASS   | 7       |
     | C    | 210줄      | FAIL   | 5       |

4단계 — 선택 + 정리
  # Team Lead / 사용자가 옵션 A 선택 결정 → merge + cleanup
  git checkout main && git merge --no-ff compare-A
  /worktree cleanup compare-B
  /worktree cleanup compare-C
  /worktree cleanup compare-A
```

#### 4.5.2 비교 기준(criteria) 가이드

| KEY | 수집 방법 | 해석 |
|-----|----------|------|
| `lines` | `git diff --stat HEAD` 줄 수 합계 | 낮을수록 간결 |
| `test-pass` | `npm test` / `pytest -q` 자동 시도 | PASS / FAIL / N/A |
| `perf` | 사용자가 별도 측정 후 수동 기록 (자동 수집 불가) | ms, RPS 등 |
| `readability` | 사용자/에이전트가 주관 평가 후 수동 기록 | 1~5점 척도 등 |

`lines`, `test-pass`만 자동 수집. `perf`, `readability`는 비교 표에 `(수동입력)` 플레이스홀더로 표시된다.

#### 4.5.3 포트 분리 (A/B/C 동시 실행 시)

각 worktree에서 dev 서버를 동시에 실행할 경우 포트가 충돌한다.
각 worktree 루트에 `.env.local`을 만들어 독립 포트를 지정하라.

```bash
# ../myproject-wt-compare-A/.env.local
PORT=3000

# ../myproject-wt-compare-B/.env.local
PORT=3001

# ../myproject-wt-compare-C/.env.local
PORT=3002
```

#### 4.5.4 선택 보류 시 임시 태깅

최종 결정 전 각 옵션 상태를 태그로 보존한다.

```bash
git tag compare-snapshot/A compare-A
git tag compare-snapshot/B compare-B
git tag compare-snapshot/C compare-C
```

이후 비선택 worktree를 제거해도 스냅샷 태그가 남아 롤백 가능하다.

---

## §5 모범 사례 (체크리스트)

| # | 항목 | 확인 방법 |
|---|------|----------|
| **CK-1** | 같은 브랜치를 2개 worktree가 동시 체크아웃하지 않음 | `git worktree list --porcelain \| awk '/^branch/ {print $2}' \| sort \| uniq -d` → 0건 |
| **CK-2** | worktree 내부 `.git` 파일 링크 무결성 | `( cd ../myproject-wt-feature-x && cat .git )` — `gitdir: <메인경로>/.git/worktrees/...` 패턴 |
| **CK-3** | 빌드 산출물 공유 금지 | 각 worktree가 독립 `node_modules` / `.venv` 보유; 심볼릭 링크 공유 금지 |
| **CK-4** | 작업 완료 후 worktree 정리 | 정리 전 미커밋 변경·unpushed 커밋 확인 후 `worktree remove` + `prune` |
| **CK-5** | `git worktree prune` 주기 실행 | 작업 완료 시 최소 1회 실행하여 메타데이터 orphan 청소 |
| **CK-6** | compare: 옵션 개수 ≤ 5 권장 | 6개 이상 시 비교 표 가독성 저하 — 2~3개 우선 검토 후 추가 |
| **CK-7** | compare: 옵션별 포트 분리 확인 | dev 서버 동시 실행 시 `.env.local`로 포트 독립 지정 (4.5.3 참조) |
| **CK-8** | compare: 선택 전 스냅샷 태그 생성 | `git tag compare-snapshot/<OPT> compare-<OPT>` — 결정 취소 시 복구 기준점 |
| **CK-9** | compare: 비선택 옵션 정리 완료 확인 | `git worktree list` → `wt-compare-*` 0건; `git worktree prune` 실행 |

### 5.2 compare 모범 사용 패턴

```
권장 순서:
1. compare 호출로 worktree 생성 (Step 1)
2. 각 worktree에서 최소 단위 구현 → commit
3. compare 재호출로 비교 표 확인 (Step 3)
4. 사용자/Team Lead 선택 결정
5. 선택 옵션 merge → 비선택 cleanup → prune

피해야 할 패턴:
- worktree 생성 후 merge 없이 장기 방치 (좀비 risk)
- 같은 worktree에서 여러 옵션을 겸용 (비교 신뢰성 저하)
- compare 결과 표 없이 임의 선택 (비교 워크플로우 취지 위반)
```

### 5.1 위반 검출 명령 모음

```bash
# CK-1: 브랜치 중복 검출
git worktree list --porcelain | awk '/^branch/ {print $2}' | sort | uniq -d

# CK-2: 역참조 무결성 (worktree 내부에서 실행)
cat .git   # "gitdir: ..." 형태여야 함

# CK-3: node_modules 심볼릭 링크 여부
[ -L node_modules ] && echo "VIOLATION: symlink"

# CK-5: prune 사전 확인
git worktree prune --verbose --dry-run
```

---

## §6 트러블슈팅

### Q1. 메인 저장소에서 실수로 편집했습니다 (경로 오인)

**원인**: `pwd`를 확인하지 않고 메인 저장소에서 작업.

**해결**:
1. `git format-patch -1` 로 해당 commit을 패치로 추출
2. `git reset HEAD~1` 로 메인 브랜치에서 제거
3. 올바른 worktree로 이동 후 `git am <패치파일>` 로 재적용

### Q2. `.gitignore`에 worktree 디렉토리를 등록해야 하나요?

**아니오.** 저장소 옆 배치(형제 디렉토리) 방식을 쓰면 메인 저장소의 `git status`가
worktree 파일을 인식하지 않으므로 `.gitignore` 등록이 **불필요**합니다.
저장소 내부(`./.worktrees/`)에 배치했을 때만 등록이 필요합니다.

### Q3. `node_modules`를 공유하면 디스크를 절약할 수 있지 않나요?

**CK-3 위반입니다.** 의존성 버전 충돌·빌드 캐시 오염으로 더 큰 비용이 발생합니다.
디스크가 부족하면 `pnpm`의 content-addressable store나 `npm --prefer-offline` 캐시를 활용하세요.
이 방식은 워크트리 격리 원칙을 위반하지 않습니다.

### Q4. A/B 분기에서 같은 dev 서버 포트를 쓰면 어떻게 되나요?

**포트 충돌 + 측정값 신뢰도 붕괴**가 동시에 발생합니다.
A/B worktree는 `.env.local`을 각각 분리하여 포트(예: A=3000, B=3001),
DB 스키마, Redis 네임스페이스 등을 독립시키세요.

### Q5. 에이전트/프로세스가 비정상 종료되어 worktree가 좀비 상태입니다

**복구 절차**:
1. `git worktree list` — `prunable` 표시 또는 디렉토리 부재 확인
2. `git worktree prune --verbose` — 좀비 메타 제거
3. 디렉토리가 남아 있으면:
   - 미커밋 변경 있음 → `git diff > /tmp/wt-backup.patch` 백업 후 `git worktree remove --force`
   - 미커밋 변경 없음 → `git worktree remove` 정상 제거
4. 링크가 깨진 경우: `git worktree repair <path>` 실행

### Q6. `git worktree add` 가 "already checked out" 오류를 냅니다

**원인**: 다른 worktree(또는 메인)에 같은 브랜치가 이미 체크아웃되어 있습니다.

**해결**: `git worktree list`로 어떤 worktree가 해당 브랜치를 사용 중인지 확인.
다른 worktree가 사용 중이면 먼저 제거하거나, 브랜치명을 변경하여 새 worktree를 생성하세요.

---

## §7 GitHub 연동 (선택)

### 7.1 gh CLI — PR Draft 자동 생성

`gh` CLI가 설치되어 있으면 worktree 생성 후 즉시 PR draft를 만들 수 있다.

```bash
# worktree 생성
git worktree add -b feature-x ../myproject-wt-feature-x

# PR draft 생성 (gh CLI 필요)
cd ../myproject-wt-feature-x
gh pr create --draft --title "[Draft] feature-x" --body "" --head feature-x --base main
```

`worktree` skill의 `setup feature-x --gh-pr` 옵션을 사용하면 위 두 단계를 자동으로 수행한다.
**gh CLI 미설치 시 worktree는 그대로 생성**되며 PR 생성 안내만 출력된다 (graceful fallback).

### 7.2 다른 GitHub 레포에서 사용 시 주의사항

본 가이드와 `worktree` skill은 **어떤 git 레포에서도 동작**한다.

- **레포 이름**: `$REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")`으로 자동 결정
- **worktree 경로**: `${REPO_PARENT}/${REPO_NAME}-wt-${branch}` 형태로 생성
- **프로젝트 종속성 없음**: 하드코딩된 프로젝트명·절대 경로 없음
- `--remote=<URL>` 옵션으로 다른 레포를 clone 후 worktree를 생성할 수 있다

```bash
# 다른 레포 clone + worktree 생성 (skill 호출 예시)
# setup feature-x --remote=https://github.com/org/other-repo
```

> **Phase 6-3 검증 예정**: gh CLI 연동 E2E 시나리오 및 다른 레포 호환성 상세 검증.

---

## 빠른 참조 치트시트

| 질문 | 명령 / 답 |
|------|----------|
| 신규 worktree 생성? | `git worktree add -b <branch> ../<REPO_NAME>-wt-<branch>` |
| 목록 확인? | `git worktree list` |
| 안전 제거? | 미커밋·unpushed 확인 후 `git worktree remove ...` |
| 메타 정리? | `git worktree prune` |
| 병렬 작업 시 필수? | 병렬 브랜치 ≥ 2 |
| 경로 위치? | 저장소 옆 형제 디렉토리 (`../`) |
| 정리 시점? | 작업(브랜치) 완료 직후 |
| gh 없이 사용? | 가능 (worktree 기능에 영향 없음) |
