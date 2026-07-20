---
title: "RESEARCH_NOTE — Type MOC"
description: "RESEARCH_NOTE TYPE에 속하는 모든 노트의 자동 수집 MOC. 외부 레퍼런스/논문/실험 노트의 진입점."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[TYPES]]"]
tags: [moc, types/research-note]
keywords: [moc, research-note, type-index]
sources: ["wiki/30_Constraints/frontmatter-spec.md"]
aliases: ["RESEARCH_NOTE MOC", "Research Notes Index"]
---

# RESEARCH_NOTE — Type MOC

## TYPE 정의

`RESEARCH_NOTE`는 **외부 자료(논문·블로그·강의·영상·기술 문서 등)를 분석·정제한 노트**이다. 출처(`sources` 필드)를 명확히 갖추고, 인용·요약·자체 해석을 분리하여 LLM이 원천을 추적할 수 있게 한다.

- **작성 시점**: 외부 자료를 학습하면서 (강의 시청 중 / 논문 정독 중 / 블로그 정리 중)
- **예시**:
  - "Agentic Engineering 개론" — Karpathy 강의 분석
  - "LangGraph 멀티에이전트 패턴" — 공식 문서 + arXiv 논문 정리
  - "Claude Code Hook 메커니즘" — Anthropic docs 발췌

## 자동 수집 (dataview)

```dataview
LIST
FROM ""
WHERE type = "[[RESEARCH_NOTE]]"
SORT created DESC
LIMIT 100
```

## 폴백 정적 링크

<!-- moc-build:auto-start -->
- [[2026-06-23_rtx3090_vllm_context_kv_offload]] — vLLM 컨텍스트 확장 핵심 진단 — 엔진 KV캐시 vs 앱 외부기억 2층위 (RTX3090)
- [[2026-06-16_everything_claude_code]] — Everything Claude Code (ECC) — 에이전트 하네스 최적화 시스템 (갓대희 리뷰)
- [[2026-06-15_deepseek_v4_opencode_api]] — DeepSeek V4를 OpenCode에 이식하기 — OpenAI 호환 base_url로 provider 연결 + oh-my-opencode 프레임워크 활용
- [[2026-06-14_pab_conductor_03_features]] — PAB-Conductor 구현 기능 전수 분석
- [[2026-06-01_samsung_sds_public_ax_direction]] — 공공AX 추진 방향 및 우선 과제 (삼성SDS, 2026)
- [[2026-06-01_samsung_sds_trusted_public_ax_workflow]] — 신뢰 기반 공공AX 업무 체계 고도화 전략 (삼성SDS, 2026)
- [[2026-06-01_samsung_sds_public_ax_strategy]] — 공공AX 전환 전략 — 공공 AI·클라우드 기반 구조 설계 (삼성SDS, 2026)
- [[2026-05-27_mcp_spec_2026_07_28_rc]] — MCP 스펙 2026-07-28 RC — stateless 프로토콜 + first-class extensions (출시 후 최대 개정)
- [[2026-05-26_beellama_v020_dflash_3090]] — BeeLlama.cpp v0.2.0 — DFlash로 단일 RTX 3090에서 Qwen3.6-27B 164 tps(4.40x)·Gemma4-31B 177.8 tps(4.93x)
- [[2026-05-07_qwen36_3090_launch_scripts]] — Qwen3.6 on RTX 3090 — 재현 가능한 Launch Scripts 가이드 (Alexander-Ollman GitHub)
- [[2026-05-07_qwen36_dual_3090_25_to_283_tps]] — Qwen3.6 듀얼 RTX 3090 풀스택 서빙 — 25 → 283 tok/s (Round 1 dense + Round 2 MoE)
- [[2026-05-06_greedysearch_pi]] — GreedySearch-pi — API 키 없이 헤드리스 브라우저로 Perplexity/Bing/Google AI 병렬 검색 (Pi + Claude Code 플러그인)
- [[2026-05-05_qwen36_27b_3090_218k_pn12]] — Qwen3.6-27B on 1× RTX 3090 — 218K context + PN12 fix (Reddit follow-up)
- [[2026-05-05_pab_ssot_skills_detail]] — PAB SSOT — 11 skill 상세 (입출력·내부 절차·예시)
- [[2026-05-05_club_3090]] — club-3090 — RTX 3090에서 LLM 서빙하는 두 가지 경로 (vLLM dual / llama.cpp single)
- [[2026-05-05_pab_ssot_intro]] — PAB SSOT v8.2-renewal-6th — 진입점·버전·3계층 아키텍처 개요
- [[2026-05-05_pab_ssot_templates]] — PAB SSOT — 템플릿 11종 (TEMPLATES/)
- [[2026-05-05_pab_ssot_persona_qc]] — PAB SSOT — 9 PERSONA Charter + 11명 Verification Council (QUALITY/10-persona-qc)
- [[2026-05-05_pab_ssot_skills_catalog]] — PAB SSOT — 11 skill 카탈로그 (skills/)
- [[2026-05-05_pab_ssot_roles]] — PAB SSOT — 역할 9종 정의 (ROLES/)
- [[2026-05-05_pab_ssot_architecture]] — PAB SSOT — 시스템 아키텍처 (인프라·BE·FE·DB)
- [[2026-05-05_pab_ssot_workflow]] — PAB SSOT — 워크플로우·상태 머신·게이트·Phase Chain
- [[2026-05-05_pab_ssot_rules_chain]] — PAB SSOT — 96개 규칙 통합 인덱스 + 공통 포맷 (6-rules-index + 7-shared-definitions)
- [[2026-05-05_pab_ssot_subssot_misc]] — PAB SSOT — SUB-SSOT 라우팅 + tests + mcp-design + infra (보조 디렉토리)
- [[2026-05-05_pab_ssot_event_automation]] — PAB SSOT — 이벤트 프로토콜·자동화 파이프라인 (4·5-event/automation)
- [[2026-05-03_local_llm_under_3090]] — 12GB VRAM(RTX 3060)으로 쓸만한 LLM 호스팅 가능한가 — r/LocalLLaMA 토론 정리
- [[2026-05-02_karpathy_llm_wiki_v1_backup]] — Karpathy의 LLM Wiki — 누적되는 지식 산출물 패턴
- [[2026-05-02_karpathy_llm_wiki]] — Karpathy의 LLM Wiki — 누적되는 지식 산출물 패턴
<!-- moc-build:auto-end -->

> Phase 1-4 `wiki moc-build` 명령으로 자동 채워질 placeholder. dataview 미지원 환경(LLM/CLI)에서도 도달할 수 있도록 정적 링크 리스트를 유지한다.

- (placeholder — Phase 1-4 `wiki moc-build`에서 자동 채움)

## 작성 가이드

새 RESEARCH_NOTE 작성 시 다음 템플릿을 사용한다:

- 템플릿: [[40_Templates/RESEARCH_NOTE]]
- 명명 규칙: `wiki/10_Notes/YYYY-MM-DD_<slug>.md`
- 필수 frontmatter: `type: "[[RESEARCH_NOTE]]"`, `sources: [...]` (외부 URL/도서명 1개 이상)
- 권장 섹션: 개요 / 핵심 주장 / 인용 / 본인 해석 / 후속 질문
