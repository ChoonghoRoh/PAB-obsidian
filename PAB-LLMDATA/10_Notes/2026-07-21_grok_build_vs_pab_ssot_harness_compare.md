---
title: "Grok Build 하네스 vs PAB SSOT 하네스 정밀 비교 — 코드 강제 vs 문서 규범"
description: "xAI grok-build의 프롬프트 요청 처리 하네스(Rust 런타임)와 PAB SSOT(문서 기반 규범 하네스)의 요청 수명주기·프롬프트 계층·품질 게이트·컨텍스트 전략 정밀 비교"
created: 2026-07-21 07:09
updated: 2026-07-21 07:09
type: "[[RESEARCH_NOTE]]"
index: "[[HARNESS]]"
topics: ["[[PAB_SSOT]]", "[[CLAUDE_CODE]]", "[[GROK_BUILD]]"]
tags: [research-note, grok-build, ssot, agent-harness, claude-code, xai, compaction]
keywords: [Grok Build, xAI, SSOT, 하네스 비교, SessionActor, ACP, doom-loop, two-pass prefire, G0~G4 게이트, AGENTS.md, persona, worktree, max_turns]
sources: ["[[15_Sources/2026-07-21_grok_build_vs_pab_ssot_harness_compare_source]]", "https://github.com/xai-org/grok-build"]
aliases: ["grok vs SSOT 비교", "grok-build SSOT 하네스 비교", "하네스 정밀 비교 2026"]
---

# Grok Build 하네스 vs PAB SSOT 하네스 정밀 비교 — 코드 강제 vs 문서 규범

> 분석 방법: [[Grok Build]] 소스 직접 정독(시스템 프롬프트 3종 XOR 복호화 검증 포함) + 요청 처리 파이프라인 전수 조사, [[PAB_SSOT]] 코어 문서(0-entrypoint·3-workflow 전문·규칙 인덱스 100규칙) 정독. 전문은 원본(source) 참조.

