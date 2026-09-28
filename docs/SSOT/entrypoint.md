# SSOT 진입점

**최근 수정일**: 2026-09-22
**SSOT 버전**: ver6-6

---

## 📌 빠른 시작

### SSOT 목적

Claude Code Agent Teams 운영 문서.

- 메인 세션이 **Team Lead**로서 팀을 생성·조율·판정·해산한다.
- 팀원은 역할별 Charter([ROLES/](ROLES/) 각 파일 §1 페르소나)를 기반으로 **병렬·협업** 작업을 수행한다.
- 모든 작업은 **상태 기반 워크플로우**로 진행된다.

### 실행 환경

| 항목 | 내용 |
|------|------|
| **도구** | Claude Code Agent Teams (`Agent` 도구로 스폰 / `SendMessage`) |
| **프로젝트** | 루트 [PROJECT.md](../../PROJECT.md) §1 — 프로젝트별 설정 단일 소스 |
| **현재 Phase** | `docs/phases/phase-X-Y/phase-X-Y-status.md` — 없으면 **NO ACTIVE PHASE** (ENTRY-1) |
| **에이전트 간 출력 대기** | 팀원의 SendMessage 통지(결론 · 결과 파일 경로)를 받고 그 경로의 결과 파일을 읽는다. 감시 도구(inotifywait 등, 있으면)는 보조 수단이다 — bash sleep 폴링 금지. |

---

## 🧩 역할별 스폰 컨텍스트 주입

| 역할 | 주입 세트 (Team Lead: 전체 / 팀원: 전달 게이트 base) |
|------|------------------------------|
| **Team Lead** | [entrypoint.md](entrypoint.md) · [WORKFLOW/](WORKFLOW/) + [CORE/shared-definitions.md](CORE/shared-definitions.md) + [ROLES/SUB-SSOT/TEAM-LEAD/](ROLES/SUB-SSOT/TEAM-LEAD/) + [ROLES/team-lead.md](ROLES/team-lead.md) |
| **Planner** | [handoff/common.md](WORKFLOW/handoff/common.md) + [handoff/planning.md](WORKFLOW/handoff/planning.md) + [ROLES/planner.md](ROLES/planner.md) + [ROLES/SUB-SSOT/PLANNER/](ROLES/SUB-SSOT/PLANNER/) + [CORE/shared-definitions.md](CORE/shared-definitions.md) + `PROJECT.md` §4(규칙 오버라이드) · §6(페르소나 오버라이드) |
| **Designer** | [handoff/common.md](WORKFLOW/handoff/common.md) + [handoff/designing.md](WORKFLOW/handoff/designing.md) + [ROLES/designer.md](ROLES/designer.md) + `PROJECT.md` §3(디자인 구역) · §4(규칙 오버라이드) |
| **Backend Dev** | [handoff/common.md](WORKFLOW/handoff/common.md) + [handoff/building.md](WORKFLOW/handoff/building.md) + [ROLES/backend-dev.md](ROLES/backend-dev.md) + `PROJECT.md` §3(담당 구역) · §4(규칙 오버라이드) |
| **Frontend Dev** | [handoff/common.md](WORKFLOW/handoff/common.md) + [handoff/building.md](WORKFLOW/handoff/building.md) + [ROLES/frontend-dev.md](ROLES/frontend-dev.md) + `PROJECT.md` §3(담당 구역) · §4(규칙 오버라이드) |
| **Verifier** | [handoff/common.md](WORKFLOW/handoff/common.md) + [handoff/verifying.md](WORKFLOW/handoff/verifying.md) + [ROLES/verifier.md](ROLES/verifier.md) + [ROLES/SUB-SSOT/VERIFIER/](ROLES/SUB-SSOT/VERIFIER/) (REVIEWER 페르소나·plan-first review·컨텍스트 분리 통합) + [CORE/shared-definitions.md](CORE/shared-definitions.md) + `PROJECT.md` §4(규칙 오버라이드) · §5(품질 게이트 튜닝) · §6(페르소나 오버라이드) |
| **Tester** | [handoff/common.md](WORKFLOW/handoff/common.md) + [handoff/testing.md](WORKFLOW/handoff/testing.md) + [ROLES/tester.md](ROLES/tester.md) + [ROLES/SUB-SSOT/TESTER/](ROLES/SUB-SSOT/TESTER/) (VALIDATOR 페르소나·VAL 포맷·FAIL_COUNTER 통합) + [CORE/shared-definitions.md](CORE/shared-definitions.md) + `PROJECT.md` §4(규칙 오버라이드) · §6(페르소나 오버라이드) |

