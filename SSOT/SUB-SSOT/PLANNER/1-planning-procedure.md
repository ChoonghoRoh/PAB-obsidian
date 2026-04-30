# Planning Procedure — SUB-SSOT

> **버전**: 1.1 | **갱신**: 2026-04-15 (Phase-F — _backup/GUIDES/planner-work-guide.md 고유 콘텐츠 통합)
> **소스**: `_backup/GUIDES/planner-work-guide.md` + DEV-work-guide 파일4 §0~2 (2026-04-15 GUIDES → SUB-SSOT 이관 완료)

## 실행 프로세스

```
[1] Team Lead: SendMessage → planner에게 계획 분석 요청
[2] planner: SSOT·리스크 확인 (ssot_version 일치, blockers 확인)
[3] planner: 요구사항 분석, Task 분해 (도메인 태그·담당·완료 기준)
[4] planner: G1 준비 여부 점검
[5] planner: SendMessage → Team Lead에게 분석 결과 반환
```

---

## Task 분해 규칙

### TODO 형식 (필수)

```
- [ ] {Task name}
      done_when : {code_written | test_passed | doc_recorded | human_approved}
      verify_by : {pytest path::test_name | file existence | command}
      complexity: HIGH / MED / LOW
      risk      : {known risk or "none identified"}
      covered_by: SCENARIO-{N}, SCENARIO-{M}
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

```markdown
## Planner 분석 결과 — Phase X-Y

### SSOT·리스크
- SSOT 버전: (일치/불일치)
- 리스크: (목록 또는 없음)

### Task 분해
| Task ID | 도메인 | 담당 팀원     | 요약 | 완료 기준 | 복잡도 | UI 변경 |
|---------|--------|--------------|------|-----------|--------|---------|
| X-Y-1   | [DB]   | backend-dev  | ...  | ...       | HIGH   | 아니오  |
| X-Y-2   | [BE]   | backend-dev  | ...  | ...       | MED    | 아니오  |
| X-Y-3   | [FE]   | frontend-dev | ...  | ...       | MED    | 예      |

### G1 준비 여부
- 완료 기준 명확: 예/아니오
- Task 수: N (3~7 범위)
- 프론트엔드 동선/구조 기술: 예/아니오
- DESIGN_REVIEW 필요: 예/아니오 (UI 변경 포함 Task 존재 시)
```

---

## 병렬 처리 Phase

**참조**: `1-project.md §7.3 병렬 처리 정책`.

병렬 BUILDING(또는 병렬 VERIFYING) 시 planner는 추가 명시:

| 항목 | 내용 |
|------|------|
| **수정 파일 경로** | 각 Task별 **수정(쓰기) 예정 파일 경로**를 Task 분해 표에 포함. 병렬 가능 여부 판단 근거 |
| **트랙별 작업 지시** | 병렬 가능한 Task 쌍(수정 파일 교집합 ∅)에 대해 트랙별 분리 지시. 예: `Track A: Task X-Y-2, X-Y-3 (backend-dev-1) / Track B: Task X-Y-4, X-Y-6 (backend-dev-2)` |
| **담당 팀원 구분** | 동일 역할 다중 인스턴스(backend-dev-1, backend-dev-2 등) 사용 시 Task–담당 매핑 명시. Team Lead가 SendMessage를 **트랙별 별도 전달** 가능하도록 |

**신규 기능 제작** Phase는 병렬 적용 대상 아님 — **단일 인스턴스·순차 진행**.

---

## 유의사항

- planner는 **파일을 쓰지 않음** → SendMessage로만 보고
- shutdown_request 수신 시 → approve: true 후 종료
- 리서치 결과 미반영 시 G1 FAIL 가능 (5th_mode.research=true 환경)

---

## 5th 확장 연계 (Phase-F 이관)

### DESIGN_REVIEW 상태 참조

5세대에서 추가된 **DESIGN_REVIEW** 상태는 E2E 테스트 통과 후 UI/UX 변경이 포함된 Phase에서 실행된다. Planner는 Task 분해 시 **UI 변경 여부를 명시**하여 Team Lead가 DESIGN_REVIEW 진입 여부를 판단할 수 있도록 한다.

- Task 분해 표에 `UI 변경` 열 추가 (예/아니오) — 위 §출력 형식에 이미 반영됨
- UI 변경이 포함된 Task가 있으면 planner 분석 결과에 **"DESIGN_REVIEW 필요"** 명시

### G0 결과 반영 프로토콜

`5th_mode.research: true` 환경에서는 PLANNING 이전에 **RESEARCH → RESEARCH_REVIEW(G0)** 가 선행된다. Planner는 G0 통과 후 전달된 `research-report.md`를 반드시 참조하여 계획을 수립한다.

```
G0 PASS → Team Lead가 planner에게 리서치 결과 전달
  → planner: research-report.md 읽기
  → 기술 선택 결과를 Task 분해에 반영
  → 리서치 보고서의 영향 범위·리스크를 Task 완료 기준에 포함
```

- **리서치 결과 미반영 시**: G1 FAIL 사유
- **권장 옵션 변경 시**: planner가 Team Lead에게 사유 보고 필수

---

**문서 관리**: v1.1, PLANNER 계획 절차 (2026-04-13 생성, 2026-04-15 Phase-F 확장)
