---
title: "Grok Build 오픈소스 하네스 vs PAB SSOT 하네스 정밀 비교 보고서 (원문)"
description: "xAI grok-build의 프롬프트 요청 처리 하네스와 PAB SSOT 문서 하네스 정밀 비교 보고서 전문 — 소스 코드(프롬프트 복호화 포함)·SSOT 문서 직접 분석 기반"
created: 2026-07-21 07:09
updated: 2026-07-21 07:09
type: "[[SOURCE]]"
index: "[[HARNESS]]"
topics: ["[[PAB_SSOT]]", "[[CLAUDE_CODE]]", "[[GROK_BUILD]]"]
tags: [source, grok-build, ssot, agent-harness, xai]
keywords: [Grok Build, xAI, SSOT, agent harness, SessionActor, ACP, compaction, quality gate, subagent, worktree, doom-loop]
sources: ["https://github.com/xai-org/grok-build"]
aliases: ["grok-build 비교 보고서 원문", "grok vs SSOT source"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층). 작성 2026-07-21 · 사본 원본: docs/data/grok-build-vs-PAB-SSOT-하네스-정밀비교-보고서.md · 분석 대상 저장소: https://github.com/xai-org/grok-build

# Grok Build 하네스 vs PAB SSOT 하네스 — 정밀 비교 보고서

**작성일**: 2026-07-21
**비교 대상 A**: xAI(SpaceXAI) **Grok Build** (`grok`) — 오픈소스 터미널 AI 코딩 에이전트 런타임 (Rust, Apache 2.0, `sub/grok-build`, monorepo 동기화본)
**비교 대상 B**: **PAB SSOT v8.0-renewal-6th** — 본 프로젝트의 문서 기반 멀티에이전트 오케스트레이션 하네스 (`SSOT/`, Claude Code Agent Teams 위에서 운영)
**분석 방법**: grok-build 소스 직접 정독(시스템 프롬프트 3종 XOR 복호화 포함) + 병렬 탐색 에이전트의 요청 처리 파이프라인 전수 조사 + SSOT 코어 문서(0-entrypoint, 3-workflow 전문, 규칙 인덱스) 정독

---

## 1. 요약 (Executive Summary)

두 하네스는 같은 문제 — **"LLM 에이전트가 사용자 요청을 받았을 때, 폭주하지 않고 품질을 보장하며 끝까지 완료하게 만드는 제어 구조"** — 를 정반대 방향에서 푼다.

| 축 | Grok Build | PAB SSOT |
|---|---|---|
| **강제 계층** | Rust 런타임 코드 + OS 커널(Landlock/Seatbelt 샌드박스)이 **물리적으로 강제** | 규범 문서(HARD RULES 등 상위 100규칙)를 LLM이 **자기 준수** |
| **하네스의 실체** | 컴파일된 이벤트 루프 (`SessionActor` → `handle_prompt` → `process_conversation_turn`) | 마크다운 상태 머신 (`status.md` YAML + 20개 상태 + G0~G4 게이트) |
| **에이전트 모델** | 단일 주 에이전트 + 얕은(depth 1) 서브에이전트 | Team Lead + 9개 역할 페르소나 팀 (Hub-and-Spoke) |
| **품질 보증** | 훅·권한·샌드박스·TodoGate·Stop 게이트 (실행 시점 차단) | 역할 분리(구현자/검증자) + G0~G4 게이트 (프로세스 시점 판정) |
| **컨텍스트 위기 대응** | 자동 압축(two-pass prefire) → 초소형 시스템 프롬프트로 교체 후 계속 | `/clear` + SSOT 리로드 + status.md 재진입 (문서에서 상태 복원) |
| **기록/복구 매체** | `updates.jsonl` 리플레이 + 파일 스냅샷 rewind point | Phase 산출물 4종 + Chain 파일 + Git 태그/worktree |

가장 흥미로운 발견은 **수렴 진화**다: 서로 완전히 다른 강제 수단을 쓰면서도, 두 시스템은 worktree 격리, 역할(role)/페르소나(persona) 이원화, 종료 게이트(Stop gate ↔ G4/DONE), todo 강제(TodoGate ↔ todo-list 산출물), 반복 상한(max\_turns/AUTO\_FIX 3회), 메모리 주입 같은 동일한 제어 장치에 도달했다. 차이는 "누가 그 규칙을 지키게 만드는가"(코드 vs 규범) 하나로 수렴한다.

---

## 2. 두 시스템 개관

### 2.1 Grok Build — 컴파일된 런타임 하네스

