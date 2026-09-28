# Orchestration Procedure — SUB-SSOT

---

## Team Lead 역할 요약

**로딩**: SSOT 코어(entrypoint·WORKFLOW/) + `CORE/shared-definitions.md` + 본 SUB-SSOT(`orchestration-procedure.md`·`lifecycle-procedure.md`·`leader-contract.md`)

| 항목 | 내용 |
|------|------|
| **실행 위치** | 메인 세션 |
| **Charter** | `ROLES/team-lead.md` §1 |
| **코드 편집** | ❌ 절대 금지 (HR-1) |
| **핵심 역할** | 조율·판정·라우팅 |

---

## §/plan Pre-draft — 마스터 플랜 전 프롬프트 다듬기 (선택)

> **적용 규칙**: `PROMPT-QUALITY` (rules-index.md §1.20)
> **적용 시점**: 사용자가 `/plan`을 호출했을 때 — 마스터 플랜 작성·팀 생성(첫 팀원 스폰) 이전

```
/plan 호출
  → pre-draft-topics.md 작성 (docs/phases/pre/phase-{N}-pre-draft.md)
  → PROMPT-QUALITY 항목 판정
      ├─ PASS → master-plan 작성 착수
      └─ FAIL/PARTIAL → 트리아지: 진행 / 재질문 / 분할 / 취소 (pre-draft-topics.md 항목 5)
```

- 사용자와 조율할 항목(DELEGATE-4 ③)은 이 단계에서 묻는다. planner가 낸 질문 목록도 여기서 Team Lead가 사용자에게 옮긴다.

- master-plan YAML에 `prompt_quality`("full" | "fast-path")와 `pre_draft_ref`(full일 때)를 기입한다.
- 스킬: `.claude/skills/plan/SKILL.md` (Team Lead 단독)
- 템플릿: `TEMPLATES/pre-draft-topics.md`

---

## §G-A — worktree 휴리스틱 판정 의무

> **적용 규칙**: WT-6 (worktree.md §6)

### 적용 시점

다음 두 시점에 Team Lead는 **반드시** worktree 휴리스틱 판정을 수행한다:

1. **마스터 플랜 작성 시** — `/plan` 호출 직후, 또는 master-plan YAML 작성 시점
2. **Sub-Phase 진입 시** — `/phase-init` 호출 직전 (status.md 신규 생성 단계)

### 입력 신호 셋 (S1 + S5 + S6)

| 신호 ID | 출처 | 추출 방법 |
|---------|------|---------|
| **S1. 트랙 수 N** | master-plan / Sub-Phase Task 명세 | 도메인 태그 `[BE]/[FE]/[TEST]` 카운트 |
| **S5. 상태머신 분기** | status.md `current_state` | `current_state ∈ {AB_COMPARISON, REWINDING}` 여부 |
| **S6. 사용자 명시** | master-plan / Sub-Phase 본문 | `worktree: yes/no` 직접 선언 여부 |

### 판정 결과 3분 (WT-6 D2)

- **필요** — WT-1 CRITICAL 등 강제 발동 (G-C 차단, G-D FAIL 안전망 연계)
- **권장** — 회색지대, 안내만, 사용자 결정
- **불필요** — 출력 없음

우선순위: **S6 > S5 > S1** (사용자 명시 → 상태머신 → 트랙 수)

- 신호 정의의 정본은 `WORKFLOW/worktree.md` §6 D1이다. G-A 발동(`worktree_required: true`)은 계획의 병렬 트랙이 2개 이상(`expected_tracks` ≥ 2)일 때다(`WORKFLOW/worktree.md` §7 G-A).

### 판정 결과 기록

판정 결과는 다음 두 위치에 동시 기록한다:

1. **master-plan 본문**: "필요" 판정 시 한 줄 안내 (예: "worktree 필수 — 트랙 N=2 이상")
2. **phase-X-Y-status.md YAML 헤더**: `worktree_required` · `worktree_recommended` · `expected_tracks` — 필드 정의는 `WORKFLOW/workflow.md` §2.2가 정본이다

