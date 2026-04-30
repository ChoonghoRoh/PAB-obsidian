# Defect Report: [요약 제목]

```yaml
---
defect_id: "DEF-phase-X-Y-NNN"
severity: "Critical | Major | Minor | Trivial"
type: "Functional | Performance | Security | Usability | Compatibility"
status: "Open | In Progress | Resolved | Closed | Deferred"
reporter: "[tester 이름 또는 ID]"
assignee: "[담당 팀원 이름 또는 ID]"
phase: "X-Y"
task: "X-Y-N"
created_at: "YYYY-MM-DDTHH:MM:SSZ"
resolved_at: null
---
```

---

## 1. 요약

- **제목**: [결함 요약 (1줄)]
- **발견 시점**: [G3 테스트 / 통합 테스트 / E2E 등]
- **관련 테스트**: [실패한 테스트 파일 및 함수명]

---

## 2. 재현 절차 (Steps to Reproduce)

1. [사전 조건: 환경 설정, 데이터 준비 등]
2. [단계 1]
3. [단계 2]
4. [단계 3]
5. [결함 발생 확인]

---

## 3. 기대 결과 (Expected Result)

[정상 동작 시 예상되는 결과를 구체적으로 기술]

---

## 4. 실제 결과 (Actual Result)

[결함 발생 시 관찰된 실제 결과를 구체적으로 기술]

---

## 5. 환경 (Environment)

| 항목 | 값 |
|------|-----|
| **OS** | [예: macOS 15.x / Ubuntu 24.04] |
| **런타임** | [예: Python 3.12.x / Node.js 22.x] |
| **Docker** | [예: Docker Compose v2.x, 이미지 태그] |
| **브라우저** | [예: Chrome 130 (E2E 해당 시)] |
| **DB** | [예: PostgreSQL 16.x] |
| **기타** | [Ollama 버전, Redis 버전 등] |

---

## 6. 스크린샷 / 로그

### 에러 로그

```
[에러 메시지, 스택 트레이스 등 붙여넣기]
```

### 스크린샷

> 해당 시 이미지 첨부 또는 경로 기재. 없으면 "N/A".

---

## 7. 비고

- **우회 방법**: [있으면 기술, 없으면 "없음"]
- **관련 결함**: [연관 Defect ID, 없으면 "없음"]
- **비고**: [추가 참고 사항]

---

> **참조**: [_backup/GUIDES/tester-work-guide.md § 결함 분류 체계](../_backup/GUIDES/tester-work-guide.md#결함-분류-체계-istqb-ctfl-40-기반), [3-workflow.md §4.2 G3](../3-workflow.md#42-게이트별-판정-기준)