- 약 90개 crate의 Rust workspace. 핵심: `xai-grok-shell`(에이전트 런타임), `xai-grok-agent`(에이전트 정의+프롬프트 조립), `xai-grok-tools`(툴), `xai-grok-sampler`(모델 호출), `xai-chat-state`(대화 상태 액터), `xai-grok-compaction`(압축), `xai-grok-mcp`(MCP), `xai-grok-sandbox`(샌드박스).
- **모든 실행 모드(TUI/headless/stdio/IDE)가 ACP(Agent Client Protocol) 단일 인터페이스**(`impl acp::Agent`인 `MvpAgent`)로 수렴. 서브에이전트조차 부모와 ACP로 통신.
- **Leader-follower 구조**: 머신당 leader 프로세스 1개가 에이전트 상태를 소유하고(`~/.grok/leader.sock`), TUI/IDE/headless 클라이언트가 붙어 **공유 대화·공유 프롬프트 큐**를 본다. "1 프로세스 = 1 세션"인 통상 CLI 에이전트와 근본적으로 다른 설계.
- **세션 = 액터 = 전용 OS 스레드**: 각 `SessionActor`는 `!Send`로 자기 스레드의 tokio `LocalSet` 위에서만 돌고, 외부와는 `SessionCommand` mpsc 채널로만 통신한다.

### 2.2 PAB SSOT — 문서 기반 규범 하네스

- 실행 엔진이 없다. Claude Code(Agent Teams: TeamCreate/SendMessage/TaskList)가 범용 런타임이고, SSOT 문서 세트가 그 위에 **워크플로우·역할·게이트·금지 규칙**을 규범으로 얹는다.
- 계층: `0-entrypoint.md`(진입) → `1-project.md`(팀) → `2-architecture.md` → `3-workflow.md`(상태 머신) → `4-event-protocol.md` → `5-automation.md` + `ROLES/`·`PERSONA/`·`SUB-SSOT/`(역할별 모듈 로딩) + `core/6-rules-index.md`(규칙 100개, 20카테고리, CRITICAL 42/HIGH 37/MEDIUM 18/LOW 1).
- 워크플로우는 **20개 상태 머신**(4th 14 + 5th 6)으로 정의되고, 상태의 단일 진실은 `docs/phases/phase-X-Y/phase-X-Y-status.md` YAML(ENTRY-1)이다.
- 5세대 혁신 5축: Research-first(G0), Event-first(JSONL), Automation-first(AUTO\_FIX 등), Branch-first(Git 격리), Multi-perspective(11명 Verification Council).

---

## 3. 요청(프롬프트) 처리 수명주기 — 단계별 정밀 비교

사용자 요청 1건이 완료까지 흐르는 경로를 단계별로 대응시킨다.

### 3.1 진입 (Entry)

| 단계 | Grok Build | PAB SSOT |
|---|---|---|
| 수신 | 클라이언트 → `MvpAgent::prompt()` (acp\_agent.rs:1983) → `SessionCommand::Prompt`를 세션 액터 mailbox로 전송 | 사용자 → Team Lead 메인 세션이 자연어로 수신 |
| 전처리 | 슬래시/스킬 resolve, 이미지 정규화, 대용량 truncation, `UserPromptSubmit` 훅 | FRESH-1: SSOT 0→1→2→3 로딩, ENTRY-1: status.md 선독(先讀), ENTRY-3: ssot\_version 대조, ENTRY-4: blocker 우선 |
| 시작 강제 | 코드가 강제 — 큐를 거치지 않고는 턴이 시작될 수 없음 | ENTRY-5(진입점 외 직접 시작 금지)를 **규범으로** 강제 — 위반 가능하나 규칙 위반으로 처리 |

- Grok은 진입 자체가 코드 경로라 우회가 불가능하다. SSOT는 "status.md를 읽지 않고 시작하는 것"이 물리적으로 가능하기 때문에, 이를 CRITICAL 규칙(ENTRY-5) + 체크리스트 + 복구 프로토콜(§9)로 3중 방어한다. **SSOT 규칙 수의 상당 부분은 '런타임이 없어서 생기는 빈틈'을 문서로 메우는 비용**이다.

### 3.2 대기열과 조율 (Queueing / Steering)

| 항목 | Grok Build | PAB SSOT |
|---|---|---|
| 큐 | `pending_inputs: VecDeque` (액터 상태가 유일한 권위). versioned 편집(remove/reorder/edit/interject), owner-scoped, `x.ai/queue/changed` 실시간 브로드캐스트 | Phase Chain 파일(`phase-chain-*.md`)의 phases 배열 = 매크로 수준 큐. CHAIN-4(순서 보장, 건너뛰기 금지) |
| 실행 중 개입 | **Interjection** 전용 크레잇(`xai-interjection-core`): 턴 실행 중 사용자 메시지를 안전 지점에서 `<user_query>`로 주입, blocking-wait 툴은 `tokio::select!`로 즉시 중단 | 사용자가 Team Lead에게 개입 → Team Lead가 SendMessage로 팀원 조율. BLOCKED 상태 전이로 공식화 |
| 우선순위 | user > synthetic(자동 깨우기) — user 도착 시 synthetic 항목 sweep 제거 | Blocker 최우선(ENTRY-4), 이후 상태 머신 순서 |

