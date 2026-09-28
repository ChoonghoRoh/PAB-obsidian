# SSOT — Worktree

worktree는 git으로 개발 기능을 분리해, 메인 작업 공간과 떨어진 별도 공간에서 구현·테스트하는 격리 공간이다. 경로 `../{project}-wt-…`의 `{project}`는 저장소 폴더명이다.

| 사용 | 만드는 주체 | 규칙 |
|------|------------|------|
| 병렬 트랙 격리 (N ≥ 2) | Team Lead | WT-1 · §1 |
| REWINDING 재시도 | Team Lead | §2 |
| A/B 분기 | Team Lead | §3 |
| 팀원 자율 시험 (Spike · 교체 검증 · 이전 버전 비교 등) | 팀원 — 승인 없이 만들고 즉시 보고 | WT-8 (`handoff/common.md` §3) |

> **운영 도구**: `/worktree` 스킬 — `setup`(worktree 생성) · `cleanup`(미커밋·미push를 확인한 뒤 제거) · `audit`(worktree 상태·브랜치 중복 진단) · `compare`(옵션별 worktree 생성·결과 비교). 의존성 설치 · REWINDING 재시도 worktree · G-D 적발은 스킬이 하지 않는다. `compare`는 `../{project}-wt-compare-{옵션}` 경로와 `compare-{옵션}` 브랜치를 쓰고, 선택한 옵션을 main에 병합하며 보관 태그는 달지 않는다 — §3 A/B 분기와 별개이고 WT-2 경로 규약의 예외다.

## 1. BRANCH_CREATION → WORKTREE_SETUP

### 1.1 TASK_SPEC → BRANCH_CREATION (병렬 N ≥ 2)

> 병렬 BUILDING 트랙이 2개 이상일 때만 실행 (WT-1).

```
1. TASK_SPEC 완료 후 Team Lead: 병렬 트랙 수 N 판정 (entrypoint.md §3.9 병렬 처리 정책)
2. N ≥ 2 → current_state = "BRANCH_CREATION"
   N = 1 → BUILDING (Team Lead 지정 worktree 없음. 기능을 분리해 따로 테스트할 필요가 있으면 팀원이 WT-8로 쓴다)
3. Team Lead: git checkout -b phase-{X}-{Y}        ← 메인 저장소에서 브랜치 생성
4. current_state = "WORKTREE_SETUP"
```

**TASK_SPEC 대조** (전이 전에 Team Lead가 확인): plan의 병렬 트랙 수 = status `expected_tracks` 개수, 2개 이상이면 `worktree_required: true`. WORKTREE_SETUP 뒤에는 `worktree_paths` 개수 = `git worktree list | grep -c 'wt-phase-{X}-{Y}'`. 하나라도 어긋나면 BUILDING으로 전이하지 않는다.

### 1.2 BRANCH_CREATION → WORKTREE_SETUP (병렬 N ≥ 2 필수, WT-1)

> `BRANCH_CREATION` 다음 상태.

```
1. 각 트랙 {track} ∈ {be, fe, ver, ...} 에 대해:
   git worktree add ../{project}-wt-phase-{X}-{Y}-{track} phase-{X}-{Y}-{track}
2. 각 worktree 에서 의존성 설치 (npm ci / pip install -r requirements.txt 등) — 의존성 독립 격리 보장
3. phase-{X}-{Y}-status.md 에 worktree_paths (YAML 배열) + cleanup_wt: pending 필드 기록 (WT-5)
4. current_state = "BUILDING" (각 worktree 경로는 팀원 스폰 시 CWD 로 주입)
```

#### G-C 차단 게이트 (WT-7)

> **조건**: 병렬 트랙 N ≥ 2인데 status.md `worktree_paths: []`이면 `BUILDING`으로 전이하지 않는다. Team Lead가 지키는 절차 게이트다 — 상태 전이 훅은 worktree 필드를 보지 않는다.

