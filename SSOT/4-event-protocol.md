# 4. 이벤트 프로토콜 (5세대 신규)

> SSOT 5세대에서 도입된 Event-first 축의 운영 규칙

---

## §1 이벤트 스키마 (JSONL)

### 1.1 형식 규칙
- **파일 형식**: 1줄 1JSON, UTF-8 인코딩
- **저장 경로**: `/tmp/agent-events/{phase}.jsonl`
  - 예: `/tmp/agent-events/phase-23-1.jsonl`
- **줄바꿈**: LF (`\n`) 사용, CRLF 금지

### 1.2 필수 필드

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| `timestamp` | string (ISO8601) | 이벤트 발생 시각 | `"2026-02-28T14:30:00+09:00"` |
| `agent` | string | 이벤트 발생 에이전트 | `"backend-dev"`, `"team-lead"` |
| `event_type` | enum | 이벤트 유형 (§1.3 참조) | `"heartbeat"` |
| `state` | string | 현재 상태 | `"BUILDING"`, `"VERIFYING"` |
| `detail` | object | 이벤트 상세 정보 | `{"task":"23-1-3","progress":60}` |
| `phase_id` | string | Phase 식별자 | `"23-1"` |

### 1.3 event_type 열거형

| event_type | 설명 | 발생 주체 |
|------------|------|----------|
| `heartbeat` | 생존 확인 신호 | 모든 에이전트 |
| `state_transition` | 상태 전이 발생 | Team Lead / Watchdog |
| `gate_result` | 게이트 판정 결과 | Verifier / Tester |
| `blocker` | 차단 이슈 발생 | 모든 에이전트 |
| `decision` | 의사결정 기록 | Team Lead |
| `artifact_created` | 산출물 생성 완료 | Planner / Dev |
| `error` | 오류 발생 | 모든 에이전트 |
| `reminder` | 리마인드 알림 | Watchdog |

---

## §2 Heartbeat 프로토콜

### 2.1 주기 규칙

| 상태 | Heartbeat 주기 | 근거 |
|------|---------------|------|
| BUILDING | 5분 | 코드 작성 중 진행률 추적 필요 |
| VERIFYING | 10분 | 검증 작업은 상대적으로 정적 |
| TESTING | 10분 | 테스트 실행 대기 시간 고려 |
| PLANNING | 7분 | 분석 중간 상태 보고 |
| RESEARCH | 10분 | 조사 작업 특성 반영 |

### 2.2 Heartbeat 메시지 형식

```json
{
  "timestamp": "2026-02-28T14:30:00+09:00",
  "agent": "backend-dev",
  "event_type": "heartbeat",
  "state": "working",
  "detail": {
    "task": "23-1-3",
    "progress": 60,
    "current_action": "API 엔드포인트 구현 중"
  },
  "phase_id": "23-1"
}
```

### 2.3 미수신 처리 흐름

```
Heartbeat 미수신
  → interval × 2 경과: Watchdog 1차 리마인드 (SendMessage)
  → interval × 3 경과: Watchdog 2차 에스컬레이션 (Team Lead 알림)
  → interval × 4 경과: BLOCKED 상태 전이
```

---

## §3 Watchdog SLA

### 3.1 역할별 타임아웃

| 상태 | 타임아웃 | 비고 |
|------|---------|------|
| PLANNING | 10분 | 분석 완료 기한 |
| RESEARCH | 15분 | 리서치 범위 제한 |
| BUILDING | 무제한 | heartbeat 의존 (§2 참조) — 아래 §3.1.1 참조 |
| VERIFYING | 12분 | 검증 단계 제한 |
| TESTING | 15분 | 테스트 실행 포함 |

#### 3.1.1 BUILDING SLA 명확화
BUILDING 상태에는 **절대 타임아웃이 없다**. 에스컬레이션은 오직 heartbeat 미수신 시에만 발생한다.
구체적으로: heartbeat **3회 연속 미수신**(= 3 × `heartbeat_interval`, 즉 BUILDING 기준 15분) 시
§3.2의 2차 에스컬레이션 규칙에 따라 Team Lead에게 에스컬레이션된다.

### 3.2 에스컬레이션 단계

