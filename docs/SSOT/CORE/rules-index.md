# rules-index.md — SSOT 규칙 통합 인덱스

## 개요

SSOT에 정의된 모든 규칙의 통합 인덱스. 색인(카테고리/파일)을 제공한다.

---

## §1 카테고리별 색인

> 아래 표의 심각도 칸은 규칙 자체의 중요도다. G2 결함의 등급은 이 칸이 아니라 `verification-procedure.md` §G2 판정 기준 「등급 산출」 표에서 낸다.

### 1.1 HR — Hard Rules (절대 위반 금지)

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| HR-1 | Team Lead 코드 수정 금지 | Team Lead는 코드 Edit/Write 금지, 팀원 위임 전용 | rules-index §3 | CRITICAL |
| HR-2 | Phase 산출물 생략 금지 | status/plan/todo-list/tasks 필수 (CHAIN-6) | rules-index §3 | CRITICAL |
| HR-3 | 컨텍스트 복구 시 SSOT 리로드 | 세션 복구 시 entrypoint → status → 팀 확인 필수 | rules-index §3 | CRITICAL |
| HR-4 | Phase 문서 경로 규칙 | master-plan → docs/phases/ 루트, phase 문서 → 하위 폴더 (CHAIN-10) | rules-index §3 | CRITICAL |
| HR-5 | 리팩토링 규정 | 500줄 등록 / 700줄 Level 분류 / 1000줄 즉시 편성 (REFACTOR-1~3) | rules-index §3 | CRITICAL |
| HR-6 | Task 도메인-역할 분리 (별칭) | ASSIGN-1~5를 묶어 부르는 이름. 인용할 때는 해당 ASSIGN-N을 함께 적는다 | workflow §TASK_SPEC | CRITICAL |
| HR-7 | 에이전트 라이프사이클 (별칭) | LIFECYCLE-1~6을 묶어 부르는 이름. 인용할 때는 해당 LIFECYCLE-N을 함께 적는다 | workflow §AGENT-LIFECYCLE | CRITICAL |

### 1.2 LOCK — SSOT 잠금 & 불변성

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| LOCK-1 | Phase 실행 중 SSOT 변경 금지 | current_state가 IDLE/DONE 아닌 동안 SSOT 수정 불가 | entrypoint §3.4 | CRITICAL |
| LOCK-2 | 변경 시 Phase 일시정지 | SSOT 수정 불가피 시 BLOCKED 전이 후 보고. BLOCKED에서도 훅이 막으므로 수정은 DONE 뒤 | entrypoint §3.4 | CRITICAL |
| LOCK-3 | 변경 후 리로드 필수 | SSOT 변경 후 모든 팀원에게 SendMessage로 리로드 지시 | entrypoint §3.4 | CRITICAL |
| LOCK-4 | 팀원 SSOT 수정 금지 | 팀원은 SSOT 읽기 전용 | entrypoint §3.4 | CRITICAL |
| LOCK-5 | 변경 이력 필수 기록 | SSOT 변경 시 버전 히스토리에 기록 | entrypoint §3.4 | HIGH |
| LOCK-6 | 정본 규율 | 규칙 ID마다 정본은 한 곳 — 원본 칸이 가리키는 곳이 이기고 공동 정본은 두지 않는다. 역할 문서는 ID + 정본 경로 + 적용분만 쓰고 재서술하지 않는다. 사본에만 있는 조건은 정본으로 올리고, 역방향 의존(정본이 역할 문서 · SUB-SSOT의 정의에 기댐)은 한쪽으로 정리한다(역할 문서 · SUB-SSOT 쪽 등재는 원본 칸이 그 경로를 가리킬 때). 그 역할만 수행하는 절차는 ROLES 안에 정본을 둘 수 있다(원본 칸이 그 경로를 가리킬 때). 이름 규칙도 행을 가지고, 행 없는 ID는 정의하거나 인용을 지운다. 정본 절에 ID. 정본끼리 충돌하면 사용자 결정. 에이전트 정의는 ID별 핵심어를 요약과 맞춘다 | entrypoint §3.4 | HIGH |
| LOCK-7 | 변경 순서 · 편집자 재확인 | 정본 → rules-index → ROLES · SUB-SSOT 인용 → 에이전트 정의 · 스킬 → MANIFEST 재생성(역순 금지). 편집자 DoD: 영향 인용 수집 · 사본 분류 · 짝 스캔 네 축(규칙 ID · 계열 · 입력물 사본 · 새 동작에서도 참인가) · rules-index 동기화 · 3자 정합 표를 G2 요청 전에 마쳐 붙인다. 뒤 단계를 다음 커밋으로 넘기면 그 커밋을 DoD에 적는다 — MANIFEST 재생성은 별도 커밋이 기본이라 넘김 기록을 생략한다. 사용자 결정을 반영하는 편집은 결정 반영표를 편집자가 먼저 쓴다 | entrypoint §3.4 | HIGH |

### 1.3 FRESH — SSOT 신선도 & 컨텍스트

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| FRESH-1 | 작업 착수 전 SSOT 로딩 | 실제 작업 지시를 받으면 entrypoint → workflow 순서로 로딩. 단순 질문에는 로딩 안 함 | entrypoint §3.5 | CRITICAL |
| FRESH-2 | 새 Phase 시작 시 버전 확인 | entrypoint `SSOT 버전` ↔ status ssot_version 일치 확인 | entrypoint §3.5 | HIGH |
| FRESH-3 | 버전 불일치 시 갱신 우선 | 버전 변경 감지 시 Phase 전 리로드 | entrypoint §3.5 | CRITICAL |
| FRESH-4 | 리로드 시각 기록 | ssot_loaded_at에 타임스탬프 기록 | entrypoint §3.5 | MEDIUM |
| FRESH-5 | 장기 세션 주기적 확인 | Task 3개+ 처리 시 SSOT 버전 재확인 권장 | entrypoint §3.5 | MEDIUM |
| FRESH-6 | 팀원 역할별 로딩 | 스폰 시 base 세트(스폰 주입표 팀원 행)만 로딩, 그 밖은 HANDOFF-3 요청 | entrypoint §3.5 | HIGH |
| FRESH-7 | 컨텍스트 복구 시 리로드 | 압축·중단 후 SSOT 리로드 + status + 팀 확인 필수 (=HR-3) | entrypoint §3.5 | CRITICAL |
| FRESH-8 | 리팩토링 레지스트리 관리 | Phase 완료 시 500줄 초과 등록, Master Plan 시 700줄 초과 확인 | entrypoint §3.5 | HIGH |
| FRESH-11 | 공통 레이어 필수 | SUB-SSOT 로딩 시 CORE/shared-definitions.md 함께 로딩 | entrypoint §3.5 | HIGH |
| FRESH-12 | SUB-SSOT 독립 검증 | 그 역할의 base 세트(스폰 주입표 자기 행)와 함께 로딩해 역할 작업을 끝낼 수 있어야 한다. 참조 무결성 필수 | entrypoint §3.5 | MEDIUM |

