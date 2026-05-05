---
title: "PAB SSOT — 이벤트 프로토콜·자동화 파이프라인 (4·5-event/automation)"
description: "5세대 신규 — JSONL 이벤트 로그 + Heartbeat + Watchdog SLA + Artifact Persister + AutoReporter + DecisionEngine(AUTO_FIX 6조건 AND, 최대 3회) + ContextRecoveryManager + Git Checkpoint 정리"
created: 2026-05-05 05:13
updated: 2026-05-05 05:13
type: "[[RESEARCH_NOTE]]"
index: "[[ENGINEERING]]"
topics: ["[[PAB_SSOT]]", "[[EVENT_PROTOCOL]]", "[[AUTOMATION]]", "[[AUTO_FIX]]"]
tags: [research-note, pab-ssot-nexus, event-protocol, automation, jsonl, heartbeat, watchdog, decision-engine]
keywords: ["JSONL", "Heartbeat", "Watchdog", "SLA", "state_transition", "gate_result", "blocker", "Artifact Persister", "AutoReporter", "DecisionEngine", "AUTO_FIX", "6조건 AND", "Git Checkpoint", "AB 분기", "ContextRecoveryManager"]
sources:
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/4-event-protocol.md"
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/5-automation.md"
aliases: ["이벤트 프로토콜", "자동화 파이프라인", "AUTO_FIX 루프"]
---

# PAB SSOT — 이벤트 프로토콜 + 자동화 파이프라인

> 5세대 신규 두 문서 통합. **활성화 조건**: `5th_mode.event = true` / `5th_mode.automation = true`. 미설정 시 4세대 호환 수동 모드.

## §1 JSONL 이벤트 스키마

### 형식 규칙
- **파일 형식**: 1줄 1JSON, UTF-8
- **저장 경로**: `/tmp/agent-events/{phase}.jsonl` (예: `phase-23-1.jsonl`)
- **줄바꿈**: LF(`\n`), CRLF 금지

### 필수 필드

| 필드 | 타입 | 예시 |
|---|---|---|
| `timestamp` | ISO8601 | `"2026-02-28T14:30:00+09:00"` |
| `agent` | string | `"backend-dev"`, `"team-lead"` |
| `event_type` | enum | `"heartbeat"` |
| `state` | string | `"BUILDING"`, `"VERIFYING"` |
| `detail` | object | `{"task":"23-1-3","progress":60}` |
| `phase_id` | string | `"23-1"` |

### event_type 8종

| event_type | 발생 주체 |
|---|---|
| `heartbeat` | 모든 에이전트 (생존 신호) |
| `state_transition` | Team Lead / Watchdog |
| `gate_result` | Verifier / Tester |
| `blocker` | 모든 에이전트 |
| `decision` | Team Lead |
| `artifact_created` | Planner / Dev |
| `error` | 모든 에이전트 |
| `reminder` | Watchdog |

## §2 Heartbeat 프로토콜

### 주기 (상태별)

| 상태 | 주기 | 근거 |
|---|---:|---|
| BUILDING | 5분 | 진행률 추적 |
| VERIFYING | 10분 | 정적 작업 |
| TESTING | 10분 | 실행 대기 |
| PLANNING | 7분 | 분석 중간 보고 |
| RESEARCH | 10분 | 조사 특성 |

### Heartbeat 메시지 예시

```json
{
  "timestamp": "2026-02-28T14:30:00+09:00",
  "agent": "backend-dev",
  "event_type": "heartbeat",
  "state": "working",
  "detail": {"task":"23-1-3","progress":60,"current_action":"API 엔드포인트 구현 중"},
  "phase_id": "23-1"
}
```

### 미수신 처리 (Watchdog)

```
Heartbeat 미수신
  → interval × 2 경과: Watchdog 1차 리마인드 (SendMessage)
  → interval × 3 경과: 2차 에스컬레이션 (Team Lead 알림 + 이벤트 로그)
  → interval × 4 경과: BLOCKED 상태 전이
```

## §3 Watchdog SLA

### 역할별 타임아웃

| 상태 | 타임아웃 | 비고 |
|---|---:|---|
| PLANNING | 10분 | 분석 완료 기한 |
| RESEARCH | 15분 | 리서치 범위 제한 |
| **BUILDING** | **무제한** | heartbeat 의존 (3회 연속 미수신 = 15분 시 2차 에스컬레이션) |
| VERIFYING | 12분 | 검증 단계 제한 |
| TESTING | 15분 | 테스트 실행 포함 |

