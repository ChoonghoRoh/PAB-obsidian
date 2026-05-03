---
task_id: "1-5-3"
title: "G2_wiki 재검증 — 본질 5항목 + Hard 9 + Soft 6 + auditor mode (cross-model)"
domain: WIKI-SKILL
owner: verifier
priority: P0
estimate_min: 45
status: rework_required
depends_on: ["1-5-2", "1-5-6"]
blocks: []
intent_ref: docs/phases/phase-1-5/phase-1-5-intent.md
cross_model: "backend-dev=sonnet, verifier=opus"
---

# Task 1-5-3 (REWORK) — G2_wiki 재검증

> **본질 (잃지 말 것)**:
> 1. 원본 immutable 보존 (`wiki/15_Sources/`)
> 2. LLM 요약본 (`wiki/10_Notes/`)
> 3. TOC 양방향 링크
> 4. 두 산출물 동시 생성
> 5. Karpathy 3계층 아키텍처 충족

## 목적

T-2 v2 SKILL.md + T-5 vault 확장 + T-6 재생성 노트 한 쌍을 통합 검증한다. v1 검증과 달리 **본질 5항목 강제 체크** + **auditor mode**가 추가되어 결정/의미 검증보다 본질 통찰이 우선한다.

> ⚠️ **HR-6 / E-4 / Cross-model 강제**: backend-dev(sonnet)와 verifier(opus)는 다른 모델이어야 한다. backend-dev 자기 검증 금지.