- Grok의 interjection은 **턴 내부(밀리초~초)** 개입이고, SSOT의 BLOCKED/REWINDING은 **Phase 수준(분~시간)** 개입이다. 제어 해상도가 두 자릿수 다르다.

### 3.3 에이전트 루프 (핵심 턴 루프)

**Grok Build** — 3중 루프 구조 (`turn.rs`, 2,497줄):

```
run_session (액터 이벤트 루프, tokio::select!)
 └─ handle_prompt          [외부 턴 루프]
     └─ loop:
         process_conversation_turn   [내부 agentic 루프]
           loop:
             인터젝션 드레인 → 메모리/MCP/모니터 리마인더 주입
             auto-compact 체크 → 필요 시 압축
             build_request → SamplerActor → 모델 호출
             tool_calls 없음 → TodoGate(미완 todo nudge) → Completed
             tool_calls 있음 → execute_tool_calls (2단계 디스패치)
             max_turns 초과 → MaxTurnsReached
             preflight overflow → 압축 후 continue
         ← TurnOutcome
         goal 루프 활성 → continuation 주입 후 continue
         Stop 훅 → KeepWorking이면 피드백을 user 메시지로 넣고 continue
```

**PAB SSOT** — 상태 머신이 곧 루프:

```
IDLE → TEAM_SETUP → [RESEARCH → G0] → PLANNING → G1 → [DESIGN_REVIEW]
 → TASK_SPEC(ASSIGN 검증) → [BRANCH_CREATION → WORKTREE_SETUP]
 → BUILDING → VERIFYING(G2) ─FAIL→ AUTO_FIX(≤3회) ─┐
 → TESTING(G3) → [AB_COMPARISON] → INTEGRATION → E2E │
 → E2E_REPORT → TEAM_SHUTDOWN → DONE(G4 + NOTIFY)    │
 실패: REWINDING → rewind_target / 차단: BLOCKED ←───┘
```

| 항목 | Grok Build | PAB SSOT |
|---|---|---|
| 루프 단위 | 모델 호출 1회 = 1 iteration (초 단위) | 상태 전이 1회 = 1 step (분~시간 단위) |
| 상태 저장 | 메모리 내 액터 상태 + `updates.jsonl` append | `status.md` YAML의 `current_state` 명시 기록 |
| 종료 조건 | tool\_calls 빈 응답 + TodoGate 통과 + Stop 훅 AllowStop | G4 PASS(G2+G3+Blocker 0) + Telegram 알림(NOTIFY-1: 알림 없으면 DONE 무효) |
| 완주 강제 | `completion_requirement`(필수 툴 미호출 시 리마인더 주입 + 지수 백오프 재시도), goal harness continuation | CHAIN-6 산출물 의무, CHAIN-7 게이트 생략 불가, 체크리스트 대조 |

### 3.4 반복·자율성 제어 (폭주 방지)

| 장치 | Grok Build | PAB SSOT |
|---|---|---|
| 반복 상한 | `max_turns`(툴 라운드 상한, 기본 무제한, headless `--max-turns`) → `MaxTurnsReached` | AUTO\_FIX ≤ 3회, 동일 상태 retry\_count ≥ 3이면 접근 폐기+사용자 대기, ITER-PRE ≤ 3회, ITER-POST ≤ 2회 |
| 루프 병리 감지 | **doom-loop recovery**: 모델이 같은 출력을 반복하면 별도 budget으로 재샘플, 소진 시 as-is 수락 (sampler 계층) | 없음 — 상태 머신 재시도 상한이 간접 방어 |
| 자원 상한 | 토큰은 압축으로 관리(상한 개념 없음) | **ITERATION-BUDGET**: 1 사이클 500K 토큰, 80% WARNING, 100% HALT+에스컬레이션 |
| 계속 강제 | Stop 훅 `KeepWorking`(피드백 주입 후 턴 연장), goal streak/backoff | Team Lead가 상태 기반 판정으로 다음 상태 지시 |
| API 장애 | 401 복구 1s/2s/4s per-incident 백오프(과거 지수 폭주로 11.57일 sleep 버그 → 회귀 테스트로 고정), context-length 에러 → 압축 후 재제출 | E0~E4 등급별 대응(E0 즉시 중단·보고, E1 BLOCKED, E2 REWINDING…) |