### 자동 발동 금지 (사용자 통제권 보장)

- AI(Team Lead)는 판정·기록만 수행. 실제 worktree 생성은 **G-C 강제 차단** 또는 **사용자 트리거 어휘**(§G-E 참조) 발동 시에만 진행
- "필요"만 강제, "권장"은 인지만. 자동 발동 절대 금지

### 체크리스트 (Team Lead 의무)

마스터 플랜 작성 시 / Sub-Phase 진입 시 Team Lead는 다음 순서로 수행:

- [ ] 1. S1 (트랙 수 N) 추출 — Task 도메인 태그 카운트
- [ ] 2. S5 (상태머신 분기) 점검 — status.md `current_state` 확인
- [ ] 3. S6 (사용자 명시) 확인 — master-plan/Sub-Phase 본문 `worktree: yes/no` 검색
- [ ] 4. WT-6 D3 우선순위(S6 > S5 > S1) 적용하여 3분 판정
- [ ] 5. master-plan / status.md YAML에 `worktree_required` / `worktree_recommended` / `expected_tracks` 기록
- [ ] 6. "필요" 판정 시 master-plan 본문에 한 줄 안내 작성
- [ ] 7. TASK_SPEC 전이 전 대조 — plan 병렬 트랙 수 = `expected_tracks` 개수, 2개 이상이면 `worktree_required: true`. BRANCH_CREATION 뒤에는 `worktree_paths` 개수 = `git worktree list | grep -c 'wt-phase-X-Y'`(`WORKFLOW/worktree.md` §1.1 TASK_SPEC 대조 · G-C)

---

## §G-E — VERIFYING 종료 후 차기 Phase 권고 작성 의무

> **적용 규칙**: WT-7 G-E (worktree.md §7)

### 적용 시점

VERIFYING 종료 직후 — G2 결과 파일(verifier) · G3 결과 파일(tester)을 받은 시점.

### 임계값 점검 의무

임계값 판정은 Team Lead가 한다. 결과 파일을 받는 즉시 다음 두 임계값을 점검한다 (OR 조건 — 하나라도 충족 시 권고 작성 의무 발동):

- **테스트 FAIL 비율 ≥ 30%** → "compare 권고" 작성 의무 발동
- **도달성 R ≥ 1인 룰 위반 High 이상 ≥ 5건** → "compare 권고" 작성 의무 발동

두 조건 모두 미달 시 권고 작성 생략 (불필요 — 일반 흐름).

### 권고 출력 위치 (양쪽 기록 의무)

권고는 다음 두 위치에 **동시** 기록한다:

1. **status.md YAML**: `phase-X-Y-status.md` 헤더의 `next_phase_recommendations` 필드 — 사유·옵션·트리거 어휘 명시
2. **final-summary**: `phase-X-final-summary-report.md`의 `§다음 Phase 권고` 섹션 — 본문 권고 코멘트

### 트리거 어휘

차기 Phase `/plan` 시작 시 사용자에게 다음 어휘 중 하나의 응답을 요청한다:

- `권고안 진행` → suggested_options 그대로 compare 발동
- `쉽게 진행` → 권고 무시, 일반 흐름
- `옵션 X로` → 권고 옵션 중 1개만 채택 (단일 worktree)
- `compare 진행` → 명시적 compare 호출
- 무응답 → 묵시적 거절 (일반 흐름)

### 자동 발동 금지

- AI(Team Lead)는 권고 작성·기록만 수행. 실제 worktree compare 발동은 **사용자 트리거 어휘** 입력 시에만 진행
- 무응답 = 거절로 간주 (묵시적 거절)

### 체크리스트 (Team Lead 의무)

G2 · G3 결과 파일 수신 시 Team Lead는 다음 순서로 수행:

