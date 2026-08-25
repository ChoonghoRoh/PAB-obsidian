---
name: worktree
description: Git worktree 신설/정리/감사 (병렬 BUILDING 격리). 어떤 git 레포에서도 동작 (PAB 종속성 0).
argument-hint: "<setup|cleanup|audit|compare> [branch|opt-A opt-B] [--gh-pr] [--remote=URL] [--criteria=KEYS] [--branch-prefix=PREFIX] [--dry] [--help]"
user-invocable: true
context: fork
agent: general-purpose
allowed-tools: "Bash, Read, Glob"
---

# worktree — Git Worktree 관리

Git worktree를 이용해 병렬 브랜치 작업 디렉토리를 생성(setup), 정리(cleanup), 감사(audit)한다.
현재 저장소 컨텍스트에서 동적으로 경로를 결정하므로 어떤 git 레포에서도 동작한다.

## §0 `--help` 처리

`$ARGUMENTS`에 `--help` 토큰이 포함되면 아래 도움말을 출력하고 즉시 종료한다.

```
사용법: /worktree <setup|cleanup|audit|compare> [branch|opt-A opt-B] [옵션]

서브커맨드:
  setup   <branch>             worktree를 저장소 옆 형제 디렉토리에 생성
  cleanup <branch>             안전 검사 후 worktree 제거 및 메타데이터 prune
  audit                        모든 worktree 상태 진단 및 정리 후보 권고
  compare <opt-A> <opt-B> ...  옵션별 worktree 생성 후 결과 비교 워크플로우

옵션:
  --gh-pr                (setup) worktree 생성 후 GitHub PR draft 생성 (gh CLI 필요)
  --remote=<URL>         (setup) 다른 GitHub 레포 clone 후 worktree 생성
  --criteria=KEY1,KEY2   (compare) 비교 기준 — 기본값: lines,test-pass
  --branch-prefix=PREFIX (compare) branch 명명 prefix — 기본값: compare-
  --dry                  실제 실행 없이 명령만 출력
  --help                 이 도움말 출력

예시:
  /worktree setup feature-x
  /worktree setup feature-x --gh-pr
  /worktree cleanup feature-x
  /worktree audit
  /worktree compare A B C --criteria=lines,test-pass,readability
  /worktree compare A B --dry
  /worktree --help

상세 참조: skills/worktree/REFERENCE.md
```

## §1 입력 파싱

`$ARGUMENTS`를 공백 단위로 토큰화한다.

| 패턴 | 분류 | 예시 |
|------|------|------|
| 첫 번째 위치 인수 | subcommand | `setup`, `cleanup`, `audit` |
| 두 번째 위치 인수 | branch 이름 | `feature-x` |
| `--key=value` | 키-값 옵션 | `--remote=https://github.com/user/repo` |
| `--flag` | 불린 플래그 | `--gh-pr`, `--dry`, `--help` |

### 파싱 절차

1. `--help` 포함 시 §0 헬프 출력 후 즉시 종료
2. 첫 위치 인수를 `subcommand`로 추출 (`setup` / `cleanup` / `audit` / `compare`)
3. subcommand 없거나 유효하지 않으면 오류 출력 후 종료
4. `setup` / `cleanup`: 두 번째 위치 인수를 `branch`로 수집; 미제공 시 오류 종료
5. `compare`: 두 번째 이후 위치 인수를 `opt_list[]` 배열로 수집; 2개 미만 시 오류 종료
6. `--remote` / `--gh-pr`: `setup` 전용 — 다른 subcommand에 지정 시 경고 후 무시
7. `--criteria` / `--branch-prefix`: `compare` 전용 — 다른 subcommand에 지정 시 경고 후 무시
8. 알 수 없는 옵션: 경고 출력 후 실행 계속
9. `--dry`: 이후 모든 bash 명령을 실행 생략, 명령 목록만 출력

## §2 사전 조건

모든 subcommand 실행 전 검증한다.

### 2.1 git 레포 확인

```bash
git rev-parse --git-dir 2>/dev/null
```

실패(exit ≠ 0) 시: `[ERROR] 현재 디렉토리가 git 레포가 아닙니다. git 레포 루트에서 실행하세요.` 출력 후 종료

