# SSOT — 프로젝트 정의

**버전**: 7.0-renewal-5th
**최종 수정**: 2026-02-28
**특징**: 단독 사용 (다른 SSOT 폴더 참조 불필요) + **5세대 혁신 5축 확장** (Research Team, 11명 Verification Council, Event Protocol, Automation, Git Checkpoint)

---

## 1. 프로젝트 정의

| 항목 | 내용 |
|------|------|
| **프로젝트명** | Personal AI Brain v3 |
| **목적** | 로컬 설치형 개인 AI 브레인 — 문서 벡터화, 의미 검색, AI 응답, 지식 구조화, Reasoning |
| **배포 형태** | Docker Compose (On-Premise, 폐쇄망 동작 필수) |
| **현재 Phase** | Phase 21 진행 중 (Chain 21: 21-1 DONE, 21-2 DONE, 21-3 TESTING) |
| **실행 환경** | Claude Code Agent Teams (TeamCreate / SendMessage / TaskList) |

---

## 2. 팀 구성

### 2.1 Agent Teams 구조

```
┌─────────────────────────────────────────────────────────────────────┐
│               Team Lead + Orchestrator (메인 세션)                    │
│  Charter: LEADER.md                                                  │
│  역할: TeamCreate → 팀원 스폰 → SendMessage 조율 → 판정 → TeamDelete │
│  코드 편집: ❌ 금지 (조율·판정·통신 허브)                             │
└──┬──────────┬──────────────┬──────────────┬──────────────┬──────────┘
   │          │              │              │              │
┌──▼───┐ ┌───▼──────────┐ ┌─▼──────────┐ ┌▼──────────┐ ┌▼─────────┐
│plan- │ │backend-dev   │ │frontend-   │ │verifier   │ │tester   │
│ner   │ │              │ │dev         │ │           │ │         │
│      │ │Charter:      │ │Charter:    │ │Charter:   │ │Charter: │
│opus  │ │BACKEND.md    │ │FRONTEND.md │ │QA.md      │ │QA.md    │
│      │ │              │ │            │ │           │ │         │
│읽기  │ │**코드 편집** │ │**코드 편집**│ │읽기 전용  │ │Bash 전용│
│전용  │ │**가능**      │ │**가능**    │ │           │ │         │
│      │ │sonnet        │ │sonnet      │ │sonnet     │ │sonnet   │
└──────┘ └──────────────┘ └────────────┘ └───────────┘ └─────────┘
           ↕ 모든 통신은 Team Lead 경유 (Hub-and-Spoke) ↕

── [5th 확장] Research Team (선택적, 5th_mode.research = true 시) ──
┌──────────────┐ ┌──────────────────┐ ┌──────────────────┐
│research-lead │ │research-architect│ │research-analyst  │
│              │ │                  │ │                  │
│Explore/opus  │ │Explore/opus      │ │Explore/sonnet    │
│조사 총괄     │ │아키텍처 탐색     │ │코드베이스 분석   │
│읽기 전용     │ │읽기 전용         │ │읽기 전용         │
└──────────────┘ └──────────────────┘ └──────────────────┘
```

### 2.2 역할-실행 매핑

| 역할 | Charter | 팀원 이름 | `subagent_type` | `model` | 코드 편집 | 담당 도메인 |
|------|---------|----------|:---------------:|:-------:|:--------:|:----------:|
| **Team Lead** | `LEADER.md` | — (메인 세션) | — | opus | ❌ | — (조율·판정) |
| **Research Lead** | — | `research-lead` | `Explore` | opus | ❌ | — (조사 총괄) |
| **Research Architect** | — | `research-architect` | `Explore` | opus | ❌ | — (아키텍처 탐색) |
| **Research Analyst** | — | `research-analyst` | `Explore` | sonnet | ❌ | — (코드 분석) |
| **Planner** | — (고유) | `planner` | `Plan` 또는 `Explore` | opus | ❌ | — (계획 수립) |
| **Backend Developer** | `BACKEND.md` | `backend-dev` | `general-purpose` | sonnet | ✅ | `[BE]` `[DB]` `[FS]`(BE) |
| **Frontend Developer** | `FRONTEND.md` | `frontend-dev` | `general-purpose` | sonnet | ✅ | `[FE]` `[FS]`(FE) |
| **Verifier** | `QA.md` | `verifier` | `Explore` | sonnet | ❌ | — (코드 리뷰) |
| **Tester** | `QA.md` | `tester` | `Bash` | sonnet | ❌ | — (테스트 실행) |

*backend-dev·frontend-dev: 리팩토링 관련 큰 업무 시 **opus 최신 버전** 사용 (§7.2).*
*Research Team (research-lead, research-architect, research-analyst): **5th 전용**, `5th_mode.research = true` 시에만 스폰.*

**코드 편집 원칙**:
- Team Lead는 코드를 직접 수정하지 않는다 (조율·판정·통신 허브)
- `backend-dev`는 `backend/`, `tests/`, `scripts/` 편집
- `frontend-dev`는 `web/`, `e2e/` 편집
- `verifier`는 읽기 전용 (수정 필요 시 Team Lead에게 보고)

---

### 2.3 역할별 상세

#### Team Lead + Orchestrator (메인 세션)