- [ ] 1. 보고서 수신 즉시 임계값 점검 (테스트 FAIL ≥ 30% / 도달성 R ≥ 1인 High 이상 ≥ 5건)
- [ ] 2. 임계값 충족 시 status.md YAML `next_phase_recommendations` 작성 — 반드시 사유·옵션 후보(suggested_options)·트리거 어휘 모두 명시
- [ ] 3. final-summary-report.md `§다음 Phase 권고` 섹션 동시 작성
- [ ] 4. 사용자 응답에 따라 status.md `decision_at` / `decision_by` / `reason` 기록
- [ ] 5. 임계값 판정 · 권고 본문 · 옵션 결정은 **Team Lead 단독**. verifier · tester는 결과 파일만 낸다 (책임 분리)
- [ ] 6. 임계값 미달 시 권고 작성 생략 + 일반 흐름 진행 (현 Phase DONE 전이는 깨지지 않음)

---

## Phase 오케스트레이션 흐름

```
Phase 시작
  │
  ▼
[1] 팀 확인(처음 팀원을 스폰할 때 한 번 생기고 `/clear`·새 세션 뒤에도 이어지며 자동 정리되지 않는다 — `~/.claude/teams/session-<세션 id 앞 8자>/`, 별도 생성·삭제 도구 없음)
  │
  ▼
[2] 상태 진입 → 전달 게이트 통과(HANDOFF-1 · HANDOFF-4) → `Agent` 도구 — 그 상태 담당 팀원 스폰
  │   PLANNING planner(pab-planner — G4 입력까지 상주), BUILDING backend-dev · frontend-dev(pab-backend-dev · pab-frontend-dev),
  │   VERIFYING verifier(pab-verifier), TESTING tester(pab-tester)
  │   팀원 0 → 1이면 즉시 워처 arm(LIFECYCLE-6) · 스폰마다 SPAWN_GATE(스폰 → 임무 전달 → 준비 신호 대기 → 판정, LIFECYCLE-6.1)
  │
  ▼
[3] SendMessage — 작업 할당: base 세트(FRESH-6) + 업무 지시(HANDOFF-2 · DELEGATE-1~4)
  │   팀원은 한 줄 ack(COMM-1). 모든 통신은 Team Lead 경유(COMM-2)
  │
  ▼
[4] 팀원 작업 → 결과 파일(REPORT-1) + 요지 · 경로. 완료는 파일 상태로 판정(REPORT-6)
  │   G2 · G3 요청은 대상 SHA 고정(HANDOFF-6) → 다음 상태면 [2]
  │
  ▼
[5] 모든 작업 완료 → 임시 도구 폐기 · 편입 판정(TOOL-3) → shutdown_request × N → 워처 회수(LIFECYCLE-6)
  │
  ▼
[6] 팀 해산 — 전원 shutdown_request → 팀 config에 team-lead만 남았는지 확인 → 센티넬 해제 확인
  │
  ▼
Phase 완료 (DONE)
```

---

## 팀원 스폰 시 base 세트 로딩 지시

Team Lead는 팀원 스폰 시 SendMessage에 **base 세트 경로**(스폰 주입표의 그 팀원 행 — FRESH-6)를 포함한다:

```
SendMessage → planner:
  "다음 문서를 로딩하세요:
   1. WORKFLOW/handoff/common.md
   2. WORKFLOW/handoff/planning.md
   3. ROLES/planner.md
   4. ROLES/SUB-SSOT/PLANNER/planning-procedure.md
   5. CORE/shared-definitions.md
   그 밖의 SSOT가 필요하면 [SSOT 요청]을 보내세요.
   그리고 Phase X-Y 계획 분석을 시작하세요."
```

---

## §업무 지시 규약 (scoped delegation)

Team Lead는 작업 할당([3] SendMessage) 시 base 세트 로딩 지시와 함께 **업무 지시**(목표 · 경계 · 읽을 것 · 방향 가이드 · 검증 · 보고 형식 · 중단 조건 — HANDOFF-2)를 준다. 업무 지시는 아래 4규칙을 지킨다.