```
1. Team Lead는 current_state = BUILDING 으로 전이하지 않는다
2. WORKTREE_SETUP 절차(위)를 실행한다
3. worktree_paths 가 채워진 뒤에만 BUILDING 으로 전이한다
```

| 항목 | 내용 |
|------|------|
| **확인 대상** | 병렬 트랙 N ≥ 2 + status.md `worktree_paths: []` |
| **누락 시 안전망** | G-D — verifier가 G2에서 트랙 ≥ 2인데 worktree가 없으면 **G2 FAIL** |
| **게이트 체인** | G-A(계획 시 판정 안내) → **G-C(이 게이트)** → G-D(G2) → G-E(사후 권고) — §7 |

---

## 2. REWINDING 과 worktree (WT-1 연계)

REWINDING 시 실패한 worktree 는 **보존** 하고, `retry-N` worktree 를 **추가 생성** 하여 재시도 격리를 보장한다.

```
1. phase-{X}-{Y} 실패 시점에 태깅: git tag phase-{X}-{Y}-retry-{N-1}-fail
2. retry 브랜치 생성: git checkout -b phase-{X}-{Y}-retry-{N}
3. retry worktree 추가: git worktree add ../{project}-wt-phase-{X}-{Y}-retry-{N} phase-{X}-{Y}-retry-{N}
4. 실패 worktree 는 §4 아카이브 규칙에 따라 Chain 종료까지 보존 (포렌식·롤백 용)
5. 성공 시 retry worktree 를 정본으로 채택, 실패 worktree 는 아카이브 후 제거 (WT-4)
```

## 3. A/B 분기 + worktree (WT-1, WT-4 연계)

`AB_COMPARISON` 에서 A/B 두 구현안을 병렬 수행할 때, 두 브랜치를 **각각 독립 worktree 에 격리** 한다 (WT-1 필수). 빌드 산출물·환경 변수·측정값이 교차 오염되지 않도록 의존성 독립 격리를 강제한다.

```
A/B 분기 시작
  → git tag phase-{X}-{Y}-ab-start
  → git checkout -b phase-{X}-{Y}-branch-A
  → git checkout main ; git checkout -b phase-{X}-{Y}-branch-B
  → git worktree add ../{project}-wt-phase-{X}-{Y}-ab-A phase-{X}-{Y}-branch-A        # WT-1 필수
  → git worktree add ../{project}-wt-phase-{X}-{Y}-ab-B phase-{X}-{Y}-branch-B        # WT-1 필수
  → 각 worktree 에서 병렬 구현 (CWD 격리 보장, 의존성 독립)
  → 비교 평가 (ab-comparison-template.md)
  → 선택된 브랜치 main 에 merge
  → 비선택 브랜치 worktree 제거 + 브랜치 아카이브 태깅 (WT-4)
    · git tag archive/phase-{X}-{Y}-branch-{비선택} phase-{X}-{Y}-branch-{비선택}
    · git worktree remove ../{project}-wt-phase-{X}-{Y}-ab-{비선택}
  → git worktree prune
```

## 4. 실패·비선택 브랜치 아카이브 규칙

- REWINDING 에서 실패한 브랜치와 A/B 비선택 브랜치는 **즉시 삭제하지 않는다**.
- Chain 종료 시점까지 `archive/phase-{X}-{Y}-*` 태그로 보존하며, worktree 는 WT-4 에 따라 Chain 완료 시 일괄 제거한다.
- 롤백이 필요한 경우 아카이브 태그에서 재체크아웃 후 새 worktree 를 생성한다.

## 5. Worktree 규칙 (WT-1 ~ WT-5)

병렬 BUILDING·A/B 분기·REWINDING 에서 공통 적용되는 worktree 운영 규칙.