| 단계 | 조건 | 행동 |
|------|------|------|
| 1차 리마인드 | heartbeat_interval × 2 초과 | SendMessage로 해당 에이전트에 알림 |
| 2차 에스컬레이션 | heartbeat_interval × 3 초과 | Team Lead에게 알림 + 이벤트 로그 기록 |
| 3차 BLOCKED 전이 | heartbeat_interval × 4 초과 | 해당 Task를 BLOCKED 상태로 전이 |

### 3.3 경고 임계치 계산

```
리마인드 트리거 = heartbeat_interval × 2
예: BUILDING 상태 → 5분 × 2 = 10분 무응답 시 1차 리마인드
```

---

## §4 상태 전이 이벤트

### 4.1 기록 규칙
- 모든 상태 전이 시 **자동으로** 이벤트 로그에 기록한다
- 기록 누락은 SSOT 위반으로 간주한다

### 4.2 상태 전이 메시지 형식

```json
{
  "timestamp": "2026-02-28T14:45:00+09:00",
  "agent": "team-lead",
  "event_type": "state_transition",
  "state": "BUILDING→VERIFYING",
  "detail": {
    "task": "23-1-3",
    "gate": "G2",
    "previous_state": "BUILDING",
    "next_state": "VERIFYING",
    "trigger": "dev 완료 보고"
  },
  "phase_id": "23-1"
}
```

### 4.3 Git Checkpoint 연동
- 상태 전이 이벤트 발생 시 **Team Lead가 수동으로 태그 생성** (Branch-first 원칙, 향후 자동화 검토 예정)
- 태그 명명 규칙: `phase-{X}-{Y}-{state}`
  - 예: `phase-23-1-BUILDING`, `phase-23-1-VERIFYING`
- 동일 상태 재진입 시 접미사 추가: `phase-23-1-BUILDING-retry-1`

---

## §5 게이트 결과 이벤트

### 5.1 기록 대상
- G0 (리서치 리뷰) ~ G4 (최종 검수) 모든 게이트 판정 시 기록

### 5.2 게이트 결과 메시지 형식

```json
{
  "timestamp": "2026-02-28T15:00:00+09:00",
  "agent": "verifier",
  "event_type": "gate_result",
  "state": "VERIFYING",
  "detail": {
    "gate": "G2",
    "verdict": "PASS",
    "score": 92,
    "issues": [],
    "council_members": ["security", "performance", "test-engineer"],
    "duration_minutes": 8
  },
  "phase_id": "23-1"
}
```

### 5.3 판정 결과 값

| verdict | 의미 | 후속 행동 |
|---------|------|----------|
| `PASS` | 통과 | 다음 상태로 전이 |
| `PARTIAL` | 조건부 통과 | AUTO_FIX 또는 수정 지시 |
| `FAIL` | 불합격 | 이전 상태로 복귀 |

---

## §6 이벤트 로그 관리

### 6.1 보존 규칙
- **활성 Phase**: `/tmp/agent-events/{phase}.jsonl`에 실시간 기록
- **완료 Phase**: `docs/phases/phase-X-Y/events.jsonl`로 아카이브
- **아카이브 시점**: Phase 상태가 `DONE`으로 전이된 직후

### 6.2 조회 방법

```bash
# 특정 이벤트 타입 조회
jq 'select(.event_type == "gate_result")' /tmp/agent-events/phase-23-1.jsonl

# 특정 에이전트의 이벤트 조회
jq 'select(.agent == "backend-dev")' /tmp/agent-events/phase-23-1.jsonl

# 특정 시간대 이벤트 조회
jq 'select(.timestamp >= "2026-02-28T14:00:00")' /tmp/agent-events/phase-23-1.jsonl

# blocker 이벤트만 조회
jq 'select(.event_type == "blocker")' /tmp/agent-events/phase-23-1.jsonl
```

### 6.3 삭제 규칙
- **삭제 조건**: Phase `DONE` + 아카이브 완료 **모두 충족** 시에만 `/tmp` 파일 삭제
- **아카이브 파일**: 삭제 금지 (프로젝트 이력으로 보존)
- **미아카이브 상태에서 삭제 시도**: SSOT 위반

### 6.4 로그 용량 관리
- 단일 Phase JSONL 파일이 10MB 초과 시 Team Lead에게 경고
- heartbeat 이벤트는 아카이브 시 요약 가능 (마지막 heartbeat만 보존)
