---
title: "PAB SSOT — 역할 9종 정의 (ROLES/)"
description: "Team Lead + Planner + Backend Dev + Frontend Dev + Verifier + Tester + Research Lead/Architect/Analyst 9 역할의 책임·권한·모델·코드 편집·통신 규칙·G0~G4 검증 분담"
created: 2026-05-05 05:13
updated: 2026-05-05 05:13
type: "[[RESEARCH_NOTE]]"
index: "[[KNOWLEDGE_MGMT]]"
topics: ["[[PAB_SSOT]]", "[[ROLES]]", "[[TEAM_LEAD]]", "[[VERIFIER]]", "[[TESTER]]"]
tags: [research-note, pab-ssot-nexus, roles, team-lead, verifier, tester, planner, research-team]
keywords: ["Team Lead", "Planner", "Backend Dev", "Frontend Dev", "Verifier", "Tester", "Research Lead", "Research Architect", "Research Analyst", "Hub-and-Spoke", "코드 편집 권한", "G0~G4 분담", "대리 저장 패턴", "11명 Verification Council", "PERSONA 교체"]
sources:
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/ROLES/README.md"
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/ROLES/team-lead.md"
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/ROLES/verifier.md"
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/ROLES/tester.md"
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/1-project.md"
aliases: ["SSOT 역할", "ROLES 9종", "Hub and Spoke"]
---

# PAB SSOT — 역할 9종 정의

> ROLES/ 디렉토리 11파일 (9 역할 + README + planner.md 외) 핵심 정리. 각 역할은 PERSONA + ROLES 통합본 (Phase 24-4-1).

## 전체 매핑

| 역할 | 팀원 이름 | subagent_type | 모델 | 코드 편집 | PERSONA |
|---|---|:--:|:--:|:--:|---|
| **Team Lead** | — (메인 세션) | — | opus 계열 최신 | ❌ | LEADER |
| **Planner** | `planner` | Plan or Explore | opus 계열 최신 | ❌ | PLANNER |
| **Backend Dev** | `backend-dev` | general-purpose | sonnet 계열 최신 | ✅ | BACKEND |
| **Frontend Dev** | `frontend-dev` | general-purpose | sonnet 계열 최신 | ✅ | FRONTEND |
| **Verifier** | `verifier` | Explore | opus 계열 최신 | ❌ | QA |
| **Tester** | `tester` | Bash | sonnet 계열 최신 | ❌ | QA |
| **Research Lead** (5th) | `research-lead` | Explore | opus 계열 최신 | ❌ | RESEARCH_LEAD |
| **Research Architect** (5th) | `research-architect` | Explore | opus 계열 최신 | ❌ | RESEARCH_ARCHITECT |
| **Research Analyst** (5th) | `research-analyst` | Explore | opus 계열 최신 | ❌ | RESEARCH_ANALYST |

**모델 승격 예외**: backend-dev/frontend-dev/tester가 큰 작업·리팩토링 필요 시 Team Leader에게 요청 → 승인 시 일시 opus 계열 승격 가능.