> BUILDING은 절대 타임아웃 없음. 오직 heartbeat 미수신 시에만 에스컬레이션.

### 경고 임계치

```
리마인드 트리거 = heartbeat_interval × 2
예: BUILDING 5분 × 2 = 10분 무응답 시 1차 리마인드
```

## §4 상태 전이 이벤트

```json
{
  "timestamp": "2026-02-28T14:45:00+09:00",
  "agent": "team-lead",
  "event_type": "state_transition",
  "state": "BUILDING→VERIFYING",
  "detail": {
    "task": "23-1-3", "gate": "G2",
    "previous_state": "BUILDING", "next_state": "VERIFYING",
    "trigger": "dev 완료 보고"
  },
  "phase_id": "23-1"
}
```

**기록 누락은 SSOT 위반.**

## §5 게이트 결과 이벤트

G0(리서치 리뷰) ~ G4(최종 검수) 모든 판정 시 기록.

```json
{
  "timestamp": "2026-02-28T15:00:00+09:00",
  "agent": "verifier",
  "event_type": "gate_result",
  "state": "VERIFYING",
  "detail": {
    "gate": "G2", "verdict": "PASS", "score": 92, "issues": [],
    "council_members": ["security","performance","test-engineer"],
    "duration_minutes": 8
  },
  "phase_id": "23-1"
}
```

| verdict | 후속 행동 |
|---|---|
| `PASS` | 다음 상태 전이 |
| `PARTIAL` | AUTO_FIX 또는 수정 지시 |
| `FAIL` | 이전 상태 복귀 |

## §6 이벤트 로그 관리

### 보존
- **활성 Phase**: `/tmp/agent-events/{phase}.jsonl`
- **완료 Phase**: `docs/phases/phase-X-Y/events.jsonl`로 아카이브 (DONE 직후)
- **삭제**: Phase DONE + 아카이브 완료 둘 다 충족 시에만 `/tmp` 파일 삭제. 아카이브 파일은 삭제 금지.

### 조회 (jq)

```bash
# 게이트 결과만
jq 'select(.event_type == "gate_result")' /tmp/agent-events/phase-23-1.jsonl

# 특정 에이전트
jq 'select(.agent == "backend-dev")' /tmp/agent-events/phase-23-1.jsonl

# 시간대 필터
jq 'select(.timestamp >= "2026-02-28T14:00:00")' /tmp/agent-events/phase-23-1.jsonl

# blocker만
jq 'select(.event_type == "blocker")' /tmp/agent-events/phase-23-1.jsonl
```

### 용량 관리
- 단일 Phase JSONL 10MB 초과 시 Team Lead 경고
- heartbeat은 아카이브 시 요약 가능 (마지막만 보존)

---

# 자동화 파이프라인 (5-automation)

## §1 Artifact Persister — 산출물 자동 무결성 검증

> **구현 주체**: 현재 **Team Lead 수동**. `5th_mode.automation: true`여도 검증 절차는 수동. 향후 Hook/MCP 자동화 예정.

### 검증 시점
- 각 상태 전이 전 자동 실행
- Planner SendMessage 도착 시점
- Team Lead 승인 시점
- status.md 업데이트 시마다

### 검증 항목

| 대상 | 내용 | 실패 시 |
|---|---|---|
| YAML frontmatter | 유효 YAML, 필수 필드 | 에스컬레이션 |
| 필수 필드 존재 | `current_state`, `ssot_version`, `phase_id` 등 | 에스컬레이션 |
| 링크 유효성 | 참조 링크가 실제 파일 가리키는지 | 경고 기록 |
| 산출물 완전성 | CHAIN-6 필수 산출물 전체 존재 | 에스컬레이션 |

### 자동 생성 대상

| 산출물 | 파일명 | 시점 |
|---|---|---|
| 계획서 | `phase-X-Y-plan.md` | Planner 분석 완료 후 |
| 체크리스트 | `phase-X-Y-todo-list.md` | 계획서 직후 |
| Task 명세 | `tasks/task-X-Y-N.md` | 체크리스트 직후 |
| 상태 파일 | `phase-X-Y-status.md` | Phase 시작 시 |

