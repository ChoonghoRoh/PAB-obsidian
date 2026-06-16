---
title: "Everything Claude Code 리뷰 (원문 캡처) — 갓대희의 작은공간"
description: "https://goddaehee.tistory.com/575 원문 캡처 — '하네스 엔지니어링' ECC 리뷰. WebFetch 추출본(바이트 단위 원문 아님)."
created: 2026-06-16 13:27
updated: 2026-06-16 13:27
type: "[[SOURCE]]"
index: "[[HARNESS]]"
topics: ["[[AGENT_HARNESS]]", "[[CLAUDE_CODE]]"]
tags: [source, claude-code, agent-harness, ecc]
keywords: [Everything Claude Code, ECC, 갓대희, 하네스 엔지니어링, Instinct, AgentShield]
sources: ["https://goddaehee.tistory.com/575"]
aliases: ["ECC 원문", "갓대희 ECC 리뷰"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층)
> ℹ️ 캡처 방식: Tistory 페이지를 WebFetch(소형 모델)로 추출 → 요약·재구성이 포함되어 **바이트 단위 원문과 동일하지 않음**. 정본은 상단 `sources` URL을 직접 확인할 것.

# "하네스 엔지니어링" — Everything Claude Code 리뷰: 혼자서 팀처럼 개발하는 에이전트 셋업

- **블로그**: 갓대희의 작은공간
- **출처 URL**: https://goddaehee.tistory.com/575
- **핵심 주제**: Everything Claude Code(ECC)는 단순한 설정 파일 모음이 아니라 **에이전트 하네스 성능 최적화 시스템**으로, Claude Code 및 기타 AI 코딩 에이전트의 성능을 체계적으로 개선하는 통합 프레임워크다.

## 프로젝트 개요

Everything Claude Code(ECC)는 GitHub 스타 **133,000+**를 기록한 프로젝트로, "단순 설정 파일 모음"이 아닌 **에이전트 하네스 성능 최적화 시스템**을 표방한다. 제작자 **Affaan Mustafa**는 2025년 NYC에서 열린 Anthropic 해커톤에서 우승했고, 2026년 Cerebral Valley 해커톤에서 보안 스캐너 **AgentShield**를 개발했다.

## 프로젝트 구조

ECC는 다음 구성요소를 통합한다.

- **36개 전문 에이전트** — planner, code reviewer, security auditor 등
- **151개 워크플로우 스킬** — TDD, 보안 리뷰, 프레임워크 패턴 등
- **68개 슬래시 명령어** — `/plan`, `/tdd` 등 레거시 엔트리 포함
- **25개+ 자동화 훅** — 7개 이벤트 타입에 걸침
- **34개+ 코딩 규칙** — 12개 언어 대상

## 3대 가이드

ECC는 세 종류의 가이드를 제공한다.

1. **Shortform Guide** — 빠른 시작용 요약 가이드
2. **Longform Guide** — 상세 설명 가이드
3. **Security Guide** — CVE 사례 기반 보안 가이드

## 핵심 구성요소

핵심 빌딩 블록은 **Agents, Skills, Commands, Hooks, Rules** 다섯 가지다. 사용자는 전부를 한 번에 설치하기보다 필요한 구성요소만 선택적으로 채택하도록 권장된다.

## 크로스 플랫폼 지원

ECC는 Claude Code를 넘어 다음 플랫폼을 지원한다.

- **Codex**
- **Cursor IDE**
- **OpenCode**
- **Antigravity**
- **Gemini CLI** (실험적 통합)

여러 AI 코딩 플랫폼에 걸쳐 **통합 설정**을 제공한다.

## AgentShield 보안 스캐너

**AgentShield**는 보안 스캐닝을 담당한다.

- **102개 정적 규칙(static rules)**
- **1,282개 테스트** (커버리지 98%)
- 옵션으로 **Opus 기반 심층 분석** 제공

보안 가이드는 실제 CVE 사례를 기반으로 작성되었다.

## 토큰 최적화와 자가 학습

ECC의 핵심 차별점은 **Instinct 시스템**이다. Claude가 도구 사용 패턴을 **신뢰도 점수(confidence score, 0.3~0.9)**와 함께 포착하고, `/evolve` 명령으로 이를 새 스킬로 진화시켜 **세션 간 패턴 학습**을 가능하게 한다.

토큰 측면 주의사항:

- 151개 스킬을 모두 활성화하면 200K 컨텍스트 윈도가 **~70K 토큰**까지 줄어들 수 있다.
- 권장: **MCP 설정 20~30개**, 동시 활성 **10개**, 전체 도구 **80개 미만**.
- **프로파일 기반 훅 제어**(minimal / standard / strict)로 환경에 맞춰 조정 가능.

## 설치 가이드

ECC는 **4가지 설치 방법**을 제공하며, 필요한 구성요소만 선택적으로 설치하는 것을 권장한다.

## 실전 활용 팁

- 모든 스킬·도구를 한꺼번에 켜기보다 **언어·작업별로 선별 활성화**.
- 병렬 작업 패턴 활용.
- 토큰 예산을 의식한 MCP·도구 수 관리.

## 커뮤니티 반응

긍정과 비판이 공존한다. 강력한 통합·자동화에 대한 호평과 함께, 과도한 구성요소가 컨텍스트·토큰을 잠식한다는 우려가 제기된다.

## 핵심 교훈

ECC는 **"설정은 아키텍처가 아니라 미세 조정(fine-tuning)"**이라는 원칙을 강조한다. 모든 것을 동시에 배포하기보다, 언어별 에이전트·스킬을 **선택적으로 채택**하는 편이 더 효과적이다. 자동 학습 시스템(Instinct)으로 세션 간 패턴 학습이 가능하고, 보안 가이드는 CVE 사례 기반이다.
