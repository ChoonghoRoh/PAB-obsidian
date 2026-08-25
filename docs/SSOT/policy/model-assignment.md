---
title: "Model Assignment Policy"
version: "v1.0"
created: "2026-05-01"
applies_to: "SSOT v8.2-renewal-6th 이상"
ssot_anchor: "0-entrypoint §3.9 팀 라이프사이클"
---

# 모델 할당 정책 (Model Assignment Policy)

> Claude Code Agent Teams 운영에서 각 역할이 사용하는 LLM 모델 할당 규칙의 **단일 진실 공급원**(SSOT).
> 모델은 향후 다른 LLM(GPT, Gemini 등)으로 변경될 수 있으며, 변경 시 **본 문서만 갱신**하면 된다.
> 본 문서를 갱신한 후 [0-entrypoint §3.9](../0-entrypoint.md#39-팀-라이프사이클-루프-가능)와 [VERSION.md](../VERSION.md)를 동기화한다.

---

## §1 정책 개요

### 1.1 기본 모델 (Default)

별도 지정이 없는 모든 역할에 적용되는 기본값.

- **모델**: `sonnet (latest)`
- **현재 ID**: `claude-sonnet-4-6` (Sonnet 4.6)

### 1.2 Strategic Tier — opus 사용 역할

다음 역할은 **`opus (latest)`**를 사용한다. 사유: 전략적 판단, 다관점 통합, 품질 게이트 판정이 핵심 책무다.

| 역할 | 사용 모델 | 사유 |
|---|---|---|
| **team-lead** (Team Leader) | `opus (latest)` | 팀 조율 · G4 최종 판정 · SSOT 일관성 관리 · Hub-and-Spoke 통신 허브 |
| **planner** (Planner) | `opus (latest)` | Master Plan 설계 · Task 3~7개 분해 · 리스크 분석 · G1 게이트 산출 |
| **verifier** (Verifier) | `opus (latest)` | G2 코드 게이트 판정 · Critical/High/Low 등급 결정 · plan-first review |
| **research-lead** (Research Lead) | `opus (latest)` | Research Team 총괄 · G0 게이트 산출물 품질 · 다관점 통합 |
| **research-architect** (Research Architect) | `opus (latest)` | 아키텍처 대안 탐색 · 기술 스택 비교 분석 · PoC 설계 |
| **research-analyst** (Research Analyst) | `opus (latest)` | 코드베이스 분석 · 의존성 영향 조사 · 데이터 수집·정리 |

### 1.3 Implementation Tier — sonnet 사용 역할 (기본값)

다음 역할은 **`sonnet (latest)`**를 사용한다. 사유: 명시적 spec을 따라 코드/테스트를 산출하는 구현·실행 중심 책무다.

| 역할 | 사용 모델 | 비고 |
|---|---|---|
| **backend-dev** | `sonnet (latest)` | 대규모 리팩토링·복잡 업무 시 opus 일시 승격 가능 (Team Lead 판단) |
| **frontend-dev** | `sonnet (latest)` | 동일 |
| **tester** | `sonnet (latest)` | pytest 실행 · E2E · 커버리지 검증 |

### 1.4 향후 추가 역할

신규 역할 추가 시 본 문서의 §1.2 또는 §1.3 표에 한 줄 추가하고 사유를 기재한다. 분류 기준:

- **판정·전략·다관점 통합** → §1.2 (opus)
- **명시적 spec 기반 산출·실행** → §1.3 (sonnet)

---

## §2 모델 ID 매핑 (현재)

| Tier alias | 현재 모델 ID | 모델명 |
|---|---|---|
| `opus (latest)` | `claude-opus-4-7` | Opus 4.7 (1M context) |
| `sonnet (latest)` | `claude-sonnet-4-6` | Sonnet 4.6 |
| `haiku (latest)` | `claude-haiku-4-5-20251001` | Haiku 4.5 (필요 시 Light tier 추가용) |

> Tier alias는 변하지 않는다. 모델 ID만 신모델 출시 시 갱신한다.

---

## §3 향후 LLM 변경 대비

본 정책의 `opus` / `sonnet` 명칭은 다음 의미의 alias다:

- `opus` ≡ **Strategic Tier**: 판단·통합·게이트
- `sonnet` ≡ **Implementation Tier**: 구현·실행

향후 GPT, Gemini 등 다른 LLM 계열로 변경 시:

1. §1.2 / 1.3의 **Tier 매핑은 그대로 유지**
2. §2의 **모델 ID만 신규 ID로 갱신**
3. 역할별 Tier 분류는 책무 기준이므로 **변경 없음**

**예시 — opus → `gpt-5-pro`, sonnet → `gpt-5-mini`로 변경 시**:

| Tier alias | 변경 전 | 변경 후 |
|---|---|---|
| Strategic | `claude-opus-4-7` | `gpt-5-pro` |
| Implementation | `claude-sonnet-4-6` | `gpt-5-mini` |

→ §2만 수정하고 §1.2 / 1.3 표는 그대로 둔다.

---

## §4 변경 절차 (LOCK-2 준수)

본 정책 변경 시 다음 순서를 따른다:

1. **BLOCKED 전이** — 진행 중 Phase의 `current_state`를 `BLOCKED` (사유: "model-assignment 정책 변경")
2. **본 문서 갱신** — §1.2 / §1.3 / §2 중 해당 항목 수정
3. **0-entrypoint 동기화** — `0-entrypoint.md §3.9` 팀 라이프사이클 트리의 모델 표기 갱신
4. **VERSION.md 이력 기록** — 변경 이력 섹션에 사유 + 영향 범위 기재 (LOCK-5)
5. **SendMessage 리로드 지시** — 모든 활성 팀원에게 SSOT 리로드 지시 (LOCK-3)
6. **이전 상태 복귀** — Phase `current_state`를 변경 전 값으로 복귀

---

## §5 규칙 (MODEL 카테고리)

| ID | 규칙 | 심각도 | 적용 |
|---|---|---|---|
| **MODEL-1** | 역할별 Tier 매핑 준수 | CRITICAL | Team Lead는 팀원 스폰 시 §1.2 / §1.3 표를 그대로 따른다. 임의 변경 금지. |
| **MODEL-2** | 변경 시 BLOCKED 전이 | HIGH | 본 문서 갱신은 §4 절차 준수. Phase 실행 중 직접 수정 금지 (LOCK-2). |
| **MODEL-3** | Tier alias 우선 | MEDIUM | 문서·로그·보고서에 모델 ID 대신 Tier alias(opus/sonnet) 사용 권장. 모델 ID 변경에 대한 결합도 감소. |
| **MODEL-4** | 일시 승격 기록 | MEDIUM | backend-dev/frontend-dev를 일시적으로 opus로 승격 시 task spec의 `model_override` 필드에 사유 기재. |

---

## §6 변경 이력

| 일자 | 버전 | 변경 내용 | 사유 |
|---|---|---|---|
| 2026-05-01 | v1.0 | 초기 작성. team-lead/planner/verifier/research-{lead,architect,analyst} 6역할 opus, 나머지 sonnet 기본 | 사용자 지정 정책 명시 |

---

## §7 참조

- [SSOT/0-entrypoint.md §3.9 팀 라이프사이클](../0-entrypoint.md#39-팀-라이프사이클-루프-가능) — 팀 트리 모델 표기 동기화 위치
- [SSOT/VERSION.md](../VERSION.md) — SSOT 버전 관리·변경 이력
- [SSOT/core/6-rules-index.md](../core/6-rules-index.md) — 규칙 통합 인덱스 (MODEL 카테고리 신설)
- [SSOT/3-workflow.md AGENT-LIFECYCLE](../3-workflow.md) — 팀원 스폰 시 모델 지정 절차
