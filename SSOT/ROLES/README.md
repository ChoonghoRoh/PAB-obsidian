# ROLES/ — 통합 역할 정의 (정본)

본 디렉토리는 **PERSONA + ROLES 통합** 버전의 9개 역할 파일을 보관한다. 이전 `project/ROLES/` 는 본 디렉토리로 통합·삭제되었다 (2026-04-14).

## 역할 목록

| 역할 | 파일 | 페르소나 (교체 가능) | SUB-SSOT |
|------|------|---------------------|----------|
| Team Lead | [team-lead.md](team-lead.md) | [PERSONA/LEADER.md](../PERSONA/LEADER.md) | [SUB-SSOT/TEAM-LEAD/](../SUB-SSOT/TEAM-LEAD/) |
| Planner | [planner.md](planner.md) | [PERSONA/PLANNER.md](../PERSONA/PLANNER.md) | [SUB-SSOT/PLANNER/](../SUB-SSOT/PLANNER/) |
| Backend Dev | [backend-dev.md](backend-dev.md) | [PERSONA/BACKEND.md](../PERSONA/BACKEND.md) | [SUB-SSOT/DEV/](../SUB-SSOT/DEV/) |
| Frontend Dev | [frontend-dev.md](frontend-dev.md) | [PERSONA/FRONTEND.md](../PERSONA/FRONTEND.md) | [SUB-SSOT/DEV/](../SUB-SSOT/DEV/) |
| Verifier | [verifier.md](verifier.md) | [PERSONA/QA.md](../PERSONA/QA.md) | [SUB-SSOT/VERIFIER/](../SUB-SSOT/VERIFIER/) — **REVIEWER 역할 수행** (6th SUB-SSOT v1.1 통합) |
| Tester | [tester.md](tester.md) | [PERSONA/QA.md](../PERSONA/QA.md) | [SUB-SSOT/TESTER/](../SUB-SSOT/TESTER/) — **VALIDATOR 역할 수행** (6th SUB-SSOT v1.1 통합) |
| Research Lead | [research-lead.md](research-lead.md) | [PERSONA/RESEARCH_LEAD.md](../PERSONA/RESEARCH_LEAD.md) | [SUB-SSOT/RESEARCH/](../SUB-SSOT/RESEARCH/) (entrypoint + `1-lead-procedure.md`) |
| Research Architect | [research-architect.md](research-architect.md) | [PERSONA/RESEARCH_ARCHITECT.md](../PERSONA/RESEARCH_ARCHITECT.md) | [SUB-SSOT/RESEARCH/](../SUB-SSOT/RESEARCH/) (entrypoint + `2-architect-procedure.md`) |
| Research Analyst | [research-analyst.md](research-analyst.md) | [PERSONA/RESEARCH_ANALYST.md](../PERSONA/RESEARCH_ANALYST.md) | [SUB-SSOT/RESEARCH/](../SUB-SSOT/RESEARCH/) (entrypoint + `3-analyst-procedure.md`) |

## 페르소나 교체 원칙

각 역할의 기본 페르소나(Charter)는 본 파일 내 `## 1. 페르소나 (Charter)` 블록에 포함되어 있으나, **다른 페르소나 유형으로 교체 가능**하다. 교체 시 `PERSONA/{FILE}.md` 를 스폰 컨텍스트에 **덮어써서** 주입한다.
