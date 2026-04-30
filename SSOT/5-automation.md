# 5. 자동화 파이프라인 (5세대 신규)

> SSOT 5세대에서 도입된 Automation-first 축의 운영 규칙

---

## §1 Artifact Persister (산출물 자동 무결성 검증)

### 1.1 역할
Phase 산출물(status.md, plan.md, todo-list.md, tasks/)의 **무결성 검증**을 수행한다.

> **구현 주체**: 현재는 **Team Lead가 수동으로 검증**한다 (향후 Hook/MCP 기반 자동화 예정).
> 자동화 파이프라인이 활성화되더라도(`5th_mode.automation: true`), Artifact Persister의 검증 절차 자체는 Team Lead가 직접 실행하는 수동 프로세스이다.

### 1.2 검증 시점
- **각 상태 전이 전** 자동 실행
- Planner의 분석 결과가 SendMessage로 Team Lead에게 전달된 시점
- Team Lead가 분석 결과를 승인한 시점
- `status.md` 업데이트 시마다

### 1.3 검증 항목

| 검증 대상 | 검증 내용 | 실패 시 행동 |
|----------|----------|-------------|
| YAML frontmatter | 유효한 YAML 구문, 필수 필드 존재 | 에스컬레이션 |
| 필수 필드 존재 | `current_state`, `ssot_version`, `phase_id` 등 | 에스컬레이션 |
| 링크 유효성 | 문서 내 참조 링크가 실제 파일 가리키는지 | 경고 기록 |
| 산출물 완전성 | CHAIN-6 필수 산출물 전체 존재 | 에스컬레이션 |

### 1.4 자동 생성 대상

| 산출물 | 파일명 패턴 | 생성 시점 |
|--------|-----------|----------|
| 계획서 | `phase-X-Y-plan.md` | Planner 분석 완료 후 |
| 체크리스트 | `phase-X-Y-todo-list.md` | 계획서 생성 직후 |
| Task 명세 | `tasks/task-X-Y-N.md` | 체크리스트 생성 직후 |
| 상태 파일 | `phase-X-Y-status.md` | Phase 시작 시 |

### 1.5 CHAIN-6 자동 검증
- 산출물 생성 완료 후 **필수 산출물 체크리스트 자동 확인**:
  ```
  ✓ phase-X-Y-status.md 존재
  ✓ phase-X-Y-plan.md 존재
  ✓ phase-X-Y-todo-list.md 존재
  ✓ tasks/task-X-Y-N.md (N >= 1) 존재
  ```
- 누락 감지 시: `blocker` 이벤트 발생 + Team Lead 알림

### 1.6 실패 시 처리
- 검증 실패 시 **에스컬레이션 → Team Lead**
- 상태가 `BUILDING` 이상으로 전이되려면 모든 산출물 존재 + 검증 PASS 필수
- **자동 커밋 금지**: Team Lead 검토 완료 전까지 커밋하지 않는다
- 검토 완료 시 Team Lead가 직접 커밋 지시

---

## §2 AutoReporter (자동 보고서 생성)

### 2.1 역할
Phase 진행 상황을 **자동으로 보고서**로 생성한다.

### 2.2 보고 주기

| 트리거 | 보고 내용 | 생성 대상 |
|--------|----------|----------|
| **Task 완료 시** | Task별 완료 요약, 남은 Task 목록 | 진행 보고서 |
| **상태 전이 시** | 이전 상태 → 다음 상태, 소요 시간, 이슈 요약 | 전이 보고서 |
| **게이트 판정 시** | G0~G4 판정 결과, 점수, 이슈 목록 | 게이트 리포트 |

### 2.3 보고 형식
마크다운 테이블 기반으로 **Task별 상태, 진행률, 남은 작업**을 표시한다.

```markdown
## Phase X-Y 진행 보고서
| Task ID | 상태 | 담당 | 진행률 | 비고 |
|---------|------|------|:------:|------|
| X-Y-1   | DONE | backend-dev | 100% | |
| X-Y-2   | BUILDING | backend-dev | 60% | API 구현 중 |
| X-Y-3   | PENDING | frontend-dev | 0% | BE 의존 대기 |
```

### 2.4 저장 위치
```
docs/phases/phase-X-Y/auto-reports/
```
- 파일 명명: `{YYYYMMDD-HHMM}-{report-type}.md`
- 예: `20260228-1430-gate-G2-report.md`

### 2.5 게이트 리포트 경로 (호환)
```
docs/phases/phase-X-Y/gate-{G}-report.md
```
- 예: `docs/phases/phase-23-1/gate-G2-report.md`

### 2.6 리포트 내용 구조

```markdown
# Gate {G} Report: Phase {X-Y}

## 판정 결과
- 판정: {PASS | PARTIAL | FAIL}
- 점수: {점수}/100
- 검증 시각: {ISO8601}
- 검증 소요 시간: {분}

## 이슈 목록
| # | 심각도 | 항목 | 설명 | 파일 |
|:-:|--------|------|------|------|
| 1 | Critical | | | |

## 수정 지시
- [ ] {수정 항목 1}
- [ ] {수정 항목 2}

## 다음 행동
- {PASS}: {다음 상태}로 전이
- {PARTIAL}: AUTO_FIX 루프 진입
- {FAIL}: {이전 상태}로 복귀
```