**팀원 행 = 전달 게이트 base 세트** (HANDOFF-2). 팀원은 base만 읽고, base 밖 SSOT는 Team Lead에게 요청해 추가로 읽는다(HANDOFF-3). DEV SUB-SSOT(`ROLES/SUB-SSOT/DEV/`)는 dev의 추가 로드 대상이며, 추가하면 `CORE/shared-definitions.md`도 함께 읽는다. 고르는 기준: fn 기본 개발은 `dev-entrypoint` + `fn-procedure`, 호환 분석·인프라 변경이 따르는 복잡·위험 작업은 DEV 전부, 단순 코드 수정은 `dev-entrypoint`만. 업무 지시(목표 · 경계 · 읽을 것 · 방향 가이드 · 검증 · 보고 형식 · 중단 조건 — HANDOFF-2)는 Team Lead가 스폰 시 함께 준다. 업무 지시는 **범위 좁힘 · 방향 가이드 · 개방형 "전체 파악" 금지 · 업무 지시 3단계**(DELEGATE-1~4, `ROLES/SUB-SSOT/TEAM-LEAD/orchestration-procedure.md §업무 지시 규약`)를 따른다.

**페르소나 확장**: 각 역할의 Charter는 `ROLES/*.md` §1이 정본이다. 프로젝트별 지시는 `PROJECT.md` §6 페르소나 오버라이드로 덧붙인다(덮어쓰지 않는다). SSOT 파일은 편집하지 않는다. 스폰 때는 그 페르소나의 누적 회수 · 최근 사건(`docs/persona-overrides/scoreboard.md`)도 함께 전달한다(OPS-5).

---

## 3. 코어 개념 요약

### 3.1 팀 구조

```
Team Lead (메인 세션)
  ├── planner (pab-planner / opus) — 계획 수립
  ├── designer (pab-designer / opus) — 화면 시안(HTML+CSS) · UI 설계 명세 · 디자인 조사 · 디자인 검수
  ├── backend-dev (pab-backend-dev / opus) — 백엔드 구현
  ├── frontend-dev (pab-frontend-dev / opus) — 프론트엔드 구현
  ├── verifier (pab-verifier / opus) — 코드 리뷰
  └── tester (pab-tester / opus) — 테스트 실행
```

팀원은 번들 에이전트 정의(`.claude/agents/pab-<역할>.md`)로 스폰한다. 모델과 도구는 정의가 정한다. planner·verifier는 편집 도구(Edit·Write)가 없고 Bash는 있다. **서브에이전트 스폰은 Team Lead 전용이다**(SUBAGENT-1 — 정본 `ROLES/SUB-SSOT/TEAM-LEAD/orchestration-procedure.md` §서브에이전트 스코핑). Team Lead는 범위 좁힘을 read-only 탐색 서브에이전트로 오프로드할 수 있다(SCOPE-1 — 같은 절).

**모델 정책**:

| 분류 | 모델 | 적용 역할 |
|------|------|----------|
| **opus 계열 최신** | 전 역할 (판단·설계·구현·검증) | Team Lead · Planner · Designer · Backend Dev · Frontend Dev · Verifier · Tester |

**승격 요청 방법**: backend-dev / frontend-dev / tester가 작업 복잡도·규모를 판단하여 Team Leader에게 요청. Team Leader 승인 시 해당 Task에 한해 `model: "opus 계열 최신"` 스폰.

**코드 편집 원칙**:

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **EDIT-1** | 도메인별 편집 범위 | `backend-dev`·`frontend-dev`는 각자의 담당 구역(`PROJECT.md` §3)만, `designer`는 디자인 구역(`PROJECT.md` §3, 기본 `docs/design/`)만 편집 — 화면 시안(HTML+CSS)은 디자인 구역에 만들고 제품 코드는 편집하지 않는다 |
| **EDIT-2** | Team Lead 코드 수정 금지 | Team Lead(메인 세션)는 코드를 직접 수정하지 않고 팀원에게 위임 |
| **EDIT-3** | 상태·SSOT 쓰기 독점 | `phase-X-Y-status.md`와 SSOT 문서는 Team Lead만 수정 가능 |
| **EDIT-4** | 읽기 전용 팀원 | `verifier`와 `planner`는 편집 도구(Edit·Write)가 없다. Bash로도 파일을 쓰지 않는다 (수정 필요 시 Team Lead에게 보고). REPORT-1 결과 파일(`/tmp/agent-messages/`)만 예외다 |
| **EDIT-5** | 동시 편집 금지 | 동일 파일을 두 팀원이 동시에 편집하지 않음. [FS] Task는 BE 파트 → FE 파트 순차 진행. **병렬 트랙 ≥ 2 일 때는 worktree 로 디렉토리 격리 필수 (WT-1).** |

