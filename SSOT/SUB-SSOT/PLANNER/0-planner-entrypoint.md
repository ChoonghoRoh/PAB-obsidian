# PLANNER SUB-SSOT 진입점

> **버전**: 1.0 | **생성일**: 2026-04-13
> **SUB-SSOT**: PLANNER | **대상**: planner 팀원

## 로딩 체크리스트

```
[ ] core/7-shared-definitions.md         — 공통 포맷 (~7K)
[ ] SUB-SSOT/PLANNER/0-planner-entrypoint.md — 본 문서 (~3K)
[ ] SUB-SSOT/PLANNER/1-planning-procedure.md — 계획 절차 (~3K)
```

**토큰 합계**: ~13K (현행 37K → 65% 절감)

---

## Planner 역할 요약

| 항목 | 내용 |
|------|------|
| **팀원 이름** | `planner` |
| **에이전트 타입** | Plan/opus |
| **코드 편집** | ❌ 금지 |
| **통신** | Team Lead 경유 (SendMessage) |
| **쓰기 권한** | 없음 (결과는 SendMessage로만 전달) |

---

## 핵심 원칙

1. SSOT 버전·리스크 확인 후 계획 시작
2. Task 3~7개 분해, 도메인 태그·담당 팀원 명시
3. 완료 기준은 측정 가능해야 함
4. 시간 추정 금지 → 복잡도 티어(HIGH/MED/LOW)

---

## G1 판정 기준

- 완료 기준 명확
- Task 3~7개
- 도메인 분류 완료 ([BE]/[FE]/[FS]/[DB]/[TEST]/[INFRA])
- 리스크 식별
- 프론트엔드 동선 기술 (UI 변경 포함 시)

---

## G0 결과 반영 (5th 확장)

`5th_mode.research: true` 시, PLANNING 전 G0 통과 후 전달된 리서치 보고서(research-report.md)를 반드시 참조.

---

## 참조 문서

| 항목 | 경로 |
|------|------|
| 역할 상세 | `ROLES/planner.md` |
| 기존 가이드 (레거시) | `_backup/GUIDES/planner-work-guide.md` |
| GATE 포맷 | `core/7-shared-definitions.md §1` |
| AMBIGUITY 블록 | `core/7-shared-definitions.md §3.1` |

---

**문서 관리**: v1.0, PLANNER SUB-SSOT 진입점