| 규칙 | 내용 |
|------|------|
| **DELEGATE-1 범위 좁힘** | 위임 대상을 `파일:라인` · 블록명(주석 Name) · `point-N` · 담당 구역(`PROJECT.md` §3)으로 좁혀 지정한다. "읽을 것"은 파일 전체가 아니라 그 지점을 가리킨다. |
| **DELEGATE-2 방향 가이드** | "어떻게 해라"를 함께 준다 — 접근 방향 · 해결 형태 · 참고 사례. 단순 지시 전달로 그치지 않는다. |
| **DELEGATE-3 개방형 금지** | "전체를 파악하라" 식 개방형 전체 파악 지시를 하지 않는다. 팀원은 좁힌 범위 안에서 사례·해결점을 찾는다. |
| **DELEGATE-4 업무 지시 3단계** | 과업을 받으면 ① 현행 소스 · 정본을 파일:줄로 조사하고 ② 가장 비슷한 외부 사례를 찾아 출처와 함께 적용 방향을 정하고 ③ 사용자와 조율할 항목을 질문 목록으로 만든 뒤 지시한다. planner는 ③을 Team Lead에게 넘기고 사용자에게 직접 묻지 않는다(COMM-2). 적용 대상: Team Lead · planner. ②의 검색 수단은 `ROLES/planner.md` §3.3 |

**위치 도구**: 범위 좁힘은 `docs/comment-policy/comment-policy.md`의 읽기 3단계(L1 주석·파일명 → L2 `point-N` → L3 코드 흐름)와 `scripts/comment/comment-lint.py map`으로 기계화한다. Team Lead는 map으로 블록을 특정해 위임 범위를 만든다. 이 순서는 위치를 정하는 데만 쓴다 — L1로는 결론을 내지 않는다(NOTE-5).

**정본 컴포넌트**: `[FE]` `[DS]` `[FS]` Task는 쓸 정본 컴포넌트 목록을 「읽을 것」에 넣는다. 신규 컴포넌트가 필요하면 Team Lead가 재사용 불가 사유를 심사해 먼저 `LEAD_SELECTED`로 선택한 뒤 지시한다(REUSE-2 · REUSE-3).

**판정 요청(G2 · G3)**: 요청에 대상 SHA · worktree 경로 · 기준 커밋 · 변경 파일 목록을 적는다(HANDOFF-6). G2 범위에 다른 Task 커밋이 있으면 커밋 ↔ Task 표를 더한다(`WORKFLOW/handoff/verifying.md` §3). [DOC] Task는 편집자 DoD(LOCK-7)를 붙인다. 결과 파일 결함 표의 `원인` 열로 High 이상 결함이 되풀이되는 곳을 추적한다(`WORKFLOW/handoff/verifying.md` §3).

**자문 요청**: TODO로 바꾸기 어려운 과제 · 판단이 갈리는 쟁점은 상주 planner에게 자문을 요청한다. 요청에 쟁점 · 선택지 · 판단 기준을 적고, planner는 결과 파일로 조언을 낸다. 채택은 Team Lead가 한다.

**주석 전체 정리 요청(COMMENT-3)**: 사용자가 파일(또는 파일 목록)을 지정해 요청할 때만 편성한다. Team Lead · 팀원은 발동하지 않는다 — Team Lead는 부채 레지스트리를 근거로 제안만 할 수 있다. 절차:
1. **기록** — 요청을 status 로그와 task 파일 「COMMENT-3 요청」 칸(일시 · 요청 요지 · 대상 파일 목록)에 적는다. 디렉터리 요청이면 파일 목록으로 펼쳐 사용자 확인을 받는다
2. **기준선** — Team Lead가 `python3 scripts/comment/comment-lint.py lint <파일>` 위반 수와 `scan <파일>` 분류 수를 task 파일에 적는다(구현자가 기준선을 뜨지 않는다)
3. **편성** — 대상 파일마다 담당 구역 dev(마크업 시안은 designer)에게 주석 전용 Task · 커밋으로 맡긴다. 기능 변경과 섞지 않는다
4. **판정** — verifier G2(판정 기준: `WORKFLOW/handoff/common.md` §5 COMMENT-3)
5. **레지스트리** — 부채 레지스트리에 그 파일의 파일 행을 두어(없으면 새로) 「lint 위반 0 · 정리일 · COMMENT-3 요청 근거」로 적고, 그 파일이 속한 경로 행은 `lint <행 경로>` 위반 합계와 `scan` 분류 수를 다시 재어 갱신한다(COMMENT-2 기준선 — `docs/comment-policy/comment-policy.md` §3)

