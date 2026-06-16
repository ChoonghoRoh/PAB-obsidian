---
title: "Everything Claude Code (ECC) — 에이전트 하네스 최적화 시스템 (갓대희 리뷰)"
description: "GitHub 13.3만+ 스타 ECC 정리 — 36 에이전트·151 스킬·68 명령어, Instinct 자가학습, AgentShield 보안, '설정은 미세조정이지 아키텍처가 아니다' 원칙."
created: 2026-06-16 13:27
updated: 2026-06-16 13:27
type: "[[RESEARCH_NOTE]]"
index: "[[HARNESS]]"
topics: ["[[AGENT_HARNESS]]", "[[CLAUDE_CODE]]"]
tags: [research-note, claude-code, agent-harness, ecc, instinct, agentshield]
keywords: [Everything Claude Code, ECC, Affaan Mustafa, agent harness, Instinct, AgentShield, MCP, 토큰 최적화, 크로스 플랫폼, Claude Code]
sources: ["[[15_Sources/2026-06-16_everything_claude_code_source]]", "https://goddaehee.tistory.com/575"]
aliases: [ECC, "에브리띵 클로드 코드", "Everything Claude Code"]
---

# Everything Claude Code (ECC) — 에이전트 하네스 최적화 시스템

> 갓대희 블로그 리뷰([원문](https://goddaehee.tistory.com/575)) 정리. ECC는 설정 파일 모음이 아니라 [[Claude Code]] 같은 AI 코딩 에이전트의 **하네스(harness)** 성능을 끌어올리는 통합 프레임워크다.

## ECC란 무엇인가
[원본 §프로젝트 개요 →](2026-06-16_everything_claude_code_source.md#프로젝트-개요)

**Everything Claude Code(ECC)**는 GitHub 스타 **13.3만+**를 기록한 오픈소스로, 자신을 "단순 설정 모음이 아닌 **에이전트 하네스 성능 최적화 시스템**"으로 규정한다. 제작자 **Affaan Mustafa**는 Anthropic 해커톤(2025, NYC) 우승자이며, 보안 스캐너 [[AgentShield]]를 별도 해커톤에서 내놓았다. 핵심 메시지는 "에이전트를 더 똑똑하게 만드는 건 모델 교체가 아니라 **하네스 엔지니어링**"이라는 것.

## 구성 요소 한눈에
[원본 §프로젝트 구조 →](2026-06-16_everything_claude_code_source.md#프로젝트-구조)

ECC는 다섯 빌딩 블록(**Agents · Skills · Commands · Hooks · Rules**)으로 이뤄진다.

| 구성요소 | 규모 | 비고 |
|---|---|---|
| Agents | 36개 | planner·code reviewer·security auditor 등 |
| Skills | 151개 | TDD·보안 리뷰·프레임워크 패턴 |
| Commands | 68개 | `/plan`, `/tdd` 등 |
| Hooks | 25개+ | 7개 이벤트 타입 |
| Rules | 34개+ | 12개 언어 |

핵심 권고: **전부 설치 금지 — 필요한 것만 선택적 채택**.

## Instinct — 세션 간 자가 학습
[원본 §토큰 최적화와 자가 학습 →](2026-06-16_everything_claude_code_source.md#토큰-최적화와-자가-학습)

ECC의 차별점은 **Instinct 시스템**이다. Claude가 도구 사용 패턴을 **신뢰도 점수 0.3~0.9**와 함께 기록하고, `/evolve` 명령으로 이를 **새 스킬로 진화**시켜 세션을 넘는 학습을 가능케 한다. 본 프로젝트의 SSOT 거버넌스(AutoCycle·SUB-SSOT 모듈 로딩)와 문제의식이 겹치는 지점.

## AgentShield — 보안 스캐너
[원본 §AgentShield 보안 스캐너 →](2026-06-16_everything_claude_code_source.md#agentshield-보안-스캐너)

[[AgentShield]]는 **102개 정적 규칙**, **1,282개 테스트(커버리지 98%)**, 옵션 **Opus 심층 분석**을 갖춘 스캐너다. 보안 가이드는 실제 **CVE 사례 기반**으로 작성된다.

## 크로스 플랫폼
[원본 §크로스 플랫폼 지원 →](2026-06-16_everything_claude_code_source.md#크로스-플랫폼-지원)

[[Claude Code]] 외에 **Codex · Cursor IDE · OpenCode · Antigravity**를 지원하고 **Gemini CLI**는 실험적 통합. 여러 코딩 에이전트에 **통합 설정**을 제공하는 것이 목표.

## 도입 시 주의점 — 토큰 예산
[원본 §실전 활용 팁 →](2026-06-16_everything_claude_code_source.md#실전-활용-팁)

- 151개 스킬 **전체 활성화 시 200K 컨텍스트 → ~70K로 축소**될 수 있음.
- 권장치: **MCP 설정 20~30개 / 동시 활성 10개 / 전체 도구 80개 미만**.
- **프로파일 기반 훅 제어**(minimal·standard·strict)로 환경별 조정.

## 핵심 교훈 — "설정은 미세조정이지 아키텍처가 아니다"
[원본 §핵심 교훈 →](2026-06-16_everything_claude_code_source.md#핵심-교훈)

ECC의 결론은 **"configuration is fine-tuning, not architecture"**. 모든 구성요소를 동시 배포하지 말고 언어·작업별로 **선별 채택**하는 편이 효과적이다. → 본 프로젝트 시사점: SSOT/SUB-SSOT의 **역할별 모듈 로딩(약 60% 토큰 절감)** 전략과 동일한 철학. 무분별한 스킬·MCP 확장은 컨텍스트 예산을 잠식한다.
