---
title: "PAB-SSOT-Nexus — 프로젝트 개요"
description: "PAB 생태계의 SSOT(Single Source of Truth) 본체 — 워크플로우·역할·게이트·skill 규칙의 단일 공급원"
created: 2026-05-04 22:39
updated: 2026-05-04 22:39
type: "[[PROJECT]]"
index: "[[KNOWLEDGE_MGMT]]"
topics: ["[[PAB_ECOSYSTEM]]", "[[SSOT]]", "[[WORKFLOW]]", "[[GOVERNANCE]]"]
tags: ["project", "pab-ssot-nexus", "ssot"]
keywords: ["ssot", "workflow", "phase", "gate", "role", "skill", "version"]
sources: ["~/WORKS/PAB-SSOT-Nexus"]
aliases: ["PAB-SSOT-Nexus", "SSOT-Nexus", "Nexus", "SSOT 본체"]
---

# PAB-SSOT-Nexus

## 시스템 목적 및 역할
PAB 생태계 전체에서 사용하는 **SSOT(Single Source of Truth) 본체 저장소**. Phase 워크플로우·게이트(G0~G4)·역할(Team Lead/backend-dev/verifier 등)·skill 규칙·하드룰(HR-1~HR-8)의 정의를 한 곳에 두고, 다른 PAB 프로젝트(Conductor·Khala·obsidian 등)가 이 SSOT를 참조하여 일관된 방식으로 개발·운영된다. 버전 관리(`ver5-0`/`ver5-1`/`ver6-0`)로 SSOT 자체의 진화 이력 보존.

## 위치
`~/WORKS/PAB-SSOT-Nexus`

## 구조 요약
- `pab-ssot/` — SSOT 본체 (현행 버전 작업 공간)
- `ver5-0/`, `ver5-1/`, `ver6-0/` — 과거·현행 버전 스냅샷
- `dist/` — 배포용 빌드 결과
- `docs/`
  - `overview/`, `phases/`, `analysis/`, `handoff/`, `data/`, `poc/`, `refactoring/`
  - `PAB_v1.0_KPI.md` — KPI 정의
  - `plan-device-version-tracking.md` — 디바이스 버전 추적 계획
  - `skillsmp-search/` — skill 검색 관련
- `scripts/` — 빌드·검증·배포 자동화
- `skills/` — 표준 skill 정의 (다른 PAB가 import)
- `wiki/` — 자체 wiki 영역

## 핵심 기능
1. **SSOT 정의 관리**: Phase 워크플로우, G0~G4 게이트, 역할, HR-1~HR-8 하드룰
2. **버전 스냅샷**: ver5-0/5-1/6-0 등으로 SSOT 자체의 진화 보존
3. **표준 skill 공급**: `skills/` 디렉토리를 다른 PAB 프로젝트가 참조
4. **배포**: `dist/`로 빌드 → 다른 PAB 프로젝트에 적용

## 연동 현황

### 흐름 도식
```
[PAB-SSOT-Nexus]
    │ ① SSOT 정의 (workflow·gate·role·skill·rule)
    │ ② 버전 빌드 (dist/)
    ▼
[다른 PAB 프로젝트들 — Conductor · Khala · obsidian · ...]
    ├─ ③ SSOT 참조 (CLAUDE.md → ../PAB-SSOT-Nexus/...)
    ├─ ④ Phase 산출물 작성 (status/plan/todo-list/tasks)
    └─ ⑤ G0~G4 게이트 검증
        │
        ▼
[Team Lead + 팀원 (backend-dev · verifier · ...)]
    ⑥ SSOT 규칙 따라 작업·검증·완료 보고
```

### 절차 상세
1. **SSOT 정의·갱신** (Nexus 내부)
   - 1-1. 워크플로우/게이트/역할 변경 사항을 `pab-ssot/` 또는 새 버전(`verN-M/`)에 작성
   - 1-2. 버전 번호 업데이트 (예: 6.0 → 6.1)
2. **배포** (Nexus → 다른 PAB)
   - 2-1. `dist/` 빌드
   - 2-2. 다른 PAB 프로젝트의 `SSOT/` 또는 `CLAUDE.md`가 참조
3. **다른 PAB의 SSOT 적용**
   - 3-1. 프로젝트별 CLAUDE.md에 SSOT 진입점·버전 명시
   - 3-2. Phase 진입 시 SSOT 0-entrypoint.md 읽기 (FRESH-1 절차)
   - 3-3. 산출물 작성·게이트 검증·완료 알림 모두 SSOT 규칙 준수
4. **예외 등록** (프로젝트 단위)
   - 4-1. 특정 프로젝트가 SSOT 규칙 일부를 비적용하려면 `phase-X-exceptions.md`로 예외 등록
   - 4-2. SSOT 본체는 무수정 — 예외만 프로젝트 측에서 관리

## 다른 PAB 프로젝트와의 관계
- [[PAB_project_overview|PAB 생태계 MOC]] — 진입점
- [[2026-05-04_pab_conductor_overview|PAB-Conductor]] — SSOT Phase 워크플로우 적용 (docs/phases/ 다수)
- [[2026-05-04_pab_khala_overview|PAB-Khala]] — SSOT Phase 워크플로우 적용 (Phase 0~5)
- **PAB-obsidian** — SSOT 워크플로우만 빌려쓰되 코드 게이트는 phase-1-exceptions.md(E-1~E-5)로 비적용
- [[2026-05-04_pab_observer_overview|PAB-Observer]] — 향후 SSOT 적용 예정 (현재 초기 단계)

## 구현 정보
- 본체이므로 **상위 의존이 없음** — 다른 PAB가 모두 이쪽을 참조
- 버전 디렉토리 분리 정책 — 과거 버전을 지우지 않고 보존 (ver5-0/5-1/6-0)
- 자체 wiki 영역 보유 (`wiki/`) — PAB-obsidian의 PAB-LLMDATA vault와는 별개

## 참고
- `/PAB-SSOT-Nexus/pab-ssot/` — 현행 SSOT 본체
- `/PAB-SSOT-Nexus/ver6-0/` — 최신 버전 스냅샷
- `/PAB-SSOT-Nexus/docs/PAB_v1.0_KPI.md` — KPI 정의
- `/PAB-SSOT-Nexus/skills/` — 표준 skill 정의
- `/PAB-SSOT-Nexus/dist/` — 배포 빌드