### 2.2 저장소 컨텍스트 변수화

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")
REPO_PARENT=$(dirname "$REPO_ROOT")
```

이후 모든 경로는 위 변수로만 구성한다. **절대 경로 하드코딩 금지.**

## §3 처리 절차

worktree 경로 패턴: `${REPO_PARENT}/${REPO_NAME}-wt-${branch}`

### 3.1 setup `<branch>`

1. **branch 존재 확인**: `git show-ref --verify --quiet "refs/heads/${branch}"`

2. **worktree 생성** (`--dry` 시 명령만 출력)

   ```bash
   # branch 미존재 시 (신규 생성)
   git worktree add -b "${branch}" "${REPO_PARENT}/${REPO_NAME}-wt-${branch}"

   # branch 존재 시
   git worktree add "${REPO_PARENT}/${REPO_NAME}-wt-${branch}" "${branch}"
   ```

3. **`--remote=<URL>` 시**: 지정 URL을 별도 경로에 clone 후 worktree 추가

   ```bash
   CLONE_PATH="${REPO_PARENT}/${REPO_NAME}-wt-${branch}-remote"
   git clone "${REMOTE_URL}" "${CLONE_PATH}"
   ( cd "${CLONE_PATH}" && git worktree add -b "${branch}" "${REPO_PARENT}/${REPO_NAME}-wt-${branch}" )
   ```

4. **`--gh-pr` 시**: `command -v gh` 로 설치 확인
   - **설치됨**: `gh pr create --draft --title "[Draft] ${branch}" --body "" --head "${branch}"`
   - **미설치**: worktree는 정상 생성 완료; `[INFO] gh CLI 미설치 — PR은 GitHub에서 수동 생성하세요.` 출력

5. **결과**: `[OK] worktree 생성: ${REPO_PARENT}/${REPO_NAME}-wt-${branch} (branch: ${branch})`

### 3.2 cleanup `<branch>`

1. **worktree 존재 확인**:
   `git worktree list --porcelain | grep -F "worktree ${REPO_PARENT}/${REPO_NAME}-wt-${branch}"`
   미존재 시: 경고 출력 후 prune만 실행

2. **미커밋 변경 검사**:
   `( cd "${REPO_PARENT}/${REPO_NAME}-wt-${branch}" && git status --porcelain )`
   변경 있음: `[WARN] 미커밋 변경 있음 — 삭제 중단` 출력 후 종료

3. **unpushed 커밋 검사**:
   `( cd "${REPO_PARENT}/${REPO_NAME}-wt-${branch}" && git log "@{u}..HEAD" --oneline 2>/dev/null )`
   unpushed 있음: `[WARN] push되지 않은 커밋 있음 — 삭제 중단` 출력 후 종료

4. **제거 및 prune** (`--dry` 시 명령만 출력):

   ```bash
   git worktree remove "${REPO_PARENT}/${REPO_NAME}-wt-${branch}"
   git worktree prune
   ```

5. **결과**: `[OK] worktree 제거: ${REPO_PARENT}/${REPO_NAME}-wt-${branch} (브랜치는 보존됨)`

### 3.3 audit

1. **전체 목록**: `git worktree list`

2. **각 worktree 진단** (메인 제외):

   ```bash
   ( cd "${wt_path}" && git status --porcelain )          # 미커밋
   ( cd "${wt_path}" && git log "@{u}..HEAD" --oneline 2>/dev/null )  # unpushed
   ```

   상태 표시: `[CLEAN]` / `[DIRTY]` / `[UNPUSHED]` / `[MISSING]`(좀비)

3. **orphan 탐지**: `git worktree prune --verbose --dry-run`

4. **브랜치 중복 검출** (CK-1):
   `git worktree list --porcelain | awk '/^branch/ {print $2}' | sort | uniq -d`

5. **결과 출력 형식**:

   ```
   ## Worktree Audit 결과

   | 경로 | 브랜치 | 상태 |
   |------|--------|------|
   | (메인) | main | CLEAN |
   | ../repo-wt-feature-x | feature-x | CLEAN |

   ### 정리 후보
   - [MISSING] ../repo-wt-old — git worktree prune 권장

   ### 브랜치 중복: 없음
   ```

### 3.4 compare `<opt-A> <opt-B> [opt-C ...]`

복수 옵션(안)을 각 worktree에서 병렬 개발한 결과를 비교하는 워크플로우 도구.
**워크플로우 인프라 역할만 담당** — 실제 옵션 구현은 사용자/에이전트가 별도 진행한다.

#### 전제 변수 (§2.2 변수 재활용)

```bash
BRANCH_PREFIX="${PREFIX:-compare-}"   # --branch-prefix 로 덮어쓸 수 있음
CRITERIA="${CRITERIA:-lines,test-pass}"  # --criteria 기본값
```

#### Step 1 — 옵션별 worktree setup

opt_list[]의 각 옵션에 대해 반복 수행한다.

```bash
for OPT in "${opt_list[@]}"; do
  BRANCH="${BRANCH_PREFIX}${OPT}"
  WT_PATH="${REPO_PARENT}/${REPO_NAME}-wt-compare-${OPT}"

  # branch 미존재 시 신규 생성 / 존재 시 기존 연결
  if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
    git worktree add "${WT_PATH}" "${BRANCH}"
  else
    git worktree add -b "${BRANCH}" "${WT_PATH}"
  fi

  echo "[OK] worktree 생성: ${WT_PATH} (branch: ${BRANCH})"
done
```

`--dry` 지정 시 위 명령을 출력만 하고 실행하지 않는다.

#### Step 2 — 옵션 개발 안내

worktree 생성 완료 후 다음 안내 메시지를 출력한다.

```
## 다음 단계 안내