### 1.4 ENTRY — 진입점 프로토콜

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| ENTRY-1 | 단일 진입점 | status.md를 먼저 읽고 시작 | entrypoint §3.6 | CRITICAL |
| ENTRY-2 | 상태 기반 분기 | current_state 값에 따라 행동 결정 | entrypoint §3.6 | CRITICAL |
| ENTRY-3 | SSOT 버전 확인 | 진입 시 ssot_version ↔ entrypoint `SSOT 버전` 일치 확인 | entrypoint §3.6 | CRITICAL |
| ENTRY-4 | Blocker 우선 확인 | blockers 비어있지 않으면 Blocker 해결 우선 | entrypoint §3.6 | HIGH |
| ENTRY-5 | 직접 시작 금지 | status 파일 미확인 후 Task 시작 금지 | entrypoint §3.6 | CRITICAL |

### 1.5 CHAIN — Phase Chain & 순차 실행

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| CHAIN-1 | Phase 독립성 | 각 Phase는 단독 실행 가능해야 함 | phase-chain §5 | HIGH |
| CHAIN-2 | /clear 필수 | Phase 간 전환 시 /clear로 토큰 초기화 | phase-chain §5 | CRITICAL |
| CHAIN-3 | Chain 파일 유지 | /clear 후에도 Chain 파일은 디스크에 영속 | phase-chain §5 | MEDIUM |
| CHAIN-4 | 순차 보장 | phases 배열 순서대로만 실행, 건너뛰기 금지 | phase-chain §5 | CRITICAL |
| CHAIN-5 | 완료 리포트 | Phase DONE 시 1줄 요약을 Chain 파일에 기록 | phase-chain §5 | MEDIUM |
| CHAIN-6 | 산출물 의무 | plan/todo-list/tasks/status 최소 필수 (=HR-2) | phase-chain §5 | CRITICAL |
| CHAIN-7 | Gate 의무 | G1~G4 생략 불가 | phase-chain §5 | CRITICAL |
| CHAIN-8 | Status 형식 | status.md는 YAML frontmatter 형식 | phase-chain §5 | HIGH |
| CHAIN-9 | Task 문서 형식 | 메타 필드 + §1~§4 섹션 번호 + 선택 칸 「COMMENT-3 요청」(발동 때만) | phase-chain §5 | HIGH |
| CHAIN-10 | 파일 경로 규칙 | 디렉토리 구조 Glob 확인 후 생성 (=HR-4) | phase-chain §5~§6 | CRITICAL |
| CHAIN-11 | Master Plan 완료 보고서 | Master Plan 전체 완료 시 final-summary-report.md 작성 필수 | phase-chain §5 | HIGH |

### 1.6 EDIT — 코드 편집 권한 & 도메인 경계

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| EDIT-1 | 도메인별 편집 범위 | backend-dev·frontend-dev: 각자의 담당 구역(PROJECT.md §3), designer: 디자인 구역(화면 시안 HTML+CSS, 제품 코드 없음) | entrypoint §3.1 | CRITICAL |
| EDIT-2 | Team Lead 코드 수정 금지 | Team Lead → 팀원 위임 (=HR-1) | entrypoint §3.1 | CRITICAL |
| EDIT-3 | 상태·SSOT 쓰기 독점 | status.md와 SSOT는 Team Lead만 수정 | entrypoint §3.1 | CRITICAL |
| EDIT-4 | 읽기 전용 팀원 | verifier·planner는 편집 도구(Edit·Write) 없음, Bash로도 파일을 쓰지 않음. REPORT-1 결과 파일(`/tmp/agent-messages/`)만 예외 | entrypoint §3.1 | HIGH |
| EDIT-5 | 동시 편집 금지 | 동일 파일 두 팀원 동시 편집 금지, [FS] BE→FE 순차 | entrypoint §3.1 | HIGH |

### 1.7 GATE — 품질 게이트

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| G1 | Plan Review | 완료 기준 명확 · Task 3~7개 · 도메인 분류 · 리스크 식별 · 백엔드 API Spec · DB 스키마 · 프론트엔드 페이지 구조 · 동선 · 정본 컴포넌트 목록 · DESIGN_REVIEW 필요 여부. 판정 Team Lead | handoff/planning §2 | CRITICAL |
| G2 | Code Review | Critical 0건 · 입력 검증(백엔드) · XSS 방지(프론트엔드) · 정본 컴포넌트 재사용(REUSE-1) · 보안 취약점 없음 · 주석 규격 NOTE-1~6(제품 코드). 세부 항목은 G2_be · G2_fe · G2_DS, 등급은 verification-procedure §G2 판정 기준 「등급 산출」 표 | handoff/verifying §1 | CRITICAL |
| G3 | Test Gate | 테스트 PASS · 커버리지 ≥80%(백엔드) · 페이지 로드 OK · 콘솔 에러 0건(프론트엔드) · E2E PASS · 회귀 통과 · 결함 밀도 ≤ 5건/KLOC. tester가 PASS/FAIL을 판정해 보고하고 최종 판정은 Team Lead | handoff/testing §1 | CRITICAL |
| G4 | Final Gate | G2+G3 PASS + Blocker 0건. 입력: G2 · G3 결과 파일 + planner 계획서 이행 점검(VUL3). 판정 Team Lead | entrypoint §3.7 | CRITICAL |
| G2_be | G2 백엔드 세부 | 백엔드 G2 판정 항목과 등급 | verification-procedure §G2 판정 기준 | CRITICAL |
| G2_fe | G2 프론트엔드 세부 | 프론트엔드 G2 판정 항목과 등급(REUSE-1 포함) | verification-procedure §G2 판정 기준 | CRITICAL |
| G2_DS | G2 디자인 세부 | 디자인 시안 G2 판정 항목과 등급(REUSE-1 포함) | verification-procedure §G2 판정 기준 | CRITICAL |

### 1.8 ERROR — 에러 처리

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| E0 | Critical 에러 | 즉시 중단, 사용자 보고 | workflow §4 | CRITICAL |
| E1 | Blocker 이슈 | BLOCKED 전이, Fix Task 생성 | workflow §4 | HIGH |
| E2 | High 이슈 | REWINDING, 수정 요청 | workflow §4 | HIGH |
| E3 | Medium 이슈 | Technical Debt 등록 | workflow §4 | MEDIUM |
| E4 | Low 이슈 | 기록만 | workflow §4 | LOW |