## 1. 한 줄 결론
[원본 §1. 요약 (Executive Summary) →](2026-07-21_grok_build_vs_pab_ssot_harness_compare_source.md#1-요약-executive-summary)

두 하네스는 같은 문제 — **"LLM 에이전트가 요청을 받았을 때 폭주 없이 품질을 보장하며 완주하게 만드는 제어 구조"** — 를 정반대 수단으로 푼다. [[Grok Build]]는 **Rust 런타임 + OS 커널 샌드박스가 물리적으로 강제**하고, [[PAB_SSOT]]는 **규범 문서(상위 100규칙, CRITICAL 42)를 LLM이 자기 준수**한다. 그런데 양쪽이 도달한 제어 장치는 놀랍도록 수렴한다: worktree 격리, role/persona 이원화, 종료 게이트(Stop gate ↔ G4/DONE), todo 강제(TodoGate ↔ todo-list 산출물), 반복 상한, 파일 기반 에이전트 간 계약. **차이는 "누가 규칙을 지키게 만드는가" 하나로 수렴한다.**

## 2. 두 하네스의 정체
[원본 §2. 두 시스템 개관 →](2026-07-21_grok_build_vs_pab_ssot_harness_compare_source.md#2-두-시스템-개관)

- **Grok Build**: xAI의 터미널 AI 코딩 에이전트(약 90개 Rust crate, Apache 2.0). 전 실행 모드(TUI/headless/stdio/IDE)가 **ACP 단일 인터페이스**로 수렴하고, 머신당 leader 프로세스 1개가 상태를 소유하는 **leader-follower 멀티클라이언트** 구조. **세션 = 액터 = 전용 OS 스레드**.
- **PAB SSOT**: 실행 엔진이 없는 **문서 세트**. [[Claude Code]] Agent Teams가 범용 런타임이고, SSOT가 그 위에 20개 상태 머신 + G0~G4 게이트 + 9역할 팀(Hub-and-Spoke)을 규범으로 얹는다. 상태의 단일 진실은 `status.md` YAML(ENTRY-1).

## 3. 요청 처리 수명주기 비교
[원본 §3.3 에이전트 루프 →](2026-07-21_grok_build_vs_pab_ssot_harness_compare_source.md#33-에이전트-루프-핵심-턴-루프) · [원본 §3.4 반복·자율성 제어 →](2026-07-21_grok_build_vs_pab_ssot_harness_compare_source.md#34-반복자율성-제어-폭주-방지)

| 단계 | Grok Build | PAB SSOT |
|---|---|---|
| 진입 | 큐를 거치지 않으면 턴 시작 불가(코드 강제) | ENTRY-1~5: status.md 선독을 규범 강제 |
| 루프 | 3중 루프(액터 이벤트 → 외부 턴 → 내부 agentic), 1 iteration = 모델 호출 1회(초 단위) | 상태 머신 20개, 1 step = 상태 전이(분~시간 단위) |
| 폭주 방지 | `max_turns` 상한, **doom-loop 감지 재샘플**, TodoGate, Stop 훅 KeepWorking | AUTO_FIX ≤3회, retry ≥3 폐기, ITER-PRE/POST, **토큰 예산 500K(ITERATION-BUDGET)** |
| 개입 | **interjection**: 실행 중 턴에 밀리초 단위 주입, blocking-wait 툴 즉시 중단 | BLOCKED/REWINDING 상태 전이(Phase 수준 개입) |
| 종료 | tool_calls 빈 응답 + TodoGate + Stop 훅 AllowStop | G4(G2+G3+Blocker 0) + **Telegram 알림 없으면 DONE 무효**(NOTIFY-1) |

제어 해상도가 두 자릿수 다르다(툴 호출 단위 vs 상태 전이 단위). Grok의 폭주 방지는 **증상 감지형**, SSOT는 **예산·횟수 상한형**.

## 4. 툴 실행·안전장치와 품질 게이트
[원본 §3.5 툴 실행과 안전장치 →](2026-07-21_grok_build_vs_pab_ssot_harness_compare_source.md#35-툴-실행과-안전장치) · [원본 §3.6 검증·품질 게이트 →](2026-07-21_grok_build_vs_pab_ssot_harness_compare_source.md#36-검증품질-게이트)

- Grok: 2단계 디스패치(파싱→권한→`FuturesUnordered` 동시 실행+파일별 mutex), 권한 3모드(YOLO/**Auto=LLM 분류기**/Ask), **커널 샌드박스**(Landlock/Seatbelt/bwrap). plan 모드는 **YOLO에서도 read-only**(권한 위의 별도 코드 게이트).
- SSOT: 역할별 편집 권한(EDIT-1~5)·구현자/검증자 분리(HR-6, ASSIGN-1~5)·G2/G3 체크리스트 게이트. **Grok에는 내장 품질 게이트가 없고**(훅으로 사용자가 구성), **SSOT에는 결정론적 차단 지점이 없다** — 목적 차이(범용 도구 vs 프로젝트 품질 내장 운영 체계).
- 환산 법칙: **"코드 게이트 1개 = 문서 규칙 N개"** — plan read-only 1게이트 ↔ HR-1+EDIT-2+EDIT-3+복구 금지사항 4규칙.

## 5. 프롬프트(지시) 계층 비교
[원본 §4. 지시(프롬프트) 계층 비교 →](2026-07-21_grok_build_vs_pab_ssot_harness_compare_source.md#4-지시프롬프트-계층-비교--요청일-때-모델이-받는-규범)

- Grok 시스템 프롬프트 3종: **BASE 45줄**(정체성+action_safety+출력 규범), **CODEX 283줄**(openai/codex 포팅 — plan·preamble·최종 답변 스타일), **SUBAGENT 84줄**(role/persona 주입 슬롯). XOR 난독화 임베드이나 `templates/`에 평문 공개(strings 방지용). MiniJinja로 **툴 이름 런타임 바인딩**(`${{ tools.by_kind.* }}`).
- [[AGENTS.md]]는 시스템 프롬프트가 아닌 **user 메시지의 system-reminder로 주입**. `CLAUDE.md`·`.claude/rules/`·Claude 훅 별칭까지 **경쟁 도구 호환** — grok 위에 SSOT를 얹는 것도 이론상 가능.
- 압축 후엔 전체 스택이 **2문장 COMPACT_SYSTEM_PROMPT로 교체**된다(규범 소실 리스크) ↔ SSOT는 HR-3/FRESH-7로 압축 후 **전체 규범 재로딩**을 CRITICAL 강제.
- 분량의 역설: grok 기본 규범 45줄(행동 세부는 코드가 대행) vs SSOT 코어 2,600줄+(런타임 부재를 언어로 서술).

## 6. 컨텍스트 전략 — 가장 대조적인 영역
[원본 §3.7 컨텍스트 관리 →](2026-07-21_grok_build_vs_pab_ssot_harness_compare_source.md#37-컨텍스트-관리--가장-대조적인-영역)

- Grok: "컨텍스트는 소모품 — 압축하고 계속 달린다." 사용률 % 임계 자동 압축, **two-pass prefire**(임계 10%p 전 백그라운드 pass-1로 KV-cache 프리픽스 보존), preflight overflow, 이미지 evict(50MB), 툴 결과 prune. 복구는 `updates.jsonl` 리플레이 + 파일 스냅샷 rewind.
- SSOT: "컨텍스트는 신뢰 불가 — 진실은 디스크 문서에 있다." `/clear` + SSOT 리로드 + status.md 재진입(복구 프로토콜 7단계), SUB-SSOT 모듈 로딩으로 재로딩 비용 60% 절감.

## 7. 서브에이전트 vs 팀 — 수렴 진화의 증거
[원본 §3.8 서브에이전트 / 팀 위임 →](2026-07-21_grok_build_vs_pab_ssot_harness_compare_source.md#38-서브에이전트--팀-위임)

| | Grok | SSOT |
|---|---|---|
| 깊이 | 최대 1 (재스폰 시 task 툴 제거) | Hub-and-Spoke(구조상 등가) |
| 역할 정의 | agent type ⊕ role(TOML) ⊕ persona(TOML, **input/output 파일 계약**) | ROLES ⊕ PERSONA Charter ⊕ SUB-SSOT |
| 격리 | worktree isolation + pool | WT-1~5 (병렬 ≥2 트랙이면 필수) |
| 결과 | 요약 반환 + usage 정산 | REPORT-1~5: **보고서 파일 + 경로 링크만** |

grok persona의 input/output 계약과 SSOT REPORT 규칙은 같은 패턴 — **"에이전트 간 인터페이스를 파일로 고정"**. 양쪽 모두 대화 텍스트를 신뢰할 수 없는 전달 매체로 본다.

## 8. 상호 차용 제안
[원본 §8. 상호 차용 제안 (Actionable) →](2026-07-21_grok_build_vs_pab_ssot_harness_compare_source.md#8-상호-차용-제안-actionable)

**SSOT에 도입할 grok 장치**: ① doom-loop 감지 규칙(동일 실패 2회 → 접근 전환, retry 3회보다 조기 개입) ② prefire식 선제 상태 기록(`/clear` 전 status.md 동기화) ③ completion_requirement 패턴("X 산출물 없이 DONE 불가"를 status 필드로) ④ capability mode 명명 태그.
**grok에 SSOT식 보강**: ① AGENTS.md에 G2/G3 게이트 체크리스트 ② Stop 훅으로 G4 구현("검증 산출물 없으면 KeepWorking") ③ persona 계약을 REPORT 규칙처럼 파일 경로 표준화.

## 9. 핵심 통찰
[원본 §7. 핵심 통찰 3가지 →](2026-07-21_grok_build_vs_pab_ssot_harness_compare_source.md#7-핵심-통찰-3가지)

1. **하네스의 본질은 동일, 강제 수단만 다르다** — 구조적 대응물이 거의 1:1. LLM 에이전트 제어의 해 공간은 수렴 중.
2. **SSOT 규칙 인플레이션은 런타임 부재의 대가** — 대신 바이너리 없이 이식 가능하고 규칙 증축이 커밋 1개로 끝난다.
3. **컨텍스트 철학이 정체성을 가른다** — "압축하고 계속"(속도, 규범 소실 감수) vs "문서에서 재구성"(규범 보존, 토큰 비용 감수). 장시간 자율 작업에서 grok류가 규범을 잃는 지점이 정확히 SSOT HR-3가 겨냥하는 지점.
