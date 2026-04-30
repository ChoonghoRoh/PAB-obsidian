---
name: plan
description: 사용자 주도 마스터 플랜 진입 전 프롬프트 품질 토픽 논의 및 자료 수집(AutoCycle Step 0 Pre-draft). Team Lead 단독 운영, 코드 조사·리뷰 필요 시에만 BE/FE/tester 온디맨드 호출. AI handoff 시 자동 제외.
user-invocable: true
context: inherit
agent: main
allowed-tools: "Read, Glob, Grep, Bash, Write, Edit, EnterPlanMode, ExitPlanMode, Agent"
---

# plan — AutoCycle Step 0 Pre-draft (사용자 주도 한정)

## 역할

`PROMPT-QUALITY` 규칙(`6-rules-index.md §1.20`)에 따라 사용자 주도 마스터 플랜 진입 전 프롬프트 품질을 점검하고, 마스터 플랜 등록에 필요한 자료를 수집·정리한다. Claude Code 내장 **Plan Mode**와 유사하게 동작하며, **Team Lead 단독**으로 운영된다.

## 진입 조건 (§1)

아래 2가지 조건 중 하나라도 만족하면 진입:

| 조건 | 판별 방법 |
|------|-----------|
| **A** 사용자가 `/plan` 명시 호출 | 본 스킬이 호출됨 |
| **B** master-plan YAML `initiator: user` | Team Lead가 마스터 플랜 요청 접수 시 자동 확인 |

**제외 조건** (진입 불가):
- master-plan YAML `initiator: ai-handoff` — AI 주도 Next Prompt 이어짐 → Step 0 자동 스킵 + CHAIN-13(직전 3 Phase 기억 자동 로딩)으로 대체

## 동작 원리 (§2)

1. **Plan Mode 유사 운영**
   - 필요 시 `EnterPlanMode`로 계획 수립 모드 진입 → 사용자와 대화하며 Pre-draft 작성
   - 완료 시 `ExitPlanMode`로 종료 후 마스터 플랜 작성 단계로 이관

2. **Team Lead 단독 운영**
   - 본 스킬은 메인 세션(Team Lead) 전용
   - 팀 스폰 없이 시작 — 새로 팀을 만들지 않는다
   - HR-1 준수: Team Lead는 코드 수정 금지 — §3 온디맨드 호출을 통해서만 코드 접근

3. **토픽 레벨 경량 논의**
   - 구현 상세·라인 단위 설계 금지 — 토픽/방향/범위 수준까지만
   - 사용자 원본 프롬프트를 §1 그대로 보존하며, 보완·명확화 대화만 수행

## 온디맨드 팀원 호출 (§3)

필요 시에만 `Agent` 도구로 단일 질문 단위 스폰. 지속 협업 금지 — 응답 수신 후 즉시 활용하고 재호출은 별도.

| 상황 | 호출 대상 | 목적 |
|------|-----------|------|
| 기존 코드 현황 파악 | `backend-dev` / `frontend-dev` | 파일·모듈 경로 확인, 현행 구조 조사 |
| 문서 정합성·기존 규칙 확인 | `verifier` (또는 직접 Grep) | SSOT 충돌·중복 확인 |
| 외부 벤치마크·기술 비교 | `research-analyst` | 대안 기술 비교, 웹 리서치 |
| 영향도 분석 | `research-architect` | 의존성·변경 파급 분석 |
| 결함·리스크 식별 | `tester` | 테스트 가능성·엣지 케이스 사전 식별 |

**온디맨드 호출 원칙**:
- 호출 전 반드시 "호출 없이 해결 가능한가" 자문
- 1회 호출 = 1개 명확한 질문 (팀 스폰 아님 — Agent 서브에이전트)
- 결과는 즉시 `pre-draft-topics.md §3 수집 자료`에 기록

## 산출물 (§4)

**파일 경로**: `docs/phases/pre/phase-{N}-pre-draft.md`