---

## §서브에이전트 스코핑 (Lead 전용)

DELEGATE-1(범위 좁힘)을 Team Lead가 직접 다 읽으면 본체 컨텍스트가 부푼다. 아래 규칙으로 스코핑을 오프로드한다.

| 규칙 | 내용 |
|------|------|
| **SUBAGENT-1** | 서브에이전트 스폰은 **Team Lead 전용**이다. 팀원(pab-*)은 스폰 도구(`Agent`)가 없다 — **스폰하지 않는다.** Bash로 `claude`를 띄우는 것도 금지다. |
| **SCOPE-1** | Team Lead는 범위 좁힘을 **read-only · 일회성 · 스코핑 전용** 탐색 서브에이전트에 위임할 수 있다. `Agent` 도구로 팀 밖(서브에이전트 모드, §실행 모드 — 팀원 모드와 갈리는 정확한 기준은 실측 미확정. `team_name` 인자는 CLI가 무시하므로 그것이 기준은 아니다)에서 띄운다. 반환은 **scope map**(파일:라인 · 블록명 · `point-N` · 최소 읽을 세트)뿐이며 파일 덤프는 받지 않는다. 읽기 비용은 버리는 컨텍스트에서 소모되고 Team Lead에는 결론만 남는다. scope map을 받으면 그 서브에이전트가 종료됐는지 확인한다(서브에이전트 모드는 최종 응답과 함께 종료돼 세션을 넘어 남지 않는다). Team Lead가 scope를 확인한 뒤 구현자에게 위임한다(탐색 결론은 최종 판단이 아니다). |

**경계**: 스코핑 서브에이전트는 read-only · 일회성 · 스코핑 전용이다. 구현·게이트 판정은 Agent Team이 한다(실행 모델 불변).

---

## §실행 모드

에이전트가 보고하는 방식은 실행 모드마다 다르다.

| 모드 | 스폰 · 호출 | 보고 |
|------|------------|------|
| 팀원 | `Agent` 도구(팀 상주 — 처음 팀원 스폰 시 팀 생성, 이후 이어짐. backendType은 team-lead가 `in-process`, 팀원은 설정 `teammateMode: tmux`일 때 `tmux`) | SendMessage(Team Lead 경유 — COMM-2) |
| 서브에이전트 | `Agent` 도구 호출(Team Lead 전용 — SUBAGENT-1) | 최종 응답(호출자에게 직접 반환, SendMessage 없음) |
| headless | `claude -p --agent`(격리 런) | 결과 파일 + 최종 출력(SendMessage 없음) |

headless 격리 런에 넘기는 환경변수는 명령줄 인자가 아니라 settings `env`로 준다 — 명령줄 변수는 tmux 팀원 프로세스에 상속되지 않는다. `.claude/skills/plan` 스킬의 온디맨드 팀원 호출은 서브에이전트 모드다.

서브에이전트 · headless 모드는 SendMessage 왕복이 없다. 착수 ack(COMM-1)는 생략하고, 확인이 필요한 조작(COMM-4 범위 조정 · TOOL-6 되돌리기 어려운 조작 · 외부 게시)은 실행하지 않고 계획 · 질문을 최종 응답(headless는 결과 파일)에 적고 끝낸다.

---

## 에이전트 라이프사이클 관리

