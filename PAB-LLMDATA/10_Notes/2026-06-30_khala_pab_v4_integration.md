---
title: "PAB-v4 Khala 연동 아키텍처 — 두 옵션 비교·권장"
description: "외부조회 연동 두 방향(khala-fronted/PAB-fronted) 비교·용도분담 권장·견고성 검증정정"
created: 2026-06-30 07:47
updated: 2026-06-30 07:47
type: "[[PROJECT]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[EXTERNAL_QUERY_API]]"]
tags: ["project", "khala", "pab-v4", "external-query", "integration", "architecture"]
keywords: ["khala", "pab-v4", "외부조회", "lineage", "resumable", "연동아키텍처", "결정성", "lv0", "추론위임"]
sources: ["[[15_Sources/2026-06-30_khala_pab_v4_integration_source]]", "docs/overview/260629-PAB-v4-khala연동-아키텍처분석.md"]
aliases: ["khala연동", "PAB-khala연동", "외부조회연동"]
---

# PAB-v4 Khala 연동 아키텍처 — 두 옵션 비교·권장

> 외부 LLM이 PAB 지식을 쓰는 **두 연동 방향**을 비교하고 견고성을 실증·정정한 의사결정 요약. 원문 전문: [[15_Sources/2026-06-30_khala_pab_v4_integration_source|SOURCE]].

## 핵심 질문 — 어느 방향으로 잇나
[원본 §0 →](2026-06-30_khala_pab_v4_integration_source.md#0-질문--어느-방향으로-잇는가)

[[KHALA]](LLM 추론·에이전트 런타임, 3800x `:8765`)와 PAB-v4(결정적 지식 공급자)는 같은 호스트에 있다. 잇는 방향은 둘이고, 차이는 **외부가 누구를 진입점으로 보느냐**다.

- **옵션 1 (khala-fronted)** — 외부 → khala `/v1/tools/run` → PAB를 **도구로 조회**. khala가 추론·진입점.
- **옵션 2 (PAB-fronted)** — 외부 → PAB `/ext` 게이트 → **khala로 추론 위임 + 출처 보존**.

두 옵션은 배타적이 아니라 워크로드가 다르다(옵션1=작업/생성, 옵션2=질의/답변).

## 컨텍스트 보호의 진짜 의미
[원본 §1 →](2026-06-30_khala_pab_v4_integration_source.md#1-컨텍스트-보호추론이-각-옵션에서-다른-것을-뜻한다-핵심)

khala의 두 자산 — **resumable**(`workspace.md`: 무엇을 이어가나)·**lineage**(`_runs.jsonl`: 누가 누구와). 둘 다 [[LV0]] 단순 조회엔 **불필요**(결정적·무상태). 가치는 **조회 위에 추론 턴이 쌓일 때** 난다. 이 사실이 두 옵션의 평가를 가른다.

## 축별 비교 (요약)
[원본 §2 →](2026-06-30_khala_pab_v4_integration_source.md#2-축별-비교)

| 축 | 옵션1 khala-fronted | 옵션2 PAB-fronted |
|---|---|---|
| 진입·책임 | khala (노출면 최소) | PAB (인증·SLA 표준 경계) |
| SLA 보존 | ⚠️ 재서술 위험 → URI로 완화 | ✅ 추론을 LV3+ 격리 |
| 구현 비용 | 낮음 (지금 실증됨) | 높음 (LV3/4 선행) |
| 결합도 | 느슨 (PAB는 khala 모름) | 강결합 (장애 전파) |

## 권장 — 용도 분담, 1차는 옵션 1
[원본 §5 →](2026-06-30_khala_pab_v4_integration_source.md#5-권장--용도-분리-단-1차는-옵션-1)

| 외부 요청 유형 | 진입점 | 옵션 |
|---|---|:---:|
| 작업/생성 위임 | khala | **1** |
| 결정적 조회 | PAB `/ext/lv0` | — |
| 출처보존 추론 | PAB `/ext/lv3·lv4` | **2** |

→ **옵션 1을 지금 정식화**(저비용·실증·[[LV0]] 정합), 옵션 2는 PAB 추론(LV3/4) 성숙 후 출처보존 추론 전용으로. 둘은 진입점이 달라 공존한다.

## 검증·정정 — khala 견고성은 층위별
[원본 §8 →](2026-06-30_khala_pab_v4_integration_source.md#8-직접-비교-검증--테스트-문서-기반-정정-2026-06-29-추가)

PAB-Khala 테스트 산출물 ↔ 라이브 lineage **100% 일치**로 직접 비교 입증(error parent 격리·path-traversal 400/404 라이브 재현). 단 견고성은 층위별로 다름을 정정:

- **lineage(B)** = 순차·단일라이터·내부망에서 견고 (`resume_valid`는 강제력 없는 경고)
- **무손실(A)** = Track A로 막 견고화 (6/6 KPI, 0628)
- **외부진입 견고성(인증·DoS·동시성·SSRF)** = **Track B 미구현**

→ 외부 공개형은 **옵션 2(PAB 게이트)가 보안상 우월**. 경계 원칙: **인증·DoS는 PAB가, 추론·컨텍스트는 khala가**.

## 의사결정 요약
[원본 §7 →](2026-06-30_khala_pab_v4_integration_source.md#7-의사결정-요약-한-장)

- 둘 중 하나만? → 아니오, **워크로드로 분담**.
- 지금 무엇? → **옵션 1 정식화**.
- MCP는? → Claude Desktop 전용 별 트랙. khala 연결엔 [[EXTERNAL_QUERY_API|REST]].
- SLA 보호? → **추론을 [[LV0]]에 섞지 않기**(LV3+ 격리, lineage로 근거 출처화).

---

관련: [[2026-05-04_pab_khala_overview|PAB-Khala 개요]] · 원문 [[15_Sources/2026-06-30_khala_pab_v4_integration_source|SOURCE 전문]]