각 옵션 worktree에서 독립 구현 후 결과 비교를 진행하세요:

  옵션 A → cd ${REPO_PARENT}/${REPO_NAME}-wt-compare-A
  옵션 B → cd ${REPO_PARENT}/${REPO_NAME}-wt-compare-B
  ...

구현 완료 후 비교 실행:
  /worktree compare A B [C] --criteria=<criteria> (재호출)

※ compare 재호출 시 worktree가 이미 존재하면 Step 1을 건너뛰고 Step 3 (결과 비교)로 진행합니다.
```

#### Step 3 — 결과 비교 (compare-results 서브 모드)

모든 compare worktree가 이미 존재할 때 자동으로 진입한다.
`--criteria` 값에 따라 지표를 수집하고 비교 표를 출력한다.

```bash
for OPT in "${opt_list[@]}"; do
  WT_PATH="${REPO_PARENT}/${REPO_NAME}-wt-compare-${OPT}"

  # lines: 변경된 파일 줄 수 합계
  LINES=$(cd "${WT_PATH}" && git diff --stat HEAD 2>/dev/null | tail -1)

  # test-pass: npm test / pytest 자동 시도 (실패 시 N/A)
  if [ -f "${WT_PATH}/package.json" ]; then
    TEST_RESULT=$(cd "${WT_PATH}" && npm test --silent 2>&1 | tail -1 || echo "N/A")
  elif [ -f "${WT_PATH}/pytest.ini" ] || [ -f "${WT_PATH}/setup.cfg" ]; then
    TEST_RESULT=$(cd "${WT_PATH}" && python -m pytest -q 2>&1 | tail -1 || echo "N/A")
  else
    TEST_RESULT="N/A"
  fi

  # git diff stat
  DIFF_STAT=$(cd "${WT_PATH}" && git diff --stat HEAD 2>/dev/null)

  # commit 수
  COMMIT_COUNT=$(cd "${WT_PATH}" && git log "main..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ')
done
```

**비교 표 출력 형식**:

```
## 옵션 비교 결과

| 옵션 | 브랜치 | 변경 줄 수 | 테스트 | 커밋 수 | 비고 |
|------|--------|-----------|--------|---------|------|
| A    | compare-A | X줄 | PASS | N | - |
| B    | compare-B | Y줄 | FAIL | M | - |

기준: lines,test-pass
권장 선택: (판단 보류 — 사용자/Team Lead가 결정)
```

#### Step 4 — 선택 후 정리

사용자/Team Lead가 최적 옵션 선택 후 다음 명령을 실행한다.

```bash
# 선택된 옵션(예: A)을 main에 merge
git checkout main
git merge --no-ff compare-A -m "feat: compare-A 선택 merge"

# 비선택 옵션 worktree 정리 (cleanup subcommand 재활용)
# /worktree cleanup compare-B
# /worktree cleanup compare-C

# 선택된 옵션 worktree도 정리
# /worktree cleanup compare-A

git worktree prune
```

`--dry` 지정 시 위 명령을 출력만 하고 실행하지 않는다.

## §4 옵션 표준

| 옵션 | 설명 | 유효 subcommand |
|------|------|----------------|
| `--help` | 도움말 출력 후 즉시 종료 | 모든 |
| `--gh-pr` | setup 후 PR draft 생성 (gh 미설치 시 graceful fallback) | setup |
| `--remote=<URL>` | 다른 GitHub 레포 clone 후 worktree 생성 | setup |
| `--criteria=KEY1,KEY2,...` | 비교 기준 지표 설정 (기본값: `lines,test-pass`) — 지원: `lines`, `test-pass`, `perf`, `readability` | compare |
| `--branch-prefix=PREFIX` | compare branch 명명 prefix (기본값: `compare-`) | compare |
| `--dry` | 실제 실행 없이 명령만 출력 | 모든 |

## §5 PAB 종속성 검증

본 스킬은 어떤 git 레포에서도 동작한다. 아래 원칙을 준수한다.

- **고유 프로젝트명 하드코딩 금지** — 레포명은 `$REPO_NAME` 변수로만 참조
- **절대 경로 하드코딩 금지** — `${REPO_PARENT}/${REPO_NAME}-wt-${branch}` 형태만 허용
- **전용 환경 변수 가정 금지** — `$HOME` 외 특정 프로젝트 변수 사용 금지
- **gh CLI는 선택사항** — 미설치 시 worktree 동작에 영향 없이 안내만 출력

종속성 셀프 검증 (이 파일 자체의 §0~§4 내용에서 0건 확인):

```bash
grep -E "(PAB-SSOT-Nexus|/Users/map-rch|oceanui)" skills/worktree/SKILL.md
```

## 참조

- 상세 커맨드·시나리오·CK 체크리스트: `skills/worktree/REFERENCE.md`
