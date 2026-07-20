---
title: "PAB-Khala tools/run 빈 응답·출력 오염 이슈"
description: "khala /v1/tools/run이 max_iter 소진 시 빈 final_response, status=ok에도 제어토큰·CoT 누출 — 원인·해결(FIX-A~F)·자동 loop 설계 검토"
created: 2026-07-02 14:24
updated: 2026-07-02 14:24
type: "[[LESSON]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[API_GATEWAY]]", "[[VLLM]]"]
tags: ["lesson", "khala", "tools-run", "issue", "bug", "max-iter", "vllm"]
keywords: ["khala", "tools/run", "max_iter", "final_response", "제어토큰누출", "degeneration", "cot누출", "no-data-exit", "적응형종료", "qwen3.6"]
sources: ["[[15_Sources/2026-07-02_khala_tools_run_max_iter_issues_source]]", "docs/overview/260702-Khala-toolsrun-빈응답-버그·개선점.md"]
aliases: ["khala tools/run 이슈", "max_iter 빈응답", "tools-run 출력오염"]
---

# PAB-Khala tools/run 빈 응답·출력 오염 이슈

> [[KHALA]]의 `/v1/tools/run`을 브라우저·외부에서 호출할 때 마주친 **빈 응답·출력 오염** 이슈와 해결·설계 검토(개발 이슈). 원문 전문: [[15_Sources/2026-07-02_khala_tools_run_max_iter_issues_source|SOURCE]].

## 한줄 요약
[[2026-07-02_khala_tools_run_max_iter_issues_source#TL;DR|원문 TL;DR →]]

없는/찾기 어려운 내용을 물으면 `/v1/tools/run`이 **빈 `final_response`(status=max_iter)** 로 끝나거나, **`status=ok`인데도 `<tool_call>`/`</think>` 제어토큰·사고과정을 누출**한다. 콘솔의 `undefined`는 데이터가 아니라 `console.log`의 반환값(오해).

## 핵심 버그 5종
[[2026-07-02_khala_tools_run_max_iter_issues_source#2. 버그/오해 목록|원문 §2 →]]

- **BUG-1**: max_iter 소진 → `final_response=""`(status=max_iter). status 미확인 시 조용한 실패.
- **BUG-4** (심각): 없는 내용 → 제어토큰 `<tool_call>`/`</think>` **누출·반복**, `status=ok`라 status로 안 걸림.
- **BUG-5**: 도구 미호출 + **사고과정 그대로 출력**, `status=ok`.
- NOTE-2(오해): 콘솔 `undefined`=`console.log` 반환값 · ROOT-3: "없어서"가 아니라 "못 끝냄"(SSOT 문서는 실재).

## 해결책 (FIX-A~F)
[[2026-07-02_khala_tools_run_max_iter_issues_source#3. 개선점|원문 §3 →]]

- **클라**: `status` 확인 + **출력 내용 검증**(`looksBroken`: 제어토큰/CoT/반복) — `status=ok`도 못 믿음.
- **프롬프트**: `max_iter≥8` + system에 수렴/포기 지시("근거 모이면 즉시 답, 없으면 없다고").
- **서버**: max_iter 종료 시 best-effort 요약(FIX-C), 출력 정화로 오염을 `status`에 반영(FIX-E), 디코딩 `repetition_penalty`·stop토큰 정합(FIX-F).

## status=ok 오염 사례 (아시아나·Karpathy)
[[2026-07-02_khala_tools_run_max_iter_issues_source#5. 추가 사례 상세 (2026-07-02 보강) — status=ok인데 오염된 출력|원문 §5 →]]

- **아시아나 IDT**(vault 0건) → 제어토큰 반복 7,389자.
- **Karpathy LLM Wiki**(전용문서 없음) → 도구 미호출·CoT 6,229자.
- 근본: quantized [[VLLM]] 소형 모델(qwen3.6-27b)의 tool-call 포맷·CoT 억제·'없음' 선언 신뢰성 부족.

## 설계 검토 — 자동 loop · no-data exit (개발방향 미정)
[[2026-07-02_khala_tools_run_max_iter_issues_source#6. 설계 검토 — 자동 loop 제어 · no-data exit · 사용자 옵션 (개발방향 미정)|원문 §6 →]]

사용자가 `max_iter`·exit를 손대지 않게 **시스템이 자동 판단**: ① 필요 loop 수 산정(**적응형 종료** 권장) ② `max_iter:"auto"` 서버모드 ③ **구조화 outcome**(no_data→`pab_lv0_list_keywords`로 실존 검색어 추천, thin_data→링크확장/웹조합). 웹조합은 조회/생성 **두 축 분리** 준수(LV0 저자only 혼입 금지). **C(적응형 종료+outcome 구조화)** 하나로 Q1~Q3 + BUG-1/4/5 일괄 해소.

## 관련
- 원문 보고서(PAB-v4 리포): `docs/overview/260702-Khala-toolsrun-빈응답-버그·개선점.md`
- 연동 배경: [[2026-06-30_khala_pab_v4_integration_source|khala↔PAB v4 연동]] · [[API_GATEWAY]] · [[KHALA]]
