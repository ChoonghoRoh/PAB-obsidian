# 기술 부채 보고서 템플릿 (Tech Debt Report)

> **버전**: 1.0 | **생성일**: 2026-04-16 (Phase-G sub-G-6)
> **적용 Step**: AutoCycle Step 12 — 수정 불가 항목 별도 문서화
> **작성 주체**: Team Lead (Phase 종료 시점)

---

## §1 Phase 기본 정보

| 항목 | 값 |
|------|-----|
| **Phase ID** | X-Y |
| **달성 보고서** | `docs/phases/phase-X-Y/phase-achievement-report.md` |
| **작성일** | YYYY-MM-DD |

---

## §2 기술 부채 목록

| Debt ID | 유형 | 설명 | 원인 | 난이도 | 영향도 | carryover_to |
|---------|------|------|------|--------|--------|--------------|
| TD-001 | [코드/아키텍처/테스트/문서/인프라] | {설명} | {Phase X-Y에서 미해결 사유} | HIGH/MED/LOW | [1~5] | `phase-{N+1}` |
| TD-002 | ... | ... | ... | ... | ... | ... |

> **carryover_to**: 다음 Phase ID. Team Lead가 해당 Phase 시작 시 본 보고서 로딩 의무 (Phase-H H-3 규칙).

---

## §3 미수정 사유 상세

| Debt ID | 수정 시도 여부 | 실패 원인 | 최소 해결 조건 |
|---------|---------------|-----------|---------------|
| TD-001 | 예 (2회 시도, Step 9 2회 제한 도달) | {구체 실패 사유} | {필요 자원·선행 조건} |
| TD-002 | 아니오 (범위 외 판정) | {판정 근거} | {조건} |

---

## §4 우선순위 매트릭스

| 우선순위 | Debt ID | 난이도 × 영향도 점수 | 권고 Phase |
|----------|---------|---------------------|------------|
| P1 (즉시) | TD-001 | 12 (HIGH×4) | phase-{N+1} |
| P2 (계획) | TD-002 | 6 (MED×3) | phase-{N+2} |
| P3 (여유) | ... | ... | 미정 |

---

## §5 차기 Phase 연계 (CHAIN-12 자동 로딩 — Phase-H H-3 확장)

### 5.1 carryover_to 필드 규칙

| 규칙 | 설명 |
|------|------|
| **필수 기입** | 모든 Debt ID에 `carryover_to` 값 필수. 미정 시 `"미정 — master-plan 작성 시 결정"` |
| **대상 Phase 형식** | `phase-{N+1}` 또는 구체적 Phase ID (예: `phase-5-2`) |
| **우선순위 연동** | P1 항목은 반드시 **직후 Phase** 지정. P2는 1~2 Phase 이내. P3은 미정 허용 |

### 5.2 자동 로딩 절차 (CHAIN-12)

차기 Phase Team Lead는 **Phase 시작 시 아래를 자동 수행**:

```
Phase-{N} 시작:
  1. status.md 읽기 (ENTRY-1)
  2. Glob("docs/phases/phase-{N-1}*/tech-debt-report.md") → 존재 확인
  3. 존재 시:
     a) §2 기술 부채 목록 읽기
     b) carryover_to == "phase-{N}" 항목 추출
     c) 추출 항목을 plan.md §선행 해결 항목에 등록
     d) master-plan 해당 Phase 행에 "Tech Debt carryover: TD-XXX" 주석 추가
  4. 비존재 시: 정상 진행 (로그: "이전 Phase Tech Debt 없음")
```

### 5.3 미해결 시 재등록

- 현재 Phase에서도 해결 못한 carryover 항목 → **본 Phase의 tech-debt-report.md에 재등록**
- Debt ID 유지 (TD-001 → TD-001), `carryover_to`만 `phase-{N+2}`로 갱신
- **3 Phase 연속 carryover 시**: HUMAN_ESCALATION_REQUEST 발동 (만성 부채 경고)

---

**문서 관리**: v1.1, 2026-04-16, AutoCycle Step 12 기술 부채 보고서 템플릿 (Phase-H H-3 carryover 확장)
