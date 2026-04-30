# 최종 보고서 템플릿 (Master Final Report)

> **버전**: 1.0 | **생성일**: 2026-04-16 (Phase-G sub-G-7)
> **적용 Step**: AutoCycle Step 13 — 최종 final report
> **작성 주체**: Team Lead (체인 또는 Phase 종료 시)
> **구조**: 사용자 원본 요청의 6섹션 요구 + Next Prompt Suggestion

---

## §1 원본 프롬프트

> {사용자 개발 요청 프롬프트 전문 인용}
> **출처**: `development-plan.md §1` 또는 `autocycle-initial-requirements.md`

---

## §2 계획

### 2.1 개발 계획 요약

| 항목 | 값 |
|------|-----|
| **Phase 범위** | {Phase X-Y ~ X-Z} |
| **Task 수** | {총 N개} |
| **복잡도 분포** | HIGH {a} / MED {b} / LOW {c} |
| **사전 반복 횟수** (Step 6) | {0~3}회 |
| **본 개발 사이클 수** (Step 7~9) | {1~3}회 |

### 2.2 KPI 계획 (development-plan §3)

| KPI ID | 지표 | 초기값 | 목표값 |
|--------|------|--------|--------|
| KPI-01 | ... | ... | ... |

---

## §3 달성 수치

### 3.1 KPI 달성 대조

| KPI ID | 목표값 | **최종 달성값** | 달성률 | PASS/FAIL |
|--------|--------|----------------|--------|-----------|
| KPI-01 | ... | **{실측}** | {%} | ✅/❌ |

### 3.2 Gate 통과 이력

| Phase | G2 | G3 | G4 | 비고 |
|-------|-----|-----|-----|------|
| X-Y | PASS | PASS | PASS | 1차 |
| X-Y (2차) | PASS | PASS | PASS | 수정계획 반영 |

### 3.3 프롬프트 정합성 (prompt-alignment-check §2)

- Drift 비율: {%} (목표 ≤10%)

---

## §4 개발 내역

### 4.1 변경 파일 요약

| 영역 | 파일 수 | 변경 라인 |
|------|---------|-----------|
| backend/ | {N} | +{A}/-{B} |
| web/ | {N} | +{A}/-{B} |
| tests/ | {N} | +{A}/-{B} |

### 4.2 주요 의사결정 로그

| 일시 | 결정 | 근거 | 영향 |
|------|------|------|------|
| ... | ... | ... | ... |

---

## §5 보완점 (Tech Debt)

### 5.1 기술 부채 요약

| Debt ID | 설명 | 난이도 | carryover_to |
|---------|------|--------|--------------|
| TD-001 | ... | HIGH | phase-{N+1} |

→ 상세: `docs/phases/phase-X-Y/tech-debt-report.md`

### 5.2 테스트 미달 항목

| KPI ID | 미달 사유 | 보완 방향 |
|--------|-----------|-----------|
| ... | ... | ... |

---

## §6 향후 시나리오

### 6.1 단기 (다음 1~2 Phase)

| 시나리오 | 설명 | 예상 효과 |
|----------|------|-----------|
| {시나리오 A} | Tech Debt TD-001 해소 | KPI-01 달성 |
| {시나리오 B} | {추가 기능} | {효과} |

### 6.2 중기 (3~5 Phase)

| 시나리오 | 설명 |
|----------|------|
| {아키텍처 개선} | {설명} |

---

## §7 Next Prompt Suggestion (Step 14)

### 7.1 추천 프롬프트 3안

| 안 | 추천 프롬프트 | 근거 (3요소) |
|----|--------------|-------------|
| **안 1** | "{구체적 프롬프트 문장}" | Tech Debt: TD-001 / KPI 미달: KPI-01 / 사용자 피드백: {있으면 기술, 없으면 "미수집"} |
| **안 2** | "{프롬프트}" | ... |
| **안 3** | "{프롬프트}" | ... |

### 7.2 사용자 피드백 반영 정도 (Phase-H H-5 확장)

#### 피드백 수집 가이드