---

### 3.2 상태 머신

```
IDLE → TEAM_SETUP
  → PLANNING → PLAN_REVIEW → DESIGN_REVIEW → TASK_SPEC
  → BRANCH_CREATION → WORKTREE_SETUP → BUILDING → VERIFYING
  → TESTING → AB_COMPARISON → (다음 Task 또는 INTEGRATION)
  → INTEGRATION → E2E → E2E_REPORT → TEAM_SHUTDOWN → DONE
```

**상태 목록**: IDLE, TEAM_SETUP, PLANNING, PLAN_REVIEW, TASK_SPEC, BUILDING, VERIFYING, TESTING, INTEGRATION, E2E, E2E_REPORT, TEAM_SHUTDOWN, BLOCKED, REWINDING, DONE, BRANCH_CREATION, WORKTREE_SETUP, AB_COMPARISON, DESIGN_REVIEW

**실패 시**: REWINDING → 이전 상태로 복귀
**차단 시**: BLOCKED → 이슈 해결 후 복귀

---

### 3.3 Hub-and-Spoke 통신 모델

**모든 팀원 통신은 Team Lead 경유**:
- 팀원 → SendMessage → Team Lead
- Team Lead → SendMessage → 특정 팀원
- 팀원끼리 직접 메시지 금지

**예시**:
1. backend-dev가 구현 완료 → SendMessage → Team Lead
2. Team Lead → SendMessage → verifier (검증 지시)
3. verifier → SendMessage → Team Lead (판정 보고)
4. Team Lead → SendMessage → backend-dev (수정 요청)

**착수 확인·소통 규칙**: 팀원은 지시 수신 즉시 한 줄 ack를 보낸다(COMM-1). 모든 통신은 Team Lead 경유다(COMM-2, Hub-and-Spoke). 정본은 `WORKFLOW/handoff/common.md §6 통신`.

**재스폰 생존확인**: 무응답 팀원을 respawn하기 전에는 «완료 미보고 vs 죽음» 판정 비대칭(`ROLES/SUB-SSOT/TEAM-LEAD/lifecycle-procedure.md §LIFECYCLE-5`)을 적용한다 — `idle_notification` 등 생존 신호가 있으면 respawn하지 않고, ZOMBIE 확정 시에만 respawn한다.

**에이전트 간 출력 대기 (SendMessage 통지 + 공유 디렉터리, 감시 도구는 선택)**:

**목적**: **전 역할**의 보고를 파일 기록 + 경로 통지로 통일한다(①A 전면, `REPORT-1`). 팀원(Bash) 실행 결과를 **bash sleep 폴링** 대신 **SendMessage 통지 수신 + 결과 파일 읽기**(감시 도구가 있으면 파일 이벤트로 보조)로 받아, 보고 잘림·미도달을 없애고 완료 시점에 바로 처리한다.

