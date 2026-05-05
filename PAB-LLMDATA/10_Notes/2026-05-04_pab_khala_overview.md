---
title: "PAB-Khala — 프로젝트 개요"
description: "3800X(RTX 3090) 위에서 멀티모델 앙상블의 품질·시간·안정성을 검증하는 합의 레이어"
created: 2026-05-04 22:39
updated: 2026-05-04 22:39
type: "[[PROJECT]]"
index: "[[AI]]"
topics: ["[[PAB_ECOSYSTEM]]", "[[ENSEMBLE]]", "[[MULTI_MODEL]]", "[[OLLAMA]]"]
tags: ["project", "pab-khala", "ensemble"]
keywords: ["multi-model", "ensemble", "ollama", "arbiter", "track-a", "track-b", "rtx 3090"]
sources: ["~/WORKS/PAB-Khala", "~/WORKS/PAB-Khala/README.md"]
aliases: ["PAB-Khala", "Khala", "칼라"]
---

# PAB-Khala

## 시스템 목적 및 역할
**Khala**(칼라) — Protoss 정신 연결망 메타포. 다수 LLM 모델의 의식을 하나로 잇는 **합의(consensus) 레이어**. 3800X 서버(RTX 3090 24GB) 위에서 멀티모델 앙상블의 **품질·시간·안정성을 정량 검증**하고, 두 운영 방식(Track A 대형 순차 vs Track B 소형 동시) 중 하나를 채택해 [[2026-05-04_pab_conductor_overview|PAB-Conductor]]에 외부 서비스로 통합한다.

## 위치
`~/WORKS/PAB-Khala`

운영 환경: 3800X 서버 (Tailscale `100.109.251.86`), 작업 디렉토리 `~/pab-khala/`, 의존 서비스 Ollama (`localhost:11434`)

## 구조 요약
- `config/` — `ensemble_config.yaml`(Track A/B 모델 풀), `test_cases.yaml`(20케이스), `rubric.yaml`(채점 루브릭)
- `scripts/`
  - `00_setup.sh`, `01_download_models.sh` (~50GB 7종), `02_load_benchmark.py`
  - `lib/db.py`(SQLite), `lib/ollama_client.py`(트랙별 keep_alive)
  - `phase1/`(베이스라인) · `phase2a/`(Track A) · `phase2b/`(Track B) · `phase3/arbiter.py` · `phase4/compare.py`
  - `phase4/api.py` — Phase 5 FastAPI
  - `setup/install_ollama_dropin.sh`, `sync-back.sh`
- `data/khala.db` — SQLite (실험 결과)
- `docs/plan/` — v2 현행 계획서, `docs/SSOT/` (PAB SSOT 외부 참조)
- `reports/` — 분석 리포트

## 핵심 기능
1. **Track A**: 대형 모델 순차 호출 — 단일 강한 모델 + 검토 모델
2. **Track B**: 소형 모델 동시 호출 — 다수 약한 모델 합의 + Arbiter
3. **Arbiter**: 양 트랙 모두 적용 — 후보 응답 평가 + 최종 채택
4. **벤치마크**: 20 케이스 × 트랙 × 모델 → 품질(rubric)·시간·안정성 측정
5. **REST API** (Phase 5): 채택된 트랙을 FastAPI로 외부 노출

## Phase 일정
```
Phase 0  환경 준비 (공통)               0.5일
Phase 1  단일 모델 베이스라인 2종         1일
Phase 2A Track A 대형 순차 앙상블         1일
Phase 2B Track B 소형 동시 앙상블         1일
Phase 3  Arbiter 통합 (양 트랙)          1일
Phase 4  ⭐ Track A vs B 직접 비교       0.5일
Phase 5  Conductor REST API (채택 트랙)   1일
```

## 연동 현황

### 흐름 도식
```
[Conductor (3800X)]
    │ ① 개발 스테이지 작업 — 앙상블 호출 요청
    ▼
[Khala REST API (FastAPI, Phase 5)]
    │ ② 트랙 선택 (채택된 A 또는 B)
    ▼
[Ollama (localhost:11434)]
    ├─ Track A: 대형 모델 순차 호출
    └─ Track B: 소형 모델 동시 호출
        │
        ▼
[Arbiter — 후보 응답 평가]
    │ ③ 최종 응답 결정
    ▼
[Conductor — 결과 수신 + 이력 기록]
```

### 절차 상세
1. **요청 수신** (Conductor → Khala)
   - 1-1. Conductor 19스테이지 중 개발 스테이지가 앙상블 호출 필요로 판단
   - 1-2. Khala REST API 엔드포인트로 프롬프트 전달
2. **모델 호출** (Khala → Ollama)
   - 2-1. 채택된 트랙에 따라 대형 순차 또는 소형 동시 분기
   - 2-2. Ollama keep_alive 정책으로 모델 로드 시간 최소화
3. **합의 형성** (Khala 내부)
   - 3-1. 후보 응답들을 Arbiter가 평가
   - 3-2. 단일 최종 응답 결정
4. **응답 회신** (Khala → Conductor)
   - 4-1. 최종 응답 + 메타데이터(트랙·모델·시간·품질 점수)
   - 4-2. SQLite(`khala.db`)에 실험 이력 기록

## 다른 PAB 프로젝트와의 관계
- [[PAB_project_overview|PAB 생태계 MOC]] — 진입점
- [[2026-05-04_pab_conductor_overview|PAB-Conductor]] — Khala를 개발 스테이지 외부 앙상블 서비스로 호출 (Phase 5에서 통합)
- [[2026-05-04_pab_ssot_nexus_overview|PAB-SSOT-Nexus]] — Khala 자체도 SSOT Phase 워크플로우 따름

## 구현 정보
- 현행 계획서: v2 (`docs/plan/20260504-khala_v2.md`)
- 코드 구조: scripts/ 위주의 Phase 단위 단순 구조 (full-stack 아님)
- 운영 위치: 3800X 원격 서버 (MacBook → rsync로 결과 회수)
- 모델 다운로드: ~50GB, 1~2시간 소요 (1회성)
- 결과 저장: SQLite (`data/khala.db`, journal/wal/shm은 gitignore)

## 참고
- `/PAB-Khala/README.md` — 본 노트의 1차 출처
- `/PAB-Khala/docs/plan/20260504-khala_v2.md` — 현행 계획서
- `/PAB-Khala/docs/plan/20260425-khala_handoff.md` — 인계 정리본
- `/PAB-Khala/config/ensemble_config.yaml` — Track A/B 모델 풀 정의
- `/PAB-Khala/config/rubric.yaml` — 채점 루브릭 (Phase 1 시작 후 변경 금지)