- Grok의 폭주 방지는 **증상 감지형**(doom-loop, TodoGate, Stop gate)이고 SSOT는 **예산·횟수 상한형**(3회, 500K)이다. 특히 doom-loop recovery(모델 반복 감지 재샘플)와 ITERATION-BUDGET(명시적 토큰 예산)은 서로에게 없는 장치로, 상호 차용 가치가 가장 크다(→ §8).

### 3.5 툴 실행과 안전장치

| 항목 | Grok Build | PAB SSOT |
|---|---|---|
| 디스패치 | 2단계: ① `prepare_tool_call`(인자 파싱 — concatenated-JSON 복구 포함, plan-mode edit gate, PreToolUse 훅, 권한 판정) ② `FuturesUnordered` **동시 실행** + 같은 파일 쓰기는 per-path mutex 직렬화 | Team Lead가 SendMessage로 팀원에게 위임. 동시성은 EDIT-5(동일 파일 동시 편집 금지)·worktree 격리로 규범 관리 |
| 권한 | 3모드: **YOLO**(전부 승인) / **Auto**(LLM 분류기 사이드쿼리가 위험도 판정) / **Ask**(사용자 승인). `AccessKind`별 세분화 | 역할별 편집 권한 문서 고정: Team Lead ❌, backend-dev `backend/ tests/ scripts/`, frontend-dev `web/ e2e/`, verifier/planner 읽기 전용 (EDIT-1~4) |
| 격리 | **커널 샌드박스**: Landlock(Linux)/Seatbelt(macOS)/bwrap re-exec, 네트워크 정책, 경로 deny/glob | Git worktree 격리(WT-1~5): 병렬 트랙 ≥ 2면 worktree 필수, CWD 주입 검증(WT-3), 위반 시 재할당 |
| 읽기 전용 모드 | plan 모드는 **권한 모드와 무관하게(YOLO 포함)** edit gate가 read-only 강제 | verifier(Explore)·planner(Plan)는 쓰기 권한 없는 subagent 타입으로 스폰 — 도구 수준에서 실질 강제되는 유일한 지점 |

- 주목: Grok의 "plan 모드는 YOLO에서도 read-only"는 **권한 시스템 위에 있는 별도 코드 게이트**다. SSOT의 대응물은 HR-1(Team Lead 수정 금지)인데, 이는 규범이라 위반이 물리적으로 가능하고, 실제로 CLAUDE.md에 "어떤 이유로도 정당화 불가"라는 강한 언어 + 위반 기록 절차가 필요했다. **같은 요구를 코드는 게이트 1개로, 문서는 규칙 4개(HR-1, EDIT-2, EDIT-3, 복구 시 금지사항)로 커버한다.**

### 3.6 검증·품질 게이트

| 항목 | Grok Build | PAB SSOT |
|---|---|---|
| 코드 품질 | 시스템 프롬프트 지침(root-cause fix, 최소 변경, 테스트 검증 유도) + 사용자 훅(PostToolUse 등) | G2 게이트: verifier가 Critical 체크리스트(ORM/Pydantic/타입힌트/ESM/esc()/CDN) 판정, Critical 1건이면 FAIL |
| 테스트 | 프롬프트 지침("start specific, then broaden") — 실행 여부는 모델 재량+승인 모드 | G3 게이트: tester 전용(ASSIGN-2, 구현자 셀프체크 금지), pytest+커버리지 ≥80%+E2E+결함밀도 ≤5건/KLOC(ISTQB) |
| 독립성 | 서브에이전트 리뷰 권장(user-guide) — 강제 아님 | **구현자/검증자 역할 분리 자체가 하네스의 뼈대**(HR-6, ASSIGN-1~5, Team Lead 3단계 통제) |
| 최종 판정 | Stop 훅 + TodoGate (턴 종료 조건) | G4: G2 PASS + G3 PASS + Blocker 0 → DONE, 다관점 옵션(11명 Verification Council) |

- Grok에는 SSOT의 G2/G3에 해당하는 **내장 품질 게이트가 없다** — 품질은 프롬프트 지침·훅·사용자 리뷰에 위임된다. 반대로 SSOT에는 Grok의 훅 같은 **결정론적 차단 지점이 없다**(Telegram 스크립트가 유일한 외부 실행 지점). 이는 두 시스템의 목적 차이를 반영한다: Grok은 범용 도구(품질 기준은 사용자 몫), SSOT는 특정 프로젝트의 품질 기준을 내장한 운영 체계.

### 3.7 컨텍스트 관리 — 가장 대조적인 영역

