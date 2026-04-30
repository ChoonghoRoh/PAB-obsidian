# RESEARCH SUB-SSOT 진입점

> **버전**: 1.0 | **생성일**: 2026-04-15 (Phase-E task-E-1-2)
> **SUB-SSOT**: RESEARCH | **대상**: Research Team 3역할 공용
> **해결 이슈**: #17 — 기존에는 3역할이 단일 `_backup/GUIDES/research-work-guide.md`에 의존하여 독립 주입·차별화 불가. 본 SUB-SSOT 도입으로 역할별 SUB-SSOT 구조와 정합성 달성.

## 개요

RESEARCH SUB-SSOT는 **기술 조사(Research Phase)를 수행하는 3역할 — research-lead, research-architect, research-analyst — 공용 레이어**이다. 공통 레이어(`core/7-shared-definitions.md`)와 역할별 procedure와 함께 로딩하면 SSOT 코어 전체 없이도 완전한 리서치 작업이 가능하다. Read-only 전용 역할이며, 모든 산출물은 SendMessage로 Team Lead에게 전달한다.

## Research Phase 진입 조건 (Phase-F 이관)

### 활성화 조건

- `status.md`의 `5th_mode.research: true` 설정 시 활성화
- Team Lead가 **RESEARCH 상태 전이**를 선언한 경우

### 진입 상황

- Team Lead가 현재 Phase에 대해 **기술 조사가 필요**하다고 판단한 경우
- Phase 도메인·기술 선택이 불확실하여 **사전 리서치가 필요**한 경우
- 기존 아키텍처에 대한 **영향도 분석**이 필요한 경우

### Research Team 구성

| 역할 | 인원 | 책임 |
|------|------|------|
| research-lead | 1명 | 리서치 범위 정의 + 팀 조율 |
| research-architect | 1명 | 아키텍처 영향도 분석 |
| research-analyst | 1명 | 대안 비교·벤치마크 |

---

## §1 로딩 체크리스트

### 1.1 필수 로딩 (모든 Research 역할)

```
[ ] core/7-shared-definitions.md         — 공통 포맷 (~7K)
[ ] SUB-SSOT/RESEARCH/0-research-entrypoint.md — 본 문서 (~3K)
[ ] SUB-SSOT/RESEARCH/{역할}-procedure.md     — 해당 역할 procedure (~4K)
```

### 1.2 요청 유형별 로딩 집합

| 역할 | 로딩 집합 | 토큰 추정 |
|------|-----------|-----------|
| **Research Lead** | 7-shared + entrypoint + `1-lead-procedure.md` | ~14K |
| **Research Architect** | 7-shared + entrypoint + `2-architect-procedure.md` | ~14K |
| **Research Analyst** | 7-shared + entrypoint + `3-analyst-procedure.md` | ~14K |

→ 현행 GUIDES 단일 공유 운영(~30K) 대비 **~53% 절감**.

### 1.3 선택적 로딩 (공통)

```
[ ] TEMPLATES/research-report-template.md — research-report.md 작성 시
[ ] TEMPLATES/ab-comparison-template.md   — Architect PoC/비교 시
[ ] 2-architecture.md                     — Architect 영향도 분석 시 필수
[ ] 1-project.md (§Research Team)         — Lead 범위 재정의 시
```

---

## §2 역할 매핑 (3역할 × Agent)

| 절차 역할 | 팀원 이름 | Agent 타입 | 모델 | 핵심 책임 |
|-----------|-----------|------------|------|-----------|
| **research-lead** | `research-lead` | Explore | opus | 리서치 범위 정의, 팀 조율, 결과 통합, research-report.md 작성 |
| **research-architect** | `research-architect` | Explore | opus | 아키텍처 대안 탐색, 영향도 분석, PoC 설계, 호환성 검토 |
| **research-analyst** | `research-analyst` | Explore | sonnet | 대안 비교, 벤치마크 수집, 리스크 정량화, WebSearch/WebFetch 활용 |

| ROLES | PERSONA (교체 가능) |
|-------|---------------------|
| `ROLES/research-lead.md` | `PERSONA/RESEARCH_LEAD.md` |
| `ROLES/research-architect.md` | `PERSONA/RESEARCH_ARCHITECT.md` |
| `ROLES/research-analyst.md` | `PERSONA/RESEARCH_ANALYST.md` |

