# 6-rules-index.md — 5th SSOT 규칙 통합 인덱스

> **버전**: 1.4 | **최종 갱신**: 2026-04-18 (Phase-J J-3 — WT 카테고리 5규칙 추가, 총수 95 → 100)
> **SSOT**: v7.0-renewal-5th | **생성**: Phase 24-1 Task 24-1-1

## 개요

5th SSOT에 정의된 모든 규칙의 통합 인덱스. 3중 색인(카테고리/파일/심각도)을 제공한다.

- **총 규칙 수**: 100개 상위 규칙 (하위 규칙 포함 134개)
- **카테고리**: 20개
- **원본 파일**: 7개
- **심각도 분포**: CRITICAL 42 / HIGH 37 / MEDIUM 18 / LOW 1

---

## §1 카테고리별 색인

### 1.1 HR — Hard Rules (절대 위반 금지) — 5개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| HR-1 | Team Lead 코드 수정 금지 | Team Lead는 코드 Edit/Write 금지, 팀원 위임 전용 | CLAUDE.md | CRITICAL |
| HR-2 | Phase 산출물 생략 금지 | status/plan/todo-list/tasks 4종 필수 (CHAIN-6) | CLAUDE.md | CRITICAL |
| HR-3 | 컨텍스트 복구 시 SSOT 리로드 | 세션 복구 시 0-entrypoint → status → 팀 확인 필수 | CLAUDE.md | CRITICAL |
| HR-4 | Phase 문서 경로 규칙 | master-plan → docs/phases/ 루트, phase 문서 → 하위 폴더 (CHAIN-10) | CLAUDE.md | CRITICAL |
| HR-5 | 리팩토링 규정 | 500줄 등록 / 700줄 Level 분류 / 1000줄 즉시 편성 (REFACTOR-1~3) | CLAUDE.md | CRITICAL |

### 1.2 LOCK — SSOT 잠금 & 불변성 — 5개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| LOCK-1 | Phase 실행 중 SSOT 변경 금지 | current_state가 IDLE/DONE 아닌 동안 SSOT 수정 불가 | 0-entrypoint §3.4 | CRITICAL |
| LOCK-2 | 변경 시 Phase 일시정지 | SSOT 수정 불가피 시 BLOCKED 전이 후 변경 | 0-entrypoint §3.4 | CRITICAL |
| LOCK-3 | 변경 후 리로드 필수 | SSOT 변경 후 모든 팀원에게 SendMessage로 리로드 지시 | 0-entrypoint §3.4 | CRITICAL |
| LOCK-4 | 팀원 SSOT 수정 금지 | 팀원은 SSOT 읽기 전용 | 0-entrypoint §3.4 | CRITICAL |
| LOCK-5 | 변경 이력 필수 기록 | SSOT 변경 시 버전 히스토리에 기록 | 0-entrypoint §3.4 | HIGH |