| 항목 | Grok Build | PAB SSOT |
|---|---|---|
| 임계 감지 | 토큰 사용률 % 임계(`should_auto_compact`), 툴 출력 후 preflight overflow 체크, 모델 전환 시 재검사, context-length 에러 시 | FRESH-5(Task 3개+ 처리 시 버전 재확인), CHAIN-2(`/clear` 필수) — 감지가 아니라 **예방적 초기화** |
| 압축 방식 | **Two-pass prefire**: 임계 도달 10%p 전에 백그라운드에서 pass-1 요약을 미리 생성(KV-cache 프리픽스 보존) → 실제 압축 시 pass-2로 완결. 이미지 evict(≈50MB), 툴 결과 prune(>50% 사용률) | 압축을 **신뢰하지 않음**. HR-3/FRESH-7: 압축·중단 후에는 요약 기반 재개 금지, SSOT 리로드 + status.md + 팀 재구성 필수 |
| 압축 후 정체성 | 시스템 프롬프트를 2문장 `COMPACT_SYSTEM_PROMPT`로 **교체**하고 계속 진행 | 압축 후에도 원본 문서를 다시 읽어 **전체 규범을 복원** |
| 토큰 절약 | 요청 조립 시 hot-path 무변형 clone, 메모리 리마인더는 첫 턴만(`context_injected` gate) | SUB-SSOT 모듈형 로딩(역할별 13K~38K 토큰, 60% 절감), 실행 단위 권장 로딩 집합(§9.5) |
| 복구 | `updates.jsonl` 리플레이로 대화 복원, `FileStateTracker` 파일 스냅샷 → prompt 단위 rewind, 세션 fork | 복구 프로토콜 §9(7단계), Chain 파일 → status.md → 팀 재구성, Git 태그·아카이브 브랜치에서 재체크아웃 |

- 철학이 정반대다. Grok: "컨텍스트는 소모품 — 잘 압축해서 계속 달린다." SSOT: "컨텍스트는 신뢰 불가 — 진실은 디스크의 문서에 있고, 의심되면 문서에서 다시 만든다." Grok의 `COMPACT_SYSTEM_PROMPT`가 압축 후 에이전트의 규범을 2문장으로 줄이는 지점은, SSOT 관점에서 보면 **규범 소실 리스크**다(SSOT가 HR-3를 CRITICAL로 두는 정확한 이유). 반대로 SSOT의 `/clear` 재로딩은 Grok 관점에서 **막대한 토큰 재투자**다 — SUB-SSOT 60% 절감은 그 비용을 줄이려는 보완책이다.

### 3.8 서브에이전트 / 팀 위임

| 항목 | Grok Build | PAB SSOT |
|---|---|---|
| 생성 | `spawn_subagent` 툴 → **완전한 자식 SessionActor를 전용 OS 스레드에 생성**. foreground(예산 초과 시 auto-background 전환) / background | TeamCreate + Task tool로 역할별 팀원 스폰(planner/backend-dev/frontend-dev/verifier/tester + Research 3역할) |
| 깊이 | **최대 1** (서브에이전트는 재스폰 불가, task 툴 자체가 제거됨) | Hub-and-Spoke — 팀원 간 직접 통신 금지, Team Lead 경유(구조상 깊이 1과 등가) |
| 역할 정의 | agent type(`general-purpose`/`explore`/`plan` + `.grok/agents/*.md`) ⊕ role(TOML: capability/model/prompt\_file) ⊕ **persona**(TOML: instructions, input/output 계약, model/effort override) | ROLES/\*.md(작업 절차) ⊕ PERSONA/\*.md(Charter, 스폰 시 교체 가능) ⊕ SUB-SSOT/(역할별 모듈 문서) |
| 해상도 순서 | spawn 명시 override → role 기본값 → persona 기본값 → 부모 세션 | 모델은 policy/model-assignment.md 단일 정책(Strategic=opus / Implementation=sonnet 티어) |
| 툴 제한 | capability mode(read-only/read-write/execute/all) — 코드가 툴셋 필터링 | 역할별 subagent\_type 선택(Explore/Plan/Bash/general-purpose)으로 실질 제한 + EDIT 규범 |
| 격리 | worktree isolation 옵션(`x.ai/git/worktree/*` 확장, apply-merge 지원, worktree pool) | WT-1~5: 병렬 ≥ 2 트랙이면 worktree 필수, 경로 규약, 상태 파일 기록, Chain 종료 시 일괄 정리 |
| 결과 수신 | 요약 텍스트 반환, background는 `SubagentCompleted` synthetic 프롬프트로 재기동, usage 정산(120s 상한 drain) | REPORT-1~5: 보고서 파일 작성 + SendMessage는 **경로 링크만**(본문 보고 금지) — 파일이 정본 |
| 정리 | 액터/스레드 수명 자동 관리 | LIFECYCLE-1~4: 5분 무보고 점검, 유휴 즉시 종료, 해산 시 전원 shutdown + TeamDelete — **수동 GC를 규범화** |