---

## §3 Hub-and-Spoke 통신 모델

```
Team Lead ←──→ research-lead ←──→ research-architect
                              ←──→ research-analyst
```

### 3.1 규칙

- 모든 팀원은 **SendMessage**로만 통신 (파일 공유·직접 호출 금지).
- Research 팀 **내부 통신은 research-lead 경유**.
- research-architect ↔ research-analyst **직접 통신 금지**.
- 최종 보고는 research-lead가 Team Lead에게 SendMessage.

---

## §4 G0 Research Review 게이트 절차

### 4.1 필수 통과 조건

- [ ] **기술 조사 완료** — 조사 범위 내 모든 항목에 대한 분석 완료
- [ ] **아키텍처 대안 2개 이상** 제시
- [ ] **리스크 분석 포함** — 식별 + 완화 방안 수립

### 4.2 선택 통과 조건

- [ ] **PoC 결과 첨부** — 성능 비교·호환성 검증 필요 시

### 4.3 판정 결과

| 결과 | 후속 행동 |
|------|----------|
| **PASS** | PLANNING 상태 전이 → research-report.md를 planner에게 전달 |
| **FAIL** | 보완 범위 지정 + RESEARCH 재수행 |

**참조**: `3-workflow.md §4.3 G0 Research Review 상세` (운영 SSOT 정의 — 본 SUB-SSOT는 절차 요약만 보유).

---

## §5 산출물 디렉토리

### 5.1 필수 산출물

| 산출물 | 파일명 | 경로 | 작성 주체 |
|--------|--------|------|-----------|
| 리서치 보고서 | `research-report.md` | `docs/phases/phase-X-Y/` | research-lead (통합) |
| 기술 비교 매트릭스 | (보고서 §2) | 동 | research-analyst 기여 |
| 리스크 분석서 | (보고서 §5) | 동 | research-analyst 기여 |
| 영향도 분석서 | (보고서 §3) | 동 | research-architect 기여 |

### 5.2 선택적 산출물

| 산출물 | 파일명 | 조건 |
|--------|--------|------|
| 벤치마크 데이터 | `benchmark-data.md` | 성능 비교 수행 시 |
| 영향도 상세 분석 | `impact-analysis.md` | 대규모 아키텍처 변경 시 |
| PoC 코드·결과 | `poc-result.md` | PoC 수행 시 |

보고서 형식: `TEMPLATES/research-report-template.md` 준수.

---

## §6 권한·제약

### 6.1 권한 제약

- **모든 Research 팀원 Read-only**
- Edit/Write 도구 사용 금지
- Git 커밋 금지
- 파일 생성은 research-report.md 및 선택적 산출물에 한정 (실제 생성 주체 — Team Lead로 SendMessage → Team Lead가 저장)

### 6.2 시간 제약 — 15분 SLA

- 리서치 타임박스 15분. 초과 시 Watchdog 에스컬레이션.
- 초과 대응: 중간 보고 작성 → Team Lead가 시간 부여 또는 범위 축소 결정.

### 6.3 범위 제약

- Phase 범위 벗어난 조사 금지.
- 기술 선택지는 프로젝트 기술 스택과 호환 가능한 것만 포함.
- 실험적·미성숙 기술은 리스크 명시 후 대안으로만 제시.

---

## §7 참조 문서

| 항목 | 경로 |
|------|------|
| 역할 상세 (3종) | `ROLES/research-lead.md`, `research-architect.md`, `research-analyst.md` |
| 페르소나 (3종, 교체 가능) | `PERSONA/RESEARCH_LEAD.md`, `RESEARCH_ARCHITECT.md`, `RESEARCH_ANALYST.md` |
| 기존 가이드 (5th, 호환) | `_backup/GUIDES/research-work-guide.md` — 본 SUB-SSOT의 원본·상위 호환 |
| G0 정의 | `3-workflow.md §4.3` |
| 보고서 템플릿 | `TEMPLATES/research-report-template.md` |
| 공통 정의 | `core/7-shared-definitions.md` |
| SSOT 진입점 | `0-entrypoint.md §7.5` |
| SUB-SSOT 인덱스 | `SUB-SSOT/0-sub-ssot-index.md` |

---

**문서 관리**: v1.0, 2026-04-15, RESEARCH SUB-SSOT 진입점 (3역할 공용 레이어)