### 1.3 FRESH — SSOT 신선도 & 컨텍스트 — 9개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| FRESH-1 | 세션 시작 시 SSOT 리로드 | 0→1→2→3 순서로 SSOT 4개 파일 로딩 | 0-entrypoint §3.5 | CRITICAL |
| FRESH-2 | 새 Phase 시작 시 버전 확인 | ssot_version 일치 여부 확인 | 0-entrypoint §3.5 | HIGH |
| FRESH-3 | 버전 불일치 시 갱신 우선 | 버전 변경 감지 시 Phase 전 리로드 | 0-entrypoint §3.5 | CRITICAL |
| FRESH-4 | 리로드 시각 기록 | ssot_loaded_at에 타임스탬프 기록 | 0-entrypoint §3.5 | MEDIUM |
| FRESH-5 | 장기 세션 주기적 확인 | Task 3개+ 처리 시 SSOT 버전 재확인 권장 | 0-entrypoint §3.5 | MEDIUM |
| FRESH-6 | 팀원 역할별 로딩 | 스폰 시 해당 ROLES/*.md 1개만 로딩 | 0-entrypoint §3.5 | HIGH |
| FRESH-7 | 컨텍스트 복구 시 리로드 | 압축·중단 후 SSOT 리로드 + status + 팀 확인 필수 (=HR-3) | 0-entrypoint §3.5 | CRITICAL |
| FRESH-8 | 리팩토링 레지스트리 관리 | Phase 완료 시 500줄 초과 등록, Master Plan 시 700줄 편성 | 0-entrypoint §3.5 | HIGH |
| FRESH-9 | 실행 단위 컨텍스트 | 역할별 작업 1회 시작 시 권장 로딩 집합 (선택) | 0-entrypoint §3.5 | MEDIUM |

### 1.4 ENTRY — 진입점 프로토콜 — 5개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| ENTRY-1 | 단일 진입점 | status.md를 먼저 읽고 시작 | 0-entrypoint §3.6, 3-workflow §0 | CRITICAL |
| ENTRY-2 | 상태 기반 분기 | current_state 값에 따라 행동 결정 | 0-entrypoint §3.6 | CRITICAL |
| ENTRY-3 | SSOT 버전 확인 | 진입 시 ssot_version 일치 확인 | 0-entrypoint §3.6 | CRITICAL |
| ENTRY-4 | Blocker 우선 확인 | blockers 비어있지 않으면 Blocker 해결 우선 | 0-entrypoint §3.6 | HIGH |
| ENTRY-5 | 직접 시작 금지 | status 파일 미확인 후 Task 시작 금지 | 0-entrypoint §3.6 | CRITICAL |

### 1.5 CHAIN — Phase Chain & 순차 실행 — 11개 (+ITER 2 + ITERATION-BUDGET 1 + CHAIN-12/13 2, AutoCycle)

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| CHAIN-1 | Phase 독립성 | 각 Phase는 단독 실행 가능해야 함 | 3-workflow §8.6 | HIGH |
| CHAIN-2 | /clear 필수 | Phase 간 전환 시 /clear로 토큰 초기화 | 3-workflow §8.6 | CRITICAL |
| CHAIN-3 | Chain 파일 유지 | /clear 후에도 Chain 파일은 디스크에 영속 | 3-workflow §8.6 | MEDIUM |
| CHAIN-4 | 순차 보장 | phases 배열 순서대로만 실행, 건너뛰기 금지 | 3-workflow §8.6 | CRITICAL |
| CHAIN-5 | 완료 리포트 | Phase DONE 시 1줄 요약을 Chain 파일에 기록 | 3-workflow §8.6 | MEDIUM |
| CHAIN-6 | 산출물 의무 | plan/todo-list/tasks/status 최소 필수 (=HR-2) | 3-workflow §8.6 | CRITICAL |
| CHAIN-7 | Gate 의무 | G0~G4 생략 불가 (G0은 research=true 시) | 3-workflow §8.6 | CRITICAL |
| CHAIN-8 | Status 형식 | status.md는 YAML frontmatter 형식 | 3-workflow §8.6 | HIGH |
| CHAIN-9 | Task 문서 형식 | 메타 필드 4종 + §1~§4 섹션 번호 | 3-workflow §8.6 | HIGH |
| CHAIN-10 | 파일 경로 규칙 | 디렉토리 구조 Glob 확인 후 생성 (=HR-4) | 3-workflow §8.6~§8.7 | CRITICAL |
| CHAIN-11 | Master Plan 완료 보고서 | Master Plan 전체 완료 시 final-summary-report.md 작성 필수 | 3-workflow §8.6 | HIGH |
| **ITER-PRE** | Pre-Build Iteration Loop | Step 1~5 사전 반복 최대 3회 (PRE_BUILD_ITERATION_COUNTER). 3회 후 G-Pre 수렴 게이트. 미충족 시 범위 축소/사용자 승인 | SUB-SSOT/TEAM-LEAD/1-orchestration §ITER-PRE | **CRITICAL** |
| **ITER-POST** | Post-Build Re-plan Loop | Step 8 재계획 최대 2회 (REPLAN_COUNTER). 초과 시 Tech Debt 전이 (tech-debt-report.md) | SUB-SSOT/TEAM-LEAD/1-orchestration §ITER-POST | **CRITICAL** |
| **ITERATION-BUDGET** | 사이클 자원 상한 | 1 사이클 토큰 상한 500K. 80% 도달 시 WARNING, 100% 시 HALT + 에스컬레이션. 사용자 "예산 무제한" 선언 시 예외 | core/7-shared-definitions §8 | **CRITICAL** |
| **CHAIN-12** | Tech Debt 자동 로딩 | 차기 Phase 시작 시 Team Lead가 직전 Phase의 tech-debt-report.md를 로딩하여 carryover 항목 확인 필수 | TEMPLATES/tech-debt-report §5 + 1-orchestration §Phase Chain | **HIGH** |
| **CHAIN-13** | 직전 3 Phase Final Report 자동 로딩 (CHAIN-N+1) | 차기 Phase/사이클 시작 시 Team Lead가 직전 최대 3개 Phase의 master-final-report 요약을 로딩. 기억 전달로 반복 실수 방지 | SUB-SSOT/TEAM-LEAD/1-orchestration §Phase Chain 확장 | **HIGH** |

### 1.6 EDIT — 코드 편집 권한 & 도메인 경계 — 5개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| EDIT-1 | 도메인별 편집 범위 | backend-dev: backend/tests/scripts, frontend-dev: web/e2e | 1-project §7.1 | CRITICAL |
| EDIT-2 | Team Lead 코드 수정 금지 | Team Lead → 팀원 위임 (=HR-1) | 1-project §7.1, §7.5 | CRITICAL |
| EDIT-3 | 상태·SSOT 쓰기 독점 | status.md와 SSOT는 Team Lead만 수정 | 1-project §7.1 | CRITICAL |
| EDIT-4 | 읽기 전용 팀원 | verifier(Explore)·planner(Plan)는 쓰기 권한 없음 | 1-project §7.1 | HIGH |
| EDIT-5 | 동시 편집 금지 | 동일 파일 두 팀원 동시 편집 금지, [FS] BE→FE 순차 | 1-project §7.1 | HIGH |

### 1.7 GATE — 품질 게이트 — 5개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| G0 | Research Review | 기술 조사·아키텍처 대안 2+·리스크 분석 (5th 신규) | 1-project §6.2, 3-workflow §4.2 | CRITICAL |
| G1 | Plan Review | 완료 기준 명확, Task 3~7개, 도메인 분류, 리스크 식별 | 1-project §6.2, 3-workflow §4.2 | CRITICAL |
| G2 | Code Review | Critical 0건 (ORM, Pydantic, type hints, ESM, esc(), CDN) | 1-project §6.2, 3-workflow §4.2 | CRITICAL |
| G3 | Test Gate | pytest PASS, 커버리지 ≥80%, E2E PASS, 회귀 통과 | 1-project §6.2, 3-workflow §4.2 | CRITICAL |
| G4 | Final Gate | G2+G3 PASS + Blocker 0건 | 1-project §6.2, 3-workflow §4.2 | CRITICAL |

### 1.8 ERROR — 에러 처리 — 5개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| E0 | Critical 에러 | 즉시 중단, 사용자 보고 | 3-workflow §5 | CRITICAL |
| E1 | Blocker 이슈 | BLOCKED 전이, Fix Task 생성 | 3-workflow §5 | HIGH |
| E2 | High 이슈 | REWINDING, 수정 요청 | 3-workflow §5 | HIGH |
| E3 | Medium 이슈 | Technical Debt 등록 | 3-workflow §5 | MEDIUM |
| E4 | Low 이슈 | 기록만 | 3-workflow §5 | LOW |

### 1.9 REFACTOR — 코드 유지관리 — 3개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| REFACTOR-1 | Phase 완료 시 코드 스캔 | 500줄 초과 파일 레지스트리 등록 | 3-workflow §10, refactoring-rules.md | HIGH |
| REFACTOR-2 | Master Plan 시 편성 | 700줄 초과 Lv1/Lv2 분류 후 리팩토링 편성 | 3-workflow §10, refactoring-rules.md | HIGH |
| REFACTOR-3 | 신규 코드 사전 방지 | PLANNING/BUILDING/G2에서 500줄 초과 방지 | 3-workflow §10, refactoring-rules.md | MEDIUM |

### 1.10 5TH — 5세대 조건부 기능 플래그 — 5개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| 5TH_RESEARCH | Research-first | research=true 시 RESEARCH→G0 상태 포함 | 0-entrypoint §3.10, 3-workflow §1.3 | MEDIUM |
| 5TH_EVENT | Event-first | event=true 시 JSONL 이벤트 로그·Heartbeat 활성화 | 0-entrypoint §3.10, 1-project §7.6 | MEDIUM |
| 5TH_AUTOMATION | Automation-first | automation=true 시 AUTO_FIX·Persister·AutoReporter 활성화 | 0-entrypoint §3.10, 3-workflow §1.3 | MEDIUM |
| 5TH_BRANCH | Branch-first | branch=true 시 Phase별 Git 격리 + 체크포인트 | 0-entrypoint §3.10, 3-workflow §1.3 | MEDIUM |
| 5TH_MULTI | Multi-perspective | multi_perspective=true 시 11명 Verification Council | 0-entrypoint §3.10, 1-project §3.2 | MEDIUM |

### 1.11 EVENT — 이벤트 프로토콜 — 6개 (하위 15개)

| ID | 제목 | 하위 | 요약 | 원본 | 심각도 |
|----|------|------|------|------|--------|
| EVENT-1 | 이벤트 스키마 | 3 | 1line-1JSON, UTF-8, 필수 6필드, 8종 이벤트 타입 | 4-event §1 | CRITICAL |
| EVENT-2 | Heartbeat | 2 | 상태별 간격(5~10분), 미수신 시 에스컬레이션 | 4-event §2 | HIGH |
| EVENT-3 | Watchdog SLA | 2 | 역할별 타임아웃(10~15분), 3단계 에스컬레이션 | 4-event §3 | HIGH |
| EVENT-4 | 상태 전이 기록 | 2 | 모든 상태 전이 자동 로깅, Git 태그 생성 | 4-event §4 | CRITICAL |
| EVENT-5 | Gate 결과 기록 | 2 | G0~G4 결과 로깅(verdict/score/council) | 4-event §5 | HIGH |
| EVENT-6 | 로그 보존 | 4 | /tmp 활성, docs/ 아카이브, 삭제 규칙, 10MB 경고 | 4-event §6 | CRITICAL |

### 1.12 AUTO — 자동화 파이프라인 — 6개 (하위 31개)

| ID | 제목 | 하위 | 요약 | 원본 | 심각도 |
|----|------|------|------|------|--------|
| AUTO-1 | Artifact Persister | 6 | 산출물 무결성 검증, CHAIN-6 자동 검증, 자동 생성 | 5-automation §1 | CRITICAL |
| AUTO-2 | AutoReporter | 6 | Task 완료/상태 전이/Gate 시 자동 진행 리포트 생성 | 5-automation §2 | HIGH |
| AUTO-3 | DecisionEngine | 5 | AUTO_FIX 6조건 AND 판정, 최대 3회 반복, 에스컬레이션 | 5-automation §3 | CRITICAL |
| AUTO-4 | 활성화 제어 | 3 | 5th_mode.automation으로 전체 활성/비활성 | 5-automation §4 | CRITICAL |
| AUTO-5 | ContextRecovery | 4 | FRESH-7 복구 절차 실행, HR-1/2/3 준수 검증 | 5-automation §5 | CRITICAL |
| AUTO-6 | Git 체크포인트 | 5 | 상태 전이 태그, REWINDING 복구, A/B 브랜치 패턴 | 5-automation §6 | HIGH |

### 1.13 MODE — 교차 문서 규칙 — 2개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| MODE-1 | 5세대 이중축 아키텍처 | Event-first + Automation-first 조율 시스템 | 4-event intro, 5-automation intro | CRITICAL |
| MODE-2 | SSOT 버전 잠금 | 5th_mode 미설정 시 4th 호환 모드 동작 | 5-automation §4 | HIGH |

### 1.14 ASSIGN — Task 할당 규칙 — 4개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| ASSIGN-1 | 도메인-역할 매핑 필수 | [BE]→backend-dev, [FE]→frontend-dev, [TEST]→tester, [DOC]→전문가/TL | 3-workflow §TASK_SPEC | CRITICAL |
| ASSIGN-2 | [TEST] tester 전용 | [TEST] Task를 구현 역할(backend-dev/frontend-dev)에 할당 금지 | 3-workflow §TASK_SPEC | CRITICAL |
| ASSIGN-3 | 할당 전 도메인-역할 검증 | assignee 지정 시 도메인↔역할 일치 검증 필수 | 3-workflow §TASK_SPEC | CRITICAL |
| ASSIGN-4 | 스크립트 실행·분석 Task | 코드 미작성 Task(평가/분석)는 tester/verifier에 할당 | 3-workflow §TASK_SPEC | CRITICAL |
| ASSIGN-5 | Team Lead 통제 의무 | 모든 검증·테스트·QC 작업이 구현자에게 할당되지 않았는지 3단계(스폰·할당·진행 중) 능동 감시 | 3-workflow §TASK_SPEC | CRITICAL |

### 1.15 LIFECYCLE — 에이전트 라이프사이클 관리 — 4개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| LIFECYCLE-1 | 5분 무보고 점검 | 5분 이상 보고 없으면 역할·Task 점검 후 필요 시 종료 | 3-workflow §AGENT-LIFECYCLE | CRITICAL |
| LIFECYCLE-2 | 미사용 에이전트 즉시 종료 | 할당 Task 없거나 완료된 에이전트 즉시 shutdown | 3-workflow §AGENT-LIFECYCLE | CRITICAL |
| LIFECYCLE-3 | 종료 전 Task 상태 확인 | 미완료 Task 재할당/보류 판단 후 종료 | 3-workflow §AGENT-LIFECYCLE | HIGH |
| LIFECYCLE-4 | 팀 해산 시 전원 종료 | 모든 팀원 shutdown 후 TeamDelete | 3-workflow §AGENT-LIFECYCLE | HIGH |

### 1.16 REPORT — 팀원 보고 방식 — 5개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| REPORT-1 | 보고서 파일 필수 작성 | Task 완료 시 Phase 디렉토리 reports/ 내 마크다운 보고서 작성 필수 | 3-workflow §BUILDING | HIGH |
| REPORT-2 | SendMessage는 링크만 | SendMessage에는 보고서 파일 경로만 포함, 텍스트 본문 보고 금지 | 3-workflow §BUILDING | HIGH |
| REPORT-3 | 보고서 템플릿 준수 | TEMPLATES/task-report-template.md 형식 준수 | 3-workflow §BUILDING | MEDIUM |
| REPORT-4 | 필수 섹션 5개 | 작업 내용, 작업 결과, 테스트 결과, 위험 요소, 다음 개발 추천 | 3-workflow §BUILDING | HIGH |
| REPORT-5 | 보고서 경로 규칙 | docs/phases/phase-X-Y/reports/report-{역할명}.md | 3-workflow §BUILDING | HIGH |

### 1.17 NOTIFY — Telegram 완료 알림 — 3개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| NOTIFY-1 | Phase DONE 시 Telegram 알림 필수 | DONE 전이 즉시 `scripts/pmAuto/report_to_telegram.sh` 실행. **생략 시 DONE 전이 무효** | 3-workflow §3 DONE | CRITICAL |
| NOTIFY-2 | 알림 메시지 형식 | `✅ Phase {N}-{M} 완료: {요약} / 📊 결과 / 📁 보고서 경로` 형식 준수 | 3-workflow §3 DONE | HIGH |
| NOTIFY-3 | Master Plan 완료 시 종합 알림 | 전체 Chain 완료 시 Sub-Phase별 요약 포함 종합 알림 발송 | 3-workflow §3 DONE | HIGH |

### 1.18 ANALYSIS — 사전 분석 규칙 — 3개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| ANALYSIS-1 | 사전 분석 결과 파일 저장 필수 | 보류 항목·비교 검토·요구사항 분석 결과를 `docs/phases/pre/phase-{N}-pre-analysis.md`에 저장. 텍스트 출력만으로 완료 처리 금지 | 3-workflow §12 | CRITICAL |
| ANALYSIS-2 | 분석 파일 경로 규칙 | `docs/phases/pre/` 폴더에 `phase-{N}-pre-analysis.md` 형식 생성 (HR-4 / CHAIN-10 준수, Phase-I I-1 경로 이전) | 3-workflow §12 | HIGH |
| ANALYSIS-3 | 분석 파일 필수 섹션 | 분석 배경, 현황 진단, 비교 검토, 결론 및 추천안 4개 섹션 필수 | 3-workflow §12 | HIGH |

### 1.19 REFERENCE — 문서 우선순위 — 1개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| REFERENCE-1 | 3-workflow.md 권위 | 컨텍스트 복구는 §9, Phase 문서 구조는 §8.7이 정본 | 5-automation §5.3 | HIGH |

### 1.20 PROMPT — 프롬프트 품질 규칙 (Phase-I I-3) — 1개

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| PROMPT-QUALITY | 프롬프트 품질 5항목 점검 | 사용자 주도 마스터 플랜(`initiator: user`) 진입 전 Step 0 Pre-draft 단계에서 완전성·명료성·실행 가능성·범위 적정성·트리아지 5항목 판정 필수. AI handoff(`initiator: ai-handoff`) 시 적용 제외. Fast-path: 5항목 자명 PASS 시 템플릿 작성 생략 허용 (master-plan에 `prompt_quality: fast-path` 표기) | TEMPLATES/pre-draft-topics.md, Phase-I I-3 | HIGH |

**5항목 판정 기준**:
1. **완전성** — 사용자 관점 + 개발자 관점 양쪽 도출 가능
2. **명료성** — 모호 용어 0건 (또는 전부 "TBD" 명시 표기)
3. **실행 가능성** — 기술적 Show-stopper 없음 (리서치 필요 항목은 플래그)
4. **범위 적정성** — 단일 Phase 적정 / 분할 필요 판정 완료
5. **트리아지** — 즉시 진행 / 재질문 / 분할 / 취소 중 1건 선택

### 1.21 WT — Worktree (병렬 격리 · Phase-J 신규) — 5개

> **원본**: [3-workflow.md §6.6](../3-workflow.md#66-worktree-규칙-wt-1--wt-5) / 상세: [infra/git-worktree-guide.md](../infra/git-worktree-guide.md)
> **배경**: ver6-0 §7.3 병렬 처리 정책의 "수정 파일 집합 교집합 ∅" 조건만으로는 빌드 산출물·git 상태 경합을 막지 못함. worktree 격리로 3요소(checkout·stash·빌드 캐시) 동시 해결.

| ID | 제목 | 요약 | 원본 | 심각도 |
|----|------|------|------|--------|
| WT-1 | worktree 필수 조건 | 병렬 BUILDING 트랙 수 ≥ 2 일 때 worktree 없이 BUILDING 진입 금지. A/B 분기(§6.4)·REWINDING(§6.3) 에서도 적용 | [3-workflow §6.6](../3-workflow.md#66-worktree-규칙-wt-1--wt-5) | CRITICAL |
| WT-2 | 경로 규약 | `../PAB-SSOT-Nexus-wt-phase-{X}-{Y}-{track}` 패턴만 허용. 저장소 내부 `.worktrees/` 배치 금지 (gitignore 누락 시 재귀 노출 위험) | [3-workflow §6.6](../3-workflow.md#66-worktree-규칙-wt-1--wt-5) | HIGH |
| WT-3 | CWD 일관성 | 팀원은 스폰 시 주입된 worktree 경로 밖에서 편집·빌드 금지. 위반 시 즉시 작업 중단·재할당. BUILDING 단락 CWD 주입 규칙과 연계 | [3-workflow §6.6](../3-workflow.md#66-worktree-규칙-wt-1--wt-5) | CRITICAL |
| WT-4 | 수명 주기 | Phase Chain 완료 시 `git worktree remove` + `git worktree prune` 일괄 수행. 실패 브랜치(REWINDING)·A/B 비선택 브랜치는 §6.5 아카이브 규칙 준수 후 제거 | [3-workflow §6.6](../3-workflow.md#66-worktree-규칙-wt-1--wt-5) | HIGH |
| WT-5 | 상태 기록 | `phase-{X}-{Y}-status.md` YAML 에 `worktree_paths: []` 와 `cleanup_wt: pending\|done` 필드 필수 기록 | [3-workflow §6.6](../3-workflow.md#66-worktree-규칙-wt-1--wt-5) | MEDIUM |

**심각도 분포**: CRITICAL 2 (WT-1, WT-3) / HIGH 2 (WT-2, WT-4) / MEDIUM 1 (WT-5).
**연계 규칙**: EDIT-5 (병렬 ≥ 2 일 때 worktree 필수 보강) · CHAIN-5/NOTIFY-1 (Chain 완료 시 cleanup + prune 동기)

---

## §2 파일별 색인

| 원본 파일 | 규칙 ID | 개수 |
|-----------|---------|------|
| `.claude/CLAUDE.md` | HR-1~5 | 5 |
| `5th/0-entrypoint.md` | LOCK-1~5, FRESH-1~9, ENTRY-1~5, 5TH_* (5) | 24 |
| `5th/1-project.md` | EDIT-1~5, G0~G4, **WT-1 (참조)** | 11 |
| `5th/3-workflow.md` | CHAIN-1~10, REFACTOR-1~3, E0~E4, G0~G4, ASSIGN-1~5, LIFECYCLE-1~4, REPORT-1~5, NOTIFY-1~3, ANALYSIS-1~3, **WT-1~5 (정본 §6.6)** | 48 |
| `5th/4-event-protocol.md` | EVENT-1~6 (하위 15), MODE-1 | 7 |
| `5th/5-automation.md` | AUTO-1~6 (하위 31), MODE-2, REFERENCE-1 | 8 |
| `refactoring-rules.md` | REFACTOR-1~3 (상세) | 3 |
| `infra/git-worktree-guide.md` | WT-1~5 (운영 상세 · CK-1~5) | 5 |

※ GATE(G0~G4)는 1-project와 3-workflow 양쪽에서 정의 (교차 참조)
※ WT-1~5 정본은 3-workflow §6.6, 1-project §7.3 에서 WT-1 만 참조 (§7.1 EDIT-5 보강에서도 WT-1 인용)

---

## §3 심각도별 색인

### CRITICAL (32개)

| ID | 카테고리 | 핵심 제약 |
|----|----------|-----------|
| HR-1~5 | Hard Rules | 절대 위반 금지, 모든 상황에 적용 |
| LOCK-1~4 | SSOT 잠금 | Phase 중 SSOT 변경 금지, 팀원 읽기전용 |
| FRESH-1, 3, 7 | 신선도 | 세션 시작·버전 불일치·복구 시 리로드 |
| ENTRY-1~3, 5 | 진입점 | 단일 진입점, 상태 기반 분기, 직접 시작 금지 |
| CHAIN-2, 4, 6, 7, 10 | Phase Chain | /clear 필수, 순차, 산출물, Gate, 경로 |
| EDIT-1~3 | 편집 권한 | 도메인 범위, TL 금지, SSOT 독점 |
| G0~G4 | Gate | 모든 품질 게이트 생략 불가 |
| E0 | 에러 | Critical 에러 즉시 중단 |
| EVENT-1, 4, 6 | 이벤트 | 스키마, 상태 전이 기록, 로그 보존 |
| AUTO-1, 3~5 | 자동화 | Persister, DecisionEngine, 활성화, 복구 |
| MODE-1 | 모드 | 이중축 아키텍처 |
| ANALYSIS-1 | 사전 분석 | 분석 결과 파일 저장 필수, 텍스트 출력만으로 완료 금지 |
| **WT-1, WT-3** | **Worktree (Phase-J)** | **병렬 N ≥ 2 worktree 필수 / CWD 일관성 (위반 시 즉시 중단)** |

### HIGH (29개)

| ID | 카테고리 |
|----|----------|
| LOCK-5 | SSOT 잠금 |
| FRESH-2, 6, 8 | 신선도 |
| ENTRY-4 | 진입점 |
| CHAIN-1, 8, 9 | Phase Chain |
| EDIT-4, 5 | 편집 권한 |
| E1, E2 | 에러 |
| REFACTOR-1, 2 | 리팩토링 |
| EVENT-2, 3, 5 | 이벤트 |
| AUTO-2, 6 | 자동화 |
| MODE-2 | 모드 |
| REFERENCE-1 | 문서 우선순위 |
| ANALYSIS-2, 3 | 사전 분석 |
| **WT-2, WT-4** | **Worktree (Phase-J)** (경로 규약 · 수명 주기) |

### MEDIUM (17개)

| ID | 카테고리 |
|----|----------|
| FRESH-4, 5, 9 | 신선도 |
| CHAIN-3, 5 | Phase Chain |
| E3 | 에러 |
| REFACTOR-3 | 리팩토링 |
| 5TH_RESEARCH~MULTI | 5세대 플래그 (5개) |
| **WT-5** | **Worktree (Phase-J)** (status.md 필드 기록) |

### LOW (1개)

| ID | 카테고리 |
|----|----------|
| E4 | 에러 (기록만) |

---

## §4 HR-1~5 정식 복사

> 원본: `.claude/CLAUDE.md` — 5th 단독 사용을 위한 정식 복사본

### HR-1: Team Lead 코드 수정 절대 금지

- Team Lead(메인 세션)는 **코드 파일을 직접 수정하지 않는다** (Edit/Write 금지)
- 코드 수정은 **반드시 팀원(backend-dev, frontend-dev)을 통해서만** 수행한다
- "간단한 수정", "1줄 변경", "빠르게 처리" 등 어떤 이유로도 직접 수정을 정당화할 수 없다
- 팀이 없으면 **먼저 팀을 생성**한다. 팀 없이 코드 수정을 시작하는 것은 금지

### HR-2: Phase 산출물 생략 금지 (CHAIN-6)

- 모든 Phase는 다음 산출물을 **필수로** 생성한다:
  - `phase-X-Y-status.md` (YAML 상태)
  - `phase-X-Y-plan.md` (계획서)
  - `phase-X-Y-todo-list.md` (체크리스트)
  - `tasks/task-X-Y-N.md` (개별 Task 명세, Task 수만큼)
- "Task가 1개뿐", "단순 작업" 등의 이유로 생략 불가

### HR-3: 컨텍스트 복구 시 SSOT 리로드 필수

- 컨텍스트 압축 또는 세션 중단 후 복구 시, **작업 재개 전 반드시**:
  1. SSOT 0-entrypoint.md를 읽는다
  2. 현재 Phase의 status.md를 읽는다
  3. 팀 상태를 확인한다 (팀이 없으면 새로 생성)
- "이전 컨텍스트 요약이 있으니 바로 작업" 하는 것은 금지
- 상세: 3-workflow.md §9 (컨텍스트 복구 프로토콜)

### HR-4: Phase 문서 경로 규칙 (CHAIN-10)

새 Phase 문서 생성 시 **반드시 기존 파일 패턴을 Glob으로 확인** 후 동일 경로 레벨에 생성한다.

- `master-plan.md`, `phase-chain-*.md` → **`docs/phases/` 루트** (하위 폴더 생성 금지)
- `status.md`, `plan.md`, `todo-list.md`, `tasks/` → **`docs/phases/phase-{N}-{M}/` 하위**
- 상세: 3-workflow.md §8.7 (Phase 문서 디렉토리 구조)

### HR-5: 코드 유지관리 — 리팩토링 규정 (REFACTOR-1~3)

- **Phase X-Y 완료 시**: 코드 스캔 → 500줄 초과 파일을 레지스트리에 **등록**
- **Master Plan 작성 시**: 레지스트리 읽기 → 700줄 초과 시 **Level 분류 후 리팩토링 편성**
  - **Lv1** (독립 분리 가능): Master Plan 내 선행 sub-phase
  - **Lv2** (연관 파일 밀접): `phase-X-refactoring` 별도 Phase + git branch 분리 + 별도 팀
- **초기 개발 시에도 적용**: 신규 파일 500줄 초과 사전 방지, G2에서 검출
- **[예외]**: 영향도 조사 실시 + 분리 불가 입증 + 사용자 승인 3요건 필수
- **규정 상세**: docs/refactoring/refactoring-rules.md
- **워크플로우**: 3-workflow.md §10 (코드 유지관리·리팩토링)

---

## §5 교차 참조 맵

### HR ↔ 규칙 ID 대응

| HR | 대응 규칙 | 관계 |
|----|-----------|------|
| HR-1 | EDIT-2, AUTO-5.4 | 동일 제약, 자동화 복구 시에도 적용 |
| HR-2 | CHAIN-6, AUTO-1.5 | 산출물 의무, Persister가 자동 검증 |
| HR-3 | FRESH-7, AUTO-5.3 | 복구 프로토콜, ContextRecovery가 실행 |
| HR-4 | CHAIN-10 | 파일 경로 규칙 동일 |
| HR-5 | REFACTOR-1~3, FRESH-8 | 리팩토링 전체 흐름 |
| HR-6 | ASSIGN-1~5 | Task 도메인-역할 분리 |
| HR-7 | LIFECYCLE-1~4 | 에이전트 라이프사이클 관리 |

---

## §6 CRITICAL Quick Reference (39개)

> **용도**: 세션 시작 시 빠른 확인용. CRITICAL 규칙만 1줄 요약으로 모은 즉시 참조표.

### 절대 위반 금지 (HR)
| ID | 1줄 요약 |
|----|----------|
| HR-1 | Team Lead 코드 Edit/Write 금지 → 팀원 위임 |
| HR-2 | Phase 산출물(status/plan/todo/tasks) 4종 생략 금지 |
| HR-3 | 컨텍스트 복구 시 SSOT 리로드 + status + 팀 확인 필수 |
| HR-4 | Phase 문서 경로 Glob 확인 후 생성 |
| HR-5 | 500줄→등록, 700줄→리팩토링 편성, Master Plan 시 레지스트리 로드 |

### SSOT 잠금 (LOCK)
| ID | 1줄 요약 |
|----|----------|
| LOCK-1 | Phase 실행 중 SSOT 변경 금지 |
| LOCK-2 | 변경 불가피 시 BLOCKED 전이 후 변경 |
| LOCK-3 | SSOT 변경 후 전 팀원 리로드 지시 |
| LOCK-4 | 팀원은 SSOT 읽기 전용 |

### 신선도 (FRESH)
| ID | 1줄 요약 |
|----|----------|
| FRESH-1 | 세션 시작 시 SSOT 0→1→2→3 순서 로딩 |
| FRESH-3 | 버전 불일치 감지 시 Phase 전 리로드 |
| FRESH-7 | 컨텍스트 복구 시 SSOT + status + 팀 필수 (=HR-3) |

### 진입점 (ENTRY)
| ID | 1줄 요약 |
|----|----------|
| ENTRY-1 | status.md 먼저 읽고 시작 |
| ENTRY-2 | current_state 값으로 행동 결정 |
| ENTRY-3 | 진입 시 ssot_version 일치 확인 |
| ENTRY-5 | status 미확인 후 Task 시작 금지 |

### Phase Chain (CHAIN)
| ID | 1줄 요약 |
|----|----------|
| CHAIN-2 | Phase 간 전환 시 /clear 필수 |
| CHAIN-4 | phases 배열 순서대로만 실행, 건너뛰기 금지 |
| CHAIN-6 | plan/todo/tasks/status 산출물 의무 (=HR-2) |
| CHAIN-7 | G0~G4 게이트 생략 불가 |
| CHAIN-10 | 파일 경로 규칙 (=HR-4) |

### 편집 권한 (EDIT)
| ID | 1줄 요약 |
|----|----------|
| EDIT-1 | backend-dev: backend/tests/scripts, frontend-dev: web/e2e |
| EDIT-2 | Team Lead 코드 수정 금지 (=HR-1) |
| EDIT-3 | status.md/SSOT는 Team Lead만 수정 |

### 품질 게이트 (GATE)
| ID | 1줄 요약 |
|----|----------|
| G0 | Research 완료 + 대안 2개+ + 리스크 분석 |
| G1 | Task 3~7개, 도메인 분류, 리스크 식별 |
| G2 | Critical 0건 (ORM/Pydantic/ESM/esc/CDN) |
| G3 | pytest PASS + 커버리지 ≥80% + 회귀 통과 |
| G4 | G2 PASS + G3 PASS + Blocker 0건 |

### Task 할당 (ASSIGN)
| ID | 1줄 요약 |
|----|----------|
| ASSIGN-1 | [BE]→backend-dev, [FE]→frontend-dev, [TEST]→tester |
| ASSIGN-2 | [TEST] Task를 구현 역할에 할당 금지 |
| ASSIGN-3 | 할당 시 도메인↔역할 일치 검증 |
| ASSIGN-4 | 평가/분석 Task → tester/verifier |
| ASSIGN-5 | Team Lead 3단계 능동 감시 의무 |

### 에이전트 (LIFECYCLE)
| ID | 1줄 요약 |
|----|----------|
| LIFECYCLE-1 | 5분 무보고 → 점검 후 필요 시 종료 |
| LIFECYCLE-2 | 미사용 에이전트 즉시 shutdown |

### Worktree (WT, Phase-J 신규)
| ID | 1줄 요약 |
|----|----------|
| WT-1 | 병렬 BUILDING 트랙 ≥ 2 시 worktree 격리 필수 (상세: [3-workflow §6.6](../3-workflow.md#66-worktree-규칙-wt-1--wt-5)) |
| WT-3 | 팀원은 주입된 CWD 밖 편집·빌드 금지, 위반 시 즉시 중단·재할당 |

### 기타 CRITICAL
| ID | 1줄 요약 |
|----|----------|
| E0 | Critical 에러 즉시 중단 + 사용자 보고 |
| EVENT-1 | 이벤트 스키마 필수 6필드 |
| EVENT-4 | 모든 상태 전이 자동 로깅 |
| EVENT-6 | 이벤트 로그 보존 규칙 |
| AUTO-1 | Artifact Persister 산출물 무결성 검증 |
| AUTO-3 | DecisionEngine AUTO_FIX 최대 3회 |
| AUTO-4 | 5th_mode.automation으로 활성화 제어 |
| AUTO-5 | ContextRecovery HR-1/2/3 준수 검증 |
| MODE-1 | Event + Automation 이중축 아키텍처 |