- grok의 persona **input/output 계약**(persona 간 파일 체이닝)과 SSOT의 REPORT 규칙(보고서 파일 + 링크 보고)은 사실상 같은 패턴 — "에이전트 간 인터페이스를 파일로 고정"이다. 양쪽 모두 대화 텍스트를 신뢰할 수 없는 전달 매체로 보고 있다는 증거.

---

## 4. 지시(프롬프트) 계층 비교 — "요청일 때 모델이 받는 규범"

### 4.1 Grok Build의 시스템 프롬프트 스택

grok-build의 프롬프트는 `crates/codegen/xai-grok-agent/templates/`에 평문 공개되어 있으며, 바이너리에는 XOR 난독화(`prompt_encrypted.rs`, seed `0x5A/0x7B/0x3D`, `strings` 노출 방지용 — 보안 아님을 주석에 명시, `Zeroizing`으로 드롭 시 메모리 소거)로 임베드된다. 본 분석에서 복호화·평문 대조로 검증 완료.

| 템플릿 | 크기 | 용도·내용 |
|---|---|---|
| `prompt.md` (BASE) | **4.6KB / 45줄** | 기본 정체성("You are Grok released by xAI"), `<action_safety>`(되돌리기 어려움·파급 범위로 행동 가중, "One approval is not a blank check"), `<tool_calling>`, `<output_efficiency>`("Write like an excellent technical blog post"), `<formatting>`, `<user_guide>`(문서를 `~/.grok/docs/`에서 읽으라는 자기 참조) |
| `apply_patch_prompt.md` (CODEX) | 21KB / 283줄 | **openai/codex에서 포팅**된 프롬프트(THIRD-PARTY-NOTICES에 명시). preamble 메시지 규범, plan 툴 사용법(고품질/저품질 플랜 예시 포함), task execution("keep going until resolved"), 검증 철학, 최종 답변 스타일 가이드. `TemplateOverride::Codex` 선택 시 사용 |
| `subagent_prompt.md` | 4.7KB / 84줄 | 서브에이전트 전용: 범위 확장 금지, hashline 앵커 편집 워크플로우, AGENTS.md 스코프/우선순위 스펙, `<user_info>`(OS/shell/CWD/날짜), `${{ role_instructions }}`·`${{ persona_instructions }}` **주입 슬롯** |

**조립 파이프라인** (`prompt/context.rs`의 `PromptContext::render`):
- MiniJinja 계열 템플릿: `${{ tools.by_kind.read }}` 식으로 **툴 이름을 런타임 바인딩** — 툴명이 바뀌어도 프롬프트가 자동 추종. `is_non_interactive`(headless) 분기, `system_prompt_label` 교체 가능.
- `PromptMode::Extend`(기본 템플릿 + prompt\_body 추가) / `Full`(완전 교체), audience(Primary/Subagent)에 따라 템플릿 선택.
- **AGENTS.md는 시스템 프롬프트가 아니라 선행 user 메시지의 `<system-reminder>` 블록으로 주입** — 서브에이전트도 동일하게 전문을 받는다.
- CLI `--rules` 텍스트는 `<human_rules>` 블록으로 append, `--system-prompt-override`는 전체 교체.
- 압축 후엔 위 스택 전체가 2문장 `COMPACT_SYSTEM_PROMPT`로 대체된다.

**사용자 확장 계층** (우선순위 순): 직접 채팅 지시 > 깊은 디렉토리 AGENTS.md > 얕은 AGENTS.md > 홈 규칙. 지원 파일명이 `AGENTS.md`뿐 아니라 **`CLAUDE.md`/`CLAUDE.local.md`/`.claude/rules/` 및 `.cursor/rules/`까지 호환**(경쟁 도구 마이그레이션 비용 제거 전략). 훅 이벤트명도 Claude Code 별칭(`beforeShellExecution` 등)을 그대로 매핑한다.

### 4.2 PAB SSOT의 지시 계층