## 입력
- T-2 산출: `skills/wiki/SKILL.md` v2
- T-5 산출: `wiki/40_Templates/SOURCE.md`, `_schema.json` 갱신, `wiki/00_MOC/TYPES/SOURCE.md`, `wiki/15_Sources/` 폴더, `frontmatter-spec.md`/`naming-convention.md` 갱신
- T-6 산출: `wiki/15_Sources/2026-05-02_karpathy_llm_wiki_source.md` + `wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md` (재생성)
- 의도 문서: `docs/phases/phase-1-5/phase-1-5-intent.md`
- baseline: `docs/phases/phase-1-5/poc/wiki-skill-simulation-baseline.md` (Soft #4 범위 5~12로 완화 적용)

## 산출
- `docs/phases/phase-1-5/reports/report-verifier-v2.md`

## 검증 절차 (3-stage)

### STAGE A — 본질 5항목 강제 체크 (FAIL 1건이라도 G2_wiki FAIL)

| # | 본질 | 검증 방법 | PASS 기준 |
|---|---|---|---|
| 1 | 원본 immutable 보존 | `wiki/15_Sources/2026-05-02_karpathy_llm_wiki_source.md` 존재 + frontmatter `type: "[[SOURCE]]"` + 본문 분량(원문 대비 손실률) | 파일 존재 + SOURCE TYPE + 원문 분량 80% 이상 보존 |
| 2 | LLM 요약본 | `wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md` 존재 + frontmatter `type: "[[RESEARCH_NOTE]]"` | 파일 존재 + RESEARCH_NOTE TYPE |
| 3 | TOC 양방향 링크 | 요약본의 각 H2 섹션 직후 `[원본 §... →](..._source.md#anchor)` 패턴 존재 + anchor가 원본 실제 헤더와 일치 | 11/11 H2 섹션에 링크 + 모든 anchor 일치 (또는 LLM 판단 합리적 매핑) |
| 4 | 두 산출물 동시 생성 | T-6 보고서에서 단일 호출로 두 파일 동시 생성 명시 + 타임스탬프 같은 분 안 | 두 파일의 `created` 동일 또는 1분 이내 |
| 5 | Karpathy 3계층 충족 | 원본/위키/스키마 분리 — `wiki/15_Sources/` (immutable) / `wiki/10_Notes/` + `wiki/00_MOC/` (LLM 갱신) / `skills/wiki/SKILL.md` + `wiki/30_Constraints/` (스키마) | 3 계층 폴더/파일 모두 존재 + 역할 분리 명시 |

**STAGE A 1건이라도 FAIL → G2_wiki 즉시 FAIL, T-2/T-5/T-6 재작업 권고**

### STAGE B — Hard Match 9항목 (baseline §11.1, v2 갱신 적용)

| # | 항목 | 갱신 사항 |
|---|---|---|
| 1 | 파일 경로 | 요약본 + 원본 두 경로 모두 검증 |
| 2 | 슬러그 정규식 | 둘 다 정규식 PASS |
| 3 | frontmatter 11필드 | 둘 다 11필드 모두 존재 |
| 4 | 요약본 type = `"[[RESEARCH_NOTE]]"` | (v1과 동일) |
| 5 | 요약본 index = `"[[KNOWLEDGE_MGMT]]"` | (v1과 동일) |
| 6 | topics wikilink 형식 | (v1과 동일) |
| 7 | created/updated 패턴 | 둘 다 PASS |
| 8 | 요약본 tags 첫 항목 = `research-note` | (v1과 동일) |
| 9 | link-check PASS | violations=0 (양 파일 모두), broken은 의도 unresolved 시 WARN 분리 |

**추가 검증 (v2 신규)**:
- 원본 type = `"[[SOURCE]]"`
- 원본 tags 첫 항목 = `source`
- 요약본 sources에 원본 wikilink 포함

### STAGE C — Soft Match + auditor mode

#### Soft Match (baseline §11.2, 6항목, 범위 완화 적용)

| # | 항목 | 허용 범위 |
|---|---|---|
| 1 | title 키워드 | (v1 동일) |
| 2 | description | (v1 동일) |
| 3 | slug | (v1 동일) |
| 4 | 본문 H2 섹션 수 | **5~12개로 완화** (v1 5~10에서) |
| 5 | wikilink 5개 이상 | (v1 동일) |
| 6 | 핵심 인용 포함 | (v1 동일) |

#### auditor mode (verifier 마지막 단계, 본 task의 핵심 추가)

verifier는 검증 마지막에 **의도 부합 별도 체크**를 수행:

1. `phase-1-5-intent.md` §본질 5항목 vs 실제 산출물 — 줄별 매핑 표
2. `phase-1-5-intent.md` §비목표 — 위반 항목 없는지 (다중 SKILL / skill_bridge / 옵션 모드 분기 등)
3. v1 손실률 편차 (팁&트릭 20%) → v2에서 원본 보존으로 해소됐는지 (원본 파일이 100% 보존이면 자동 해소)
4. 사용자 본질 통찰("위키 한쪽만 만들고 원본을 안 보존했다") → v2에서 정정됐는지

auditor mode 결과: AUDITOR PASS / WARN / FAIL — STAGE A/B/C와 별도 등급. AUDITOR FAIL 시 G2_wiki PASS여도 사용자 결정 대기.

## 보고서 형식

```markdown
# Phase 1-5 verifier 보고서 v2 — G2_wiki 재검증

**Cross-model**: backend-dev=sonnet, verifier=opus

## 1. 환경 확인 (T-1, T-4, T-5 산출물 존재 + 정의 일치)
...

## 2. STAGE A — 본질 5항목 강제 체크
| # | 본질 | 결과 | 근거 |
| 1 | 원본 immutable 보존 | ✓/✗ | 파일 존재 + SOURCE TYPE + 분량 N% |
| 2 | LLM 요약본 | ✓/✗ | ... |
| 3 | TOC 양방향 링크 | ✓/✗ | 11/11 섹션 링크 + anchor 일치 |
| 4 | 두 산출물 동시 | ✓/✗ | created 시각 비교 |
| 5 | Karpathy 3계층 | ✓/✗ | 3 계층 매핑 표 |

→ STAGE A: PASS / FAIL

## 3. STAGE B — Hard Match 9 + 추가 검증
... (표)

## 4. STAGE C — Soft Match 6 + auditor mode

### 4.1 Soft Match
... (표)

### 4.2 auditor mode
- 의도 본질 5 vs 산출물: ... (매핑 표)
- 비목표 5 위반 점검: ... (모두 ✓)
- v1 손실률 편차 해소: ... (원본 보존으로 자동 해소)
- 사용자 본질 통찰 정정: ... (✓)

→ AUDITOR: PASS / WARN / FAIL

## 5. 차이 분석 + SKILL.md 보강 권고
...

## 6. 종합 판정
- STAGE A: ...
- STAGE B: ...
- STAGE C Soft: ...
- AUDITOR: ...
- 종합: PASS / PASS+ / WARN / FAIL
- G4 진입 가능 여부: ...
```

## 판정 기준

- **PASS**: STAGE A 5/5 PASS + STAGE B 9/9 + 추가 3 PASS + Soft 4/6 PASS + AUDITOR PASS → G2_wiki PASS, G4 진입 가능
- **PASS+**: 위 + Soft 6/6 PASS + auditor 통찰 1건 이상 baseline 우수 → baseline 갱신
- **WARN**: STAGE A 5/5 PASS + STAGE B PASS + Soft 3/6 이하 또는 AUDITOR WARN → 사용자 합의 후 G4 진입
- **FAIL**: STAGE A 1건 이상 FAIL OR STAGE B Hard 1건 이상 FAIL OR AUDITOR FAIL → 재작업 필수

## 완료 기준

- [ ] STAGE A 5항목 모두 검증 + 보고서 표 작성
- [ ] STAGE B Hard 9 + 추가 3 검증
- [ ] STAGE C Soft 6 + auditor mode 4 항목 검증
- [ ] 차이 분석 + SKILL.md 보강 권고 (있을 경우)
- [ ] 종합 판정 명시
- [ ] `report-verifier-v2.md` 작성

## 완료 보고

1. TaskUpdate 1-5-3 in_progress → completed
2. SendMessage(to="team-lead", summary="Phase 1-5 verifier v2 — STAGE A/B/C/AUDITOR <판정>", message="종합: <PASS/...>. STAGE A 본질 5항목 결과: <X/5>. AUDITOR: <PASS/...>. 보고서 경로: docs/phases/phase-1-5/reports/report-verifier-v2.md")

## 위험

- **L-1**: STAGE A 본질 항목 검증 시 LLM 자체 판단 필요 (예: TOC 링크 매핑 합리성) — 보고서에 사유 명시 필수
- **L-2**: 원본 보존 분량 측정 — wc 또는 줄 수 기준. 80% 기준은 정량적이라 명확
- **L-3**: anchor 정규화 검증 시 한글 헤더 — 옵시디언 실제 동작 차이 가능 → 보고서에 차이 사유 명시
- **L-4**: cross-model 강제 — verifier 모델이 sonnet이면 즉시 중단, opus 재할당