### CHAIN-6 자동 검증
산출물 생성 후 필수 체크리스트 자동 확인. 누락 시 `blocker` 이벤트 + Team Lead 알림. **자동 커밋 금지** — Team Lead 검토 후 직접 커밋.

## §2 AutoReporter

### 보고 트리거

| 트리거 | 보고 내용 | 대상 |
|---|---|---|
| Task 완료 | Task별 요약, 남은 Task | 진행 보고서 |
| 상태 전이 | 이전→다음 상태, 소요 시간, 이슈 | 전이 보고서 |
| 게이트 판정 | G0~G4 결과, 점수, 이슈 | 게이트 리포트 |

### 형식 (마크다운 테이블)

```markdown
## Phase X-Y 진행 보고서
| Task ID | 상태 | 담당 | 진행률 | 비고 |
|---------|------|------|:------:|------|
| X-Y-1   | DONE | backend-dev | 100% | |
| X-Y-2   | BUILDING | backend-dev | 60% | API 구현 중 |
| X-Y-3   | PENDING | frontend-dev | 0% | BE 의존 대기 |
```

### 저장 위치
- 자동 보고서: `docs/phases/phase-X-Y/auto-reports/{YYYYMMDD-HHMM}-{type}.md`
- 게이트 리포트(호환): `docs/phases/phase-X-Y/gate-{G}-report.md`
- 재판정 시: 기존 유지 + 접미사 (예: `gate-G2-report-retry-1.md`)
- **삭제 금지** (Phase 완료 후에도 보존)

### 게이트 리포트 구조

```markdown
# Gate {G} Report: Phase {X-Y}

## 판정 결과
- 판정: {PASS | PARTIAL | FAIL}
- 점수: {점수}/100
- 검증 시각: {ISO8601}
- 검증 소요: {분}

## 이슈 목록
| # | 심각도 | 항목 | 설명 | 파일 |

## 수정 지시
- [ ] {항목 1}
- [ ] {항목 2}

## 다음 행동
- PASS: {다음 상태} 전이
- PARTIAL: AUTO_FIX 루프 진입
- FAIL: {이전 상태} 복귀
```

## §3 DecisionEngine — AUTO_FIX 6조건 AND

### AUTO_FIX 적용 가능 조건 (모두 동시 충족)

| # | 조건 | 설명 |
|:--:|---|---|
| 1 | G2 = **PARTIAL** | FAIL이면 즉시 REWINDING (자동 판정 불가) |
| 2 | **Critical 0건** | Critical 1건 이상이면 Team Lead 필수 |
| 3 | **High 1~2건** | High 3건 이상이면 Team Lead 필수 |
| 4 | **아키텍처 변경 없음** | 구조 변경 시 Team Lead 승인 필수 |
| 5 | **새 의존성 없음** | 신규 라이브러리 추가 시 승인 필수 |
| 6 | **Security/Performance 비토 없음** | Council 비토 발동 시 자동 판정 불가 |

> **하나라도 미충족 → 자동 판정 불가 → Team Lead 수동 에스컬레이션**

### AUTO_FIX 루프

```
G2 PARTIAL 판정
  → DecisionEngine 적용 가능성 평가
  → 적용 가능: Verifier가 Dev에게 직접 수정 지시
  → Dev 수정 완료 → Verifier 재검증
  → (최대 3회 반복)
  → 3회 초과 시: Team Lead 강제 개입 + BLOCKED 전이
```

| 상황 | 판정 | 행동 |
|---|---|---|
| 동일 이슈 1회 | 자동 수정 시도 | Dev 수정 지시 |
| 동일 이슈 2~3회 | 자동 수정 재시도 | 경고 + 재지시 |
| 동일 이슈 3회 초과 | **에스컬레이션** | Team Lead 강제 개입 |

### 수동 에스컬레이션 조건

- Critical 이슈 존재
- 아키텍처 변경 필요
- 새 의존성 추가
- Security/Performance 비토 발동

### 판정 이력 기록
모든 자율 판정은 `decision-log.md`에 자동 저장. 항목: 시각·판정 내용·근거·대안·결과.

## §4 자동화 활성화

```yaml
5th_mode:
  automation: true   # true: 자동화 활성, false: 4th 호환 수동 모드
```