### 2.7 리포트 보존
- 게이트 리포트는 Phase 완료 후에도 **삭제하지 않는다**
- 동일 게이트 재판정 시 기존 리포트 유지 + 새 리포트 접미사 추가
  - 예: `gate-G2-report.md`, `gate-G2-report-retry-1.md`

---

## §3 DecisionEngine (반복적 의사결정 자동화)

### 3.1 역할
반복적 의사결정을 자동화한다 (AUTO_FIX 재시도, 경미한 이슈 자동 분류).

### 3.2 자동 판정 규칙

**AUTO_FIX 적용 가능 조건** (모든 조건을 **동시에(AND)** 충족해야 함):

| # | 조건 | 설명 |
|:-:|------|------|
| 1 | G2 판정 = **PARTIAL** | FAIL이면 즉시 REWINDING (자동 판정 불가) |
| 2 | **Critical 이슈 0건** | Critical 1건 이상이면 Team Lead 필수 개입 |
| 3 | **High 이슈 1~2건** | High 3건 이상이면 Team Lead 필수 개입 |
| 4 | **아키텍처 변경 없음** | 아키텍처 구조 변경 필요 시 Team Lead 승인 필수 |
| 5 | **새 의존성 없음** | 신규 라이브러리/패키지 추가 필요 시 Team Lead 승인 필수 |
| 6 | **Security/Performance 비토 없음** | Council 비토 발동 시 자동 판정 불가 |

> **위 6가지 조건 중 하나라도 미충족 시 → 자동 판정 불가 → Team Lead 수동 에스컬레이션**

**AUTO_FIX 루프 내 재시도 규칙**:

| 상황 | 판정 | 행동 |
|------|------|------|
| 동일 이슈 1회 발생 | 자동 수정 시도 | Dev에게 수정 지시 |
| 동일 이슈 2~3회 반복 | 자동 수정 재시도 | 경고 + 수정 재지시 |
| 동일 이슈 3회 초과 반복 | **에스컬레이션** | Team Lead 강제 개입 |

### 3.3 AUTO_FIX 루프

```
G2 PARTIAL 판정
  → DecisionEngine 적용 가능성 평가
  → 적용 가능: Verifier가 Dev에게 직접 수정 지시
  → Dev 수정 완료
  → Verifier 재검증
  → (최대 3회 반복)
  → 3회 초과 시: Team Lead 강제 개입 + BLOCKED 전이
```

- **AUTO_FIX 최대 3회**: 동일 이슈에 대해 최대 3회까지만 자동 재시도
- **동일 이슈 반복 시 에스컬레이션**: 3회 초과 시 Team Lead 수동 개입

### 3.4 수동 에스컬레이션 조건

| 조건 | 사유 |
|------|------|
| **Critical 이슈** | Critical 이슈 1건 이상 시 자율 판정 불가 → Team Lead 필수 |
| **아키텍처 변경** | 기존 아키텍처 구조 변경 필요 시 → Team Lead 승인 필수 |
| **새 의존성 추가** | 신규 라이브러리/패키지 추가 시 → Team Lead 승인 필수 |
| **Security/Performance 비토** | Council 비토 발동 시 자율 판정 불가 |

### 3.5 에스컬레이션 결과 처리

| 상황 | 행동 |
|------|------|
| AUTO_FIX 1회 성공 | PASS 처리 + decision-log 기록 |
| AUTO_FIX 3회 이내 성공 | PASS 처리 + decision-log 기록 + 경고 |
| AUTO_FIX 3회 초과 | Team Lead 강제 개입 + BLOCKED 전이 |
| Critical 이슈 존재 | 자율 판정 불가 → Team Lead 필수 개입 |

### 3.6 판정 이력 기록
- 모든 자율 판정은 `decision-log.md`에 자동 저장
- 기록 항목: 시각, 판정 내용, 근거, 대안, 결과

---

## §4 자동화 활성화

### 4.1 활성화 조건
- status.md의 `5th_mode.automation: true` 설정 시 본 문서의 자동화 규칙이 **활성화**된다

### 4.2 비활성화 시 동작
- `5th_mode.automation: false` 또는 미설정 시 **수동 모드(4th 호환)**로 동작한다
- 수동 모드에서는:
  - Artifact Persister: Team Lead가 수동으로 산출물 검증
  - AutoReporter: 보고서 수동 작성
  - DecisionEngine: 모든 판정을 Team Lead가 수동 수행
  - AUTO_FIX 루프: Team Lead가 직접 수정 지시

### 4.3 설정 예시

```yaml
5th_mode:
  automation: true    # true: 자동화 활성, false: 4th 호환 수동 모드
```

### 4.4 부분 활성화
- 향후 개별 자동화 모듈(Persister, Reporter, DecisionEngine)의 독립 활성화를 지원할 수 있으나, 현재는 **일괄 활성화/비활성화**만 지원한다