| ID | 규칙 | 심각도 |
|----|------|--------|
| **WT-1** | **worktree 필수 조건** — 병렬 BUILDING 트랙 수 ≥ 2 일 때 worktree 없이 BUILDING 진입 금지. A/B 분기(§3)·REWINDING(§2) 에서도 적용 | CRITICAL |
| **WT-2** | **경로 규약** — `../{project}-wt-phase-{X}-{Y}-{track}` 패턴만 허용. 저장소 내부 `.worktrees/` 배치 금지 (gitignore 누락 시 재귀 노출 위험) | HIGH |
| **WT-3** | **CWD 일관성** — 팀원은 스폰 시 주입된 worktree 경로 밖에서 편집·빌드 금지. 위반 시 즉시 작업 중단·재할당. 팀원이 WT-8로 만든 자율 worktree는 그 경로가 작업 공간이다. BUILDING 단락 CWD 주입 규칙과 연계 | CRITICAL |
| **WT-4** | **수명 주기** — Phase Chain 완료 시 `git worktree remove` + `git worktree prune` 일괄 수행. 실패 브랜치(REWINDING)·A/B 비선택 브랜치는 §4 아카이브 규칙 준수 후 제거 | HIGH |
| **WT-5** | **상태 기록** — `phase-{X}-{Y}-status.md` YAML 에 `worktree_paths: []` 와 `cleanup_wt: pending\|done` 필드 필수 기록(worktree를 만들지 않는 Phase는 `null` — `WORKFLOW/workflow.md` §2.2) | MEDIUM |

## 6. WT-6 — worktree 발동 휴리스틱 룰

| 항목 | 내용 |
|------|------|
| **ID** | WT-6 |
| **심각도** | HIGH |
| **요약** | 신호 셋 S1+S5+S6 기반 worktree 발동 3분 판정 (필요/권장/불필요). 우선순위 S6 > S5 > S1. **자동 발동 금지** — 사용자 통제권 보장 (필요만 강제, 권장은 안내). |

### D1. 입력 신호 셋 (시작 셋)

| 신호 ID | 출처 | 추출 방법 | 신뢰도 |
|---------|------|----------|-------|
| **S1. 트랙 수 N** | Task 도메인 태그 `[BE]/[FE]/[TEST]` 카운트 | Task 명세 파일 grep | 높음 |
| **S5. 상태머신 분기** | status.md `current_state` | 직접 매핑: `AB_COMPARISON` / `REWINDING` → 자동 필요 | 확정 |
| **S6. 사용자 명시** | Plan/Phase 본문 `worktree: yes/no` | 사용자 직접 선언 | 확정 |

### D2. 판정 결과 카테고리 — 3분

| 카테고리 | 의미 |
|---------|------|
| **필요** | WT-1 CRITICAL 등 강제 발동 (G-C 차단, G-D FAIL) |
| **권장** | 회색지대 — 안내만, 사용자 결정 |
| **불필요** | 아무 출력 없음 |

### D3. 룰 (조건식, 우선순위 ↓)

```
[1] 사용자 명시 (S6) 우선
    worktree: yes 명시 → 강제로 "필요"
    worktree: no 명시  → 강제로 "불필요" (단 S5 만족 시 경고)

[2] 상태머신 자동 발동 (S5)
    current_state ∈ {AB_COMPARISON, REWINDING} → "필요"

[3] 트랙 수 (S1)
    N ≥ 2           → "필요"     (WT-1 CRITICAL)
    N = 1 + Task ≥ 10 → "권장"   (대형 단일 트랙도 격리 효과)
    N = 1 + Task < 10 → "불필요"

[4] 알 수 없음 (Task 명세 미작성 등)
    → "권장" + 안내 메시지로 사용자에게 판정 요청
```

### D4. 권유 vs 강제 정책

| 결과 | G-A (Plan) | G-C (BUILDING) | G-D (G2) |
|------|----------|--------------|---------|
| **필요** | 한 줄 안내 | `worktree_paths: []` 시 **차단** | 미생성 시 **FAIL** |
| **권장** | 안내+사용자 확인 요청 | 차단 없음, 경고만 | 경고 (FAIL 아님) |
| **불필요** | 출력 없음 | 통과 | 통과 |

