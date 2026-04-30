# SSOT 진입점 (v8.0-renewal-6th) — 단독 사용

**버전**: 8.0-renewal-6th
**릴리스**: 2026-04-13
**전략**: 요약+상세 분리 + **claude/ 의존성 제거** + **5세대 혁신 5축 확장** + **6세대 SUB-SSOT 모듈형 로딩**
**목표 읽기 시간**: 15~20분 (700줄)

---

## 📌 빠른 시작

### SSOT 목적

이 SSOT(Single Source of Truth)는 **Claude Code Agent Teams 운영**을 위한 단일 진실 공급원이다.

- 메인 세션이 **Team Lead**로서 팀을 생성·조율·판정·해산한다.
- 팀원은 역할별 Charter(본 5th [PERSONA/](PERSONA/) 내 페르소나 문서)를 기반으로 **병렬·협업** 작업을 수행한다.
- 모든 Phase 작업은 **상태 기반 워크플로우**로 진행된다 (20개 상태).
- **본 iterations/5th 세트만으로 단독 사용 가능** (다른 SSOT 폴더 참조 불필요).
- **5세대 확장**: Research Team(3역할), G0 게이트, Event Protocol, Automation, Git Checkpoint 지원.

### 실행 환경

| 항목 | 내용 |
|------|------|
| **도구** | Claude Code Agent Teams (TeamCreate / SendMessage / TaskList) |
| **프로젝트** | Personal AI Brain v3 (Docker Compose 기반) |
| **현재 Phase** | Phase 21 진행 중 (Chain 21: 21-1 DONE, 21-2 DONE, 21-3 TESTING) |
| **에이전트 간 출력 대기** | **inotifywait**(inotify-tools) + **공유 디렉터리** `/tmp/agent-messages/` 사용. bash sleep 폴링 대신 파일 이벤트로 완료 감지. ➜ [1-project.md §7.4](1-project.md#74-에이전트-간-출력-대기-inotifywait--공유-디렉터리) |

### 당신의 역할은?

| 역할 | 읽기 분량 | 읽기 시간 | 체크리스트로 이동 |
|------|----------|----------|------------------|
| **Research Lead** | 400줄 | 8분 | [§2.0a](#20a-research-lead) |
| **Research Architect** | 400줄 | 8분 | [§2.0b](#20b-research-architect) |
| **Research Analyst** | 400줄 | 8분 | [§2.0c](#20c-research-analyst) |
| **Planner** | 450줄 | 9분 | [§2.0](#20-planner) |
| **Backend Developer** | 500줄 | 10분 | [§2.1](#21-backend-developer) |
| **Frontend Developer** | 500줄 | 10분 | [§2.2](#22-frontend-developer) |
| **Verifier** | 700줄 | 15분 | [§2.3](#23-verifier) |
| **Tester** | 400줄 | 8분 | [§2.4](#24-tester) |
| **Team Lead** | 전체 | 30분 | [§2.5](#25-team-lead) |

---

## 🧩 역할별 스폰 컨텍스트 주입 (6th 모듈형 로딩)

Team Lead가 역할 에이전트를 스폰할 때 **컨텍스트에 포함할 문서 세트**. SUB-SSOT 우선 로딩, GUIDES는 상세 참조용. 2026-04-14 ROLES 통합·PERSONA 교체 원칙 반영.

| 역할 | 주입 세트 (스폰 시 우선 로딩) |
|------|------------------------------|
| **Team Lead** | 코어 0~5 + [core/7-shared-definitions.md](core/7-shared-definitions.md) + [SUB-SSOT/TEAM-LEAD/](SUB-SSOT/TEAM-LEAD/) + [ROLES/team-lead.md](ROLES/team-lead.md) (PERSONA: [LEADER.md](PERSONA/LEADER.md)) + [QUALITY/10-persona-qc.md](QUALITY/10-persona-qc.md) |
| **Planner** | 코어 0~3 + [SUB-SSOT/PLANNER/](SUB-SSOT/PLANNER/) + [ROLES/planner.md](ROLES/planner.md) (PERSONA: [PLANNER.md](PERSONA/PLANNER.md)) + [TEMPLATES/](TEMPLATES/) |
| **Backend Dev** | 코어 2(BE) + 3 + [SUB-SSOT/DEV/](SUB-SSOT/DEV/) (CODER 전용 — v1.1) + [ROLES/backend-dev.md](ROLES/backend-dev.md) (PERSONA: [BACKEND.md](PERSONA/BACKEND.md)) — [_backup/GUIDES/backend-work-guide.md](_backup/GUIDES/backend-work-guide.md) 상세 참조 |
| **Frontend Dev** | 코어 2(FE) + 3 + [SUB-SSOT/DEV/](SUB-SSOT/DEV/) (CODER 전용 — v1.1) + [ROLES/frontend-dev.md](ROLES/frontend-dev.md) (PERSONA: [FRONTEND.md](PERSONA/FRONTEND.md)) — [_backup/GUIDES/frontend-work-guide.md](_backup/GUIDES/frontend-work-guide.md) 상세 참조 |
| **Verifier** | 코어 3 + [SUB-SSOT/VERIFIER/](SUB-SSOT/VERIFIER/) (REVIEWER 페르소나·plan-first review·컨텍스트 분리 통합 — v1.1) + [ROLES/verifier.md](ROLES/verifier.md) (PERSONA: [QA.md](PERSONA/QA.md)) + [QUALITY/](QUALITY/) |
| **Tester** | 코어 3 + [SUB-SSOT/TESTER/](SUB-SSOT/TESTER/) (VALIDATOR 페르소나·VAL 포맷·FAIL_COUNTER 통합 — v1.1) + [ROLES/tester.md](ROLES/tester.md) (PERSONA: [QA.md](PERSONA/QA.md)) + [tests/index.md](tests/index.md) |
| **Research Lead** | 코어 2 + 3 + [SUB-SSOT/RESEARCH/](SUB-SSOT/RESEARCH/) (entrypoint + `1-lead-procedure.md`) + [ROLES/research-lead.md](ROLES/research-lead.md) (PERSONA: [RESEARCH_LEAD.md](PERSONA/RESEARCH_LEAD.md)) + [TEMPLATES/research-report-template.md](TEMPLATES/research-report-template.md) |
| **Research Architect** | 코어 2 + 3 + [SUB-SSOT/RESEARCH/](SUB-SSOT/RESEARCH/) (entrypoint + `2-architect-procedure.md`) + [ROLES/research-architect.md](ROLES/research-architect.md) (PERSONA: [RESEARCH_ARCHITECT.md](PERSONA/RESEARCH_ARCHITECT.md)) |
| **Research Analyst** | 코어 2 + 3 + [SUB-SSOT/RESEARCH/](SUB-SSOT/RESEARCH/) (entrypoint + `3-analyst-procedure.md`) + [ROLES/research-analyst.md](ROLES/research-analyst.md) (PERSONA: [RESEARCH_ANALYST.md](PERSONA/RESEARCH_ANALYST.md)) |

**PERSONA 교체**: 각 역할의 기본 Charter(§1)는 스폰 시 다른 `PERSONA/*.md` 로 덮어쓰기 가능. 상세: [ROLES/README.md](ROLES/README.md).

---

## 🎯 역할별 필독 체크리스트

### 2.0a Research Lead

**팀원 이름**: `research-lead` | **코드 편집**: ❌ | **5th 전용**

- [ ] 본 문서 § 코어 개념 ([§3](#3-코어-개념-요약))
- [ ] [1-project.md](1-project.md) § Research Team
- [ ] [3-workflow.md](3-workflow.md) § RESEARCH·RESEARCH_REVIEW(G0) 상태

**핵심 원칙**: Research Team 총괄, 기술 조사·아키텍처 탐색 지휘, G0 게이트 산출물 품질 관리, Team Lead 경유 통신

---

### 2.0b Research Architect

**팀원 이름**: `research-architect` | **코드 편집**: ❌ | **5th 전용**

- [ ] 본 문서 § 코어 개념 ([§3](#3-코어-개념-요약))
- [ ] [1-project.md](1-project.md) § Research Team
- [ ] [2-architecture.md](2-architecture.md) 전체
- [ ] [3-workflow.md](3-workflow.md) § RESEARCH 상태

**핵심 원칙**: 아키텍처 대안 탐색, 기술 스택 비교 분석, PoC 설계, research-lead 경유 보고

---

### 2.0c Research Analyst

**팀원 이름**: `research-analyst` | **코드 편집**: ❌ | **5th 전용**

- [ ] 본 문서 § 코어 개념 ([§3](#3-코어-개념-요약))
- [ ] [1-project.md](1-project.md) § Research Team
- [ ] [3-workflow.md](3-workflow.md) § RESEARCH 상태

**핵심 원칙**: 기존 코드베이스 분석, 의존성·영향 범위 조사, 데이터 수집·정리, research-lead 경유 보고

---

### 2.0 Planner

**팀원 이름**: `planner` | **Charter**: [PLANNER.md](PERSONA/PLANNER.md) | **코드 편집**: ❌

- [ ] 본 문서 § 코어 개념 ([§3](#3-코어-개념-요약))
- [ ] [ROLES/planner.md](ROLES/planner.md)
- [ ] [1-project.md](1-project.md) § 팀 구성·라이프사이클
- [ ] [3-workflow.md](3-workflow.md) § 상태머신

**핵심 원칙**: SSOT 버전·리스크 확인, Task 3~7개 분해, 도메인 태그·담당 팀원 명시, Team Lead 경유 통신

**계획 시작 시**: [_backup/GUIDES/planner-work-guide.md](_backup/GUIDES/planner-work-guide.md) 참조

**SUB-SSOT**: [SUB-SSOT/PLANNER/](SUB-SSOT/PLANNER/) — 모듈형 로딩 시 `core/7-shared + PLANNER/0~1` 로딩

---

### 2.1 Backend Developer

**팀원 이름**: `backend-dev` | **Charter**: [BACKEND.md](PERSONA/BACKEND.md) | **코드 편집**: ✅

- [ ] 본 문서 § 코어 개념 ([§3](#3-코어-개념-요약))
- [ ] [ROLES/backend-dev.md](ROLES/backend-dev.md)
- [ ] [1-project.md](1-project.md) § 팀 구성
- [ ] [2-architecture.md](2-architecture.md) § 백엔드
- [ ] [3-workflow.md](3-workflow.md) § 상태머신

**핵심 원칙**: ORM 필수, Pydantic 검증, 타입 힌트, Team Lead 경유 통신

**Task 시작 시**: [_backup/GUIDES/backend-work-guide.md](_backup/GUIDES/backend-work-guide.md) 참조

**SUB-SSOT**: [SUB-SSOT/DEV/](SUB-SSOT/DEV/) — fn 개발 시 `core/7-shared + DEV/0~1` 로딩

---

### 2.2 Frontend Developer

**팀원 이름**: `frontend-dev` | **Charter**: [FRONTEND.md](PERSONA/FRONTEND.md) | **코드 편집**: ✅

- [ ] 본 문서 § 코어 개념 ([§3](#3-코어-개념-요약))
- [ ] [ROLES/frontend-dev.md](ROLES/frontend-dev.md)
- [ ] [1-project.md](1-project.md) § 팀 구성
- [ ] [2-architecture.md](2-architecture.md) § 프론트엔드
- [ ] [3-workflow.md](3-workflow.md) § 상태머신

**핵심 원칙**: ESM import/export, innerHTML+esc(), CDN 금지, Team Lead 경유 통신

**Task 시작 시**: [_backup/GUIDES/frontend-work-guide.md](_backup/GUIDES/frontend-work-guide.md) 참조

**SUB-SSOT**: [SUB-SSOT/DEV/](SUB-SSOT/DEV/) — fn 개발 시 `core/7-shared + DEV/0~1` 로딩

---

### 2.3 Verifier

**팀원 이름**: `verifier` | **Charter**: [QA.md](PERSONA/QA.md) | **코드 편집**: ❌

- [ ] 본 문서 § 코어 개념 ([§3](#3-코어-개념-요약))
- [ ] [ROLES/verifier.md](ROLES/verifier.md)
- [ ] [1-project.md](1-project.md)
- [ ] [2-architecture.md](2-architecture.md) § BE+FE
- [ ] [3-workflow.md](3-workflow.md) § 품질 게이트

**검증 시작 시**: [_backup/GUIDES/verifier-work-guide.md](_backup/GUIDES/verifier-work-guide.md) 참조

**SUB-SSOT**: [SUB-SSOT/VERIFIER/](SUB-SSOT/VERIFIER/) — 모듈형 로딩 시 `core/7-shared + VERIFIER/0~1` 로딩

**핵심 원칙**: Critical 1건+ → FAIL, Critical 0/High 있음 → PARTIAL, Critical 0/High 0 → PASS

---

### 2.4 Tester

**팀원 이름**: `tester` | **Charter**: [QA.md](PERSONA/QA.md) | **코드 편집**: ❌

- [ ] 본 문서 § 코어 개념 ([§3](#3-코어-개념-요약))
- [ ] [ROLES/tester.md](ROLES/tester.md)
- [ ] [3-workflow.md](3-workflow.md) § 품질 게이트

**테스트 시작 시**: [_backup/GUIDES/tester-work-guide.md](_backup/GUIDES/tester-work-guide.md) 참조

**SUB-SSOT**: [SUB-SSOT/TESTER/](SUB-SSOT/TESTER/) — 모듈형 로딩 시 `core/7-shared + TESTER/0~1` 로딩

**핵심 원칙**: pytest 실행, E2E 실행, 커버리지 80%, Team Lead 경유 보고, **Ollama/AI 테스트(`tests/test_ai_api.py`, `/api/ask`) 병렬(동시) 실행 금지(단일 pytest만 실행)**. G3 결과 확인 시 **동기 실행** 권장; 다른 경로(도구 task output 등) sleep 후 반복 조회 금지. ➜ [_backup/GUIDES/tester-work-guide.md §G3 pytest 실행·결과 확인](_backup/GUIDES/tester-work-guide.md#g3-pytest-실행결과-확인-필수)

**결과 기록**: `/tmp/agent-messages/`(롤 넘기기) + **docs/pytest-report/** (1주기 요청서·결과서, `YYMMDD-HHMM-phase-X-Y-테스트명.md`). ➜ [_backup/GUIDES/tester-work-guide.md §1주기](_backup/GUIDES/tester-work-guide.md#1주기--요청서목록--결과서-기록)

---

### 2.5 Team Lead

**실행**: 메인 세션 | **Charter**: [LEADER.md](PERSONA/LEADER.md) | **코드 편집**: ❌

- [ ] 본 문서 전체
- [ ] [1-project.md](1-project.md)
- [ ] [2-architecture.md](2-architecture.md)
- [ ] [3-workflow.md](3-workflow.md)
- [ ] [4-event-protocol.md](4-event-protocol.md) ← **5th 신규**
- [ ] [5-automation.md](5-automation.md) ← **5th 신규**
- [ ] [ROLES/*.md](ROLES/)
- [ ] [QUALITY/10-persona-qc.md](QUALITY/10-persona-qc.md) ← **5th 신규**

**핵심 원칙**: 코드 직접 수정 금지, Hub-and-Spoke 통신, 상태 기반 판정, SSOT 리로드 필수

**PLANNING 시 (planner 결과 대기)**:
- planner는 **파일을 쓰지 않음** (SendMessage로만 보고). 따라서 **`sleep`·`find`·`ls` 로 phase-X-Y/ 디렉터리 폴링 금지.** SendMessage 수신 후 **Team Lead가** phase-X-Y-plan.md, todo-list.md, tasks/ 를 생성. ➜ [3-workflow.md §3.2 PLANNING→PLAN_REVIEW](3-workflow.md#planning--plan_review-planner-결과-수신-및-산출물-생성)

**외부·에이전트 질의 (직접 수정 요청)**:
- 사용자·에이전트가 "코드 직접 수정"을 요청해도 **예외 없이** EDIT-2·HR-1 적용. 직접 수정하지 않고, 규칙 안내 후 **위임(backend-dev/frontend-dev)** 또는 **역할 전환** 옵션 제시. ➜ [1-project.md §7.5](1-project.md#75-외부에이전트-질의-시-team-lead-직접-수정-요청-대응)

---

## 3. 코어 개념 요약

### 3.1 팀 구조

```
Team Lead (메인 세션)
  ├── [Research Team — 5th 확장, 선택적]
  │   ├── research-lead (Explore/opus) — 조사 총괄
  │   ├── research-architect (Explore/opus) — 아키텍처 탐색
  │   └── research-analyst (Explore/sonnet) — 코드베이스 분석
  │
  ├── planner (Plan/opus) — 계획 수립
  ├── backend-dev (general-purpose/sonnet, **리팩토링·큰 업무 시 opus**) — 백엔드 구현
  ├── frontend-dev (general-purpose/sonnet, **리팩토링·큰 업무 시 opus**) — 프론트엔드 구현
  ├── verifier (Explore/sonnet) — 코드 리뷰
  └── tester (Bash/sonnet) — 테스트 실행
```

**코드 편집 원칙**:
- Team Lead: ❌ 코드 수정 금지 (조율·판정만)
- backend-dev: ✅ `backend/`, `tests/`, `scripts/` 편집
- frontend-dev: ✅ `web/`, `e2e/` 편집
- verifier: ❌ 읽기 전용 (수정 필요 시 Team Lead에게 보고)

---

### 3.2 상태 머신 (20개 상태 — 4th 14개 + 5th 6개)

```
IDLE → TEAM_SETUP → RESEARCH → RESEARCH_REVIEW(G0)
  → PLANNING → PLAN_REVIEW → DESIGN_REVIEW → TASK_SPEC
  → BRANCH_CREATION → BUILDING → AUTO_FIX → VERIFYING
  → TESTING → AB_COMPARISON → (다음 Task 또는 INTEGRATION)
  → INTEGRATION → E2E → E2E_REPORT → TEAM_SHUTDOWN → DONE
```

**4th 기존 상태 (14개)**: IDLE, TEAM_SETUP, PLANNING, PLAN_REVIEW, TASK_SPEC, BUILDING, VERIFYING, TESTING, INTEGRATION, E2E, E2E_REPORT, TEAM_SHUTDOWN, BLOCKED, REWINDING, DONE

**5th 신규 상태 (6개)**: RESEARCH, RESEARCH_REVIEW(G0), BRANCH_CREATION, AUTO_FIX, AB_COMPARISON, DESIGN_REVIEW

**실패 시**: REWINDING → 이전 상태로 복귀
**차단 시**: BLOCKED → 이슈 해결 후 복귀
**자동 수정**: AUTO_FIX → 최대 3회 재시도, 초과 시 에스컬레이션

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

---

### 3.4 SSOT Lock Rules

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **LOCK-1** | Phase 실행 중 SSOT 변경 금지 | `current_state`가 `IDLE` 또는 `DONE`이 아닌 동안 SSOT 수정 불가 |
| **LOCK-2** | 변경 필요 시 Phase 일시정지 | SSOT 수정 불가피하면 `current_state`를 `BLOCKED`로 전이 후 변경 |
| **LOCK-3** | 변경 후 리로드 필수 | SSOT 변경 후 모든 팀원에게 SendMessage로 리로드 지시 |
| **LOCK-4** | 팀원 SSOT 수정 금지 | 팀원은 SSOT를 읽기 전용으로만 참조 |
| **LOCK-5** | 변경 이력 필수 기록 | SSOT 변경 시 버전 히스토리에 반드시 기록 |

**Lock 상태 머신**:
```
Phase 실행 중 (PLANNING~E2E_REPORT)
  │
  ├── SSOT 변경 필요 발견
  │     → current_state = BLOCKED (사유: "SSOT 변경 필요")
  │     → 사용자 승인 → SSOT 수정 → 버전 갱신
  │     → SendMessage(broadcast) — "SSOT 리로드 필요"
  │     → 리로드 완료 → 이전 상태 복귀
  │
  └── Phase 미실행 (IDLE / DONE)
        → SSOT 수정 가능 (버전 갱신 필수)
```

---

### 3.5 SSOT Freshness Rules

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **FRESH-1** | 세션 시작 시 SSOT 리로드 | 새 AI 세션 시작 시 SSOT 4개 파일을 순서대로 로딩 (0→1→2→3) |
| **FRESH-2** | 새 Phase 시작 시 버전 확인 | Phase 시작 전 SSOT 버전이 `ssot_version`과 일치하는지 확인 |
| **FRESH-3** | 버전 불일치 시 갱신 우선 | SSOT 버전이 변경되었으면 Phase 진행 전 SSOT를 먼저 리로드 |
| **FRESH-4** | 리로드 시각 기록 | SSOT 로딩 완료 시 `ssot_loaded_at`에 타임스탬프 기록 |
| **FRESH-5** | 장기 세션 중 주기적 확인 | Phase가 3개 이상의 Task를 처리한 경우 SSOT 버전 재확인 권장 |
| **FRESH-6** | 팀원 역할별 로딩 | 각 팀원은 스폰 시 해당 **ROLES/*.md** 1개만 로딩 (본 4th 세트 내) |
| **FRESH-7** | 컨텍스트 복구 시 SSOT 리로드 필수 | 컨텍스트 압축·세션 중단 후 복구 시, 작업 재개 전 반드시 SSOT 리로드 + status.md 확인 + 팀 재구성. [3-workflow.md §9](3-workflow.md#9-컨텍스트-복구-프로토콜) 참조. **팀 없이 코드 수정 절대 금지** |
| **FRESH-8** | 리팩토링 레지스트리 관리 | ① Phase X-Y 완료(DONE) 시 코드 스캔→500줄 초과 파일을 레지스트리에 등록. ② 새 Master Plan 작성 시 레지스트리 읽기→700줄 초과 있으면 리팩토링 sub-phase 자동 편성. [3-workflow.md §10](3-workflow.md#10-코드-유지관리-리팩토링) 참조 |
| **FRESH-9** | 실행 단위 컨텍스트 (권장) | 역할별 "작업 1회"(계획/Task/검증) 시작 시 [3-workflow.md §9.5](3-workflow.md#95-실행-단위-컨텍스트-권장-로딩-집합) 권장 로딩 집합 준수 시 토큰·품질 일관성 향상. planner·verifier 우선 적용 권장 |
| **FRESH-10** | SUB-SSOT 모듈형 로딩 | 역할별 SUB-SSOT 진입점 + 공통 레이어만 로딩하여 토큰 60% 절감. [SUB-SSOT/0-sub-ssot-index.md](SUB-SSOT/0-sub-ssot-index.md) 라우팅 테이블 참조 |
| **FRESH-11** | 공통 레이어 필수 | SUB-SSOT 로딩 시 `core/7-shared-definitions.md` 항상 함께 로딩. 공통 포맷(GATE, 역할, 승인, VUL) 일관성 보장 |
| **FRESH-12** | SUB-SSOT 독립 검증 | 각 SUB-SSOT는 공통 레이어와 함께 단독 로딩 시 역할 작업이 완전히 수행 가능해야 함. 참조 무결성 필수 |

**토큰·컨텍스트 관리 요약**:
- **세션/Phase**: FRESH-1(Team Lead 0→1→2→3), FRESH-6(팀원 스폰 시 ROLES/*.md 1개).
- **Phase 간**: Phase Chain 시 [§8](3-workflow.md#8-phase-chain-자동-순차-실행) CHAIN-2 — `/clear`로 토큰 초기화.
- **복구**: FRESH-7 + [3-workflow.md §9](3-workflow.md#9-컨텍스트-복구-프로토콜) (압축·세션 중단·토큰 초과 후 필수 절차).
- **작업 1회 단위**: FRESH-9 — [§9.5 실행 단위 컨텍스트](3-workflow.md#95-실행-단위-컨텍스트-권장-로딩-집합) 권장 로딩 집합.

**로딩 순서 (Team Lead)**:
```
[0] 0-entrypoint.md (진입점, 역할별 체크리스트)
  ↓
[1] 1-project.md (팀 구성, 역할 정의)
  ↓
[2] 2-architecture.md (인프라, BE, FE 구조)
  ↓
[3] 3-workflow.md (상태 머신, 워크플로우, Phase Chain)
```

---

### 3.6 ENTRYPOINT 규칙

Phase 실행의 **단일 진입점**은 `phase-X-Y-status.md` 파일이다.

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **ENTRY-1** | 단일 진입점 | 모든 Phase 작업은 `docs/phases/phase-X-Y/phase-X-Y-status.md`를 먼저 읽는 것으로 시작 |
| **ENTRY-2** | 상태 기반 분기 | `current_state` 값에 따라 다음 행동을 결정 |
| **ENTRY-3** | SSOT 버전 확인 | 진입 시 `ssot_version` 필드와 현재 SSOT 버전의 일치 여부를 확인 |
| **ENTRY-4** | Blocker 우선 확인 | `blockers` 배열이 비어있지 않으면 다른 작업보다 Blocker 해결을 우선 |
| **ENTRY-5** | 진입점 외 직접 시작 금지 | status 파일을 읽지 않고 Task 구현을 바로 시작하는 것을 금지 |

**ENTRYPOINT 플로우**:
```
세션 시작 / Phase 재개
  │
  ▼
[1] SSOT 로딩 (0→1→2→3) ← FRESH-1
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
[6] 팀 상태 확인 (TeamCreate 필요 여부, 팀원 idle 상태)
  │
  ▼
[7] 워크플로우 실행
```

---

### 3.7 품질 게이트 (G0~G4 — 5th 확장)

```
[G0: Research Review] ← 5th 신규. Research Team 조사 결과 검증
  ↓
[G1: Plan Review]     planner 분석 → Team Lead 검토
  ↓
[G2: Code Review]     verifier가 BE+FE 코드 검증 → Team Lead 보고
  ↓
[G3: Test Gate]       tester가 테스트 실행 + 커버리지 확인
  ↓
[G4: Final Gate]      Team Lead가 G2+G3 종합 판정
```

**판정 기준**:
- **G0 PASS** *(5th 신규)*: 기술 조사 완료, 아키텍처 대안 2개+, 리스크 분석 포함, PoC 결과(선택) 첨부
- **G1 PASS**: 완료 기준 명확, Task 3~7개, 도메인 분류 완료
- **G2 PASS**: Critical 0건 (ORM 사용, Pydantic 검증, CDN 미사용, XSS 방지)
- **G3 PASS**: pytest PASS, 커버리지 ≥80%, E2E PASS, 회귀 테스트 통과
- **G4 PASS**: G2 PASS + G3 PASS + Blocker 0건

---

### 3.8 도메인 태그

모든 Task는 도메인 태그 필수:
- `[BE]`: 백엔드 (API, 서비스 로직)
- `[FE]`: 프론트엔드 (UI, 페이지)
- `[FS]`: 풀스택 (BE → FE 순서 또는 병렬)
- `[DB]`: 데이터베이스 (스키마, 마이그레이션)
- `[TEST]`: 테스트 (pytest, E2E)
- `[INFRA]`: 인프라 (Docker, 설정)

---

### 3.9 팀 라이프사이클 (루프 가능)

**한 Phase 내 라이프사이클**:

```
Phase 시작
  │
  ▼
[1] TeamCreate(team_name: "phase-X-Y")  ← 팀 생성 (Team Lead)
  │
  ▼
[1.5] (5th 선택) Research Team 스폰 ← 5th_mode.research = true 시
  │   Task(research-lead, Explore/opus), Task(research-architect, Explore/opus),
  │   Task(research-analyst, Explore/sonnet)
  │   → RESEARCH 상태 진입 → RESEARCH_REVIEW(G0) 통과 후 PLANNING으로 전이
  │
  ▼
[2] Task tool(team_name, name, subagent_type, model) × N  ← 팀원 스폰
  │   예: planner (Plan/opus), backend-dev, frontend-dev (general-purpose/sonnet; 리팩토링·큰 업무 시 opus),
  │       verifier (Explore/sonnet), tester (Bash/sonnet)
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

**루프(다음 Phase)**:
- **단일 Phase만 실행**: DONE 도달 후 Phase 종료. 필요 시 새 Phase 시작 시 위 [1]부터 다시 진행 (새 팀 생성).
- **Phase Chain 사용**: `docs/phases/phase-chain-{name}.md`에 phases 배열을 정의하고, DONE 후 `/clear` → 다음 Phase의 status.md 읽기 → [1] TeamCreate(team_name: "phase-X-Y")부터 반복. 자세한 프로토콜은 [3-workflow.md § Phase Chain](3-workflow.md#phase-chain-자동-순차-실행) 참조.

**지연 스폰**: verifier, tester는 VERIFYING/TESTING 단계 진입 시 스폰 가능 (비용 절감).

---

## 3.10 5세대 혁신 5축 (5th Generation Innovation Axes)

5세대 SSOT는 4세대 기반 위에 5개 혁신 축을 추가하여 워크플로우를 강화한다.

| # | 혁신 축 | 핵심 개념 | 주요 변경 |
|---|---------|----------|----------|
| **1** | **Research-first** | 구현 전 조사·탐색 단계 의무화 | RESEARCH 상태 + G0 게이트 + Research Team 3역할 |
| **2** | **Event-first** | 파일 기반 폴링 → 이벤트 기반 아키텍처 | JSONL 이벤트 로그, Heartbeat 프로토콜 → [4-event-protocol.md](4-event-protocol.md) |
| **3** | **Automation-first** | 반복 산출물 자동 생성·보고 | Artifact Persister, AutoReporter → [5-automation.md](5-automation.md) |
| **4** | **Branch-first** | Phase별 Git 격리 + 체크포인트 | BRANCH_CREATION 상태, `phase-{X}-{Y}-{state}` 태그 |
| **5** | **Multi-perspective** | 단일 Verifier → 다관점 검증 위원회 | 11명 Verification Council → [QUALITY/10-persona-qc.md](QUALITY/10-persona-qc.md) |

**5th_mode 설정**: status.md에 `5th_mode` 필드를 추가하여 각 축을 개별 활성화/비활성화할 수 있다. **기본값은 전부 true (opt-out 방식)**. 명시적으로 `false`로 설정한 축만 비활성화된다. 미설정 시 **모든 축 활성화 (5th 풀 모드)**.

```yaml
5th_mode:
  research: true           # Research-first (RESEARCH 상태 + G0) — 기본 true
  event: true              # Event-first (JSONL 이벤트 로그) — 기본 true
  automation: true         # Automation-first (Artifact Persister) — 기본 true
  branch: true             # Branch-first (Git Checkpoint) — 기본 true
  multi_perspective: true  # Multi-perspective (11명 Council) — 기본 true
```

> **opt-out 원칙**: 특정 축을 비활성화하려면 `false`를 명시적으로 설정한다. 생략하면 `true`로 간주한다.

**신규 문서 참조**:
- [4-event-protocol.md](4-event-protocol.md) — 이벤트 인프라 프로토콜
- [5-automation.md](5-automation.md) — 자동화 파이프라인
- [QUALITY/10-persona-qc.md](QUALITY/10-persona-qc.md) — 11명 Verification Council

---

## 4. 백엔드 핵심 규칙

| 규칙 | 설명 |
|------|------|
| **ORM 필수** | raw SQL 절대 금지, SQLAlchemy ORM만 사용 |
| **Pydantic 검증** | 모든 API 입력은 Pydantic 스키마로 검증 |
| **타입 힌트** | 함수 파라미터 + 반환 타입 힌트 필수 |
| **에러 핸들링** | try-except + HTTPException 패턴 |
| **비동기** | async/await 활용 |
| **네이밍** | snake_case |

**금지**: raw SQL, 타입 힌트 생략, 입력 검증 생략, 에러 처리 생략

➜ [상세: ROLES/backend-dev.md](ROLES/backend-dev.md)

---

## 5. 프론트엔드 핵심 규칙

| 규칙 | 설명 |
|------|------|
| **ESM import/export** | `type="module"` 필수 |
| **innerHTML + esc()** | XSS 방지 필수 |
| **외부 CDN 금지** | 모든 리소스는 로컬에서 제공 (`web/public/libs/`) |
| **window 전역 금지** | 기존 것 제외하고 새로 할당 금지 |
| **컴포넌트 재사용** | `layout-component.js`, `header-component.js` 활용 |

**금지**: CDN 참조, innerHTML without esc(), 새 window 전역 변수

➜ [상세: ROLES/frontend-dev.md](ROLES/frontend-dev.md)

---

## 6. Verifier 판정 기준

### 6.1 백엔드 (G2_be)

**Critical (필수)**:
- [ ] ORM 사용 (raw SQL 없음)
- [ ] Pydantic 검증 존재
- [ ] 타입 힌트 완전
- [ ] 기존 테스트 깨지지 않음

**High (권장)**:
- [ ] 에러 핸들링 존재
- [ ] 새 기능 테스트 파일 존재

### 6.2 프론트엔드 (G2_fe)

**Critical (필수)**:
- [ ] CDN 참조 없음
- [ ] innerHTML 시 esc() 사용
- [ ] ESM import/export 패턴
- [ ] 페이지 로드 시 콘솔 에러 없음

**High (권장)**:
- [ ] window 전역 변수 할당 없음
- [ ] 기존 컴포넌트 재사용
- [ ] API 에러 핸들링

➜ [상세: ROLES/verifier.md](ROLES/verifier.md)

---

## 7. 상세 가이드 링크 (본 5th 세트 내)

| 주제 | 링크 |
|------|------|
| **팀 구성·역할 상세** | [1-project.md](1-project.md) |
| **아키텍처 (인프라·BE·FE)** | [2-architecture.md](2-architecture.md) |
| **워크플로우·상태머신·Phase Chain** | [3-workflow.md](3-workflow.md) |
| **이벤트 프로토콜** | [4-event-protocol.md](4-event-protocol.md) ← **5th 신규** |
| **자동화 파이프라인** | [5-automation.md](5-automation.md) ← **5th 신규** |
| **Planner** | [ROLES/planner.md](ROLES/planner.md) |
| **Backend 개발 가이드** | [ROLES/backend-dev.md](ROLES/backend-dev.md) |
| **Frontend 개발 가이드** | [ROLES/frontend-dev.md](ROLES/frontend-dev.md) |
| **Verifier 검증 가이드** | [ROLES/verifier.md](ROLES/verifier.md) |
| **Tester 테스트 가이드** | [ROLES/tester.md](ROLES/tester.md) |
| **11명 Verification Council** | [QUALITY/10-persona-qc.md](QUALITY/10-persona-qc.md) ← **5th 신규** |
| **SUB-SSOT 인덱스** | [SUB-SSOT/0-sub-ssot-index.md](SUB-SSOT/0-sub-ssot-index.md) ← **6th 신규** |
| **공통 포맷 정의** | [core/7-shared-definitions.md](core/7-shared-definitions.md) ← **6th 신규** |

---

## 7.5 SUB-SSOT 라우팅 (6th 신규)

> **목적**: 전체 SSOT 로딩 대신 역할별 SUB-SSOT만 로딩하여 토큰 효율 60% 향상.

### 라우팅 테이블

| 작업 유형 | 로딩 경로 | 토큰 (추정) |
|-----------|-----------|-------------|
| fn 기본 개발 | `core/7-shared` + `DEV/0-dev` + `DEV/1-fn` (CODER 전용) | ~18K |
| fn 풀 (복잡) | `core/7-shared` + `DEV/0~3` (CODER 전용) | ~27K |
| 계획 수립 | `core/7-shared` + `PLANNER/0~1` | ~13K |
| 코드 검증 (REVIEWER) | `core/7-shared` + `VERIFIER/0~1` (REVIEWER 통합) | ~17K |
| 테스트 실행 (VALIDATOR) | `core/7-shared` + `TESTER/0~1` (VALIDATOR 통합) | ~16.5K |
| 오케스트레이션 | SSOT 코어(0~5) + `TEAM-LEAD/0~1` + 인덱스 | ~38K |
| 기술 조사 (Research Lead) | `core/7-shared` + `RESEARCH/0-research` + `RESEARCH/1-lead` | ~14K |
| 기술 조사 (Research Architect) | `core/7-shared` + `RESEARCH/0-research` + `RESEARCH/2-architect` | ~14K |
| 기술 조사 (Research Analyst) | `core/7-shared` + `RESEARCH/0-research` + `RESEARCH/3-analyst` | ~14K |

### 관련 FRESH 규칙

- **FRESH-10**: SUB-SSOT 모듈형 로딩 규칙
- **FRESH-11**: 공통 레이어(`core/7-shared-definitions.md`) 필수 동반 로딩
- **FRESH-12**: 각 SUB-SSOT 독립 실행 가능성 검증

→ 상세: [SUB-SSOT/0-sub-ssot-index.md](SUB-SSOT/0-sub-ssot-index.md)

---

## 8. SSOT-NEW 구조 (core/ + project/)

> Phase 24-1-3에서 도입. 이식 가능성을 위해 core(프레임워크)와 project(프로젝트별)를 분리한다.
> 현재 비파괴적 전환 중: 기존 파일 위치 유지 + 참조 README 배치. 실제 이동은 Phase 24-4.

```
5th/
├── core/                          ← 이식 가능 프레임워크
│   ├── README.md                  (참조 허브)
│   ├── 6-rules-index.md           (규칙 통합 인덱스, 72개 상위 규칙)
│   ├── → 3-workflow.md            (참조: ../3-workflow.md)
│   ├── → 4-event-protocol.md      (참조: ../4-event-protocol.md)
│   ├── → 5-automation.md          (참조: ../5-automation.md)
│   ├── QUALITY/                   (참조: ../QUALITY/)
│   └── TEMPLATES/                 (참조: ../TEMPLATES/)
├── project/                       ← 프로젝트별 맞춤
│   ├── README.md                  (참조 허브)
│   ├── → 1-project.md             (참조: ../1-project.md)
│   ├── → 2-architecture.md        (참조: ../2-architecture.md)
│   ├── ROLES/                     (참조: ../ROLES/)
│   └── _backup/GUIDES/            (레거시 참조: 2026-04-15 Phase-F로 SUB-SSOT 이관)
├── 0-entrypoint.md                (본 파일, core+project 연결 허브)
└── VERSION.md
```

- **core/ 상세**: [core/README.md](core/README.md)
- **project/ 상세**: [project/README.md](project/README.md)
- **규칙 인덱스**: [core/6-rules-index.md](core/6-rules-index.md) — 14개 카테고리, 3중 색인(카테고리/파일/심각도)

---

## 9. 버전 관리

**현재 버전**: 8.0-renewal-6th
**릴리스 날짜**: 2026-04-13
**특징**: 5th 기반 확장 — SUB-SSOT 모듈형 로딩 아키텍처 도입. 역할별 SUB-SSOT로 토큰 60% 절감. 공통 레이어(core/7-shared-definitions.md) 신설.

➜ [상세 버전 정보: VERSION.md](VERSION.md)

---

**문서 관리**:
- 버전: 8.0-renewal-6th (6th iteration)
- 최종 수정: 2026-04-13
- 5th 대비: +SUB-SSOT 모듈형 로딩, +core/7-shared-definitions.md, +FRESH-10~12, +§7.5 SUB-SSOT 라우팅
- 5th 콘텐츠 전량 보존 + SUB-SSOT 확장 레이어 추가