### 비활성화 시 동작 (수동 모드)
- Artifact Persister: Team Lead 수동 검증
- AutoReporter: 보고서 수동 작성
- DecisionEngine: 모든 판정 Team Lead 수동
- AUTO_FIX 루프: Team Lead 직접 수정 지시

부분 활성화는 향후 지원 — 현재는 일괄 활성화/비활성화만.

## §5 ContextRecoveryManager

> **구현 주체**: **Team Lead 수동**. 자동 감지 메커니즘 없음. 향후 `5th_mode.event = true` 환경에서 Heartbeat/Watchdog 기반 자동 감지 도입 가능.

### 트리거 조건

| 상황 | Team Lead 인지 | 행동 |
|---|---|---|
| 컨텍스트 압축 | 세션 재개 시 압축 요약 메시지 | FRESH-7 절차 실행 |
| 세션 중단 | 새 세션 시작 시 이전 작업 불명확 | FRESH-7 절차 실행 |
| 팀원 응답 없음 | SendMessage 후 응답 미수신 | 팀원 상태 확인 → 재스폰 |

### FRESH-7 복구 절차 (요약)

권위 문서: [[2026-05-05_pab_ssot_workflow|3-workflow §9]]. 본 섹션은 요약.

```
1. SSOT 리로드 (FRESH-1)
2. 팀 상태 확인 (team_name 존재? 없으면 새 팀 생성 — HR-1)
3. 미완료 Task 식별 (task_progress, status != DONE)
4. 업무 재분배 (idle 팀원 SendMessage 또는 새 스폰)
```

### 금지 사항
- SSOT 리로드 없이 작업 재개 (HR-3)
- 팀 없이 Team Lead 직접 코드 수정 (HR-1)
- 산출물 생략 (HR-2)
- 이전 세션 요약만으로 상태 추정 (ENTRY-1 위반)

## §6 Git Checkpoint 규칙

### 태그 명명

| 상황 | 태그 패턴 | 예시 |
|---|---|---|
| 상태 전이 | `phase-{X}-{Y}-{state}` | `phase-23-1-BUILDING` |
| 재시도 | `phase-{X}-{Y}-{state}-retry-{N}` | `phase-23-1-BUILDING-retry-1` |
| A/B 분기 시작 | `phase-{X}-{Y}-ab-start` | `phase-23-1-ab-start` |
| A/B 선택 | `phase-{X}-{Y}-ab-selected-{A\|B}` | `phase-23-1-ab-selected-A` |

### REWINDING

```bash
git checkout phase-{X}-{Y}-{target_state}
git checkout -b phase-{X}-{Y}-retry-{N}
```

REWINDING 시 반드시 새 브랜치 생성 (기존 덮어쓰기 금지).

### A/B 분기

```
A/B 시작
  → git tag phase-{X}-{Y}-ab-start
  → git checkout -b phase-{X}-{Y}-branch-A
  → git checkout -b phase-{X}-{Y}-branch-B
  → 병렬 구현 (worktree 격리, WT-1 필수)
  → 비교 평가 (ab-comparison-template.md)
  → 선택 브랜치 merge
  → 비선택 브랜치 아카이브
```

### 브랜치 보존
- **패배 브랜치 삭제 금지**
- 아카이브: `archive/phase-X-Y-option-{A|B}` (`git branch -m phase-{X}-{Y}-branch-{B} archive/phase-X-Y-option-B`)
- 향후 참조용으로 보존

상세 worktree 운영은 [[2026-05-05_pab_ssot_workflow|워크플로우 §6.6]] WT-1~5 + `/pab:worktree` skill ([[2026-05-05_pab_ssot_skills_detail|skill 상세 노트]]).

## 다음 노트

- [[2026-05-05_pab_ssot_workflow|워크플로우]] — 본 노트의 상위 (상태 머신·G2 PARTIAL 진입 조건)
- [[2026-05-05_pab_ssot_rules_chain|규칙·CHAIN]] — HR-1~8, CHAIN-1~13 인덱스
- [[2026-05-05_pab_ssot_skills_detail|skill 상세]] — `/pab:worktree`·`/pab:notify-telegram` 등 자동화 skill
- [[PAB_SSOT_overview|MOC]]

## 참고

- `/PAB-SSOT-Nexus/docs/SSOT/docs/4-event-protocol.md` (213줄)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/5-automation.md` (319줄)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/3-workflow.md` §9 — ContextRecoveryManager 권위 문서