### 1.9 REFACTOR — 코드 유지관리

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| REFACTOR-1 | Phase 완료 시 코드 스캔 | 500줄 초과 파일 레지스트리 등록 | refactoring-rules §0 | HIGH |
| REFACTOR-2 | Master Plan 시 편성 | 700줄 초과 Lv1 분리 편성 (분리 부적합은 [예외]) | refactoring-rules §0 | HIGH |
| REFACTOR-3 | 신규 파일 사전 방지 | PLANNING/BUILDING/G2에서 신규 파일 500줄 초과 방지. 기존 파일 확장은 REFACTOR-1 관심선 등록 대상 | refactoring-rules §0 | MEDIUM |

### 1.14 ASSIGN — Task 할당 규칙

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| ASSIGN-1 | 도메인-역할 매핑 필수 | 구현 팀원은 entrypoint §3.8 도메인 태그 표대로 할당 | workflow §TASK_SPEC | CRITICAL |
| ASSIGN-2 | [TEST] tester 전용 | [TEST] Task를 구현 역할(backend-dev/frontend-dev)에 할당 금지 | workflow §TASK_SPEC | CRITICAL |
| ASSIGN-3 | 할당 전 도메인-역할 검증 | assignee 지정 시 도메인↔역할 일치 검증 필수 | workflow §TASK_SPEC | CRITICAL |
| ASSIGN-4 | 스크립트 실행·분석 Task | 코드 미작성 Task(평가/분석)는 tester/verifier에 할당 | workflow §TASK_SPEC | CRITICAL |
| ASSIGN-5 | Team Lead 통제 의무 | 모든 검증·테스트·QC 작업이 구현자에게 할당되지 않았는지 3단계(스폰·할당·진행 중) 능동 감시 | workflow §TASK_SPEC | CRITICAL |
| ASSIGN-6 | 편집자 · 판정자 · 이관 결정자 겸직 견제 | 편집자 · 실행자인 Task에서 G2 · G3 High 이상을 낮추거나 tech-debt로 넘길 때 결정자 · 근거 · 사용자 확인을 status 로그에 적는다. 판정자는 판정 입력(tester · verifier 보고서)을 고치지 않는다. Team Lead는 [TEST] 실행 결과를 스스로 만들어 판정 근거로 쓰지 않는다. Team Lead가 `LEAD_SELECTED`로 고른 컴포넌트의 G2_DS 판정은 verifier가 한다(entrypoint §3.8) | workflow §TASK_SPEC | HIGH |

### 1.15 LIFECYCLE — 에이전트 라이프사이클 관리

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| LIFECYCLE-1 | 5분 무보고 점검 | 5분 이상 보고 없으면 역할·Task 점검 후 필요 시 종료. 예외: 상주 역할(planner)은 대기를 할당 상태로 본다 | workflow §AGENT-LIFECYCLE | CRITICAL |
| LIFECYCLE-2 | 미사용 에이전트 즉시 종료 | 할당 Task가 없거나 모두 완료된 에이전트 즉시 shutdown. 예외: 상주 역할(planner 또는 respawn 이름 `planner_r1`~`planner_r5`)은 G4 입력 제출까지 대기를 할당 상태로 본다 | workflow §AGENT-LIFECYCLE | CRITICAL |
| LIFECYCLE-3 | 종료 전 Task 상태 확인 | 미완료 Task 재할당/보류 판단 후 종료 | workflow §AGENT-LIFECYCLE | HIGH |
| LIFECYCLE-4 | 팀 해산 시 전원 종료 | 모든 팀원 shutdown 후 팀 config에 team-lead만 남았는지 확인 · 센티넬 해제 확인. 비정상 종료 멤버가 config에 남으면 LIFECYCLE-5(생존 확인)로 처리하고 status에 기록 | workflow §AGENT-LIFECYCLE | HIGH |
| LIFECYCLE-5 | 좀비 감지 + Respawn | spawn 30초 1차 + 3분 정기 check. 좀비 확정 시 shutdown_request + suffix(`_r1`~`_r5`) respawn, 상한 5회 도달 시 BLOCKED | SUB-SSOT TEAM-LEAD `lifecycle-procedure.md` §LIFECYCLE-5 RESPAWN (workflow §AGENT-LIFECYCLE = 요약) | CRITICAL |
| LIFECYCLE-6 | 체크 스케줄러 | LIFECYCLE-1·5의 실행체. 팀원 ≥1 Phase는 팀원 0→1 스폰 직후 워처 arm(BUILDING 진입 시 미arm이면 진입 차단 — 2차 방어선). 3분 폴링 + spawn+30초 1차 체크. 알림은 기동 시 한 번, ZOMBIE는 매 주기, 그 밖에는 상태가 바뀔 때. 하위 규칙 LIFECYCLE-6.1(아래 행) | SUB-SSOT TEAM-LEAD `lifecycle-procedure.md` §LIFECYCLE-6 SCHEDULER (workflow §AGENT-LIFECYCLE = 요약) | CRITICAL |
| LIFECYCLE-6.1 | SPAWN_GATE | 팀원을 스폰하는 모든 상태 진입과 상태 진입 밖 스폰(respawn · Task별 추가 · 겹침 판정자), 곧 모든 스폰에 적용한다: 스폰 → 임무 전달 → 준비 신호 60~90초 대기 → 판정. 무응답은 `SPAWN_UNCONFIRMED` — 자동 respawn 금지, 시그널 #1 · #2 객관 판정으로 전환 | SUB-SSOT TEAM-LEAD `lifecycle-procedure.md` §SPAWN_GATE | CRITICAL |

### 1.16 REPORT — 팀원 보고 방식

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| REPORT-1 | 보고 경로 | 보고 본문=`/tmp/agent-messages/<phase>-<role>.json`(또는 `.md`) 파일 기록 + SendMessage=결론 요지+경로 통지(통지 수신 뒤 회수 — 감시 도구는 있으면 보조). 전 역할 의무. 파일 본문은 고정 블록 형식 | handoff/common §4 | HIGH |
| REPORT-2 | 필수 칸 | 한 일 · 결과(검증 명령·출력 요지) · 안 본 것 · 지시와 다르게 한 것 · 막힌 것 · 다음 제안. 빈 칸은 「없음」 | handoff/common §4 | HIGH |
| REPORT-3 | 중간 보고 | 지시에서 정한 시점에 보냄 | handoff/common §4 | MEDIUM |
| REPORT-4 | 핵심 먼저 | 결론을 앞에, 길면 나눠 보냄 | handoff/common §4 | MEDIUM |
| REPORT-5 | 커밋은 Team Lead | 팀원 커밋·스테이징 금지, 지시로 위임한 경우만 예외 | handoff/common §4 | HIGH |
| REPORT-6 | 파일 상태로 판정 | Team Lead는 git diff·검증 명령 재실행으로 판정, 늦은 메시지를 멈춤으로 단정 금지 | handoff/gate §2 | HIGH |

