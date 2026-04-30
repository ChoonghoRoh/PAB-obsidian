# TEAM-LEAD SUB-SSOT 진입점

> **버전**: 1.0 | **생성일**: 2026-04-13
> **SUB-SSOT**: TEAM-LEAD | **대상**: 메인 세션 (Team Lead)

## 로딩 체크리스트

```
[ ] core/7-shared-definitions.md                — 공통 포맷 (~7K)
[ ] SUB-SSOT/TEAM-LEAD/0-lead-entrypoint.md    — 본 문서 (~4K)
[ ] SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md — 오케스트레이션 (~4K)
[ ] SUB-SSOT/0-sub-ssot-index.md               — 라우팅 테이블 (~3K)
```

**참고**: Team Lead는 SSOT 코어(0~5)도 함께 로딩. SUB-SSOT는 팀원 라우팅용 추가 참조.

---

## Team Lead 역할 요약

| 항목 | 내용 |
|------|------|
| **실행 위치** | 메인 세션 |
| **Charter** | `PERSONA/LEADER.md` |
| **코드 편집** | ❌ 절대 금지 (HR-1) |
| **핵심 역할** | 조율·판정·라우팅 |

---

## SUB-SSOT 라우팅 판단

Team Lead는 팀원 스폰 시 해당 역할의 SUB-SSOT를 로딩 지시한다.

| 작업 유형 | 라우팅 | 팀원 로딩 지시 |
|-----------|--------|---------------|
| fn 개발 요청 | DEV SUB-SSOT | `core/7-shared + SUB-SSOT/DEV/0~1` |
| 계획 수립 | PLANNER SUB-SSOT | `core/7-shared + SUB-SSOT/PLANNER/0~1` |
| 코드 검증 | VERIFIER SUB-SSOT | `core/7-shared + SUB-SSOT/VERIFIER/0~1` |
| 테스트 실행 | TESTER SUB-SSOT | `core/7-shared + SUB-SSOT/TESTER/0~1` |
| 오케스트레이션 | 본 SUB-SSOT | SSOT 코어 + TEAM-LEAD SUB-SSOT |

---

## HR 규칙 요약 (HR-1~HR-8)

| HR | 요약 |
|----|------|
| HR-1 | Team Lead 코드 수정 **절대 금지** → 팀원 위임 |
| HR-2 | Phase 산출물(status/plan/todo/tasks) 4종 **생략 금지** |
| HR-3 | 컨텍스트 복구 시 **SSOT 리로드 필수** |
| HR-4 | Phase 문서 경로 **Glob 확인 후 생성** |
| HR-5 | 500줄→등록, 700줄→리팩토링 편성 |
| HR-6 | Task 도메인-역할 분리 (ASSIGN-1~5) |
| HR-7 | 에이전트 라이프사이클 관리 (LIFECYCLE-1~4) |

---

## 참조 문서

| 항목 | 경로 |
|------|------|
| Charter | `PERSONA/LEADER.md` |
| 규칙 인덱스 | `core/6-rules-index.md` |
| 라우팅 테이블 | `SUB-SSOT/0-sub-ssot-index.md` |

---

**문서 관리**: v1.0, TEAM-LEAD SUB-SSOT 진입점