| 항목 | 내용 |
|------|------|
| **Charter** | [LEADER.md](PERSONA/LEADER.md) (4th PERSONA) |
| **핵심 역할** | 팀 생성·해산, 워크플로우 지휘, 상태 관리, 최종 판정, 통신 허브 |
| **권한** | TeamCreate, TeamDelete, SendMessage, Task tool, 파일 읽기, Git, Bash |
| **책임** | Phase 상태 관리, 판정 결정(PASS/FAIL/PARTIAL), Task 할당, 팀원 조율, 이슈 해결 |
| **금지** | **코드 직접 수정 금지** — 모든 코드 작성은 `backend-dev` 또는 `frontend-dev`에게 위임 |

<details>
<summary>상세 가이드</summary>

- **SSOT 리로드 필수**: 세션 시작 시 FRESH-1 규칙 적용 (0→1→2→3 순서)
- **ENTRYPOINT 진입**: `phase-X-Y-status.md` 읽기 → `current_state` 확인 → 다음 행동 결정
- **상태 전이 책임**: IDLE → TEAM_SETUP → PLANNING → ... → DONE 전체 관장
- **판정 권한**: G1~G4 게이트 최종 판정 (PASS/FAIL/PARTIAL)
- **통신 허브**: 모든 팀원의 SendMessage를 받아 라우팅
- **PLANNING 산출물 생성**: planner는 쓰기 권한이 없으므로 **planner의 SendMessage 수신 후** Team Lead가 `phase-X-Y/`에 plan.md, todo-list.md, tasks/ 파일을 생성한다. phase-X-Y/ 디렉터리 폴링(sleep + ls)으로 "산출물 대기"하지 않음. ➜ [3-workflow.md §3.2 PLANNING→PLAN_REVIEW](3-workflow.md#planning--plan_review-planner-결과-수신-및-산출물-생성)
- **직접 수정 요청 대응**: 사용자·에이전트가 "코드 직접 수정"을 요청해도 예외 없이 EDIT-2·HR-1 적용. 직접 수정하지 않고, 규칙 안내 후 위임/역할 전환 옵션 제시. ➜ [§7.5](#75-외부에이전트-질의-시-team-lead-직접-수정-요청-대응)

➜ [0-entrypoint.md](0-entrypoint.md) §3 팀 라이프사이클·Lock·Freshness

</details>

---

#### Planner (팀원: `planner`)

| 항목 | 내용 |
|------|------|
| **팀원 이름** | `planner` |
| **실행 방법** | `Task tool` → `team_name`, `name: "planner"`, `subagent_type: "Plan"`, `model: "opus"` |
| **핵심 역할** | 요구사항 분석, 영향 범위 탐색, 계획 수립, Task 분해 (3~7개) |
| **권한** | 파일 읽기, 검색 (Glob, Grep, Read) — 쓰기 권한 없음 |
| **입력** | master-plan, navigation, 이전 Phase summary |
| **출력** | plan + todo-list (도메인 태그 포함)를 SendMessage로 Team Lead에게 전달 |

<details>
<summary>상세 가이드</summary>

- **Task 분해 전략**: 3~7개로 분해 (너무 많지 않게)
- **도메인 태그 필수**: `[BE]` `[FE]` `[FS]` `[DB]` 명시
- **완료 기준**: Done Definition 구체적으로 작성
- **리스크 식별**: 기술적 난이도, 의존성 명시

➜ [ROLES/planner.md](ROLES/planner.md) · [_backup/GUIDES/planner-work-guide.md](_backup/GUIDES/planner-work-guide.md)

</details>

---

#### Research Team (5th 확장 — 선택적)

> **활성화 조건**: `5th_mode.research = true` 시에만 스폰. 미설정 시 TEAM_SETUP → PLANNING으로 직행 (4th 호환).

| 역할 | 팀원 이름 | `subagent_type` | `model` | 핵심 역할 |
|------|----------|:---------------:|:-------:|----------|
| **Research Lead** | `research-lead` | `Explore` | opus | 조사 총괄, Research Team 지휘, G0 산출물 품질 관리 |
| **Research Architect** | `research-architect` | `Explore` | opus | 아키텍처 대안 탐색, 기술 스택 비교, PoC 설계 |
| **Research Analyst** | `research-analyst` | `Explore` | sonnet | 기존 코드베이스 분석, 의존성·영향 범위 조사, 데이터 수집 |

**Research Team 라이프사이클**:
1. TEAM_SETUP 완료 후 Research Team 스폰
2. `RESEARCH` 상태 진입: research-lead가 조사 범위 정의 → research-architect + research-analyst 병렬 탐색
3. 조사 완료 → research-lead가 통합 보고서를 SendMessage로 Team Lead에게 전달
4. `RESEARCH_REVIEW(G0)` 상태 진입: Team Lead가 G0 게이트 판정
5. G0 PASS → PLANNING 진입. G0 FAIL → REWINDING → RESEARCH

**산출물**: 기술 조사 보고서, 아키텍처 대안 비교표, 리스크 분석, PoC 결과(선택)

**11명 Verification Council 참조**: 다관점 품질 검증이 필요한 경우 → [QUALITY/10-persona-qc.md](QUALITY/10-persona-qc.md)

---

#### Backend Developer (팀원: `backend-dev`)

| 항목 | 내용 |
|------|------|
| **Charter** | [BACKEND.md](PERSONA/BACKEND.md) (4th PERSONA) |
| **팀원 이름** | `backend-dev` |
| **실행 방법** | `Task tool` → `team_name`, `name: "backend-dev"`, `subagent_type: "general-purpose"`, `model: "sonnet"` |
| **핵심 역할** | API, DB, 서비스 로직 구현 — **코드 편집 가능** |
| **권한** | 파일 읽기/쓰기/편집, Bash, Glob, Grep, Read |
| **담당 범위** | `backend/`, `tests/`, `scripts/` 디렉토리 |
| **담당 도메인** | `[BE]` `[DB]` `[FS]`(백엔드 파트) |

<details>
<summary>필수 준수 사항</summary>

| 규칙 | 설명 |
|------|------|
| **ORM 필수** | raw SQL 절대 금지, SQLAlchemy ORM만 사용 |
| **Pydantic 검증** | 모든 API 입력은 Pydantic 스키마로 검증 |
| **타입 힌트** | 함수 파라미터 + 반환 타입 힌트 필수 |
| **에러 핸들링** | try-except + HTTPException 패턴 |
| **Team Lead 경유 통신** | 구현 완료 시 SendMessage로 Team Lead에게만 보고 |

➜ [ROLES/backend-dev.md](ROLES/backend-dev.md)

</details>

---

#### Frontend Developer (팀원: `frontend-dev`)

| 항목 | 내용 |
|------|------|
| **Charter** | [FRONTEND.md](PERSONA/FRONTEND.md) (4th PERSONA) |
| **팀원 이름** | `frontend-dev` |
| **실행 방법** | `Task tool` → `team_name`, `name: "frontend-dev"`, `subagent_type: "general-purpose"`, `model: "sonnet"` |
| **핵심 역할** | UI/UX 분석 + 구현 — **코드 편집 가능** |
| **권한** | 파일 읽기/쓰기/편집, Bash, Glob, Grep, Read |
| **담당 범위** | `web/`, `e2e/` 디렉토리 |
| **담당 도메인** | `[FE]` `[FS]`(프론트엔드 파트) |

<details>
<summary>필수 준수 사항</summary>

| 규칙 | 설명 |
|------|------|
| **ESM import/export** | `type="module"` 필수 |
| **innerHTML + esc()** | XSS 방지 필수 |
| **외부 CDN 금지** | 모든 리소스는 로컬에서 제공 (`web/public/libs/`) |
| **window 전역 금지** | 기존 것 제외하고 새로 할당 금지 |
| **Team Lead 경유 통신** | 구현 완료 시 SendMessage로 Team Lead에게만 보고 |

➜ [ROLES/frontend-dev.md](ROLES/frontend-dev.md)

</details>

---

#### Verifier (팀원: `verifier`)

| 항목 | 내용 |
|------|------|
| **Charter** | [QA.md](PERSONA/QA.md) (4th PERSONA) |
| **팀원 이름** | `verifier` |
| **실행 방법** | `Task tool` → `team_name`, `name: "verifier"`, `subagent_type: "Explore"`, `model: "sonnet"` |
| **핵심 역할** | 코드 리뷰, 품질 게이트(G2) 판정 — **읽기 전용** |
| **권한** | 파일 읽기, 검색 — 쓰기·편집 권한 없음 |
| **입력** | Team Lead가 SendMessage로 전달한 변경 파일 목록, 완료 기준 |
| **출력** | 검증 결과 (PASS/FAIL/PARTIAL + 이슈 목록)를 SendMessage로 Team Lead에게만 반환 |

<details>
<summary>판정 기준</summary>

| 조건 | 판정 |
|------|------|
| Critical 1건 이상 | **FAIL** |
| Critical 0건, High 있음 | **PARTIAL** |
| Critical 0, High 0 | **PASS** |

**Critical (필수 통과)**:
- 구문 오류 없음
- ORM 사용 (raw SQL 없음)
- Pydantic 검증 존재
- innerHTML 시 esc() 적용
- 외부 CDN 없음
- 기존 테스트 깨지지 않음

➜ [ROLES/verifier.md](ROLES/verifier.md)

</details>

---

#### Tester (팀원: `tester`)

| 항목 | 내용 |
|------|------|
| **Charter** | [QA.md](PERSONA/QA.md) (4th PERSONA) |
| **팀원 이름** | `tester` |
| **실행 방법** | `Task tool` → `team_name`, `name: "tester"`, `subagent_type: "Bash"`, `model: "sonnet"` |
| **핵심 역할** | 테스트 실행, 커버리지 분석, 품질 게이트(G3) 판정 |
| **권한** | Bash 명령 실행 (pytest, playwright 등) |
| **입력** | Team Lead가 SendMessage로 전달한 테스트 범위, 명령 |
| **출력** | 테스트 결과를 SendMessage로 Team Lead에게 반환 |

<details>
<summary>테스트 명령 · 선택적 실행 원칙</summary>

**원칙: 전체 테스트 실행(`pytest tests/`)은 불필요하다.** 변경한 코드에 영향받는 테스트만 선택 실행한다. ➜ [docs/tests/index.md](../../tests/index.md)

- **phase-x-Y 단계**: [docs/tests/index.md §1](../../tests/index.md)에서 변경 시나리오(A~I)를 확인하고 해당 테스트만 실행. Team Lead는 테스트 요청 시 **변경 도메인/파일**을 명시한다.
- **phase-x-Y 완료 후**: 빠른 회귀 (`-m "not llm and not integration"`, ~2분)
- **Phase X 전체 완료**: LLM 포함 회귀 (`-m "not integration" --timeout=60`, ~6분)
- **병렬(동시) 금지 — Ollama/AI 테스트**: 단일 pytest로 실행. ➜ [ROLES/tester.md](ROLES/tester.md) §4.1

```bash
# [선택] 시나리오 확인 후 해당 테스트만 (예: Reasoning 변경 시)
OLLAMA_BASE_URL=http://192.168.0.22:11434 \
pytest tests/test_reasoning_api.py tests/test_reason_document.py --tb=short -v

# [빠른 회귀] phase-x-Y 완료 후 (~2분)
pytest tests/ -m "not llm and not integration" --tb=short -q

# [LLM 회귀] Phase X 전체 완료 시 (~6분)
OLLAMA_BASE_URL=http://192.168.0.22:11434 \
pytest tests/ -m "not integration" --tb=short -q --timeout=60

# E2E
npx playwright test e2e/phase-X-Y.spec.js
npx playwright test e2e/smoke.spec.js e2e/phase-*.spec.js
```

➜ [ROLES/tester.md](ROLES/tester.md) §3.5, [docs/tests/index.md](../../tests/index.md)

</details>

---

## 3. 팀 라이프사이클

```
Phase 시작
  │
  ▼
[1] TeamCreate(team_name: "phase-X-Y")  ← 팀 생성 (Team Lead)
  │
  ▼
[1.5] (5th) Research Team 스폰 (5th_mode.research = true 시) ← 선택적
  │   Task(research-lead, Explore/opus), Task(research-architect, Explore/opus),
  │   Task(research-analyst, Explore/sonnet)
  │   → RESEARCH → RESEARCH_REVIEW(G0) 통과 후 PLANNING
  │
  ▼
[2] Task tool(team_name, name, subagent_type, model) × N  ← 팀원 스폰
  │   예: Task(team_name: "phase-15-1", name: "planner", subagent_type: "Plan", model: "opus")
  │       Task(team_name: "phase-15-1", name: "backend-dev", subagent_type: "general-purpose", model: "sonnet")
  │
  ▼
[3] TaskCreate → TaskUpdate(owner) → SendMessage  ← 작업 할당·조율
  │
  ▼
[4] 팀원들이 TaskList로 작업 확인, 완료 시 TaskUpdate(completed) + SendMessage 보고
  │
  ▼
[5] 모든 작업 완료 → SendMessage(type: "shutdown_request") × N
  │
  ▼
[6] TeamDelete  ← 팀 해산 (Team Lead)
  │
  ▼
Phase 완료 (current_state: DONE)
```

**루프**: DONE 후 다음 Phase 실행 시 [1] TeamCreate부터 반복. Phase Chain 사용 시 [3-workflow.md § Phase Chain](3-workflow.md#phase-chain-자동-순차-실행) 참조.

**지연 스폰**: verifier, tester는 VERIFYING/TESTING 단계 진입 시 스폰 (비용 절감).

### 3.1 Research Team 스폰 프로토콜 (5th 확장)

> **활성화 조건**: status.md의 `5th_mode.research = true` 시에만 실행. 미설정 시 Step [1.5]를 건너뛰고 Step [2]로 직행 (4th 호환).

```
[1] TeamCreate 완료
  │
  ▼
[1.5a] 5th_mode.research 확인
  │
  ├── false → Step [2] 직행 (4th 호환)
  │
  ▼ true
[1.5b] Research Team 스폰 (3인)
  │   Task(team_name, name: "research-lead", subagent_type: "Explore", model: "opus")
  │   Task(team_name, name: "research-architect", subagent_type: "Explore", model: "opus")
  │   Task(team_name, name: "research-analyst", subagent_type: "Explore", model: "sonnet")
  │
  ▼
[1.5c] current_state = "RESEARCH"
  │   research-lead: 조사 범위 정의 → Team Lead 승인
  │   research-architect + research-analyst: 병렬 탐색
  │   research-lead: 결과 통합 → SendMessage(Team Lead)
  │
  ▼
[1.5d] current_state = "RESEARCH_REVIEW" (G0 게이트)
  │   Team Lead: G0 판정
  │   ├── PASS → Step [2] (PLANNING 진입)
  │   └── FAIL → REWINDING → RESEARCH 재실행
  │
  ▼
[2] 일반 팀원 스폰 (planner, backend-dev, frontend-dev...)
```

**Research Team 산출물**:
- `research-report.md` — 기술 선택 근거, 아키텍처 대안 비교(2개+), 영향 범위 식별, 리스크 완화 방안
- G0 PASS 기준: 기술 선택 근거 충분, 영향 범위 식별 완료, 리스크 완화 방안 포함, 대안 검토 완료

### 3.2 11명 Verification Council (5th 확장)

> **활성화 조건**: `5th_mode.multi_perspective = true` 시 G4 통합 검수에 적용.

G4 통합 검수 시 11개 전문 관점에서 병렬 검증하여 다관점 품질을 확보한다. 비용 최적화를 위해 동적 5~6명을 선택한다.

| # | 페르소나 | 핵심 검증 항목 | 비토 권한 |
|:-:|---------|--------------|:---------:|
| 1 | **Security Auditor** | SQL Injection, XSS, CSRF, 암호화, 인증/인가 | **Yes** |
| 2 | **Performance Engineer** | N+1 쿼리, 메모리 누수, 캐싱, 응답 시간 | **Yes** |
| 3 | **Backend Architect** | ORM, 트랜잭션, 에러 처리, API 일관성 | No |
| 4 | **Frontend Specialist** | ESM 모듈, XSS 방지, 렌더링, 접근성 기본 | No |
| 5 | **Database Expert** | 인덱스, 정규화, 쿼리 최적화, 마이그레이션 | No |
| 6 | **Test Engineer** | 커버리지, 엣지 케이스, 테스트 품질 | No |
| 7 | **Accessibility Expert** | WCAG 2.1, 키보드 네비게이션, 스크린 리더 | No |
| 8 | **DevOps Engineer** | Docker, 로그, 배포, 환경 설정 | No |
| 9 | **Code Quality Reviewer** | 복잡도, 가독성, 네이밍, 중복 | No |
| 10 | **User Advocate** | UX, 에러 메시지, 사용자 동선, 직관성 | No |
| 11 | **Data Integrity Specialist** | 데이터 정합성, 마이그레이션 안전, 외래키 | No |

**동적 선택 규칙**: 필수(Security, Performance, Test Engineer) + 도메인 기반([BE]→Backend Architect+DB Expert, [FE]→Frontend Specialist+Accessibility Expert) + Phase 특성(리팩토링→Code Quality, UI→User Advocate).

**합성 규칙**: Security/Performance FAIL → 즉시 FAIL (비토). 나머지 가중치 기반 점수(85점+ PASS, 70~84 PARTIAL, <70 FAIL).

➜ [상세: QUALITY/10-persona-qc.md](QUALITY/10-persona-qc.md)

---

## 4. Hub-and-Spoke 통신 모델

모든 팀원 간 통신은 **Team Lead를 경유**한다. 팀원끼리 직접 메시지를 주고받지 않는다.

```
       planner
          ↕
backend-dev ← → Team Lead ← → frontend-dev
          ↕                ↕
       verifier          tester
```

**통신 원칙**:
1. 팀원은 `SendMessage(team_name, recipient: "team-lead", ...)`로 Team Lead에게만 보고
2. Team Lead는 `SendMessage(team_name, recipient: "backend-dev", ...)`로 특정 팀원에게 전달
3. 팀원끼리 직접 통신 금지

---

## 5. Task 도메인 분류

각 Task는 도메인 태그를 명시하여 적절한 팀원이 구현/검증한다.

| 도메인 태그 | 설명 | 구현 팀원 | 검증 팀원 |
|-----------|------|:--------:|:-------:|
| `[BE]` | 백엔드 (API, 서비스, 미들웨어) | `backend-dev` | `verifier` + `tester` |
| `[DB]` | 데이터베이스 (스키마, 마이그레이션) | `backend-dev` | `verifier` + `tester` |
| `[FE]` | 프론트엔드 (HTML, JS, CSS) | `frontend-dev` | `verifier` + `tester` |
| `[FS]` | 풀스택 (백엔드 + 프론트 연동) | `backend-dev` + `frontend-dev` | `verifier` + `tester` |
| `[TEST]` | 테스트 전용 (테스트 코드 작성) | `tester` | `verifier` |
| `[INFRA]` | 인프라 (Docker, 환경변수, CI) | `backend-dev` | — |

**Todo-list 작성 예시**:
```markdown
- [ ] Task X-Y-1: [BE] Admin API CRUD 구현 (Owner: backend-dev)
- [ ] Task X-Y-2: [DB] Admin 테이블 마이그레이션 (Owner: backend-dev)
- [ ] Task X-Y-3: [FE] Admin 설정 UI 페이지 구현 (Owner: frontend-dev)
- [ ] Task X-Y-4: [FS] API-UI 연동 및 데이터 바인딩 (Owner: backend-dev + frontend-dev)
- [ ] Task X-Y-5: [TEST] 통합 테스트 시나리오 작성/실행 (Owner: tester)
```

---

## 6. 품질 게이트 정의

### 6.1 게이트 구조 (G0~G4 — 5th 확장)

```
[G0: Research Review] ← 5th 신규. Research Team 조사 결과 검증 (5th_mode.research = true 시)
        ↓
[G1: Plan Review]     planner 분석 → Team Lead 검토
        ↓
[G2: Code Review]     verifier가 BE+FE 코드 검증 (→ Team Lead 보고)
        ↓
[G3: Test Gate]       tester가 테스트 실행 + 커버리지 확인 (→ Team Lead 보고)
        ↓
[G4: Final Gate]      Team Lead가 G2+G3 종합 판정
```

**G0 판정 기준** *(5th 신규)*:
- 기술 조사 완료, 아키텍처 대안 2개+, 리스크 분석 포함, PoC 결과(선택) 첨부
- PASS → PLANNING 진입. FAIL → RESEARCH 재실행

### 6.2 게이트별 통과 기준

| 게이트 | 백엔드 기준 | 프론트엔드 기준 | 공통 기준 |
|--------|-----------|--------------|----------|
| **G1** | API Spec 확정, DB 스키마 정의 | 페이지 구조/동선 정의 | 완료 기준 명확, Task 3~7개, 리스크 식별 |
| **G2** | Critical 0건, ORM 사용, 타입 힌트 | CDN 미사용, ESM, innerHTML+esc() | 보안 취약점 없음 |
| **G3** | pytest PASS, 커버리지 ≥80% | 페이지 로드 OK, 콘솔 에러 0건 | 회귀 테스트 통과 |
| **G4** | G2 PASS + G3 PASS | G2 PASS + G3 PASS | Blocker 0건 |

### 6.3 판정 기준

```
G4 Final Gate 판정 로직:

IF (G2_backend = PASS) AND (G2_frontend = PASS)
   AND (G3 = PASS) AND (Blockers = []):
    최종 판정 = "PASS"

ELSE IF (어디든 Critical 이슈):
    최종 판정 = "FAIL"
    → 해당 게이트로 리와인드

ELSE IF (High 이슈만 존재):
    최종 판정 = "PARTIAL"
    → Team Lead 판단:
      - 기능 차단 → FAIL
      - 개선 사항 → Technical Debt 등록 후 진행
```

---

## 7. 에이전트 팀 운용 원칙

| 원칙 | 설명 |
|------|------|
| **팀 생성** | Phase 시작 시 `TeamCreate(team_name: "phase-X-Y")`로 팀 생성 |
| **팀원 스폰** | `Task tool`에 `team_name`, `name`, `subagent_type`, `model` 지정하여 스폰 |
| **Charter 장착** | 팀원 스폰 시 해당 역할의 **PERSONA/*.md** 경로를 프롬프트에 포함 (본 4th 세트) |
| **역할별 문서** | 각 팀원은 스폰 시 해당 **ROLES/*.md** 1개만 로딩 (본 4th 세트) |
| **작업 할당** | `TaskCreate` → `TaskUpdate(owner: "팀원이름")`으로 작업 할당 |
| **통신 모델** | Hub-and-Spoke: 모든 통신은 Team Lead 경유. 팀원끼리 직접 메시지 금지 |
| **작업 완료** | 팀원이 `TaskUpdate(status: "completed")` 후 Team Lead에게 SendMessage |
| **병렬 실행** | **완전히 분리된 작업**일 때만 병렬 허용. 신규 기능 제작은 단일 인스턴스·순차. 상세: §7.3 |
| **팀 해산** | Phase 완료 후 `SendMessage(type: "shutdown_request")` → `TeamDelete` |
| **모델 선택** | planner: `opus` (계획 수립), 나머지 팀원: `sonnet` (구현/검증/테스트). **예외**: 리팩토링 관련 큰 업무 시 backend-dev·frontend-dev는 **opus 최신 버전** 사용 (§7.2) |
| **지연 스폰** | verifier, tester는 VERIFYING/TESTING 단계 진입 시 스폰 (비용 절감) |
| **실행 단위 컨텍스트** | 역할별 "작업 1회" 시작 시 [3-workflow.md §9.5](3-workflow.md#95-실행-단위-컨텍스트-권장-로딩-집합) 권장 로딩 집합 준수 시 토큰·품질 일관성 향상 (권장) |
| **출력 대기** | Bash 서브에이전트 결과 수신은 **inotifywait**(inotify-tools) + **공유 디렉터리** `/tmp/agent-messages/` 사용. bash sleep 폴링 지양. 상세: §7.4 |

### 7.1 도메인별 편집 원칙

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **EDIT-1** | 도메인별 편집 범위 | `backend-dev`는 `backend/`, `tests/`, `scripts/`만, `frontend-dev`는 `web/`, `e2e/`만 편집 |
| **EDIT-2** | Team Lead 코드 수정 금지 | Team Lead(메인 세션)는 코드를 직접 수정하지 않고 팀원에게 위임 |
| **EDIT-3** | 상태·SSOT 쓰기 독점 | `phase-X-Y-status.md`와 SSOT 문서는 Team Lead만 수정 가능 |
| **EDIT-4** | 읽기 전용 팀원 | `verifier`(Explore)와 `planner`(Plan)는 파일 쓰기/편집 권한 없음 |
| **EDIT-5** | 동시 편집 금지 | 동일 파일을 두 팀원이 동시에 편집하지 않음. [FS] Task는 BE 파트 → FE 파트 순차 진행. **병렬 트랙 ≥ 2 일 때는 worktree 로 디렉토리 격리 필수 (WT-1).** |

### 7.2 리팩토링·큰 업무 시 모델 선택 (backend-dev, frontend-dev)

| 조건 | 모델 | 적용 |
|------|------|------|
| **일반 구현** (기능 개발, 소규모 수정) | sonnet | 기본 |
| **리팩토링 관련 큰 업무** | **opus 최신 버전** | backend-dev, frontend-dev 스폰 시 해당 Task/Phase에 한해 적용 |

**리팩토링 관련 큰 업무**의 예: phase-X-refactoring Phase, 500줄 초과 파일 분리·구조 개편, 다수 파일 연쇄 수정이 필요한 리팩토링 Task, Master Plan에서 "리팩토링(대규모)"로 명시된 작업.  
Team Lead는 해당 Task/Phase 시작 시 `Task tool` 스폰에 `model: "opus"`를 지정하여 backend-dev 또는 frontend-dev를 호출한다.

### 7.3 병렬 처리 정책 (Backend / Frontend / Verifier)

| 원칙 | 설명 |
|------|------|
| **완전 분리 시에만 병렬** | Backend·Frontend·Verifier 병렬은 **수정(쓰기) 파일 집합이 서로 교집합이 없을 때만** 허용. 수정(A) ∩ (수정(B) ∪ 참조(B)) = ∅ **그리고** 수정(B) ∩ (수정(A) ∪ 참조(A)) = ∅. EDIT-5 준수. |
| **신규 기능 제작 = 단일·순차** | **신규 기능 제작** Phase는 **단일 인스턴스·순차 진행** 원칙. backend-dev 1명, frontend-dev 1명, verifier 1명으로 순차 또는 BE→FE 순서 유지. 병렬 스폰은 “완전히 분리된 작업”으로 판정된 Phase에만 적용. |
| **병렬 Phase 완료 후 재검증** | 병렬 BUILDING(또는 병렬 VERIFYING)을 사용한 Phase는 **전체 작업 완료 후** Team Lead가 **재검증 절차**를 한 번 더 수행. VERIFYING → (병렬 완료) → **Phase 전체 변경 대상 통합 검증(G2)** → TESTING. 상세: [3-workflow.md §3.3](3-workflow.md#33-병렬-building--재검증) 참조. |
| **Plan·Leader 작업 지시 별도** | 병렬 처리 Phase에서는 **planner**가 계획 시, **Task별 수정 파일 경로·담당 팀원**을 명시하고, 병렬 가능 쌍에 대해 **작업 지시를 트랙별로 구분**하여 출력. **Team Lead**는 BUILDING 진입 시 병렬 팀원에게 **SendMessage를 트랙별로 별도 전달** (Task A → backend-dev-1, Task B → backend-dev-2 등). [_backup/GUIDES/planner-work-guide.md](_backup/GUIDES/planner-work-guide.md) §3, [PERSONA/LEADER.md](PERSONA/LEADER.md) §4 참조. |
| **Task DAG + Merge Queue (5th 확장)** | 5th에서는 Task 간 의존성을 **DAG(Directed Acyclic Graph)**로 명시. 의존성 없는 Task는 **병렬 실행**, 의존성 있는 Task는 **merge queue**에서 순차 대기. planner가 계획 시 Task 의존성 그래프를 `depends_on` 필드로 명시. Team Lead가 DAG 기반으로 병렬/순차 판정. |
| **Worktree 필수 (WT-1)** | 병렬 BUILDING 트랙 ≥ 2 시 `git worktree` 로 작업 디렉토리 격리 필수. **수정 파일 집합 교집합 ∅ 조건만으로는 빌드 산출물(`node_modules`·`.venv`·`__pycache__`)·`git checkout`·`git stash` 경합을 막지 못함**. 병렬 트랙 수 N 판정 후 N ≥ 2 시 `BRANCH_CREATION → WORKTREE_SETUP` 전이 강제. 상세: [infra/git-worktree-guide.md](infra/git-worktree-guide.md), [3-workflow.md §6.6](3-workflow.md#66-worktree-규칙-wt-1--wt-5). |

### 7.4 에이전트 간 출력 대기: inotifywait + 공유 디렉터리

**목적**: Bash 서브에이전트(예: tester) 실행 결과를 **bash sleep 폴링** 대신 **파일 이벤트 기반**으로 수신하여, 불필요한 대기 시간을 줄이고 완료 시점에 바로 처리한다.

| 항목 | 내용 |
|------|------|
| **방식** | **inotifywait**(inotify-tools)를 사용해 **공유 디렉터리** 내 파일 생성·닫기 이벤트를 감지. 팀원(Bash)이 결과를 해당 디렉터리에 쓰면, Team Lead 또는 호출 측이 **inotifywait**로 즉시 감지 후 읽기. |
| **패키지** | **inotify-tools** 패키지 설치로 `inotifywait`를 바로 사용 가능. (Linux: `apt-get install inotify-tools` / macOS: `brew install inotify-tools` — macOS는 fswatch 대안 가능) |
| **공유 디렉터리** | **`/tmp/agent-messages/`** (또는 프로젝트·환경에 맞게 동일 경로로 통일). 에이전트 간 메시지·결과 파일을 이 디렉터리에 쓰고, 수신 측은 inotifywait로 해당 디렉터리를 감시한 뒤 새 파일이 생기면 읽어서 처리. |
| **사용 예** | 팀원(Bash)이 작업 완료 시 `/tmp/agent-messages/<task-id>.done` 또는 `<phase>-<role>.json` 등으로 결과 기록. 호출 측은 `inotifywait -m -e close_write /tmp/agent-messages/` 등으로 감시 후 **파일 내용** 읽기. |
| **결과 파일 내용** | 결과 파일은 **빈 파일이 아니어야 함**. 판정(PASS/FAIL)·요약·실패 목록 등 **내용을 반드시 포함**하여 기록. 빈 파일만 두는 것은 결과 수신으로 간주하지 않음. |
| **공식 수신 경로** | 호출 측(Team Lead 등)은 **공유 디렉터리 `/tmp/agent-messages/`**에서만 결과를 읽음. 도구 런타임의 임시 출력 경로(예: `.../tasks/<id>.output`)는 SSOT에서 정의하지 않으며, **해당 경로를 sleep 후 반복 조회하지 않음**. |
| **G3 pytest 실행** | 결과를 받으려면 **동기 실행** 권장. 백그라운드가 불가피하면 stdout을 `> /tmp/agent-messages/phase-X-Y-pytest.log` 등 **이 경로**로 리다이렉트한 뒤, 완료 시 **그 파일만** 읽음. ➜ [_backup/GUIDES/tester-work-guide.md](_backup/GUIDES/tester-work-guide.md) §G3 pytest 실행·결과 확인 |
| **테스트 요청·결과 기록(1주기)** | 요청서(목록)+결과서를 **docs/pytest-report/** 에 `YYMMDD-HHMM-phase-X-Y-테스트명.md` 로 저장. `run_tester_with_report.py` 참조. ➜ [_backup/GUIDES/tester-work-guide.md §1주기](_backup/GUIDES/tester-work-guide.md#1주기--요청서목록--결과서-기록) |

**금지**: 결과 대기를 **고정 sleep**(예: `sleep 90`)만으로 하는 패턴은 지양. inotifywait(또는 도구가 지원하는 이벤트/콜백) + 공유 디렉터리를 사용하면 깔끔하게 동작한다.

### 7.5 외부·에이전트 질의 시 Team Lead 직접 수정 요청 대응

**적용 상황**: 사용자·다른 에이전트·채팅 등에서 Team Lead(메인 세션)에게 **코드 직접 수정**을 요청하는 질의가 오는 경우 (예: "Execute X fix in Y file", "search_service.py 수정해줘", "이 핫픽스 적용해줘").

| 원칙 | 내용 |
|------|------|
| **적용 범위** | **요청 형식·긴급성·컨텍스트와 무관하게** EDIT-2·HR-1 적용. "어떤 상황에서도 예외 없이" 코드 직접 수정 금지. |
| **정당화 불가** | "간단한 수정", "1줄 변경", "핫픽스", "빠르게 처리" 등 어떤 이유로도 Team Lead 직접 수정을 정당화하지 않는다. |
| **대응** | ① 요청자에게 HR-1/EDIT-2 규칙 안내 및 직접 수정 불가 응답 ② 해결 옵션 제시: 팀 구성 후 **backend-dev/frontend-dev에게 SendMessage로 작업 위임**, 또는 **세션/역할 전환**(해당 역할로 전환하여 수행) ③ 규칙 완화가 필요하면 **사용자 명시적 승인** 후 CLAUDE.md 등 규칙 문서 수정으로만 가능. |

**요약**: 에이전트 팀에서 생성된 질의든 사용자 직접 요청이든, "Team Lead가 이 파일/이 수정 해줘"는 **위임 또는 역할 전환**으로만 처리한다.

### 7.6 Event Protocol 참조 (5th 확장)

> **활성화 조건**: `5th_mode.event = true` 시 적용.

inotifywait 기반 파일 감시(§7.4)를 확장하여, **JSONL 이벤트 로그** 기반의 구조화된 이벤트 인프라를 사용한다.

| 항목 | 내용 |
|------|------|
| **이벤트 로그 경로** | `/tmp/agent-events/{phase}.jsonl` |
| **이벤트 스키마** | `{timestamp, agent, event_type, state, detail, phase_id}` |
| **이벤트 유형** | heartbeat, state_transition, gate_result, blocker, decision, artifact_created |
| **Heartbeat 프로토콜** | 팀원이 5~10분 주기로 `{event_type: "heartbeat", state: "working"}` 발신 |
| **Watchdog SLA** | Heartbeat 미수신 시 자동 리마인드 → SLA 초과 시 에스컬레이션 |

➜ [상세: 4-event-protocol.md](4-event-protocol.md)

### 7.7 Automation 참조 (5th 확장)

> **활성화 조건**: `5th_mode.automation = true` 시 적용.

| 항목 | 내용 |
|------|------|
| **Artifact Persister** | Team Lead 메시지 내 plan/task/status 키워드 감지 → 산출물 자동 생성 + CHAIN-6 검증 |
| **AutoReporter** | 게이트 통과 시 자동 리포트 생성 (G0~G4 각 게이트별) |
| **DecisionEngine** | 자율 판정 (Critical 0, High 1~2건 → AUTO_FIX 루프, max 3회). decision-log.md 자동 기록 |

➜ [상세: 5-automation.md](5-automation.md)

---

## 8. 참조 문서

| 문서 | 용도 | 경로 |
|------|------|------|
| Leader Charter | Team Lead 역할 | [LEADER.md](PERSONA/LEADER.md) |
| Backend Charter | Backend Developer 역할 | [BACKEND.md](PERSONA/BACKEND.md) |
| Frontend Charter | Frontend Developer 역할 | [FRONTEND.md](PERSONA/FRONTEND.md) |
| QA Charter | Verifier/Tester 역할 | [QA.md](PERSONA/QA.md) |
| 검증 템플릿 | Verification report 형식 | `docs/rules/templates/verification-report-template.md` |
| Task 생성 규칙 | Task 문서 생성·명명·검증 | `docs/rules/ai/references/ai-rule-task-creation.md` |
| Task 검사 규칙 | Task 완료 검사·산출물 | `docs/rules/ai/references/ai-rule-task-inspection.md` |
| Plan·Todo 생성 규칙 | Phase plan/todo 생성 순서 | `docs/rules/ai/references/ai-rule-phase-plan-todo-generation.md` |
| Event Protocol | **5th 신규** 이벤트 인프라 프로토콜 | [4-event-protocol.md](4-event-protocol.md) |
| Automation | **5th 신규** 자동화 파이프라인 | [5-automation.md](5-automation.md) |
| 11명 Verification Council | **5th 신규** 다관점 품질 검증 | [QUALITY/10-persona-qc.md](QUALITY/10-persona-qc.md) |

---

**문서 관리**:
- 버전: 7.0-renewal-5th (5th iteration)
- 최종 수정: 2026-02-28
- 단독 사용: 본 iterations/5th 세트만으로 SSOT 완결
- 4th 콘텐츠 전량 보존
- 5th 확장: Research Team 3역할 + G0 게이트, 11명 Verification Council, Event Protocol, Automation, Git Checkpoint, Task DAG + Merge Queue
