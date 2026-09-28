# Planning Procedure — SUB-SSOT

## Planner 역할 요약

> 본 SUB-SSOT는 역할 base 세트(`entrypoint.md` §역할별 스폰 컨텍스트 주입의 자기 행)와 함께 로딩한다(FRESH-12).

| 항목 | 내용 |
|------|------|
| **팀원 이름** | `planner` |
| **에이전트 타입** | pab-planner / opus |
| **코드 편집** | ❌ 금지 |
| **통신** | Team Lead 경유 (SendMessage). 지시를 받으면 즉시 한 줄 ack(COMM-1), 팀원끼리 직접 메시지 금지(COMM-2) |
| **쓰기 권한** | 없음 (EDIT-4 — REPORT-1 결과 파일만 예외. 결과는 파일 기록 + SendMessage로 요지 · 경로 전달) |
| **생애주기** | PLANNING에 스폰 → G4 입력(계획서 이행 점검) 제출까지 상주. 대기는 할당 상태로 본다(LIFECYCLE-1 · 2 예외 — `WORKFLOW/workflow.md` §AGENT-LIFECYCLE) |

## 핵심 원칙

1. SSOT 버전·리스크 확인 후 계획 시작
2. Task 3~7개 분해, 도메인 태그·담당 팀원 명시
3. 완료 기준은 측정 가능해야 함
4. 시간 추정 금지 → 복잡도 티어(HIGH/MED/LOW)
5. Team Lead가 제시한 추천안(권장 옵션)과 다르게 계획하면 Team Lead에게 사유를 보고한다
6. 업무 지시 3단계(DELEGATE-4): ① 현행 소스 · 정본을 파일:줄로 조사하고 ② 가장 비슷한 외부 사례를 출처와 함께 적용한다(검색 수단: `ROLES/planner.md` §3.3). ③ 사용자와 조율할 항목은 질문 목록으로 Team Lead에게 넘긴다
7. KPI · 규칙 대조표 명령은 VP §판정 명령 작성 규칙(`ROLES/SUB-SSOT/VERIFIER/verification-procedure.md`)을 따른다. planner는 명령을 **적기만** 하고, 실행 · 확인은 G1에서 Team Lead가 한다(EDIT-4 · ASSIGN-4 — 규칙 완화 없음). 적용분: 경로 비교에 `git -c core.quotePath=false` · 결과 파일 집계는 `## 결함` 절 안 정확 일치 · 파일 소유는 G2 요청 「커밋 ↔ Task 표」와 기계 대조. 대조표에는 다음 네 행을 반영한다: ① 표 칸 수 · 코드 펜스 짝 · 상대 링크 실재를 재는 기계 행 ② 「변경 줄 0」을 기준으로 삼는 행은 변경 파일 수 M ≥ 1 조건을 함께 건다 ③ 계열(같은 뜻의 다른 표기)을 잡는 정규식인지 확인하는 행(판독 — 명령으로 대체할 수 없는 이유: 표기 계열 판단은 사람이 본다) ④ `git diff --diff-filter=A` 새 파일이 MANIFEST에 포함됐는지 보는 행. Task 완료 기준 · 판독 항목도 규칙 ID만으로 가리키지 않고 뜻을 본문에 적는다(위치 · 예/아니오 질문 · 판정 문장)

## G1 판정 기준

정본은 `WORKFLOW/handoff/planning.md` §2다(①~⑧ · ⑨는 Team Lead가 G1에서 실행). planner는 그 번호대로 자가 점검한 결과를 「G1 준비 여부」에 적고, 판정은 Team Lead가 한다.

---

## 실행 프로세스

```
[1] Team Lead: SendMessage → planner에게 계획 분석 요청
[2] planner: SSOT·리스크 확인 (ssot_version 일치, blockers 확인)
[3] planner: 요구사항 분석, Task 분해 (도메인 태그·담당·완료 기준)
[4] planner: G1 준비 여부 점검
[5] planner: 결과 파일 기록(REPORT-1) → SendMessage로 요지 · 경로를 Team Lead에게 반환
```

---

## Task 분해 규칙

### TODO 형식 (필수)

```
- [ ] {Task name}
      done_when : {code_written | test_passed | doc_recorded | human_approved}
      verify_by : {test path::test_name | file existence | command}
      complexity: HIGH / MED / LOW
      risk      : {known risk or "none identified"}
      covered_by: SCENARIO-{N}, SCENARIO-{M}
      reuse     : {정본 컴포넌트 목록 | 신규 선택 — LEAD_SELECTED 전 착수 금지}   ([FE] [DS] [FS]만, REUSE-3)
```

### 복잡도 티어

| 티어 | 기준 |
|------|------|
| **HIGH** | 외부 API / DB 스키마 변경 / Auth 로직 / 신규 라이브러리 |
| **MED** | 기존 모듈 확장 / 새 라우트 / 설정 변경 |
| **LOW** | 단순 CRUD / 상수 변경 / 이름 변경 |

