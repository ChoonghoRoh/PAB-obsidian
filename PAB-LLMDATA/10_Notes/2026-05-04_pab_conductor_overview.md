---
title: "PAB-Conductor — 프로젝트 개요"
description: "여러 머신·여러 프로젝트의 LLM 작업을 등록·분배·추적하는 큐 매니저"
created: 2026-05-04 22:39
updated: 2026-05-04 22:39
type: "[[PROJECT]]"
index: "[[PRODUCT]]"
topics: ["[[PAB_ECOSYSTEM]]", "[[TASK_QUEUE]]", "[[LLM_ORCHESTRATION]]"]
tags: ["project", "pab-conductor", "orchestration"]
keywords: ["task queue", "worker", "heartbeat", "llm dispatch", "claude code"]
sources: ["~/WORKS/PAB-Conductor", "~/WORKS/PAB-Conductor/docs/overview/README.md"]
aliases: ["PAB-Conductor", "Conductor"]
---

# PAB-Conductor

## 시스템 목적 및 역할
LLM 작업의 **큐 매니저 + 분배기 + 실행 이력 추적기**. 개발자가 여러 프로젝트를 여러 머신에서 LLM(Claude Code)으로 돌릴 때, "누가 무엇을 언제 어디서 실행했는가"를 중앙에서 관리한다. Conductor 서버(3800X)가 작업 큐를 들고, macbook·thinkbook 등 워커 머신이 각자 할당받은 프로젝트 폴더에서 LLM을 호출.

## 위치
`~/WORKS/PAB-Conductor`

## 구조 요약
- `src/` — Conductor 본체 (작업 큐·머신 관리·프로젝트 할당·이력)
- `pab-conductor-agent/` — 워커 머신에서 도는 에이전트
- `web/` — 관리 UI
- `schema/` — 데이터/API 스키마
- `docker-compose.yml`, `Dockerfile`, `deploy/` — 배포 인프라
- `tests/`, `pytest.ini` — 테스트
- `docs/overview/`, `docs/phases/`, `docs/plans/` — 설계·운영 문서 다수
- `config/`, `scripts/`, `logs/`, `output/`

## 핵심 기능 (docs/overview/README.md 기준 2026-04-18)
1. **작업 큐**: 지시 등록 → 우선순위 정렬 → 머신 배분 → 실행 → 결과 수신 → 기록
2. **머신 관리**: 등록·heartbeat 상태 감시·enrollment 토큰 인증·버전 추적
3. **프로젝트 관리**: 1 프로젝트 = 1 머신 할당, 경로·연결 4단계 검증
4. **실행 이력**: 작업 단위 기록·통계·추적

## 연동 현황

### 흐름 도식
```
[사용자]
    │ ① 작업 지시 (프로젝트·우선순위·역할 지정)
    ▼
[Conductor 서버 (3800X)]
    ├─ ② 작업 큐 적재 + 우선순위 정렬
    ├─ ③ 머신 상태 확인 (heartbeat)
    └─ ④ 할당 워커에 작업 전달
        │
        ▼
[워커 에이전트 (macbook · thinkbook · ...)]
    │ ⑤ 프로젝트 폴더에서 Claude Code 호출
    │ ⑥ 결과 회신
    ▼
[Conductor — 실행 이력 기록]
    ⑦ 통계·추적·후속 작업 분기
```

### 절차 상세
1. **작업 지시 등록** (사용자 → Conductor)
   - 1-1. 사용자가 CLI 또는 web UI로 작업 등록
   - 1-2. 프로젝트·우선순위·역할(executor) 지정
2. **큐 관리** (Conductor 내부)
   - 2-1. 우선순위 기반 정렬
   - 2-2. 머신 오프라인 시 blocked 상태 보류
3. **머신 분배** (Conductor → 워커)
   - 3-1. heartbeat로 워커 가용 여부 확인
   - 3-2. 프로젝트에 할당된 워커에 작업 전달
4. **실행** (워커 머신)
   - 4-1. 워커 에이전트가 지정 프로젝트 폴더로 이동
   - 4-2. Claude Code 호출 → 결과 생성
   - 4-3. 결과를 Conductor로 회신
5. **이력 기록** (Conductor)
   - 5-1. 작업 단위 기록 (시작/종료 시각, 결과, 오류)
   - 5-2. 통계 집계 + 후속 작업 분기

## 다른 PAB 프로젝트와의 관계
- [[PAB_project_overview|PAB 생태계 MOC]] — 진입점
- [[2026-05-04_pab_ssot_nexus_overview|PAB-SSOT-Nexus]] — Conductor 자체가 SSOT 워크플로우를 따라 개발 (docs/phases/ 구조 적용)
- [[2026-05-04_pab_khala_overview|PAB-Khala]] — Conductor 19스테이지 워크플로우 중 **개발 스테이지에서 호출하는 외부 앙상블 서비스**로 통합 예정
- [[2026-05-04_pab_observer_overview|PAB-Observer]] — Conductor 실행 이력의 관측 대상 가능성 (추정 — 확인 필요)

## 구현 정보
- 구조상 full-stack (server + agent + web + docker)으로 가장 성숙한 PAB 프로젝트
- docs/phases/ 다수 존재 → 자체 SSOT Phase 워크플로우 적용 중
- 최근 문서 갱신: 2026-04-18 (overview/README.md)

## 참고
- `/PAB-Conductor/docs/overview/README.md` — 본 노트의 1차 출처
- `/PAB-Conductor/docs/overview/conductor-worker-roles.md` — Conductor↔Worker 역할 분담
- `/PAB-Conductor/docs/overview/target-agent-architecture.md` — 목표 에이전트 아키텍처
- `/PAB-Conductor/docs/overview/phase25-api-specification.md` — API 명세