> **핵심**: "필요"만 강제, "권장"은 인지만. **자동 발동 금지** = 사용자 통제권 유지.

## 7. WT-7 — worktree 발동 게이트 체인

| 항목 | 내용 |
|------|------|
| **ID** | WT-7 |
| **심각도** | HIGH |
| **요약** | G-A → G-C → G-D → G-E. 앞 게이트가 누락되면 다음 게이트가 적발한다. 모두 Team Lead · verifier가 지키는 절차 게이트이며 훅이 검사하지 않는다 |

### 게이트 체인 다이어그램

각 게이트는 **앞 게이트가 누락됐을 때 잡는 안전망** 역할.

```
G-A (예측)  → "필요할 것 같다" 한 줄 안내      [발견]
   ↓ 누락 시
G-C (강제) → BUILDING 진입 차단                [강제]
   ↓ 누락 시
G-D (적발) → G2 FAIL (verifier 독립 검증)     [감사]

G-E (사후) → VERIFYING 후 차기 Phase 권고      [인계]
```

### 게이트별 상세

| 게이트 | 시점 | 주체 | 입력 | 출력 | 강제력 |
|-------|------|------|------|------|--------|
| **G-A** | 계획 작성 시 | Team Lead | S1+S5+S6 · 계획의 병렬 트랙 | "worktree 필요/권장" 한 줄 안내. 병렬 트랙이 2개 이상이면 status `expected_tracks`에 트랙을 적고 `worktree_required: true` | 안내 |
| **G-C** | `BRANCH_CREATION → WORKTREE_SETUP` 전이 | Team Lead | 병렬 트랙 N ≥ 2 + status.md `worktree_paths` | `worktree_paths: []` 이면 BUILDING **차단** | **차단**(절차) |
| **G-D** | verifier G2 시 | verifier | `git worktree list` + status.md `expected_tracks` | `expected_tracks` ≥ 2 + worktree 없음 → 결함으로 적고, 등급 · 판정 규칙과 무관하게 G2 FAIL(High만 있으면 PARTIAL이라는 규칙을 적용하지 않는다). 순차 Phase(`expected_tracks` < 2)는 대상이 아니다 | **FAIL** |
| **G-E** | VERIFYING 종료 직후 | Team Lead (verifier · tester는 결과 파일을 낸다) | G2/G3 결과 + 임계값 (FAIL 30%/R ≥ 1인 High 이상 5건) | `next_phase_recommendations` YAML + final-summary §섹션 | 안내 (차기 Phase 인계) |

### G-E 사후 권고 절차 (D/E 케이스 전용)

D/E 케이스(기능 개발 실패, 1차 품질 낮음)는 사전 휴리스틱으로 잡히지 않으며, **사람의 주관 평가**가 필요한 영역. AI는 권고만 작성하고 차기 Phase로 인계한다.

```
1. G2 결과 파일(verifier) · G3 결과 파일(tester) 완료
2. 임계값 판정은 Team Lead가 한다:
   - 테스트 FAIL 비율 ≥ 30% → "compare 권장"
   - 도달성 R ≥ 1인 룰 위반 High 이상 ≥ 5건 → "compare 권장"
3. 권고 코멘트 생성 → status.md YAML + final-summary-report.md 양쪽 기록
4. 현 Phase DONE 전이 (현 Phase는 깨지지 않음)
   ───────────────────────────────────────────────
5. 사용자 결정 (트리거 어휘):
   - "권고안 진행"   → suggested_options 그대로 compare 발동
   - "쉽게 진행"     → 권고 무시, 일반 흐름
   - "옵션 X로"      → 권고 옵션 중 1개만 채택 (단일 worktree)
   - "compare 진행"  → 명시적 compare 호출
   - 무응답          → 묵시적 거절 (일반 흐름)
6. status.md에 결정 기록 (decision_at, decision_by, reason)
```