| 계층 | 내용 |
|---|---|
| CLAUDE.md | HARD RULES 8개(HR-1~8) + 시점별 필수 체크리스트 — 최상위 불변 규범 |
| SSOT 코어 0~5 | 진입·프로젝트·아키텍처·워크플로우·이벤트·자동화 — FRESH-1 순서 로딩 |
| ROLES + PERSONA + SUB-SSOT | 스폰 시 역할별 주입 세트(0-entrypoint §"스폰 컨텍스트 주입" 표) — grok의 role/persona TOML에 대응 |
| Phase 산출물 | status/plan/todo-list/tasks — 실행 시점의 동적 지시(작업 명세) |
| 규칙 인덱스 | core/6-rules-index.md — 3중 색인(카테고리/파일/심각도)으로 규칙 조회 |

### 4.3 대조 분석

1. **분량의 역설**: grok의 기본 규범(BASE)은 45줄에 불과하고, 행동 세부는 도구·게이트·훅이 코드로 대신한다. SSOT는 코어만 2,600줄+ — 런타임이 없으니 모든 제어를 언어로 서술해야 한다. **"코드 1게이트 = 문서 N규칙" 환산이 두 시스템 전반에서 관찰된다.**
2. **동적 바인딩 vs 정적 문서**: grok은 툴명·모드·audience를 템플릿 변수로 런타임 해석. SSOT는 정적 마크다운이라 버전 관리(VERSION.md, FRESH-2/3 대조)로 드리프트를 방어한다.
3. **타사 호환**: grok이 CLAUDE.md·Claude 훅 별칭까지 읽는 반면, SSOT는 Claude Code 전용으로 설계됐다. grok 하네스 위에 SSOT를 얹는 것도 이론상 가능하다는 뜻이다(AGENTS.md 경유).
4. **프롬프트 보호**: grok은 서브에이전트/코덱스 프롬프트에 "내용을 노출하지 말라"는 지시를 넣으면서도 저장소에 평문을 공개한다(난독화는 `strings` 방지용). SSOT는 반대로 **규범 전체가 사용자 소유 문서**이며 LOCK-1~5로 변경 절차만 통제한다.

---

## 5. 관찰성·알림·기록

| 항목 | Grok Build | PAB SSOT |
|---|---|---|
| 실시간 관찰 | TUI tasks pane(Ctrl+B), 서브에이전트 프레임 뷰, `x.ai/queue/changed`·interjection 브로드캐스트, telemetry(Mixpanel 계열) | 이벤트 프로토콜(JSONL, `5th_mode.event`), Heartbeat |
| 완료 통지 | ACP PromptResponse, headless는 `{"type":"max_turns_reached"}` 등 구조화 출력 | **NOTIFY-1~3: Telegram 알림이 DONE 전이의 필수 조건**("알림 없이 DONE 무효") |
| 감사 추적 | `updates.jsonl` 전체 세션 리플레이 가능, SQLite journal(NFS 안전) | Phase 산출물 + reports/ + Chain 파일 1줄 요약(CHAIN-5) + Git 태그 — 사람이 읽는 감사 문서 |

---

## 6. 종합 대조표

| 차원 | Grok Build | PAB SSOT | 판정 |
|---|---|---|---|
| 강제력 | 컴파일 코드·커널 — 우회 불가 | 규범 — LLM 준수 의존, 위반 감지·기록으로 보완 | 신뢰성: grok / 적응성: SSOT |
| 제어 해상도 | 툴 호출 1건 단위 (ms~s) | 상태 전이 단위 (min~h) | 상호 보완 (다른 층위) |
| 품질 게이트 | 없음(훅으로 사용자가 구성) | G0~G4 내장 + 역할 분리 | SSOT 고유 강점 |
| 폭주 방지 | doom-loop 감지, TodoGate, Stop gate, max\_turns | 횟수 상한(3회), 토큰 예산(500K), 게이트 | 상호 차용 가치 최대 영역 |
| 컨텍스트 위기 | 자동 압축 후 계속(규범 축소 감수) | 문서 기반 전체 재구성(토큰 비용 감수) | 목적 따라 상이 |
| 병렬성 | 액터+FuturesUnordered+파일락 (코드 조율) | worktree 규약+EDIT-5 (규범 조율) | grok이 세밀, SSOT가 안전 편향 |
| 이식성 | Rust 바이너리 필요, 모델은 xAI 계열 중심 | 마크다운만 — 어떤 에이전트 런타임에도 이식 가능(core/project 분리 진행 중) | SSOT |
| 개발 비용 | 수십만 줄 Rust (약 90 crate) | 문서 세트 (코어 ~2.6천 줄 + 부속) | SSOT (2~3자릿수 저렴) |
| 검증 가능성 | 회귀 테스트(예: 11.57일 sleep 버그 고정) | 위반 사례 기반 규칙 증축(V-25-3 → ASSIGN 신설 등) | 방식 자체가 다름: 테스트 vs 판례 |

---

## 7. 핵심 통찰 3가지