**템플릿**: `SSOT/TEMPLATES/pre-draft-topics.md` (§1~§8 구조 준수)

| 섹션 | 내용 |
|------|------|
| §1 | 원본 프롬프트 (Raw Input, 수정 금지) |
| §2 | 토픽 논의 요약 (T-01, T-02 …) |
| §3 | 수집 자료 (온디맨드 호출 결과 — 없으면 "없음") |
| §4 | Pre-test 결과 (간이 spike, 없으면 "생략 + 사유") |
| §5 | PROMPT-QUALITY 5항목 판정 (완전성·명료성·실행 가능성·범위 적정성·트리아지) |
| §6 | 마스터 플랜 진입 준비 (KPI 초안·제안 범위·리스크) |
| §7 | Next Step (마스터 플랜 착수 승인 또는 재질문) |
| §8 | 작성 지침 (템플릿 포함) |

## 종료 조건 (§5)

아래 2가지 중 1건 만족 시 종료:

1. **정규 종료**: PROMPT-QUALITY 5항목 모두 PASS → 사용자 최종 승인(§7.3) → 마스터 플랜 착수
2. **Fast-path 종료**: 5항목 자명 PASS 판정 → §1·§5·§6만 작성 → master-plan YAML에 `prompt_quality: fast-path` 표기

**이상 종료**:
- 1건 이상 FAIL → 사용자에게 재질문 또는 범위 조정 요청 → 재질문 결과 반영 후 재판정
- 1건 이상 PARTIAL → 보완 후 재판정 (최대 반복 횟수 명시 없음 — 사용자 판단)

## 제외 조건 (§6)

본 스킬을 **호출하지 말아야 하는** 상황:

| 상황 | 이유 |
|------|------|
| AI handoff에서 자동 이어진 마스터 플랜 | `initiator: ai-handoff` — 직전 Phase의 Next Prompt Suggestion이 채택된 경우, CHAIN-13으로 기억 전달이 이미 수행됨 |
| 이미 Phase 실행 중 (BUILDING 이후) | Step 0는 마스터 플랜 작성 **전** 단계 — Phase 실행 중 호출은 범위 혼란 초래 |
| 단순 질문·정보 조회 요청 | Phase 착수가 아닌 일반 질문은 스킬 불요 |
| 코드 수정 직접 요청 | Team Lead는 코드 수정 금지(HR-1) — 팀 스폰 플로우로 이행 |

## 출력 형식

```markdown
## /plan 스킬 실행 결과

### 진입 판정
- 조건: [A /plan 명시 호출 | B initiator: user]
- 본 Phase: Phase-{N} "{제목}"

### 산출물
- 경로: docs/phases/pre/phase-{N}-pre-draft.md
- 작성 범위: [전체 §1~§7 | Fast-path §1·§5·§6만]

### PROMPT-QUALITY 판정
- 완전성: PASS/PARTIAL/FAIL
- 명료성: PASS/PARTIAL/FAIL
- 실행 가능성: PASS/PARTIAL/FAIL
- 범위 적정성: PASS/PARTIAL/FAIL
- 트리아지: [즉시 진행 | 재질문 | 분할 | 취소]

### 온디맨드 호출 내역
- {대상}: {질문 요약} → {결과 요약}
- (없으면 "호출 없음")

### Next Step
- [ ] 마스터 플랜 착수 (phase-{N}-master-plan.md 작성)
- [ ] 재질문 필요: {질문}
- [ ] 범위 분할 필요: {제안}
```

## 참고

- 규칙: `SSOT/core/6-rules-index.md §1.20 PROMPT-QUALITY` (HIGH)
- 템플릿: `SSOT/TEMPLATES/pre-draft-topics.md`
- 규정 근거: Phase-I I-2 (AutoCycle Pre-draft Gate)
- 제외 분기 로직: `SSOT/SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md §Step-0 Branch` (Phase-I I-4 산출물)
