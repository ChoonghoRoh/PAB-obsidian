---
title: "PAB 생태계 — 프로젝트 MOC"
description: "PAB-* 프로젝트 5종의 진입점. 각 프로젝트 개요 노트 모음 + 생태계 내 위치 도식"
created: 2026-05-04 22:39
updated: 2026-05-04 22:39
type: "[[REFERENCE]]"
index: "[[KNOWLEDGE_MGMT]]"
topics: ["[[PAB_ECOSYSTEM]]"]
tags: ["reference", "moc", "pab-ecosystem"]
keywords: ["pab", "ecosystem", "moc", "map of content", "index"]
sources: ["~/WORKS/"]
aliases: ["PAB MOC", "PAB 생태계 MOC", "PAB Project Overview"]
---

# PAB 생태계 — 프로젝트 MOC

> PAB-* 프로젝트들의 진입점 노트. 각 프로젝트 1장 wikilink + 생태계 내 위치·관계 정리.
>
> 제외: PAB-obsidian (본 vault 호스트, 자체 메타로 충분), PAB-test (실험 샌드박스)

## 생태계 도식

```
                    ┌──────────────────────────┐
                    │   PAB-SSOT-Nexus         │
                    │   (SSOT 본체 — 워크플로우·게이트·역할)
                    └──────────┬───────────────┘
                               │ 참조
            ┌──────────────────┼──────────────────┐
            ▼                  ▼                  ▼
    ┌───────────────┐  ┌───────────────┐  ┌───────────────┐
    │ PAB-Conductor │  │ PAB-Khala     │  │ PAB-Observer  │
    │ (작업 큐 분배) │  │ (멀티모델 앙상블)│  │ (관측·로깅)   │
    └───────┬───────┘  └───────▲───────┘  └───────▲───────┘
            │                  │                   │
            │ 개발 스테이지에서 호출 (Phase 5)        │
            └──────────────────┘                   │
            │                                       │
            └───────────── 실행 이력 송신 (가설) ────┘

    ┌───────────────┐
    │ PAB-Reader    │  ← 다른 PAB의 docs/를 루트로 등록 가능 (공용 뷰어)
    │ (md 문서 뷰어) │
    └───────────────┘
```

## 프로젝트 노트

| 프로젝트 | 한 줄 정의 | 상태 | 노트 |
|---|---|---|---|
| **PAB-Conductor** | 여러 머신·여러 프로젝트의 LLM 작업 큐 매니저·분배기·이력 추적기 | 가장 성숙 (full-stack) | [[2026-05-04_pab_conductor_overview]] |
| **PAB-Khala** | 멀티모델 앙상블 합의 레이어 (Track A/B 검증 → Conductor 통합) | Phase 0~5 진행 | [[2026-05-04_pab_khala_overview]] |
| **PAB-Observer** | (추정) PAB 생태계 관측·로깅·메트릭 | 아이디어 단계 | [[2026-05-04_pab_observer_overview]] |
| **PAB-Reader** | 다중 루트 마크다운 문서 브라우저 (경량 HTTP 뷰어) | 동작 가능 | [[2026-05-04_pab_reader_overview]] |
| **PAB-SSOT-Nexus** | PAB 전체의 SSOT 본체 (워크플로우·게이트·역할·skill 정의) | 본체, 버전 관리 중 (ver6-0) | [[2026-05-04_pab_ssot_nexus_overview]] |

## 핵심 연결 관계

- **SSOT-Nexus → 모든 PAB**: 워크플로우·게이트·하드룰의 단일 공급원
- **Khala → Conductor**: Phase 5에서 외부 앙상블 REST API로 통합 예정
- **Observer ↔ Conductor·Khala**: 실행 이력·메트릭 관측 (가설, 확인 필요)
- **Reader → 임의 PAB의 docs/**: `config.json`의 `roots`에 등록하면 공용 문서 뷰어로 활용

## 운영 메모

- 본 MOC는 **정적 wikilink 방식**(dataview 미사용). 새 PROJECT 노트가 추가되면 표에 1줄 수동 또는 skill로 추가
- 파일명 규약: `YYYY-MM-DD_pab_<project>_overview.md` (slug에 하이픈 금지로 언더스코어 사용, frontmatter `project:`에 풀네임 `PAB-Conductor` 보존)
- 본 노트(`PAB_project_overview.md`)는 MOC라 날짜 prefix 없음 — 영구 진입점

## 향후 보강 예정

- PAB-Observer 정식 README/계획서 작성 시 노트 갱신
- 각 프로젝트의 deep-dive 노트 (아키텍처·결정 이력·교훈)는 별도로 누적 — 본 MOC는 progressive overview만 유지