1. **하네스의 본질은 동일하다 — 강제 수단만 다르다.** 진입 통제(큐 vs ENTRY), 종료 게이트(Stop/TodoGate vs G4/NOTIFY), 반복 상한(max\_turns vs 3회 규칙), 역할·페르소나 이원화, worktree 격리, 파일 기반 에이전트 간 계약까지 — 구조적 대응물이 거의 1:1로 존재한다. 이는 LLM 에이전트 제어 문제의 해(解) 공간이 수렴하고 있음을 시사한다.
2. **SSOT의 규칙 인플레이션은 런타임 부재의 대가다.** grok이 코드 게이트 1개로 끝내는 통제(예: plan 모드 read-only)를 SSOT는 규칙 3~4개 + 체크리스트 + 위반 기록으로 재현한다. 규칙 100개 중 상당수가 이 범주다. 반대로 그 덕에 SSOT는 **바이너리 없이 어디로든 이식 가능**하고, 규칙 증축이 커밋 1개로 끝난다.
3. **컨텍스트 철학이 두 시스템의 정체성을 가른다.** grok은 "압축하고 계속"(속도 우선, 규범 소실 감수), SSOT는 "의심되면 문서에서 재구성"(규범 보존 우선, 토큰 비용 감수). 장시간 자율 작업에서 grok류 하네스가 규범을 잃는 문제는 SSOT의 HR-3/FRESH-7이 정확히 겨냥하는 지점이며, 역으로 SSOT의 재로딩 비용은 grok의 prefire 압축 같은 기법으로 완화할 여지가 있다.

---

## 8. 상호 차용 제안 (Actionable)

**SSOT에 도입할 만한 grok 장치**:
1. **doom-loop 감지 규칙**: 팀원이 동일 실패를 반복 보고하면(예: 같은 오류 2회) Team Lead가 접근 자체를 바꾸게 하는 명시 규칙 — 현행 retry 3회 상한보다 조기 개입.
2. **prefire 방식 선제 리로드**: 컨텍스트 사용률이 높아지면 `/clear` **이전에** status.md·Chain 파일에 현재 상태를 선제 기록(pass-1에 해당) — 압축이 덮치기 전에 문서 동기화.
3. **completion\_requirement 패턴**: "이 Phase는 X 산출물 없이는 DONE 불가"를 status.md 필드로 선언 — NOTIFY-1("알림 없이 DONE 무효")의 일반화.
4. **capability mode 명명**: 팀원 스폰 시 read-only/read-write/execute를 명시 태그로 기록해 EDIT 규칙 검증을 기계적으로.

**grok 사용 시 SSOT식으로 보강할 지점**:
1. AGENTS.md에 G2/G3식 게이트 체크리스트를 넣어 품질 게이트 부재를 보완.
2. Stop 훅으로 "검증 산출물 없으면 KeepWorking" — SSOT G4를 훅으로 구현 가능.
3. 서브에이전트 persona의 input/output 계약을 SSOT REPORT 규칙처럼 파일 경로 기반으로 표준화.

---

## 9. 부록 — 근거 소스

**grok-build** (`sub/grok-build/`):
- 프롬프트: `crates/codegen/xai-grok-agent/templates/{prompt,apply-patch-prompt,subagent-prompt}.md`, `src/prompt/{context.rs, template.rs, prompt_encrypted.rs, agents_md.rs, skills.rs}`
- 턴 루프: `crates/codegen/xai-grok-shell/src/session/acp_session_impl/{turn.rs, run_loop.rs, tool_calls.rs, prompt_queue.rs, interjection.rs, compaction.rs, sampler_turn.rs}`
- 진입: `crates/codegen/xai-grok-pager-bin/src/main.rs`, `xai-grok-shell/src/agent/app.rs`, `agent/mvp_agent/acp_agent.rs`, `agent/subagent/`
- 보조: `xai-grok-sampler`(doom-loop), `xai-grok-compaction`, `xai-token-estimation`, `xai-grok-sandbox`, `xai-grok-hooks`, `xai-grok-memory`, `xai-chat-state`, `xai-grok-mcp`
- 문서: `crates/codegen/xai-grok-pager/docs/user-guide/` (01~24)

**PAB SSOT** (`SSOT/`):
- `0-entrypoint.md`(v8.0-renewal-6th), `3-workflow.md`(v7.0-renewal-5th, 1,091줄 전문), `core/6-rules-index.md`(v1.4, 규칙 100/134), `.claude/CLAUDE.md`(HR-1~8), `ROLES/`, `PERSONA/`, `SUB-SSOT/`, `QUALITY/10-persona-qc.md`, `refactoring/`, `infra/git-worktree-guide.md`