### IMPL_GRANULARITY 판정

```
요청 수신 시 구현 단위 선언:
  FN          = 단일 함수/메서드
  UNIT        = 단일 모듈/클래스 + 테스트
  INTEGRATION = 복수 모듈 E2E 연동
  SYSTEM      = BE + FE + DB + Infra 교차
```

---

## 출력 형식

분석 결과는 결과 파일의 REPORT-2 보고 블록(`WORKFLOW/handoff/common.md` §4) 「결과」 칸 안에 아래 구조로 쓴다. 분석 결과 구조의 정본은 이 절이다(`ROLES/planner.md` · `pab-planner`는 인용한다).

```markdown
## Planner 분석 결과 — Phase X-Y

### SSOT·리스크
- SSOT 버전: (일치/불일치)
- 리스크: (목록 또는 없음)

### Task 분해
| Task ID | 도메인 | 담당 팀원     | 요약 | 완료 기준 | 복잡도 | 정본 컴포넌트(REUSE-3) |
|---------|--------|--------------|------|-----------|--------|---------------|
| X-Y-1   | [DB]   | backend-dev  | ...  | ...       | HIGH   | —             |
| X-Y-2   | [BE]   | backend-dev  | ...  | ...       | MED    | —             |
| X-Y-3   | [FE]   | frontend-dev | ...  | ...       | MED    | (목록 또는 신규 선택) |

### G1 준비 여부 (handoff/planning §2 번호대로)
- ① ~ ⑦: 예 / 아니오 / 해당 없음 — 근거 한 줄씩
- ⑧ DESIGN_REVIEW 필요: 예/아니오 — 복잡도로 본 의견. 판단은 Team Lead(`WORKFLOW/workflow.md` §PLAN_REVIEW → DESIGN_REVIEW)
```

---

## 검토 · 벤치마크

- 대상: pre-draft · master plan · 계획 초안 · DESIGN_REVIEW 설계(Team Lead가 지시할 때).
- 결과 파일에 「지적 · 근거(파일:줄 또는 출처 URL · 명령) · 제안」 표로 쓴다. 판정 · 채택은 Team Lead가 한다.
- 외부 사례는 `ROLES/planner.md` §3.3 순서로 찾는다.

---

## 계획서 이행 점검 (G4 입력)

통합 G2 · G3가 끝난 뒤, 계획한 것이 모두 산출됐는지 문서로 대조한다. 판정은 Team Lead(G4)가 한다.

| 항목 | 내용 |
|------|------|
| **기준** | `CORE/shared-definitions.md` §6.3 VUL3-01~05 |
| **입력** | plan · tasks 완료 기준 · 수정 파일 목록 · G2 · G3 결과 파일 · `git -c core.quotePath=false diff --name-only <기준 커밋> <최종 SHA>` |
| **방법** | 문서 대조만 한다. 검증 명령을 다시 돌리지 않는다(ASSIGN-4) |
| **출력** | VUL3 항목마다 「충족 / 미충족 / 이탈(DEVIATION 근거 유무)」 표. 판정 문구(PASS · FAIL)를 쓰지 않는다 |
| **겹침 금지** | 품질 결함은 「관찰」로만 적는다 — Team Lead가 verifier에게 보낸다 |

---

## 병렬 처리 Phase

병렬 BUILDING(또는 병렬 VERIFYING) 시 planner는 추가 명시:

| 항목 | 내용 |
|------|------|
| **수정 파일 경로** | 각 Task별 **수정(쓰기) 예정 파일 경로**를 Task 분해 표에 포함. 병렬 가능 여부 판단 근거 |
| **트랙별 작업 지시** | 병렬 가능한 Task 쌍(수정 파일 교집합 ∅)에 대해 트랙별 분리 지시. 예: `Track A: Task X-Y-2, X-Y-3 (backend-dev-1) / Track B: Task X-Y-4, X-Y-6 (backend-dev-2)` |
| **담당 팀원 구분** | 동일 역할 다중 인스턴스(backend-dev-1, backend-dev-2 등) 사용 시 Task–담당 매핑 명시. Team Lead가 SendMessage를 **트랙별 별도 전달** 가능하도록 |

**신규 기능 제작** Phase는 병렬 적용 대상 아님 — **단일 인스턴스·순차 진행**.

---

## 유의사항

- planner는 **산출물 파일을 쓰지 않음** → REPORT-1 결과 파일 기록 + SendMessage로 요지 · 경로 보고
- 상주 중에는 Task 사이 대기를 할당 상태로 보고 다음 지시를 기다린다. shutdown_request를 받으면 approve: true 후 종료한다(보통 G4 입력을 낸 뒤다)