### 1.17 NOTIFY — Telegram 완료 알림

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| NOTIFY-1 | Phase DONE 시 Telegram 알림 필수 | DONE 전이 즉시 `scripts/pmAuto/report_to_telegram.sh` 실행. **생략 시 DONE 전이 무효** | workflow §3 DONE | CRITICAL |
| NOTIFY-2 | 알림 메시지 형식 | `✅ Phase {N}-{M} 완료: {요약} / 📊 결과 / 📁 보고서 경로` 형식 준수 | workflow §3 DONE | HIGH |
| NOTIFY-3 | Master Plan 완료 시 종합 알림 | 전체 Chain 완료 시 Sub-Phase별 요약 포함 종합 알림 발송 | workflow §3 DONE | HIGH |

### 1.20 PROMPT — 프롬프트 품질 규칙

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| PROMPT-QUALITY | 프롬프트 품질 항목 점검 | `/plan` 호출 시 master-plan 작성 전 Pre-draft 단계에서 완전성·명료성·실행 가능성·범위 적정성·트리아지 항목 판정 필수. Fast-path: 전 항목 자명 PASS 시 템플릿 작성 생략 허용 (master-plan에 `prompt_quality: fast-path` 표기) | TEMPLATES/pre-draft-topics.md | HIGH |

**항목 판정 기준**:
1. **완전성** — 사용자 관점 + 개발자 관점 양쪽 도출 가능
2. **명료성** — 모호 용어 0건 (또는 전부 "TBD" 명시 표기)
3. **실행 가능성** — 기술적 Show-stopper 없음 (리서치 필요 항목은 플래그)
4. **범위 적정성** — 단일 Phase 적정 / 분할 필요 판정 완료
5. **트리아지** — 즉시 진행 / 재질문 / 분할 / 취소 중 1건 선택