| 항목 | 내용 |
|------|------|
| **방식** | 팀원(Bash)이 결과를 **공유 디렉터리**에 쓰고 SendMessage로 경로를 통지하면, Team Lead 또는 호출 측이 통지를 받는 즉시 그 파일을 읽는다. `inotifywait`(inotify-tools) 등 감시 도구가 있으면 디렉터리 이벤트 감지로 보조할 수 있다(선택). |
| **패키지(선택)** | 감시 도구를 쓰려면 Linux는 `inotify-tools`(`apt-get install inotify-tools`), macOS는 `fswatch`(`brew install fswatch` — macOS에는 `inotify-tools`가 없다)를 설치한다. 없어도 SendMessage 통지 + 파일 읽기로 동작한다. |
| **공유 디렉터리** | **`/tmp/agent-messages/`** (또는 프로젝트·환경에 맞게 동일 경로로 통일). 에이전트 간 메시지·결과 파일을 이 디렉터리에 쓰고, 수신 측은 SendMessage 통지로 새 파일 경로를 받아 읽는다(감시 도구가 있으면 디렉터리 감시로 보조). |
| **사용 예** | 팀원(Bash)이 작업 완료 시 `/tmp/agent-messages/<task-id>.done` 또는 `<phase>-<role>.json` 등으로 결과 기록 후 SendMessage로 경로 통지. 호출 측은 통지를 받으면 **파일 내용**을 읽는다(감시 도구가 있으면 `inotifywait -m -e close_write /tmp/agent-messages/` 등으로 보조 감시 가능). |
| **결과 파일 내용** | 결과 파일은 **빈 파일이 아니어야 함**. 판정(PASS/FAIL)·요약·실패 목록 등 **내용을 반드시 포함**하여 기록. 빈 파일만 두는 것은 결과 수신으로 간주하지 않음. |
| **공식 수신 경로** | 호출 측(Team Lead 등)은 **공유 디렉터리 `/tmp/agent-messages/`**에서만 결과를 읽음. 도구 런타임의 임시 출력 경로(예: `.../tasks/<id>.output`)는 SSOT에서 정의하지 않으며, **해당 경로를 sleep 후 반복 조회하지 않음**. |
| **G3 테스트 실행** | 결과를 받으려면 **동기 실행** 권장. 백그라운드가 불가피하면 stdout을 `> /tmp/agent-messages/phase-X-Y-test.log` 등 **이 경로**로 리다이렉트한 뒤, 완료 시 **그 파일만** 읽음. |
| **테스트 요청·결과 기록(1주기)** | 요청서(목록)+결과서를 **docs/test-report/** 에 `YYMMDD-HHMM-phase-X-Y-테스트명.md` 로 저장. |

**금지**: 결과 대기를 **고정 sleep**(예: `sleep 90`)만으로 하는 패턴은 지양. SendMessage 통지 수신 + 공유 디렉터리 파일 읽기가 기본이며, 감시 도구(inotifywait·fswatch 등, 있으면)는 보조로 쓴다.

---

### 3.4 SSOT Lock Rules

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **LOCK-1** | Phase 실행 중 SSOT 변경 금지 | `current_state`가 `IDLE` 또는 `DONE`이 아닌 동안 SSOT 수정 불가 |
| **LOCK-2** | 변경 필요 시 Phase 일시정지 | SSOT 수정이 불가피하면 `current_state`를 `BLOCKED`로 전이하고 사용자에게 보고한다. `BLOCKED`에서도 수정은 막히므로, 수정은 Phase를 `DONE`으로 닫은 뒤 한다 |
| **LOCK-3** | 변경 후 리로드 필수 | SSOT 변경 후 모든 팀원에게 SendMessage로 리로드 지시 |
| **LOCK-4** | 팀원 SSOT 수정 금지 | 팀원은 SSOT를 읽기 전용으로만 참조 |
| **LOCK-5** | 변경 이력 필수 기록 | SSOT 변경 시 버전 히스토리에 반드시 기록 |
| **LOCK-6** | 정본 규율 | 규칙 ID마다 정본은 한 곳이다. `CORE/rules-index.md` 「원본」 칸이 정본 위치를 가리키고, 사본이 정본과 다르면 정본이 이긴다. 공동 정본은 두지 않는다. 역할 문서 · SUB-SSOT는 「ID + 정본 경로 + 그 역할의 적용분」만 쓰고 규칙 본문을 다시 풀어 쓰지 않는다. 사본에만 있는 조건 · 예외 · 금지는 정본으로 올린다. 정본이 역할 문서 · SUB-SSOT의 정의에 기대는 역방향 의존은 그 정의를 정본으로 올리거나, 역할 문서 · SUB-SSOT 쪽을 정본으로 등재하는 것(rules-index 행 원본 칸이 그 경로를 가리킬 때) 중 하나로 정리한다. 그 역할만 수행하는 절차는 ROLES 안에 정본을 둘 수 있고, 이때 rules-index 행의 원본 칸이 그 경로를 가리킨다. 이름 규칙(VAL · G2_be 등)도 rules-index 행을 가진다. 행 없는 ID는 행을 만들어 정의하거나 인용을 지운다. 정본 절 본문에는 규칙 ID를 적는다. 정본끼리 값이 부딪히면 Team Lead가 한쪽을 고르지 않고 사용자 결정으로 올린다. 에이전트 정의(`.claude/agents/pab-*.md`)는 본문 문장을 두고 ID 표지와 ID별 핵심어를 같은 줄에 적어 rules-index 요약과 핵심어를 맞춘다 |
| **LOCK-7** | 변경 순서 · 편집자 재확인 | 규칙을 바꾸거나 더할 때는 정본 → rules-index → ROLES · SUB-SSOT 인용 → 에이전트 정의 · 스킬 → MANIFEST 재생성 순으로 고치고, 역순으로 고치지 않는다. 편집자는 ① 영향 인용 수집(ID · 핵심 문구 grep) ② 사본 분류(인용 · 적용분 · 재서술 — 재서술은 인용으로 바꾸거나 정본과 글자를 맞춘다) ③ 짝 스캔 네 축(규칙 ID · 계열(같은 뜻의 다른 표기) · 입력물 사본(결정 · 보고서 원문) · 새 동작에서도 참인가) ④ rules-index 행 · 원본 칸 · §2 색인 동기화 ⑤ 3자 정합 표(정본 · rules-index 요약 · 인용) 작성을 G2 요청 전에 마치고, 그 결과를 G2 요청에 붙인다(편집자 DoD). 순서의 뒤 단계(예: rules-index)를 다음 커밋으로 넘기면 그 커밋을 편집자 DoD에 적는다. 단 MANIFEST 재생성은 별도 커밋이 기본이다 — 이 넘김은 편집자 DoD에 적지 않는다. 사용자 결정을 반영하는 편집이면 결정 반영표(결정 ↔ 파일:줄)를 편집자가 먼저 쓴다 — 판정자의 재현표로 대신하지 않는다. 이 DoD의 형식 확인(표 칸 수 · 코드 펜스 짝 · 링크 실재)은 검사일 뿐이고 짝 · 3자 정합 · 사실 여부 같은 내용 판정을 대신하지 않는다 |

**Lock 상태 머신**:
```
Phase 실행 중 (IDLE·DONE 외 모든 상태, BLOCKED 포함)
  │
  └── SSOT 변경 필요 발견
        → current_state = BLOCKED (사유: "SSOT 변경 필요") → 사용자 보고
        → SSOT 수정은 훅이 막는다 — Phase를 DONE으로 닫은 뒤 수정

Phase 미실행 (IDLE / DONE)
  → SSOT 수정 가능 (최근 수정일·SSOT 버전 갱신 필수)
  → SendMessage(broadcast) — "SSOT 리로드 필요" (LOCK-3)
```

**LOCK 훅** (`.claude/hooks/lock1-guard.sh`): Edit·Write 대상 경로가 활성 SSOT 경로(`ssot_path` — `hooks.env`가 정하고 기본값은 `docs/SSOT`)의 물리 경로 하위인지 판정하고, 맞으면 `docs/phases/` 아래에서 가장 최근에 수정된 `*status.md` 파일 하나의 `current_state`를 본다. `IDLE`·`DONE`만 통과시키고 나머지는 막는다. 활성 SSOT 하나만 잠그므로, 이름이 같은 다른 폴더의 SSOT 사본(백업·번들)은 이 훅으로 잠기지 않는다.

**업그레이드와 SSOT**: `install.sh --upgrade`는 `docs/SSOT/`를 번들 판으로 덮어쓴다(리팩토링 레지스트리만 보존). 프로젝트에서 고친 SSOT는 사라진다.

---

### 3.5 SSOT Freshness Rules

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **FRESH-1** | 작업 착수 전 SSOT 로딩 | 실제 작업 지시를 받으면 착수 전에 SSOT를 순서대로 로딩한다 (entrypoint → workflow). 단순 질문에는 로딩하지 않는다 |
| **FRESH-2** | 새 Phase 시작 시 버전 확인 | Phase 시작 전 entrypoint 머리의 `SSOT 버전`이 status.md `ssot_version`과 일치하는지 확인 |
| **FRESH-3** | 버전 불일치 시 갱신 우선 | SSOT 버전이 변경되었으면 Phase 진행 전 SSOT를 먼저 리로드 |
| **FRESH-4** | 리로드 시각 기록 | SSOT 로딩 완료 시 `ssot_loaded_at`에 타임스탬프 기록 |
| **FRESH-5** | 장기 세션 중 주기적 확인 | Phase가 3개 이상의 Task를 처리한 경우 SSOT 버전 재확인 권장 |
| **FRESH-6** | 팀원 역할별 로딩 | 각 팀원은 스폰 시 스폰 주입표의 자기 행(전달 게이트 base 세트)만 읽는다. 그 밖의 SSOT는 `[SSOT 요청]`으로 추가 로드한다(HANDOFF-3) |
| **FRESH-7** | 컨텍스트 복구 시 SSOT 리로드 필수 | 컨텍스트 압축·세션 중단 후 복구 시, 작업 재개 전 반드시 SSOT 리로드 + status.md 확인 + 팀 재구성. **팀 없이 코드 수정 절대 금지**. 컨텍스트 압축 뒤에는 훅이 이 규칙을 알림으로 넣는다 |
| **FRESH-8** | 리팩토링 레지스트리 관리 | ① Phase X-Y 완료(DONE) 시 코드 스캔→500줄 초과 파일을 레지스트리에 등록. ② 새 Master Plan 작성 시 레지스트리를 읽어 700줄 초과 파일을 확인. |
| **FRESH-11** | 공통 레이어 필수 | SUB-SSOT 로딩 시 `CORE/shared-definitions.md` 항상 함께 로딩. 공통 포맷(GATE, 역할, 승인, VUL) 일관성 보장 |
| **FRESH-12** | SUB-SSOT 독립 검증 | 각 SUB-SSOT는 그 역할의 base 세트(「역할별 스폰 컨텍스트 주입」 표의 자기 행)와 함께 로딩했을 때 역할 작업을 끝낼 수 있어야 한다. 참조 무결성 필수 |

---

### 3.6 ENTRYPOINT 규칙

Phase 실행의 **단일 진입점**은 `phase-X-Y-status.md` 파일이다.

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **ENTRY-1** | 단일 진입점 | 모든 Phase 작업은 `docs/phases/phase-X-Y/phase-X-Y-status.md`를 먼저 읽는 것으로 시작 |
| **ENTRY-2** | 상태 기반 분기 | `current_state` 값에 따라 다음 행동을 결정 |
| **ENTRY-3** | SSOT 버전 확인 | 진입 시 `ssot_version` 필드와 entrypoint 머리의 `SSOT 버전` 일치 여부를 확인 |
| **ENTRY-4** | Blocker 우선 확인 | `blockers` 배열이 비어있지 않으면 다른 작업보다 Blocker 해결을 우선 |
| **ENTRY-5** | 진입점 외 직접 시작 금지 | status 파일을 읽지 않고 Task 구현을 바로 시작하는 것을 금지 |

**ENTRYPOINT 플로우**:
```
세션 시작 / Phase 재개
  │
  ▼
[1] SSOT 로딩 (entrypoint → workflow) ← FRESH-1
  │
  ▼
[2] phase-X-Y-status.md 읽기 ← ENTRY-1
  │
  ▼
[3] ssot_version 확인 ← ENTRY-3
  │
  ├── 불일치 → SSOT 리로드 ← FRESH-3
  │
  ▼
[4] blockers 확인 ← ENTRY-4
  │
  ├── 비어있지 않음 → Blocker 해결 우선
  │
  ▼
[5] current_state 기반 다음 행동 결정 ← ENTRY-2
  │
  ▼
[6] 팀 상태 확인 (팀원 idle 상태 — 팀은 처음 팀원을 스폰할 때 한 번 생기고 `/clear`·새 세션 뒤에도 이어지며 자동 정리되지 않는다)
  │
  ▼
[7] 워크플로우 실행
```

---

### 3.7 품질 게이트 (G1~G4)

```
[G1: Plan Review]     planner 분석 → Team Lead 검토
  ↓
[G2: Code Review]     verifier가 BE+FE 코드 검증 → Team Lead 보고
  ↓
[G3: Test Gate]       tester가 테스트 실행 + 커버리지 확인
  ↓
[G4: Final Gate]      Team Lead가 G2+G3 종합 판정
```

**G4 판정 기준**: G2 PASS(백엔드·프론트엔드) + G3 PASS + Blocker 0건

**G4 입력**: G2 · G3 결과 파일과 planner의 계획서 이행 점검(`CORE/shared-definitions.md` §6.3 VUL3-01~05 — 계획한 것이 모두 산출됐는지 충족 · 미충족 · 이탈로 적은 표, 판정 문구 없음)이다. 판정은 Team Lead가 한다.

**세부 기준 정본**: G1 = `WORKFLOW/handoff/planning.md` §2, G2 세부 = `ROLES/SUB-SSOT/VERIFIER/verification-procedure.md` §G2 판정 기준(G2_be · G2_fe · G2_DS), G3 = `WORKFLOW/handoff/testing.md` §1. 역할 문서는 이 정본을 인용한다(LOCK-6).

**G4 판정 로직**:

```
G4 Final Gate 판정 로직:

IF (G2_backend = PASS) AND (G2_frontend = PASS)
   AND (G3 = PASS) AND (Blockers = []):
    최종 판정 = "PASS"

ELSE IF (어디든 Critical 이슈):
    최종 판정 = "FAIL"
    → REWINDING → BUILDING (계획 결함이면 PLANNING)

ELSE IF (High 이슈만 존재):
    최종 판정 = "PARTIAL"
    → Team Lead 판단:
      - 기능 차단 → FAIL
      - 개선 사항 → Technical Debt 등록 후 진행(High 이상 이관은 사용자 확인 — VP §등급 산출)
```

---

### 3.8 도메인 태그

모든 Task는 도메인 태그 필수. 태그로 구현·검증 팀원이 정해진다.

| 도메인 태그 | 설명 | 구현 팀원 | 검증 팀원 |
|-----------|------|:--------:|:-------:|
| `[BE]` | 백엔드 (API, 서비스, 미들웨어) | `backend-dev` | `verifier` + `tester` |
| `[DB]` | 데이터베이스 (스키마, 마이그레이션) | `backend-dev` | `verifier` + `tester` |
| `[DS]` | 디자인 (화면 시안 HTML+CSS · UI 설계 명세 · 디자인 트렌드 조사 · 현행 디자인 검수) | `designer` | Team Lead(`LEAD_SELECTED` 신규 컴포넌트는 `verifier` — ASSIGN-6) |
| `[FE]` | 프론트엔드 (HTML, JS, CSS) | `frontend-dev` | `verifier` + `tester` |
| `[FS]` | 풀스택 (백엔드 + 프론트 연동) | `backend-dev` + `frontend-dev` | `verifier` + `tester` |
| `[TEST]` | 테스트 전용 (테스트 코드 작성 · 실행 · 기준선 측정. 제품 코드는 수정하지 않는다) | `tester` | `verifier` |
| `[INFRA]` | 인프라 (Docker, 환경변수, CI) | `backend-dev` | `verifier` + `tester`(G2는 G2_be 준용) |
| `[DOC]` | 문서 (SSOT·규칙·가이드) | 해당 전문가 또는 Team Lead | `verifier` |

**Todo-list 작성 예시**:
```markdown
- [ ] Task X-Y-1: [BE] Admin API CRUD 구현 (Owner: backend-dev)
- [ ] Task X-Y-2: [DB] Admin 테이블 마이그레이션 (Owner: backend-dev)
- [ ] Task X-Y-3: [FE] Admin 설정 UI 페이지 구현 (Owner: frontend-dev)
- [ ] Task X-Y-4: [FS] API-UI 연동 및 데이터 바인딩 (Owner: backend-dev + frontend-dev)
- [ ] Task X-Y-5: [TEST] 통합 테스트 시나리오 작성/실행 (Owner: tester)
```

---

### 3.9 팀 라이프사이클 (루프 가능)

> 팀 상주 loop의 4단 절차(스폰 · 보고 · 게이트 · **정리** — iteration 간 `/tmp/agent-messages/` 직전 회전 결과 파일 회수·제거 포함)는 `ROLES/SUB-SSOT/TEAM-LEAD/orchestration-procedure.md §loop 운용 절차`가 정본이다.

**한 Phase 내 라이프사이클**:

```
Phase 시작
  │
  ▼
[1] 팀 확인(처음 팀원을 스폰할 때 한 번 생기고 `/clear`·새 세션 뒤에도 이어지며 자동 정리되지 않는다 — `~/.claude/teams/session-<세션 id 앞 8자>/`, 별도 생성·삭제 도구 없음) (Team Lead)
  │
  ▼
[2] 상태 진입 → 전달 게이트(HANDOFF) 통과 → `Agent` 도구(name, subagent_type, model — `team_name`·`mode` 인자는 CLI가 무시한다)  ← 그 상태 담당 팀원 스폰
  │   예: PLANNING planner (pab-planner), BUILDING backend-dev (pab-backend-dev),
  │       BUILDING frontend-dev (pab-frontend-dev), VERIFYING verifier (pab-verifier),
  │       TESTING tester (pab-tester)
  │
  ▼
[3] SendMessage로 업무 지시 전달(범위 좁힘 · 방향 가이드 — DELEGATE-1~4)  ← 작업 할당·조율
  │
  ▼
[4] 팀원이 지시대로 작업, 완료 시 SendMessage로 보고(상태 갱신은 Team Lead가 한다) → 다음 상태면 [2]
  │
  ▼
[5] 모든 작업 완료 → SendMessage(type: "shutdown_request") × N
  │
  ▼
[6] 팀 해산 확인 — 전원 shutdown_request → 팀 config에 team-lead만 남았는지 확인 → 센티넬 해제 확인 (Team Lead)
  │
  ▼
Phase 완료 (current_state: DONE)
```

**루프(다음 Phase)**:
- **단일 Phase만 실행**: DONE 도달 후 Phase 종료. 필요 시 새 Phase 시작 시 위 [1]부터 다시 진행(같은 세션이면 팀은 새로 생기지 않고 이어진다 — [1] 참고).
- **Phase Chain 사용**: `docs/phases/phase-chain-{name}.md`에 phases 배열을 정의하고, DONE 후 `/clear` → 다음 Phase의 status.md 읽기 → [1]부터 반복(팀은 `/clear` 뒤에도 이어지므로 새로 생기지 않는다 — 기존 팀을 그대로 확인).

#### 병렬 처리 정책

| 원칙 | 설명 |
|------|------|
| **완전 분리 시에만 병렬** | Backend·Frontend·Verifier 병렬은 **수정(쓰기) 파일 집합이 서로 교집합이 없을 때만** 허용. 수정(A) ∩ (수정(B) ∪ 참조(B)) = ∅ **그리고** 수정(B) ∩ (수정(A) ∪ 참조(A)) = ∅. EDIT-5 준수. |
| **신규 기능 제작 = 단일·순차** | **신규 기능 제작** Phase는 **단일 인스턴스·순차 진행** 원칙. backend-dev 1명, frontend-dev 1명, verifier 1명으로 순차 또는 BE→FE 순서 유지. 병렬 스폰은 “완전히 분리된 작업”으로 판정된 Phase에만 적용. |
| **병렬 Phase 완료 후 재검증** | 병렬 BUILDING(또는 병렬 VERIFYING)을 사용한 Phase는 **전체 작업 완료 후** Team Lead가 **재검증 절차**를 한 번 더 수행. VERIFYING → (병렬 완료) → **Phase 전체 변경 대상 통합 검증(G2)** → TESTING. |
| **Plan·Leader 작업 지시 별도** | 병렬 처리 Phase에서는 **planner**가 계획 시, **Task별 수정 파일 경로·담당 팀원**을 명시하고, 병렬 가능 쌍에 대해 **작업 지시를 트랙별로 구분**하여 출력. **Team Lead**는 BUILDING 진입 시 병렬 팀원에게 **SendMessage를 트랙별로 별도 전달** (Task A → backend-dev-1, Task B → backend-dev-2 등). |
| **Task DAG + Merge Queue** | Task 간 의존성을 **DAG(Directed Acyclic Graph)**로 명시. 의존성 없는 Task는 **병렬 실행**, 의존성 있는 Task는 **merge queue**에서 순차 대기. planner가 계획 시 Task 의존성 그래프를 `depends_on` 필드로 명시. Team Lead가 DAG 기반으로 병렬/순차 판정. |
| **Worktree 필수 (WT-1)** | 병렬 BUILDING 트랙 ≥ 2 시 `git worktree` 로 작업 디렉토리 격리 필수. **수정 파일 집합 교집합 ∅ 조건만으로는 빌드 산출물(`node_modules`·`.venv`·`__pycache__`)·`git checkout`·`git stash` 경합을 막지 못함**. 병렬 트랙 수 N 판정 후 N ≥ 2 시 Team Lead가 `BRANCH_CREATION → WORKTREE_SETUP`을 거친다 — 상태 전이 훅은 이 전이를 검사하지 않는다. worktree 생성·정리는 `/worktree` 스킬 |

#### 역할별 병렬 정책

| 담당 | 병렬 단위 | 충돌 방지 | 제한 |
|------|----------|----------|------|
| **backend-dev · frontend-dev** | 폴더 구역(`PROJECT.md` §3) 또는 화면·컴포넌트 묶음 | 수정 파일 교집합 ∅ · 같은 파일은 순차 · 빌드 산출물을 공유하면 worktree(WT-1) · 공용 모듈은 한 트랙이 먼저 만들고 나머지는 대기 | 병렬 중 build·dev 서버 금지(타입 검사까지) · 빌드를 쓰는 작업은 동시 2명 이하 |
| **designer** | 화면 묶음 | 관련 `[FE]` Task는 `[DS]` 완료 뒤 착수 · 디자인 구역만 편집하므로 BE와 병렬 가능 | 제품 코드 편집 없음 |
| **verifier** | BE·FE 나눠 검증 가능 | 병렬 BUILDING 뒤 통합 G2 재검증 | 읽기 전용 |
| **tester** | 단일 | 공유 환경(DB·서버·포트) 경합 | 동시 실행 금지 |
| **planner** | 단일 | — | — |