| 항목 | 설명 |
|------|------|
| **수집 경로** | 사용자 대화 / 이슈 코멘트 / Telegram 피드백 / 별도 피드백 세션 |
| **수집 시점** | Phase 완료 보고 후 ~ final report 작성 전 (권장: G3 PASS 직후) |
| **수집 형식** | 자유 텍스트 (사용자 원문 인용 필수) |
| **미수집 시** | §7.1 3안 모두에 **"사용자 피드백 미수집 — 피드백 수집부터 필요"** 명시 |

#### 피드백 반영 기록

| 항목 | 값 |
|------|-----|
| **피드백 수집 여부** | 예 / 아니오 |
| **수집 경로** | {경로 명시} |
| **피드백 원문** | {사용자 원문 인용 또는 "미수집"} |
| **피드백 내용 요약** | {요약 또는 "미수집 — 피드백 수집부터 필요"} |
| **반영 정도** | 완전 / 부분 / 미반영 |
| **미반영 사유** | {사유 또는 "해당 없음"} |

> 피드백 미수집 시: §7.1 추천 프롬프트 3안은 "현재 데이터 기반 추정"으로 한정하고,
> **"사용자 피드백 수집 후 재조정 권고"**를 각 안에 명시.

### 7.3 다음 마스터 플랜 initiator 힌트 (Phase-I I-4)

본 final-report의 Next Prompt Suggestion이 채택되어 다음 마스터 플랜으로 이어질 경우, 해당 마스터 플랜의 YAML 헤더에 기본 적용될 `initiator` 값을 명시한다.

```yaml
initiator_hint: "ai-handoff"       # 본 Next Prompt 자동 이어짐 (기본값)
prompt_quality_hint: "n/a"         # ai-handoff 시 프롬프트 품질 체크 제외
pre_draft_required: false          # Step 0 스킵
```

**규칙**:
- 본 필드는 **기본값**이며 사용자가 master-plan YAML을 직접 `initiator: "user"`로 변경 시 오버라이드
- AI handoff로 이어진 Phase는 **Step 0 스킵** + **CHAIN-13 자동 로딩**으로 진행
- 사용자가 `/plan` 명시 호출 시 본 힌트와 무관하게 Step 0 강제 진입 (최우선)

**관련 규칙/문서**:
- `core/6-rules-index.md §1.20 PROMPT-QUALITY` (HIGH)
- `SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md §Step-0 Branch`
- `.claude/skills/plan/SKILL.md`

---

## §8 verifier 승인 (Phase-H H-4 — 필수)

> **본 섹션은 필수**. verifier 독립 검증 없이 G4 DONE 전이 불가.

### 8.1 verifier 승인 절차

```
master-final-report.md 초안 완성 (Team Lead)
  → verifier 스폰 (read-only, 별도 컨텍스트)
  → verifier가 §1~§7 전 섹션 검증:
     V-1: 원본 프롬프트 정확성 (§1 vs 실제 요청)
     V-2: KPI 달성 수치 정확성 (§3 vs 실측 데이터)
     V-3: Tech Debt 누락 여부 (§5 vs tech-debt-report)
     V-4: Next Prompt 3요소 충족 (§7: Tech Debt + KPI 미달 + 피드백)
  → PASS: 아래 표 기입 + G4 진입 허가
  → FAIL: 결함 사항 기록 → Team Lead 수정 → 재검증 (최대 2회)
```

### 8.2 승인 기록

| 항목 | 값 |
|------|-----|
| **verifier 독립 검증** | PASS / FAIL |
| **검증 축** | V-1, V-2, V-3, V-4 각 PASS/FAIL |
| **결함 사항** | {FAIL 축별 상세, PASS 시 "없음"} |
| **승인 일시** | YYYY-MM-DD |
| **verifier 보고서** | `docs/phases/phase-X-Y/verifier-final-report.md` |

### 8.3 G4 연동

- G4 체크리스트에 **"§8 verifier 승인 = PASS"** 항목 필수 추가
- verifier FAIL 상태에서 G4 DONE 전이 시도 시 **자동 차단** (AUTO-1 Persister 검증)

---

**문서 관리**: v1.1, 2026-04-16, AutoCycle Step 13·14 최종 보고서 템플릿 (Phase-H H-4 verifier 필수화 + H-5 피드백 확장)