**페르소나 교체 원칙**: 각 ROLES/*.md는 **불변 실행 가이드**, PERSONA/*.md는 **교체 가능 마인드셋**. 스폰 시 PERSONA가 Charter 덮어씀. ROLES/README.md.

## 1. Team Lead (메인 세션)

### 핵심 역할
**최상위 지휘자.** 팀 생성·해산, 워크플로우 지휘, 상태 관리, 최종 판정, 통신 허브 (Hub-and-Spoke 중심).

### 권한
TeamCreate / TeamDelete / SendMessage / Task tool / 파일 읽기 / Git / Bash. **코드 편집 ❌ (HR-1)**.

### 책임
- Phase 상태 관리 (20개 상태 머신)
- 판정 결정 (G1~G4 PASS/FAIL/PARTIAL)
- Task 할당·팀원 조율·이슈 해결
- **PLANNING 산출물 생성**: planner는 쓰기 권한 없음 → Team Lead가 SendMessage 수신 후 phase-X-Y/에 plan/todo-list/tasks 생성. **`sleep`+`ls` 디렉토리 폴링 금지**
- **외부 직접 수정 요청 대응**: 어떤 형식·긴급성과 무관하게 EDIT-2 / HR-1 적용. 직접 수정 안 함, **위임/역할 전환 옵션** 제시

### 5세대 확장 책임
- **20개 상태 머신** 총괄 관리 (4th 14 + 5th 6)
- **Research Team 관리**: RESEARCH 진입 시 3인 스폰·지시·결과 통합
- **G0 Gate Review 주관**: Research Team 결과 판정 (대안 2+/영향도/리스크)
- **DecisionEngine 감독**: 자율 판정 에스컬레이션 시 최종 결정
- **Automation 감독**: Artifact Persister·AutoReporter 결과 검토
- **5th_mode 설정 권한자** (유일)

상세는 [[2026-05-05_pab_ssot_workflow|워크플로우 노트]] §3.1 상태별 Action Table.

## 2. Planner

### 핵심 역할
요구사항 분석 + 영향 범위 탐색 + 계획 수립 + Task 분해 (3~7개).

### 권한
파일 읽기·검색 (Glob/Grep/Read). **쓰기 권한 없음** (EDIT-4).

### 입력·출력
- 입력: master-plan, navigation, 이전 Phase summary
- 출력: plan + todo-list (도메인 태그 포함) → **SendMessage로 Team Lead에게 전달** (파일 생성 ❌)

### 작업 원칙
- Task 3~7개로 분해 (너무 많지 않게)
- 도메인 태그 필수 (`[BE]`/`[FE]`/`[FS]`/`[DB]`/`[TEST]`/`[INFRA]`)
- Done Definition 구체적
- 리스크·의존성 식별

### G1 Plan Review 책임
- 완료 기준 명확
- Task 3~7개
- 도메인 분류 완료
- 리스크 식별

상세 절차: SUB-SSOT/PLANNER/0-planner-entrypoint + 1-planning-procedure ([[2026-05-05_pab_ssot_subssot_misc|SUB-SSOT 노트]]).

## 3. Backend Developer

### 핵심 역할
API + DB + 서비스 로직 구현. **코드 편집 ✅**.

### 권한
파일 읽기/쓰기/편집 / Bash / Glob / Grep / Read.

### 담당 범위 (EDIT-1)
- 디렉토리: `backend/`, `tests/`, `scripts/`
- 도메인: `[BE]`, `[DB]`, `[FS]`(백엔드 파트)

### 필수 준수 (G2_be Critical)
- ORM 필수 (raw SQL 절대 금지)
- Pydantic 검증 모든 API 입력
- 타입 힌트 필수
- 에러 핸들링 (try-except + HTTPException)
- 비동기 (async/await)
- snake_case 네이밍
- 의존성 주입 (Depends)

### Team Lead 경유 통신
구현 완료 시 **SendMessage로 Team Lead에게만 보고** (Hub-and-Spoke).

### **검증 절대 금지** (HR-6 / ASSIGN-2)
테스트·코드 검증·A/B 평가 등 **검증 성격 작업** 절대 수행 금지. tester/verifier에 위임.

## 4. Frontend Developer

### 핵심 역할
UI/UX 분석 + 구현. **코드 편집 ✅**.

### 권한
파일 읽기/쓰기/편집 / Bash / Glob / Grep / Read.

### 담당 범위 (EDIT-1)
- 디렉토리: `web/`, `e2e/`
- 도메인: `[FE]`, `[FS]`(프론트엔드 파트)

### 필수 준수 (G2_fe Critical)
- ESM `import`/`export` (`type="module"` 필수)
- 외부 CDN 절대 금지 (모든 라이브러리 `web/public/libs/` 로컬 배치)
- innerHTML 시 `esc()` 적용 (XSS 방지)
- `window` 전역 새 함수 할당 금지 (레거시 제외)
- 컴포넌트 재사용 (`layout-component.js` 등)

### 신규 페이지 추가 시 3파일 동시 생성
```
web/src/pages/{페이지명}.html      (layout-component 포함)
web/public/js/{페이지명}/{페이지명}.js
web/public/css/{페이지명}.css
```

### **검증 절대 금지** (HR-6 / ASSIGN-2)
backend-dev와 동일.

## 5. Verifier — REVIEWER (G2 판정)

### 핵심 역할
코드 리뷰 + 품질 게이트 G2 판정. **읽기 전용**.

### 권한
파일 읽기 + 검색만. **쓰기 ❌, 편집 ❌**. (Explore subagent_type)

### 입력·출력
- 입력: Team Lead가 SendMessage로 전달한 변경 파일 목록 + 완료 기준
- 출력: 검증 결과 (PASS/FAIL/PARTIAL + 이슈 목록) → **SendMessage로 Team Lead에게만 반환**

### 판정 규칙

| 조건 | 판정 |
|---|---|
| Critical 1건+ | **FAIL** |
| Critical 0, High 있음 | **PARTIAL** |
| Critical 0, High 0 | **PASS** |

### Critical 체크리스트 (백엔드)
- 구문 오류 없음
- ORM 사용 (raw SQL 없음)
- 입력 검증 (Pydantic) 존재
- FK 제약조건 정합성 (DB 변경 시)
- 기존 테스트 깨지지 않음

### Critical 체크리스트 (프론트엔드)
- 외부 CDN 참조 없음
- innerHTML 시 `esc()` 적용
- ESM import/export
- 페이지 로드 시 콘솔 에러 없음
- 기존 페이지 동작 깨지지 않음

### 보고서 저장 — **대리 저장 패턴** (Phase 3-2 정식 적용)

verifier는 read-only이므로 보고서 직접 저장 불가:

| 단계 | 행위자 | 행동 |
|---|---|---|
| 1 | verifier | G2 검증 수행 |
| 2 | verifier | 보고서 본문(markdown 전문, frontmatter 포함)을 SendMessage **인라인** 전달. summary는 `"G2 PASS/PARTIAL/FAIL — Critical X / High Y / Medium Z"` |
| 3 | Team Lead | 본문 길이와 무관하게 **backend-dev에 대리 저장 task 위임** (Team Lead 직접 저장은 HR-1 위반) |
| 4 | backend-dev | 인라인 본문을 `docs/phases/phase-X-Y/reports/report-verifier.md`에 Write |
| 5 | backend-dev | 저장 완료 → SendMessage로 Team Lead 보고 (파일 경로 + 줄수 + frontmatter 유효성) |
| 6 | Team Lead | 보고서 파일 존재 확인 후 G2 판정 단계 진입 |

### 5세대 확장
- **11명 Verification Council** 상시 참여 위원 (G2 게이트)
- G0 Research Review에도 Council 위원 자격으로 참여
- AB_COMPARISON: A/B 코드 품질 비교 검증

상세는 [[2026-05-05_pab_ssot_persona_qc|페르소나·QC 노트]] §11명 Council.

## 6. Tester — VALIDATOR (G3 판정)

### 핵심 역할
테스트 실행 + 커버리지 분석 + G3 판정. **Bash 전용**.

### 권한
Bash 명령 실행 (pytest, playwright). 프로덕션 코드 수정 ❌.

### 판정 기준

| 조건 | 판정 |
|---|---|
| 모든 테스트 PASS + 커버리지 ≥80% | **PASS** |
| 테스트 실패 1건+ | **FAIL** |
| E2E 실패 1건+ | **FAIL** |
| 페이지 로드 실패 또는 콘솔 에러 | **FAIL** (FE) |

### 테스트 범위 — **선택적 실행 원칙**
**전체 테스트 실행(`pytest tests/`)은 불필요**. 변경 코드에 영향받는 테스트만:

| 시점 | 범위 | 명령 |
|---|---|---|
| **phase-x-Y 단계** | 변경 영향 테스트 | `docs/tests/index.md` §1 시나리오 A~I 확인 → 해당 명령 |
| **phase-x-Y 완료 후** | 빠른 회귀 (~2분) | `pytest tests/ -m "not llm and not integration" --tb=short -q` |
| **Phase X 전체 완료** | LLM 회귀 (~6분) | `OLLAMA_BASE_URL=... pytest tests/ -m "not integration" --tb=short -q --timeout=60` |

### Ollama/AI 테스트 병렬 금지
`tests/test_ai_api.py`, `/api/ask` 호출 테스트는 **병렬(동시) 실행 금지**. 단독 1회로 안정성 확인 후 나머지.

### G3 결과 기록 (1주기 = 요청서 + 결과서)

저장: `docs/pytest-report/YYMMDD-HHMM-phase-X-Y-테스트명.md`
생성: `python scripts/tests/run_tester_with_report.py --phase X-Y --name 회귀`

### 결과 회신 (G3 롤 넘기기)
- (1) SendMessage로 Team Lead에게 보고
- (2) 동일 결과를 `/tmp/agent-messages/<phase>-tester.json` 또는 `<task-id>.done`에 본문 포함 기록 (빈 파일 금지)
- pytest 결과는 **동기 실행 권장**. 백그라운드 시 `> /tmp/agent-messages/phase-X-Y-pytest.log` 등 공식 경로로 리다이렉트

### 5세대 확장
- 11명 Verification Council 위원 (G3 + G0 참여)
- AB_COMPARISON: A/B 동일 테스트 스위트 실행 비교 (통과율·커버리지·성능·안정성)
- 이벤트 로그 JSONL 형식으로 추가 기록 (`{"role":"tester","event":"test_pass|test_fail",...}`)

## 7~9. Research Team (5세대 신규, `5th_mode.research = true`)

### Research Lead (`research-lead`)
- **조사 총괄** + Research Team 지휘
- G0 산출물 품질 관리
- 조사 범위 정의 → research-architect + research-analyst 병렬 탐색 지시
- 결과 통합 → SendMessage로 Team Lead에게 통합 보고서 전달
- Charter: PERSONA/RESEARCH_LEAD.md

### Research Architect (`research-architect`)
- **아키텍처 대안 탐색** + 기술 스택 비교 + PoC 설계
- research-lead 경유 보고
- Charter: PERSONA/RESEARCH_ARCHITECT.md

### Research Analyst (`research-analyst`)
- **기존 코드베이스 분석** + 의존성·영향 범위 조사 + 데이터 수집
- WebSearch / WebFetch 활용 가능 (sonnet 계열로도 운영 가능)
- research-lead 경유 보고
- Charter: PERSONA/RESEARCH_ANALYST.md

### Research Team 라이프사이클
1. TEAM_SETUP 완료 → `5th_mode.research = true` 확인 → 3인 스폰
2. RESEARCH 상태: 조사 범위 정의 → 병렬 탐색
3. research-lead가 통합 보고서 SendMessage
4. RESEARCH_REVIEW(G0): Team Lead 판정
5. PASS → PLANNING 진입 / FAIL → REWINDING → RESEARCH 재실행

### G0 PASS 기준
- 기술 조사 완료
- 아키텍처 대안 2개 이상 비교
- 리스크 분석 + 완화 방안
- 영향 범위 식별 (파일·모듈·API)
- (선택) PoC 결과 첨부

## 통신 모델 — Hub-and-Spoke

```
       planner
          ↕
backend-dev ← → Team Lead ← → frontend-dev
          ↕                ↕
       verifier          tester
```

원칙:
1. 팀원 → SendMessage(`recipient: "team-lead"`) → Team Lead
2. Team Lead → SendMessage(`recipient: "{팀원}"`) → 특정 팀원
3. **팀원끼리 직접 통신 금지**

## Task 도메인 태그 → 역할 매핑 (HR-6 / ASSIGN-1)

| 도메인 | 구현 팀원 | 검증 팀원 |
|---|---|---|
| `[BE]` | backend-dev | verifier + tester |
| `[DB]` | backend-dev | verifier + tester |
| `[FE]` | frontend-dev | verifier + tester |
| `[FS]` | backend-dev + frontend-dev | verifier + tester |
| `[TEST]` | **tester** (절대 BE/FE에 할당 금지 — ASSIGN-2) | verifier |
| `[INFRA]` | backend-dev | — |

## 게이트 분담 매트릭스

| 게이트 | 소유자 | 입력 | 출력 |
|---|---|---|---|
| **G0** Research Review | Team Lead (Council 참여 가능) | research-report.md | RESEARCH_REVIEW status |
| **G1** Plan Review | Team Lead | planner SendMessage | PLAN_REVIEW status |
| **G2** Code Review | verifier (Team Lead 보고) | 변경 파일 + 완료 기준 | report-verifier.md (대리 저장) |
| **G3** Test Gate | tester (Team Lead 보고) | 테스트 명령 + 시나리오 | report-tester.md + /tmp 결과 파일 |
| **G4** Final Gate | Team Lead | G2 + G3 결과 + Blockers | DONE 또는 REWINDING |

## 다음 노트

- [[2026-05-05_pab_ssot_persona_qc|페르소나·QC]] — 9 PERSONA + 11명 Verification Council 상세
- [[2026-05-05_pab_ssot_subssot_misc|SUB-SSOT·기타]] — 역할별 SUB-SSOT 모듈형 로딩
- [[2026-05-05_pab_ssot_workflow|워크플로우]] — 상태 머신 + 게이트 + 라이프사이클
- [[2026-05-05_pab_ssot_rules_chain|규칙·CHAIN]] — HR-6/ASSIGN, HR-7/LIFECYCLE
- [[PAB_SSOT_overview|MOC]]

## 참고

- `/PAB-SSOT-Nexus/docs/SSOT/docs/ROLES/README.md` — 역할 매핑·페르소나 교체 원칙
- `/PAB-SSOT-Nexus/docs/SSOT/docs/ROLES/team-lead.md`, `verifier.md`, `tester.md` 등 9개 역할 정의
- `/PAB-SSOT-Nexus/docs/SSOT/docs/1-project.md` §2 팀 구성 + §7 운용 원칙
