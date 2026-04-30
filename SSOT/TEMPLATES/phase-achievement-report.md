# Phase 달성 보고서 템플릿 (Phase Achievement Report)

> **버전**: 1.0 | **생성일**: 2026-04-16 (Phase-G sub-G-5)
> **적용 Step**: AutoCycle Step 8 — 1사이클 후 계획 부합 검증
> **작성 주체**: Team Lead (G4 판정 시점)

---

## §1 Phase 기본 정보

| 항목 | 값 |
|------|-----|
| **Phase ID** | X-Y |
| **개발 계획서** | `docs/phases/phase-X-Y/development-plan.md` |
| **원본 프롬프트** | {development-plan §1 인용 또는 링크} |
| **시작일** | YYYY-MM-DD |
| **완료일** | YYYY-MM-DD |
| **사이클 차수** | 1차 / 2차 (Step 9 재계획) |

---

## §2 KPI 달성 대조

| KPI ID | 지표 | 초기값 | 목표값 | **달성값** | 달성률 | PASS/FAIL |
|--------|------|--------|--------|-----------|--------|-----------|
| KPI-01 | {지표} | {as-is} | {to-be} | **{실측}** | {%} | ✅/❌ |
| KPI-02 | ... | ... | ... | ... | ... | ... |

### 달성 요약

- 전체 KPI: {N}개
- PASS: {A}개 · FAIL: {B}개
- **달성률**: {A/N × 100}%

---

## §3 미완성 항목 분석

| 미완성 ID | KPI ID | 현 달성값 | 목표 대비 차이 | 원인 분석 | 수정 가능성 |
|-----------|--------|-----------|---------------|-----------|-------------|
| INC-01 | KPI-01 | p99=350ms | -150ms | {쿼리 최적화 미시행} | 다음 사이클 가능 |

---

## §4 수정 계획서 (Step 8 — 미완성 시)

| INC ID | 수정 내용 | 담당 | 목표 | 반영 Phase |
|--------|-----------|------|------|------------|
| INC-01 | {구체 수정} | backend-dev | KPI-01 달성 | Phase X-Y (2차) 또는 X-Y+1 |

> **2회 제한**: Step 9 규칙에 의해 본 수정 계획은 **최대 2회** 이행. 초과 시 `tech-debt-report.md`로 이관.

---

## §5 Gate 통과 결과

| Gate | 판정 | 비고 |
|------|------|------|
| G2 | PASS / PARTIAL / FAIL | {verifier 보고서 링크} |
| G3 | PASS / FAIL | {tester 보고서 링크} |
| G4 | PASS / FAIL | Team Lead 종합 |

---

## §6 master-plan 참조 보고

| 항목 | 값 |
|------|-----|
| master-plan 파일 | {링크} |
| Phase Chain 기록 | {chain 파일 + 1줄 요약} |
| 본 보고서의 master-plan 반영 | {완료/미완료} |

---

**문서 관리**: v1.0, 2026-04-16, AutoCycle Step 8 Phase 달성 보고서 템플릿. Phase-G sub-G-5.