---

## §5 ContextRecoveryManager (복구 절차)

### 5.1 개요
컨텍스트 압축, 세션 중단, 토큰 초과 등으로 작업이 중단된 후의 **복구 절차 가이드**이다.

> **구현 주체**: **Team Lead가 수동으로 실행**한다.
> 현재 자동 감지 메커니즘은 없으며, Team Lead가 세션 재개 시 직접 인지하고 절차를 수행한다.
> 향후 `5th_mode.event = true` 환경에서 Heartbeat/Watchdog 기반 자동 감지를 도입할 수 있으나, 현재는 수동 운영이다.

### 5.2 트리거 조건 (Team Lead 인지)

| 상황 | Team Lead 인지 방법 | 행동 |
|------|---------------------|------|
| 컨텍스트 압축 발생 | 세션 재개 시 압축 요약 메시지 확인 | FRESH-7 절차 실행 |
| 세션 중단 | 새 세션 시작 시 이전 작업 상태 불명확 | FRESH-7 절차 실행 |
| 팀원 응답 없음 | SendMessage 후 응답 미수신 | 팀원 상태 확인 → 필요 시 재스폰 |

### 5.3 FRESH-7 복구 절차 (Team Lead 수동 실행)

> **상세 절차**: `3-workflow.md §9 컨텍스트 복구 프로토콜` 참조 (7단계 정의)

본 섹션은 요약이며, 정식 절차는 3-workflow.md §9가 **권위 문서(authoritative source)**이다.

```
1. SSOT 리로드 ← FRESH-1
   → 0-entrypoint.md 읽기
   → 현재 Phase의 status.md 읽기 (ENTRY-1)
   → 5th_mode 설정 확인

2. 팀 상태 확인
   → team_name 존재 → 팀 config 읽기, idle 팀원 확인
   → team_name null → 새 팀 생성 필수 (HR-1)

3. 미완료 Task 식별
   → task_progress에서 status != "DONE" 항목 확인
   → 해당 Task의 task-X-Y-N.md 읽기

4. 업무 재분배
   → idle 팀원 → SendMessage로 작업 재개 지시
   → 팀원 없음 → 새 팀원 스폰 + Task 할당
```

### 5.4 복구 시 금지 사항
- SSOT 리로드 없이 작업 재개 **금지** (HR-3)
- 팀 없이 Team Lead가 직접 코드 수정 **금지** (HR-1)
- 산출물 생략 **금지** (HR-2)
- 이전 세션 요약만 보고 상태 추정 **금지** (ENTRY-1 위반)

### 5.5 향후 자동화 로드맵
- `5th_mode.event = true` 시 Heartbeat 프로토콜(`4-event-protocol.md §4`)과 연동하여 **자동 감지** 가능
- Watchdog SLA 기반 팀원 무응답 자동 감지 → Team Lead 알림
- 현재는 수동 운영이며, 자동화는 향후 이터레이션에서 구현 예정

---

## §6 Git Checkpoint 규칙

### 6.1 태그 명명 규칙

| 상황 | 태그 패턴 | 예시 |
|------|----------|------|
| 상태 전이 | `phase-{X}-{Y}-{state}` | `phase-23-1-BUILDING` |
| 재시도 | `phase-{X}-{Y}-{state}-retry-{N}` | `phase-23-1-BUILDING-retry-1` |
| A/B 분기 시작 | `phase-{X}-{Y}-ab-start` | `phase-23-1-ab-start` |
| A/B 분기 선택 | `phase-{X}-{Y}-ab-selected-{A|B}` | `phase-23-1-ab-selected-A` |

### 6.2 자동 태그 생성
- 상태 전이 이벤트(`state_transition`) 발생 시 자동 생성
- 태그 메시지: `"Auto-tagged by EventProtocol: {previous_state} → {next_state}"`

### 6.3 REWINDING (되감기)

```bash
# 특정 상태 시점으로 복원
git checkout phase-{X}-{Y}-{target_state}

# 복원 후 새 브랜치 생성
git checkout -b phase-{X}-{Y}-retry-{N}
```

- REWINDING 시 반드시 새 브랜치를 생성한다 (기존 브랜치 덮어쓰기 금지)

### 6.4 A/B 분기 규칙

```
A/B 분기 시작
  → git tag phase-{X}-{Y}-ab-start
  → git checkout -b phase-{X}-{Y}-branch-A
  → git checkout -b phase-{X}-{Y}-branch-B
  → 각 브랜치에서 병렬 구현
  → 비교 평가 (ab-comparison-template.md)
  → 선택된 브랜치 merge
  → 비선택 브랜치 아카이브
```

### 6.5 브랜치 보존 규칙
- **패배 브랜치 삭제 금지**
- 아카이브 위치: `archive/phase-X-Y-option-{A|B}`
- 아카이브 방법: `git branch -m phase-{X}-{Y}-branch-{B} archive/phase-X-Y-option-B`
- 아카이브된 브랜치는 향후 참조용으로 보존