### 1.21 WT — Worktree (병렬 격리)

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| WT-1 | worktree 필수 조건 | 병렬 BUILDING 트랙 수 ≥ 2 일 때 worktree 없이 BUILDING 진입 금지. A/B 분기(worktree §3)·REWINDING(worktree §2) 에서도 적용 | [worktree §5](../WORKFLOW/worktree.md#5-worktree-규칙-wt-1--wt-5) | CRITICAL |
| WT-2 | 경로 규약 | `../{project}-wt-phase-{X}-{Y}-{track}` 패턴만 허용. 저장소 내부 `.worktrees/` 배치 금지 (gitignore 누락 시 재귀 노출 위험) | [worktree §5](../WORKFLOW/worktree.md#5-worktree-규칙-wt-1--wt-5) | HIGH |
| WT-3 | CWD 일관성 | 팀원은 스폰 시 주입된 worktree 경로 밖에서 편집·빌드 금지. 위반 시 즉시 작업 중단·재할당. BUILDING 단락 CWD 주입 규칙과 연계 | [worktree §5](../WORKFLOW/worktree.md#5-worktree-규칙-wt-1--wt-5) | CRITICAL |
| WT-4 | 수명 주기 | Phase Chain 완료 시 `git worktree remove` + `git worktree prune` 일괄 수행. 실패 브랜치(REWINDING)·A/B 비선택 브랜치는 worktree §4 아카이브 규칙 준수 후 제거 | [worktree §5](../WORKFLOW/worktree.md#5-worktree-규칙-wt-1--wt-5) | HIGH |
| WT-5 | 상태 기록 | `phase-{X}-{Y}-status.md` YAML 에 `worktree_paths: []` 와 `cleanup_wt: pending\|done` 필드 필수 기록(worktree를 만들지 않는 Phase는 `null`) | [worktree §5](../WORKFLOW/worktree.md#5-worktree-규칙-wt-1--wt-5) | MEDIUM |
| **WT-6** | **휴리스틱 룰** | 신호 셋 S1+S5+S6 기반 worktree 발동 3분 판정 (필요/권장/불필요). 우선순위 S6 > S5 > S1. **자동 발동 금지** (사용자 통제권 보장). 정본 §6 D1~D4 | [worktree §6](../WORKFLOW/worktree.md#6-wt-6--worktree-발동-휴리스틱-룰) | **HIGH** |
| **WT-7** | **게이트 체인** | G-A(계획 시 판정 안내) → G-C(BUILDING 차단) → G-D(verifier G2 적발) → G-E(VERIFYING 후 차기 Phase 권고). 앞 게이트 누락을 다음 게이트가 적발. Team Lead · verifier가 지키는 절차 게이트이며 훅이 검사하지 않음 | worktree §7 · §1.2 G-C | **HIGH** |
| **WT-8** | **팀원 자율 worktree** | 기능 분리·별도 시험용. BE: Spike·의존성 교체·마이그레이션 리허설·리팩토링 비교·성능 측정(구현 전 대안 비교만) / FE: Spike·UI 대안·공용 컴포넌트 영향·빌드 설정 / DS: 이전 버전 화면 비교. 승인 없이 만들고 즉시 보고, 병합·커밋 금지 | handoff/common §3 | HIGH |
| G-A | worktree 판정 안내 | 계획 작성 시 병렬 트랙이 2개 이상이면 status `expected_tracks` · `worktree_required: true`를 적고 "worktree 필요/권장"을 안내 | worktree §7 | HIGH |
| G-C | BUILDING 차단 | 병렬 트랙 ≥ 2인데 `worktree_paths: []`이면 BUILDING 전이 금지 | worktree §1.2 G-C | HIGH |
| G-D | G2 적발 | `expected_tracks` ≥ 2인데 worktree가 없으면 결함으로 적고 등급 · 판정 규칙과 무관하게 G2 FAIL | worktree §7 | HIGH |
| G-E | 사후 권고 | VERIFYING 뒤 임계값(테스트 FAIL 30% · R ≥ 1인 High 이상 5건) 판정은 Team Lead → 차기 Phase 권고 기록 | worktree §7 | MEDIUM |

**연계 규칙**: EDIT-5 (병렬 ≥ 2 일 때 worktree 필수 보강) · CHAIN-5/NOTIFY-1 (Chain 완료 시 cleanup + prune 동기) · **WT-7 G-C** ↔ §3 `BRANCH_CREATION → WORKTREE_SETUP` 차단 게이트

---

### 1.22 HANDOFF — 전달 게이트

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| HANDOFF-1 | 전달 시점 | 팀원 수행 상태 진입 시 게이트 통과 후 스폰·지시 | handoff/gate §1 | HIGH |
| HANDOFF-2 | 전달물 | base SSOT(스폰 주입표 팀원 행) + 업무 지시. SSOT 전체·다른 단계 단위 전달 금지 | handoff/gate §1 | CRITICAL |
| HANDOFF-3 | 추가 로드 요청 | 팀원은 `[SSOT 요청]`으로 요청, Team Lead가 파일:절 지정 승인 | handoff/gate §1 (팀원 쪽 절차: handoff/common §1) | HIGH |
| HANDOFF-4 | 통과 조건 | base 세트 · 담당 구역 · 역할별 병렬 정책 · 보고 형식이 정해져야 스폰·지시 | handoff/gate §1 | CRITICAL |
| HANDOFF-5 | 기록 | 추가 로드 내역은 보고의 「지시와 다르게 한 것」 칸 | handoff/gate §1 | MEDIUM |
| HANDOFF-6 | 판정 대상 SHA 고정 | G2 · G3 요청에 대상 SHA · worktree 경로를 적고, 결과 파일을 쓰는 팀원(verifier · tester)은 그 SHA로 읽고 측정한다. 회신 전 수정은 amend · rebase 없이 새 커밋 · 새 SHA로 다시 요청 | handoff/gate §1 | HIGH |

---

### 1.23 COMMENT · NOTE — 주석

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| COMMENT-1 | 주석은 최소한으로 | 코드만으로 알 수 없는 동작의 이유·제약만. 참조·과거 이력·과정·이슈 서술·개수·버전·코드 반복·주석 내 코드 예시·블록 표지(구분선 `# ====`·`# ----`) 금지. 규격 표지의 작성일 · 수정일 칸은 이력이 아니다. `PROJECT.md` §4 주석 규칙이 우선. 하네스 · scratchpad 임시 도구가 대상인 베이스. 적용은 작성자가 아니라 파일 위치 기준 — 제품 코드 구역(`PROJECT.md` §3)의 코드·마크업 주석은 누가 쓰든 NOTE-1~6 | handoff/common §5 | HIGH |
| COMMENT-2 | 기존 주석은 건드릴 때 정리 | 일괄 정리 금지. 건드리는 블록만 규격화(touch-and-clean), 의도·이력은 `point-N` 이관, 잔여 규모는 `comment-lint.py scan`으로 규모를 재고 부채 레지스트리에서 소진 추적. 적용은 작성자가 아니라 파일 위치 기준 — 제품 코드 구역(`PROJECT.md` §3)의 주석에 적용하고, 구역 밖 하네스는 COMMENT-1만 따른다. 판정 범위: `lint <대상> --changed <기준 커밋>` 위반 0이 기준이며 위반이 있으면 결함, 파일 전체 위반 수가 부채 레지스트리 기준선보다 늘어도 결함이다(등급은 VP §G2 판정 기준 「등급 산출」 표). 예외: COMMENT-3 | handoff/common §5 (절차: comment-policy §3) | CRITICAL |
| COMMENT-3 | 주석 전체 정리 게이트 | 사용자가 파일을 지정해 요청할 때만 그 파일 주석 전체를 규격으로 정리(주석 전용 Task · 커밋, 기능 변경 혼입 금지). 이 게이트 안에서만 `lint <파일>` 위반 1건 이상 · 주석 외 변경 · 요청 기록 없음은 결함이다(죽은 참조는 게이트와 무관하게 파일 단위로 결함 — NOTE-6). 등급은 VP §G2 판정 기준 「등급 산출」 표. Team Lead · 팀원은 발동하지 않는다(Team Lead는 제안만) | handoff/common §5 (절차: orchestration §업무 지시 규약 · comment-policy §3.1) | CRITICAL |
| NOTE-1 | 주석은 최소로 | 제품 코드·마크업 주석은 코드의 역할·작동 방식만. 형식 `Name : 한글명 · YYMMDD`. 설명하지 않는다 | comment-policy §1.1 | CRITICAL |
| NOTE-2 | 수치·설명·이력·과정·코드 예시 금지 | 수치·수식·개수, 서술형 설명, 날짜·Phase·결함 번호, 개발 과정·이슈, 주석 안의 코드 예시를 쓰지 않는다 | comment-policy §1.3 | CRITICAL |
| NOTE-3 | 순번 허용·결번 유지 | 탭·콘텐츠 등장 순번은 허용(`TabCont1`). 삭제해도 번호를 당기지 않고 결번을 둔다 | comment-policy §1.4 | CRITICAL |
| NOTE-4 | 닫는 표지 필수 | 여는 표지에는 `// Name` 닫는 표지를 예외 없이 둔다. 판정은 스택으로 한다 | comment-policy §1.1 · §1.5 · §4.2 | CRITICAL |
| NOTE-5 | 주석으로 결론을 내지 않는다 | 읽기 3단계 — L1 주석(결론 금지) / L2 `point-N` / L3 코드 흐름. 공용 값·분기 조건은 L3 필수. lint 대상이 아니고 verifier가 G2에서 판독한다 | comment-policy §6 | CRITICAL |
| NOTE-6 | 오류 참고는 point-N으로 | 코드에는 식별자만. 내용은 `docs/comment-policy/points/point-{번호}-{주제어}.md` 한 항목 한 파일 | comment-policy §2 | CRITICAL |

- COMMENT-1은 하네스(SSOT·훅·스킬·스크립트) · scratchpad 임시 도구의 베이스다 — 구역 밖 하네스는 COMMENT-1로 판정한다. NOTE-1~6은 제품 코드 구역(`PROJECT.md` §3)의 코드·마크업 주석 규격이다. 등급은 VP §G2 판정 기준 「등급 산출」 표(comment-policy §7). 적용은 누가 쓰든 파일 위치로 가린다(handoff/common §5). 검사 도구: `scripts/comment/comment-lint.py`. NOTE-5는 읽는 쪽 규칙이라 산출물 검사(lint) 대상이 아니고, verifier가 G2에서 판독 절차(L3 → L2 → L1)로 본다

---

### 1.24 DELEGATE — 업무 지시 규약 (scoped delegation)

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| DELEGATE-1 | 범위 좁힘 | 위임 대상을 파일:라인 · 블록명(주석 Name) · `point-N` · 담당 구역으로 좁혀 지정 | orchestration §업무 지시 규약 | HIGH |
| DELEGATE-2 | 방향 가이드 | "어떻게 해라"(접근 · 해결 형태 · 참고 사례)를 함께 준다. 단순 지시 전달 금지 | orchestration §업무 지시 규약 | HIGH |
| DELEGATE-3 | 개방형 금지 | "전체를 파악하라" 식 개방형 전체 파악 지시 금지. 팀원은 좁힌 범위 내에서 해결 | orchestration §업무 지시 규약 | HIGH |
| DELEGATE-4 | 업무 지시 3단계 | 과업을 받으면 ① 현행 소스 · 정본을 파일:줄로 조사하고 ② 가장 비슷한 외부 사례를 찾아 출처와 함께 적용 방향을 정하고 ③ 사용자와 조율할 항목을 질문 목록으로 만든 뒤 지시한다. planner는 ③을 Team Lead에게 넘기고 사용자에게 직접 묻지 않는다(COMM-2). 적용 대상: Team Lead · planner | orchestration §업무 지시 규약 | HIGH |

---

### 1.25 SUBAGENT · SCOPE — 서브에이전트 스코핑 (Lead 전용)

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| SUBAGENT-1 | 스폰 Lead 전용 | 서브에이전트 스폰은 Team Lead 전용. 팀원(pab-*)은 스폰 도구(`Agent`)가 없다 — Bash로 `claude`를 띄우는 것도 스폰하지 않는다 | orchestration §서브에이전트 스코핑 (entrypoint §3.1 = 인용) | HIGH |
| SCOPE-1 | 스코핑 오프로드 | Lead는 범위 좁힘을 read-only · 일회성 탐색 서브에이전트(`Agent` 도구, 팀 밖)에 위임 가능. 반환은 scope map만, 파일 덤프 금지. scope map 수령 시 종료 확인. 구현·게이트는 Agent Team | orchestration §서브에이전트 스코핑 | MEDIUM |

---

### 1.26 COMM — 소통

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| COMM-1 | 착수 확인 | 지시 수신 즉시 한 줄 ack. REPORT-3·SPAWN_GATE 준비 신호와 연계 | handoff/common §6 | MEDIUM |
| COMM-2 | Hub-and-Spoke | 모든 통신은 Team Lead 경유. 팀원 간 직접 메시지 금지 | handoff/common §6 (entrypoint §3.3 = 인용) | HIGH |
| COMM-3 | 송신 규약 | 한 통에 한 과업 · 지시 ID · ack에 ID 복창. 처리 중인 지시가 있으면 겹쳐 보내지 않는다. 보류 · 취소는 파일 신호(`.hold`), 팀원은 작업 경계마다 확인. 옛 ID 메시지는 따르지 않고 보고만 | handoff/common §6 | HIGH |
| COMM-4 | 범위 축소 금지 | 팀원은 지시 범위(대상 · 항목 · 지표)를 스스로 줄이거나 넓히지 않는다. 줄여야 하면 `SCOPE_REDUCTION_PROPOSAL`로 Team Lead 승인 후 진행 | handoff/common §6 | HIGH |

---

### 1.27 REUSE — 컴포넌트 재사용

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| REUSE-1 | 정본 재사용 | 정본 존재 유형의 미재사용·유사 신규 생산 = 결함(G2_fe · G2_DS, 등급은 verification-procedure §G2 판정 기준 「등급 산출」 표) | handoff/common §7 (등급 판정: verification-procedure §G2 판정 기준) | CRITICAL |
| REUSE-2 | 신규는 사유 + Team Lead 선행 선택 | 착수 전에 재사용 불가 사유(정본 부재 증거 또는 기능 차이 근거)를 Team Lead에게 보고 → Team Lead가 심사해 선택하고 레지스트리에 `LEAD_SELECTED`로 표기하면 개발. 사유가 요건을 채우지 못하면 무효. 팀원 자기 선택 불인정. `LEAD_SELECTED`를 `HUMAN_APPROVED`로 기록 금지. 사용자는 사후 검토 — 결과(`HUMAN_APPROVED` 또는 변경)는 레지스트리에 누적. 정본 존재 유형의 미재사용은 REUSE-1 결함, 정본 부재 유형의 선택 표기(`LEAD_SELECTED`) 누락도 결함이다 — 등급은 verification-procedure §G2 판정 기준 「등급 산출」 표 | handoff/common §7 (심사 절차: verification-procedure §재사용 불가 사유 심사 · fn-procedure GATE 5) | HIGH |
| REUSE-3 | 레지스트리 단일 원본 | 정본은 `PROJECT.md` §3.1 정본 컴포넌트 레지스트리가 정한다. 선택된 신규는 Team Lead가 `LEAD_SELECTED`로 등록, 사용자 검토 결과 · 변경 이력 누적. planner는 Task에 정본 목록 명시 | handoff/common §7 (레지스트리: PROJECT.md §3.1) | HIGH |

---

### 1.28 TOOL — 도구 사용 (TOOL-GUARD)

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| TOOL-1 | 기존 도구 우선 | `build_cmd`·`test_cmd`·`lint_cmd`·`comment-lint.py`(`lint --changed` 포함)·`refactor-scan` 먼저. 탐지 기계화는 기존 도구 확장만, 신규 도구 금지 | handoff/common §8 | HIGH |
| TOOL-2 | 신규 임시 도구는 승인 | 기존 도구로 안 되는 이유를 보고하고 Team Lead 승인 후 제작 | handoff/common §8 | HIGH |
| TOOL-3 | scratchpad 한정 · 수명 | 임시 도구는 scratchpad에만, 수명 명시. Phase 종료 시 폐기 또는 정식 편입 판정 | handoff/common §8 | MEDIUM |
| TOOL-4 | 정본 승격 | 세 번 이상 재사용된 도구만 정본 승격 검토 | handoff/common §8 | MEDIUM |
| TOOL-5 | 과업 치환 방지 | 도구 개선보다 본과업 먼저. 개선 요청은 tech-debt로 | handoff/common §8 | HIGH |
| TOOL-6 | 되돌리기 어려운 조작 사전 확인 | 위험 등급별 확인 수준 — 가역: 확인 없음 / 되돌리기 어려움(설치 · 삭제 · 커밋 · 프로세스 종료 · 라이브 경로 쓰기): 한 줄 계획 + ack 후 실행 + 전후 상태 기록 / 외부 게시(push · 알림 · 원격 쓰기): 사용자 확인(Team Lead 경유) | handoff/common §8 | HIGH |
| TOOL-GUARD | 도구 사용 규칙 묶음 | TOOL-1~6을 묶어 부르는 이름 | handoff/common §8 | HIGH |

---

### 1.29 SUB-SSOT 공통 포맷 이름

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| GATE_FORMAT | GATE 포맷 | GATE 체크리스트 항목은 한 줄씩 `[PASS/FAIL/N/A] 항목 — 근거` 로 판정. 일괄 선언은 GATE 실패 | shared-definitions §1.1 | HIGH |
| ANTI-COMPRESSION | 일괄 응답 금지 | 각 체크리스트 항목은 자체 줄에 개별 응답. 일괄 응답은 무효 · 재평가 | shared-definitions §1.2 | HIGH |
| ROLE_CHECK | 역할 선언 | STEP · PHASE 시작 시 현재 역할(PLANNER · CODER · REVIEWER · VALIDATOR)과 금지 행동을 선언 | shared-definitions §2.1 | HIGH |
| VAL | 검증 결과 기록 | 명령어 · 출력(실제 stdout 3줄 이상) · 결과 · 실행시각. 출력이 없으면 자동 FAIL | shared-definitions §4.2 | HIGH |
| FAIL_COUNTER | 실패 카운터 | 동일 항목 1회 실패 → 수정 후 재검증(자율), 2회 연속 → 계획 재검토, 3회 연속 → HUMAN_ESCALATION_REQUEST, 실패율 30% 초과 → 이전 단계 복귀, 반복 3회 초과 → HUMAN_ESCALATION_REQUEST | shared-definitions §4.3 | HIGH |
| GATE 0~7 | fn 절차 게이트 | IMPL_GRANULARITY = FN 요청의 dev fn 절차 단계 게이트(PHASE 0~7마다 하나). 항목마다 GATE_FORMAT · ANTI-COMPRESSION으로 판정 | fn-procedure §0.3 · §1.3 · GATE 2~6 · §7.5 | HIGH |
| VUL1 | 샘플 코드 경계 검증 | 프로토타입 코드의 import · 범위 상한 · 커버리지 · 격리 · 헤더 · 인증 적용을 VUL1-01~06으로 점검 | shared-definitions §6.1 | MEDIUM |
| VUL2 | 호환성 충돌 감사 | 충돌 로그와 Type A~E 해결 기록을 VUL2-01~05로 점검 | shared-definitions §6.2 | MEDIUM |
| VUL3 | 범위 무결성 감사 | 산출물 수 · VAL 항목 추이 · TODO 완료 · DEVIATION 영향 · 목표 일치를 VUL3-01~05로 대조. planner 계획서 이행 점검(G4 입력)의 기준 | shared-definitions §6.3 (G4 입력: entrypoint §3.7) | HIGH |

---

### 1.30 OPS — 운영 원칙

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| OPS-1 | 요구사항 우선 | 요청자 요구사항이 최우선. 순위는 사용자에게 질의해 정하고 임의로 바꾸지 않는다 | workflow §6 | HIGH |
| OPS-2 | 발견 문제 | 계획 밖 문제는 `reports/issue-*.md`로 검토 · 결정 뒤 반영. 팀원은 발견 사실만 보고(COMM-4), 리포트는 Team Lead가 쓴다. 판정자의 「관찰」도 받은 회차에 처리 경로를 status에 적고, 사용자 결정과 닿는 관찰은 수용으로 닫지 않는다 | workflow §6 | HIGH |
| OPS-3 | 예산 | 착수 때 예상 · 상한 · 중간 보고 지점을 승인받아 status `token_budget`에 적고, 예상 안에서 최대 완성을 지향하며, Task 수령마다 계측(`CORE/shared-definitions.md` §8). 완성도 저하 · 상한 초과 전망이면 분석 설계 리포트 뒤 사용자 승인 | workflow §6 | HIGH |
| OPS-4 | 1.5배 | 예상의 1.5배 이상 필요하면 멈추고 계획을 전면 재검토한다 | workflow §6 | HIGH |
| OPS-5 | 페르소나 평점제 | 페르소나 6종 · 사건별 1회 · 프로젝트 누적 · 조치 뒤 차감. 3회 룰/페르소나 점검 · 5회 workflow 점검 · 10회 하네스 재설계. 원장 `docs/persona-overrides/scoreboard.md`(형식 `TEMPLATES/scoreboard-template.md` · 없으면 Team Lead가 첫 스폰 전에 만듦). 스폰 때 누적 회수 · 최근 사건 전달 | workflow §6 | MEDIUM |

---

## §2 파일별 색인

| 원본 파일 | 규칙 ID |
|-----------|---------|
| `rules-index.md` §3 | **HR-1~5 (정본)** |
| `entrypoint.md` | LOCK-1~7, FRESH-1~8, 11, 12, ENTRY-1~5, EDIT-1~5, G4, **WT-1 (참조)** |
| `workflow.md` | E0~E4, ASSIGN-1~6, LIFECYCLE-1~4 (LIFECYCLE-5 · 6은 요약), NOTIFY-1~3, OPS-1~5 (§6), HR-6 · 7 (별칭), §1.4 전이 훅(current_state는 Edit · Write 전용 · additionalContext 경고) |
| `handoff/gate.md` | HANDOFF-1~6, REPORT-6 |
| `handoff/planning.md` · `verifying.md` · `testing.md` | G1 · G2 · G3 (판정 기준 정본) |
| `handoff/common.md` | REPORT-1~5, WT-8, COMMENT-1~3, COMM-1~4, REUSE-1~3, TOOL-1~6 (TOOL-GUARD) |
| `docs/comment-policy/comment-policy.md` | NOTE-1~6 (정본) |
| `ROLES/SUB-SSOT/TEAM-LEAD/orchestration-procedure.md` | DELEGATE-1~4, SUBAGENT-1, SCOPE-1 (정본) |
| `ROLES/SUB-SSOT/TEAM-LEAD/lifecycle-procedure.md` | LIFECYCLE-5 · 6 · 6.1 (정본) |
| `ROLES/SUB-SSOT/VERIFIER/verification-procedure.md` | G2_be · G2_fe · G2_DS (G2 세부 정본) |
| `ROLES/SUB-SSOT/DEV/fn-procedure.md` | GATE 0~7 (fn 절차 게이트) |
| `CORE/shared-definitions.md` | GATE_FORMAT, ANTI-COMPRESSION, ROLE_CHECK, VAL, FAIL_COUNTER, VUL1, VUL2, VUL3, §8 토큰 예산 · 계측 정의 |
| `PROJECT.md` §3.1 | 정본 컴포넌트 레지스트리 (REUSE-3가 가리킴) |
| `TEMPLATES/pre-draft-topics.md` | PROMPT-QUALITY 트리아지 항목 |
| `worktree.md` | **WT-1~7 (정본)**, G-A · G-C · G-D · G-E |
| `phase-chain.md` | CHAIN-1~11 |
| `refactoring-rules.md` | REFACTOR-1~3 (정본) |

※ G1 · G3 판정 기준 정본은 handoff 단계 파일, G2는 handoff/verifying §1이 요약이고 세부는 verification-procedure, G4는 entrypoint §3.7
※ WT-1~5 정본은 worktree §5, entrypoint §3.9 병렬 처리 정책에서 WT-1 만 참조 (§3.1 EDIT-5 보강에서도 WT-1 인용)

**원본 칸 정리 (LOCK-6 — 공동 정본 해소)**: 두 곳 이상을 정본으로 적던 행은 주 정본 하나로 정하고 나머지는 인용으로 본다.

| ID | 주 정본 | 인용으로 보는 곳 |
|----|---------|------------------|
| SUBAGENT-1 | orchestration §서브에이전트 스코핑 | entrypoint §3.1 |
| LIFECYCLE-5 · 6 · 6.1 | lifecycle-procedure | workflow §AGENT-LIFECYCLE (요약) |
| REUSE-1~3 | handoff/common §7 | verification-procedure (심사 · 등급) · fn-procedure GATE 5 · PROJECT.md §3.1 (레지스트리) |
| G2 세부 | verification-procedure §G2 판정 기준 | handoff/verifying §1 (요약) · verifier.md · verify-* 스킬 |
| G1 · G3 | handoff/planning §2 · handoff/testing §1 | planner.md · planning-procedure · tester.md · testing-procedure |
| HANDOFF-3 | handoff/gate §1 | handoff/common §1 (팀원 쪽 절차) |
| COMM-2 | handoff/common §6 | entrypoint §3.3 |
| COMMENT-2 | handoff/common §5 | comment-policy §3 (절차) |

---

## §3 HR-1~5 정본

> `.claude/CLAUDE.md`에는 HR-1 요약만 둔다 — 전문은 이 절이 정본이다

### HR-1: Team Lead 코드 수정 절대 금지

- Team Lead(메인 세션)는 **코드 파일을 직접 수정하지 않는다** (Edit/Write 금지)
- 코드 수정은 **반드시 팀원(backend-dev, frontend-dev)을 통해서만** 수행한다
- "간단한 수정", "1줄 변경", "빠르게 처리" 등 어떤 이유로도 직접 수정을 정당화할 수 없다
- 팀이 없으면 **먼저 팀을 생성**한다. 팀 없이 코드 수정을 시작하는 것은 금지
- 훅(`.claude/hooks/hr1-guard.sh`)은 팀 활성 표지 파일(`/tmp/agent-teams-active-<세션 id>`)이 있을 때 코드 영역(`PROJECT.md` `code_dirs` × `code_exts`) 파일의 Edit·Write를 막고, 없으면 경고만 한다. 표지 파일은 리더 세션의 `PreToolUse`(팀원 스폰 시 `team-sentinel.sh spawn`) · `Stop`(팀원 생존 대조 `reconcile`)이 만들고 갱신하며 `SessionEnd`(`end`)가 지운다 — `SubagentStart`·`SubagentStop`은 팀원(teammate)에게 발화하지 않는다. 가드 범위는 Edit·Write와 이 팀 활성 판정까지이며, Bash·NotebookEdit 쓰기는 이 훅 밖이다

### HR-2: Phase 산출물 생략 금지 (CHAIN-6)

- 모든 Phase는 다음 산출물을 **필수로** 생성한다:
  - `phase-X-Y-status.md` (YAML 상태)
  - `phase-X-Y-plan.md` (계획서)
  - `phase-X-Y-todo-list.md` (체크리스트)
  - `tasks/task-X-Y-N.md` (개별 Task 명세, Task 수만큼)
- "Task가 1개뿐", "단순 작업" 등의 이유로 생략 불가

### HR-3: 컨텍스트 복구 시 SSOT 리로드 필수

- 컨텍스트 압축 또는 세션 중단 후 복구 시, **작업 재개 전 반드시**:
  1. SSOT entrypoint.md를 읽는다
  2. 현재 Phase의 status.md를 읽는다
  3. 팀 상태를 확인한다 (팀이 없으면 새로 생성)
- "이전 컨텍스트 요약이 있으니 바로 작업" 하는 것은 금지

### HR-4: Phase 문서 경로 규칙 (CHAIN-10)

새 Phase 문서 생성 시 **반드시 기존 파일 패턴을 Glob으로 확인** 후 동일 경로 레벨에 생성한다.

- `master-plan.md`, `phase-chain-*.md` → **`docs/phases/` 루트** (하위 폴더 생성 금지)
- `status.md`, `plan.md`, `todo-list.md`, `tasks/` → **`docs/phases/phase-{N}-{M}/` 하위**

### HR-5: 코드 유지관리 — 리팩토링 규정 (REFACTOR-1~3)

- **Phase X-Y 완료 시**: 코드 스캔 → 500줄 초과 파일을 레지스트리에 **등록**
- **Master Plan 작성 시**: 레지스트리 읽기 → 700줄 초과 시 **Lv1 분리를 Master Plan 내 선행 sub-phase로 편성**
- **초기 개발 시에도 적용**: 신규 파일 500줄 초과 사전 방지, G2에서 검출 (기존 파일 확장은 REFACTOR-1 관심선 등록 — REFACTOR-3)
- **[예외]**: 영향도 조사 실시 + 분리 불가 입증 + 사용자 승인 3요건 필수
- **규정 상세**: `WORKFLOW/refactoring/refactoring-rules.md`

---

## §4 교차 참조 맵

### HR ↔ 규칙 ID 대응

| HR | 대응 규칙 | 관계 |
|----|-----------|------|
| HR-1 | EDIT-2 | 동일 제약 |
| HR-2 | CHAIN-6 | 산출물 의무 |
| HR-3 | FRESH-7 | 복구 프로토콜 |
| HR-4 | CHAIN-10 | 파일 경로 규칙 동일 |
| HR-5 | REFACTOR-1~3, FRESH-8 | 리팩토링 전체 흐름 |
| HR-6 | ASSIGN-1~5 | Task 도메인-역할 분리 |
| HR-7 | LIFECYCLE-1~6 | 에이전트 라이프사이클 관리 |