| 규칙 | 행동 |
|------|------|
| LIFECYCLE-1 | 5분 무보고 → 역할·Task 점검 → 필요 시 종료. 상주 역할(planner)은 G4 입력 제출까지 예외 |
| LIFECYCLE-2 | 할당 Task가 없거나 모두 완료된 에이전트 → 즉시 shutdown. 상주 역할(planner 또는 respawn 이름 `planner_r1`~`planner_r5`)은 G4 입력 제출까지 예외 |
| LIFECYCLE-3 | 종료 전 미완료 Task 재할당/보류 판단 |
| LIFECYCLE-4 | 팀 해산 시 전원 shutdown → 팀 config에 team-lead만 남았는지 확인(비정상 종료 멤버가 남으면 LIFECYCLE-5로 처리하고 status에 기록) → 센티넬 해제 확인 |
| LIFECYCLE-5 | 좀비 감지 + Respawn (30초/3분 check, 상한 5회) — 상세 `lifecycle-procedure.md §LIFECYCLE-5 RESPAWN` |
| LIFECYCLE-6 | 체크 스케줄러 arm/해제 + BUILDING 진입 차단 (상세 `lifecycle-procedure.md §LIFECYCLE-6 SCHEDULER`) |

> **§LIFECYCLE-5 RESPAWN · §LIFECYCLE-6 SCHEDULER 는 `lifecycle-procedure.md` 로 분리**. 본 문서는 LIFECYCLE-1~6 요약표까지만 보유한다.

---

## Phase Chain 운영

- DONE 후 `/clear` → 다음 Phase status.md 읽기 → [1]부터 반복(팀은 `/clear` 뒤에도 이어지므로 새로 생기지 않는다 — 기존 팀을 그대로 확인)
- Chain 파일: `docs/phases/phase-chain-{name}.md` (phases 배열)
- 순차 보장 (CHAIN-4), /clear 필수 (CHAIN-2)

---

## §loop 운용 절차 (팀 상주)

팀을 상주시키며 여러 Task·상태를 도는 loop의 4단 절차다.

1. **스폰** — 팀은 첫 팀원 스폰 시 자동 생성된다(팀 상주, 이어지며 새로 생기지 않는다 — 위 §Phase Chain 운영). 상태별(HANDOFF-1 대상 상태) 전달 게이트(HANDOFF-1) 통과 → 스폰 → 임무 전달 → 준비 신호 대기 → 판정(SPAWN_GATE). 팀원 0 → 1이면 스폰 직후 워처 arm(LIFECYCLE-6).
2. **보고** — 팀원이 결과를 `/tmp/agent-messages/<phase>-<role>.md`(또는 `.json`)에 기록(REPORT-1 ①A) 후 SendMessage로 경로 통지, Team Lead가 통지를 받아 회수한다(감시 도구가 있으면 보조). 완료는 메시지가 아니라 결과 파일 · 파일 상태로 판정한다(REPORT-6).
3. **게이트** — 상태별 G1~G4 판정. G2 · G3 요청은 대상 SHA를 고정한다(HANDOFF-6).
4. **정리** — 다음 Task/상태면 재스폰(재스폰 전 생존확인, `entrypoint §3.3`), Phase 종료면 임시 도구 폐기 · 편입 판정(TOOL-3) → shutdown_request × N → 워처 회수(LIFECYCLE-6) → 팀 config에 team-lead만 남았는지 확인해 해산 확인. **iteration(회전)마다 `/tmp/agent-messages/`의 직전 회전 결과 파일을 회수 후 제거**한다 — stale 결과 파일 재판독 방지.

Phase Chain 연계: DONE → `/clear` → 다음 status → [1](위 §Phase Chain 운영 — 팀은 이어지며 새로 생기지 않는다).

---

## 외부·에이전트 질의 대응

사용자/에이전트가 "코드 직접 수정" 요청 시:
1. **예외 없이** HR-1 / EDIT-2 적용
2. 직접 수정 거부
3. 규칙 안내 후 **위임**(backend-dev/frontend-dev) 또는 **역할 전환** 제시

