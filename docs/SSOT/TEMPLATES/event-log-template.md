# Event Log Template

> 표준 JSONL 이벤트 로그 형식 안내 및 예시
> 참조: [4-event-protocol.md](../4-event-protocol.md) §1 이벤트 스키마

---

## 1. 형식 규칙

- **파일 형식**: 1줄 1JSON (JSONL), UTF-8 인코딩
- **저장 경로**: `/tmp/agent-events/{phase}.jsonl`
- **줄바꿈**: LF (`\n`) 사용, CRLF 금지
- **아카이브 경로**: `docs/phases/phase-X-Y/events.jsonl`

---

## 2. 필수 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `timestamp` | string (ISO8601) | 이벤트 발생 시각 |
| `agent` | string | 이벤트 발생 에이전트 |
| `event_type` | enum | 이벤트 유형 |
| `state` | string | 현재 상태 |
| `detail` | object | 이벤트 상세 정보 |
| `phase_id` | string | Phase 식별자 |

---

## 3. event_type 열거형

| event_type | 설명 |
|------------|------|
| `heartbeat` | 생존 확인 신호 |
| `state_transition` | 상태 전이 발생 |
| `gate_result` | 게이트 판정 결과 |
| `blocker` | 차단 이슈 발생 |
| `decision` | 의사결정 기록 |
| `artifact_created` | 산출물 생성 완료 |
| `error` | 오류 발생 |
| `reminder` | 리마인드 알림 |

---

## 4. 이벤트 예시

### 4.1 Heartbeat 이벤트

```json
{"timestamp":"2026-02-28T14:30:00+09:00","agent":"backend-dev","event_type":"heartbeat","state":"working","detail":{"task":"23-1-3","progress":60,"current_action":"API 엔드포인트 구현 중"},"phase_id":"23-1"}
```

### 4.2 상태 전이 이벤트

```json
{"timestamp":"2026-02-28T14:45:00+09:00","agent":"team-lead","event_type":"state_transition","state":"BUILDING→VERIFYING","detail":{"task":"23-1-3","gate":"G2","previous_state":"BUILDING","next_state":"VERIFYING","trigger":"dev 완료 보고"},"phase_id":"23-1"}
```

### 4.3 게이트 결과 이벤트

```json
{"timestamp":"2026-02-28T15:00:00+09:00","agent":"verifier","event_type":"gate_result","state":"VERIFYING","detail":{"gate":"G2","verdict":"PASS","score":92,"issues":[],"council_members":["security","performance","test-engineer"],"duration_minutes":8},"phase_id":"23-1"}
```

### 4.4 블로커 이벤트

```json
{"timestamp":"2026-02-28T15:10:00+09:00","agent":"backend-dev","event_type":"blocker","state":"BUILDING","detail":{"task":"23-1-4","blocker_type":"dependency","description":"외부 API 응답 없음","severity":"High"},"phase_id":"23-1"}
```

### 4.5 의사결정 이벤트

```json
{"timestamp":"2026-02-28T15:20:00+09:00","agent":"team-lead","event_type":"decision","state":"VERIFYING","detail":{"decision":"AUTO_FIX 적용","reason":"High 이슈 1건, Critical 0건","alternatives":["수동 수정 지시","REWINDING"],"outcome":"AUTO_FIX 1회차 시작"},"phase_id":"23-1"}
```

### 4.6 산출물 생성 이벤트

```json
{"timestamp":"2026-02-28T13:00:00+09:00","agent":"team-lead","event_type":"artifact_created","state":"PLANNING","detail":{"artifact_type":"plan","file_path":"docs/phases/phase-23-1/phase-23-1-plan.md","task_count":5},"phase_id":"23-1"}
```

---

## 5. 조회 명령 예시

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
