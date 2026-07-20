---
title: "PAB-Khala Phase 6 페르소나 검증 — arbiter 적대 리뷰"
description: "동시성·보안·적대QA 3 페르소나가 게이트웨이 arbiter 초안을 적대 검증 — Blocker 2건 입증"
created: 2026-06-30 07:58
updated: 2026-06-30 07:58
type: "[[LESSON]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[API_GATEWAY]]"]
tags: ["lesson", "khala", "phase6", "persona-review", "adversarial", "concurrency"]
keywords: ["khala", "페르소나검증", "적대리뷰", "동시성", "보안", "blocker", "arbiter", "swap실패", "복귀트리거", "threadpool"]
sources: ["[[15_Sources/2026-06-30_phase6_persona_review_source]]", "docs/analysis/20260629-phase6-persona-review.md"]
aliases: ["phase6페르소나검증", "arbiter적대리뷰", "PAB-Khala 페르소나검증"]
---

# PAB-Khala Phase 6 페르소나 검증 — arbiter 적대 리뷰

> [[2026-06-30_phase6_unified_gateway|Phase 6]] arbiter 초안을 3 페르소나(동시성·보안·적대QA)로 독립 적대 검증한 G0 기록. 원문 전문: [[15_Sources/2026-06-30_phase6_persona_review_source|SOURCE]].

## 판정 — G2 구현 불가
[[2026-06-30_phase6_persona_review_source#0. 판정 요약|원문 §0 →]]

v1.0 arbiter 스케치는 정상 운영 경로에 구조적 공백 2건(Blocker)이 입증돼 구현 불가. 둘 다 위협모델 무관하게 내부망 단독에서 "전체 LLM 트래픽 정지"로 현실화.

## 발견 통합표
[[2026-06-30_phase6_persona_review_source#1. 발견 통합표 (3 페르소나 dedup + 검증 verdict)|원문 §1 →]]

- **Q-1 (Blocker)**: swap 실패 중간상태 — GPU 고아 + `_current` 미갱신 + Ollama 복귀가 `vllm_stop already_off`(exit4→502)로 막혀 데드락.
- **Q-2 (Blocker)**: 배치 종료 후 Ollama 복귀 트리거가 **코드에 아예 없음** → vLLM 무기한 상주 → "mutex 자동화" 주장 거짓.
- High 다수: threadpool 고갈, idle/busy 미구분, admin↔arbiter 상호 무지, 권한 상승, 시간창 가드 부재.
- **과장 배제**: 명령 주입(S-4) 기각, "단일 프로세스=동시성 OK" 정정.

## 구조적 종합 — 근원 2개
[[2026-06-30_phase6_persona_review_source#2. 구조적 종합 — 근원 2개로 수렴|원문 §2 →]]

① 요청구동+락내 장시간 swap → **전용 직렬 swap 워커(큐)**로 해소. ② 복귀/시간창 트리거 부재 → **idle-TTL watcher + 배치 release + idle/busy 구분**. → arbiter v2로 반영.

## 교훈
[[2026-06-30_phase6_persona_review_source#3. G0 승인 조건 (필수 반영 → 마스터플랜 §4.5)|원문 §3 →]]

다중 페르소나 적대 검증이 "정상동작 주장"을 반증해 Blocker를 구현 전 차단(Phase 5 패턴 재현). 과장 자가배제도 검증의 일부. 반영본 → [[2026-06-30_phase6_unified_gateway]].
